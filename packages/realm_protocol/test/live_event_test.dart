import 'package:realm_protocol/realm_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('LiveEvent', () {
    test('round-trips JSON and normalizes timestamps to UTC', () {
      final localLike = DateTime.parse('2026-11-23T01:15:00+02:00');
      final event = LiveEvent(
        type: 'blob.updated',
        eventId: 'evt-01',
        occurredAt: localLike,
        payload: {
          'blobId': 'note-1',
          'revision': 3,
          'tags': ['e2ee', 'sync'],
        },
      );

      expect(event.occurredAt.isUtc, isTrue);
      expect(event.occurredAt, DateTime.utc(2026, 11, 22, 23, 15));

      final decoded = LiveEvent.fromJson(event.toJson());
      expect(decoded, event);
      expect(decoded.hashCode, event.hashCode);
    });

    test('deeply freezes nested payload collections', () {
      final sourceNested = {'revision': 1};
      final sourceList = [
        {'id': 'a'},
      ];
      final event = LiveEvent(
        type: 'sync.hint',
        eventId: 'evt-02',
        occurredAt: DateTime.utc(2026, 11, 23),
        payload: {'nested': sourceNested, 'items': sourceList},
      );

      sourceNested['revision'] = 999;
      sourceList.add({'id': 'b'});

      final nested = event.payload['nested']! as Map<String, Object?>;
      final items = event.payload['items']! as List<Object?>;
      expect(nested['revision'], 1);
      expect(items, hasLength(1));
      expect(() => event.payload['x'] = 1, throwsUnsupportedError);
      expect(() => nested['revision'] = 2, throwsUnsupportedError);
      expect(() => items.add('x'), throwsUnsupportedError);
    });

    test('rejects invalid event metadata or non-timezone timestamps', () {
      expect(
        () => LiveEvent(
          type: '   ',
          eventId: 'evt-1',
          occurredAt: DateTime.utc(2026, 11, 23),
        ),
        throwsArgumentError,
      );
      expect(
        () => LiveEvent(
          type: 'sync',
          eventId: '',
          occurredAt: DateTime.utc(2026, 11, 23),
        ),
        throwsArgumentError,
      );
      expect(
        () => LiveEvent.fromJson({
          'type': 'sync',
          'eventId': 'evt-1',
          'occurredAt': '2026-11-23T00:00:00',
        }),
        throwsArgumentError,
      );
      expect(
        () => LiveEvent.fromJson({
          'type': 'sync',
          'eventId': 'evt-1',
          'occurredAt': '2026-11-23T00:00:00Z',
          'payload': ['not-a-map'],
        }),
        throwsArgumentError,
      );
    });
  });
}
