import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hexagon/hexagon.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/features/Teacher%20auth/teacher_loginpage.dart';
import 'package:stem_vault/features/auth/loginpage.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.theme,
        body: SingleChildScrollView(
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
                  "Choose",
                  style: AppText.onboardingHeadingStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                "Your Account",
                textAlign: TextAlign.center,
                style: AppText.onboardingHeadingStyle().copyWith(
                  color: AppColors.bgColor,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Transform.rotate(
                        angle: 33,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: const Duration(milliseconds: 300),
                                child: TeacherLoginPage(),
                              ),
                            );
                          },
                          child: HexagonWidget.flat(
                            width: 150,
                            height: 160,
                            color: AppColors.bgColor,
                            cornerRadius: 10,
                            child: Transform.rotate(
                              angle: 4.7,
                              child: SizedBox(
                                height: 110,
                                child: Image.asset("assets/Images/teacher.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text("Teacher", style: AppText.descriptionTextStyle()),
                    ],
                  ),
                  const SizedBox(width: 10), // Added spacing
                  Column(
                    children: [
                      Transform.rotate(
                        angle: 33,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: const Duration(milliseconds: 300),
                                child: LoginPage(),
                              ),
                            );
                          },
                          child: HexagonWidget.flat(
                            width: 150,
                            height: 160,
                            color: AppColors.bgColor,
                            cornerRadius: 10,
                            child: Transform.rotate(
                              angle: 4.7,
                              child: SizedBox(
                                height: 110,
                                child: Image.asset("assets/Images/student.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text("Student", style: AppText.descriptionTextStyle()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
