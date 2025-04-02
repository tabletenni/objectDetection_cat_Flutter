import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:objectdetectioncat/page/homescreen.dart';
import 'package:objectdetectioncat/widget/navdar.dart';
import 'package:objectdetectioncat/page/object_detection.dart';

class Cameras extends StatefulWidget {
  const Cameras({super.key});

  @override
  State<Cameras> createState() => _CamerasState();
}

class _CamerasState extends State<Cameras> {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  late ObjectDetectionModel objectDetectionModel;
  ObjectDetectionModel objectDetectionModelresult = ObjectDetectionModel();

  DateTime?
  lastProcessedTime; // ประกาศตัวแปรสำหรับเก็บเวลาครั้งล่าสุดที่ประมวลผล

  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    objectDetectionModel.onDetectionResult = (
      String className,
      double maxScore,
    ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Detected: $className (Confidence: ${maxScore.toStringAsFixed(2)})",
          ),
          duration: Duration(seconds: 3),
        ),
      );
    };
  }

  Future<void> _initialize() async {
    try {
      objectDetectionModel = ObjectDetectionModel();
      await objectDetectionModel.loadModelAndLabels();
      await _setupCameraController();
    } catch (e) {
      print('Error initializing application: $e');
    }
  }

  Future<void> _setupCameraController() async {
    try {
      List<CameraDescription> _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        setState(() {
          cameras = _cameras;
          cameraController = CameraController(
            _cameras.first,
            ResolutionPreset.high,
          );
        });
        await cameraController?.initialize();
        setState(() {
          _isCameraInitialized = true;
        });

        cameraController?.startImageStream((CameraImage image) {
          if (!_isProcessing && _isCameraInitialized) {
            runModelOnFrame(image);
          }
        });
      }
    } catch (e) {
      print("Error setting up camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  appBar: AppBar(
     
      // ),
      body: Container(
        // ใช้ Container แทน Expanded
        width: double.infinity,
        height: double.infinity,
        child: _buildUI(),
      ),
    );
  }

Widget _buildUI() {
  if (cameraController == null || !_isCameraInitialized) {
    return const Center(child: CircularProgressIndicator());
  }

  // Get the screen height and width excluding the status bar and AppBar
  final screenHeight = MediaQuery.of(context).size.height -
      MediaQuery.of(context).padding.top - // Excluding status bar
      MediaQuery.of(context).viewInsets.bottom - // Excluding bottom space (keyboard)
      kBottomNavigationBarHeight -19; // Subtract the height of the bottom navigation bar

  final screenWidth = MediaQuery.of(context).size.width;

  return SafeArea(
    child: SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: screenHeight, // Use the available height after excluding navbar and keyboard
            width: screenWidth,    // Use the full width of the screen
            child: CameraPreview(cameraController!),
          ),
        ],
      ),
    ),
  );
}




  Future<void> runModelOnFrame(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // ตัวแปรสำหรับตรวจสอบเวลาครั้งล่าสุดที่ประมวลผล
    DateTime now = DateTime.now();
    if (lastProcessedTime != null &&
        now.difference(lastProcessedTime!).inMilliseconds < 5000) {
      // ถ้าเวลาผ่านไปน้อยกว่า 100 มิลลิวินาที ให้ข้ามการประมวลผล
      _isProcessing = false;
      return;
    }

    lastProcessedTime = now; // อัปเดตเวลาล่าสุดที่ประมวลผล

    try {
      // ตรวจสอบว่า convertedImage ไม่เป็น null
      var convertedImage = objectDetectionModel.convertBGRA8888(cameraImage);
      if (convertedImage == null) {
        print('Error: Converted image is null');
        return;
      }

      var processedImage = Uint8List.fromList(img.encodeJpg(convertedImage));
      var result = await objectDetectionModel.runModelFromBytes(processedImage);
      if (result == null) {
        print('Error: Result is null');
        return;
      }

      objectDetectionModel.processDetectionResults(result,context);
    } catch (e) {
      print('Error in runModelOnFrame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
