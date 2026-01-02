import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../Core/appColors.dart';
import '../../Core/apptext.dart';
import '../features/home/Account Screens/account_page.dart';
import '../features/home/Home Screens/home_page.dart';
import '../features/home/chat_page.dart';
import '../features/home/course_page.dart';
import '../features/home/search_page.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex; // New parameter to set index initially

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;
  DateTime? currentBackPressTime;

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

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: "Press back again to exit",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
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
                      offset: Offset(0, -2),
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
                    BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
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
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
              },
              shape: CircleBorder(side: BorderSide(color: Colors.grey)),
              child: Icon(Icons.search, color: Colors.black, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
