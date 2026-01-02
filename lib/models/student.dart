import 'user.dart';

class Student extends User {
  String studentID;
  DateTime enrollmentDate;
  String major;
  bool isEnrolled;

  Student({
    required String userID,
    required String username,
    required String passwordHash,
    required String email,
    required DateTime createdAt,
    required this.studentID,
    required this.enrollmentDate,
    required this.major,
    required this.isEnrolled,
  }) : super(
         userID: userID,
         username: username,
         passwordHash: passwordHash,
         email: email,
         createdAt: createdAt,
       );

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['studentID'] = studentID;
    data['enrollmentDate'] = enrollmentDate.toIso8601String();
    data['major'] = major;
    data['isEnrolled'] = isEnrolled;
    return data;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      userID: json['userID'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      studentID: json['studentID'],
      enrollmentDate: DateTime.parse(json['enrollmentDate']),
      major: json['major'],
      isEnrolled: json['isEnrolled'],
    );
  }
}
