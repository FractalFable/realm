# Monorepo & Linting

Realm uses **Dart Pub Workspaces** (`sdk: ^3.14.0`, workspace globs from Dart 3.11+) so all Dart and Flutter packages share a single root `pubspec.lock`, unified dependency resolution, and a single analyzer context.

## Directory Layout

- `pubspec.yaml` — Root workspace manifest (`workspace:` globs) and shared `pubspec.lock`.
- `packages/` — Reusable Dart and Flutter libraries (`realm_lints`, `realm_core`, `realm_ui`).
- `apps/` — Deployable Flutter apps, Dart servers, and supporting non-Dart tools (reserved via `apps/.gitkeep`).

Every Dart/Flutter package inside `packages/*` or `apps/*` must include `resolution: workspace` in its `pubspec.yaml` and reference sibling workspace packages by version constraint (e.g. `realm_core: ^0.1.0`) without `path:` overrides.

## Workspace Commands

Run from the repository root:

```bash
flutter pub get            # Resolve all workspace packages (use flutter, not dart, while Flutter packages exist in the workspace)
dart pub workspace list    # List all packages discovered in the workspace
dart analyze               # Analyze every workspace package cleanly
dart format .              # Format using Dart 3.7+ tall-style formatting (page_width: 80)
```

Target a specific package from the root with `-C`:

```bash
dart pub -C packages/realm_core add <package>
```

Run tests per package:

```bash
(cd packages/realm_core && dart test)
(cd packages/realm_ui && flutter test)
```

## Linter & Analyzer Rules (`packages/realm_lints`)

Shared lint presets live in [`packages/realm_lints`](../packages/realm_lints):

- `package:realm_lints/dart.yaml` — Pure Dart preset (`package:lints/recommended.yaml` + strict language modes `strict-casts`, `strict-inference`, `strict-raw-types`, error-level async/resource checks like `unawaited_futures`, `discarded_futures`, `cancel_subscriptions`, `close_sinks`, and Dart 3.13 idioms like `use_declaring_parameters` and `unnecessary_primary_constructor_body`).
- `package:realm_lints/flutter.yaml` — Flutter preset using multi-include (`package:realm_lints/dart.yaml` + `package:flutter_lints/flutter.yaml`) plus widget performance and styling rules (`use_colored_box`, `use_decorated_box`, `sized_box_shrink_expand`, `migrate_design_widgets`).

## Adding New Packages & Apps

1. **New Dart/Flutter package or app**:
   - Place under `packages/<name>` or `apps/<name>` (and uncomment `- apps/*` in root [`pubspec.yaml`](../pubspec.yaml) once the first `apps/` Dart/Flutter package is added).
   - Set `environment: sdk: ^3.14.0` and `resolution: workspace` in its `pubspec.yaml`.
   - Add `realm_lints: ^0.1.0` to `dev_dependencies` and point `analysis_options.yaml` at `package:realm_lints/dart.yaml` or `package:realm_lints/flutter.yaml`.
   - Run `flutter pub get` from the root.
2. **New non-Dart tool/app** (e.g. web site, Python utility, infra script):
   - Place it in its own directory under `apps/<name>` or `tools/<name>` without a `pubspec.yaml`; Dart workspace globs ignore directories without `pubspec.yaml`.
   - Add a local `<dir>/AGENTS.md` if it has stack-specific rules.
