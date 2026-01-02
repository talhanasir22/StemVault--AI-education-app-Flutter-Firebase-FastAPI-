class Chat {
  String chatID;
  String subject;
  DateTime lastMessageTime;

  Chat({
    required this.chatID,
    required this.subject,
    required this.lastMessageTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatID': chatID,
      'subject': subject,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      chatID: json['chatID'],
      subject: json['subject'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}
