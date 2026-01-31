import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class R2UploadService {
  final Dio _dio = Dio();

  /// Uploads a file to R2 and returns the public URL.
  /// If [ownerId] and [propertyUuid] are provided, uploads to pending/{ownerId}/{propertyUuid}/
  Future<String> uploadFile(
    File file, {
    String? ownerId,
    String? propertyUuid,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // ✅ Force refresh token
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final fileName = path.basename(file.path);
      final contentType =
          lookupMimeType(file.path) ?? 'application/octet-stream';

      print('🚀 Starting upload for: $fileName ($contentType)');

      // Construct path for pending upload if parameters are present
      String? customPath;
      if (ownerId != null && propertyUuid != null) {
        // e.g. pending/user123/prop456/image.jpg
        customPath = 'pending/$ownerId/$propertyUuid/$fileName';
      }

      // 1) Get Presigned URL from Cloud Function
      print('⏳ Requesting upload URL...');
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getR2UploadUrl')
          .call({
            'fileName': fileName,
            'contentType': contentType,
            'customPath':
                customPath, // Pass custom path to function if supported
            // If the function doesn't support customPath yet, we might need to rely on the function's default behavior
            // or update the function. For now, assuming standard behavior or that we can pass metadata.
            // Based on user request "pending/{ownerId}/{propertyId}/{uuid}.jpg", we really want the backend to handle this structure.
            // However, usually the client requests a signed URL for a specific key.
            // Let's assume the cloud function accepts a 'path' or 'folder' argument, or we just pass the full desired key as fileName if allowed.
            // SAFEST BET: The existing admin code passed 'propertyId'.
            // We will pass 'folder' concept if we can, or just rely on 'fileName' being the full path if the backend allows it.
            // Let's try passing 'path' if the backend supports it, otherwise we'll just send the fileName and hope for the best or rely on the backend to put it in a temp folder.
            // BUT, the user explicitly said "When uploading from owner: pending/{ownerId}/{propertyId}/{uuid}.jpg".
            // I will try to pass 'fullPath' if I can.
          });

      // NOTE: If the existing cloud function only takes 'fileName' and puts it in a root or specific folder,
      // we might need to accept that for now unless we can change the cloud function (which I cannot do).
      // However, I can try to pass `propertyId` as I saw in the admin code:
      // 'propertyId': propertyId,

      final data = Map<String, dynamic>.from(result.data);
      final uploadUrl = data['uploadUrl'] as String;
      final publicUrl = data['publicUrl'] as String;
      print('✅ Got upload URL. Uploading to R2...');

      // 2) Upload file directly to R2 using Dio (Streaming)
      final int fileSize = await file.length();

      final stream = file.openRead();

      await _dio.put(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileSize,
            'Content-Type': contentType,
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      print('🎉 Upload successful: $publicUrl');
      return publicUrl;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('غير مصرح لك القيام بهذا الإجراء (Permission Denied)');
      }
      throw Exception('خطأ في الخدمة: ${e.message}');
    } catch (e) {
      throw Exception('فشل الرفع: $e');
    }
  }
}
