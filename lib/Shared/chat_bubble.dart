import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String msg;
  final DateTime timestamp;  // Add timestamp to represent the time when the message was sent

  // Constructor with the required parameters
  ChatBubble({required this.isMe, required this.msg, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    String formattedTime = _formatTimestamp(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        width: MediaQuery.of(context).size.width * 0.5, // Set width to 50% of the screen
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the message text
            Text(
              "$msg",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 4),
            // Display the formatted timestamp and double check ticks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Icon(Icons.remove_red_eye_outlined,size: 12,)
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format the timestamp as HH:MM AM/PM
  String _formatTimestamp(DateTime timestamp) {
    String hour = timestamp.hour > 9 ? timestamp.hour.toString() : '0${timestamp.hour}';
    String minute = timestamp.minute > 9 ? timestamp.minute.toString() : '0${timestamp.minute}';
    String ampm = timestamp.hour >= 12 ? 'PM' : 'AM';

    int hourIn12HourFormat = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    hourIn12HourFormat = hourIn12HourFormat == 0 ? 12 : hourIn12HourFormat;

    return "$hourIn12HourFormat:$minute $ampm";
  }
}
