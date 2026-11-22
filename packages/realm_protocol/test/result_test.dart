import 'package:realm_protocol/realm_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and transforms via map/fold', () {
      const ApiResult<int> result = Ok<int, ApiError>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);

      final mapped = result.map((value) => 'count:$value');
      expect(mapped, const Ok<String, ApiError>('count:42'));

      final mappedError = result.mapError((err) => err.message);
      expect(mappedError, const Ok<int, String>(42));

      final folded = result.fold(onOk: (value) => value * 2, onErr: (_) => -1);
      expect(folded, 84);
    });

    test('Err exposes error and transforms via mapError/fold', () {
      final apiError = ApiError(
        code: ApiErrorCode.unauthorized,
        message: 'Session expired',
      );
      final ApiResult<int> result = Err<int, ApiError>(apiError);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, apiError);

      final mapped = result.map((value) => value.toString());
      expect(mapped, Err<String, ApiError>(apiError));

      final mappedError = result.mapError((err) => err.code.name);
      expect(mappedError, const Err<int, String>('unauthorized'));

      final folded = result.fold(
        onOk: (value) => value,
        onErr: (err) => err.code.index,
      );
      expect(folded, ApiErrorCode.unauthorized.index);
    });

    test('supports structural equality and hashCode', () {
      const firstOk = Ok<int, String>(7);
      const secondOk = Ok<int, String>(7);
      const differentOk = Ok<int, String>(8);
      const err = Err<int, String>('boom');

      expect(firstOk, secondOk);
      expect(firstOk.hashCode, secondOk.hashCode);
      expect(firstOk, isNot(equals(differentOk)));
      expect(firstOk, isNot(equals(err)));
      expect(err, const Err<int, String>('boom'));
    });
  });
}
