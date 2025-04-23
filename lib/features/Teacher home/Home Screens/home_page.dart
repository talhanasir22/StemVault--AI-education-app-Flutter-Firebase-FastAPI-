import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/features/Teacher%20home/Home%20Screens/my_courses.dart';
import 'package:stem_vault/features/Teacher%20home/enrolled_students_page.dart';

import '../../../Data/Firebase/student_services/firestore_services.dart';


class HomePage extends StatefulWidget {
  final Function(int)? onNavIndexChange; // Callback function
  const HomePage({super.key, required this.onNavIndexChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: SizedBox(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 200,),
                    SizedBox(
                      height: 155,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        elevation: 1,
                        color: Color(0xffCEECFE),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text("What do you want to teach?",style: AppText.mainSubHeadingTextStyle().copyWith(
                                  fontWeight: FontWeight.bold
                              ),),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 50.0,left: 10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.onNavIndexChange?.call(1);  // Set index to "Course" tab
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.bgColor,
                                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text("Get Started",style: AppText.buttonTextStyle().copyWith(
                                        color: AppColors.theme
                                    ),),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: Color(0xffCEECFE),
                                  backgroundImage: AssetImage("assets/Images/teacher_home.png"),
                                  radius: 50,
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text("Learning Plan"
                        ,style: AppText.mainHeadingTextStyle().copyWith(
                            fontSize: 18
                        ),),
                    ),
                    SizedBox(
                      height: 130,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        elevation: 1,
                        color: Color(0xffCEECFE),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Center(
                                child: SizedBox(
                                  height: 100,
                                  width: MediaQuery.of(context).size.width * 0.75,
                                  child: Text("Explore, learn, and grow with interactive STEM courses. Track progress, completehands-on exercises, and master new skills.Your journey to innovation starts here!"
                                    ,style: AppText.mainSubHeadingTextStyle().copyWith(
                                        fontWeight: FontWeight.w600
                                    ),),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        elevation: 1,
                        color: AppColors.bgColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(" The STEM Vault"
                              ,style: AppText.mainHeadingTextStyle().copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.theme
                              ),),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: SizedBox(
                                    height: 70,
                                    width: 200,
                                    child: Text("Unlocking Knowledge, Powering Innovation!"
                                      ,style: AppText.mainSubHeadingTextStyle().copyWith(
                                          fontSize: 12
                                      ),),
                                  ),
                                ),
                                Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right:8.0,bottom: 10),
                                  child: Container(
                                    height: 75,
                                    width: 75,
                                    decoration: BoxDecoration(
                                        color: AppColors.theme.withOpacity(0.56),
                                        shape: BoxShape.circle
                                    ),
                                    child: Center(
                                      child:  Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                            color: AppColors.theme.withOpacity(0.8),
                                            shape: BoxShape.circle
                                        ),
                                        child:   Center(
                                          child: Container(
                                            height: 25,
                                            width: 25,
                                            decoration: BoxDecoration(
                                                color: AppColors.theme.withOpacity(1),
                                                shape: BoxShape.circle
                                            ),
                                            child: Center(
                                                child: CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: AppColors.theme,
                                                  backgroundImage: AssetImage("assets/Images/Page2.png"),
                                                )),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 180,
            color: AppColors.bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, $_userName",
                  style: AppText.mainHeadingTextStyle().copyWith(
                    color: AppColors.theme,
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: Text(
                    "Teacher",
                    style: AppText.mainSubHeadingTextStyle().copyWith(
                      color: AppColors.theme,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Avatars at Top Right
          Positioned(
            top: 50,
            right: 10,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.theme,
                  backgroundImage: const AssetImage("assets/Images/User.png"),
                ),
              ],
            ),
          ),
          Positioned(
            top: 130,
            left: MediaQuery.of(context).size.width * 0.075,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.theme,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          PageTransition(type: PageTransitionType.rightToLeft,
                              child: MyCourse()
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgColor,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("My Courses",style: AppText.buttonTextStyle().copyWith(
                        color: AppColors.theme
                    ),),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          PageTransition(type: PageTransitionType.rightToLeft,
                          child: EnrolledStudentPage()
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgColor,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("My Students",style: AppText.buttonTextStyle().copyWith(
                      color: AppColors.theme
                    ),),
                  ),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }
}
