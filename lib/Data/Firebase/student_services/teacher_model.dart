class TeacherModel {
  String? tid;
  String? userName;
  String? email;
  List<String>? assignedCourses;
  List<String>? generatedAssignments;
  List<String>? enrolledCourses;
  List<String>? completedCourses;

  TeacherModel({
    this.tid,
    this.userName,
    this.email,
    this.generatedAssignments,
    this.assignedCourses,
    this.enrolledCourses,
    this.completedCourses,
  });

  TeacherModel.fromMap(Map<String, dynamic> map) {
    tid = map["tid"];
    userName = map["userName"];
    email = map["email"];
    generatedAssignments = (map["generatedAssignments"] as List?)?.map((e) => e.toString()).toList();
    assignedCourses = (map["assignedCourses"] as List?)?.map((e) => e.toString()).toList();
    enrolledCourses = (map["enrolledCourses"] as List?)?.map((e) => e.toString()).toList();
    completedCourses = (map["completedCourses"] as List?)?.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      "tid": tid,
      "userName": userName,
      "email": email,
      "assignedCourses": assignedCourses ?? [],
      "generatedAssignments": generatedAssignments ?? [],
      "enrolledCourses": enrolledCourses ?? [],
      "completedCourses": completedCourses ?? [],
    };
  }
}
