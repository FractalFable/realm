import 'package:grimoire_core/grimoire_core.dart';
import 'package:test/test.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 22, 10);

  NoteDocument makeNote({
    required String id,
    required String title,
    DateTime? updatedAt,
    List<NoteBlock> blocks = const [],
    Set<String> tags = const {},
    bool excludeFromCloudAi = false,
    int revision = 0,
  }) => NoteDocument(
    id: id,
    title: title,
    createdAt: baseTime,
    updatedAt: updatedAt ?? baseTime,
    blocks: blocks,
    tags: tags,
    excludeFromCloudAi: excludeFromCloudAi,
    revision: revision,
  );

  group('InMemoryVaultStore', () {
    test('rejects duplicate initial note IDs', () {
      final first = makeNote(id: 'dup', title: 'First');
      final second = makeNote(id: 'dup', title: 'Second');
      expect(
        () => InMemoryVaultStore(initialNotes: [first, second]),
        throwsArgumentError,
      );
    });

    test('lists deterministically and bumps revision on save', () async {
      var tick = 0;
      final store = InMemoryVaultStore(
        initialNotes: [
          makeNote(
            id: 'note-b',
            title: 'Note B',
            updatedAt: baseTime.add(const Duration(minutes: 1)),
          ),
          makeNote(
            id: 'note-a',
            title: 'Note A',
            updatedAt: baseTime.add(const Duration(minutes: 1)),
          ),
        ],
        now: () => baseTime.add(Duration(minutes: 10 + tick++)),
      );

      final initial = await store.listNotes();
      expect(initial.map((n) => n.id), ['note-a', 'note-b']);

      final saved = await store.saveNote(
        initial.last.copyWith(title: 'Note B Updated'),
        expectedRevision: 0,
      );
      expect(saved.revision, 1);
      expect(saved.title, 'Note B Updated');

      final afterSave = await store.listNotes();
      expect(afterSave.map((n) => n.id), ['note-b', 'note-a']);
      expect((await store.getNote('note-b'))?.revision, 1);
      expect(await store.deleteNote('note-a'), isTrue);
      expect(await store.deleteNote('note-a'), isFalse);
      expect(await store.getNote('note-a'), isNull);
    });

    test(
      'throws VaultRevisionConflictException on stale or missing revision',
      () async {
        final store = InMemoryVaultStore(
          initialNotes: [makeNote(id: 'n1', title: 'Initial', revision: 2)],
        );

        await expectLater(
          () => store.saveNote(
            makeNote(id: 'n1', title: 'Stale'),
            expectedRevision: 1,
          ),
          throwsA(
            isA<VaultRevisionConflictException>()
                .having((e) => e.noteId, 'noteId', 'n1')
                .having((e) => e.expectedRevision, 'expectedRevision', 1)
                .having((e) => e.actualRevision, 'actualRevision', 2),
          ),
        );

        await expectLater(
          () => store.saveNote(
            makeNote(id: 'missing', title: 'Missing'),
            expectedRevision: 0,
          ),
          throwsA(
            isA<VaultRevisionConflictException>()
                .having((e) => e.noteId, 'noteId', 'missing')
                .having((e) => e.actualRevision, 'actualRevision', -1),
          ),
        );
      },
    );
  });

  group('LocalNoteSearchIndex', () {
    const index = LocalNoteSearchIndex();

    final secretNote = makeNote(
      id: 'secret-vault',
      title: 'Private Recovery Keys',
      excludeFromCloudAi: true,
      tags: const {'e2ee', 'recovery'},
      blocks: [
        RichTextBlock(id: 'r1', text: 'Argon2id passphrase backup ritual.'),
        NoteLinkBlock(id: 'l1', targetNoteId: 'public-guide'),
      ],
    );
    final publicGuide = makeNote(
      id: 'public-guide',
      title: 'Workspace Guide',
      tags: const {'guide'},
      blocks: [
        RichTextBlock(id: 'r2', text: 'Use GraphRAG to traverse linked notes.'),
        NoteLinkBlock(id: 'l2', targetNoteId: 'linked-only'),
        NoteLinkBlock(id: 'l3', targetNoteId: 'secret-vault'),
      ],
    );
    final linkedOnly = makeNote(
      id: 'linked-only',
      title: 'Appendix',
      tags: const {'reference'},
      blocks: [
        RichTextBlock(id: 'r3', text: 'Supplementary reference material.'),
      ],
    );

    final notes = [secretNote, publicGuide, linkedOnly];

    test('scores direct matches and pulls GraphRAG neighbors', () {
      final hits = index.search(notes: notes, query: 'graphrag');
      expect(hits.map((h) => h.note.id), [
        'public-guide',
        'linked-only',
        'secret-vault',
      ]);
      expect(hits.first.matchedTerms, {'graphrag'});
      expect(hits.first.score, 4);
      expect(hits[1].score, 2);
      expect(hits[1].matchedTerms, isEmpty);
      expect(
        hits.first.graphNeighborIds,
        containsAll(['linked-only', 'secret-vault']),
      );
    });

    test(
      'optInByokCloud excludes excludeFromCloudAi notes and neighbor IDs',
      () {
        final hits = index.search(
          notes: notes,
          query: 'recovery',
          trustTier: AiTrustTier.optInByokCloud,
        );
        expect(hits, isEmpty);

        final guideHits = index.search(
          notes: notes,
          query: 'graphrag',
          trustTier: AiTrustTier.optInByokCloud,
        );
        expect(guideHits.map((h) => h.note.id), [
          'public-guide',
          'linked-only',
        ]);
        for (final hit in guideHits) {
          expect(hit.note.id, isNot('secret-vault'));
          expect(hit.graphNeighborIds, isNot(contains('secret-vault')));
        }
      },
    );

    test('filters by requiredTags and parses AiTrustTier names strictly', () {
      final hits = index.search(
        notes: notes,
        query: '',
        requiredTags: const {'guide'},
      );
      expect(hits.map((h) => h.note.id), ['public-guide']);
      expect(AiTrustTier.fromName('strictLocal'), AiTrustTier.strictLocal);
      expect(() => AiTrustTier.fromName('unknownTier'), throwsArgumentError);
    });
  });

  group('SandboxedScriptRuntime', () {
    const runtime = SandboxedScriptRuntime(a2uiCatalogId: 'test_catalog');

    final overview = makeNote(
      id: 'overview',
      title: 'Overview',
      blocks: [
        RichTextBlock(
          id: 'c1',
          text: 'Verify AEAD',
          style: RichTextStyle.checklist,
          checked: true,
        ),
        RichTextBlock(
          id: 'c2',
          text: 'Ship web build',
          style: RichTextStyle.checklist,
          checked: false,
        ),
        NoteLinkBlock(id: 'l1', targetNoteId: 'child'),
      ],
    );
    final child = makeNote(
      id: 'child',
      title: 'Child Note',
      blocks: [NoteLinkBlock(id: 'l2', targetNoteId: 'overview')],
    );

    test(
      'denies execution when block or user lacks required permissions',
      () async {
        final block = ScriptBlock(
          id: 'sc1',
          source: 'return { linkedCount: 1 };',
          grantedPermissions: const {ScriptPermission.readCurrentNote},
        );

        final missingGrant = await runtime.execute(
          block,
          ScriptExecutionContext(
            currentNote: overview,
            allNotes: [overview, child],
            approvedPermissions: const {
              ScriptPermission.readCurrentNote,
              ScriptPermission.emitA2ui,
            },
          ),
        );
        expect(
          missingGrant,
          isA<ScriptErrorResult>().having(
            (r) => r.missingPermissions,
            'missingPermissions',
            {ScriptPermission.emitA2ui},
          ),
        );

        final grantedBlock = ScriptBlock(
          id: 'sc2',
          source: 'return { linkedCount: 1 };',
          grantedPermissions: const {
            ScriptPermission.readCurrentNote,
            ScriptPermission.emitA2ui,
          },
        );
        final missingApproval = await runtime.execute(
          grantedBlock,
          ScriptExecutionContext(
            currentNote: overview,
            allNotes: [overview, child],
            approvedPermissions: const {ScriptPermission.readCurrentNote},
          ),
        );
        expect(
          missingApproval,
          isA<ScriptErrorResult>().having(
            (r) => r.missingPermissions,
            'missingPermissions',
            {ScriptPermission.emitA2ui},
          ),
        );
      },
    );

    test('blocks network access in offline sandbox', () async {
      final netBlock = ScriptBlock(
        id: 'sc-net',
        source: 'return fetch("example");',
        grantedPermissions: const {
          ScriptPermission.readCurrentNote,
          ScriptPermission.network,
        },
      );

      final result = await runtime.execute(
        netBlock,
        ScriptExecutionContext(
          currentNote: overview,
          allNotes: [overview, child],
          approvedPermissions: const {
            ScriptPermission.readCurrentNote,
            ScriptPermission.network,
          },
        ),
      );
      expect(
        result,
        isA<ScriptErrorResult>().having(
          (r) => r.message,
          'message',
          contains('Network access is blocked'),
        ),
      );
    });

    test(
      'returns ScriptValueResult and ScriptA2uiResult with live metrics',
      () async {
        final valueBlock = ScriptBlock(
          id: 'sc-val',
          source: 'return queryNotes().length;',
          grantedPermissions: const {
            ScriptPermission.readCurrentNote,
            ScriptPermission.queryNotes,
          },
        );

        final valueResult = await runtime.execute(
          valueBlock,
          ScriptExecutionContext(
            currentNote: overview,
            allNotes: [overview, child],
            approvedPermissions: const {
              ScriptPermission.readCurrentNote,
              ScriptPermission.queryNotes,
            },
          ),
        );
        expect(
          valueResult,
          isA<ScriptValueResult>()
              .having((r) => r.data['blockCount'], 'blockCount', 3)
              .having((r) => r.data['checklistDone'], 'checklistDone', 1)
              .having((r) => r.data['checklistTotal'], 'checklistTotal', 2)
              .having((r) => r.data['outgoingLinks'], 'outgoingLinks', 1)
              .having((r) => r.data['backlinks'], 'backlinks', 1)
              .having((r) => r.data['totalNotes'], 'totalNotes', 2),
        );

        final a2uiBlock = ScriptBlock(
          id: 'sc-ui',
          source: 'return { linkedCount: 1 };',
          grantedPermissions: const {
            ScriptPermission.readCurrentNote,
            ScriptPermission.emitA2ui,
          },
        );

        final a2uiResult = await runtime.execute(
          a2uiBlock,
          ScriptExecutionContext(
            currentNote: overview,
            allNotes: [overview, child],
            approvedPermissions: const {
              ScriptPermission.readCurrentNote,
              ScriptPermission.emitA2ui,
            },
          ),
        );
        expect(
          a2uiResult,
          isA<ScriptA2uiResult>()
              .having((r) => r.surfaceId, 'surfaceId', 'script_sc-ui')
              .having(
                (r) => r.messages.first['createSurface'],
                'createSurface',
                isA<Map<String, Object?>>(),
              ),
        );
      },
    );
  });
}
