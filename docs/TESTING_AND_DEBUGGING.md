# Testing, Previews & Runtime Debugging

Actionable runbook for **Flutter 3.50+ / Dart 3.14+** testing, isolated Widget Previews, live UI inspection, and VM Service debugging.

- **Implemented packages today**: `packages/realm_core` (pure Dart) and `packages/realm_ui` (shared Flutter UI/theming).
- **Future runnable apps**: `apps/<app>/` (not yet populated; follow Section 5 when scaffolding a new Flutter app).
- **Tooling prerequisites**: see [Agent & MCP Setup](AGENT_SETUP.md) for enabling `dart mcp-server` (`flutter_app_lifecycle`), `browser`/Playwright, and opt-in E2E MCPs.

## 1. Verification Pyramid & Deterministic Gate

Run checks from the narrowest feedback loop upward, then run the full deterministic gate before `code-reviewer` (see [AI Efficiency & Autonomy](AI_EFFICIENCY.md)):

| Layer | Scope | Command / Tool | Required Checks |
| :--- | :--- | :--- | :--- |
| **1. Unit** | Pure Dart (`packages/realm_core`) | `(cd packages/realm_core && dart test --reporter=failures-only)` | Logic, serialization, endpoint/config resolution |
| **2. Widget** | Flutter primitives (`packages/realm_ui`, future `apps/*`) | `(cd packages/realm_ui && flutter test --reporter=failures-only)` | Both **light + dark** `Brightness` and distinct `VenueBranding` seeds |
| **3. Widget Preview** | Isolated UI states (no emulator/backend) | `flutter widget-preview start` + `browser` subagent (or Playwright MCP) | Render `@Preview` / `@MultiPreview` variants visually |
| **4. Golden** | Design-system primitives & core states | `alchemist` + `flutter_test_config.dart` *(when configured)* | Local vs. CI-safe goldens; inspect `failures/*.png` before updating |
| **5. Integration / E2E** | Future runnable apps (`apps/*`) | `integration_test` + `flutter_driver`; Patrol or Maestro when needed | End-to-end flows, native dialogs, smoke checks |
| **6. Repo Gate** | Entire workspace | [`../scripts/check.sh`](../scripts/check.sh) | Format, `dart analyze`, hygiene, and all package tests |

### Isolated UI Previews (Flutter Widget Previewer)

Use Flutter's built-in Widget Previewer to inspect `packages/realm_ui` components and future app views in a browser without spinning up a backend or mobile emulator:

1. Annotate preview functions with `@Preview(...)` or `@MultiPreview(...)` from `package:flutter/widget_previews.dart`.
2. Pass explicit `size` constraints (e.g., `Size(400, 240)`) and neutral `Example Venue` branding.
3. Keep previewed widgets free of direct `dart:io` or `dart:ffi` imports (Widget Previewer compiles for web).
4. Start the preview server as a background/daemon process inside the package or app directory (it runs persistently until stopped):
   ```bash
   (cd packages/realm_ui && flutter widget-preview start)
   ```
5. Open the printed local preview URL in Antigravity's `browser` subagent (or Playwright MCP in Claude Code) to visually verify spacing, contrast, overflow, and light/dark `VenueBranding` variants.

### Golden & Visual Regression Tests

- Prefer `alchemist` with `flutter_test_config.dart` to separate local host-rendered goldens from deterministic CI-safe goldens.
- **Mandatory Golden Rule**: Never blindly run `flutter test --update-goldens` to silence a failure. Always inspect every generated diff image in `failures/` with `read_file` first to confirm whether the pixel delta is an intended design change or a regression.

### Integration & E2E Tests (Future `apps/*`)

- **Baseline (`integration_test` + `flutter_driver`)**: Zero extra dependencies; call `enableFlutterDriverExtension()` in `lib/main_test.dart` (or `kDebugMode`-guarded entrypoint) so both `flutter test integration_test/` and `dart mcp-server` can drive the app.
- **Native OS UI (Patrol + Patrol MCP)**: Use when flows touch OS permission prompts, notifications, WebViews, or system settings.
- **Black-box smoke tests (Maestro + Maestro MCP)**: Optional lightweight YAML smoke flows; requires stable `Semantics(identifier: '...')` attributes on interactive elements.

### Pre-Review Deterministic Gate

Always run [`../scripts/check.sh`](../scripts/check.sh) from the workspace root before invoking `code-reviewer`. See [Monorepo & Linting](MONOREPO.md) for workspace layout and `dart analyze` rules.

## 2. Testability & Accessibility Contract (Every New Widget/Screen)

Apply this contract to all widgets in [`packages/realm_ui`](../packages/realm_ui/AGENTS.md) and future `apps/*`:

1. **Stable test keys**: Put `ValueKey('...')` on interactive controls and key landmarks (`WidgetTester`, `flutter_driver`, Patrol).
2. **Semantic identifiers & labels**: Wrap icon-only buttons, custom controls, and primary interactive elements in `Semantics(identifier: '...', label: '...')` (screen readers, Maestro, Mobile-MCP, `flutter_a11y_agent`).
3. **Accessibility audit**: Run `flutter_a11y_agent` (Antigravity) to audit new screens and primitives for contrast, tap targets, and semantics gaps.
4. **Strict brand & endpoint neutrality**: Never hardcode venue brands, fixed venue colors, or `http(s)://` URLs in `lib/`; use `Theme.of(context)` / `VenueBranding` and `ClientEndpointConfig` ([Config, Branding & BYOK Secrets](CONFIG_AND_SECRETS.md)).

## 3. Live App Inspection & UI Driving via `dart mcp-server`

Follow this exact MCP sequence when inspecting or driving a running Flutter app:

1. **Connect to DTD or VM Service**:
   - Prefer DTD: `dtd` → `listDtdUris` → `connect` → `listConnectedApps`.
   - Fallback (when launched outside DTD): `vm_service` → `connect` with the active VM Service URI.
2. **Launch or attach to the app**:
   - If `flutter_app_lifecycle` tools (`list_devices`, `launch_app`, `list_running_apps`, `get_app_logs`, `stop_app`) are enabled, launch and manage the app via MCP.
   - Otherwise, start `flutter run` in a background daemon process or attach to an existing IDE session.
3. **Inspect the widget tree before interacting**:
   - Call `widget_inspector` → `get_widget_tree` with `summaryOnly: true`. Never guess widget keys, text, or tree structure.
4. **Drive UI & capture visual state** *(requires `enableFlutterDriverExtension()`)*:
   - Use `flutter_driver_command` for `tap`, `enter_text`, `send_text_input_action`, `scroll`, `scrollIntoView`, `waitFor`, `waitForAbsent`, `get_diagnostics_tree` (with `renderObject` for layout/constraint debugging), and `screenshot`.
5. **Closed-loop fix cycle**:
   - Check `get_runtime_errors` → edit code → run `hot_reload` (or `hot_restart` after `initState`/static/provider-root changes) → re-verify via `get_runtime_errors` and `widget_inspector` / `screenshot`.

*Opt-in alternative*: **Marionette MCP** (`marionette_flutter` + `marionette_mcp`) provides a Playwright-style runtime bridge (`get_interactive_elements`, `take_screenshots`, `get_logs`) for Flutter apps when a higher-level interaction loop is preferred over `flutter_driver_command`.

## 4. Connecting to a Real Debugger (VM Service, Breakpoints & Custom Extensions)

### Direct VM Service RPC (`vm_service`)

Works against both live `flutter run` sessions and paused test runs (`dart test --pause-isolates-on-start` or `flutter test --start-paused`):

1. Connect via `vm_service` → `connect`.
2. Call `callMethod("getVM")` to discover isolates and pick the target `isolateId`.
3. Inspect and control execution:
   - `getIsolate` — inspect libraries, root script, and pause state.
   - `addBreakpointWithScriptUri` — set a source breakpoint by script URI and line.
   - `resume` — resume a paused isolate or step until the breakpoint hits.
   - `getStack` — inspect active call frames when paused.
   - `evaluate` / `evaluateInFrame` — evaluate Dart expressions in a library or paused stack frame.

### Realm Debug Service Extensions (`dart:developer`)

For future apps in `apps/*`, expose non-sensitive runtime diagnostics in debug mode only:

- Register extensions under `ext.realm.*` guarded by `kDebugMode` using `developer.registerExtension('ext.realm.getState', ...)`.
- Return JSON summarizing current route, active `VenueBranding` summary (e.g., `Example Venue`, `HostingMode`), and non-sensitive UI state.
- **Security rule**: **Never** include BYOK API keys, credentials, auth tokens, or PII in service extension payloads ([Config, Branding & BYOK Secrets](CONFIG_AND_SECRETS.md)).
- Agents discover active extensions via `vm_service` → `listRegisteredServices` and invoke them with `callMethod("ext.realm.getState", ...)`.

### DAP Support

Dart and Flutter ship `dart debug_adapter` and `flutter debug-adapter` for clients or IDE workflows using Debug Adapter Protocol (DAP) bridges.

## 5. New Flutter App Debug-Readiness Checklist (Future `apps/<app>/`)

When creating any runnable Flutter app under `apps/<app>/`, include:

- [ ] `lib/main_test.dart` (or `kDebugMode`-guarded `enableFlutterDriverExtension()`) for `flutter_driver` and MCP UI driving.
- [ ] `kDebugMode`-only `ext.realm.getState` service extension returning non-secret route/branding/state JSON.
- [ ] `integration_test` in `dev_dependencies`, plus `ValueKey('...')` and `Semantics(identifier: '...', label: '...')` on interactive controls.
- [ ] `apps/<app>/AGENTS.md` documenting exact launch commands, supported target devices, and required `--dart-define` / `--dart-define-from-file` flags (e.g., `venue.json` with `example.com`).
