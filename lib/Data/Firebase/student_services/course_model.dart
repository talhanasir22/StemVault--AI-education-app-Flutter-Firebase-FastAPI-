class CourseModel {
  String? tid;
  String? cid;
  String? courseTitle;
  String? courseDescription;
  String? thumbnailUrl;
  String? tag;
  List<String>? lectures;
  List<String>? enrolledStudents;

  CourseModel({
    this.tid,
    this.cid,
    this.courseTitle,
    this.courseDescription,
    this.thumbnailUrl,
    this.lectures,
    this.tag,
    this.enrolledStudents,
  });

  CourseModel.fromMap(Map<String, dynamic> map) {
    tid = map["tid"];
    cid = map["cid"];
    courseTitle = map["courseTitle"];
    courseDescription = map["courseDescription"];
    thumbnailUrl = map["thumbnailUrl"];
    tag = map["tag"];
    lectures = (map["lectures"] as List?)?.map((e) => e.toString()).toList();
    enrolledStudents = (map["enrolledStudents"] as List?)?.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      "tid": tid,
      "cid": cid,
      "courseTitle": courseTitle,
      "courseDescription": courseDescription,
      "thumbnailUrl": thumbnailUrl,
      "tag" : tag,
      "lectures": lectures ?? [],
      "enrolledStudents": enrolledStudents ?? [],
    };
  }
}
