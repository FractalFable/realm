# packages/grimoire_notes

- **Purpose**: Interactive Grimoire note workspace (`GrimoireWorkspaceCubit` + `GrimoireWorkspaceScreen`).
- **Allowed deps**: `flutter`, `flutter_bloc`, `material_ui`, `realm_core`, `realm_ui`, `realm_a2ui`, `grimoire_core` (zero `tavern_*`, zero codegen).
- **Public API**: `lib/grimoire_notes.dart` (`GrimoireWorkspaceCubit`, `GrimoireWorkspaceState`, `GrimoireWorkspaceScreen`).
- **Commands**: `(cd packages/grimoire_notes && flutter test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: Plain Dart 3.14 sealed states; `AiTrustTier` respected on local RAG search; `ValueKey` + `Semantics` on controls; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/grimoire_notes/lib/src/cubit/**`).
