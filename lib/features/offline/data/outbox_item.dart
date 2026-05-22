enum OutboxKind {
  serviceRequest('service_request'),
  offlineLead('offline_lead'),
  profilePatch('profile_patch'),
  animalCreate('animal_create'),
  animalPatch('animal_patch'),
  batchCreate('batch_create'),
  batchPatch('batch_patch'),
  batchMove('batch_move'),
  batchMerge('batch_merge'),
  milkCreate('milk_create'),
  milkPatch('milk_patch'),
  milkDelete('milk_delete'),
  feedCreate('feed_create'),
  feedPatch('feed_patch'),
  feedDelete('feed_delete'),
  financeExpenseCreate('finance_expense_create'),
  financeExpensePatch('finance_expense_patch'),
  financeExpenseDelete('finance_expense_delete'),
  financeIncomeCreate('finance_income_create'),
  financeIncomePatch('finance_income_patch'),
  financeIncomeDelete('finance_income_delete'),
  healthCreate('health_create'),
  healthPatch('health_patch'),
  healthDelete('health_delete'),
  vaccineCreate('vaccine_create'),
  vaccinePatch('vaccine_patch'),
  vaccineDelete('vaccine_delete'),
  treatmentCreate('treatment_create'),
  treatmentPatch('treatment_patch'),
  treatmentDelete('treatment_delete'),
  supportTicketCreate('support_ticket_create'),
  supportTicketReply('support_ticket_reply'),
  supportTicketPatch('support_ticket_patch'),
  aiChatMessage('ai_chat_message'),
  settingsSync('settings_sync');

  const OutboxKind(this.apiValue);
  final String apiValue;

  static OutboxKind fromApi(String value) {
    return OutboxKind.values.firstWhere(
      (k) => k.apiValue == value,
      orElse: () => OutboxKind.serviceRequest,
    );
  }
}

class OutboxItem {
  const OutboxItem({
    required this.idempotencyKey,
    required this.kind,
    required this.payload,
    required this.clientSequence,
    required this.attemptCount,
    this.nextRetryAt,
    this.lastError,
    required this.createdAt,
  });

  final String idempotencyKey;
  final OutboxKind kind;
  final Map<String, dynamic> payload;
  final int clientSequence;
  final int attemptCount;
  final String? nextRetryAt;
  final String? lastError;
  final String createdAt;

  bool get isDead => attemptCount >= 5;

  bool get isReady {
    if (nextRetryAt == null) return true;
    final at = DateTime.tryParse(nextRetryAt!);
    if (at == null) return true;
    return !DateTime.now().isBefore(at);
  }

  OutboxItem copyWith({
    int? attemptCount,
    String? nextRetryAt,
    String? lastError,
  }) {
    return OutboxItem(
      idempotencyKey: idempotencyKey,
      kind: kind,
      payload: payload,
      clientSequence: clientSequence,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'kind': kind.apiValue,
        'payload': payload,
        'clientSequence': clientSequence,
        'attemptCount': attemptCount,
        if (nextRetryAt != null) 'nextRetryAt': nextRetryAt,
        if (lastError != null) 'lastError': lastError,
        'createdAt': createdAt,
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    return OutboxItem(
      idempotencyKey: json['idempotencyKey'] as String,
      kind: OutboxKind.fromApi(json['kind'] as String? ?? ''),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      clientSequence: json['clientSequence'] as int? ?? 0,
      attemptCount: json['attemptCount'] as int? ?? 0,
      nextRetryAt: json['nextRetryAt'] as String?,
      lastError: json['lastError'] as String?,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
