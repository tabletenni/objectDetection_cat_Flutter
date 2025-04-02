import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:objectdetectioncat/service/get_data.dart';

class HistoryDataPerDate extends StatefulWidget {
  final String dateSelected;

  const HistoryDataPerDate({super.key, required this.dateSelected});

  @override
  _HistoryDataPerDateState createState() => _HistoryDataPerDateState();
}

class _HistoryDataPerDateState extends State<HistoryDataPerDate> {
  final FirestoreService firestoreService = FirestoreService(); 

  String formatTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy HH:mm').format(dateTime); 
  }

  // การใช้ StreamBuilder เพื่อดึงข้อมูลแบบ real-time จาก Firestore
  Stream<List<Map<String, dynamic>>> getDataForSelectedDate(String date) {
    return firestoreService.fetchDataAndGroup().map((allData) {
      return allData[date] ?? []; // คืนค่าข้อมูลจากวันที่ที่เลือก
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ประวัติของวันที่ ${widget.dateSelected}"),
        backgroundColor: Color.fromARGB(255, 227, 221, 197),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getDataForSelectedDate(widget.dateSelected),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("ไม่มีข้อมูลในวันนี้"));
          }

          List<Map<String, dynamic>> behaviors = snapshot.data!;

          return ListView.builder(
            itemCount: behaviors.length,
            itemBuilder: (context, index) {
              var item = behaviors[index];
              return ListTile(
                title: Text("${item['behavior']}".toUpperCase(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "Start time: ${formatTime(item['start_time'])} \nEnd time: ${formatTime(item['end_time'])}",
                  style: GoogleFonts.inter(fontSize: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
