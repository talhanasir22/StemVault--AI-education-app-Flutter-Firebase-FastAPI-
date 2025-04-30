import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'course_perfornance_model.dart';

class StudentPerformancePage extends StatefulWidget {
  @override
  State<StudentPerformancePage> createState() => _StudentPerformancePageState();
}

class _StudentPerformancePageState extends State<StudentPerformancePage> {
  final List<CoursePerformance> courses = [
    CoursePerformance(
      courseName: "Web Technologies",
      teacherName: "Mr. Smith",
      monthlyPerformance: [
        AssignmentPerformance(week: "Week 1", completionPercentage: 75),
        AssignmentPerformance(week: "Week 2", completionPercentage: 60),
        AssignmentPerformance(week: "Week 3", completionPercentage: 90),
        AssignmentPerformance(week: "Week 4", completionPercentage: 80),
      ],
    ),
    CoursePerformance(
      courseName: "Machine Learning",
      teacherName: "Mr. Fahad",
      monthlyPerformance: [
        AssignmentPerformance(week: "Week 1", completionPercentage: 70),
        AssignmentPerformance(week: "Week 2", completionPercentage: 65),
        AssignmentPerformance(week: "Week 3", completionPercentage: 85),
        AssignmentPerformance(week: "Week 4", completionPercentage: 95),
      ],
    ),
    CoursePerformance(
      courseName: "Calculus",
      teacherName: "Dr. Johny Sins",
      monthlyPerformance: [
        AssignmentPerformance(week: "Week 1", completionPercentage: 50),
        AssignmentPerformance(week: "Week 2", completionPercentage: 75),
        AssignmentPerformance(week: "Week 3", completionPercentage: 65),
        AssignmentPerformance(week: "Week 4", completionPercentage: 90),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Student Performance",style: TextStyle(color: Colors.white),),
        backgroundColor: AppColors.bgColor,
      ),
      body: ListView.builder(
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
                                return BarTooltipItem(
                                  "${course.monthlyPerformance[group.x.toInt()].week}\n"
                                      "${rod.toY.round()}%",
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),


                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return Text(
                                    course.monthlyPerformance[value.toInt()].week,
                                    style: TextStyle(fontSize: 12),
                                  );
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
