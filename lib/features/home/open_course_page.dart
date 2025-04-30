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
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios)),
        automaticallyImplyLeading: false,
        title: Text(
          "Lectures",
          style: AppText.mainHeadingTextStyle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CourseAnnouncementBanner(
                bannerText: "Explore a diverse selection of STEM courses for a comprehensive learning experience.",
              ),
            ),
            SizedBox(height: 20),
            _buildLabel('Lectures'),
            Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
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
                      String lectureId = lectureDoc.id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('studentProgress')
                            .doc(userId)
                            .collection('lectures')
                            .doc(lectureId)
                            .get(),
                        builder: (context, progressSnapshot) {
                          bool isCompleted = false;
                          if (progressSnapshot.hasData && progressSnapshot.data!.exists) {
                            isCompleted = progressSnapshot.data!.get('isCompleted') ?? false;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: SizedBox(
                              height: 150,
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Card(
                                color: Colors.black,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        child: OpenLecturePage(
                                          title: '${lectureDoc['lectureTitle']}',
                                          url: '${lectureDoc['lectureUrl']}',
                                          description: '${lectureDoc['lectureDescription']}',
                                          lecId: lectureId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                '${index + 1}. ${lectureDoc['lectureTitle']}',
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
                                              setState(() {}); // To refresh the UI
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Icon(
                                            Icons.play_circle,
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
        style: AppText.mainSubHeadingTextStyle().copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
