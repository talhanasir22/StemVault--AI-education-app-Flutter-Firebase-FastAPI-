import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stem_vault/Data/Firebase/student_services/student_model.dart';
import 'package:stem_vault/Data/Firebase/student_services/teacher_model.dart';
import 'firestore_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreServices _firestoreServices = FirestoreServices();



  // Common Sign-Up Handler
  Future<User?> StudentSignUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? student = userCredential.user;

      if (student != null) {
        // Create UserModel instance
        StudentModel newStudent = StudentModel(
          sid: student.uid,
          userName: student.displayName ?? "", // Set empty if null
          email: email,
        );

        await _firestoreServices.saveStudentData(newStudent);
        await student.reload();

        // Show success message
        Fluttertoast.showToast(msg: "Student Registered Successfully!");
        return student;
      } else {
        Fluttertoast.showToast(msg: "Student creation failed!");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      showFirebaseError(e);
      return null;
    }
  }

  Future<User?> TeacherSignUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? teacher = userCredential.user;

      if (teacher != null) {
        // Create UserModel instance
        TeacherModel newTeacher = TeacherModel(
          tid: teacher.uid,
          userName: teacher.displayName ?? "", // Set empty if null
          email: email,
        );

        await _firestoreServices.saveTeacherData(newTeacher);
        await teacher.reload();

        // Show success message
        Fluttertoast.showToast(msg: "Teacher Registered Successfully!");
        return teacher;
      } else {
        Fluttertoast.showToast(msg: "Teacher creation failed!");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      showFirebaseError(e);
      return null;
    }
  }

  // Common Sign-In Handler
  Future<User?> studentSignIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? student = userCredential.user;

      if (student != null) {
        bool exists = await _firestoreServices.studentExists(student.uid);

        if (!exists) {
          // Create a new UserModel instance
          StudentModel newUser = StudentModel(
            sid: student.uid,
            userName: student.displayName ?? "", // Handle null username
            email: email,
          );

          // Save user data to Firestore
          await _firestoreServices.saveStudentData(newUser);
        }
        // Reload user after Firestore update
        await student.reload();

        Fluttertoast.showToast(msg: "Student Logged In Successfully!");
        return student;
      } else {
        Fluttertoast.showToast(msg: "Student sign-in failed!");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      showFirebaseError(e);
      return null;
    }
  }
  Future<User?> teacherSignIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? teacher = userCredential.user;

      if (teacher != null) {
        bool exists = await _firestoreServices.teacherExists(teacher.uid);

        if (!exists) {
          // Create a new UserModel instance
          TeacherModel newUser = TeacherModel(
            tid: teacher.uid,
            userName: teacher.displayName ?? "", // Handle null username
            email: email,
          );

          // Save user data to Firestore
          await _firestoreServices.saveTeacherData(newUser);
        }
        // Reload user after Firestore update
        await teacher.reload();

        Fluttertoast.showToast(msg: "Teacher Logged In Successfully!");
        return teacher;
      } else {
        Fluttertoast.showToast(msg: "Teacher sign-in failed!");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      showFirebaseError(e);
      return null;
    }
  }


  // Google Sign-In Handler
  Future<User?> studentSignInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Fluttertoast.showToast(msg: "Google Sign-In canceled.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        bool exists = await _firestoreServices.studentExists(user.uid);

        if (!exists) {
          // Create a UserModel instance
          StudentModel newUser = StudentModel(
            sid: user.uid,
            userName: user.displayName ?? "", // Ensure no null issue
            email: user.email ?? "", // Ensure no null issue
          );
          await _firestoreServices.saveStudentData(newUser);
        }

        // Reload user after Firestore update
        await user.reload();

        Fluttertoast.showToast(msg: "Signed in as ${user.displayName ?? 'User'}");
        return user;
      } else {
        Fluttertoast.showToast(msg: "User sign-in failed!");
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
      return null;
    }
  }
  Future<User?> teacherSignInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Fluttertoast.showToast(msg: "Google Sign-In canceled.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        bool exists = await _firestoreServices.teacherExists(user.uid);

        if (!exists) {
          // Create a UserModel instance
          TeacherModel newUser = TeacherModel(
            tid: user.uid,
            userName: user.displayName ?? "", // Ensure no null issue
            email: user.email ?? "", // Ensure no null issue
          );
          await _firestoreServices.saveTeacherData(newUser);
        }

        // Reload user after Firestore update
        await user.reload();

        Fluttertoast.showToast(msg: "Signed in as ${user.displayName ?? 'User'}");
        return user;
      } else {
        Fluttertoast.showToast(msg: "User sign-in failed!");
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
      return null;
    }
  }

  // Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: "Password reset link sent to your email!");
    } on FirebaseAuthException catch (e) {
      showFirebaseError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: "Logged Out Successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error Logging Out: ${e.toString()}");
    }
  }

  // Handle Firebase Errors
  void showFirebaseError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'invalid-email':
        message = "Invalid email format!";
        break;
      case 'user-not-found':
        message = "No account found with this email!";
        break;
      case 'wrong-password':
        message = "Incorrect password!";
        break;
      case 'email-already-in-use':
        message = "Email is already registered!";
        break;
      case 'weak-password':
        message = "Password is too weak!";
        break;
      default:
        message = "Authentication error: ${e.message}";
        break;
    }
    Fluttertoast.showToast(msg: message);
  }
}
