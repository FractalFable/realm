import 'package:grimoire_core/grimoire_core.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 11, 22, 12);

  NoteDocument makeNote(String id, List<String> targets) => NoteDocument(
    id: id,
    title: 'Note $id',
    blocks: [
      for (var i = 0; i < targets.length; i++)
        NoteLinkBlock(id: '$id-l$i', targetNoteId: targets[i]),
    ],
    createdAt: ts,
    updatedAt: ts,
  );

  group('NoteGraph', () {
    test(
      'computes outgoing links, backlinks, and cycle-safe N-hop neighbors',
      () {
        final graph = NoteGraph([
          makeNote('a', ['b']),
          makeNote('b', ['c', 'a']),
          makeNote('c', ['d']),
          makeNote('d', const []),
        ]);

        expect(graph.outgoingLinks('a'), {'b'});
        expect(graph.backlinksFor('a'), {'b'});
        expect(graph.backlinksFor('c'), {'b'});

        expect(graph.neighbors('a', maxDepth: 0), isEmpty);
        expect(graph.neighbors('a'), {'b'});
        expect(graph.neighbors('a', maxDepth: 2), {'b', 'c'});
        expect(graph.neighbors('a', maxDepth: 5), {'b', 'c', 'd'});
        expect(graph.neighbors('missing'), isEmpty);
      },
    );

    test('rejects duplicate note IDs and negative maxDepth', () {
      expect(
        () => NoteGraph([makeNote('a', const []), makeNote('a', const [])]),
        throwsArgumentError,
      );

      final graph = NoteGraph([makeNote('a', const [])]);
      expect(() => graph.neighbors('a', maxDepth: -1), throwsArgumentError);
    });
  });
}
