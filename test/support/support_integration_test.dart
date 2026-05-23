import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/support/data/support_dto.dart';
import 'package:pranidoctor_user/features/support/data/support_validation.dart';
import 'package:pranidoctor_user/features/support/presentation/support_providers.dart';

void main() {
  group('SupportTicketSummary', () {
    test('parses list item json', () {
      final ticket = SupportTicketSummary.fromJson({
        'id': 't1',
        'category': 'TECHNICAL',
        'subject': 'App crash',
        'priority': 'HIGH',
        'status': 'OPEN',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
        'lastMessagePreview': 'Details here',
        'attachmentCount': 2,
      });
      expect(ticket.category, SupportTicketCategory.technical);
      expect(ticket.status, SupportTicketStatus.open);
      expect(ticket.attachmentCount, 2);
    });
  });

  group('SupportTicketDetail', () {
    test('parses messages and timeline', () {
      final ticket = SupportTicketDetail.fromJson({
        'id': 't1',
        'category': 'OTHER',
        'subject': 'Help',
        'description': 'Need help',
        'priority': 'MEDIUM',
        'status': 'OPEN',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
        'messages': [
          {
            'id': 'm1',
            'authorType': 'CUSTOMER',
            'body': 'Need help',
            'createdAt': '2026-05-22T08:00:00.000Z',
            'attachments': [],
          },
        ],
      });
      expect(ticket.messages.single.body, 'Need help');
      expect(ticket.timeline.single.authorType, SupportMessageAuthor.customer);
    });
  });

  group('SupportTicketInput', () {
    test('create json includes attachment ids', () {
      const input = SupportTicketInput(
        category: SupportTicketCategory.billing,
        subject: 'Invoice issue',
        description: 'I was charged twice for the same service.',
        priority: SupportTicketPriority.high,
        attachmentFileIds: ['f1'],
      );
      final json = input.toCreateJson();
      expect(json['category'], 'BILLING');
      expect(json['attachmentFileIds'], ['f1']);
    });
  });

  group('SupportValidation', () {
    test('rejects oversized files', () {
      expect(
        SupportValidation.validateFile(
          mimeType: 'application/pdf',
          sizeBytes: SupportValidation.maxAttachmentBytes + 1,
          unsupportedType: 'bad type',
          fileTooLarge: 'too big',
        ),
        'too big',
      );
    });

    test('rejects unsupported mime', () {
      expect(
        SupportValidation.validateFile(
          mimeType: 'application/zip',
          sizeBytes: 1000,
          unsupportedType: 'bad type',
          fileTooLarge: 'too big',
        ),
        'bad type',
      );
    });

    test('validates ticket fields', () {
      expect(
        SupportValidation.validateTicket(
          category: SupportTicketCategory.other,
          subject: 'ab',
          description: 'short',
          subjectRequired: 'req',
          descriptionRequired: 'req',
          subjectTooShort: 'short subject',
          descriptionTooShort: 'short desc',
        ),
        isNotNull,
      );
    });
  });

  group('SupportHelpData', () {
    test('parses faq and contact', () {
      final help = SupportHelpData.fromJson({
        'faq': [
          {'id': 'f1', 'category': 'ACCOUNT', 'question': 'Q?', 'answer': 'A.'},
        ],
        'contact': {'phone': '+880123', 'whatsapp': '+880123'},
        'quickActions': [
          {'id': 'a1', 'label': 'Create', 'action': 'create_ticket'},
        ],
      });
      expect(help.faq.single.question, 'Q?');
      expect(help.contact.phone, '+880123');
      expect(help.quickActions.single.action, 'create_ticket');
    });
  });

  group('SupportSummary', () {
    test('counts ticket statuses', () {
      final summary = SupportSummary.fromTickets([
        SupportTicketSummary(
          id: '1',
          category: SupportTicketCategory.other,
          subject: 'A',
          priority: SupportTicketPriority.medium,
          status: SupportTicketStatus.open,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SupportTicketSummary(
          id: '2',
          category: SupportTicketCategory.other,
          subject: 'B',
          priority: SupportTicketPriority.medium,
          status: SupportTicketStatus.closed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      expect(summary.open, 1);
      expect(summary.closed, 1);
    });
  });

  group('SupportCreateDraft', () {
    test('round trips json', () {
      const draft = SupportCreateDraft(
        subject: 'Help',
        description: 'Need assistance with billing',
      );
      final restored = SupportCreateDraft.fromJson(draft.toJson());
      expect(restored.subject, 'Help');
    });
  });

  group('PendingSupportAttachment', () {
    test('copyWith tracks upload state', () {
      const pending = PendingSupportAttachment(
        localPath: '/tmp/a.pdf',
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 100,
      );
      final uploaded = pending.copyWith(
        fileId: 'f1',
        state: SupportAttachmentUploadState.success,
        progress: 1,
      );
      expect(uploaded.isUploaded, isTrue);
    });
  });
}
