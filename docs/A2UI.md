# A2UI Architecture Note

*Verified: 2026-11-22*

**A2UI (Agent-to-User Interface)** is Google's open-source (Apache 2.0) declarative JSON UI protocol for AI agents. Rather than emitting executable HTML or code, agents stream declarative surface/component descriptions that the client renders using its own approved native widget catalog.

## Current Ecosystem Status (November 2026)

- **A2UI 1.0 Stable (November 2026)**: Reached 1.0 with bidirectional function calling/actions, streaming updates, accessibility support, and an official Dart SDK alongside Flutter native rendering.
- **Flutter Package Rebrand (`genui` → `a2ui_flutter`)**: Legacy `genui` was rebranded and split into modular `pub.dev` packages:
  - `a2ui_core` — Pure Dart protocol parsing, payload validation, surface/data state models, and bidirectional RPC.
  - `a2ui_agent` — Dart agent payload generation and catalog negotiation.
  - `a2ui_flutter` — Native Flutter surface/widget renderer (`basic_catalog` + custom catalogs).
  - `genui_customizer` — Runtime appearance/preference customization without an AI roundtrip.
- **Rule for Realm**: Do **not** install legacy `genui` in new Realm apps; use `a2ui_core` / `a2ui_flutter` / `a2ui_agent` when adding generative UI.

## Fit & Boundaries for Realm

1. **White-Label Branding**: Because A2UI renders through a client-owned native catalog, every generated card, table, or action form automatically inherits the instance's `AppBranding` / `VenueBranding` and `realm_ui` Material theme—avoiding unstyled or inconsistent webviews.
2. **BYOK API Keys & Privacy Gating**: Generative UI surfaces must remain **optional and gracefully gated** behind the operator's BYOK LLM configuration (or local private LLM). When AI is disabled, all core workflows continue normally.
3. **Package Isolation**: Isolate A2UI integration into `packages/realm_a2ui` (`resolution: workspace`) rather than coupling `realm_core` or `realm_ui` to agent/LLM dependencies.
4. **Tavern Use Cases** ([Tavern Architecture](apps/TAVERN.md)):
   - **Staff / Manager Copilot**: Natural-language operational queries (sales summaries, low-stock alerts, table/order status) rendered as interactive cards with typed confirmation buttons.
   - **Guest Discovery**: Interactive menu/pairing filters and allergen-aware suggestions mapped to venue catalog widgets.
5. **Grimoire Use Cases** ([Grimoire Architecture](apps/GRIMOIRE.md)):
   - **Personal Knowledge Dashboards**: Agents query the user's **local-first hybrid RAG** index over E2EE notes via client-side tools and stream A2UI surfaces (summaries, comparison tables, timelines, interactive action cards) without exposing raw vault keys to the server.
   - **Script-Emitted UI**: Note scripts (`ScriptBlock`) can return A2UI JSON payloads rendered natively inside a note via `realm_a2ui`, giving scripts rich native UI across iOS, Android, macOS, and Web.
6. **Security & Tier 4 Boundary**: Treat A2UI strictly as presentation + typed user intents. Pricing, inventory locks, allergen integrity, authorization, payment/POS actions, and E2EE vault access must always be enforced outside the A2UI payload with explicit confirmation gates (reviewed under Tier 4 in [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md)).
