class Assignment {
  String assignmentID;
  String title;
  String description;
  DateTime dueDate;
  double maxPoints;

  Assignment({
    required this.assignmentID,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignmentID': assignmentID,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'maxPoints': maxPoints,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentID: json['assignmentID'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      maxPoints: (json['maxPoints'] as num).toDouble(),
    );
  }
}
