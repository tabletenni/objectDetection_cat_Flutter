import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:objectdetectioncat/page/graphpage.dart';
import 'package:objectdetectioncat/page/historypage.dart';
import 'package:objectdetectioncat/widget/behevior_summary.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  //  DateTime customDate = DateTime(2025, 2, 4); // กำหนดวันที่เอง (ปี, เดือน, วัน)
  //   String todaydate = DateFormat('dd MMMM yyyy').format(customDate);
  //ustomDate
 // String _todaydate = DateFormat('dd MMMM yyyy').format(DateTime.now());
  @override
  Widget build(BuildContext context) {
    DateTime customDate = DateTime(2025, 2, 4); // กำหนดวันที่เอง (ปี, เดือน, วัน)
    String _todaydate = DateFormat('dd MMMM yyyy').format(customDate);
    return DefaultTabController(
      length: 2, // กำหนดจำนวนแท็บ
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 227, 221, 197),
          title: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),
                Text(
                  _todaydate,
                  style: TextStyle(fontSize: 22, color: Colors.black),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          toolbarHeight: 80,
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 5, top: 10),
              child: ShowBehaviorWidget(),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 136, 158, 115),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5), // สีเงา
                            spreadRadius: 1, // การกระจายของเงา
                            blurRadius: 5, // ความเบลอของเงา
                            offset: Offset(0, 2), // ตำแหน่งของเงา
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('ปกติ'),
                  ],
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 244, 215, 147),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5), // สีเงา
                            spreadRadius: 1, // การกระจายของเงา
                            blurRadius: 5, // ความเบลอของเงา
                            offset: Offset(0, 2), // ตำแหน่งของเงา
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('สุ่มเสี่ยง'),
                  ],
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 169, 74, 74),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5), // สีเงา
                            spreadRadius: 1, // การกระจายของเงา
                            blurRadius: 5, // ความเบลอของเงา
                            offset: Offset(0, 2), // ตำแหน่งของเงา
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('ผิดปกติ'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '** พฤติกรรมการกินไม่มีเงื่อนไข',
              style: TextStyle(fontSize: 15, color: Colors.redAccent),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Color.fromARGB(255, 185, 178, 138),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Color.fromARGB(255, 248, 243, 217),
                  indicator: BoxDecoration(
                    color: Color.fromARGB(255, 227, 221, 197),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: Colors.brown[700],
                  labelStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(
                      text: 'Graph',
                    ), // แก้เป็น Tab() เพื่อให้ใช้ได้กับ TabBarView
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),

            // TabBarView
            Expanded(child: TabBarView(children: [GraphPage(), HistoryPgae()])),
          ],
        ),
      ),
    );
  }
}
