import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FreeMediaUploadService {
  // Free Imgur Client-ID for anonymous uploads
  static const String _imgurClientId = '546c25a59c58ad7';
  static const String _imgurApiUrl = 'https://api.imgur.com/3/image';

  /// Uploads a photo file to free hosting (Imgur API) with Base64 data URI fallback.
  static Future<String> uploadPhoto(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_imgurApiUrl))
        ..headers['Authorization'] = 'Client-ID $_imgurClientId'
        ..files.add(await http.MultipartFile.fromPath('image', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null && json['data']['link'] != null) {
          final String url = json['data']['link'];
          debugPrint('FreeMediaUploadService: Uploaded photo to Imgur -> $url');
          return url;
        }
      }
    } catch (e) {
      debugPrint('FreeMediaUploadService: Imgur upload failed ($e). Using Base64 fallback.');
    }

    // Base64 Fallback: Convert image bytes to Data URI string
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : 'jpeg';
      final dataUrl = 'data:image/$mimeType;base64,$base64String';
      debugPrint('FreeMediaUploadService: Encoded photo to Base64 (length: ${dataUrl.length})');
      return dataUrl;
    } catch (e) {
      debugPrint('FreeMediaUploadService: Base64 encoding error ($e)');
      rethrow;
    }
  }

  /// Uploads a video file to free video hosting (Cloudinary demo unsigned endpoint).
  static Future<String> uploadVideo(File file) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/demo/video/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'unsigned'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['secure_url'] != null) {
          final String url = json['secure_url'];
          debugPrint('FreeMediaUploadService: Uploaded video to Cloudinary -> $url');
          return url;
        }
      }
    } catch (e) {
      debugPrint('FreeMediaUploadService: Cloudinary video upload failed ($e).');
    }

    // Return Imgur API fallback for video/gif
    try {
      return await uploadPhoto(file);
    } catch (e) {
      debugPrint('FreeMediaUploadService: Video upload error ($e)');
      rethrow;
    }
  }
}
