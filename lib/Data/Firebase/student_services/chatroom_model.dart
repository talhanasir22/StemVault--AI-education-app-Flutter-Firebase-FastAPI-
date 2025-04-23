class ChatRoomModel {
  String? chatRoomId;
  Map<String, Map<String, dynamic>>? participants;
  String? lastMessage;

  ChatRoomModel({this.chatRoomId, this.participants, this.lastMessage});

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatRoomId = map["chatRoomId"];
    participants = map["participants"] != null ? Map<String, Map<String, dynamic>>.from(
        map["participants"].map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))) : null;
    lastMessage = map["lastMessage"];
  }

  Map<String, dynamic> toMap() {
    return {
      "chatRoomId": chatRoomId,
      "participants": participants,
      "lastMessage": lastMessage
    };
  }
}
