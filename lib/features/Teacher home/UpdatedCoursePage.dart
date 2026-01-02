import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stem_vault/Data/Cloudinary/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';
import 'package:stem_vault/features/open_lecture_page.dart';
import 'package:stem_vault/features/Teacher%20home/submissions_page.dart';
import 'package:stem_vault/features/Teacher%20home/ai_lecture_generator.dart';
import 'package:stem_vault/features/Teacher%20home/CourseSingleVideoGenerationPage.dart';
import '../../Data/Firebase/student_services/firestore_services.dart';
import '../../Data/Firebase/student_services/lecture_model.dart';
import '../../Shared/LoadingIndicator.dart';

class UpdateCoursePage extends StatefulWidget {
  final String cid;
  const UpdateCoursePage({Key? key, required this.cid}) : super(key: key);

  @override
  State<UpdateCoursePage> createState() => _UpdateCoursePageState();
}

class _UpdateCoursePageState extends State<UpdateCoursePage>
    with SingleTickerProviderStateMixin {
  String? selectedDuration;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String courseId = FirebaseFirestore.instance.collection("courses").doc().id;

  File? _selectedVideo;
  late String lectureUrl;
  late String newLectureId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('Editing course with ID: ${widget.cid}');
  }

  void _validatePickedVideo(XFile? pickedFile) {
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final allowed = [
        'mp4',
        'mov',
        'avi',
        'mkv',
        'flv',
        'wmv',
        'webm',
        'mpeg',
        '3gp',
      ].contains(extension);

      if (allowed) {
        setState(() {
          _selectedVideo = file;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Unsupported video format. Please select a valid video file.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: AILectureGeneratorPage(cid: widget.cid),
            ),
          );
        },
        icon: const Icon(Icons.smart_toy),
        label: const Text('AI'),
        backgroundColor: AppColors.bgColor,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          "Tell us what do you \nwant to teach",
          style: AppText.mainHeadingTextStyle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 6.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CourseAnnouncementBanner(
                  bannerText:
                      "Explore a diverse selection of STEM courses for a comprehensive learning experience.",
                ),
              ),
              _buildLabel('My Lectures'),
              Container(
                color: Colors.white,
                height: 120,
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
                    return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var lecture = snapshot.data!.docs[index];
                        final data =
                            lecture.data() as Map<String, dynamic>? ?? {};
                        String newLectureId = lecture.id;
                        final titleText =
                            (data['lectureTitle'] ??
                                    data['title'] ??
                                    'Untitled')
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

                        return SizedBox(
                          height: 100,
                          width: 200,
                          child: Card(
                            color: Colors.black,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(
                                    8.0,
                                  ), // Optional padding
                                  child: Text(
                                    'Title: $titleText',
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
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.play_circle,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (urlText.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            PageTransition(
                                              type:
                                                  PageTransitionType
                                                      .rightToLeft,
                                              child: OpenLecturePage(
                                                title: titleText,
                                                url: urlText,
                                                description: descText,
                                                lecId: newLectureId,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No lecture URL available',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        // delete lecture
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('lectures')
                                              .doc(newLectureId)
                                              .delete();
                                          // remove from courses' lectures arrays
                                          final courseQuery =
                                              await FirebaseFirestore.instance
                                                  .collection('courses')
                                                  .where(
                                                    'cid',
                                                    isEqualTo: widget.cid,
                                                  )
                                                  .get();
                                          for (var cdoc in courseQuery.docs) {
                                            await cdoc.reference.update({
                                              'lectures':
                                                  FieldValue.arrayRemove([
                                                    newLectureId,
                                                  ]),
                                            });
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Lecture deleted'),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete lecture: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
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
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.picture_as_pdf,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (urlText.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            PageTransition(
                                              type:
                                                  PageTransitionType
                                                      .rightToLeft,
                                              child: OpenLecturePage(
                                                title: titleText,
                                                url: urlText,
                                                description: "Resource PDF",
                                                lecId: rid,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No PDF URL available',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('course_resources')
                                              .doc(rid)
                                              .delete();
                                          final courseQuery =
                                              await FirebaseFirestore.instance
                                                  .collection('courses')
                                                  .where(
                                                    'cid',
                                                    isEqualTo: widget.cid,
                                                  )
                                                  .get();
                                          for (var cdoc in courseQuery.docs) {
                                            await cdoc.reference.update({
                                              'resources':
                                                  FieldValue.arrayRemove([rid]),
                                            });
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Resource deleted'),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
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
                ),
              ),

              SizedBox(height: 20),
              _buildLabel('Assignments'),
              Container(
                color: Colors.white,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('assignment')
                          .where('cid', isEqualTo: widget.cid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: Text('No assignments'));
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty)
                      return const Center(child: Text('No assignments'));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final a = docs[index];
                        final aid = a.id;
                        final title = a['title'] ?? '';
                        final due = a['dueDate'];
                        String dueText = '';
                        try {
                          dueText =
                              (due as Timestamp).toDate().toLocal().toString();
                        } catch (_) {
                          dueText = due?.toString() ?? '';
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text('Due: $dueText'),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.list_alt),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        child: SubmissionsPage(
                                          assignmentId: aid,
                                          assignmentTitle: title,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    // delete assignment doc and remove references
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('assignment')
                                          .doc(aid)
                                          .delete();
                                      final courseQuery =
                                          await FirebaseFirestore.instance
                                              .collection('courses')
                                              .where(
                                                'cid',
                                                isEqualTo: widget.cid,
                                              )
                                              .get();
                                      for (var cdoc in courseQuery.docs) {
                                        await cdoc.reference.update({
                                          'courseAssignment':
                                              FieldValue.arrayRemove([aid]),
                                        });
                                        // remove from enrolled students
                                        final enrolled =
                                            cdoc.get('enrolledStudents') ?? [];
                                        for (var sid in enrolled) {
                                          final studentSnap =
                                              await FirebaseFirestore.instance
                                                  .collection('students')
                                                  .where('sid', isEqualTo: sid)
                                                  .get();
                                          for (var sdoc in studentSnap.docs) {
                                            await sdoc.reference.update({
                                              'incompleteAssignments':
                                                  FieldValue.arrayRemove([aid]),
                                            });
                                          }
                                        }
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Assignment deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to delete assignment: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Add new lecture",
                  style: AppText.mainHeadingTextStyle().copyWith(fontSize: 19),
                ),
              ),
              SizedBox(height: 10),
              _buildLabel('Lecture title'),
              _buildTextField(controller: _titleController),
              _buildLabel("Lecture description"),
              _buildTextField(
                controller: _descriptionController,
                maxLines: 3,
                maxlenght: 100,
              ),
              _buildLabel("Lecture Video"),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? pickedFile = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  _validatePickedVideo(pickedFile);
                },
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.attach_file, size: 20),
                    SizedBox(
                      width: 200,
                      child:
                          _selectedVideo == null
                              ? Text(
                                "Select a video file",
                                style: AppText.hintTextStyle(),
                              )
                              : Text(
                                _selectedVideo.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: CourseSingleVideoGenerationPage(
                              cid: widget.cid,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.video_library, color: AppColors.theme),
                      tooltip: "Generate AI Video",
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedVideo == null) {
                        Fluttertoast.showToast(
                          msg: "Please select a videol.",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                        return;
                      }

                      // Start Loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(child: LoadingIndicator()),
                      );

                      try {
                        // Upload video to Cloudinary
                        String imageUrl = await CloudinaryService.uploadFile(
                          _selectedVideo!,
                          resourceType: 'video',
                        );
                        DocumentReference newLectureRef =
                            FirebaseFirestore.instance
                                .collection('lectures')
                                .doc();
                        newLectureId = newLectureRef.id;
                        LectureModel lecture = LectureModel(
                          cid: widget.cid,
                          lid: newLectureId,
                          lectureTitle: _titleController.text.trim(),
                          lectureDescription:
                              _descriptionController.text.trim(),
                          lectureUrl: imageUrl,
                        );

                        await FirestoreServices().createLecture(lecture);
                        await FirestoreServices().addLecturesToCourse(courseId);

                        Navigator.pop(context);

                        // Show Success Toast
                        Fluttertoast.showToast(
                          msg: "Lecture Created Successfully!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                        _titleController.clear();
                        _descriptionController.clear();
                        _selectedVideo = null;
                      } catch (e) {
                        Navigator.pop(context); // Hide loading
                        Fluttertoast.showToast(
                          msg: "Error creating course: $e",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgColor,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Update Course",
                    style: AppText.buttonTextStyle().copyWith(
                      color: AppColors.theme,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppText.mainSubHeadingTextStyle().copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    int maxlenght = 20,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            maxLength: maxlenght,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: "Enter here",
              hintStyle: AppText.hintTextStyle(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "This field cannot be empty";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
