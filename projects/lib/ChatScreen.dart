import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:record/record.dart';
String? baseUrl = dotenv.env['BACKEND'];

/// Model for chat messages
class ChatMessage {
  final String id;
  final String filename;
  final String type;      // NEW!
  final DateTime timestamp;
  final String fromUid;
  String? localPath;

  ChatMessage({
    required this.id,
    required this.filename,
    required this.type,      // NEW!
    required this.timestamp,
    required this.fromUid,
    this.localPath,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      filename: json['filename'] as String,
      type: (json['type'] as String),          // NEW!
      timestamp: DateTime.parse(json['created_at'] as String),
      fromUid: (json['from_uid'] ?? '').toString(),
    );
  }
}

/// Service to call Flask APIs
class ChatApiService {
  static Future<List<ChatMessage>> pollMessages(
      String fromUid, String toUid) async {
    final uri = Uri.parse("$baseUrl/poll_from_uid")
        .replace(queryParameters: {'from_uid': fromUid, 'to_uid': toUid});
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception("Failed to poll messages");
    final data = jsonDecode(resp.body) as List<dynamic>;
    
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<void> sendVoice({
    required String fromUid,
    required String toName,
    required String myName,
    required String toUid,
    required File voiceFile,
  }) async {
    final uri = Uri.parse("$baseUrl/send_voice_chat");
    final request = http.MultipartRequest('POST', uri)
      // invert sender and receiver
      ..fields['from_uid'] = toUid
      ..fields['to_name'] = toName
      ..fields['from_name'] = myName
      ..fields['to_uid'] = fromUid
      ..files.add(await http.MultipartFile.fromPath('voice', voiceFile.path));
    final streamed = await request.send();
    if (streamed.statusCode != 204) {
      final resp = await http.Response.fromStream(streamed);
      throw Exception('Voice send failed: ${resp.body}');
    }
  }

  static Future<void> sendFile({
    required String fromUid,
    required String toName,
    required String myName,
    required String toUid,
    required File file,
  }) async {
    final uri = Uri.parse("$baseUrl/send_file_chat");
    final request = http.MultipartRequest('POST', uri)
      // invert sender/receiver like voice
      ..fields['from_uid'] = toUid
      ..fields['from_name'] = myName
      ..fields['to_name'] = toName
      ..fields['to_uid'] = fromUid
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    if (streamed.statusCode != 204) {
      final resp = await http.Response.fromStream(streamed);
      throw Exception('File send failed: ${resp.body}');
    }
  }
}

/// Chat screen with slick UI, grouped by date, left/right bubbles
class ChatScreen extends StatefulWidget {
  final String username;
  final String myname;
  final String fromUid;
  final String toUid;
  const ChatScreen({
    Key? key,
    required this.username,
    required this.myname,   
    required this.fromUid,
    required this.toUid,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();// nullable now, since we recreate each time
  // replace your RecorderController with the AudioRecorder package
final AudioRecorder _recorder = AudioRecorder(); // nullable now, since we recreate each time
  final CacheManager _cacheManager = DefaultCacheManager();
  late final AnimationController _animationController;

  // 1) ScrollController to handle automatic scrolling
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _isRecording = false;
  String? _recordFilePath;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initRecorderPath();
    _fetchMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchMessages(),
    );
  }

  /// Only determine the temporary-file path here. We do NOT create or prepare
  /// any controller until the user actually long-presses.
  Future<void> _initRecorderPath() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
     _recordFilePath = '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.wav';
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs =
          await ChatApiService.pollMessages(widget.fromUid, widget.toUid);
      
      setState(() {
        if(msgs.isEmpty) {print("msg empty");return;};
        print(msgs);
        if(msgs.length <= _messages.length) return;
        _messages = msgs;
      });

      // 3) After setState, schedule a scroll to bottom:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (e) {
      debugPrint("Poll error: $e");
    }
  }

  Future<File> _getMediaFile(ChatMessage msg) async {
    if (msg.localPath != null) return File(msg.localPath!);
    final url = "$baseUrl/media/${msg.filename}";
    final file = await _cacheManager.getSingleFile(url);
    msg.localPath = file.path;
    return file;
  }

  Future<void> _playAudio(ChatMessage msg) async {
    final file = await _getMediaFile(msg);
    if (_playingId == msg.id) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
      _animationController.reverse();
    } else {
      await _audioPlayer.play(DeviceFileSource(file.path));
      setState(() => _playingId = msg.id);
      _animationController.forward();
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _playingId = null);
        _animationController.reverse();
      });
    }
  }

   Future<void> _startRecording() async {
    if (_recordFilePath == null) return;
    // delete old temp…
    final file = File(_recordFilePath!);
    if (await file.exists()) {
      try { await file.delete(); } catch (_) {}
    }

    // Start with AudioRecorder in WAV mode:
    if (await _recorder.hasPermission()) {
      final config = RecordConfig(
       encoder: AudioEncoder.wav,
       bitRate: 128000,       // optional for WAV
       sampleRate: 44100,     // common WAV sample rate
      );
      try {
        await _recorder.start(config, path: _recordFilePath!);
        setState(() => _isRecording = true);
      } catch (e) {
        debugPrint('AudioRecorder start error: $e');
      }
    } else {
      debugPrint('Microphone permission denied');
    }
  }

  /// Stop recording, upload, then dispose.
  /// Stops WAV recording, uploads the file, and resets state.
Future<void> _stopRecording() async {
  if (!_isRecording || _recordFilePath == null) return;

  String? recordedPath;
  try {
    // Stop the recorder and get the final .wav path back
    recordedPath = await _recorder.stop();
  } catch (e) {
    debugPrint('AudioRecorder stop error: $e');
    return;
  }

  setState(() => _isRecording = false);

  if (recordedPath == null) return;
  final file = File(recordedPath);

  if (!await file.exists()) return;

  try {
    await ChatApiService.sendVoice(
      fromUid: widget.fromUid,
      toName: widget.username,
      myName: widget.myname,
      toUid: widget.toUid,
      voiceFile: file,            // this is your .wav file
    );
    await _fetchMessages();
  } catch (e) {
    debugPrint('Send voice error: $e');
  }
}


  @override
  void dispose() {
    _pollTimer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    _scrollController.dispose();  // 2) Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF162447), Color(0xFF1F4068)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 36, semanticLabel: 'Back', color: Colors.amberAccent,),
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(16),
          ),
          title: Text(
            widget.username,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
            semanticsLabel: 'Chat with ${""}' + widget.username,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 60),
              decoration: BoxDecoration(
                color: Colors.amberAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildGroupedList()),
          _buildInputBar(),
        ],
      ),
    );
  }
  Widget _buildGroupedList() {
    final Map<String, List<ChatMessage>> grouped = {};
    for (var msg in _messages) {
      final day = DateTime(
        msg.timestamp.year,
        msg.timestamp.month,
        msg.timestamp.day,
      );
      final key = day.toIso8601String();
      grouped.putIfAbsent(key, () => []).add(msg);
    }
    final days = grouped.keys.toList()..sort();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF162447), Color(0xFF1F4068)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          for (var dayKey in days) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: Text(
                MaterialLocalizations.of(context)
                    .formatFullDate(DateTime.parse(dayKey)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...grouped[dayKey]!.map((msg) => _bubble(msg)),
          ],
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final isSelf = msg.fromUid == widget.fromUid;
    final bubbleGradient = isSelf
        ? LinearGradient(
            colors: [Color(0xFF0BCC9A), Color(0xFF3DE7AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.white, Color(0xFFE8E8E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final msgType = msg.type.toLowerCase();
    final isAudio = msgType == 'audio' || msgType == 'voice';
    final bubbleWidth = MediaQuery.of(context).size.width * 0.6;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      alignment: isSelf ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: bubbleWidth,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          gradient: bubbleGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            if (isAudio) {
              _playAudio(msg);
            } else {
              try {
                final file = await _getMediaFile(msg);
                await OpenFile.open(file.path);
              } catch (e) {
                debugPrint('Open file error: \$e');
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAudio)
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Icon(
                    _playingId == msg.id
                        ? Icons.stop_circle
                        : Icons.play_circle_fill,
                    size: 48, // larger icon for clarity
                    color: Colors.black87,
                    semanticLabel: isAudio ? 'Play audio' : null,
                  ),
                )
              else
                Icon(
                  Icons.insert_drive_file,
                  size: 48,
                  color: Colors.black54,
                  semanticLabel: 'Open file',
                ),

              const SizedBox(width: 16),

              Text(
                TimeOfDay.fromDateTime(msg.timestamp.toLocal()).format(context),
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 16,
                ),
                semanticsLabel: 'Sent at ' +
                    TimeOfDay.fromDateTime(msg.timestamp.toLocal())
                        .format(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF1F4068),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const SizedBox(width: 28),
          GestureDetector(
            onTap: () async {
              try {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  await ChatApiService.sendFile(
                    fromUid: widget.fromUid,
                    toName: widget.username,
                    myName: widget.myname,
                    toUid: widget.toUid,
                    file: file,
                  );
                  await _fetchMessages();
                }
              } catch (e) {
                debugPrint('File picker/send error: \$e');
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.attach_file,
                size: 40,
                color: Colors.black87,
                semanticLabel: 'Attach file',
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amberAccent, Color(0xFFE33E7F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 40,
                color: Colors.white,
                semanticLabel: _isRecording ? 'Stop Recording' : 'Record Audio',
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}
