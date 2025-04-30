import 'dart:convert';
import 'package:http/http.dart' as http;
import 'noti_model.dart';
Future<void> sendPushNotification(PushNotificationModel notification) async {
  try {
    var serverKey = 'YOUR_SERVER_KEY';

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    var body = {
      "to": "/topics/assignments",
      "notification": {
        "title": notification.title,
        "body": notification.body,
        "sound": "default",
      },
      "data": notification.data ?? {
        "click_action": notification.clickAction ?? "FLUTTER_NOTIFICATION_CLICK",
      }
    };

    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("Push notification sent successfully!");
    } else {
      print("Failed to send push notification: ${response.body}");
    }
  } catch (e) {
    print("Error sending push notification: $e");
  }
}
