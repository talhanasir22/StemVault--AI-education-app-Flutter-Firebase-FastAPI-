import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// page_transition and appColors not required here
import 'package:stem_vault/Core/apptext.dart';

class EnrolledCoursesPage extends StatefulWidget {
  const EnrolledCoursesPage({Key? key}) : super(key: key);

  @override
  State<EnrolledCoursesPage> createState() => _EnrolledCoursesPageState();
}

class _EnrolledCoursesPageState extends State<EnrolledCoursesPage> {
  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
      final enrolled = List<String>.from(studentDoc.data()?['enrolledCourses'] ?? []);
      List<Map<String, dynamic>> fetched = [];

      for (var cid in enrolled) {
        final courseQuery = await FirebaseFirestore.instance.collection('courses').where('cid', isEqualTo: cid).get();
        if (courseQuery.docs.isNotEmpty) {
          final c = courseQuery.docs.first;
          fetched.add({
            'cid': cid,
            'title': c.get('courseTitle') ?? '',
            'description': c.get('courseDescription') ?? '',
          });
        }
      }

      setState(() {
        courses = fetched;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading enrolled courses: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _removeCourse(String cid) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final studentRef = FirebaseFirestore.instance.collection('students').doc(uid);
      await studentRef.update({'enrolledCourses': FieldValue.arrayRemove([cid])});

      // also remove student from course's enrolledStudents if present
      final courseQuery = await FirebaseFirestore.instance.collection('courses').where('cid', isEqualTo: cid).get();
      for (var cdoc in courseQuery.docs) {
        try {
          await cdoc.reference.update({'enrolledStudents': FieldValue.arrayRemove([uid])});
        } catch (_) {}
      }

      setState(() {
        courses.removeWhere((c) => c['cid'] == cid);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have been removed from the course')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove course: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enrolled Courses', style: AppText.mainHeadingTextStyle()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
              ? const Center(child: Text('No enrolled courses'))
              : ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final c = courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(c['title'] ?? ''),
                        subtitle: Text(c['description'] ?? ''),
                        trailing: TextButton(
                          onPressed: () => _removeCourse(c['cid']),
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
