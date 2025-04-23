import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Data/Firebase/student_services/teacher_model.dart';
import 'package:stem_vault/Shared/teacherbottomnavbar.dart';
import 'package:stem_vault/features/Teacher%20auth/teacher_forgotpasswordpage.dart';
import 'package:stem_vault/features/Teacher%20auth/teacher_signuppage.dart';
import 'package:stem_vault/features/Teacher%20home/assign_username_page.dart';
import '../../Core/appColors.dart';
import '../../Core/apptext.dart';
import '../../Data/Firebase/student_services/firestore_services.dart';
import '../../Data/Firebase/student_services/auth_services.dart';
import '../../Shared/LoadingIndicator.dart';
import '../role_selection_page.dart';


class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVisible = true;
  bool _isLoading = false;
  bool  _isgoogleLoading  = false;
  final _auth = AuthService();
  final FirestoreServices firestoreServices = FirestoreServices();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _auth.teacherSignIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          var userDoc = await firestoreServices.getTeacherData(user.uid);

          if (userDoc != null && userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>?;

            if (userData != null && userData.containsKey('userName') && userData['userName'].isNotEmpty) {
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: TeacherBottomNavBar()));
            } else {
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: AssignTeacherUserNamePage()));
            }
          } else {
            Fluttertoast.showToast(msg: "User data not found.", textColor: Colors.red);
            Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: AssignTeacherUserNamePage()));
          }
        } else {
          Fluttertoast.showToast(msg: "Invalid email or password.", textColor: Colors.red);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Login failed. Please try again.", textColor: Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
        backgroundColor: AppColors.theme,
        appBar: AppBar(
          backgroundColor: AppColors.theme,
          leading: IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageTransition(
                  type: PageTransitionType.leftToRight,
                  duration: Duration(milliseconds: 300),
                  child: RoleSelectionPage(),
                ),
                    (Route<dynamic> route) => false,
              );
            },
            icon: Icon(Icons.arrow_back_ios, color: AppColors.bgColor),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.189,
                      child: Image.asset("assets/Images/Logo.png"),
                    ),
                  ),
                  Center(
                    child: Text("Sign in", style: AppText.authHeadingStyle()),
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: Text(
                      "Enter your email & password to sign in",
                      style: AppText.authHeadingStyle().copyWith(
                          fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.textFieldColor,
                      hintText: "email@domain.com",
                      hintStyle: AppText.hintTextStyle(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter your email' : null,
                  ),
                  SizedBox(height: 13),
                  TextFormField(
                    obscureText: _isVisible,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.textFieldColor,
                      suffixIcon: IconButton(
                        icon: Icon(_isVisible ? Icons.visibility : Icons.visibility_off, size: 18),
                        onPressed: () => setState(() => _isVisible = !_isVisible),
                      ),
                      hintText: "Password",
                      hintStyle: AppText.hintTextStyle(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter your password' : null,
                  ),
                  SizedBox(
                    height: 32,
                    width: MediaQuery.of(context).size.width * 0.97,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: (){
                            Navigator.push(context,   PageTransition(
                              type: PageTransitionType.rightToLeft,
                              duration: Duration(milliseconds: 300),
                              child: TeacherForgotPassword(),
                            ));
                          },
                          child: Text("Forgot Password?",
                            style: TextStyle(
                                color: Color(0xff858597),
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0,top: 20),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "By proceeding, you agree to our ",
                            style: AppText.hintTextStyle().copyWith(
                                fontSize: 9
                            ),
                          ),
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: " and ",
                            style: AppText.hintTextStyle().copyWith(
                                fontSize: 9
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.black,
                      ),
                      child: _isLoading ? LoadingIndicator() : Text("Login", style: AppText.buttonTextStyle()),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(child: Text("- or continue with -", style: AppText.hintTextStyle())),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            _isgoogleLoading = true;
                          });

                          try {
                            final user = await _auth.teacherSignInWithGoogle();

                            if (user != null) {
                              var userDoc = await firestoreServices.getTeacherData(user.uid);

                              if (userDoc!.exists) {
                                Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

                                if (userData != null && userData['userName'] != null && userData['userName'].toString().isNotEmpty) {
                                  // If username exists, navigate to TeacherBottomNavBar
                                  Navigator.pushReplacement(
                                    context,
                                    PageTransition(type: PageTransitionType.rightToLeft, child: TeacherBottomNavBar()),
                                  );
                                } else {
                                  // If username is missing, navigate to AssignTeacherUserNamePage
                                  Navigator.pushReplacement(
                                    context,
                                    PageTransition(type: PageTransitionType.rightToLeft, child: AssignTeacherUserNamePage()),
                                  );
                                }
                              } else {
                                // If user doesn't exist in Firestore, save user data
                                TeacherModel newUser = TeacherModel(
                                  tid: user.uid,
                                  userName: user.displayName ?? "", // Handle null username
                                  email: user.email ?? "", // Handle null email
                                );

                                await firestoreServices.saveTeacherData(newUser);

                                // Navigate to AssignTeacherUserNamePage
                                Navigator.pushReplacement(
                                  context,
                                  PageTransition(type: PageTransitionType.rightToLeft, child: AssignTeacherUserNamePage()),
                                );
                              }
                            } else {
                              Fluttertoast.showToast(msg: "Google sign-in failed. Please try again.", textColor: Colors.red);
                            }
                          } catch (e) {
                            print("Error during Google Sign-In: $e");
                            Fluttertoast.showToast(msg: "An error occurred. Please try again.", textColor: Colors.red);
                          } finally {
                            setState(() {
                              _isgoogleLoading = false; // Hide loading indicator
                            });
                          }
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                          shadowColor: Colors.grey,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Image.asset('assets/Images/google.png', width: 30, height: 30),
                          ),
                        ),
                      ),


                      SizedBox(width: 20),

                      GestureDetector(
                        onTap: () {
                          Fluttertoast.showToast(msg: "This feature is available only on Apple devices.", textColor: Colors.red);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                          shadowColor: Colors.grey,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Image.asset('assets/Images/apple.png', width: 30, height: 30),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: TeacherSignUpPage(),
                        ),
                      );
                    },
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "I don\'t have an account ", style: AppText.hintTextStyle()),
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
        if (_isgoogleLoading)
          Container(
            color: Colors.black.withOpacity(0.5), // Dimmed background
            child: Center(
              child: LoadingIndicator(),
            ),
          ),
    ]
    );
  }
}