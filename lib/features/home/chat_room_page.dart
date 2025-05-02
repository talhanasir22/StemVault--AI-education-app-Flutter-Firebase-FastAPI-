import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../Data/Firebase/student_services/chatroom_model.dart';
import '../../Data/Firebase/student_services/message_model.dart';

class ChatRoomPage extends StatefulWidget {
  final String name; // this is teacher username
  final String teacherUid;
  const ChatRoomPage({super.key, required this.name, required this.teacherUid});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  late String currentUserUid;
  late String teacherUid;
  ChatRoomModel? chatRoomModel;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    teacherUid = widget.teacherUid;
    _loadOrCreateChatRoom();
  }

  Future<void> _loadOrCreateChatRoom() async {
    QuerySnapshot chatRoomSnapshot = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants.$currentUserUid.uid', isEqualTo: currentUserUid)
        .where('participants.$teacherUid.uid', isEqualTo: teacherUid)
        .get();

    if (chatRoomSnapshot.docs.isNotEmpty) {
      chatRoomModel = ChatRoomModel.fromMap(chatRoomSnapshot.docs.first.data() as Map<String, dynamic>);
    } else {
      // Create new chat room
      ChatRoomModel newChatRoom = ChatRoomModel(
        chatRoomId: const Uuid().v1(),
        participants: {
          currentUserUid: {'uid': currentUserUid, 'role': 'student'},
          teacherUid: {'uid': teacherUid, 'role': 'teacher'},
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
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty || chatRoomModel == null) return;

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

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    MessageModel message = MessageModel.fromMap(docs[index].data() as Map<String, dynamic>);
                    bool isMe = message.sender == currentUserUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message.text ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
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
