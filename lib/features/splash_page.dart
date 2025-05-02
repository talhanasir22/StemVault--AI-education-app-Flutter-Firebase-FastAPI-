import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/features/role_selection_page.dart';
import 'onboarding/wrapper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? onboardingComplete = prefs.getBool('onboardingComplete');

    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay
    if (onboardingComplete == true) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => RoleSelectionPage()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Wrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.theme,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.width * 0.95,
              child: Image.asset('assets/Images/Logo.png'),
            ),

          ],
        ),
      ),
    );
  }
}
