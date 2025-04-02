import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final firestore = FirebaseFirestore.instance;
final behaviorsCollection = firestore.collection("cat_behaviors");
Map<String, DateTime> behaviorStartTimes = {};
DateTime? initialSleepDetectionTime; // เก็บเวลาที่เริ่มตรวจจับ sleep
bool isSleepRecorded = false; // ตัวแปรบอกว่า sleep ถูกบันทึกไปแล้วหรือยัง

void saveCatBehavior(String newBehavior, DateTime detectedTime, BuildContext context) async {
  try {
    Timestamp firestoreStartTime;
  
    // ดึงพฤติกรรมล่าสุดจากฐานข้อมูล
    final snapshot = await behaviorsCollection.orderBy("start_time", descending: true).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      final lastEntry = snapshot.docs.first;
      String lastBehavior = lastEntry["behavior"];

      // ถ้าพฤติกรรมใหม่ซ้ำกับพฤติกรรมก่อนหน้า
      if (newBehavior == lastBehavior) {
        // ถ้าพฤติกรรมเหมือนกัน จะไม่ทำอะไร
        return;
      }

      // ถ้าพฤติกรรมใหม่ไม่ซ้ำกับพฤติกรรมก่อนหน้า
      if (newBehavior != "sleep" && newBehavior != lastBehavior) {
      initialSleepDetectionTime = DateTime.now(); // รีเซ็ตเวลาใหม่เมื่อมีพฤติกรรมอื่น
      isSleepRecorded = false; // รีเซ็ตค่าให้กลับไปเริ่มรอ 3 นาทีอีกครั้ง
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⏳ Behavior changed, resetting timer...")),
      );

      firestoreStartTime = Timestamp.fromDate(detectedTime);

      await firestore.runTransaction((transaction) async {
        // อัปเดตพฤติกรรมก่อนหน้าให้มี end_time
        transaction.update(lastEntry.reference, {
          "end_time": Timestamp.fromDate(detectedTime),
        });

        // บันทึกพฤติกรรมใหม่ที่เปลี่ยนไป
        transaction.set(behaviorsCollection.doc(), {
          "behavior": newBehavior,
          "start_time": firestoreStartTime,
          "end_time": null,
        });
      });

      return;
    }


      // ถ้าพฤติกรรมใหม่เป็น "sleep"
      if (newBehavior == "sleep") {
        // ถ้ายังไม่ได้บันทึก sleep หรือรอเวลา 3 นาทีไม่ครบ
        if (!isSleepRecorded && (initialSleepDetectionTime == null || DateTime.now().isBefore(initialSleepDetectionTime!.add(Duration(minutes: 3))))) {
          // ถ้าเวลาน้อยกว่า 3 นาที จะไม่บันทึก แต่แสดงข้อความ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⏳ Waiting for 3 minutes before recording sleep...")),
          );
          return;
        }
         // รีเซ็ตเวลาหากครบ 3 นาทีหรือพฤติกรรมที่บันทึกใหม่
        firestoreStartTime = Timestamp.fromDate(detectedTime);
       

        await firestore.runTransaction((transaction) async {
          transaction.update(lastEntry.reference, {
            "end_time": Timestamp.fromDate(detectedTime),
          });

          // บันทึกพฤติกรรมใหม่เป็น "sleep"
          transaction.set(behaviorsCollection.doc(), {
            "behavior": "sleep",
            "start_time": firestoreStartTime,
            "end_time": null,
          });
        });
        initialSleepDetectionTime = DateTime.now();
        isSleepRecorded = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Sleep recorded.")),
        );
        return;
      }
    } else {
      // ถ้าไม่มีพฤติกรรมเก่าเลย (ครั้งแรกที่บันทึก)
      firestoreStartTime = Timestamp.fromDate(detectedTime);

      await behaviorsCollection.add({
        "behavior": newBehavior,
        "start_time": firestoreStartTime,
        "end_time": null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ First behavior recorded: $newBehavior")),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⚠️ Error saving behavior: $error")),
    );
  }
}
