import 'package:grimoire_core/grimoire_core.dart';
import 'package:test/test.dart';

void main() {
  group('NoteBlock', () {
    test('round-trips RichTextBlock variants and validates checklist flag', () {
      final heading = RichTextBlock(
        id: 'b1',
        text: 'Project Notes',
        style: .heading1,
      );
      final task = RichTextBlock(
        id: 'b2',
        text: 'Verify E2EE',
        style: .checklist,
        checked: true,
      );

      expect(NoteBlock.fromJson(heading.toJson()), equals(heading));
      expect(NoteBlock.fromJson(task.toJson()), equals(task));

      expect(
        () => RichTextBlock(id: 'b3', text: 'Invalid', checked: false),
        throwsArgumentError,
      );
      expect(
        () => NoteBlock.fromJson({'type': 'unknown', 'id': 'b4'}),
        throwsArgumentError,
      );
    });

    test('round-trips NoteLinkBlock and rejects empty IDs', () {
      final link = NoteLinkBlock(
        id: 'link-1',
        targetNoteId: 'note-2',
        alias: 'Design Doc',
        targetBlockId: 'sec-1',
      );

      expect(NoteBlock.fromJson(link.toJson()), equals(link));
      expect(
        () => NoteLinkBlock(id: ' ', targetNoteId: 'note-2'),
        throwsArgumentError,
      );
      expect(
        () => NoteLinkBlock(id: 'link-2', targetNoteId: ''),
        throwsArgumentError,
      );
    });

    test('validates WebEmbedBlock allows only HTTPS with no userinfo', () {
      final embed = WebEmbedBlock(
        id: 'embed-1',
        url: Uri.parse('https://example.com/widget?view=compact'),
        title: 'Example Embed',
        allowInteractive: true,
      );

      expect(NoteBlock.fromJson(embed.toJson()), equals(embed));

      for (final unsafeUrl in [
        Uri.parse('http://example.com/widget'),
        Uri.parse('javascript:alert(1)'),
        Uri.parse('file:///etc/passwd'),
        Uri.parse('https:///missing-host'),
        Uri.parse('https://user:pass@example.com/embed'),
      ]) {
        expect(
          () => WebEmbedBlock(id: 'embed-bad', url: unsafeUrl),
          throwsArgumentError,
        );
      }
    });

    test('round-trips ScriptBlock with defensive permission sets', () {
      final permissions = {ScriptPermission.readCurrentNote};
      final script = ScriptBlock(
        id: 'script-1',
        source: 'return { title: "Summary" };',
        grantedPermissions: permissions,
        title: 'Summarize',
      );
      permissions.add(ScriptPermission.network);

      expect(script.grantedPermissions, {ScriptPermission.readCurrentNote});
      expect(NoteBlock.fromJson(script.toJson()), equals(script));
      expect(
        () => ScriptBlock(id: 'script-2', source: '   '),
        throwsArgumentError,
      );
    });

    test('round-trips A2uiBlock with deep equality and immutable surface', () {
      final a2ui = A2uiBlock(
        id: 'a2ui-1',
        surfaceId: 'surf-1',
        prompt: 'Show weekly tasks',
        cachedSurfaceJson: {
          'components': [
            {'id': 'root', 'type': 'Card'},
          ],
        },
      );

      final decoded = NoteBlock.fromJson(a2ui.toJson());
      expect(decoded, equals(a2ui));
      expect(decoded.hashCode, equals(a2ui.hashCode));
    });
  });
}
