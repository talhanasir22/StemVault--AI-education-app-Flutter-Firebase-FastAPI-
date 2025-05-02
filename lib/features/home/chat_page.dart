import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/LoadingIndicator.dart';

import 'chat_room_page.dart';

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

  // Function to fetch all teacher usernames from Firestore
  Future<List<Map<String, dynamic>>> _fetchTeachers() async {
    List<Map<String, dynamic>> teachers = [];

    try {
      // Fetch all users in the 'teachers' collection
      QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance.collection('teachers').get();

      print("Teacher docs found: ${teacherSnapshot.docs.length}");

      // Loop through each teacher document
      for (var doc in teacherSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('userName') && data['userName'] != null) {
          teachers.add({
            'uid': doc.id,
            'userName': data['userName'],
          });
        }
      }
    } catch (e) {
      print("Error fetching teacher usernames: $e");
    }

    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Messages & Notifications",
          style: AppText.mainHeadingTextStyle().copyWith(fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Message"),
            Tab(text: "Notification"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTeachers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No teachers found"));
              }

              List<Map<String, dynamic>> teachers = snapshot.data!;

              return ListView.separated(
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  var teacher = teachers[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: ChatRoomPage(name: teacher['userName'], teacherUid: teacher['uid']),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(teacher['userName']),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Image.asset("assets/Images/No notification.png")),
              const Center(child: Text("No notification yet"))
            ],
          ),
        ],
      ),
    );
  }
}
