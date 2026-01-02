import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage>
    with SingleTickerProviderStateMixin {
  String? selectedCategory;
  String? selectedDuration;
  late TabController _tabController;
  List<String> tidList = [];
  List<String> cidList = [];
  List<String> courseTitleList = [];
  int selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String sid = FirebaseAuth.instance.currentUser!.uid;

  final List<String> categories = [
    'SCIENCE',
    'TECHNOLOGY',
    'ENGINEERING',
    'MATH',
  ];

  final List<String> durations = [
    "0-2 Hours",
    "3-8 Hours",
    "8-14 Hours",
    "14-20 Hours",
    "20-24 Hours",
    "24-30 Hours",
  ];

  @override
  void initState() {
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  bool isEnrolling = false; // add this in your _CoursePageState

  Future<void> enrollStudent(String courseId, String studentId) async {
    setState(() {
      isEnrolling = true;
    });

    try {
      // Firestore references
      DocumentReference courseRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId);
      DocumentReference studentRef = FirebaseFirestore.instance
          .collection('students')
          .doc(studentId);

      // Fetch documents
      DocumentSnapshot courseSnapshot = await courseRef.get();
      DocumentSnapshot studentSnapshot = await studentRef.get();

      if (courseSnapshot.exists && studentSnapshot.exists) {
        // Enroll student in course
        List enrolledStudents = courseSnapshot['enrolledStudents'] ?? [];
        if (!enrolledStudents.contains(studentId)) {
          enrolledStudents.add(studentId);
          await courseRef.update({'enrolledStudents': enrolledStudents});
        }

        // Get the 'cid' field from course document
        String cid = courseSnapshot['cid'];

        // Add 'cid' to student's enrolledCourses
        List enrolledCourses = studentSnapshot['enrolledCourses'] ?? [];
        if (!enrolledCourses.contains(cid)) {
          enrolledCourses.add(cid);
          await studentRef.update({'enrolledCourses': enrolledCourses});
        }

        Fluttertoast.showToast(
          msg: "Student enrolled successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        print('Student enrolled successfully');
        setState(() {}); // refresh the page
      } else {
        print('Course or student not found');
      }
    } catch (e) {
      print('Error enrolling student: $e');
    } finally {
      setState(() {
        isEnrolling = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoursesWithTeachers({
    String? query,
  }) async {
    String? selectedTag;
    if (_tabController.index > 0) {
      selectedTag = categories[_tabController.index - 1];
    }

    Query courseQuery = FirebaseFirestore.instance.collection('courses');
    if (selectedTag != null) {
      courseQuery = courseQuery.where('tag', isEqualTo: selectedTag);
    }

    final courseSnapshot = await courseQuery.get();
    final teacherSnapshot =
        await FirebaseFirestore.instance.collection('teachers').get();

    final teacherMap = {
      for (var doc in teacherSnapshot.docs) doc['tid']: doc['userName'],
    };

    List<Map<String, dynamic>> mergedList = [];
    cidList.clear();

    for (var course in courseSnapshot.docs) {
      final enrolledStudents = List<String>.from(
        course['enrolledStudents'] ?? [],
      );

      // Skip course if current student is already enrolled
      if (enrolledStudents.contains(sid)) continue;

      final courseTitle = course['courseTitle'].toString().toLowerCase();
      if (query != null && query.isNotEmpty && !courseTitle.contains(query)) {
        continue;
      }

      cidList.add(course.id);

      mergedList.add({
        'courseTitle': course['courseTitle'],
        'thumbnailUrl': course['thumbnailUrl'],
        'teacherName': teacherMap[course['tid']] ?? 'Unknown',
      });
    }

    return mergedList;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // Maintains state when reopened
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Search Filter",
                        style: AppText.mainHeadingTextStyle()
                            .copyWith(fontWeight: FontWeight.w400, fontSize: 22)
                            .copyWith(color: AppColors.theme),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Categories",
                      style: AppText.mainHeadingTextStyle().copyWith(
                        color: AppColors.theme,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children:
                          categories.map((category) {
                            bool isSelected = category == selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedCategory =
                                      isSelected ? null : category;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bgColor),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? AppColors.bgColor
                                            : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Duration",
                      style: AppText.mainHeadingTextStyle().copyWith(
                        color: AppColors.theme,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children:
                          durations.map((duration) {
                            bool isSelected = duration == selectedDuration;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedDuration =
                                      isSelected
                                          ? null
                                          : duration; // Toggle selection
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bgColor),
                                ),
                                child: Text(
                                  duration,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? AppColors.bgColor
                                            : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the modal
                            },
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: AppColors.bgColor,
                            ),
                            child: Text(
                              "Clear",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the modal
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Apply Filter",
                              style: TextStyle(color: AppColors.bgColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Choose Your Course",
          style: AppText.mainHeadingTextStyle(),
        ),
      ),
      body: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.90,
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // simple case-insensitive search
                  });
                },
                style: TextStyle(fontSize: 14),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  hintText: "Find Course",
                  hintStyle: AppText.hintTextStyle(),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.hintIconColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _showFilterBottomSheet,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: AppColors.hintIconColor,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.textFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          CourseAnnouncementBanner(
            bannerText:
                "Explore a diverse selection of STEM courses for a comprehensive learning experience.",
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 15.0,
              bottom: 10,
            ), // Added bottom padding
            child: SizedBox(
              height: 30, // Adjust height as needed
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // Total number of tabs
                itemBuilder: (context, index) {
                  List<String> tabTitles = [
                    "All",
                    "Science",
                    "Technology",
                    "Engineering",
                    "Mathematics",
                  ];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 1,
                      left: index == 0 ? 16 : 8,
                      right: 8,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTabIndex = index;
                        });
                        _tabController.animateTo(index);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _tabController.index == index
                                ? Colors.black
                                : Colors.white,
                        foregroundColor:
                            _tabController.index == index
                                ? Colors.white
                                : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(tabTitles[index]),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 15),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(selectedTabIndex),
              future: fetchCoursesWithTeachers(query: searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListTile(
                          leading: Container(
                            height: 80,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          title: Container(
                            height: 10,
                            width: 100,
                            color: Colors.white,
                          ),
                          subtitle: Container(
                            height: 10,
                            width: 150,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No courses found'));
                }

                final courseList = snapshot.data!;

                return ListView.builder(
                  itemCount: courseList.length,
                  itemBuilder: (context, index) {
                    var course = courseList[index];
                    var title = course['courseTitle'];
                    var imageUrl = course['thumbnailUrl'];
                    var teacherName =
                        course['teacherName'] ?? 'Unknown Teacher';

                    return Card(
                      color: AppColors.theme,
                      elevation: 1,
                      shadowColor: Colors.grey,
                      child: ListTile(
                        leading: Container(
                          height: 80,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: AppText.mainSubHeadingTextStyle().copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.person, size: 12),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                teacherName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFFEBF0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: 40,
                              child: Text(
                                ' 0-2h',
                                style: TextStyle(color: Color(0xffFF6905)),
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          height: 30,
                          width: 95,
                          child: ElevatedButton(
                            onPressed: () async {
                              String studentId = sid;
                              String courseId = cidList[index];
                              // Directly enroll without payment
                              await enrollStudent(courseId, studentId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgColor,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              "Enroll Now",
                              style: AppText.buttonTextStyle().copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
