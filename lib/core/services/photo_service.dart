import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads visit photos to Firebase Storage and returns their download URLs.
class PhotoService {
  /// Uploads [bytes] as a JPEG under the user's folder and returns the URL.
  static Future<String> uploadServicePhoto(String uid, Uint8List bytes) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('users/$uid/service_photos/$name');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
