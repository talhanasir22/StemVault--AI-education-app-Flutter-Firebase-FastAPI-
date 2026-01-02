import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../Data/Firebase/student_services/chatroom_model.dart';
import '../../Data/Firebase/student_services/message_model.dart';

class ChatRoomPage extends StatefulWidget {
  final String name; // this is teacher username
  const ChatRoomPage({super.key, required this.name});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  late String currentUserUid;
  late String studentUid;
  ChatRoomModel? chatRoomModel;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    _loadOrCreateChatRoom();
  }

  Future<void> _loadOrCreateChatRoom() async {
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('userName', isEqualTo: widget.name.toLowerCase())
        .get();

    if (studentSnapshot.docs.isEmpty) {
      print('Student not found');
      return;
    }

    studentUid = studentSnapshot.docs.first.id;

  QuerySnapshot chatRoomSnapshot = await FirebaseFirestore.instance
      .collection('chatRooms')
      .where('participants.$currentUserUid.uid', isEqualTo: currentUserUid)
      .where('participants.$studentUid.uid', isEqualTo: studentUid)
      .get();

  if (chatRoomSnapshot.docs.isNotEmpty) {
    chatRoomModel = ChatRoomModel.fromMap(chatRoomSnapshot.docs.first.data() as Map<String, dynamic>);
  } else {
    // Create new chat room
    ChatRoomModel newChatRoom = ChatRoomModel(
      chatRoomId: const Uuid().v1(),
      participants: {
        currentUserUid: {'uid': currentUserUid, 'role': 'teacher'},
        studentUid: {'uid': studentUid, 'role': 'student'},
      },
      lastMessage: '',
    );

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(newChatRoom.chatRoomId)
        .set(newChatRoom.toMap());

    chatRoomModel = newChatRoom;
  }

    setState(() {});
    // Mark unseen incoming messages as seen when opening the chat
    await _markAllMessagesSeen();
  }

  Future<void> _markAllMessagesSeen() async {
    if (chatRoomModel == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomModel!.chatRoomId)
          .collection('messages')
          .where('seen', isEqualTo: false)
          .get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['sender'] != currentUserUid) {
          await doc.reference.update({'seen': true});
        }
      }
    } catch (e) {
      // ignore
    }
  }

void sendMessage() async {
  if (_messageController.text.trim().isEmpty || chatRoomModel == null) return;

  // Get current user role
  String? currentUserRole = chatRoomModel?.participants?[currentUserUid]?['role'];

  // Get receiver UID
  String? receiverUid = chatRoomModel?.participants?.keys.firstWhere((uid) => uid != currentUserUid);

  // Get receiver role
  String? receiverRole = chatRoomModel?.participants?[receiverUid]?['role'];

  // Check if the sender is allowed to send messages to the receiver
  if ((currentUserRole == 'teacher' && receiverRole == 'student') ||
      (currentUserRole == 'student' && receiverRole == 'teacher')) {
    String messageId = const Uuid().v1();
    MessageModel newMessage = MessageModel(
      messageId: messageId,
      sender: currentUserUid,
      text: _messageController.text.trim(),
      seen: false,
      createdOn: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomModel!.chatRoomId)
        .collection('messages')
        .doc(messageId)
        .set(newMessage.toMap());

    // Update last message
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomModel!.chatRoomId)
        .update({
      'lastMessage': _messageController.text.trim(),
    });

    _messageController.clear();
  } else {
    print('You are not allowed to send messages to this user.');
    // Optionally, display an error message to the user
  }
} 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: chatRoomModel == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoomModel!.chatRoomId)
                  .collection('messages')
                  .orderBy('createdOn', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                // messages are marked seen when chat opens

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    MessageModel message = MessageModel.fromMap(doc.data() as Map<String, dynamic>);
                    bool isMe = message.sender == currentUserUid;
                    bool seen = message.seen ?? false;

                    Widget bubble = Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message.text ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                    );

                    if (isMe) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            bubble,
                            const SizedBox(width: 6),
                            Icon(Icons.done_all, size: 16, color: seen ? Colors.green : Colors.grey),
                          ],
                        ),
                      );
                    } else {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!seen) ...[
                              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            ],
                            bubble,
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(onPressed: sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
