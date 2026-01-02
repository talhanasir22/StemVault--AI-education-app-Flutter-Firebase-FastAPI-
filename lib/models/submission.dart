class Submission {
  String submissionID;
  DateTime submissionDate;
  String contentURL;
  double? grade;
  String? feedback;

  Submission({
    required this.submissionID,
    required this.submissionDate,
    required this.contentURL,
    this.grade,
    this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'submissionID': submissionID,
      'submissionDate': submissionDate.toIso8601String(),
      'contentURL': contentURL,
      'grade': grade,
      'feedback': feedback,
    };
  }

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      submissionID: json['submissionID'],
      submissionDate: DateTime.parse(json['submissionDate']),
      contentURL: json['contentURL'],
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      feedback: json['feedback'],
    );
  }
}
