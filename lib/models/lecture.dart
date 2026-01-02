class Lecture {
  String lectureID;
  String title;
  String contentURL;
  int duration; // Duration in minutes
  int sequenceNumber;

  Lecture({
    required this.lectureID,
    required this.title,
    required this.contentURL,
    required this.duration,
    required this.sequenceNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'lectureID': lectureID,
      'title': title,
      'contentURL': contentURL,
      'duration': duration,
      'sequenceNumber': sequenceNumber,
    };
  }

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      lectureID: json['lectureID'],
      title: json['title'],
      contentURL: json['contentURL'],
      duration: json['duration'],
      sequenceNumber: json['sequenceNumber'],
    );
  }
}
