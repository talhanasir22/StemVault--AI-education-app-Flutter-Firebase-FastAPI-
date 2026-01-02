class StudentProgress {
  String progressID;
  String status; // e.g., 'Completed', 'In Progress'
  DateTime? completionDate;
  DateTime lastAccessed;

  StudentProgress({
    required this.progressID,
    required this.status,
    this.completionDate,
    required this.lastAccessed,
  });

  Map<String, dynamic> toJson() {
    return {
      'progressID': progressID,
      'status': status,
      'completionDate': completionDate?.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      progressID: json['progressID'],
      status: json['status'],
      completionDate:
          json['completionDate'] != null
              ? DateTime.parse(json['completionDate'])
              : null,
      lastAccessed: DateTime.parse(json['lastAccessed']),
    );
  }
}
