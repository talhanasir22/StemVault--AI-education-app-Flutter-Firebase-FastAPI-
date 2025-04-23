import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';
import '../../Data/Firebase/student_services/firestore_services.dart';
import '../../Data/Firebase/student_services/lecture_model.dart';
import '../../Shared/LoadingIndicator.dart';

class UpdateCoursePage extends StatefulWidget {
  final String cid;
  const UpdateCoursePage({Key? key, required this.cid}) : super(key: key);

  @override
  State<UpdateCoursePage> createState() => _UpdateCoursePageState();
}

class _UpdateCoursePageState extends State<UpdateCoursePage> with SingleTickerProviderStateMixin {
  String? selectedDuration;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String courseId = FirebaseFirestore.instance.collection("courses").doc().id;
  String lectureId = FirebaseFirestore.instance.collection("lectures").doc().id;
  File? _selectedVideo;

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
      if (extension == 'mp4' || extension == 'mov' || extension == 'avi' || extension == 'mkv' || extension == 'flv' || extension == 'wmv' || extension == 'webm' || extension == 'mpeg' || extension == '3gp') {
        setState(() {
          _selectedVideo = file;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Only video files are allowed.",
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              Center(child: CourseAnnouncementBanner(bannerText: "Explore a diverse selection of STEM courses for a comprehensive learning experience.",)),
              _buildLabel('My Lectures'),
              Container(
                color: Colors.white,
                height: 120,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                    itemBuilder: (
                        itemBuilder , index){
                      return SizedBox(
                        height: 100,
                        width: 200,
                        child: Card(
                          color: Colors.black,
                          child: Center(
                            child: Icon(Icons.play_circle,size: 40,color: Colors.white,),
                          ),
                        ),
                      );
                    }),
              ),
              SizedBox(height: 20,),
              Center(child: Text("Add new lecture",style: AppText.mainHeadingTextStyle().copyWith(fontSize: 19))),
              SizedBox(height: 10,),
              _buildLabel('Lecture title'),
              _buildTextField(controller: _titleController),
              _buildLabel("Lecture description"),
              _buildTextField(controller: _descriptionController, maxLines: 3, maxlenght: 100),
              _buildLabel("Lecture Video"),
              SizedBox(height: 10,),
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                  _validatePickedVideo(pickedFile);
                },
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.attach_file,size: 20,),
                    SizedBox(
                        width: 200,
                        child: _selectedVideo == null ? Text("Select a video file",
                          style: AppText.hintTextStyle(),
                        ): Text(_selectedVideo.toString(),maxLines: 1,overflow: TextOverflow.ellipsis,)
                    )
                  ],
                ),
              ),

              SizedBox(height: 10,),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedVideo == null) {
                        Fluttertoast.showToast(
                          msg: "Please select a course thumbnail.",
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
                        builder: (_) => LoadingIndicator(),
                      );

                      try {
                        // Upload image to Firebase Storage
                        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
                        final ref = FirebaseStorage.instance.ref().child('lectureVideos/$fileName');
                        await ref.putFile(_selectedVideo!);
                        String imageUrl = await ref.getDownloadURL();

                        LectureModel lecture = LectureModel(
                          cid: widget.cid,
                          lid: lectureId,
                          lectureTitle: _titleController.text.trim(),
                         lectureDescription: _descriptionController.text.trim(),
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
                  child: Text("Update Course",style: AppText.buttonTextStyle().copyWith(
                      color: AppColors.theme
                  ),),
                ),
              ),
              SizedBox(height: 40,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppText.mainSubHeadingTextStyle().copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({required TextEditingController controller, int maxLines = 1, int maxlenght = 20}) {
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
