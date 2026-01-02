import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../Core/apptext.dart';
import '../../Shared/LoadingIndicator.dart';
import '../../Shared/course_annoucement_banner.dart';
import '../open_lecture_page.dart';

class OpenCoursePage extends StatefulWidget {
  final String cid;
  const OpenCoursePage({Key? key, required this.cid}) : super(key: key);

  @override
  State<OpenCoursePage> createState() => _OpenCoursePageState();
}

class _OpenCoursePageState extends State<OpenCoursePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        automaticallyImplyLeading: false,
        title: Text("Lectures", style: AppText.mainHeadingTextStyle()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CourseAnnouncementBanner(
                bannerText:
                    "Explore a diverse selection of STEM courses for a comprehensive learning experience.",
              ),
            ),
            SizedBox(height: 20),
            _buildLabel('Lectures'),
            Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('lectures')
                        .where('cid', isEqualTo: widget.cid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No lectures yet'));
                  }

                  final userId = FirebaseAuth.instance.currentUser!.uid;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var lectureDoc = snapshot.data!.docs[index];
                      final data =
                          lectureDoc.data() as Map<String, dynamic>? ?? {};
                      String lectureId = lectureDoc.id;
                      final titleText =
                          (data['lectureTitle'] ?? data['title'] ?? 'Untitled')
                              .toString();
                      final urlText =
                          (data['lectureUrl'] ??
                                  data['lecturePdf'] ??
                                  data['lectureFile'] ??
                                  '')
                              .toString();
                      final descText =
                          (data['lectureDescription'] ??
                                  data['description'] ??
                                  '')
                              .toString();

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('studentProgress')
                                .doc(userId)
                                .collection('lectures')
                                .doc(lectureId)
                                .get(),
                        builder: (context, progressSnapshot) {
                          bool isCompleted = false;
                          if (progressSnapshot.hasData &&
                              progressSnapshot.data!.exists) {
                            isCompleted =
                                progressSnapshot.data!.get('isCompleted') ??
                                false;
                          }

                          // Determine whether URL likely points to a video
                          final isVideo =
                              urlText.toLowerCase().contains('.mp4') ||
                              urlText.toLowerCase().contains('.mov') ||
                              urlText.toLowerCase().contains('.webm') ||
                              urlText.toLowerCase().contains('.mkv');

                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: SizedBox(
                              height: 150,
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Card(
                                color: Colors.black,
                                child: InkWell(
                                  onTap: () {
                                    if (urlText.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No lecture media available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        child: OpenLecturePage(
                                          title: titleText,
                                          url: urlText,
                                          description: descText,
                                          lecId: lectureId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                '${index + 1}. $titleText',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: isCompleted,
                                            activeColor: Colors.green,
                                            onChanged: (value) {
                                              FirebaseFirestore.instance
                                                  .collection('studentProgress')
                                                  .doc(userId)
                                                  .collection('lectures')
                                                  .doc(lectureId)
                                                  .set({'isCompleted': value});
                                              setState(
                                                () {},
                                              ); // To refresh the UI
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Icon(
                                            isVideo
                                                ? Icons.play_circle
                                                : Icons.picture_as_pdf,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 25),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            _buildLabel('Course Resources'),
            Container(
              color: Colors.white,
              height: 120,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('course_resources')
                        .where('cid', isEqualTo: widget.cid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No resources yet'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var resource = snapshot.data!.docs[index];
                      final data =
                          resource.data() as Map<String, dynamic>? ?? {};
                      String rid = resource.id;
                      final titleText =
                          (data['title'] ?? 'Untitled').toString();
                      final urlText = (data['url'] ?? '').toString();

                      return SizedBox(
                        height: 100,
                        width: 200,
                        child: Card(
                          color: Colors.blueGrey[900],
                          child: InkWell(
                            onTap: () {
                              if (urlText.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    child: OpenLecturePage(
                                      title: titleText,
                                      url: urlText,
                                      description: "Resource PDF",
                                      lecId: rid,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No PDF URL available'),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: AppText.mainSubHeadingTextStyle().copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
