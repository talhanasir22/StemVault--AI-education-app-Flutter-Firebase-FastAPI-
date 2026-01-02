import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';
import 'package:stem_vault/Data/AI/video_generation_service.dart';
import 'package:stem_vault/Data/Cloudinary/cloudinary_service.dart';
import 'package:stem_vault/Data/Firebase/student_services/firestore_services.dart';
import 'package:stem_vault/Data/Firebase/student_services/lecture_model.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CourseSingleVideoGenerationPage extends StatefulWidget {
  final String cid;
  const CourseSingleVideoGenerationPage({super.key, required this.cid});

  @override
  State<CourseSingleVideoGenerationPage> createState() =>
      _CourseSingleVideoGenerationPageState();
}

class _CourseSingleVideoGenerationPageState
    extends State<CourseSingleVideoGenerationPage> {
  final TextEditingController _topicController = TextEditingController();
  bool _isLoading = false;
  String? _generatedVideoUrl;
  VideoPlayerController? _videoController;
  String _statusMessage = '';

  @override
  void dispose() {
    _topicController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<bool> _checkVideoAvailability(String url) async {
    try {
      print('[CourseSingleVideoGenerationPage] Checking availability of: $url');
      final response = await http.get(Uri.parse(url));
      print(
        '[CourseSingleVideoGenerationPage] Check response status: ${response.statusCode}',
      );
      print(
        '[CourseSingleVideoGenerationPage] Content-Type: ${response.headers['content-type']}',
      );

      if (response.statusCode == 200) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('video') ||
            contentType.contains('octet-stream')) {
          print('[CourseSingleVideoGenerationPage] Video appears ready.');
          return true;
        } else {
          print(
            '[CourseSingleVideoGenerationPage] Response is 200 but not video. Body preview: ${response.body.substring(0, 100.clamp(0, response.body.length))}',
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      print('[CourseSingleVideoGenerationPage] Check failed: $e');
      return false;
    }
  }

  Future<void> _generateVideo() async {
    if (_topicController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a topic");
      return;
    }

    print(
      '[CourseSingleVideoGenerationPage] Starting generation for topic: ${_topicController.text.trim()}',
    );

    setState(() {
      _isLoading = true;
      _statusMessage = 'Initiating video generation...';
      _generatedVideoUrl = null;
      _videoController?.dispose();
      _videoController = null;
    });

    try {
      // 1. Call API to start generation
      print(
        '[CourseSingleVideoGenerationPage] Calling VideoGenerationService.generateVideo...',
      );
      final jobId = await VideoGenerationService.generateVideo(
        _topicController.text.trim(),
      );
      print('[CourseSingleVideoGenerationPage] Job ID: $jobId');

      setState(() {
        _statusMessage = 'Video generation in progress... Please wait.';
      });

      // 2. Construct Download URL
      final downloadUrl = VideoGenerationService.getDownloadUrl(jobId);
      print('[CourseSingleVideoGenerationPage] Download URL: $downloadUrl');

      // 3. Poll for video availability
      bool isReady = false;
      int attempts = 0;
      const int maxAttempts = 30; // 30 * 3s = 90 seconds timeout

      while (!isReady && attempts < maxAttempts) {
        attempts++;
        print(
          '[CourseSingleVideoGenerationPage] Polling attempt $attempts/$maxAttempts...',
        );
        setState(() {
          _statusMessage = 'Generating video... ($attempts)';
        });

        isReady = await _checkVideoAvailability(downloadUrl);

        if (!isReady) {
          await Future.delayed(Duration(seconds: 3));
        }
      }

      if (!isReady) {
        throw Exception('Video generation timed out. Please try again later.');
      }

      // 3.5 Download video to temp file
      setState(() {
        _statusMessage = 'Downloading video to device...';
      });
      print(
        '[CourseSingleVideoGenerationPage] Downloading video from $downloadUrl...',
      );

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      // Check if it's actually a video (magic bytes or content type)
      // Simple check: if it starts with <html>, it's an error page
      if (response.body.trim().toLowerCase().startsWith('<!doctype html') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        print(
          '[CourseSingleVideoGenerationPage] Downloaded content is HTML, not video.',
        );
        print(
          'Preview: ${response.body.substring(0, 200.clamp(0, response.body.length))}',
        );
        throw Exception(
          'Downloaded content is HTML (likely an error page), not a video.',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/generated_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(response.bodyBytes);
      print('[CourseSingleVideoGenerationPage] Video saved to ${file.path}');

      setState(() {
        _statusMessage = 'Uploading to secure storage...';
      });

      print('[CourseSingleVideoGenerationPage] Uploading to Cloudinary...');
      // Use uploadFile instead of uploadUrl
      final secureUrl = await CloudinaryService.uploadFile(
        file,
        resourceType: 'video',
      );
      print(
        '[CourseSingleVideoGenerationPage] Cloudinary Secure URL: $secureUrl',
      );

      // 4. Save to Firestore
      setState(() {
        _statusMessage = 'Saving lecture...';
      });

      print('[CourseSingleVideoGenerationPage] Saving to Firestore...');
      DocumentReference newLectureRef =
          FirebaseFirestore.instance.collection('lectures').doc();
      String newLectureId = newLectureRef.id;

      LectureModel lecture = LectureModel(
        cid: widget.cid,
        lid: newLectureId,
        lectureTitle: "AI Video: ${_topicController.text.trim()}",
        lectureDescription:
            "AI generated video on ${_topicController.text.trim()}",
        lectureUrl: secureUrl,
      );

      await FirestoreServices().createLecture(lecture);
      await FirestoreServices().addLecturesToCourse(
        widget.cid,
      ); // Use widget.cid as courseId
      print(
        '[CourseSingleVideoGenerationPage] Saved to Firestore successfully.',
      );

      // 5. Initialize Video Player
      print('[CourseSingleVideoGenerationPage] Initializing video player...');
      _videoController = VideoPlayerController.networkUrl(Uri.parse(secureUrl))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });

      setState(() {
        _generatedVideoUrl = secureUrl;
        _isLoading = false;
        _statusMessage = '';
      });

      Fluttertoast.showToast(msg: "Video generated and saved successfully!");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      print('[CourseSingleVideoGenerationPage] Error: $e');
      Fluttertoast.showToast(msg: "Error: $e");
      print("Video Generation Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Video Generator",
          style: AppText.mainHeadingTextStyle(),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Generate Educational Video",
              style: AppText.mainSubHeadingTextStyle().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: "Enter topic (e.g., Stack Data Structure)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.theme,
                          ),
                        )
                        : Text(
                          "Generate Video",
                          style: AppText.buttonTextStyle().copyWith(
                            color: AppColors.theme,
                          ),
                        ),
              ),
            ),
            if (_isLoading) ...[
              SizedBox(height: 20),
              Center(
                child: Text(_statusMessage, style: AppText.hintTextStyle()),
              ),
            ],
            SizedBox(height: 30),
            if (_generatedVideoUrl != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Generated Video Preview:",
                      style: AppText.mainSubHeadingTextStyle(),
                    ),
                    SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_videoController!),
                          VideoProgressIndicator(
                            _videoController!,
                            allowScrubbing: true,
                          ),
                          Center(
                            child: IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 50,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
