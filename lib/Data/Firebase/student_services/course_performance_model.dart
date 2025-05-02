class CoursePerformance {
  final String courseName;
  final String teacherName;
  final List<AssignmentPerformance> monthlyPerformance;

  CoursePerformance({
    required this.courseName,
    required this.teacherName,
    required this.monthlyPerformance,
  });
}

class AssignmentPerformance {
  final String week;
  final double completionPercentage;

  AssignmentPerformance({
    required this.week,
    required this.completionPercentage,
  });
}
