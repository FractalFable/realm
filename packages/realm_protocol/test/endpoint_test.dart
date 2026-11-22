import 'package:meta/meta.dart';
import 'package:realm_protocol/realm_protocol.dart';
import 'package:test/test.dart';

@immutable
class _SamplePayload {
  const _SamplePayload(this.name);

  factory _SamplePayload.fromJson(Map<String, Object?> json) =>
      _SamplePayload(json['name']! as String);

  final String name;

  Map<String, Object?> toJson() => {'name': name};

  @override
  bool operator ==(Object other) =>
      other is _SamplePayload && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

void main() {
  group('HttpMethod', () {
    test('maps wire names and rejects unknown values', () {
      expect(HttpMethod.get.wireName, 'GET');
      expect(HttpMethod.post.wireName, 'POST');
      expect(HttpMethod.put.wireName, 'PUT');
      expect(HttpMethod.patch.wireName, 'PATCH');
      expect(HttpMethod.delete.wireName, 'DELETE');

      expect(HttpMethod.fromName('patch'), HttpMethod.patch);
      expect(HttpMethod.fromWireName('DELETE'), HttpMethod.delete);
      expect(() => HttpMethod.fromName('trace'), throwsArgumentError);
      expect(() => HttpMethod.fromWireName('TRACE'), throwsArgumentError);
    });
  });

  group('Endpoint', () {
    const getBlob = Endpoint<EmptyPayload, _SamplePayload>.get(
      '/api/v1/vaults/:vaultId/blobs/:blobId',
      decodeRequest: EmptyPayload.fromJson,
      encodeRequest: _encodeEmpty,
      decodeResponse: _SamplePayload.fromJson,
      encodeResponse: _encodeSample,
    );

    const publicHealth = Endpoint<EmptyPayload, EmptyPayload>.get(
      '/health',
      decodeRequest: EmptyPayload.fromJson,
      encodeRequest: _encodeEmpty,
      decodeResponse: EmptyPayload.fromJson,
      encodeResponse: _encodeEmpty,
      requiresAuth: false,
    );

    test('supports const construction across all HTTP methods', () {
      const post = Endpoint<EmptyPayload, EmptyPayload>.post(
        '/api/v1/items',
        decodeRequest: EmptyPayload.fromJson,
        encodeRequest: _encodeEmpty,
        decodeResponse: EmptyPayload.fromJson,
        encodeResponse: _encodeEmpty,
      );
      const put = Endpoint<EmptyPayload, EmptyPayload>.put(
        '/api/v1/items/:id',
        decodeRequest: EmptyPayload.fromJson,
        encodeRequest: _encodeEmpty,
        decodeResponse: EmptyPayload.fromJson,
        encodeResponse: _encodeEmpty,
      );
      const patch = Endpoint<EmptyPayload, EmptyPayload>.patch(
        '/api/v1/items/:id',
        decodeRequest: EmptyPayload.fromJson,
        encodeRequest: _encodeEmpty,
        decodeResponse: EmptyPayload.fromJson,
        encodeResponse: _encodeEmpty,
      );
      const del = Endpoint<EmptyPayload, EmptyPayload>.delete(
        '/api/v1/items/:id',
        decodeRequest: EmptyPayload.fromJson,
        encodeRequest: _encodeEmpty,
        decodeResponse: EmptyPayload.fromJson,
        encodeResponse: _encodeEmpty,
      );

      expect(getBlob.method, HttpMethod.get);
      expect(getBlob.requiresAuth, isTrue);
      expect(publicHealth.requiresAuth, isFalse);
      expect(post.method, HttpMethod.post);
      expect(put.method, HttpMethod.put);
      expect(patch.method, HttpMethod.patch);
      expect(del.method, HttpMethod.delete);
    });

    test('encodes and decodes payloads symmetrically', () {
      const sample = _SamplePayload('grimoire');
      final encoded = getBlob.encodeResponse(sample);
      expect(getBlob.decodeResponse(encoded), sample);

      const empty = EmptyPayload();
      expect(EmptyPayload.fromJson(empty.toJson()), empty);
      expect(empty.hashCode, const EmptyPayload().hashCode);
    });

    test('resolves path parameters with URL encoding', () {
      final resolved = getBlob.resolvePath({
        'vaultId': 'vault 1',
        'blobId': 'note/a+b',
      });
      expect(resolved, '/api/v1/vaults/vault%201/blobs/note%2Fa%2Bb');
      expect(publicHealth.resolvePath(), '/health');
    });

    test('rejects missing, empty, or invalid paths', () {
      expect(() => getBlob.resolvePath({'vaultId': 'v1'}), throwsArgumentError);
      expect(
        () => getBlob.resolvePath({'vaultId': 'v1', 'blobId': '   '}),
        throwsArgumentError,
      );

      const relativeEndpoint = Endpoint<EmptyPayload, EmptyPayload>.get(
        'api/v1/no-leading-slash',
        decodeRequest: EmptyPayload.fromJson,
        encodeRequest: _encodeEmpty,
        decodeResponse: EmptyPayload.fromJson,
        encodeResponse: _encodeEmpty,
      );
      expect(relativeEndpoint.resolvePath, throwsArgumentError);
    });
  });
}

Map<String, Object?> _encodeEmpty(EmptyPayload value) => value.toJson();

Map<String, Object?> _encodeSample(_SamplePayload value) => value.toJson();
