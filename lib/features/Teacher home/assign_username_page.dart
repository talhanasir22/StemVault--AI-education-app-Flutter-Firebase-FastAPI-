import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_vault/features/Teacher home/success_page.dart';
import '../../Core/appColors.dart';
import '../../Core/apptext.dart';
import '../../Data/Firebase/student_services/firestore_services.dart';
import '../../Shared/LoadingIndicator.dart';

class AssignTeacherUserNamePage extends StatefulWidget {
  @override
  State<AssignTeacherUserNamePage> createState() => _AssignTeacherUserNamePageState();
}

class _AssignTeacherUserNamePageState extends State<AssignTeacherUserNamePage> {
  final _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveUserName() async {
    try {
      // Get current user's UID
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception("User is not logged in");
      }

      // Save username inside either 'students' or 'teachers' collection
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(uid)
          .set({
        'userName': _userNameController.text.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Ensures data is merged instead of overwritten
    } catch (e) {
      print("Error saving username: $e");
      Fluttertoast.showToast(msg: "Failed to save username. Try again.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.theme,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.189,
                    child: Image.asset("assets/Images/Logo.png"),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "Enter",
                      style: AppText.onboardingHeadingStyle(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    "Your Username",
                    textAlign: TextAlign.center,
                    style: AppText.onboardingHeadingStyle().copyWith(color: AppColors.bgColor),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _userNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.textFieldColor,
                      hintText: "Enter here",
                      hintStyle: AppText.hintTextStyle(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter your username' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          final FirestoreServices firestoreservices = new FirestoreServices();
                          bool isUnique = await firestoreservices.isUsernameUnique(_userNameController.text.trim().toLowerCase());
                          if (!isUnique) {
                            Fluttertoast.showToast(msg: "Username is already taken. Please choose another.");
                            setState(() {
                              _isLoading = false;
                            });
                            return; // Exit the function early
                          }

                          await _saveUserName(); // Save username to Firestore
                          if (mounted) {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.leftToRight,
                                duration: Duration(milliseconds: 500),
                                child: SuccessPage(),
                              ),
                            );
                          }

                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.black,
                      ),
                      child: _isLoading
                          ? LoadingIndicator()
                          : Text("Next", style: AppText.buttonTextStyle()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
