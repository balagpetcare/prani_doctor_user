import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../shared/upload/services/upload_service.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'support_api_paths.dart';
import 'support_dto.dart';
import 'support_repository_contract.dart';

class SupportRepository implements SupportRepositoryContract {
  SupportRepository(this._dio, this._cache, this._outbox, this._uploads);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  final UploadService _uploads;

  Future<ApiResult<SupportTicketPageResult>>? _listInFlight;
  Future<ApiResult<SupportHelpData>>? _helpInFlight;

  SupportTicketPageResult _parseListPage(Map<String, dynamic> data) {
    final tickets = (data['tickets'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SupportTicketSummary.fromJson)
        .toList();
    return SupportTicketPageResult(
      tickets: tickets,
      total: data['total'] as int? ?? tickets.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  Future<void> _writeTicketsCache(SupportTicketPageResult page) async {
    await _cache.write(LocalCacheContract.supportTicketsListKey, {
      'tickets': page.tickets.map((t) => t.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
      'hasMore': page.hasMore,
    }, LocalCacheContract.profileTtl);
  }

  @override
  Future<SupportTicketPageResult?> readCachedTickets() async {
    final cached = await _cache.read(LocalCacheContract.supportTicketsListKey);
    if (cached == null) return null;
    final tickets = (cached['tickets'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => SupportTicketSummary.fromJson(j, fromCache: true))
        .toList();
    return SupportTicketPageResult(
      tickets: tickets,
      total: cached['total'] as int? ?? tickets.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  @override
  Future<SupportHelpData?> readCachedHelp() async {
    final cached = await _cache.read(LocalCacheContract.supportHelpKey);
    if (cached == null) return null;
    return SupportHelpData.fromJson(
      Map<String, dynamic>.from(cached),
      fromCache: true,
    );
  }

  @override
  Future<SupportTicketDetail?> readCachedTicketDetail(String id) async {
    final cached = await _cache.read(
      LocalCacheContract.supportTicketDetailKey(id),
    );
    if (cached == null) return null;
    final raw = cached['ticket'];
    if (raw is! Map<String, dynamic>) return null;
    return SupportTicketDetail.fromJson(raw, fromCache: true);
  }

  Future<void> _enqueue(
    OutboxKind kind,
    Map<String, dynamic> payload,
    String keySuffix,
  ) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: '${kind.apiValue}-$keySuffix-$sequence',
        kind: kind,
        payload: payload,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _optimisticUpsertTicket(SupportTicketDetail ticket) async {
    final cached = await readCachedTickets();
    final summary = SupportTicketSummary(
      id: ticket.id,
      category: ticket.category,
      subject: ticket.subject,
      priority: ticket.priority,
      status: ticket.status,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      closedAt: ticket.closedAt,
      lastMessagePreview: ticket.messages.isNotEmpty
          ? ticket.messages.last.body
          : ticket.description,
      attachmentCount: ticket.attachments.length,
      pendingSync: ticket.pendingSync,
    );
    final existing = cached?.tickets ?? [];
    final updated = [summary, ...existing.where((t) => t.id != ticket.id)];
    await _writeTicketsCache(
      SupportTicketPageResult(
        tickets: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.supportTicketDetailKey(ticket.id),
      {'ticket': ticket.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<ApiResult<SupportTicketPageResult>> listTickets({
    SupportTicketStatus? status,
    SupportTicketCategory? category,
    SupportTicketPriority? priority,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && page == 1 && _listInFlight != null) {
      return _listInFlight!;
    }
    final future = _loadList(
      status: status,
      category: category,
      priority: priority,
      search: search,
      page: page,
      limit: limit,
    );
    if (page == 1) _listInFlight = future;
    try {
      return await future;
    } finally {
      if (page == 1) _listInFlight = null;
    }
  }

  Future<ApiResult<SupportTicketPageResult>> _loadList({
    SupportTicketStatus? status,
    SupportTicketCategory? category,
    SupportTicketPriority? priority,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.apiValue,
        if (category != null) 'category': category.apiValue,
        if (priority != null) 'priority': priority.apiValue,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      final data = await getJson(
        _dio,
        SupportApiPaths.tickets,
        queryParameters: query,
      );
      final pageResult = _parseListPage(data);
      if (page == 1) await _writeTicketsCache(pageResult);
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedTickets();
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportTicketDetail>> getTicket(String id) async {
    try {
      final data = await getJson(_dio, SupportApiPaths.ticket(id));
      final raw = data['ticket'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Ticket not found'),
        );
      }
      final ticket = SupportTicketDetail.fromJson(raw);
      await _cache.write(
        LocalCacheContract.supportTicketDetailKey(id),
        {'ticket': ticket.toJson()},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(ticket);
    } on AppException catch (e) {
      final cached = await _cache.read(
        LocalCacheContract.supportTicketDetailKey(id),
      );
      if (cached != null) {
        return ApiResult.success(
          SupportTicketDetail.fromJson(
            cached['ticket'] as Map<String, dynamic>,
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportTicketDetail>> createTicket(
    SupportTicketInput input,
  ) async {
    final body = input.toCreateJson();
    final tempId = 'local-support-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = SupportTicketDetail(
      id: tempId,
      category: input.category,
      subject: input.subject,
      description: input.description,
      priority: input.priority,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      messages: [
        SupportMessage(
          id: 'local-msg-$tempId',
          authorType: SupportMessageAuthor.customer,
          body: input.description,
          createdAt: DateTime.now(),
          pendingSync: true,
        ),
      ],
      timeline: [],
    );

    try {
      final data = await postJson(_dio, SupportApiPaths.tickets, body);
      final raw = data['ticket'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final ticket = SupportTicketDetail.fromJson(raw);
      await _optimisticUpsertTicket(ticket);
      return ApiResult.success(ticket);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(
          OutboxKind.supportTicketCreate,
          input.toOutboxJson(),
          tempId,
        );
        await _optimisticUpsertTicket(optimistic);
        return ApiResult.success(optimistic);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportTicketDetail>> reply(SupportReplyInput input) async {
    final body = {
      'body': input.body.trim(),
      if (input.attachmentFileIds.isNotEmpty)
        'attachmentFileIds': input.attachmentFileIds,
    };

    try {
      final data = await postJson(
        _dio,
        SupportApiPaths.reply(input.ticketId),
        body,
      );
      final raw = data['ticket'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid reply response'),
        );
      }
      final ticket = SupportTicketDetail.fromJson(raw);
      await _optimisticUpsertTicket(ticket);
      return ApiResult.success(ticket);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(
          OutboxKind.supportTicketReply,
          input.toJson(),
          input.ticketId,
        );
        final cached = await _cache.read(
          LocalCacheContract.supportTicketDetailKey(input.ticketId),
        );
        if (cached != null) {
          final existing = SupportTicketDetail.fromJson(
            cached['ticket'] as Map<String, dynamic>,
            fromCache: true,
          );
          final pendingMessage = SupportMessage(
            id: 'local-reply-${DateTime.now().millisecondsSinceEpoch}',
            authorType: SupportMessageAuthor.customer,
            body: input.body,
            createdAt: DateTime.now(),
            pendingSync: true,
          );
          final updated = SupportTicketDetail(
            id: existing.id,
            category: existing.category,
            subject: existing.subject,
            description: existing.description,
            priority: existing.priority,
            status: existing.status,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            closedAt: existing.closedAt,
            pendingSync: true,
            fromCache: true,
            messages: [...existing.messages, pendingMessage],
            attachments: existing.attachments,
            timeline: [...existing.timeline, pendingMessage],
          );
          await _optimisticUpsertTicket(updated);
          return ApiResult.success(updated);
        }
        return ApiResult.failure(e);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportTicketDetail>> closeTicket(String id) async {
    return _patchStatus(id, SupportTicketStatus.closed);
  }

  @override
  Future<ApiResult<SupportTicketDetail>> reopenTicket(String id) async {
    return _patchStatus(id, SupportTicketStatus.open);
  }

  Future<ApiResult<SupportTicketDetail>> _patchStatus(
    String id,
    SupportTicketStatus status,
  ) async {
    final apiStatus = status == SupportTicketStatus.closed ? 'CLOSED' : 'OPEN';
    try {
      final data = await patchJson(_dio, SupportApiPaths.ticket(id), {
        'status': apiStatus,
      });
      final raw = data['ticket'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid patch response'),
        );
      }
      final ticket = SupportTicketDetail.fromJson(raw);
      await _optimisticUpsertTicket(ticket);
      return ApiResult.success(ticket);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.supportTicketPatch, {
          'id': id,
          'status': apiStatus,
        }, id);
        final cached = await _cache.read(
          LocalCacheContract.supportTicketDetailKey(id),
        );
        if (cached != null) {
          final existing = SupportTicketDetail.fromJson(
            cached['ticket'] as Map<String, dynamic>,
            fromCache: true,
          );
          final updated = SupportTicketDetail(
            id: existing.id,
            category: existing.category,
            subject: existing.subject,
            description: existing.description,
            priority: existing.priority,
            status: status,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            closedAt: status == SupportTicketStatus.closed
                ? DateTime.now()
                : null,
            pendingSync: true,
            fromCache: true,
            messages: existing.messages,
            attachments: existing.attachments,
            timeline: existing.timeline,
          );
          await _optimisticUpsertTicket(updated);
          return ApiResult.success(updated);
        }
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportHelpData>> getHelp({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _helpInFlight != null) return _helpInFlight!;
    final future = _loadHelp();
    _helpInFlight = future;
    try {
      return await future;
    } finally {
      _helpInFlight = null;
    }
  }

  Future<ApiResult<SupportHelpData>> _loadHelp() async {
    try {
      final data = await getJson(_dio, SupportApiPaths.help);
      final help = SupportHelpData.fromJson(data);
      await _cache.write(
        LocalCacheContract.supportHelpKey,
        help.toJson(),
        LocalCacheContract.appConfigTtl,
      );
      return ApiResult.success(help);
    } on AppException catch (e) {
      final cached = await readCachedHelp();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<SupportUploadResult>> uploadAttachment(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final result = await _uploads.uploadSupportAttachment(
      filePath,
      onProgress: onProgress,
    );
    return result.when(
      success: (upload) => ApiResult.success(
        SupportUploadResult.fromJson({
          'fileId': upload.fileId,
          'downloadUrl': upload.url,
          'originalName': upload.originalName ?? 'file',
          'mimeType': upload.mimeType,
          'sizeBytes': upload.sizeBytes,
        }, localPath: filePath),
      ),
      failure: ApiResult.failure,
    );
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
    ref.watch(uploadServiceProvider),
  );
});
