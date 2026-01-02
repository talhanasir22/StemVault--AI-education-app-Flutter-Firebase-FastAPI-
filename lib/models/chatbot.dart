class Chatbot {
  String chatbotID;
  String name;
  String responseAlgorithm;

  Chatbot({
    required this.chatbotID,
    required this.name,
    required this.responseAlgorithm,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatbotID': chatbotID,
      'name': name,
      'responseAlgorithm': responseAlgorithm,
    };
  }

  factory Chatbot.fromJson(Map<String, dynamic> json) {
    return Chatbot(
      chatbotID: json['chatbotID'],
      name: json['name'],
      responseAlgorithm: json['responseAlgorithm'],
    );
  }
}
