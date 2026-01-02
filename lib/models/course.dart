class Course {
  String courseID;
  String courseName;
  String description;
  DateTime startDate;
  DateTime endDate;
  double courseFee;

  Course({
    required this.courseID,
    required this.courseName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.courseFee,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseID': courseID,
      'courseName': courseName,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'courseFee': courseFee,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseID: json['courseID'],
      courseName: json['courseName'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      courseFee: (json['courseFee'] as num).toDouble(),
    );
  }
}
