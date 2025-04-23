import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../Core/appColors.dart';
import '../../../../Core/apptext.dart';
import '../../../../Shared/LoadingIndicator.dart';

class ChangePassword extends StatefulWidget {
  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        bool isGoogleUser =
        user.providerData.any((provider) => provider.providerId == "google.com");

        if (isGoogleUser) {
          Fluttertoast.showToast(
              msg: "You signed in with Google. Password change is not allowed.");
        } else {
          await user.updatePassword(_passwordController.text.trim());
          Fluttertoast.showToast(msg: "Password updated successfully!");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.theme,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios))),
      backgroundColor: AppColors.theme,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Change\nPassword?", style: AppText.authHeadingStyle()),
            SizedBox(height: 20),

            // Wrap TextFormField inside Form
            Form(
              key: _formKey,
              child: Center(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.textFieldColor,
                    prefixIcon:
                    Icon(Icons.lock, color: AppColors.hintIconColor),
                    hintText: "Enter a new password",
                    hintStyle: AppText.hintTextStyle(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) =>
                  (value == null || value.length < 8)
                      ? 'Password must be at least 8 characters'
                      : null,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.87,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "* ",
                          style: AppText.hintTextStyle()
                              .copyWith(color: AppColors.bgColor),
                        ),
                        TextSpan(
                          text: "Password must be at least 8 characters.",
                          style: AppText.hintTextStyle(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.87,
                height: 40,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? LoadingIndicator()
                      : Text("Submit", style: AppText.buttonTextStyle()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
