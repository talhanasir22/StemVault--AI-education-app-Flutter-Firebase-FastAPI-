import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_config.dart';

class CloudinaryService {
  /// Uploads a file to Cloudinary and returns the secure URL.
  /// resourceType: 'image', 'video', or 'raw' (for pdfs/documents).
  static Future<String> uploadFile(
    File file, {
    String resourceType = 'auto',
  }) async {
    final type = resourceType == 'auto' ? 'auto' : resourceType;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$type/upload',
    );

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Prefer unsigned uploads using an upload preset. If you must use signed uploads,
    // you should generate the signature on a secure server. For convenience (and only
    // if an apiSecret is present in the config), this client will generate a signature
    // locally — this is NOT recommended for production because it exposes your API secret.
    if (CloudinaryConfig.uploadPreset.isNotEmpty) {
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    } else if (CloudinaryConfig.apiKey.isNotEmpty &&
        CloudinaryConfig.apiSecret.isNotEmpty) {
      // Generate a timestamp and signature using the apiSecret (insecure on client)
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final toSign = 'timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      final signature = sha1.convert(utf8.encode(toSign)).toString();
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
    } else if (CloudinaryConfig.apiKey.isNotEmpty) {
      // apiKey provided but no secret/preset — attempt to send api_key (may be rejected)
      request.fields['api_key'] = CloudinaryConfig.apiKey;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      return map['secure_url'] ?? map['url'] ?? '';
    } else {
      // Provide a clearer error message including Cloudinary response body
      throw Exception(
        'Cloudinary upload failed (status ${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Uploads a file from a remote URL to Cloudinary and returns the secure URL.
  static Future<String> uploadUrl(
    String fileUrl, {
    String resourceType = 'video',
  }) async {
    final type = resourceType == 'auto' ? 'auto' : resourceType;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$type/upload',
    );

    var request = http.MultipartRequest('POST', uri);
    request.fields['file'] =
        fileUrl; // For remote URLs, pass the URL string directly as 'file'

    if (CloudinaryConfig.uploadPreset.isNotEmpty) {
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    } else if (CloudinaryConfig.apiKey.isNotEmpty &&
        CloudinaryConfig.apiSecret.isNotEmpty) {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final toSign = 'timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      final signature = sha1.convert(utf8.encode(toSign)).toString();
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
    } else if (CloudinaryConfig.apiKey.isNotEmpty) {
      request.fields['api_key'] = CloudinaryConfig.apiKey;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      return map['secure_url'] ?? map['url'] ?? '';
    } else {
      throw Exception(
        'Cloudinary upload failed (status ${response.statusCode}): ${response.body}',
      );
    }
  }
}
