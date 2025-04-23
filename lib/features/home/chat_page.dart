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
  Future<List<String>> _fetchTeacherUsernames() async {
    List<String> usernames = [];

    try {
      // Fetch all users in the 'teachers' collection
      QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance.collection('teachers').get();

      print("Teacher docs found: ${teacherSnapshot.docs.length}");

      // Loop through each teacher document
      for (var doc in teacherSnapshot.docs) {
        print('Checking teacher doc ID: ${doc.id}');

        // Safely extract data
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('userName')) {
          String? username = data['userName']?.toString().trim().toLowerCase();
          if (username != null && username.isNotEmpty) {
            usernames.add(username);
            print("Added username to list: $username");
          }
        } else {
          print("No userName field found in doc ID: ${doc.id}");
        }
      }
    } catch (e) {
      print("Error fetching teacher usernames: $e");
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
          FutureBuilder<List<String>>(
            future: _fetchTeacherUsernames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No teachers found"));
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
