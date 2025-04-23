import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';
import 'package:stem_vault/features/Teacher%20home/Home%20Screens/set_assignment.dart';
import '../../../Core/appColors.dart';
import '../UpdatedCoursePage.dart';
class MyCourse extends StatefulWidget {
  const MyCourse({super.key});

  @override
  State<MyCourse> createState() => _MyCourseState();
}

class _MyCourseState extends State<MyCourse> {
  bool isLoading = true; // Control shimmer loading state

  List<String> courseTitles = [];
  List<Color> cardColors = [];
  List<String> courseCids = [];

  final List<Color> availableColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
    Colors.teal.shade400,
    Colors.indigo.shade400,
    Colors.deepOrange.shade400,
    Colors.pink.shade400,
    Colors.amber.shade400,
  ];



  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('courses').get();

      List<String> fetchedTitles = [];
      List<Color> fetchedColors = [];
      List<String> fetchedCids = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['courseTitle'] != null) {
          fetchedTitles.add(data['courseTitle']);
          fetchedColors.add((availableColors..shuffle()).first); // Random color
          fetchedCids.add(data['cid']);
        }
      }

      setState(() {
        courseTitles = fetchedTitles;
        cardColors = fetchedColors;
        courseCids = fetchedCids;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          "My Courses",
          style: AppText.mainHeadingTextStyle(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          /// First Container (Shimmer Effect Applied)
          Center(
            child: isLoading
                ? _buildShimmerFirstContainer() // Show shimmer effect
                : CourseAnnouncementBanner(bannerText: "Manage courses, & assign assignments\nAll in one place.",),
          ),

          const SizedBox(height: 20),

          /// GridView (Shimmer Applied)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return isLoading
                      ? _buildShimmerGridItem()
                      : _buildGridItem(context,index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Shimmer Effect for First Container**
  Widget _buildShimmerFirstContainer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.theme,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 15, width: 100, color: Colors.white),
            const SizedBox(height: 5),
            Container(height: 20, width: 80, color: Colors.white),
            const SizedBox(height: 5),
            Container(height: 8, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// **Shimmer Effect for Grid Items**
  Widget _buildShimmerGridItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 20, width: 120, color: Colors.white),
              Container(height: 8, width: double.infinity, color: Colors.white),
              Container(height: 15, width: 80, color: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 20, width: 50, color: Colors.white),
                  Icon(Icons.play_circle, size: 40, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Actual Grid Items**
  Widget _buildGridItem(BuildContext context, int index) {
    // Check for index bounds to avoid crash
    if (index >= courseTitles.length || index >= cardColors.length) {
      return const SizedBox(); // Return empty widget if index is out of range
    }

    return Card(
      elevation: 10,
      shadowColor: Colors.black,
      color: cardColors[index],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                courseTitles[index],
                style: AppText.mainHeadingTextStyle().copyWith(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallCard(
                  title: "Student Enrolled",
                  subtitle: "3",
                ),
                _buildSmallCard(
                  title: "Edit your course",
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: UpdateCoursePage(
                          cid: courseCids[index], // Passing the cid here
                        ),
                      ),
                    );
                  },
                ),
                _buildSmallCard(
                  title: "Set\nAssignment",
                  icon: Icons.menu_book,
                  fontSize: 12,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: SetAssignment(),
                        type: PageTransitionType.rightToLeft,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper function to reduce code repetition
  Widget _buildSmallCard({
    required String title,
    String? subtitle,
    IconData? icon,
    double fontSize = 14,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 75,
      width: 95,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 10,
          color: AppColors.bgColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  title,
                  style: AppText.mainSubHeadingTextStyle().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: AppColors.theme,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null)
                Center(
                  child: Text(
                    subtitle,
                    style: AppText.mainSubHeadingTextStyle().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme,
                    ),
                  ),
                )
              else if (icon != null)
                Center(
                  child: Icon(
                    icon,
                    color: AppColors.theme,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
