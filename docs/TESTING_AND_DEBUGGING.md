# Testing, Previews & Runtime Debugging

Runbook for **Flutter 3.50+ / Dart 3.14+** verification, Widget Previews, live UI driving, and VM Service debugging.
*(Token tip: Read Sections 1–2 for standard unit/widget work; read Sections 3–5 only when attaching to a live app, preview server, or scaffolding `apps/<app>/`.)*

## 1. Verification Pyramid & Deterministic Gate

Run from the narrowest check upward, then run [`../scripts/check.sh`](../scripts/check.sh) before `code-reviewer`:

| Layer | Scope | Command / Tool | Required Checks |
| :--- | :--- | :--- | :--- |
| **1. Unit** | Pure Dart (`packages/realm_core`) | `./scripts/check.sh --quiet packages/realm_core` | Logic, serialization, endpoint/config resolution |
| **2. Widget** | Flutter UI (`packages/realm_ui`, future `apps/*`) | `./scripts/check.sh --quiet packages/realm_ui` | Both **light + dark** `Brightness` and `>= 2` `VenueBranding` seeds |
| **3. Preview** | Isolated UI states (no emulator/backend) | `(cd packages/realm_ui && flutter widget-preview start)` + `browser` | `@Preview` / `@MultiPreview` with `Example Venue` & explicit `Size` (no `dart:io`/`dart:ffi`) |
| **4. Golden** | Visual regression *(when configured)* | `alchemist` + `flutter_test_config.dart` | Inspect every diff in `failures/*.png` via `read_file` before `--update-goldens` |
| **5. E2E** | Future runnable apps (`apps/*`) | `integration_test` + `flutter_driver` (opt-in: Patrol / Maestro) | End-to-end flows; Patrol for native OS dialogs; Maestro for YAML smoke flows |
| **6. Repo Gate** | Full workspace | `./scripts/check.sh --quiet` | Format, `dart analyze`, hygiene, and all package tests |

## 2. Testability & Accessibility Contract (Every Widget/Screen)

1. **Test keys**: Add stable `ValueKey('...')` on interactive controls and landmarks (`WidgetTester`, `flutter_driver`, Patrol).
2. **Semantics**: Wrap icon-only buttons and custom controls in `Semantics(identifier: '...', label: '...')` (screen readers, Maestro, `flutter_a11y_agent`).
3. **A11y audit**: Run `flutter_a11y_agent` on new widgets/screens for contrast, tap targets, and semantics.
4. **White-label & endpoint neutrality**: Never hardcode venue brands, fixed colors, or `http(s)://` URLs in `lib/`; use `Theme.of(context)` / `VenueBranding` and `ClientEndpointConfig` ([Config, Branding & BYOK Secrets](CONFIG_AND_SECRETS.md)).

## 3. Live App Inspection & UI Driving (`dart mcp-server`)

1. **Connect**: Prefer DTD (`dtd` → `listDtdUris` → `connect` → `listConnectedApps`); fallback to `vm_service` → `connect`.
2. **Launch/Attach**: Use `flutter_app_lifecycle` MCP tools (`list_devices`, `launch_app`, `list_running_apps`, `get_app_logs`, `stop_app`) when enabled, or start `flutter run` as a background daemon.
3. **Inspect before acting**: Call `widget_inspector` → `get_widget_tree(summaryOnly: true)`—never guess widget keys or tree layout.
4. **Drive UI** *(requires `enableFlutterDriverExtension()`)*: Use `flutter_driver_command` (`tap`, `enter_text`, `scroll`, `scrollIntoView`, `waitFor`, `waitForAbsent`, `get_diagnostics_tree`, `screenshot`). *Opt-in alternative*: `marionette_mcp` (`get_interactive_elements`, `take_screenshots`, `get_logs`).
5. **Fix loop**: `get_runtime_errors` → edit → `hot_reload` (or `hot_restart` for `initState`/static/provider changes) → re-verify.

## 4. VM Service Debugger & `ext.realm.*` Extensions

- **VM Service RPC (`vm_service`)**: Works on live `flutter run` or paused tests (`dart test --pause-isolates-on-start` / `flutter test --start-paused`). Connect → `callMethod("getVM")` → use `getIsolate`, `addBreakpointWithScriptUri`, `resume`, `getStack`, and `evaluate` / `evaluateInFrame`. (IDE workflows can also use `dart debug_adapter` / `flutter debug-adapter`.)
- **Realm Debug Extensions (`dart:developer`)**: In future `apps/*`, register `ext.realm.getState` guarded by `kDebugMode` to return JSON with active route, `VenueBranding` summary (`Example Venue`, `HostingMode`), and non-secret UI state. **Never** include BYOK keys, tokens, or PII in service extension payloads. Discover via `listRegisteredServices` and call with `callMethod("ext.realm.getState", ...)`.

## 5. New Flutter App Checklist (Future `apps/<app>/`)

- [ ] `lib/main_test.dart` (or `kDebugMode`-guarded `enableFlutterDriverExtension()`) + `integration_test` in `dev_dependencies`.
- [ ] `kDebugMode`-only `ext.realm.getState` service extension (zero secrets/PII).
- [ ] `ValueKey('...')` and `Semantics(identifier: '...', label: '...')` on interactive elements.
- [ ] `apps/<app>/AGENTS.md` with launch commands, target devices, and `--dart-define-from-file=venue.json` (`example.com`).
