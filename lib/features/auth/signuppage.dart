import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import '../../Core/appColors.dart';
import '../../Core/apptext.dart';
import '../../Shared/LoadingIndicator.dart';
import 'loginpage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVisible = true;
  bool _isConfirmVisible = true;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: "Passwords do not match",textColor: Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Fluttertoast.showToast(msg: "Sign up Successful",textColor: Colors.green);
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          duration: Duration(milliseconds: 300),
          child: LoginPage(),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(),textColor: Colors.red);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.theme,
      appBar: AppBar(
        backgroundColor: AppColors.theme,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
                  child: Text("Create an account", style: AppText.authHeadingStyle()),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "email@domain.com",
                    hintStyle: AppText.hintTextStyle(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your email' : null,
                ),
                SizedBox(height: 13),
                TextFormField(
                  obscureText: _isVisible,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: AppText.hintTextStyle(),
                    suffixIcon: IconButton(
                      icon: Icon(_isVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isVisible = !_isVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                ),
                SizedBox(height: 13),
                TextFormField(
                  obscureText: _isConfirmVisible,
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    hintStyle: AppText.hintTextStyle(),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please confirm your password' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0,top: 10),
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
                  width: MediaQuery.of(context).size.width * 0.97,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.black,
                    ),
                    child: _isLoading ? LoadingIndicator() : Text("SignUp", style: AppText.buttonTextStyle()),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageTransition(
                        type: PageTransitionType.leftToRight,
                        duration: Duration(milliseconds: 300),
                        child: LoginPage(),
                      ),
                          (Route<dynamic> route) => false,
                    );
                  },
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: "Existing User? ", style: AppText.hintTextStyle()),
                          TextSpan(
                            text: "Login now",
                            style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}