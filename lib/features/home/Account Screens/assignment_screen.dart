import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_vault/Data/Cloudinary/cloudinary_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, dynamic>> completedAssignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAssignments();
    fetchCompletedAssignments();
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
              // Normalize fields and format due date
              DateTime? dueDateTime;
              try {
                dueDateTime = (data['dueDate'] as Timestamp).toDate();
              } catch (_) {
                dueDateTime = null;
              }

              fetchedAssignments.add({
                'assignmentId': assignmentDoc.id,
                'title': data['title'],
                'dueDate': dueDateTime != null ? DateFormat.yMMMd().format(dueDateTime) : data['dueDate'].toString(),
                'dueDateRaw': dueDateTime,
                'dueTime': data['dueTime'],
                'totalMarks': data['totalMarks'],
                'teacherName': teacherDoc['userName'],
                'courseName': courseDoc['courseTitle'],
                'assignmentUrl': data['assignmentUrl'] ?? data['pdfUrl'] ?? '',
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

  Future<void> fetchCompletedAssignments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
      final assignmentIds = List<String>.from(studentDoc.data()?['completedAssignments'] ?? []);
      List<Map<String, dynamic>> fetched = [];

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

            DateTime? dueDateTime;
            try {
              dueDateTime = (data['dueDate'] as Timestamp).toDate();
            } catch (_) {
              dueDateTime = null;
            }

            // get grade and feedback for this student from assignment doc
            String grade = '';
            String feedback = '';
            try {
              final gradesMap = Map<String, dynamic>.from(data['grades'] ?? {});
              final feedbacksMap = Map<String, dynamic>.from(data['feedbacks'] ?? {});
              grade = gradesMap[uid]?.toString() ?? '';
              feedback = feedbacksMap[uid]?.toString() ?? '';
            } catch (_) {}

            // find this student's submission url if present
            String submissionUrl = '';
            try {
              final submissions = List.from(data['submissions'] ?? []);
              for (var s in submissions) {
                if (s is Map && s['studentId'] == uid) {
                  submissionUrl = s['url'] ?? '';
                  break;
                }
              }
            } catch (_) {}

            fetched.add({
              'assignmentId': assignmentDoc.id,
              'title': data['title'],
              'dueDate': dueDateTime != null ? DateFormat.yMMMd().format(dueDateTime) : data['dueDate']?.toString() ?? '',
              'totalMarks': data['totalMarks'],
              'teacherName': teacherDoc['userName'],
              'courseName': courseDoc['courseTitle'],
              'assignmentUrl': data['assignmentUrl'] ?? data['pdfUrl'] ?? '',
              'grade': grade,
              'feedback': feedback,
              'submissionUrl': submissionUrl,
            });
          }
        }
      }

      setState(() {
        completedAssignments = fetched;
      });
    } catch (e) {
      print('Error fetching completed assignments: $e');
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
      await OpenFilex.open(file.path);
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

        final url = await CloudinaryService.uploadFile(file, resourceType: 'raw');

        final studentRef = FirebaseFirestore.instance.collection('students').doc(uid);

        // Remove from incompleteAssignments and add to completedAssignments for the student
        if (assignment.containsKey('assignmentId')) {
          final aid = assignment['assignmentId'];
          await studentRef.update({
            'incompleteAssignments': FieldValue.arrayRemove([aid]),
            'completedAssignments': FieldValue.arrayUnion([aid]),
          });

          // Record submission on the assignment document for teacher review
          await FirebaseFirestore.instance.collection('assignment').doc(aid).update({
            'submissions': FieldValue.arrayUnion([
              {
                'studentId': uid,
                'url': url,
                'submittedOn': Timestamp.now(),
              }
            ])
          });
        } else {
          // Fallback: if no assignmentId available, still store the uploaded file under student's completed list
          await studentRef.update({
            'completedAssignments': FieldValue.arrayUnion([url])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded successfully!")),
        );
      }
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
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
                smallBlueButton(Icons.open_in_new, "Open", () => openPdf(context, assignment['assignmentUrl'])),
                smallBlueButton(Icons.download, "Download", () => downloadPdf(assignment['assignmentUrl'])),
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
    if (completedAssignments.isEmpty) return const Center(child: Text("No completed assignments found."));

    return ListView.builder(
      itemCount: completedAssignments.length,
      itemBuilder: (context, index) {
        final a = completedAssignments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Title: ${a['title']}", style: AppText.mainHeadingTextStyle()),
                Text("Course: ${a['courseName']}"),
                Text("Teacher: ${a['teacherName']}"),
                Text("Total Marks: ${a['totalMarks'] ?? ''}"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: a['submissionUrl'] != null && a['submissionUrl'] != '' ? () => openPdf(context, a['submissionUrl']) : null,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Submission'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgColor),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: a['submissionUrl'] != null && a['submissionUrl'] != '' ? () => downloadPdf(a['submissionUrl']) : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Grade: ${a['grade'] != null && a['grade'] != '' ? a['grade'] : 'Not graded yet'}'),
                if (a['feedback'] != null && a['feedback'] != '') ...[
                  const SizedBox(height: 6),
                  Text('Feedback: ${a['feedback']}'),
                ],
              ],
            ),
          ),
        );
      },
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
          buildIncompleteTab(),
          buildCompletedTab(),
        ],
      ),
    );
  }
}
