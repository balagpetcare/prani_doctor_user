import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/ai/data/ai_dto.dart';
import 'package:pranidoctor_user/features/ai/data/ai_validation.dart';

void main() {
  group('AiChatMessage', () {
    test('parses assistant message', () {
      final message = AiChatMessage.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'Monitor feed intake.',
        'createdAt': '2026-05-22T08:00:00.000Z',
      });
      expect(message.role, AiMessageRole.assistant);
      expect(message.content, contains('Monitor'));
    });
  });

  group('AiChatResponse', () {
    test('parses chat response', () {
      final response = AiChatResponse.fromJson({
        'sessionId': 's1',
        'messageId': 'm2',
        'content': 'Hello',
        'refused': false,
        'humanRedirect': false,
        'escalationRecommended': false,
        'disclaimer': 'Educational only',
      });
      expect(response.sessionId, 's1');
    });
  });

  group('TriageResultModel', () {
    test('maps triage without diagnosis wording', () {
      final triage = TriageResultModel.fromJson({
        'triageId': 't1',
        'riskBucket': 'HIGH',
        'recommendation': 'Contact a veterinarian as soon as possible.',
        'escalationRequired': true,
        'disclaimer': 'Educational only',
      }, symptomsSummary: 'fever, not eating');
      expect(triage.urgency, AiRiskLevel.high);
      expect(triage.possibleConcern, 'fever, not eating');
    });
  });

  group('AiValidation', () {
    test('rejects empty message', () {
      expect(
        AiValidation.validateMessage(
          '',
          emptyMessage: 'empty',
          tooLong: 'long',
        ),
        'empty',
      );
    });

    test('requires symptoms for triage', () {
      expect(
        AiValidation.validateSymptoms([''], emptyMessage: 'need symptoms'),
        'need symptoms',
      );
    });
  });

  group('AiSendMessageInput', () {
    test('serializes locale', () {
      const input = AiSendMessageInput(message: 'Hello', locale: AiLocale.bn);
      expect(input.toJson()['locale'], 'bn');
    });
  });

  group('AiSettings', () {
    test('round trips json', () {
      const settings = AiSettings(locale: AiLocale.en, showSuggestions: false);
      final restored = AiSettings.fromJson(settings.toJson());
      expect(restored.locale, AiLocale.en);
      expect(restored.showSuggestions, isFalse);
    });
  });

  group('VoiceSttResult', () {
    test('parses normalized transcript', () {
      final stt = VoiceSttResult.fromJson({
        'sessionId': 'vs1',
        'transcriptId': 'tr1',
        'normalizedText': 'গরু অসুস্থ',
        'confidence': 0.9,
      });
      expect(stt.normalizedText, isNotEmpty);
    });
  });
}
