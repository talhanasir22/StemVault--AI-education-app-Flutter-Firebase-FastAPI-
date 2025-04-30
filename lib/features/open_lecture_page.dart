import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class OpenLecturePage extends StatefulWidget {
  final String title;
  final String url; // Direct video URL
  final String description;
  final String lecId;

  const OpenLecturePage({
    Key? key,
    required this.title,
    required this.url,
    required this.description,
    required this.lecId,
  }) : super(key: key);

  @override
  State<OpenLecturePage> createState() => _OpenLecturePageState();
}

class _OpenLecturePageState extends State<OpenLecturePage> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLandscape = false;

  Future<void> _initializeAndPlay() async {
    setState(() => _isLoading = true);

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller!.initialize();
      _controller!.play();

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading video")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleOrientation() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    setState(() => _isLandscape = !_isLandscape);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildVideoFrame(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final videoHeight = screenHeight * 0.8;

    if (_isLoading) {
      return Container(
        height: videoHeight,
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isPlaying && _controller != null && _controller!.value.isInitialized) {
      return Column(
        children: [
          Container(
            height: videoHeight,
            width: double.infinity,
            child: VideoPlayer(_controller!),
          ),
          VideoProgressIndicator(_controller!, allowScrubbing: true),
        ],
      );
    }

    return GestureDetector(
      onTap: _initializeAndPlay,
      child: Container(
        height: videoHeight,
        width: double.infinity,
        color: Colors.black,
        child: Center(
          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.screen_rotation),
            onPressed: _toggleOrientation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoFrame(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                   "Title: ${widget.title}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Description: ${widget.description}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    widget.lecId,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isPlaying && _controller != null
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller!.value.isPlaying
                ? _controller!.pause()
                : _controller!.play();
          });
        },
        child: Icon(
          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}
