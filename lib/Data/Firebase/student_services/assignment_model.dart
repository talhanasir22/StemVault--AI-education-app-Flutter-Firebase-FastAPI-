class AssignmentModel {
  String? cid;
  String? assignmentTitle;
  String? assignmentDescription;
  String? assignmentUrl;
  String? totalMarks;
  String? obtainedMarks;

  AssignmentModel({
    this.cid,
    this.assignmentTitle,
    this.assignmentDescription,
    this.assignmentUrl,
    this.totalMarks,
    this.obtainedMarks
  });

  AssignmentModel.fromMap(Map<String, dynamic> map) {
    cid = map["cid"];
    assignmentTitle = map["assignmentTitle"];
    assignmentDescription = map["assignmentDescription"];
    assignmentUrl = map["assignmentUrl"];
    totalMarks = map["totalMarks"];
    obtainedMarks = map["obtainedMakrs"];
  }

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "assignmentTitle": assignmentTitle,
      "assignmentDescription": assignmentDescription,
      "assignmentUrl": assignmentUrl,
      "totalMarks": totalMarks,
      "obtainedMarks": obtainedMarks
    };
  }
}
