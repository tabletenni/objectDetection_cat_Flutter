import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Duration calculateTotalSleepTime(List<Map<String, dynamic>> sleepData) {
  Duration totalSleepTime = Duration();

  for (var sleep in sleepData) {
    var startTimeStr = sleep['start_time'];
    var endTimeStr = sleep['end_time'];

    if (startTimeStr != null && endTimeStr != null) {
      try {
        DateTime startTime;
        DateTime endTime;

        // จัดการการแปลงเวลาจาก Timestamp หรือรูปแบบ HH:mm
        if (startTimeStr is Timestamp) {
          startTime = (startTimeStr as Timestamp).toDate();
        } else {
          startTime = DateFormat('HH:mm').parse(startTimeStr);
        }

        if (endTimeStr is Timestamp) {
          endTime = (endTimeStr as Timestamp).toDate();
        } else {
          endTime = DateFormat('HH:mm').parse(endTimeStr);
        }

        // คำนวณความแตกต่างของเวลา
        Duration sleepDuration = endTime.difference(startTime);
        totalSleepTime += sleepDuration;

        // แสดง log ของการคำนวณ
        //  print("⏰ Time Calculation: Start: $startTime, End: $endTime, Duration: ${sleepDuration.inMinutes} minutes");
      } catch (e) {
        print("Error parsing time: $e");
      }
    }
  }

  print(
    "📊 Total Sleep Duration Calculated: ${totalSleepTime.inHours} hours and ${totalSleepTime.inMinutes % 60} minutes",
  );

  return totalSleepTime;
}

Color getSleepColor(int totalSleepHours) {
  if (totalSleepHours >= 12 && totalSleepHours <= 14) {
    return Color.fromARGB(255, 172, 215, 147); // นอนปกติ
  }
  if ((totalSleepHours >= 10 && totalSleepHours < 11) || (totalSleepHours >= 15 && totalSleepHours < 20)) {
    return Color.fromARGB(255, 254, 238, 145); // นอนเกือบมากไปหรือน้อยไป
  } 
  if (totalSleepHours < 10 || totalSleepHours >= 20) {
    return Color.fromARGB(255, 241, 90, 89); // นอนน้อยเกินไปหรือนอนมากเกินไป
  }
  return Color.fromARGB(255, 196, 225, 246); // ค่าที่ไม่ได้อยู่ในเงื่อนไขใดๆ (ควรไม่เกิดขึ้น)
}

Color getToiletColor(int count) {
  if (count == 1 || count == 2) {
    return Color.fromARGB(255, 172, 215, 147); // ปกติ
  } else if (count == 3) {
    return Color.fromARGB(255, 254, 238, 145); // ค่อนข้างบ่อย
  } else if (count < 1 || count > 4) {
    return Color.fromARGB(255, 241, 90, 89); // น้อยเกินไปหรือมากเกินไป
  }
  return Color.fromARGB(255, 196, 225, 246); // ค่าอื่น ๆ (ควรไม่เกิดขึ้น)
}
