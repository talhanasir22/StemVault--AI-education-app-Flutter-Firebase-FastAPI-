import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> incompleteAssignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Get student document
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
      final assignmentIds = List<String>.from(studentDoc.data()?['incompleteAssignments'] ?? []);

      List<Map<String, dynamic>> fetchedAssignments = [];

      for (String assignmentId in assignmentIds) {
        final assignmentDoc = await FirebaseFirestore.instance.collection('assignment').doc(assignmentId).get();
        if (assignmentDoc.exists) {
          final assignmentData = assignmentDoc.data()!;
          final cid = assignmentData['cid'];

          // Get course
          final courseQuery = await FirebaseFirestore.instance.collection('courses').where('cid', isEqualTo: cid).get();
          if (courseQuery.docs.isNotEmpty) {
            final courseDoc = courseQuery.docs.first;
            final tid = courseDoc['tid'];

            // Get teacher
            final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(tid).get();
            if (teacherDoc.exists) {
              final teacherName = teacherDoc['userName'];
              final courseName = courseDoc['courseTitle'];

              fetchedAssignments.add({
                'title': assignmentData['title'],
                'dueDate': assignmentData['dueDate'],
                'dueTime': assignmentData['dueTime'],
                'totalMarks': assignmentData['totalMarks'],
                'teacherName': teacherName,
                'courseName': courseName,
              });
            }
          }
        }
      }

      setState(() {
        incompleteAssignments = fetchedAssignments;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching assignments: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildAssignmentCard(Map<String, dynamic> assignment) {
    // Format the due date and time
    String formattedDueDateTime = '';
    try {
      DateTime dueDate = (assignment['dueDate'] as Timestamp).toDate();
      TimeOfDay dueTime = TimeOfDay(
        hour: int.parse((assignment['dueTime'] ?? "00:00").toString().split(":")[0]),
        minute: int.parse((assignment['dueTime'] ?? "00:00").toString().split(":")[1]),
      );

      DateTime combinedDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute,
      );

      formattedDueDateTime = "${combinedDateTime.day.toString().padLeft(2, '0')}-${combinedDateTime.month.toString().padLeft(2, '0')}-${combinedDateTime.year} "
          "${(combinedDateTime.hour % 12 == 0 ? 12 : combinedDateTime.hour % 12)}:"
          "${combinedDateTime.minute.toString().padLeft(2, '0')}"
          "${combinedDateTime.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      formattedDueDateTime = "Invalid Date";
    }

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment['title'] ?? '',
              style: AppText.mainHeadingTextStyle().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Teacher: ${assignment['teacherName']}', style: AppText.mainSubHeadingTextStyle()),
            Text('Course: ${assignment['courseName']}', style: AppText.mainSubHeadingTextStyle()),
            Text('Total Marks: ${assignment['totalMarks']}', style: AppText.mainSubHeadingTextStyle()),
            Text('Due: $formattedDueDateTime', style: AppText.mainSubHeadingTextStyle()),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                smallBlueButton(Icons.open_in_new, "Open"),
                smallBlueButton(Icons.download, "Download"),
                smallBlueButton(Icons.upload, "Upload"),
              ],
            )
          ],
        ),
      ),
    );
  }


  Widget smallBlueButton(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {}, // No logic as per your instruction
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.bgColor,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Text(tooltip),
        ],
      ),
    );
  }

  Widget buildShimmerLoader() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 150),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Assignments",
          style: AppText.mainHeadingTextStyle().copyWith(fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Incomplete"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoading
              ? buildShimmerLoader()
              : incompleteAssignments.isEmpty
              ? Center(child: Text("No Incomplete Assignments", style: AppText.mainSubHeadingTextStyle()))
              : ListView.builder(
            itemCount: incompleteAssignments.length,
            itemBuilder: (context, index) => buildAssignmentCard(incompleteAssignments[index]),
          ),
          // Completed Assignments tab (empty UI for now)
          Center(child: Text("Completed Assignments will appear here", style: AppText.mainSubHeadingTextStyle())),
        ],
      ),
    );
  }
}
