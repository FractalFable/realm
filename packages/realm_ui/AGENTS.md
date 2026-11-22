# packages/realm_ui — Agent Rules

Scoped rules for creating or modifying shared Flutter UI primitives and white-label theming in `packages/realm_ui`.

1. **Modular Design Imports**: Import Material/Cupertino widgets from `package:material_ui/material_ui.dart` (Flutter 3.50+ modular design packages and `migrate_design_widgets`).
2. **Strict Brand Neutrality**: Derive all colors, typography, and radii from `Theme.of(context)` / `VenueBranding`. Never hardcode venue brands, fixed venue colors, or `http(s)://` URLs in `lib/`.
3. **Required Deliverables per Widget**:
   - **Widget test** in `test/` verifying both **light + dark** brightness and at least two distinct `VenueBranding` seed colors.
   - **Widget Preview** using `@Preview` / `@MultiPreview` from `package:flutter/widget_previews.dart` with neutral `Example Venue` branding and explicit `size` constraints (no `dart:io` or `dart:ffi`).
   - **Testability & A11y**: Stable `ValueKey('...')` and `Semantics(identifier: '...', label: '...')` on interactive controls and icon-only buttons.
4. **Visual & Accessibility Verification**:
   - Run `flutter widget-preview start` as a background/daemon process inside `packages/realm_ui` and visually inspect previews with the `browser` subagent (or Playwright MCP).
   - Run `flutter_a11y_agent` (Antigravity) to audit accessibility compliance.
5. **Checks**: Run `(cd packages/realm_ui && flutter test --reporter=failures-only)` and `./scripts/check.sh` from the repository root before review.

See [Testing, Previews & Runtime Debugging](../../docs/TESTING_AND_DEBUGGING.md), [Monorepo & Linting](../../docs/MONOREPO.md), and [Config, Branding & BYOK Secrets](../../docs/CONFIG_AND_SECRETS.md).
