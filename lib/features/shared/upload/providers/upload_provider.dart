import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_result.dart';
import '../models/upload_result.dart';

class UploadProgressNotifier extends StateNotifier<Map<String, UploadTask>> {
  UploadProgressNotifier() : super(const {});
  final Map<String, CancelToken> _tokens = {};

  UploadTask? taskFor(String localPath) => state[localPath];

  Future<UploadResult?> upload({
    required String localPath,
    required Future<ApiResult<UploadResult>> Function({
      required String filePath,
      void Function(int sent, int total)? onProgress,
      CancelToken? cancelToken,
    })
    uploadCall,
  }) async {
    final token = CancelToken();
    _tokens[localPath] = token;

    _setTask(
      localPath,
      UploadTask(
        localPath: localPath,
        state: UploadTaskState.uploading,
        progress: 0,
        cancelToken: token,
      ),
    );

    final result = await uploadCall(
      filePath: localPath,
      cancelToken: token,
      onProgress: (sent, total) {
        if (total <= 0) return;
        _setTask(
          localPath,
          state[localPath]!.copyWith(
            progress: sent / total,
            state: UploadTaskState.uploading,
          ),
        );
      },
    );

    _tokens.remove(localPath);

    return result.when(
      success: (upload) {
        _setTask(
          localPath,
          state[localPath]!.copyWith(
            state: UploadTaskState.success,
            progress: 1,
            result: upload,
            errorMessage: null,
          ),
        );
        return upload;
      },
      failure: (error) {
        final cancelled = error.code == 'CANCELLED';
        _setTask(
          localPath,
          state[localPath]!.copyWith(
            state: cancelled
                ? UploadTaskState.cancelled
                : UploadTaskState.error,
            errorMessage: error.message,
          ),
        );
        return null;
      },
    );
  }

  void cancel(String localPath) {
    _tokens.remove(localPath)?.cancel('cancelled');
    final current = state[localPath];
    if (current != null) {
      _setTask(
        localPath,
        current.copyWith(
          state: UploadTaskState.cancelled,
          errorMessage: 'Upload cancelled',
        ),
      );
    }
  }

  void clear(String localPath) {
    _tokens.remove(localPath);
    final next = Map<String, UploadTask>.from(state)..remove(localPath);
    state = next;
  }

  void _setTask(String localPath, UploadTask task) {
    state = {...state, localPath: task};
  }
}

final uploadProgressProvider =
    StateNotifierProvider<UploadProgressNotifier, Map<String, UploadTask>>((
      ref,
    ) {
      return UploadProgressNotifier();
    });

final activeUploadProgressProvider = Provider<double?>((ref) {
  final tasks = ref.watch(uploadProgressProvider);
  UploadTask? active;
  for (final task in tasks.values) {
    if (task.state == UploadTaskState.uploading) {
      active = task;
      break;
    }
  }
  return active?.progress;
});
