import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/features/auth/loginpage.dart';
import 'package:stem_vault/features/home/Account%20Screens/assignment_screen.dart';
import 'package:stem_vault/features/home/Account%20Screens/grade_screen.dart';
import 'package:stem_vault/features/home/Account%20Screens/notification_setting_screen.dart';
import 'package:stem_vault/features/home/Account%20Screens/submission%20_screen.dart';
import '../../../Data/Firebase/student_services/auth_services.dart';
import '../../../Data/Firebase/student_services/firestore_services.dart';
import 'Edit Profile Screens/Edit_profile_screen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}
class _AccountPageState extends State<AccountPage> {
  final _auth = AuthService();
  FirestoreServices db = FirestoreServices();
  String? fetchedUsername;
  String _userName = "loading...";
  @override
  void initState() {
    _fetchUserName();
    super.initState();
  }
  Future<void> _fetchUserName() async {
    String? fetchedUsername = await db.getStudentUsername();
    if (fetchedUsername != null) {
      setState(() {
        _userName = fetchedUsername;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Account", style: AppText.mainHeadingTextStyle()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                "Hi, $_userName",
                style: AppText.mainHeadingTextStyle().copyWith(
                  color: AppColors.bgColor,
                ),
              ),
              subtitle: Text(
                "Student",
                style: AppText.mainSubHeadingTextStyle().copyWith(
                  color: AppColors.bgColor,
                ),
              ),
              trailing: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 10,),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.89,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "View Progress",
                        style: AppText.mainHeadingTextStyle().copyWith(
                          color: AppColors.theme,
                          fontSize: 20,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.theme,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// User-friendly prioritized buttons
            _buildTextButton("Edit Profile",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: EditProfileScreen(),
                ),
              );
            }),
            _buildTextButton("Change Notification Settings",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: NotificationSettingScreen(),
                ),
              );
            }),
            _buildTextButton("Due Assignments",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: AssignmentScreen(),
                ),
              );
            }),
            _buildTextButton("Submissions",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: SubmissionScreen(),
                ),
              );
            }),
            _buildTextButton("Grades",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: GradeScreen(),
                ),
              );
            }),
            _buildTextButton("Set Daily Target",(){

            }),
            _buildTextButton("Help",(){}),
            _buildTextButton("Customer Support",(){}),_buildTextButton("Logout", () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Logout"),
                  content: Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        bool isSignedOut = false;

                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await _auth.signOut().then((_){
                            isSignedOut = true;
                          }).timeout(Duration(seconds: 5),onTimeout: (){
                            isSignedOut = false;
                            throw TimeoutException("Sign-out timed out");
                          });
                          Navigator.pop(context);
                          if (isSignedOut) {
                            Navigator.pushReplacementNamed(context, '/login');
                          } else {
                            throw Exception("Sign-out failed");
                          }
                        } catch (e) {
                          // Close loading dialog if error occurs
                          Navigator.pop(context);

                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is TimeoutException ? "Sign-out timeout. Please try again." : "Sign-out failed. Please try again.")),
                          );
                        }
                      },
                      child: Text("Cancel"),
                    ),


                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(context,
                            PageTransition(
                              type: PageTransitionType.leftToRight,
                              duration: Duration(milliseconds: 500),
                              child: LoginPage(),
                            ), (route) =>false);

                      },
                      child: Text("Logout"),
                    ),
                  ],
                ),
              );
            }),

          ],
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed, // Now takes a custom function
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppText.mainSubHeadingTextStyle().copyWith(
              fontSize: 16,
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 20,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

}