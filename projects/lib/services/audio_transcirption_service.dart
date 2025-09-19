import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:projects/services/auth_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
final authService = AuthService();
/// A service to record audio locally and send it to a Flask backend for transcription.

class TranscriptionService {
  final AudioRecorder _recorder = AudioRecorder();
   File? fallbackFile;
   File? noneResFile;
  TranscriptionService() {
    _init();
  }

  Future<void> _init() async {
    fallbackFile = await _initFallbackFile();
    noneResFile = await _initNone();
  }

  Future<File> _initFallbackFile() async {
    final bytes = await rootBundle.load('assets/sorry.mp3');
    final dir = await getApplicationDocumentsDirectory();
    final fallbackFile = File('${dir.path}/apology_audio.mp3');
    await fallbackFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return fallbackFile;
  }
  Future<File> _initNone() async {
    final bytes = await rootBundle.load('assets/nothing.mp3');
    final dir = await getApplicationDocumentsDirectory();
    final fallbackFile = File('${dir.path}/noneres.mp3');
    await fallbackFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return fallbackFile;
  }
  bool _isRecording = false;
  String? _filePath;

  /// Indicates if recording is in progress.
  bool get isRecording => _isRecording;

 
  /// Starts recording audio to a temporary file.
  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _filePath = '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.wav';
      print("______File path: $_filePath");
      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      );
      await _recorder.start(config, path: _filePath!);
      _isRecording = true;
    } else {
      throw Exception('Microphone permission denied');
    }
  }

  /// Stops recording and returns the recorded file.
  Future<File?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    // await _recorder.dispose();
    _isRecording = false;
    if (path != null) {
      return File(path);
    }
    return null;
  }

  /// Sends the audio [file] to the Flask backend and returns the transcript.
  Future<File> transcribe(File audioFile,String imageFilePath, List<dynamic>? recognitionsCache, Map<String,dynamic> location) async {
    
    

    try{
      String? url = dotenv.env['BACKEND'];
      if (url == null) {
        print("!!!!!!!!!!!!!!!!!API not found");
        return fallbackFile!;
      }
      final uri = Uri.parse(url+'/chat_audio');
      final request = http.MultipartRequest('POST', uri);

      String? uid = await authService.getCurrentUserId();

      if (uid == null) {
        throw Exception('User ID is null, please log in first');
      }
      request.fields['uid'] = uid;
      request.fields['recognitionsCache'] = jsonEncode(recognitionsCache);
      print("!!!!!!!!!recognitionsCache: $recognitionsCache");
      request.fields['language'] = 'en';
      request.fields['latitude'] = location['latitude'].toString();
      request.fields['longitude'] = location['longitude'].toString();
      request.fields['address'] = location['address'];

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType('audio', 'wav'),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFilePath,
        ),
      );
      print("!!!!!!!!!sending api request");
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        final responseBytes = await streamedResponse.stream.toBytes();
        final dir = await getApplicationDocumentsDirectory();
        final mp3File = File('${dir.path}/downloaded_audio.mp3');
        await mp3File.writeAsBytes(responseBytes, flush: true);
        return mp3File;
      } else if (streamedResponse.statusCode == 400) {
        return noneResFile!;
      }else{
        print('Transcription failed: HTTP ${streamedResponse.statusCode}');
        return fallbackFile!;
      }
    }catch(e){
      print('Something related to transcribe failed: ${e}');
      return fallbackFile!;
    }
  }

  Future<String> tts(String text) async {
    String? url = dotenv.env['BACKEND'];
    if (url == null) {
      print("!!!!!!!!!!!!!!!!!API not found");
      return "";
    }
    final uri = Uri.parse(url! + '/tts');
    final response = await http.post(uri, body: {'text': text});
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final mp3File = File('${dir.path}/downloaded_tts.mp3');
      await mp3File.writeAsBytes(response.bodyBytes, flush: true);
      return mp3File.path;
    } else {
      print('TTS failed: HTTP ${response.statusCode}');
      return "";
    }
  }
}
