import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAssignments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
      final assignmentIds = List<String>.from(studentDoc.data()?['incompleteAssignments'] ?? []);
      List<Map<String, dynamic>> fetchedAssignments = [];

      for (String assignmentId in assignmentIds) {
        final assignmentDoc = await FirebaseFirestore.instance.collection('assignment').doc(assignmentId).get();
        if (assignmentDoc.exists) {
          final data = assignmentDoc.data()!;
          final cid = data['cid'];
          final courseQuery = await FirebaseFirestore.instance.collection('courses').where('cid', isEqualTo: cid).get();

          if (courseQuery.docs.isNotEmpty) {
            final courseDoc = courseQuery.docs.first;
            final tid = courseDoc['tid'];
            final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(tid).get();

            if (teacherDoc.exists) {
              fetchedAssignments.add({
                'title': data['title'],
                'dueDate': data['dueDate'],
                'dueTime': data['dueTime'],
                'totalMarks': data['totalMarks'],
                'teacherName': teacherDoc['userName'],
                'courseName': courseDoc['courseTitle'],
                'pdfUrl': data['pdfUrl'],
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
      setState(() => isLoading = false);
    }
  }

  Future<void> openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open PDF.")),
      );
    }
  }

  Future<void> downloadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final fileName = url.split('/').last;
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      print('Download error: $e');
    }
  }

  Future<void> uploadAssignment(Map<String, dynamic> assignment) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final fileName = '${assignment['title']}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final ref = FirebaseStorage.instance.ref().child('completedAssignment/$fileName');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        final studentRef = FirebaseFirestore.instance.collection('students').doc(uid);
        await studentRef.update({
          'completedAssignment': FieldValue.arrayUnion([url])
        });

        final courseSnap = await FirebaseFirestore.instance
            .collection('courses')
            .where('courseTitle', isEqualTo: assignment['courseName'])
            .get();

        if (courseSnap.docs.isNotEmpty) {
          final tid = courseSnap.docs.first['tid'];
          final teacherRef = FirebaseFirestore.instance.collection('teachers').doc(tid);
          await teacherRef.update({
            'completedAssignment': FieldValue.arrayUnion([url])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded successfully!")),
        );
      }
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed.")),
      );
    }
  }

  Widget smallBlueButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: onPressed,
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

  Widget buildAssignmentCard(Map<String, dynamic> assignment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: ${assignment['title']}", style: AppText.mainHeadingTextStyle()),
            Text("Course: ${assignment['courseName']}"),
            Text("Teacher: ${assignment['teacherName']}"),
            Text("Due Date: ${assignment['dueDate']} at ${assignment['dueTime']}"),
            Text("Total Marks: ${assignment['totalMarks']}"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                smallBlueButton(Icons.open_in_new, "Open", () => openPdf(context, assignment['pdfUrl'])),
                smallBlueButton(Icons.download, "Download", () => downloadPdf(assignment['pdfUrl'])),
                smallBlueButton(Icons.upload, "Upload", () => uploadAssignment(assignment)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIncompleteTab() {
    if (isLoading) return buildShimmerLoader();
    if (incompleteAssignments.isEmpty) {
      return const Center(child: Text("No incomplete assignments found."));
    }
    return ListView.builder(
      itemCount: incompleteAssignments.length,
      itemBuilder: (context, index) {
        return buildAssignmentCard(incompleteAssignments[index]);
      },
    );
  }

  Widget buildCompletedTab() {
    return const Center(child: Text("Completed assignments UI coming soon..."));
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
          buildIncompleteTab(),
          buildCompletedTab(),
        ],
      ),
    );
  }
}
