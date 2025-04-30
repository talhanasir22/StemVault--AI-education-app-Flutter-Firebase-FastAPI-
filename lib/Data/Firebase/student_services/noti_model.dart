class PushNotificationModel {
  final String title;
  final String body;
  final String? clickAction;
  final Map<String, dynamic>? data;

  PushNotificationModel({
    required this.title,
    required this.body,
    this.clickAction,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      "notification": {
        "title": title,
        "body": body,
        "sound": "default",
      },
      "data": data ?? {},
      "priority": "high",
    };
  }
}
