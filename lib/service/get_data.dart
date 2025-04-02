import 'package:cloud_firestore/cloud_firestore.dart';
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, List<Map<String, dynamic>>>> fetchDataAndGroup() {
  try {
    print("Fetching data from Firestore...");
    
    // ใช้ snapshot เป็น stream จาก Firestore
    Stream<QuerySnapshot> snapshotStream = _firestore.collection("cat_behaviors").snapshots();
    
    // คืนค่าจาก stream
    return snapshotStream.map((snapshot) {
      // เก็บข้อมูลที่ดึงมาทั้งหมด
      List<Map<String, dynamic>> behaviorData = snapshot.docs.map((doc) {
        return {
          "behavior": doc['behavior'],
          "start_time": doc['start_time'],
          "end_time": doc['end_time'],
        };
      }).toList();

      // จัดกลุ่มข้อมูลตามวัน
      Map<String, List<Map<String, dynamic>>> groupedDate = {};

      for (var data in behaviorData) {
        Timestamp startTime = data["start_time"];
        DateTime startDate = startTime.toDate();
        String dateKey = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}"; // รูปแบบ: yyyy-MM-dd

        // ตรวจสอบว่า key นี้มีอยู่แล้วในกลุ่มหรือไม่
        if (!groupedDate.containsKey(dateKey)) {
          groupedDate[dateKey] = [];
        }

        // เพิ่มข้อมูลในกลุ่มตามวันที่
        groupedDate[dateKey]!.add(data);
      }

      return groupedDate;
    });
  } catch (e) {
    print("Error getting and grouping user behavior data: $e");
    // ส่งค่า stream ว่างหากเกิดข้อผิดพลาด
    return Stream.value({});
  }
}

}
