class LectureModel {
  String? cid;
  String? lid;
  String? lectureTitle;
  String? lectureDescription;
  String? lectureUrl;
  bool isCompleted; // NEW FIELD

  LectureModel({
    this.cid,
    this.lid,
    this.lectureTitle,
    this.lectureDescription,
    this.lectureUrl,
    this.isCompleted = false, // Default not completed
  });

  LectureModel.fromMap(Map<String, dynamic> map)
      : cid = map["cid"],
        lid = map["lid"],
        lectureTitle = map["lectureTitle"],
        lectureDescription = map["lectureDescription"],
        lectureUrl = map["lectureUrl"],
        isCompleted = map["isCompleted"] ?? false;

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "lid": lid,
      "lectureTitle": lectureTitle,
      "lectureDescription": lectureDescription,
      "lectureUrl": lectureUrl,
      "isCompleted": isCompleted,
    };
  }
}
