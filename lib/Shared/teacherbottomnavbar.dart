import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Core/appColors.dart';
import '../Core/apptext.dart';
import '../features/Teacher home/Account Screens/account_page.dart';
import '../features/Teacher home/Home Screens/home_page.dart';
import '../features/Teacher home/chat_page.dart';
import '../features/Teacher home/course_page.dart';
import '../features/Teacher home/enrolled_students_page.dart';

class TeacherBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const TeacherBottomNavBar({super.key, this.initialIndex = 0});

  @override
  _TeacherBottomNavBarState createState() => _TeacherBottomNavBarState();
}

class _TeacherBottomNavBarState extends State<TeacherBottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _updateNavIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages = [
    HomePage(onNavIndexChange: _updateNavIndex), // Pass callback function
    CoursePage(),
    Container(),
    ChatPage(),
    AccountPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: _pages[_selectedIndex],

          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: Offset(0, -2), // Shadow on top of navbar
                  ),
                ],
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedLabelStyle: AppText.navSelectedLabelTextStyle(),
                unselectedLabelStyle: AppText.navUnSelectedLabelTextStyle(),
                selectedItemColor: AppColors.bgColor,
                unselectedItemColor: Colors.black,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 22),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book, size: 22),
                    label: "Course",
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox.shrink(),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat, size: 22),
                    label: "Message",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person, size: 22),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 28,
          child: FloatingActionButton(
            backgroundColor: AppColors.theme,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EnrolledStudentPage()),
              );
            },
            shape: CircleBorder(side: BorderSide(color: Colors.grey)),
            child: Icon(Icons.school, color: Colors.black, size: 25),
          ),
        ),
      ],
    );
  }
}
