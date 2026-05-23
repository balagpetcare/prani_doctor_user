enum SupportTicketCategory {
  account,
  billing,
  technical,
  animalHealth,
  appUsage,
  other,
}

enum SupportTicketPriority { low, medium, high, urgent }

enum SupportTicketStatus { open, inProgress, waitingCustomer, resolved, closed }

enum SupportMessageAuthor { customer, support, system }

extension SupportTicketCategoryApi on SupportTicketCategory {
  String get apiValue {
    switch (this) {
      case SupportTicketCategory.account:
        return 'ACCOUNT';
      case SupportTicketCategory.billing:
        return 'BILLING';
      case SupportTicketCategory.technical:
        return 'TECHNICAL';
      case SupportTicketCategory.animalHealth:
        return 'ANIMAL_HEALTH';
      case SupportTicketCategory.appUsage:
        return 'APP_USAGE';
      case SupportTicketCategory.other:
        return 'OTHER';
    }
  }

  static SupportTicketCategory fromApi(String value) {
    return SupportTicketCategory.values.firstWhere(
      (c) => c.apiValue == value.toUpperCase(),
      orElse: () => SupportTicketCategory.other,
    );
  }
}

extension SupportTicketPriorityApi on SupportTicketPriority {
  String get apiValue => name.toUpperCase();

  static SupportTicketPriority fromApi(String value) {
    return SupportTicketPriority.values.firstWhere(
      (p) => p.apiValue == value.toUpperCase(),
      orElse: () => SupportTicketPriority.medium,
    );
  }
}

extension SupportTicketStatusApi on SupportTicketStatus {
  String get apiValue {
    switch (this) {
      case SupportTicketStatus.open:
        return 'OPEN';
      case SupportTicketStatus.inProgress:
        return 'IN_PROGRESS';
      case SupportTicketStatus.waitingCustomer:
        return 'WAITING_CUSTOMER';
      case SupportTicketStatus.resolved:
        return 'RESOLVED';
      case SupportTicketStatus.closed:
        return 'CLOSED';
    }
  }

  static SupportTicketStatus fromApi(String value) {
    return SupportTicketStatus.values.firstWhere(
      (s) => s.apiValue == value.toUpperCase(),
      orElse: () => SupportTicketStatus.open,
    );
  }
}

extension SupportMessageAuthorApi on SupportMessageAuthor {
  static SupportMessageAuthor fromApi(String value) {
    return SupportMessageAuthor.values.firstWhere(
      (a) => a.name.toUpperCase() == value.toUpperCase(),
      orElse: () => SupportMessageAuthor.customer,
    );
  }
}

class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.downloadUrl,
    this.uploadedFileId,
    this.createdAt,
    this.localPath,
    this.pendingSync = false,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? downloadUrl;
  final String? uploadedFileId;
  final DateTime? createdAt;
  final String? localPath;
  final bool pendingSync;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  factory SupportAttachment.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return SupportAttachment(
      id: json['id'] as String? ?? json['fileId'] as String? ?? '',
      fileName:
          json['fileName'] as String? ??
          json['originalName'] as String? ??
          'file',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String?,
      uploadedFileId:
          json['uploadedFileId'] as String? ?? json['fileId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      localPath: json['localPath'] as String?,
      pendingSync: fromCache && json['pendingSync'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    if (downloadUrl != null) 'downloadUrl': downloadUrl,
    if (uploadedFileId != null) 'uploadedFileId': uploadedFileId,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (localPath != null) 'localPath': localPath,
    if (pendingSync) 'pendingSync': true,
  };
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.authorType,
    required this.body,
    required this.createdAt,
    this.attachments = const [],
    this.pendingSync = false,
  });

  final String id;
  final SupportMessageAuthor authorType;
  final String body;
  final DateTime createdAt;
  final List<SupportAttachment> attachments;
  final bool pendingSync;

  factory SupportMessage.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return SupportMessage(
      id: json['id'] as String? ?? '',
      authorType: SupportMessageAuthorApi.fromApi(
        json['authorType'] as String? ?? 'CUSTOMER',
      ),
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => SupportAttachment.fromJson(a, fromCache: fromCache))
          .toList(),
      pendingSync: fromCache && json['pendingSync'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorType': authorType.name.toUpperCase(),
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    if (pendingSync) 'pendingSync': true,
  };
}

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.category,
    required this.subject,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.lastMessagePreview,
    this.attachmentCount = 0,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final SupportTicketCategory category;
  final String subject;
  final SupportTicketPriority priority;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? lastMessagePreview;
  final int attachmentCount;
  final bool pendingSync;
  final bool fromCache;

  factory SupportTicketSummary.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return SupportTicketSummary(
      id: json['id'] as String? ?? '',
      category: SupportTicketCategoryApi.fromApi(
        json['category'] as String? ?? 'OTHER',
      ),
      subject: json['subject'] as String? ?? '',
      priority: SupportTicketPriorityApi.fromApi(
        json['priority'] as String? ?? 'MEDIUM',
      ),
      status: SupportTicketStatusApi.fromApi(
        json['status'] as String? ?? 'OPEN',
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'] as String)
          : null,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      pendingSync: fromCache && json['pendingSync'] == true,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.apiValue,
    'subject': subject,
    'priority': priority.apiValue,
    'status': status.apiValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
    if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
    'attachmentCount': attachmentCount,
    if (pendingSync) 'pendingSync': true,
  };
}

class SupportTicketDetail extends SupportTicketSummary {
  const SupportTicketDetail({
    required super.id,
    required super.category,
    required super.subject,
    required super.priority,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.closedAt,
    super.lastMessagePreview,
    super.attachmentCount,
    super.pendingSync,
    super.fromCache,
    required this.description,
    this.messages = const [],
    this.attachments = const [],
    this.timeline = const [],
  });

  final String description;
  final List<SupportMessage> messages;
  final List<SupportAttachment> attachments;
  final List<SupportMessage> timeline;

  factory SupportTicketDetail.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final summary = SupportTicketSummary.fromJson(json, fromCache: fromCache);
    return SupportTicketDetail(
      id: summary.id,
      category: summary.category,
      subject: summary.subject,
      priority: summary.priority,
      status: summary.status,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      closedAt: summary.closedAt,
      lastMessagePreview: summary.lastMessagePreview,
      attachmentCount: summary.attachmentCount,
      pendingSync: summary.pendingSync,
      fromCache: fromCache,
      description: json['description'] as String? ?? '',
      messages: (json['messages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((m) => SupportMessage.fromJson(m, fromCache: fromCache))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => SupportAttachment.fromJson(a, fromCache: fromCache))
          .toList(),
      timeline:
          (json['timeline'] as List<dynamic>? ??
                  json['messages'] as List<dynamic>? ??
                  [])
              .whereType<Map<String, dynamic>>()
              .map((m) => SupportMessage.fromJson(m, fromCache: fromCache))
              .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'description': description,
    'messages': messages.map((m) => m.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'timeline': timeline.map((m) => m.toJson()).toList(),
  };
}

class SupportTicketPageResult {
  const SupportTicketPageResult({
    required this.tickets,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<SupportTicketSummary> tickets;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;
}

class SupportTicketInput {
  const SupportTicketInput({
    required this.category,
    required this.subject,
    required this.description,
    this.priority = SupportTicketPriority.medium,
    this.attachmentFileIds = const [],
    this.attachmentLocalPaths = const [],
  });

  final SupportTicketCategory category;
  final String subject;
  final String description;
  final SupportTicketPriority priority;
  final List<String> attachmentFileIds;
  final List<String> attachmentLocalPaths;

  Map<String, dynamic> toCreateJson() => {
    'category': category.apiValue,
    'subject': subject.trim(),
    'description': description.trim(),
    'priority': priority.apiValue,
    if (attachmentFileIds.isNotEmpty) 'attachmentFileIds': attachmentFileIds,
  };

  Map<String, dynamic> toOutboxJson() => {
    ...toCreateJson(),
    if (attachmentLocalPaths.isNotEmpty)
      'attachmentLocalPaths': attachmentLocalPaths,
  };
}

class SupportReplyInput {
  const SupportReplyInput({
    required this.ticketId,
    required this.body,
    this.attachmentFileIds = const [],
    this.attachmentLocalPaths = const [],
  });

  final String ticketId;
  final String body;
  final List<String> attachmentFileIds;
  final List<String> attachmentLocalPaths;

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'body': body.trim(),
    if (attachmentFileIds.isNotEmpty) 'attachmentFileIds': attachmentFileIds,
    if (attachmentLocalPaths.isNotEmpty)
      'attachmentLocalPaths': attachmentLocalPaths,
  };
}

class SupportHelpFaqItem {
  const SupportHelpFaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;

  factory SupportHelpFaqItem.fromJson(Map<String, dynamic> json) {
    return SupportHelpFaqItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class SupportHelpContact {
  const SupportHelpContact({this.phone, this.whatsapp, this.email});

  final String? phone;
  final String? whatsapp;
  final String? email;

  factory SupportHelpContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SupportHelpContact();
    return SupportHelpContact(
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
    );
  }
}

class SupportQuickAction {
  const SupportQuickAction({
    required this.id,
    required this.label,
    required this.action,
    this.value,
  });

  final String id;
  final String label;
  final String action;
  final String? value;

  factory SupportQuickAction.fromJson(Map<String, dynamic> json) {
    return SupportQuickAction(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      action: json['action'] as String? ?? '',
      value: json['value'] as String?,
    );
  }
}

Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _jsonMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_jsonMap).whereType<Map<String, dynamic>>().toList();
}

class SupportHelpData {
  const SupportHelpData({
    this.faq = const [],
    this.contact = const SupportHelpContact(),
    this.quickActions = const [],
    this.fromCache = false,
  });

  final List<SupportHelpFaqItem> faq;
  final SupportHelpContact contact;
  final List<SupportQuickAction> quickActions;
  final bool fromCache;

  factory SupportHelpData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return SupportHelpData(
      faq: _jsonMapList(json['faq']).map(SupportHelpFaqItem.fromJson).toList(),
      contact: SupportHelpContact.fromJson(_jsonMap(json['contact'])),
      quickActions: _jsonMapList(json['quickActions'])
          .map(SupportQuickAction.fromJson)
          .toList(),
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'faq': faq
        .map(
          (f) => {
            'id': f.id,
            'category': f.category,
            'question': f.question,
            'answer': f.answer,
          },
        )
        .toList(),
    'contact': {
      if (contact.phone != null) 'phone': contact.phone,
      if (contact.whatsapp != null) 'whatsapp': contact.whatsapp,
      if (contact.email != null) 'email': contact.email,
    },
    'quickActions': quickActions
        .map(
          (a) => {
            'id': a.id,
            'label': a.label,
            'action': a.action,
            if (a.value != null) 'value': a.value,
          },
        )
        .toList(),
  };
}

class SupportUploadResult {
  const SupportUploadResult({
    required this.fileId,
    required this.downloadUrl,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.localPath,
  });

  final String fileId;
  final String downloadUrl;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? localPath;

  factory SupportUploadResult.fromJson(
    Map<String, dynamic> json, {
    String? localPath,
  }) {
    return SupportUploadResult(
      fileId: json['fileId'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileName: json['originalName'] as String? ?? 'file',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      localPath: localPath,
    );
  }
}

enum SupportAttachmentUploadState { idle, uploading, success, error }

class PendingSupportAttachment {
  const PendingSupportAttachment({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.fileId,
    this.downloadUrl,
    this.progress = 0,
    this.state = SupportAttachmentUploadState.idle,
    this.errorMessage,
  });

  final String localPath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? fileId;
  final String? downloadUrl;
  final double progress;
  final SupportAttachmentUploadState state;
  final String? errorMessage;

  bool get isUploaded => fileId != null && fileId!.isNotEmpty;

  PendingSupportAttachment copyWith({
    String? fileId,
    String? downloadUrl,
    double? progress,
    SupportAttachmentUploadState? state,
    String? errorMessage,
  }) {
    return PendingSupportAttachment(
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      fileId: fileId ?? this.fileId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      progress: progress ?? this.progress,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
