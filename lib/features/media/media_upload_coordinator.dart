import 'dart:async';

import 'package:flutter/foundation.dart';

/// Orchestrates resumable media uploads to your CDN/API (implement with Dio + background isolate).
class MediaUploadCoordinator {
  MediaUploadCoordinator();

  final _queue = <_UploadItem>[];

  Future<void> enqueue(String localPath, {String? contentType}) async {
    _queue.add(_UploadItem(localPath, contentType: contentType));
    debugPrint('MediaUploadCoordinator enqueue (placeholder): $localPath');
    // TODO: drain queue with retry, progress callbacks, and CacheStore bookkeeping
  }

  int get pendingCount => _queue.length;
}

class _UploadItem {
  _UploadItem(this.localPath, {this.contentType});
  final String localPath;
  final String? contentType;
}
