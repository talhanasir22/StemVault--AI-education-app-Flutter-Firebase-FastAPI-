import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stem_vault/Core/appColors.dart';
import '../../../Data/Firebase/student_services/course_performance_model.dart';

class StudentPerformancePage extends StatefulWidget {
  final String? sid;

  const StudentPerformancePage({this.sid, Key? key}) : super(key: key);

  @override
  _StudentPerformancePageState createState() => _StudentPerformancePageState();
}


class _StudentPerformancePageState extends State<StudentPerformancePage> {
  late Future<List<CoursePerformance>> _performanceFuture;

  @override
  void initState() {
    super.initState();
    _performanceFuture = fetchStudentPerformance();
  }

  Future<List<CoursePerformance>> fetchStudentPerformance() async {
    try {
      Query query = FirebaseFirestore.instance.collection('coursePerformance');

      if (widget.sid != null) {
        query = query.where('sid', isEqualTo: widget.sid);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CoursePerformance(
          courseName: data['courseName'] ?? '',
          teacherName: data['teacherName'] ?? '',
          monthlyPerformance: (data['monthlyPerformance'] as List<dynamic>).map((entry) {
            return AssignmentPerformance(
              week: entry['week'] ?? '',
              completionPercentage: (entry['completionPercentage'] as num).toDouble(),
            );
          }).toList(),
        );
      }).toList();
    } catch (e) {
      print("Error fetching performance data: $e");
      return [];
    }
  }


  double averagePerformance(List<AssignmentPerformance> list) {
    if (list.isEmpty) return 0;
    return list.map((e) => e.completionPercentage).reduce((a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Student Performance", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgColor,
      ),
      body: FutureBuilder<List<CoursePerformance>>(
        future: _performanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.bgColor));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading data"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No performance data found"));
          }

          final courses = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(course.courseName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          subtitle: Text("Teacher: ${course.teacherName}"),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.bgColor,
                            child: Icon(Icons.book, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipPadding: const EdgeInsets.all(8),
                                  tooltipMargin: 8,
                                  tooltipBorderRadius: BorderRadius.circular(8),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final index = group.x.toInt();
                                    if (index < course.monthlyPerformance.length) {
                                      return BarTooltipItem(
                                        "${course.monthlyPerformance[index].week}\n${rod.toY.round()}%",
                                        const TextStyle(color: Colors.white),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() < course.monthlyPerformance.length) {
                                        return Text(
                                          course.monthlyPerformance[value.toInt()].week,
                                          style: TextStyle(fontSize: 12),
                                        );
                                      }
                                      return Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 20 == 0) {
                                        return Text("${value.toInt()}%");
                                      }
                                      return Container();
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              barGroups: course.monthlyPerformance.asMap().entries.map((entry) {
                                int idx = entry.key;
                                AssignmentPerformance data = entry.value;
                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data.completionPercentage,
                                      color: AppColors.bgColor,
                                      width: 22,
                                      borderRadius: BorderRadius.circular(6),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: 100,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Average Completion: ${averagePerformance(course.monthlyPerformance).toStringAsFixed(1)}%",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
