import 'dart:io';

import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Safe multipart/form-data builders.
///
/// Centralizes the "build a [MultipartFile] from a path" step with an explicit
/// existence check so a missing/temp file fails as a typed [AppException]
/// instead of an opaque platform error.
abstract final class Multipart {
  Multipart._();

  /// Builds a [MultipartFile] from [path], verifying the file exists first.
  static Future<MultipartFile> fileFromPath(
    String path, {
    String? filename,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const AppException(
        message: 'File not found',
        code: 'FILE_NOT_FOUND',
      );
    }
    return MultipartFile.fromFile(
      path,
      filename: filename ?? file.uri.pathSegments.last,
    );
  }

  /// Builds [FormData] from [fields], optionally attaching a single file under
  /// [fileField]. Throws a typed [AppException] if [filePath] does not exist.
  static Future<FormData> formData(
    Map<String, dynamic> fields, {
    String fileField = 'file',
    String? filePath,
    String? filename,
  }) async {
    final map = <String, dynamic>{...fields};
    if (filePath != null) {
      map[fileField] = await fileFromPath(filePath, filename: filename);
    }
    return FormData.fromMap(map);
  }
}
