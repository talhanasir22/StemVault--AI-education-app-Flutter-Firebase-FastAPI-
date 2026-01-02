import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_vault/Shared/bottomnavbar.dart';
import 'package:stem_vault/Shared/teacherbottomnavbar.dart';
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
    // If the user is already authenticated, bypass role selection and go to appropriate home
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Prefer a centralized users collection with a 'role' flag
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final map = userDoc.data() as Map<String, dynamic>;
          final role = map['role']?.toString();
          if (role == 'teacher') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeacherBottomNavBar()));
            return;
          } else if (role == 'student') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBar()));
            return;
          }
        }
      } catch (e) {
        // ignore and fallthrough to collection checks
      }

      // Fallback: check existing teachers/students collections
      try {
        final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
        if (teacherDoc.exists) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeacherBottomNavBar()));
          return;
        }
      } catch (_) {}

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBar()));
      return;
    }

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
