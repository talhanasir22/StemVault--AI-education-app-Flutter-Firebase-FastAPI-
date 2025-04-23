import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stem_vault/Data/Firebase/student_services/assignment_model.dart';
import 'package:stem_vault/Data/Firebase/student_services/student_model.dart';
import 'package:stem_vault/Data/Firebase/student_services/teacher_model.dart';

import 'course_model.dart';
import 'lecture_model.dart';

class FirestoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final CollectionReference students = FirebaseFirestore.instance.collection('students');
  final CollectionReference teachers = FirebaseFirestore.instance.collection('teachers');
  final CollectionReference chats = FirebaseFirestore.instance.collection('chats');


  // Student Model Save
  Future<void> saveStudentData(StudentModel model) async{
    await students.doc(model.sid).set(model.toMap());
  }

  // Teacher Model Save
  Future<void> saveTeacherData(TeacherModel model) async{
    await teachers.doc(model.tid).set(model.toMap());
  }

  Future<DocumentSnapshot?> getTeacherData(String uid) async {
    try {
      return await teachers
          .doc(uid)
          .get();
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
  Future<DocumentSnapshot?> getStudentData(String uid) async {
    try {
      return await students
          .doc(uid)
          .get();
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }


  Future<String?> getStudentUsername() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await students
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['userName'] as String?;
      }
      return null; // Username not found
    } catch (e) {
      print("Error fetching username: $e");
      return null;
    }
  }
  Future<String?> getTeacherUsername() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await teachers
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['userName'] as String?;
      }
      return null; // Username not found
    } catch (e) {
      print("Error fetching username: $e");
      return null;
    }
  }

  Future<bool> isUsernameUnique(String username) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      // Check in students collection
      final studentSnapshot = await students.get();
      for (var doc in studentSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        String existingUserName = userData['userName'] ?? '';

        if (existingUserName.trim().toLowerCase() == username.trim().toLowerCase() &&
            doc.id != currentUid) {
          print('Username already exists in students: ${doc.id}');
          return false;
        }
      }

      // Check in teachers collection
      final teacherSnapshot = await teachers.get();
      for (var doc in teacherSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        String existingUserName = userData['userName'] ?? '';

        if (existingUserName.trim().toLowerCase() == username.trim().toLowerCase() &&
            doc.id != currentUid) {
          print('Username already exists in teachers: ${doc.id}');
          return false;
        }
      }

      // Username is unique across both collections
      return true;
    } catch (e) {
      print("Error checking username uniqueness: $e");
      return false;
    }
  }




  Future<void> updateUsername(String newUsername) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await students.doc(uid).update({'userName': newUsername});
      print("Username updated successfully in Firestore.");
    } catch (e) {
      print("Error updating username: $e");
      throw Exception("Error updating username: $e");
    }
  }

  Future<void> updateTeacherUsername(String newUsername) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await teachers.doc(uid).update({'userName': newUsername});
      print("Username updated successfully in Firestore.");
    } catch (e) {
      print("Error updating username: $e");
      throw Exception("Error updating username: $e");
    }
  }


  Future<bool> studentExists(String uid) async {
    DocumentSnapshot userDoc = await students
        .doc(uid)
        .get();
    return userDoc.exists;
  }

  Future<bool> teacherExists(String uid) async {
    DocumentSnapshot userDoc = await teachers
        .doc(uid)
        .get();
    return userDoc.exists;
  }

  Future<void> createCourse(CourseModel course) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .add(course.toMap());
  }
  Future <void> createLecture(LectureModel lecture) async{
    await FirebaseFirestore.instance
        .collection('lectures').add(lecture.toMap());
  }

  Future<void> addLecturesToCourse(String courseId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch the correct course document by its ID
      DocumentSnapshot courseDoc = await firestore.collection('courses').doc(courseId).get();

      if (courseDoc.exists) {
        final courseData = courseDoc.data() as Map<String, dynamic>;
        final String courseCid = courseData['cid']; // Get the cid of the course

        // Fetch all lectures
        QuerySnapshot lecturesSnapshot = await firestore.collection('lectures').get();

        // Filter lectures whose 'cid' matches the course's 'cid'
        List<String> matchedLectureIds = [];
        for (var doc in lecturesSnapshot.docs) {
          final lectureData = doc.data() as Map<String, dynamic>;
          if (lectureData['cid'] == courseCid) {
            matchedLectureIds.add(doc.id); // Add lecture document id (lid)
          }
        }

        // Now update the course's lectures array
        await firestore.collection('courses').doc(courseId).update({
          'lectures': matchedLectureIds,
        });

        print('Course lectures updated successfully!');
      } else {
        print('Course not found!');
      }
    } catch (e) {
      print('Error updating course lectures: $e');
    }
  }



}
