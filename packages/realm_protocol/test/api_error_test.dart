import 'package:realm_protocol/realm_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ApiError', () {
    test('round-trips JSON with fieldErrors and requestId', () {
      final error = ApiError(
        code: ApiErrorCode.validationFailed,
        message: '  Invalid input  ',
        fieldErrors: const {' title ': ' Title is required '},
        requestId: ' req-123 ',
      );

      expect(error.message, 'Invalid input');
      expect(error.fieldErrors, const {'title': 'Title is required'});
      expect(error.requestId, 'req-123');

      final decoded = ApiError.fromJson(error.toJson());
      expect(decoded, error);
      expect(decoded.hashCode, error.hashCode);
    });

    test('omits empty fieldErrors and null requestId from JSON', () {
      final error = ApiError(
        code: ApiErrorCode.notFound,
        message: 'Blob not found',
      );

      final json = error.toJson();
      expect(json, {'code': 'notFound', 'message': 'Blob not found'});
      expect(ApiError.fromJson(json), error);
    });

    test('copyWith updates selected fields and preserves immutability', () {
      final original = ApiError(
        code: ApiErrorCode.badRequest,
        message: 'Original',
        fieldErrors: const {'a': 'bad'},
        requestId: 'req-1',
      );

      final updated = original.copyWith(
        code: ApiErrorCode.conflict,
        message: 'Revision conflict',
      );

      expect(updated.code, ApiErrorCode.conflict);
      expect(updated.message, 'Revision conflict');
      expect(updated.fieldErrors, const {'a': 'bad'});
      expect(updated.requestId, 'req-1');
    });

    test('rejects unknown error codes and invalid fields', () {
      expect(() => ApiErrorCode.fromName('madeUpCode'), throwsArgumentError);
      expect(
        () => ApiError.fromJson({'code': 'madeUpCode', 'message': 'Nope'}),
        throwsArgumentError,
      );
      expect(
        () => ApiError(code: ApiErrorCode.badRequest, message: '   '),
        throwsArgumentError,
      );
      expect(
        () => ApiError(
          code: ApiErrorCode.badRequest,
          message: 'Bad',
          fieldErrors: const {'': 'missing key'},
        ),
        throwsArgumentError,
      );
      expect(
        () => ApiError(
          code: ApiErrorCode.badRequest,
          message: 'Bad',
          fieldErrors: const {'key': '   '},
        ),
        throwsArgumentError,
      );
      expect(
        () => ApiError(
          code: ApiErrorCode.badRequest,
          message: 'Bad',
          requestId: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => ApiError.fromJson({
          'code': 'badRequest',
          'message': 'Bad',
          'fieldErrors': {'k': 123},
        }),
        throwsArgumentError,
      );
    });
  });
}
