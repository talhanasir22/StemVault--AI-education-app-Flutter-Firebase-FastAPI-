class StudentModel {
  String? sid;
  String? userName;
  String? email;
  List<String>? incompleteAssignments;
  List<String>? completedAssignments;
  List<String>? enrolledCourses;
  List<String>? completedCourses;

  StudentModel({
    this.sid,
    this.userName,
    this.email,
    this.incompleteAssignments,
    this.completedAssignments,
    this.enrolledCourses,
    this.completedCourses,
  });

  StudentModel.fromMap(Map<String, dynamic> map) {
    sid = map["sid"];
    userName = map["userName"];
    email = map["email"];
    incompleteAssignments = (map["incompleteAssignments"] as List?)?.map((e) => e.toString()).toList();
    completedAssignments = (map["completedAssignments"] as List?)?.map((e) => e.toString()).toList();
    enrolledCourses = (map["enrolledCourses"] as List?)?.map((e) => e.toString()).toList();
    completedCourses = (map["completedCourses"] as List?)?.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      "sid": sid,
      "userName": userName,
      "email": email,
      "incompleteAssignments": incompleteAssignments ?? [],
      "completedAssignments": completedAssignments ?? [],
      "enrolledCourses": enrolledCourses ?? [],
      "completedCourses": completedCourses ?? [],
    };
  }
}
