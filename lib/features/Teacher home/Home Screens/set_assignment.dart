import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Add this import
import 'package:stem_vault/Data/Cloudinary/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Shared/course_annoucement_banner.dart';
import 'package:file_picker/file_picker.dart';

class SetAssignment extends StatefulWidget {
  final String cid; // <-- get course id from constructor

  SetAssignment({required this.cid});

  @override
  _SetAssignmentState createState() => _SetAssignmentState();
}

class _SetAssignmentState extends State<SetAssignment> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  File? _selectedFile;

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      Fluttertoast.showToast(
        msg: "Only PDF files are allowed.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  bool isLoading = false; // <-- add this above build method

  Future<void> _uploadAssignment() async {
    if (_titleController.text.isEmpty ||
        _marksController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        _selectedFile == null) {
      Fluttertoast.showToast(
        msg: "Please fill all fields and upload a file.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Upload the PDF file to Cloudinary
      String fileUrl = await CloudinaryService.uploadFile(_selectedFile!, resourceType: 'raw');

      // Create new Assignment document
      DocumentReference assignmentRef = firestore.collection('assignment').doc();
      String aid = assignmentRef.id;

      await assignmentRef.set({
        "aid": aid,
        "title": _titleController.text.trim(),
        "totalMarks": _marksController.text.trim(),
        "dueDate": Timestamp.fromDate(selectedDate!), // Only Date
        "dueTime": "${selectedTime!.hour}:${selectedTime!.minute}", // Only Time
        "assignmentUrl": fileUrl,
        "cid": widget.cid, // Save course ID too (optional but good)
      });

      // Update courseAssignment list inside courses collection
      QuerySnapshot coursesSnapshot = await firestore.collection('courses')
          .where('cid', isEqualTo: widget.cid)
          .get();

      if (coursesSnapshot.docs.isNotEmpty) {
        var courseDoc = coursesSnapshot.docs.first;
        await courseDoc.reference.update({
          "courseAssignment": FieldValue.arrayUnion([aid])
        });

        List<dynamic> enrolledStudents = courseDoc.get('enrolledStudents') ?? [];

        // Update each student's incompleteAssignments
        for (String sid in enrolledStudents) {
          QuerySnapshot studentsSnapshot = await firestore.collection('students')
              .where('sid', isEqualTo: sid)
              .get();

          if (studentsSnapshot.docs.isNotEmpty) {
            var studentDoc = studentsSnapshot.docs.first;
            await studentDoc.reference.update({
              "incompleteAssignments": FieldValue.arrayUnion([aid])
            });
          }
        }
      }

      Fluttertoast.showToast(
        msg: "Assignment uploaded successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);

    } catch (e) {
      print(e.toString());
      Fluttertoast.showToast(
        msg: "Error uploading assignment: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text("Set Assignment", style: AppText.mainHeadingTextStyle()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: CourseAnnouncementBanner(
                bannerText: "Assign subject-relevant tasks to your students effectively.",
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: AppColors.theme,
              elevation: 12,
              margin: EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assignment Title", style: AppText.descriptionTextStyle()),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: "Enter here",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("Total Marks", style: AppText.descriptionTextStyle()),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter here",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text("Select due Date and time", style: AppText.descriptionTextStyle()),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: selectedDate != null
                                      ? DateFormat.yMMMd().format(selectedDate!)
                                      : "Select Date",
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: selectedTime != null
                                      ? selectedTime!.format(context)
                                      : "Select Time",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("Upload Assignment", style: AppText.descriptionTextStyle().copyWith(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _pickPdfFile,
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFile == null ? "Please select a file" : _selectedFile!.path.split('/').last,
                              style: AppText.hintTextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _uploadAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgColor,
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(
                          color: AppColors.theme,
                        )
                            : Text(
                          "Confirm & Upload",
                          style: AppText.buttonTextStyle().copyWith(
                            color: AppColors.theme,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
