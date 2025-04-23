import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../Core/appColors.dart';
import '../../../../Core/apptext.dart';
import '../../../../Data/Firebase/student_services/firestore_services.dart';
import '../../../../Shared/LoadingIndicator.dart';

class ChangeUserName extends StatefulWidget {
  @override
  State<ChangeUserName> createState() => _ChangeUserNameState();
}

class _ChangeUserNameState extends State<ChangeUserName> {
  final _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _db = FirestoreServices();

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  /// Function to update username in Firestore
  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String newUsername = _userNameController.text.trim();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid; // Get UID

        bool isUnique = await _db.isUsernameUnique(newUsername.toLowerCase());

        // If username is not unique, show toast and return early
        if (!isUnique) {
          Fluttertoast.showToast(msg: "Username is already taken. Please choose another.");
          setState(() {
            _isLoading = false;
          });
          return; // Exit the function early
        }

        await _db.updateTeacherUsername(newUsername);

        Fluttertoast.showToast(msg: "Username updated successfully!");
        Navigator.pop(context); // Go back after update
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      backgroundColor: AppColors.theme,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Change\nUserName?", style: AppText.authHeadingStyle()),
            SizedBox(height: 20),

            // Wrap TextFormField inside Form
            Form(
              key: _formKey,
              child: Center(
                child: TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.textFieldColor,
                    prefixIcon: Icon(Icons.person, color: AppColors.hintIconColor),
                    hintText: "Enter new username",
                    hintStyle: AppText.hintTextStyle(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
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
                          style: AppText.hintTextStyle().copyWith(color: AppColors.bgColor),
                        ),
                        TextSpan(
                          text: "The username must be unique and cannot match an existing one.",
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
                  onPressed: _isLoading ? null : _updateUsername,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.black,
                  ),
                  child: _isLoading ? LoadingIndicator() : Text("Submit", style: AppText.buttonTextStyle()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
