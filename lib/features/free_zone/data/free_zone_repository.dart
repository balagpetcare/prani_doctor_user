import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';

final freeZoneRepositoryProvider = Provider<FreeZoneRepository>((ref) {
  return FreeZoneRepository(ref.watch(dioProvider));
});

class FreeQuota {
  const FreeQuota({required this.canAsk, this.message, this.nextAvailableAt});
  final bool canAsk;
  final String? message;
  final DateTime? nextAvailableAt;

  factory FreeQuota.fromJson(Map<String, dynamic> j) => FreeQuota(
        canAsk: j['canAsk'] == true,
        message: j['message'] as String?,
        nextAvailableAt: DateTime.tryParse('${j['nextAvailableAt'] ?? ''}')?.toLocal(),
      );
}

class PublicSlot {
  const PublicSlot({
    required this.id,
    this.seatsLeft = 0,
    this.bookedByMe = false,
    required this.startsAt,
    required this.endsAt,
    required this.mode,
    required this.doctorName,
    required this.verified,
    this.degree,
    this.ratingAvg,
    this.ratingCount = 0,
  });
  final String id;
  final int seatsLeft;
  final bool bookedByMe;
  final DateTime startsAt;
  final DateTime endsAt;
  final String mode;
  final String doctorName;
  final bool verified;
  final String? degree;
  final double? ratingAvg;
  final int ratingCount;

  factory PublicSlot.fromJson(Map<String, dynamic> j) {
    final d = j['doctor'] is Map<String, dynamic> ? j['doctor'] as Map<String, dynamic> : <String, dynamic>{};
    return PublicSlot(
      id: '${j['id']}',
      seatsLeft: (j['seatsLeft'] as num?)?.toInt() ?? 0,
      bookedByMe: j['bookedByMe'] == true,
      startsAt: DateTime.parse('${j['startsAt']}').toLocal(),
      endsAt: DateTime.parse('${j['endsAt']}').toLocal(),
      mode: '${j['mode'] ?? 'TEXT'}',
      doctorName: '${d['name'] ?? 'ডাক্তার'}',
      verified: d['verified'] == true,
      degree: d['degree'] as String?,
      ratingAvg: (d['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MyQuestion {
  const MyQuestion({
    required this.id,
    required this.status,
    required this.symptoms,
    required this.animalName,
    required this.submittedAt,
    this.doctorName,
    this.myRating,
  });
  final String id;
  final String status;
  final String symptoms;
  final String animalName;
  final DateTime submittedAt;
  final String? doctorName;
  final int? myRating;

  bool get canRate => status == 'COMPLETED' && myRating == null;

  String get statusBn => switch (status) {
        'PENDING' => 'ডাক্তারের অপেক্ষায়',
        'ASSIGNED' => 'ডাক্তার পেয়েছেন',
        'ACCEPTED' => 'গৃহীত',
        'IN_PROGRESS' => 'চলমান',
        'COMPLETED' => 'সম্পন্ন',
        'CANCELLED' => 'বাতিল',
        'REJECTED' => 'প্রত্যাখ্যাত',
        _ => status,
      };

  factory MyQuestion.fromJson(Map<String, dynamic> j) => MyQuestion(
        id: '${j['id']}',
        status: '${j['status']}',
        symptoms: '${j['symptoms'] ?? ''}',
        animalName: '${j['animalName'] ?? ''}',
        submittedAt: DateTime.parse('${j['submittedAt']}').toLocal(),
        doctorName: j['doctorName'] as String?,
        myRating: (j['myRating'] as num?)?.toInt(),
      );
}

/// One question in the public Q&A feed (asker identity is never exposed).
class FeedItem {
  const FeedItem({
    required this.id,
    required this.status,
    required this.symptoms,
    required this.species,
    required this.submittedAt,
    required this.isMine,
    required this.commentCount,
    this.isEmergency = false,
  });
  final String id;
  final String status;
  final String symptoms;
  final String species;
  final DateTime submittedAt;
  final bool isMine;
  final int commentCount;
  final bool isEmergency;

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        id: '${j['id']}',
        status: '${j['status']}',
        symptoms: '${j['symptoms'] ?? ''}',
        species: '${j['species'] ?? ''}',
        submittedAt: DateTime.parse('${j['submittedAt']}').toLocal(),
        isMine: j['isMine'] == true,
        commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
        isEmergency: j['isEmergency'] == true,
      );
}

/// A comment on a free question. The server decides what the viewer may do (canHide / canUnhide / canReport).
class FreeComment {
  const FreeComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.verified,
    required this.isMine,
    required this.isFromAsker,
    required this.hidden,
    required this.createdAt,
    required this.canHide,
    required this.canUnhide,
    required this.canReport,
  });
  final String id;
  final String body;
  final String authorName;
  final String authorRole;
  final bool verified;
  final bool isMine;
  final bool isFromAsker;
  final bool hidden;
  final DateTime createdAt;
  final bool canHide;
  final bool canUnhide;
  final bool canReport;

  factory FreeComment.fromJson(Map<String, dynamic> j) => FreeComment(
        id: '${j['id']}',
        body: '${j['body'] ?? ''}',
        authorName: '${j['authorName'] ?? 'গ্রাহক'}',
        authorRole: '${j['authorRole'] ?? 'CUSTOMER'}',
        verified: j['verified'] == true,
        isMine: j['isMine'] == true,
        isFromAsker: j['isFromAsker'] == true,
        hidden: j['hidden'] == true,
        createdAt: DateTime.parse('${j['createdAt']}').toLocal(),
        canHide: j['canHide'] == true,
        canUnhide: j['canUnhide'] == true,
        canReport: j['canReport'] == true,
      );
}

class CommentThread {
  const CommentThread({required this.isQuestionOwner, required this.items});
  final bool isQuestionOwner;
  final List<FreeComment> items;
}

class FreeZoneRepository {
  FreeZoneRepository(this._dio);
  final Dio _dio;

  Future<FreeQuota> quota() async {
    try {
      final r = await _dio.get<dynamic>('/api/mobile/free-zone/quota');
      return FreeQuota.fromJson(ApiEnvelope.unwrapData(r));
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  /// Throws an AppException whose message is the server's Bangla text (e.g. quota reached).
  Future<String> submit({
    required String animalId,
    required String symptoms,
    String? description,
    required bool isEmergency,
  }) async {
    final d = await postJson(_dio, '/api/mobile/free-zone/questions', {
      'animalId': animalId,
      'symptoms': symptoms,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      'isEmergency': isEmergency,
    });
    return '${d['id']}';
  }

  Future<List<PublicSlot>> slots() async {
    try {
      final r = await _dio.get<dynamic>('/api/mobile/free-zone/slots');
      final raw = ApiEnvelope.unwrapData(r)['items'];
      return raw is List ? raw.whereType<Map<String, dynamic>>().map(PublicSlot.fromJson).toList() : <PublicSlot>[];
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  Future<void> bookSlot(String slotId) async {
    await postJson(_dio, '/api/mobile/free-zone/slots/$slotId/book', <String, dynamic>{});
  }

  Future<void> cancelBooking(String slotId) async {
    try {
      final r = await _dio.delete<dynamic>('/api/mobile/free-zone/slots/$slotId/book');
      ApiEnvelope.unwrapData(r);
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  Future<List<MyQuestion>> myQuestions() async {
    try {
      final r = await _dio.get<dynamic>('/api/mobile/free-zone/questions');
      final raw = ApiEnvelope.unwrapData(r)['items'];
      return raw is List ? raw.whereType<Map<String, dynamic>>().map(MyQuestion.fromJson).toList() : <MyQuestion>[];
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  Future<void> rate(String id, int rating, {String? comment}) async {
    await postJson(_dio, '/api/mobile/free-zone/questions/$id/rate', {
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }

  Future<List<FeedItem>> feed() async {
    try {
      final r = await _dio.get<dynamic>('/api/mobile/free-zone/feed');
      final raw = ApiEnvelope.unwrapData(r)['items'];
      return raw is List ? raw.whereType<Map<String, dynamic>>().map(FeedItem.fromJson).toList() : <FeedItem>[];
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  Future<CommentThread> comments(String questionId) async {
    try {
      final r = await _dio.get<dynamic>('/api/mobile/free-zone/questions/$questionId/comments');
      final d = ApiEnvelope.unwrapData(r);
      final raw = d['items'];
      return CommentThread(
        isQuestionOwner: d['isQuestionOwner'] == true,
        items: raw is List ? raw.whereType<Map<String, dynamic>>().map(FreeComment.fromJson).toList() : <FreeComment>[],
      );
    } on DioException catch (e) {
      throw ApiEnvelope.fromDioException(e);
    }
  }

  /// Throws an AppException with the server's Bangla text (e.g. contact info not allowed).
  Future<void> postComment(String questionId, String body) async {
    await postJson(_dio, '/api/mobile/free-zone/questions/$questionId/comments', {'body': body.trim()});
  }

  /// Asker only: hide or unhide a comment on their own question.
  Future<void> setCommentHidden(String commentId, bool hidden) async {
    await patchJson(_dio, '/api/mobile/free-zone/comments/$commentId', {'hidden': hidden});
  }

  Future<void> reportComment(String commentId, {String? reason}) async {
    await postJson(_dio, '/api/mobile/free-zone/comments/$commentId/report', {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }
}
