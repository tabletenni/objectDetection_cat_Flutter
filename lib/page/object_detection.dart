import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objectdetectioncat/service/database_save.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ObjectDetectionModel {
  late Interpreter _interpreter;
  late List<String> _labels;
  Function(String, double)? onDetectionResult;
  // โหลดโมเดล TFLite และ labels
  Future<void> loadModelAndLabels() async {
    try {
      print('Loading model and labels...');
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      _labels = await loadLabels();

      print(_labels);
      print('Model and labels loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  // โหลด labels จากไฟล์ text
  Future<List<String>> loadLabels() async {
    try {
      final labels = await rootBundle.loadString('assets/label.txt');
      return labels.split('\n').map((e) => e.trim()).toList();
    } catch (e) {
      print('Error loading labels: $e');
      throw Exception('Failed to load labels.');
    }
  }

  // รันโมเดลและทำการประมวลผล
  Future<Map<int, List<dynamic>>> runInference(
    List<List<List<List<double>>>> input,
  ) async {
    try {
      print('Running inference...');

      // Define the output structure to match the model
      var output0 = List.generate(
        1,
        (_) => List.generate(10, (_) => 0.0),
      ); // [1, 10]
      var output1 = List.generate(
        1,
        (_) => List.generate(10, (_) => List.generate(4, (_) => 0.0)),
      ); // [1, 10, 4]
      var output2 = [0.0]; // [1]
      var output3 = List.generate(
        1,
        (_) => List.generate(10, (_) => 0.0),
      ); // [1, 10]

      var outputs = {0: output0, 1: output1, 2: output2, 3: output3};

      // Run the model
      _interpreter.runForMultipleInputs([input], outputs);

      return outputs;
    } catch (e) {
      print('Error during inference: $e');
      // Throw an exception to ensure the method does not return null
      throw Exception('Error during inference: $e');
    }
  }

  /*
  // แปลง CameraImage ให้เป็น Uint8List
  Future<Uint8List> convertCameraImageToUint8List(CameraImage image) async {
    img.Image? imgFrame;
    imgFrame = convertBGRA8888(image);
    final pngBytes = img.encodePng(imgFrame);
    return Uint8List.fromList(pngBytes);
  }
  */
  // แปลง BGRA8888 เป็นภาพ RGB
  img.Image convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img.Format.bgra,
    );
  }

  // แปลง Uint8List ให้เป็น Float32 สำหรับ input โมเดล

  List<List<List<List<double>>>> preprocessImage(Uint8List imageBytes) {
    // ตรวจสอบว่า imageBytes ไม่ว่างเปล่า
    if (imageBytes.isEmpty) throw Exception('Image bytes are empty');

    // Decode image
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    // Resize image to
    final resizedImage = img.copyResize(image, width: 320, height: 320);

    // Normalize image to [0, 1] and create 4D tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        320,
        (y) => List.generate(320, (x) {
          final pixel = resizedImage.getPixel(x, y);

          // ดึงค่า RGB และ Normalize
          final red = img.getRed(pixel) / 255.0;
          final green = img.getGreen(pixel) / 255.0;
          final blue = img.getBlue(pixel) / 255.0;

          // ตรวจสอบค่าหลัง normalize ให้อยู่ในช่วง [0.0, 1.0]
          if (red < 0.0 ||
              red > 1.0 ||
              green < 0.0 ||
              green > 1.0 ||
              blue < 0.0 ||
              blue > 1.0) {
            throw Exception(
              'Pixel normalization out of range at ($x, $y): R=$red, G=$green, B=$blue',
            );
          }

          return [red, green, blue];
        }),
      ),
    );

    print('Input normalized to [0, 1] range.');
    return input;
  }

  Future<dynamic> runModelFromBytes(Uint8List imageBytes) async {
    try {
      final input = preprocessImage(imageBytes);
      final output = await runInference(input);
      print('Model inference result: $output');

      return output;
    } catch (e) {
      print('Error in runModelFromBytes: $e');
      rethrow;
    }
  }

  void processDetectionResults(
    Map<int, List<Object>> outputs,
    BuildContext context,
  ) async {
    var boxes = outputs[1]; // ข้อมูล bounding boxes
    var scores = outputs[0]; // ข้อมูลคะแนน
    var classId = outputs[3]; // ข้อมูลคลาส

    if (scores != null && scores is List<Object>) {
      // แปลง scores ให้เป็น List<List<double>>
      List<List<double>> convertedScores =
          scores.map((score) {
            if (score is List) {
              return score.map((e) => e is double ? e : 0.0).toList();
            } else {
              return <double>[];
            }
          }).toList();

      double maxScore = 0.0;
      int maxOuterIndex = -1;
      int maxInnerIndex = -1;

      for (int i = 0; i < convertedScores.length; i++) {
        List<double> scoreList = convertedScores[i];
        for (int j = 0; j < scoreList.length; j++) {
          double score = scoreList[j];
          if (score > maxScore) {
            maxScore = score;
            maxOuterIndex = i;
            maxInnerIndex = j;
          }
        }
      }

      // เช็คว่า maxScore มากกว่า 0.7 หรือไม่
      if (maxScore > 0.7) {
        // จัดการข้อมูล classId
        if (classId != null && classId is List<Object>) {
          List<List<double>> convertedClassId =
              classId.map((index) {
                if (index is List) {
                  return index.map((e) => e is double ? e : 0.0).toList();
                } else {
                  return <double>[];
                }
              }).toList();

          // ดึง classId ที่สัมพันธ์กับ maxScore
          if (maxOuterIndex >= 0 &&
              maxOuterIndex < convertedClassId.length &&
              maxInnerIndex >= 0 &&
              maxInnerIndex < convertedClassId[maxOuterIndex].length) {
            int detectedClassId =
                convertedClassId[maxOuterIndex][maxInnerIndex].toInt();

            // ดึงชื่อคลาสจากไฟล์ labels
            String className = await getLabelByClassId(detectedClassId);

            print(
              "Max Score: $maxScore and Class ID for Max Score: $className ($detectedClassId)",
            );
            DateTime startTime = DateTime.now();
            saveCatBehavior(className, startTime, context);
            if (onDetectionResult != null) {
              onDetectionResult!(className, maxScore);
            }
          }
        }
      } else {
        // แสดงข้อความเมื่อ maxScore น้อยกว่า 0.7
        print("Max Score is too low to display: $maxScore");
      }
    }
  }

  Future<String> getLabelByClassId(int classId) async {
    try {
      String content = await rootBundle.loadString('assets/label.txt');
      List<String> labels = content.split('\n').map((e) => e.trim()).toList();

      if (classId >= 0 && classId < labels.length) {
        return labels[classId];
      } else {
        return "Unknown Class";
      }
    } catch (e) {
      print("Error loading labels: $e");
      return "Error";
    }
  }
}
