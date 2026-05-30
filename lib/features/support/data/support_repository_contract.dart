import '../../../core/error/api_result.dart';
import 'support_dto.dart';

abstract class SupportRepositoryContract {
  Future<SupportTicketPageResult?> readCachedTickets();

  Future<SupportHelpData?> readCachedHelp();

  Future<SupportTicketDetail?> readCachedTicketDetail(String id);

  Future<ApiResult<SupportTicketPageResult>> listTickets({
    SupportTicketStatus? status,
    SupportTicketCategory? category,
    SupportTicketPriority? priority,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });

  Future<ApiResult<SupportTicketDetail>> getTicket(String id);

  Future<ApiResult<SupportTicketDetail>> createTicket(SupportTicketInput input);

  Future<ApiResult<SupportTicketDetail>> reply(SupportReplyInput input);

  Future<ApiResult<SupportTicketDetail>> closeTicket(String id);

  Future<ApiResult<SupportTicketDetail>> reopenTicket(String id);

  Future<ApiResult<SupportHelpData>> getHelp({bool forceRefresh = false});

  /// Closed-beta structured feedback (creates `[Beta Feedback]` support ticket).
  Future<ApiResult<String>> submitBetaFeedback({
    required String message,
    int? rating,
    String? screen,
    String? locale,
  });

  Future<ApiResult<SupportUploadResult>> uploadAttachment(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  });
}
