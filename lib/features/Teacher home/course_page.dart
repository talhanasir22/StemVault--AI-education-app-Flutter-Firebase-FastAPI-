import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';

import '../../Data/Firebase/student_services/course_model.dart';
import '../../Data/Firebase/student_services/firestore_services.dart';
import '../../Shared/LoadingIndicator.dart';
import 'UpdatedCoursePage.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with SingleTickerProviderStateMixin {
  String? selectedCategory;
  String? selectedDuration;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String courseId = FirebaseFirestore.instance.collection("courses").doc().id;

  File? _selectedImage;

  final List<String> _tags = ['Math', 'Science', 'Engineering', 'Technology'];

  Widget _buildTagDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: _tags.map((tag) {
        return DropdownMenuItem<String>(
          value: tag,
          child: Text(tag),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
        });
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value == null ? "Please select a course tag" : null,
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                _validatePickedFile(pickedFile);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera); // For file manager use same gallery API
                _validatePickedFile(pickedFile);
              },
            ),
          ],
        );
      },
    );
  }

  void _validatePickedFile(XFile? pickedFile) {
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final extension = pickedFile.path.split('.').last.toLowerCase();
      if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
        setState(() {
          _selectedImage = file;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Only PNG or JPEG images are allowed.",
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
              Center(child: Text("Add your Course",style: AppText.mainHeadingTextStyle().copyWith(fontSize: 19))),
              SizedBox(height: 10,),

              _buildLabel('Course title'),
              _buildTextField(controller: _titleController),

              _buildLabel("Course description"),
              _buildTextField(controller: _descriptionController, maxLines: 3, maxlenght: 100),
              _buildLabel("Course Tag"),
              _buildTagDropdown(),
              SizedBox(height: 10,),
              _buildLabel("Course thumbnail:"),
              SizedBox(height: 10,),
              GestureDetector(
                onTap: _pickImage,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.camera_alt,size: 30,),
                    SizedBox(
                        width: 200,
                        child: _selectedImage == null ? Text("Select thumbnail",
                          style: AppText.hintTextStyle(),
                        ): Text(_selectedImage.toString(),maxLines: 1,overflow: TextOverflow.ellipsis,)
                    )
                  ],
                ),
              ),

              SizedBox(height: 10,),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedImage == null) {
                        Fluttertoast.showToast(
                          msg: "Please select a course thumbnail.",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                        return;
                      }
                      if (selectedCategory == null) {
                        Fluttertoast.showToast(
                          msg: "Please select a course tag.",
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
                        final ref = FirebaseStorage.instance.ref().child('course_thumbnails/$fileName');
                        await ref.putFile(_selectedImage!);
                        String imageUrl = await ref.getDownloadURL();

                        // Create CourseModel
                        CourseModel course = CourseModel(
                          cid: courseId,
                          courseTitle: _titleController.text.trim(),
                          courseDescription: _descriptionController.text.trim(),
                          tag: selectedCategory!,
                          thumbnailUrl: imageUrl,
                          tid: FirebaseAuth.instance.currentUser!.uid,
                          // add other required fields
                        );

                        // Save Course to Firestore
                        await FirestoreServices().createCourse(course);

                        // Hide Loading
                        Navigator.pop(context);

                        // Show Success Toast
                        Fluttertoast.showToast(
                          msg: "Course Created Successfully!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                        _titleController.clear();
                        _descriptionController.clear();
                        _selectedImage = null;


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
                  child: Text("Create Course",style: AppText.buttonTextStyle().copyWith(
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
