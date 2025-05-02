import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/features/home/Account%20Screens/notification_setting_screen.dart';
import 'package:stem_vault/features/home/Account%20Screens/submission%20_screen.dart';
import 'package:stem_vault/features/role_selection_page.dart';

import '../../../Data/Firebase/student_services/firestore_services.dart';
import 'Edit Profile Screens/Edit_profile_screen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  FirestoreServices db = FirestoreServices();
  String? fetchedUsername;
  String _userName = "loading...";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserName();
  }
  Future<void> _fetchUserName() async {
    String? fetchedUsername = await db.getTeacherUsername();
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
                "Teacher",
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
            _buildTextButton("Submissions by students",(){
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: SubmissionScreen(),
                ),
              );
            }),
            _buildTextButton("Help",(){}),
            _buildTextButton("Customer Support",(){}),
            _buildTextButton("Logout", () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Logout"),
                  content: Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(context,
                            PageTransition(type: PageTransitionType.leftToRight,
                            child: RoleSelectionPage()), (route)=>false);
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