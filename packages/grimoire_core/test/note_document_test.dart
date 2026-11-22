import 'package:grimoire_core/grimoire_core.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2026, 11, 22, 10);
  final updated = DateTime.utc(2026, 11, 22, 11);

  group('NoteDocument', () {
    test('round-trips JSON with mixed interactive blocks and cloud flag', () {
      final doc = NoteDocument(
        id: 'note-1',
        title: 'Private Research',
        blocks: [
          RichTextBlock(id: 'b1', text: 'Overview', style: .heading1),
          NoteLinkBlock(id: 'b2', targetNoteId: 'note-2'),
          WebEmbedBlock(
            id: 'b3',
            url: Uri.parse('https://example.com/reference'),
          ),
          ScriptBlock(
            id: 'b4',
            source: 'return emitA2ui({ card: "ok" });',
            grantedPermissions: const {ScriptPermission.emitA2ui},
          ),
          A2uiBlock(id: 'b5', surfaceId: 'surf-1'),
        ],
        tags: const {'research', 'private'},
        excludeFromCloudAi: true,
        createdAt: created,
        updatedAt: updated,
        revision: 3,
      );

      expect(doc.linkedNoteIds, {'note-2'});
      final decoded = NoteDocument.fromJson(doc.toJson());
      expect(decoded, equals(doc));
      expect(decoded.excludeFromCloudAi, isTrue);
    });

    test('rejects duplicate block IDs, bad timestamps, and blank fields', () {
      expect(
        () => NoteDocument(
          id: 'note-dup',
          title: 'Duplicates',
          blocks: [
            RichTextBlock(id: 'same', text: 'A'),
            RichTextBlock(id: 'same', text: 'B'),
          ],
          createdAt: created,
          updatedAt: updated,
        ),
        throwsArgumentError,
      );

      expect(
        () => NoteDocument(
          id: 'note-time',
          title: 'Bad Time',
          createdAt: updated,
          updatedAt: created,
        ),
        throwsArgumentError,
      );

      expect(
        () => NoteDocument(
          id: 'note-rev',
          title: 'Bad Rev',
          createdAt: created,
          updatedAt: updated,
          revision: -1,
        ),
        throwsArgumentError,
      );

      expect(
        () => NoteDocument(
          id: 'note-tag',
          title: 'Bad Tag',
          tags: const {' '},
          createdAt: created,
          updatedAt: updated,
        ),
        throwsArgumentError,
      );
    });
  });
}
