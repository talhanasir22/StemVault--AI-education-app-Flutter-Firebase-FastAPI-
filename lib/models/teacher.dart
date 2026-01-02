import 'user.dart';

class Teacher extends User {
  String teacherID;
  DateTime hireDate;
  String department;
  String qualification;

  Teacher({
    required String userID,
    required String username,
    required String passwordHash,
    required String email,
    required DateTime createdAt,
    required this.teacherID,
    required this.hireDate,
    required this.department,
    required this.qualification,
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
    data['teacherID'] = teacherID;
    data['hireDate'] = hireDate.toIso8601String();
    data['department'] = department;
    data['qualification'] = qualification;
    return data;
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      userID: json['userID'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      teacherID: json['teacherID'],
      hireDate: DateTime.parse(json['hireDate']),
      department: json['department'],
      qualification: json['qualification'],
    );
  }
}
