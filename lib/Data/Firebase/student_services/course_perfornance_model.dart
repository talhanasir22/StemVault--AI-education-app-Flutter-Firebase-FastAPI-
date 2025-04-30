class CoursePerformance {
  final String courseName;
  final String teacherName;
  final List<AssignmentPerformance> monthlyPerformance; // 4 weeks example

  CoursePerformance({
    required this.courseName,
    required this.teacherName,
    required this.monthlyPerformance,
  });
}

class AssignmentPerformance {
  final String week; // e.g., "Week 1", "Week 2"
  final double completionPercentage; // 0 to 100

  AssignmentPerformance({
    required this.week,
    required this.completionPercentage,
  });
}
