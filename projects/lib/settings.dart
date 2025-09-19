import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PreferencesApi {
  final String baseUrl;
  PreferencesApi(this.baseUrl);

  Future<bool> savePreferences({
    required String userId,
    required List<String> languages,
    required List<String> objects,
    required double voiceSpeed,
  }) async {
    final url = Uri.parse('${dotenv.env['BACKEND']}/api/preferences');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'languages': languages,
        'objects': objects,
        'voice_speed': voiceSpeed,
      }),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getPreferences(String userId) async {
    final url = Uri.parse('${dotenv.env['BACKEND']}/api/preferences?user_id=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final api = PreferencesApi(dotenv.env['BACKEND']!);
  final authService = AuthService();

  String? _currentUserId;
  List<String> _selectedLanguages = [];
  List<String> _selectedObjects = [];
  double _voiceSpeed = 1.0;

  final List<String> _allLanguages = [
    'English', 'Arabic', 'Spanish', 'French', 'Hindi',
    'Urdu', 'Russian', 'German', 'Turkish', 'Japanese',
  ];

  final List<String> _allObjects = ['person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'];


  @override
  void initState() {
    super.initState();
    // Default first-time selections
    _selectedLanguages = ['English', 'Arabic'];
    _selectedObjects = List.from(_allObjects);
    _initUserAndPreferences();
  }

  Future<void> _initUserAndPreferences() async {
    final userId = await authService.getCurrentUserId();
    if (!mounted) return;
    setState(() => _currentUserId = userId);

    if (userId == null) return;
    final data = await api.getPreferences(userId);
    if (!mounted) return;

    if (data != null) {
      final savedLangs = List<String>.from(data['languages']);
      final savedObjs = List<String>.from(data['objects']);
      setState(() {
        if (savedLangs.isNotEmpty) _selectedLanguages = savedLangs;
        if (savedObjs.isNotEmpty) _selectedObjects = savedObjs;
        _voiceSpeed = (data['voice_speed'] as num).toDouble();
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_currentUserId == null) return;
    final success = await api.savePreferences(
      userId: _currentUserId!,
      languages: _selectedLanguages,
      objects: _selectedObjects,
      voiceSpeed: _voiceSpeed,
    );
    final msg = success ? 'Preferences saved.' : 'Failed to save.';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _pickMultiSelection({
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onConfirmed,
    required String title,
  }) async {
    final temp = List<String>.from(selected);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final isLangDialog = title == 'Text Recognition Languages';
                final isLockedLang = isLangDialog &&
                    (opt == 'English' || opt == 'Arabic');
                return CheckboxListTile(
                  value: temp.contains(opt),
                  title: Text(opt),
                  onChanged: isLockedLang
                      ? null
                      : (chk) {
                          setStateDialog(() {
                            if (chk == true) temp.add(opt);
                            else temp.remove(opt);
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirmed(temp);
              },
              child: Text('OK (${temp.length})'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 36,
            semanticLabel: 'Back',
            color: Colors.amberAccent,
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainPage()),
          ),
          padding: const EdgeInsets.all(16),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.amberAccent),
            onPressed: _savePreferences,
            tooltip: 'Save Preferences',
            padding: const EdgeInsets.all(16),
          ),
        ],
        toolbarHeight: 80,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 0, 0),
              Color.fromARGB(255, 52, 32, 57)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: ListView(
          children: [
            _buildMultiSelectTile(
              title: 'Text Recognition Languages',
              selected: _selectedLanguages,
              options: _allLanguages,
              onConfirmed: (sel) => setState(() => _selectedLanguages = sel),
            ),
            Divider(color: Colors.white24),
            _buildMultiSelectTile(
              title: 'Object Detection Preferences',
              selected: _selectedObjects,
              options: _allObjects,
              onConfirmed: (sel) => setState(() => _selectedObjects = sel),
            ),
            Divider(color: Colors.white24),
            ListTile(
              title: Text(
                'Voice Feedback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Slider(
                min: 0.5,
                max: 2.0,
                divisions: 15,
                value: _voiceSpeed,
                label: '\${_voiceSpeed.toStringAsFixed(1)}x',
                onChanged: (val) => setState(() => _voiceSpeed = val),
                activeColor: Colors.amberAccent,
              ),
            ),
            Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/tutorial');
                },
                child: Text(
                  'View Tutorial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => MainPage()),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectTile({
    required String title,
    required List<String> selected,
    required List<String> options,
    required ValueChanged<List<String>> onConfirmed,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: SizedBox(
        height: 40,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: selected.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(e),
                backgroundColor: Colors.amberAccent,
              ),
            )).toList(),
          ),
        ),
      ),
      onTap: () => _pickMultiSelection(
        options: options,
        selected: selected,
        title: title,
        onConfirmed: onConfirmed,
      ),
    );
  }
}
