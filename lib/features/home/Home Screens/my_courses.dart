import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/features/home/open_course_page.dart';
import '../../../Core/appColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCourse extends StatefulWidget {
  const MyCourse({super.key});

  @override
  State<MyCourse> createState() => _MyCourseState();
}

class _MyCourseState extends State<MyCourse> {
  bool isLoading = true;

  List<String> courseTitles = [];
  List<String> courseIds = [];


  List<Color> cardColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
  ];

  List<double> progressValues = [0.6, 1.0, 0.4, 0.7, 0.5];
  List<String> progressText = ["14/60", "48/60", "10/60", "60/60", "30/60"];

  @override
  void initState() {
    super.initState();
    fetchEnrolledCourses();
  }

  Future<void> fetchEnrolledCourses() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch all courses
      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .get();

      List<String> titles = [];
      List<String> ids = [];
      List<double> newProgressValues = [];
      List<String> newProgressTexts = [];

      for (var doc in coursesSnapshot.docs) {
        final List<dynamic> enrolledStudents = doc['enrolledStudents'] ?? [];

        if (enrolledStudents.contains(uid)) {
          final String cid = doc['cid'];
          titles.add(doc['courseTitle']);
          ids.add(cid);

          // Fetch lectures for this course
          QuerySnapshot lecturesSnapshot = await FirebaseFirestore.instance
              .collection('lectures')
              .where('cid', isEqualTo: cid)
              .get();

          int totalLectures = lecturesSnapshot.docs.length;
          int completedLectures = 0;
          int incompleteLectures = 0;

          // Fetch the student's progress document from the 'studentProgress' collection
          DocumentSnapshot studentProgressDoc = await FirebaseFirestore.instance
              .collection('studentProgress')
              .doc('ReCozybMQQgBD7b4XCf02eyQS5g1')
              .get();

          if (studentProgressDoc.exists) {
            // Fetch the 'lectures' sub-collection inside 'studentProgress'
            QuerySnapshot studentLecturesSnapshot = await FirebaseFirestore.instance
                .collection('studentProgress')
                .doc('ReCozybMQQgBD7b4XCf02eyQS5g1')
                .collection('lectures')
                .get();

            // Loop through each lecture in the 'lectures' sub-collection inside the student's progress document
            for (var progressDoc in studentLecturesSnapshot.docs) {
              final String lectureId = progressDoc.id;

              // Check if the lecture exists in the main 'lectures' collection
              var matchedLectures = lecturesSnapshot.docs.where(
                    (lectureDoc) => lectureDoc.id == lectureId,
              ).toList();

              if (matchedLectures.isNotEmpty) {
                bool isCompleted = progressDoc['isCompleted'] ?? false;
                print('Lecture ID: $lectureId, isCompleted: $isCompleted');

                if (isCompleted) {
                  completedLectures++;
                } else {
                  incompleteLectures++;
                }
              } else {
                print('No matching lecture found for lectureId: $lectureId');
              }
            }
          } else {
            print('No student progress found for UID: $uid');
          }

          // Calculate progress percentage
          double progress = totalLectures > 0 ? completedLectures / totalLectures : 0.0;

          // Update progress values and text
          newProgressValues.add(progress);
          newProgressTexts.add('$completedLectures/$totalLectures');
        }
      }

      setState(() {
        courseTitles = titles;
        courseIds = ids;
        progressValues = newProgressValues;
        progressText = newProgressTexts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching courses: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


// Helper to chunk list into sublists of length n
  List<List<String>> _chunkList(List<String> list, int size) {
    List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
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
          Center(
            child: Container(
              height: 100,
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(12),
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
              child: isLoading
                  ? _buildShimmerFirstContainer()
                  : _buildFirstContainerContent(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: isLoading ? 5 : courseTitles.length,
                itemBuilder: (context, index) {
                  return isLoading
                      ? _buildShimmerGridItem()
                      : _buildGridItem(index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFirstContainer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
    );
  }

  Widget _buildFirstContainerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Learned Today", style: AppText.hintTextStyle()),
        const SizedBox(height: 5),
        RichText(
          text: TextSpan(
            text: "0",
            style: AppText.mainHeadingTextStyle(),
            children: [
              TextSpan(
                text: "/60min",
                style: AppText.hintTextStyle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: 0.0,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ],
    );
  }

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
                  Icon(Icons.play_circle, color: Colors.white, size: 40)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int index) {
    return Card(
      elevation: 10,
      shadowColor: Colors.black,
      color: cardColors[index % cardColors.length],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseTitles[index],
              style: AppText.mainHeadingTextStyle().copyWith(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            LinearProgressIndicator(
              value: progressValues[index % progressValues.length],
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            Text(
              progressValues[index] == 1.0 ? "Completed" : "Incomplete",
              style: AppText.mainSubHeadingTextStyle().copyWith(
                color: Colors.white,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progressText[index % progressText.length],
                  style: AppText.mainSubHeadingTextStyle().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    print(courseIds[index]);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: OpenCoursePage(cid: courseIds[index]),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle, color: Colors.white, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
