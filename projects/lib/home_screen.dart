import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'services/object_detection_services.dart';
import 'services/audio_transcirption_service.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import 'services/tesseract_text_recognizer.dart';
import 'package:projects/VisionAidChat.dart';
import 'services/scene_description_service.dart';
import 'risingtide_bottom_bar.dart';
import 'services/hazard_service.dart';
import 'settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import 'profile.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late CameraController _controller;
  late ObjectDetectionService _detector;
  Future<void>? _initializeControllerFuture;
  
  List<dynamic>? recognitions;
  List<dynamic>? recognitionsCache;
  int imageHeight = 0;
  int imageWidth = 0;

  bool _isDetecting = false;
  bool _shouldDetect = true;

  int _frameCount = 2;
  int frameSkip = 0; // Process every 3rd frame

  bool sdSpeechReady = false;
  bool ocrSpeechReady = false;

  bool isSDReading = false;
  bool isOCRReading = false;

  bool isWaitingRadiResponse = false;
  // Audio transcription service
  final TranscriptionService _transcriptionService = TranscriptionService();
  String? _transcript;
  bool _isRecording = false;
  bool OCR_camera = false;
  final Map<String, dynamic> _location = {"latitude": 0, "longitude": 0, "address": "Unknown"};
  final player = AudioPlayer();

  final ImagePicker _picker = ImagePicker();
  final TesseractTextRecognizer _recognizer = TesseractTextRecognizer();
  final translator = GoogleTranslator();

  final SceneDescriptionService _sceneDescriptionService = SceneDescriptionService();
  
  late final HazardService _hazardService;
  @override
  void initState() {
    super.initState();
    availableCameras().then((cams) {
      if (cams.isNotEmpty) {
        _initializeCamera(cams.first);
      }
    });
    _detector = ObjectDetectionService();
    _hazardService = HazardService();
    _detector.loadModel().then((_) => setState(() {}));
    _getCurrentLocation();
    player.onPlayerComplete.listen((event) {
    setState(() {
      isSDReading = false;
      isOCRReading = false;
    });
  });
    // Load available cameras and initialize the first one
    
  }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permissions are permanently denied")),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            "${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
        setState(() {
          _location["latitude"] = position.latitude;
          _location["longitude"] = position.longitude;
          _location["address"] = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }
  Future<void> _initializeCamera(CameraDescription camera) async {
    print('________!!!!______________Initializing camera');
    // if (_controller != null) {
    // await _controller.dispose();
    // }
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try{
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      await _controller.setFlashMode(FlashMode.off);
      print('____________mounted ');
      if (!mounted) return;

      if (_shouldDetect){
        _startImageStream();
      }
    } catch (e) {
      print("____Error initializing camera: $e");
    }

    

  }


  void _startImageStream() {
     if (!_controller.value.isStreamingImages) {
      print('!!!!!Starting image stream for object detection');
      _controller.startImageStream((CameraImage image) async {
        if (!_shouldDetect) return;
        // if (++_frameCount % frameSkip != 0) return;
        if (_isDetecting){ 
          recognitions = [];
          print("____modelalready running");
          return;
        }
        _isDetecting = true;
        try {

          final results = await _detector.runModel(image);
          debugPrint(">> callback resumed after await!");
          print(results);

          if (mounted && results != null && _shouldDetect) {
            setState(() {
              
              recognitions = results;
              imageWidth = image.width;
              imageHeight = image.height;
              _hazardService.handleRecognitions(recognitions);
              recognitionsCache = List.from(recognitionsCache ?? []);

              final timestamp = DateTime.now().toIso8601String(); // e.g., "2025-05-02T14:36:10.123Z"

              for (var result in results) {
              
              if (!recognitionsCache!.any((element) => element['detectedClass'] == result['detectedClass'])) {
                var rect = {
                  'x': num.parse(result['rect']['x'].toStringAsFixed(2)),
                  'y': num.parse(result['rect']['y'].toStringAsFixed(2)),
                  'w': num.parse(result['rect']['w'].toStringAsFixed(2)),
                  'h': num.parse(result['rect']['h'].toStringAsFixed(2)),
                };
                recognitionsCache!.add({
                  'detectedClass': result['detectedClass'] ?? 'Unknown',
                  'Confidence': (result['confidenceInClass'] ?? 0.0).toStringAsFixed(2),
                  'rect': rect,
                  'timestamp': timestamp,
                  
                });
              }
              }
            });
          }else{
            recognitions=[];
          }
        } catch (e) {
          print("____Error in image stream callback: $e");
        } finally {
          _isDetecting = false;
          print("____Model run complete, unlocking detector");
        }
      
      });
     }
  }
  
  Future<void> _stopImageStream() async {
  if (_controller.value.isStreamingImages) {
    await _controller.stopImageStream();
  }
  }
  Future<void> _handleMicPressed() async {
  if (_transcriptionService.isRecording) {
    print('__________stopping record');
    try{
    final audioFile = await _transcriptionService.stopRecording();
    setState(() {
        _isRecording = false;
        isWaitingRadiResponse = true;
      });

    if (audioFile != null) {
      final XFile imageFile = await _controller.takePicture();
      
      final mp3File = await _transcriptionService.transcribe(audioFile, imageFile.path,recognitionsCache, _location);
      
      if (mp3File != null) {

        print('_________got audio file at ${mp3File.path}');
        setState(() {
        isWaitingRadiResponse = false;
      });
        final player = AudioPlayer();
        await player.play(DeviceFileSource(mp3File.path));
      }
    }else{
      setState(() {
        isWaitingRadiResponse = false;
      });
    }
    }catch(e){
      print("error at mic $e");
    }
  } else {
    print('__________starting to record');
    setState(() => _isRecording = true);
    await _transcriptionService.startRecording();
    setState(() {
        isWaitingRadiResponse = false;
      });
  }
}

  void _startTextRecognitionFlow() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera_alt, size: 32),
                label: Text("Scan with Camera", style: TextStyle(fontSize: 22)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 70),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  setState(() {
                    OCR_camera = true;
                  });
                  print("OCR_camera: $OCR_camera");
                  // final picked = await _picker.pickImage(source: ImageSource.camera);
                  // if (picked != null) _processOCR(picked.path);

                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.image, size: 32),
                label: Text("Pick from Gallery", style: TextStyle(fontSize: 22)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 70),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) _processOCR(picked.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _processOCR(String imagePath) async {
  // 1. Show an initial “processing” spinner while OCR runs
  showDialog(
    context: context,
    builder: (_) => Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  // 2. Run OCR to get the originalText
  final originalText = await _recognizer.sendImageForOcr(imagePath);
  print("RECEIVED original " + originalText);
  // 3. Dismiss the “processing” spinner
  Navigator.pop(context);

  if (originalText.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No text found in the image.")),
    );
    return;
  }

  // 4. Prepare all the state variables for the dialog:
  String displayText = originalText;
  bool isTranslated = false;
  bool isRefining = true;
  bool hasRefineStarted = false;

  // 5. Show the dialog with StatefulBuilder so we can update it later
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        // a) Kick off the refine call exactly once, right after the first frame
        if (!hasRefineStarted) {
          hasRefineStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              print("SENDING FOR REFINEMENT: "+ originalText);
              final refined = await refineOcrText(originalText);
              print("REFINED TEXT: "+ refined);
              setState(() {
                displayText = refined;
                isRefining = false;
                isOCRReading = true;
                ocrSpeechReady = false;
              });
              _speakOCR(refined);
            } catch (e) {
              // If refining fails, we simply stop showing the spinner
              setState(() {
                isRefining = false;
              });
            }
          });
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Stack(
              children: [
                // ───────────────────────────────────────────────────────────────
                // The main column (raw or refined text + buttons)
                // ───────────────────────────────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRefining ? "Refining Text(Please Wait)":
                      isTranslated
                          ? "\u0627\u0644\u0646\u0635 \u0627\u0644\u0645\u062a\u0631\u062c\u0645"
                          : "Recognized Text",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Text(
                          displayText,
                          textDirection:
                              isTranslated ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                                if (!isOCRReading) {
                                  setState(() => isOCRReading = true);
                                  _speakOCR(displayText);
                                } else {
                                  _stopAudio();
                                  setState(() => isOCRReading = false);
                                }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: Size(100, 50),
                            ),
                            child: Text(!isOCRReading ? "Read Aloud" : "Stop Reading", style: TextStyle(fontSize: 18, color: Colors.yellow)),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: displayText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Copied to Clipboard", style: TextStyle(color: Colors.yellow))),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            minimumSize: Size(100, 50),
                          ),
                          child: Text("Copy", style: TextStyle(fontSize: 18, color: Colors.yellow)),
                        ),
                        ElevatedButton(
                          onPressed: isRefining
                              ? null
                              : () async {
                                  final translated =
                                      await translator.translate(displayText, to: 'ar');
                                  setState(() {
                                    displayText = translated.text;
                                    isTranslated = true;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRefining ? Colors.grey : Colors.orange,
                            minimumSize: Size(100, 50),
                          ),
                          child: Text("Translate", style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close"),
                    )
                  ],
                ),

                // ───────────────────────────────────────────────────────────────
                // Overlay a small CircularProgressIndicator while refining
                // Positioned in the top-right corner, so it doesn’t obscure the text.
                // ───────────────────────────────────────────────────────────────
                if (isRefining)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
    barrierDismissible: false,
  );
}
void _speakSD(String text) async{
 
  if (isSDReading && !sdSpeechReady) {
    print('__________stopping record');
    final audioFile = await _transcriptionService.tts(text);
    
    print('_________got audio file at ${audioFile}');
    await player.play(DeviceFileSource(audioFile));
    setState(() {
      sdSpeechReady = true;
    });
  } else if (isSDReading && sdSpeechReady) {
    final dir = await getApplicationDocumentsDirectory();
    await player.play(DeviceFileSource('${dir.path}/downloaded_tts.mp3'));
    
  }
}

void _speakOCR(String text) async{
 
  if (isOCRReading && !ocrSpeechReady) {
    print('__________stopping record');
    final audioFile = await _transcriptionService.tts(text);
    
    print('_________got audio file at ${audioFile}');
    await player.play(DeviceFileSource(audioFile));
    setState(() {
      ocrSpeechReady = true;
    });
  } else if (isOCRReading && ocrSpeechReady) {
    final dir = await getApplicationDocumentsDirectory();
    await player.play(DeviceFileSource('${dir.path}/downloaded_tts.mp3'));

  }
}

void _stopAudio() async{
  await player.stop();
}
void _startSDFlow()  async{

    showDialog(
      context: context,
      builder: (_) => Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    if (!_controller!.value.isInitialized) {
      print("Camera not initialized.");
      return;
    }

    final XFile file = await _controller.takePicture();
    String text = await _sceneDescriptionService.sendImageForSD(file.path);
    Navigator.pop(context);
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No scene data found.")),
      );
      return;
    } else{
      setState(() {
        isSDReading = true;
        sdSpeechReady = false;
      });
      _speakSD(text);
    }
    print("Captured image path: ${file.path}");


    bool isTranslatedSD = false;
    String displayTextSD = text;

    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Stack(
                children: [
                  // ───────────────────────────────────────────────────────────────
                  // The main column (raw or refined text + buttons)
                  // ───────────────────────────────────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isTranslatedSD
                            ? "\u0648\u0635\u0641 \u0627\u0644\u0645\u0634\u0647\u062f"
                            : "Scene",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Text(
                            displayTextSD,
                            textDirection:
                                isTranslatedSD ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                                if (!isSDReading) {
                                  setState(() => isSDReading = true);
                                  _speakSD(displayTextSD);
                                } else {
                                  _stopAudio();
                                  setState(() => isSDReading = false);
                                }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: Size(100, 50),
                            ),
                            child: Text(!isSDReading ? "Read Aloud" : "Stop Reading", style: TextStyle(fontSize: 18, color: Colors.yellow)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: displayTextSD));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copied to Clipboard", style: TextStyle(color: Colors.yellow))),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: Size(100, 50),
                            ),
                            child: Text("Copy", style: TextStyle(fontSize: 18, color: Colors.yellow)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                                    final translated =
                                        await translator.translate(displayTextSD, to: 'ar');
                                    setState(() {
                                      displayTextSD = translated.text;
                                      isTranslatedSD = true;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              minimumSize: Size(100, 50),
                            ),
                            child: Text("Translate", style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Close"),
                      )
                    ],
                  ),

                 
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
     _stopImageStream();
  _controller.dispose();
  _detector.dispose();
  _hazardService.dispose();
  super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(221, 34, 32, 69),
    resizeToAvoidBottomInset: false,
    extendBody: true,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Camera preview expands to fill available vertical space
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _initializeControllerFuture == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.done) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LayoutBuilder(
                              builder: (ctx, constraints) {
                                return AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CameraPreview(_controller!),
                                      CustomPaint(
                                        painter: BoundingBoxPainter(
                                          recognitions ?? [],
                                          imageHeight,
                                          imageWidth,
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
            ),
          ),

          // A bit of spacing before the control row
          const SizedBox(height: 10),

          // Control tiles row
   SafeArea(
  top: false,
  bottom: true, // push content up above the bar
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Scene Description tile
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _startSDFlow,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD1A000), Color(0xFF9C6B00)], // slightly brighter gold to amber
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16), // reduced radius for clearer shape
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Scene",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Detection toggle tile
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    _shouldDetect = !_shouldDetect;
                    recognitions = [];
                  });
                  if (_shouldDetect) {
                    _startImageStream();
                  } else {
                    await _stopImageStream();
                  }
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient:const LinearGradient(
                            colors: [Color(0xFF4A80B4), Color(0xFF2F5485)], // balanced blue to navy
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                       ,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _shouldDetect ? Icons.stop_circle : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Detection",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // OCR/Text Recognition tile
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: !OCR_camera
                    ? _startTextRecognitionFlow
                    : () async {
                        try {
                          if (!_controller!.value.isInitialized) return;
                          final XFile file = await _controller.takePicture();
                          _processOCR(file.path);
                          setState(() => OCR_camera = false);
                        } catch (e) {
                          debugPrint("Error capturing image: \$e");
                        }
                      },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF896391), Color(0xFF4E394B)], // moderately muted purple to dark gray
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          OCR_camera ? "Capture" : "Text",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: OCR_camera? Colors.red: Colors.white,
                          ),
                        ),
                        Text(
                          OCR_camera ? "Text" : "Recognition",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: OCR_camera? Colors.red: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 0),
    ],
  ),
),

          // Small bottom gap above the bar
          const SizedBox(height: 10),
        ],
      ),
    ),

    bottomNavigationBar: RisingTideBottomBar(
      isRecording: _isRecording,
      isLoading: isWaitingRadiResponse,
      onHomeTap: () { /* navigate home */ },
      onChatTap: () async {
        await _stopImageStream();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VisionAidChat()),
        );
      },
      onSettingsTap: () async {
        await _stopImageStream();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen()),
        );
      },
      onAvatarTap: () async {
        await _stopImageStream();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
      },
      onMicPressed: _handleMicPressed,
    ),
  );
}



}


class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double bulgeRadius = 35; // Reduced bulge radius
    final double cx = size.width / 2;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(cx - bulgeRadius, 0)
      ..arcToPoint(
        Offset(cx + bulgeRadius, 0),
        radius: Radius.circular(bulgeRadius),
        clockwise: false,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}



class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> recognitions;
  final int imageHeight, imageWidth;
  final double screenWidth, screenHeight;

  /// List of detected classes that represent safety hazards
  final List<String> safetyHazard = [
    "scissors",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "stop sign",
    "parking meter",
  ];

  BoundingBoxPainter(
    this.recognitions,
    this.imageHeight,
    this.imageWidth,
    this.screenWidth,
    this.screenHeight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (var obj in recognitions) {
      final detectedClass = obj['detectedClass'] as String;
      final isHazard = safetyHazard.contains(detectedClass);

      // choose border and text color based on hazard
      final borderColor = isHazard ? Colors.red : Colors.green;
      final textColor = isHazard ? Colors.red : Colors.green;

      // configure paint for rectangle
      final paintRect = Paint()
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..color = borderColor;

      // calculate box coordinates
      final x = obj['rect']['x'] * screenWidth;
      final y = obj['rect']['y'] * screenHeight;
      final w = obj['rect']['w'] * screenWidth;
      final h = obj['rect']['h'] * screenHeight;

      // draw bounding box
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paintRect);

      // prepare label text
      final label = "$detectedClass ${(obj['confidenceInClass'] * 100).toStringAsFixed(0)}%";
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            background: Paint()..color = Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);

      // draw label above the box
      textPainter.paint(canvas, Offset(x, y - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter old) {
    return old.recognitions != recognitions;
  }
}
