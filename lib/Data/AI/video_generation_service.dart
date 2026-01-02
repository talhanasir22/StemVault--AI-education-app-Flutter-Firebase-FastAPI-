import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoGenerationService {
  static const String _baseUrl =
      'https://vyingly-micrologic-darron.ngrok-free.dev';

  /// Starts the video generation process for a given topic.
  /// Returns the job ID.
  static Future<String> generateVideo(String topic) async {
    final uri = Uri.parse('$_baseUrl/api/generate?topic=$topic');
    print(
      '[VideoGenerationService] Requesting video generation for topic: $topic',
    );
    print('[VideoGenerationService] URI: $uri');

    try {
      final response = await http.post(uri);
      print('[VideoGenerationService] Response Status: ${response.statusCode}');
      print('[VideoGenerationService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['job_id'] != null) {
          print('[VideoGenerationService] Job ID received: ${data['job_id']}');
          return data['job_id'];
        } else {
          print('[VideoGenerationService] Error: Job ID missing in response');
          throw Exception('Job ID not found in response: ${response.body}');
        }
      } else {
        print('[VideoGenerationService] Error: API call failed');
        throw Exception(
          'Failed to start video generation: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[VideoGenerationService] Exception: $e');
      throw Exception('Error generating video: $e');
    }
  }

  /// Constructs the download URL for a given job ID.
  /// Note: The user's example shows the download URL format as /download/{job_id}
  static String getDownloadUrl(String jobId) {
    return '$_baseUrl/download/$jobId';
  }
}
