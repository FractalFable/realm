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

1. **White-Label Branding**: Because A2UI renders through a client-owned native catalog, every generated card, table, or action form automatically inherits the venue's `VenueBranding` and `realm_ui` Material theme—avoiding unstyled or inconsistent webviews.
2. **BYOK API Keys**: Generative UI surfaces must remain **optional and gracefully gated** behind the operator's BYOK LLM configuration (when no API key is configured, all core pub/restaurant workflows continue normally without AI).
3. **Package Isolation**: When adopted, isolate A2UI integration into an optional `packages/realm_a2ui` workspace package (`resolution: workspace`) rather than coupling `realm_core` or `realm_ui` to agent/LLM dependencies.
4. **Good Initial Use Cases**:
   - **Staff / Manager Copilot**: Natural-language operational queries (sales summaries, low-stock alerts, table/order status) rendered as interactive cards with typed confirmation buttons.
   - **Customer Discovery**: Interactive menu/pairing filters and allergen-aware suggestions mapped to venue catalog widgets.
5. **Security & Tier 4 Boundary**: Treat A2UI strictly as presentation + typed user intents. Pricing, inventory locks, allergen integrity, authorization, and payment/POS actions must always be enforced server-side and pass explicit confirmation gates (reviewed under Tier 4 in [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md)).
