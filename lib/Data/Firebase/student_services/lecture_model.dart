class LectureModel {
  String? cid;
  String? lid;
  String? lectureTitle;
  String? lectureDescription;
  String? lectureUrl;

  LectureModel({
    this.cid,
    this.lid,
    this.lectureTitle,
    this.lectureDescription,
    this.lectureUrl,
  });

  LectureModel.fromMap(Map<String, dynamic> map) {
    cid = map["cid"];
    lid = map["lid"];
    lectureTitle = map["lectureTitle"];
    lectureDescription = map["lectureDescription"];
    lectureUrl = map["lectureUrl"];
  }

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "lid": lid,
      "lectureTitle": lectureTitle,
      "lectureDescription": lectureDescription,
      "lectureUrl": lectureUrl,
    };
  }
}
