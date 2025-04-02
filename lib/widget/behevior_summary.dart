import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:objectdetectioncat/service/function.dart';
import 'package:objectdetectioncat/service/get_data.dart';
import 'package:intl/intl.dart'; // ใช้จัดการเวลา

class ShowBehaviorWidget extends StatelessWidget {
  ShowBehaviorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime customDate = DateTime(2025, 2, 4); // กำหนดวันที่เอง (ปี, เดือน, วัน)
    String _todaydate = DateFormat('yyyy-MM-dd').format(customDate);

    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      stream: FirestoreService().fetchDataAndGroup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.active) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "ยังไม่มีข้อมูลของวันนี้",
                style: GoogleFonts.inter(fontSize: 20, color: Colors.grey),
              ),
            );
          }

          Map<String, List<Map<String, dynamic>>> groupedData = snapshot.data!;
          List<Map<String, dynamic>> behaviorForToday =
              groupedData[_todaydate] ?? [];

          // จับกลุ่มตาม behavior
          Map<String, List<Map<String, dynamic>>> groupedByBehavior = {};

          for (var behaviorData in behaviorForToday) {
            String behavior = behaviorData["behavior"];
            if (!groupedByBehavior.containsKey(behavior)) {
              groupedByBehavior[behavior] = [];
            }
            groupedByBehavior[behavior]!.add(behaviorData);
          }

          // คำนวณชั่วโมงรวมของ sleep
          Duration totalSleepDuration = calculateTotalSleepTime(
            groupedByBehavior['sleep'] ?? [],
          );
          int totalSleepHours = totalSleepDuration.inHours;
          int totalSleepMinutes = totalSleepDuration.inMinutes % 60;

          // พฤติกรรมที่ต้องการแสดง
          List<String> desiredBehaviors = ['sleep', 'eat', 'toilet'];

          return SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var behavior in desiredBehaviors)
                  if (groupedByBehavior.containsKey(behavior))
                    _buildBehaviorCircle(
                      behavior,
                      behavior == 'sleep'
                          ? "${totalSleepHours}h ${totalSleepMinutes}min"
                          : groupedByBehavior[behavior]!.length.toString(),
                      totalSleepHours, // ส่ง totalSleepHours เข้าไปที่ _buildBehaviorCircle
                    ),
              ],
            ),
          );
        }

        return Center(child: Text("Loading..."));
      },
    );
  }

  Widget _buildBehaviorCircle(
    String behavior,
    String value,
    int totalSleepHours,
  ) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Container(
        width: 120.0,
        height: 120.0,
        decoration: BoxDecoration(
          color:
              behavior == 'sleep'
                  ? getSleepColor(totalSleepHours) // ใช้ totalSleepHours
                  : behavior == 'toilet'
                  ? getToiletColor(int.tryParse(value) ?? 0)
                  : Color.fromARGB(255, 196, 225, 246),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // สีเงา
              offset: Offset(4, 4), // ตำแหน่งของเงา (ขวา-ล่าง)
              blurRadius: 5, // ความฟุ้งของเงา
              spreadRadius: 1, // ขยายขอบเงา
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text(
                behavior.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
