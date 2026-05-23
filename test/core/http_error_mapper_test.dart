import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/error/http_error_mapper.dart';

void main() {
  group('HttpErrorMapper', () {
    test('maps 405 to service unavailable message', () {
      final ex = HttpErrorMapper.fromStatus(statusCode: 405);
      expect(ex.code, '405');
      expect(ex.message, contains('Service unavailable'));
    });

    test('maps status codes to user titles', () {
      expect(
        HttpErrorMapper.profileErrorTitle(
          HttpErrorMapper.fromStatus(statusCode: 401),
        ),
        'Session expired',
      );
      expect(
        HttpErrorMapper.profileErrorTitle(
          HttpErrorMapper.fromStatus(statusCode: 500),
        ),
        'Server problem',
      );
    });

    test('maps DioException without exposing type name in user path', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/mobile/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/mobile/me'),
          statusCode: 405,
        ),
        type: DioExceptionType.badResponse,
      );
      final ex = HttpErrorMapper.fromDio(dioError);
      expect(ex.code, '405');
      expect(ex.message, isNot(contains('DioException')));
    });
  });
}
