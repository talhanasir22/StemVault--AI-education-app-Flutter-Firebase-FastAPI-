import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';
import '../../Data/Firebase/student_services/chatroom_model.dart';
import '../../Data/Firebase/student_services/message_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String currentTime = DateFormat.jm().format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to fetch all student usernames from Firestore
  Future<List<String>> _fetchStudentUsernames() async {
    List<String> usernames = [];

    try {
      // Fetch all students in the 'students' collection
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students').get();

      // Loop through each student document
      for (var doc in studentSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('userName')) {
          String? username = data['userName']?.toString().trim().toLowerCase();
          if (username != null && username.isNotEmpty) {
            usernames.add(username);
          }
        }
      }
    } catch (e) {
      print("Error fetching student usernames: $e");
    }

    return usernames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Messages & Notifications",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Messages"),
            Tab(text: "Notifications"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<String>>(
            future: _fetchStudentUsernames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No students found"));
              }

              List<String> usernames = snapshot.data!;

              return ListView.separated(
                itemCount: usernames.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: ChatRoomPage(name: usernames[index]),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(usernames[index]),
                      trailing: Text(currentTime),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
              );
            },
          ),
          Center(child: Text("No notifications yet")),
        ],
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String name; // Teacher username
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
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty || chatRoomModel == null) return;

    String? currentUserRole = chatRoomModel?.participants?[currentUserUid]?['role'];

    String? receiverUid = chatRoomModel?.participants?.keys.firstWhere((uid) => uid != currentUserUid);

    String? receiverRole = chatRoomModel?.participants?[receiverUid]?['role'];

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

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomModel!.chatRoomId)
          .update({
        'lastMessage': _messageController.text.trim(),
      });

      _messageController.clear();
    } else {
      print('You are not allowed to send messages to this user.');
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
                        child: Text(
                          message.text ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
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
          ),
        ],
      ),
    );
  }
}
