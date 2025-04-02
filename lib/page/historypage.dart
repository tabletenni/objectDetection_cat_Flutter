import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:objectdetectioncat/page/allhistory.dart';
import 'package:objectdetectioncat/service/function.dart';
import 'package:objectdetectioncat/service/get_data.dart';


class HistoryPgae extends StatefulWidget {
  @override
  State<HistoryPgae> createState() => _HistoryPgaeState();
}

class _HistoryPgaeState extends State<HistoryPgae> {
  DateTimeRange? selectedDates;
  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      stream: FirestoreService().fetchDataAndGroup(), // ใช้ StreamBuilder แทน FutureBuilder
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No data found"));
        }

        Map<String, List<Map<String, dynamic>>> groupedData = snapshot.data!;
        List<String> desiredBehaviors = ['sleep', 'eat', 'toilet'];

        // จัดกลุ่มข้อมูลตามวันที่ พร้อมกรองตามช่วงวันที่ที่เลือก
        Map<String, Map<String, List<Map<String, dynamic>>>> groupedByDate = {};

        for (var behavior in desiredBehaviors) {
          for (var dateData in groupedData.values.expand(
            (dateData) => dateData,
          )) {
            Timestamp timestamp = dateData['start_time'];
            DateTime startDate = timestamp.toDate();

            String formattedDate =
                "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

            // กรองข้อมูลตามช่วงวันที่ที่เลือก
            if (selectedDates != null &&
                (startDate.isBefore(selectedDates!.start) ||
                    startDate.isAfter(selectedDates!.end))) {
              continue;
            }

            if (!groupedByDate.containsKey(formattedDate)) {
              groupedByDate[formattedDate] = {};
            }

            if (!groupedByDate[formattedDate]!.containsKey(behavior)) {
              groupedByDate[formattedDate]![behavior] = [];
            }

            if (dateData['behavior'] == behavior) {
              groupedByDate[formattedDate]![behavior]!.add(dateData);
            }
          }
        }

        // จัดเรียงวันที่จากใหม่ไปเก่า
        List<String> sortedDates = groupedByDate.keys.toList()
          ..sort((a, b) {
            DateTime dateA = DateTime.parse(a);
            DateTime dateB = DateTime.parse(b);
            return dateB.compareTo(dateA); // เรียงจากใหม่ไปเก่า
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 5, bottom: 3),
                  child: IconButton(
                    onPressed: () async {
                      final DateTimeRange? dateTimeRange =
                          await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2500),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: Color.fromARGB(
                                      255,
                                      248,
                                      243,
                                      217,
                                    ),
                                    headerBackgroundColor: Color.fromARGB(
                                      255,
                                      80,
                                      75,
                                      56,
                                    ),
                                    headerForegroundColor: Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                      if (dateTimeRange != null) {
                        setState(() {
                          selectedDates = dateTimeRange;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.date_range_outlined,
                      color: Colors.black,
                      size: 35,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  selectedDates == null
                      ? 'ข้อมูลทั้งหมด'
                      : 'ข้อมูลจากวันที่ ${selectedDates!.start.toLocal().toString().split(' ')[0]} ถึง\n${selectedDates!.end.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  String date = sortedDates[index];
                  List<Map<String, dynamic>> sleepData =
                      groupedByDate[date]?['sleep'] ?? [];
                  Duration totalSleepDuration = calculateTotalSleepTime(
                    sleepData,
                  );
                  int totalSleepHours = totalSleepDuration.inHours;
                  int totalSleepMinutes = totalSleepDuration.inMinutes % 60;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (builder)=> HistoryDataPerDate(dateSelected: date,)));
                      },
                      child:Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 217, 213, 204),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'วันที่: $date',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var behavior in desiredBehaviors)
                                if (groupedByDate[date]!.containsKey(behavior))
                                  _buildBehaviorBox(
                                    behavior,
                                    behavior == 'sleep'
                                        ? "${totalSleepHours}h ${totalSleepMinutes}min"
                                        : groupedByDate[date]![behavior]!.length
                                            .toString(),
                                    totalSleepHours,
                                    context,
                                    date,
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBehaviorBox(
    String behavior,
    String value,
    int totalSleepHours,
    BuildContext context,
    String date,
  ) {
    return Container(
      width: 110.0,
      height: 110.0,
      decoration: BoxDecoration(
        color:
            behavior == 'sleep'
                ? getSleepColor(totalSleepHours)
                : behavior == 'toilet'
                ? getToiletColor(int.tryParse(value) ?? 0)
                : Color.fromARGB(255, 196, 225, 246),
        borderRadius: BorderRadius.circular(20),
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
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
