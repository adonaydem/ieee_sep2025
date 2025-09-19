import 'dart:async';
import 'package:camera/camera.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'dart:typed_data';                  // for Uint8List

import 'package:flutter/foundation.dart';   // for debugPrint, list utilities
import 'package:flutter/material.dart';     // Flutter core
      // TFLite.detectObjectOnFrame
class ObjectDetectionService {
  bool isModelLoaded = false;
  
  // Duration smoothingDuration;
  
  List<dynamic>? _lastRecognitions;
  // Timer? _detectionTimer;

  // ObjectDetectionService({
  //   // this.frameSkip = 1,
  //   // this.smoothingDuration = const Duration(milliseconds: 300),
  // });

  /// Exactly your loadModel() implementation
  Future<void> loadModel() async {
    print('_________Loading model...');
    String? res = await Tflite.loadModel(
      model: 'assets/yolo11n_float32.tflite',
      labels: 'assets/yolov2_tiny.txt',
    );
    print('______________Model loading result: $res');
    isModelLoaded = res != null;
    print('_____________isModelLoaded: $isModelLoaded');
  }
 

List<Uint8List> _compactYuvPlanes3(CameraImage image) {
  final int w = image.width, h = image.height;

  // --- Y plane (full res) ---
  final pY = image.planes[0];
  final yBytes = Uint8List(w * h);
  int dst = 0;
  for (int row = 0; row < h; row++) {
    final rowStart = row * pY.bytesPerRow;
    yBytes.setRange(dst, dst + w, pY.bytes, rowStart);
    dst += w;
  }

  // --- VU interleaved (half res) ---
  final pU = image.planes[1], pV = image.planes[2];
  final w2 = w >> 1, h2 = h >> 1;
  final vuBytes = Uint8List(w2 * h2 * 2);
  dst = 0;
  for (int row = 0; row < h2; row++) {
    final uStart = row * pU.bytesPerRow;
    final vStart = row * pV.bytesPerRow;
    for (int col = 0; col < w2; col++) {
      // NV21 = V then U
      vuBytes[dst++] = pV.bytes[vStart + col * pV.bytesPerPixel!];
      vuBytes[dst++] = pU.bytes[uStart + col * pU.bytesPerPixel!];
    }
  }

  // Now return 3 planes so plugin.index(2) exists:
  return [yBytes, vuBytes, vuBytes];
}


  /// Exactly your runModel() implementation
  Future<List<dynamic>?> runModel(CameraImage image) async {
    print('____!!!!!_____Starting to run model inference');
    
    if (image.planes.isEmpty) {
      print("_______!!!!__image plane empty");
    }
    
    try {
   final bytesList = _compactYuvPlanes3(image);
final results = await Tflite.detectObjectOnFrame(
  bytesList: bytesList, 
        model: 'YOLO',
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 2,
        threshold: 0.6,
        rotation: 90,  // Android only
      );
      print('_________Finished running model inference');
      // smoothing logic
      if (results != null && results.isNotEmpty) {
        print('_________Found results');
        _lastRecognitions = results;
        // _detectionTimer?.cancel();
        // _detectionTimer = Timer(smoothingDuration, () {
        //   print('_________Smoothing finished');
        //   _lastRecognitions = null;
        // });
        
        print('_________lastRecognitions: $_lastRecognitions');
        return _lastRecognitions;
      }
      return _lastRecognitions;

    } catch (e) {
      print("Error running model inference: $e");
      return [];
    } finally {
      print('_________Finished model inference');
     
    }
  }

  void dispose() {
    // _detectionTimer?.cancel();
    Tflite.close();
  }
}