import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:objectdetectioncat/service/function.dart';
import 'package:objectdetectioncat/service/get_data.dart';

class GraphWidget extends StatefulWidget {
  @override
  _GraphWidgetState createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
   StreamSubscription? _streamSubscription; 
  Map<String, Map<String, List<Map<String, dynamic>>>> groupedByDate =
      {}; // ตัวแปรสำหรับเก็บข้อมูลที่จัดกลุ่มตามวันที่และพฤติกรรม

  @override
  void initState() {
    super.initState();
    fetchAndDisplayData(); // เรียกใช้ฟังก์ชันเมื่อเริ่มต้น
  }

  void fetchAndDisplayData() {
  FirestoreService firestoreService = FirestoreService();

  _streamSubscription = firestoreService.fetchDataAndGroup().listen((groupedData) {
    List<String> desiredBehaviors = ['eat', 'toilet', 'sleep'];
    Map<String, Map<String, List<Map<String, dynamic>>>> tempGroupedByWeek = {};
    DateTime customDate = DateTime(2025, 2, 4); // กำหนดวันที่เอง (ปี, เดือน, วัน)
   // String _todaydate = DateFormat('yyyy-MM-dd').format(customDate);
    int currentWeek = getWeekOfYear(customDate);

    // จัดกลุ่มข้อมูลตามสัปดาห์และพฤติกรรม
    for (var behavior in desiredBehaviors) {
      for (var dateData in groupedData.values.expand((dateData) => dateData)) {
        Timestamp timestamp = dateData['start_time'];
        DateTime startDate = timestamp.toDate();

        // Log วันที่ที่ดึงข้อมูลมา
        print('ดึงข้อมูลจากวันที่: $startDate สำหรับพฤติกรรม: $behavior');

        int weekOfYear = getWeekOfYear(startDate);
        String weekKey = "${startDate.year}-W$weekOfYear"; // ใช้ year + week

        if (weekOfYear == currentWeek) {
          // ใช้เฉพาะสัปดาห์ปัจจุบัน
          tempGroupedByWeek.putIfAbsent(weekKey, () => {});

          tempGroupedByWeek[weekKey]!.putIfAbsent(behavior, () => []);

          // ตรวจสอบพฤติกรรมและเพิ่มข้อมูล
          if (dateData['behavior'] == behavior) {
            // เพิ่มข้อมูลเฉพาะถ้ายังไม่เคยมีข้อมูลเดียวกันในวันนั้น
            bool alreadyAdded = tempGroupedByWeek[weekKey]![behavior]!.any(
              (existingData) =>
                  existingData['start_time'] == dateData['start_time'],
            );

            if (!alreadyAdded) {
              tempGroupedByWeek[weekKey]![behavior]!.add(dateData);
              // Log ข้อมูลที่ถูกเพิ่ม
              print('เพิ่มข้อมูล: $behavior, วันที่: $startDate');
            }
          }
        }
      }
    }

    // ตรวจสอบว่าข้อมูลใหม่ถูกโหลด
    print('groupedByDate: $tempGroupedByWeek');

    // อัพเดตเฉพาะเมื่อมีการเปลี่ยนแปลงข้อมูล
    if (groupedByDate != tempGroupedByWeek) {
      setState(() {
        groupedByDate = tempGroupedByWeek;
      });
    }
  });
}

  int getWeekOfYear(DateTime date) {
    // คำนวณสัปดาห์ตาม ISO 8601
    DateTime startOfYear = DateTime(date.year, 1, 1);
    int dayOfYear = date.difference(startOfYear).inDays + 1;

    // เริ่มต้นจากวันจันทร์
    int weekOfYear =
        ((dayOfYear - 1 + (startOfYear.weekday - 1)) / 7).floor() + 1;

    return weekOfYear;
  }

  // ฟังก์ชันคำนวณสัปดาห์ของปี
  List<FlSpot> getSleepDataForChart(String weekKey) {
    List<FlSpot> spots = [];

    if (!groupedByDate.containsKey(weekKey)) return spots;

    Map<String, List<Map<String, dynamic>>> behaviors = groupedByDate[weekKey]!;

    if (behaviors.containsKey('sleep')) {
      List<Map<String, dynamic>> sleepData = behaviors['sleep']!;

      Map<int, double> sleepByDate = {}; // เก็บข้อมูลเวลานอนรวมของแต่ละวัน

      for (var data in sleepData) {
        Timestamp timestamp = data['start_time'];
        DateTime startDate = timestamp.toDate();
        int dayOfMonth = startDate.day; // ใช้วันที่ของเดือนเป็นค่า X

        Duration totalSleepTime = calculateTotalSleepTime([
          data,
        ]); // ฟังก์ชันคำนวณเวลานอน
        double hoursOfSleep = totalSleepTime.inHours.toDouble();

        // รวมเวลานอนของแต่ละวัน
        if (sleepByDate.containsKey(dayOfMonth)) {
          sleepByDate[dayOfMonth] =
              (sleepByDate[dayOfMonth]! + hoursOfSleep); // บวกชั่วโมงการนอน
        } else {
          sleepByDate[dayOfMonth] = hoursOfSleep;
        }
      }

      // ใช้ Set เพื่อตรวจสอบไม่ให้เพิ่มวันที่ซ้ำ
      Set<int> addedDays = {}; // Set สำหรับเก็บวันที่ที่เพิ่มไปแล้ว

      // เรียงลำดับวันที่ตามลำดับที่ถูกต้อง
      List<int> sortedDays = sleepByDate.keys.toList()..sort();

      print(sortedDays);
      sortedDays.forEach((day) {
        if (!addedDays.contains(day)) {
          addedDays.add(day); // เพิ่มวันที่ที่เพิ่มแล้ว
          spots.add(
            FlSpot(day.toDouble(), sleepByDate[day]!),
          ); // เพิ่มข้อมูลลงในกราฟ
        }
      });
      print(spots);
    }

    return spots;
  }

  List<BarChartGroupData> getEatingDataForChart(String weekKey) {
    List<BarChartGroupData> barGroups = [];

    if (!groupedByDate.containsKey(weekKey)) return barGroups;

    Map<String, List<Map<String, dynamic>>> behaviors = groupedByDate[weekKey]!;

    if (behaviors.containsKey('eat')) {
      List<Map<String, dynamic>> eatData = behaviors['eat']!;

      Map<int, int> eatCountByDate = {}; // เก็บข้อมูลจำนวนการกินของแต่ละวัน

      for (var data in eatData) {
        Timestamp timestamp = data['start_time'];
        DateTime startDate = timestamp.toDate();
        int dayOfMonth = startDate.day; // ใช้วันที่ของเดือนเป็นค่า X

        // นับจำนวนการกินในแต่ละวัน
        if (eatCountByDate.containsKey(dayOfMonth)) {
          eatCountByDate[dayOfMonth] = eatCountByDate[dayOfMonth]! + 1;
        } else {
          eatCountByDate[dayOfMonth] = 1;
        }
      }

      // ใช้ Set เพื่อตรวจสอบไม่ให้เพิ่มวันที่ซ้ำ
      Set<int> addedDays = {}; // Set สำหรับเก็บวันที่ที่เพิ่มไปแล้ว

      // เรียงลำดับวันที่ตามลำดับที่ถูกต้อง
      List<int> sortedDays = eatCountByDate.keys.toList()..sort();

      sortedDays.forEach((day) {
        if (!addedDays.contains(day)) {
          addedDays.add(day); // เพิ่มวันที่ที่เพิ่มแล้ว
          barGroups.add(
            BarChartGroupData(
              x: day, // วันที่เป็นแกน X
              barRods: [
                BarChartRodData(
                  toY: eatCountByDate[day]!.toDouble(), // จำนวนการกินเป็นค่า Y
                  color: Color.fromARGB(255, 113, 43, 117), // สีของแท่ง
                  width: 20, // ความกว้างของแท่ง
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            ),
          );
        }
      });
    }

    return barGroups;
  }

  List<BarChartGroupData> getToietDataForChart(String weekKey) {
    List<BarChartGroupData> barGroups = [];

    if (!groupedByDate.containsKey(weekKey)) return barGroups;

    Map<String, List<Map<String, dynamic>>> behaviors = groupedByDate[weekKey]!;

    if (behaviors.containsKey('toilet')) {
      List<Map<String, dynamic>> eatData = behaviors['toilet']!;

      Map<int, int> eatCountByDate = {}; // เก็บข้อมูลจำนวนการกินของแต่ละวัน

      for (var data in eatData) {
        Timestamp timestamp = data['start_time'];
        DateTime startDate = timestamp.toDate();
        int dayOfMonth = startDate.day; // ใช้วันที่ของเดือนเป็นค่า X

        // นับจำนวนการกินในแต่ละวัน
        if (eatCountByDate.containsKey(dayOfMonth)) {
          eatCountByDate[dayOfMonth] = eatCountByDate[dayOfMonth]! + 1;
        } else {
          eatCountByDate[dayOfMonth] = 1;
        }
      }

      // ใช้ Set เพื่อตรวจสอบไม่ให้เพิ่มวันที่ซ้ำ
      Set<int> addedDays = {}; // Set สำหรับเก็บวันที่ที่เพิ่มไปแล้ว

      // เรียงลำดับวันที่ตามลำดับที่ถูกต้อง
      List<int> sortedDays = eatCountByDate.keys.toList()..sort();

      sortedDays.forEach((day) {
        if (!addedDays.contains(day)) {
          addedDays.add(day); // เพิ่มวันที่ที่เพิ่มแล้ว
          barGroups.add(
            BarChartGroupData(
              x: day, // วันที่เป็นแกน X
              barRods: [
                BarChartRodData(
                  toY: eatCountByDate[day]!.toDouble(), // จำนวนการกินเป็นค่า Y
                  color: Color.fromARGB(255, 43, 52, 103), // สีของแท่ง
                  width: 20, // ความกว้างของแท่ง
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            ),
          );
        }
      });
    }

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          groupedByDate.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ยังไม่มีข้อมูลของวันนี้',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                SizedBox(height: 20),
              ],
            ),
          )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // แสดงกราฟสำหรับข้อมูลการนอนของวันนี้
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Column(
                        children: [
                          Text(
                            'จำนวนชั่วโมงการนอนในแต่ละวันใน 1 สัปดาห์' ,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 350, // กำหนดความกว้างของกราฟ
                              height: 300, // กำหนดความสูงของกราฟ
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 67,
                                        interval: 2,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              left: 10,
                                            ),

                                            child: Text(
                                              '${value.toInt()} ชม.',
                                              style: TextStyle(fontSize: 16),
                                              overflow: TextOverflow.visible,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize:
                                            45, // เพิ่มพื้นที่ให้มากขึ้นเพื่อให้แกน X ขยับลงมามากขึ้น
                                        getTitlesWidget: (value, meta) {
                                          int day = value.toInt();
                                          return Transform.rotate(
                                            angle: -90 * 3.14159 / 180,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                                top: 17,
                                                right: 9,
                                              ), // เพิ่มการจัดระยะห่างของข้อความ
                                              child: Text(
                                                'วันที่ $day', // ปรับให้แสดงคำว่า วันที่ และเลขวันที่
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: getSleepDataForChart(
                                        groupedByDate.keys.first,
                                      ),
                                      isCurved: false,
                                      color: Color.fromARGB(255, 251, 147, 0),
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  'จำนวนครั้งการกินอาหารในแต่ละวันใน 1 สัปดาห์',
                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Center(
                                  child: Container(
                                    width: 350, // กำหนดความกว้างของกราฟ
                                    height: 300, // กำหนดความสูงของกราฟ
                                    child: BarChart(
                                      BarChartData(
                                        gridData: FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 60,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '${value.toInt()} ครั้ง',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 45,
                                              getTitlesWidget: (value, meta) {
                                                int day = value.toInt();
                                                return Transform.rotate(
                                                  angle: -90 * 3.14159 / 180,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 10,
                                                          top: 15,
                                                          right: 10,
                                                        ), // เพิ่มกา
                                                    child: Text(
                                                      'วันที่ $day', // ปรับให้แสดงคำว่า วันที่ และเลขวันที่
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        barGroups: getEatingDataForChart(
                                          groupedByDate.keys.first,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  'จำนวนครั้งการเข้าห้องน้ำในแต่ละวันใน 1 สัปดาห์',
                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Center(
                                  child: Container(
                                    width: 350, // กำหนดความกว้างของกราฟ
                                    height: 300, // กำหนดความสูงของกราฟ
                                    child: BarChart(
                                      BarChartData(
                                        gridData: FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 55,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '${value.toInt()} ครั้ง',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 45,
                                              getTitlesWidget: (value, meta) {
                                                int day = value.toInt();
                                                return Transform.rotate(
                                                  angle: -90 * 3.14159 / 180,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 10,
                                                          top: 15,
                                                          right: 10,
                                                        ), // เพิ่มกา
                                                    child: Text(
                                                      'วันที่ $day', // ปรับให้แสดงคำว่า วันที่ และเลขวันที่
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        barGroups: getToietDataForChart(
                                          groupedByDate.keys.first,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
