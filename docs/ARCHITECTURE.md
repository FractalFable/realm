# Architecture Decisions

*Status: Accepted direction, details Proposed (2026-11-22). Ecosystem versions verified on that date.*

Realm is built and maintained mostly by AI agents, and few humans will read the code. Every decision here favors what makes agents reliable: **strict types, codegen over hand-written glue, small packages with one job, one obvious way to do each thing, fast deterministic tests, and a `CLAUDE.md` in every package.** A second goal is **no framework lock-in**: every layer is plain Dart, plain SQL, or a standard container, so any piece can be swapped without a rewrite.

Decisions already made elsewhere still hold: three-layer config and BYOK ([Config & Secrets](CONFIG_AND_SECRETS.md)), pub workspaces and `realm_lints` ([Monorepo](MONOREPO.md)), risk tiers ([Review Policy](REVIEW_POLICY.md)), A2UI isolation ([A2UI](A2UI.md)).

**Realm is a multi-app monorepo.** Each app lives under its own name, and apps share building blocks through app-neutral `realm_*` packages:
- **Tavern**: open-source pub and restaurant management (staff dashboard, guest ordering, server). Every Tavern-specific decision below is marked as such.
- **Grimoire**: note taking. It has its own section when its decisions are made.
- More apps may follow. A building block goes into a `realm_*` package once it is not specific to one app; until then it stays inside that app's packages (§4).

**Read only the section your task needs.** §1 is the summary; §4 covers app versus shared packages; §12 covers Tavern's sign-in, payments, tables, bills, and languages, including what is still open.

## 1. Decision Summary

| # | Area | Decision | Rejected |
| :--- | :--- | :--- | :--- |
| D1 | Product scope | Tavern: two web apps (staff dashboard, guest ordering) plus one server; **web only, responsive** (phone, tablet, laptop); **online only**; **one venue per instance** | Store apps, offline ordering, multi-venue |
| D2 | Hosting | **One cheap VPS**, Docker Compose: Caddy + the app's server + Postgres, one domain per app instance | Managed cloud services, Kubernetes, Redis |
| D3 | Backend | **Relic 2** (`relic` router + `relic_native` adapter) in each app's server (`apps/tavern_server`), shared server building blocks in `realm_server_kit`, typed endpoints | Serverpod (locks models, ORM, client, and auth to one framework), shelf (slower, fewer typed APIs), Dart Frog (no release since 2025-11) |
| D4 | Database | **PostgreSQL 16** via `package:postgres` 3.x with plain SQL; numbered SQL migrations applied by the server at startup | SQLite (runner-up), drift (no stable Postgres 2.x), ORMs |
| D5 | Shared DTOs | **`packages/realm_protocol`**: the `Endpoint`, `ApiError`, and `Result` machinery; each app's `freezed` + `json_serializable` DTOs and endpoint constants in `<app>_protocol` (`tavern_protocol`), used by that app's server and clients | Duplicated client/server classes, OpenAPI |
| D6 | State | **`flutter_bloc` Cubits** with sealed `freezed` states | Riverpod, `ChangeNotifier`, `get_it` |
| D7 | Routing | **`go_router` + `go_router_builder`** typed routes | String paths, `auto_route` |
| D8 | Live updates | One **WebSocket** per client (staff: signed-in session; guest: their own order's token); the client refetches on reconnect | Polling, a message broker |
| D9 | Codegen | `build_runner` (`freezed`, `json_serializable`, `go_router_builder`) behind `./scripts/gen.sh`; generated files committed | Hand-written `==`/`copyWith`/`fromJson`, macros (cancelled) |
| D10 | Packages | Thin apps, one package per feature named `<app>_<feature>`, app-neutral building blocks in `realm_*`, strict import direction (§4) | Feature folders inside each app |
| D11 | BYOK | Existing envelope-encryption design, isolated in `packages/realm_vault` | Secrets mixed into query code |
| D12 | Tests | Pure-Dart unit > Cubit > widget > server-with-Postgres > E2E smoke | Large E2E suites as the main proof |

## 2. Product Scope and Hosting (D1, D2)

**Tavern apps** (Flutter web, responsive from phone to laptop):

| App | Users | First screens |
| :--- | :--- | :--- |
| `apps/tavern_staff` | Workers and the manager | Live order board, order status changes, menu editing, settings (branding, BYOK keys; manager only) |
| `apps/tavern_guest` | Guests at the venue | Menu, cart, place order, order status |
| `apps/tavern_server` | — | API, WebSocket, migrations, BYOK proxy |

- **Web only.** No App Store or Play Store builds for now. Do not add `dart:io`-only code to apps or UI packages; everything must compile for web. Layouts use breakpoints from `realm_ui` (compact < 600, medium < 1024, expanded >= 1024 logical pixels).
- **Online only.** No local database, no sync queue. If the connection drops, show a clear offline banner and disable ordering until it returns.
- **One venue per instance.** One small business runs one copy. There is one `venue` row; other tables do not carry tenant columns. The BYOK AAD still binds that venue's id, as [Config & Secrets](CONFIG_AND_SECRETS.md) §3 requires. `HostingMode` stays `selfHosted` by default.

**Hosting**: one VPS (about 2 GB RAM is enough to start) running `compose.yaml` with three containers:

| Container | Role |
| :--- | :--- |
| `caddy` | Automatic HTTPS for the operator's domain; serves the guest web build at `/` and the staff build at `/staff/`; proxies `/api/` (REST and the `/api/v1/ws` WebSocket) to the server |
| `tavern_server` | AOT-compiled Dart server (`dart compile exe`), stateless |
| `postgres` | Postgres 16 with a named volume; a daily `pg_dump` to a backup volume |

Caddy must fall back to each app's `index.html` for unknown paths under its prefix (`/staff/*` for staff, everything else outside `/api/` for guest), so QR deep links such as `/t/<table-code>` and browser refresh work.

Everything runs on one origin, so apps use the same-origin fallback in `ClientEndpointConfig` and need no `config.json`. The operator supplies only a domain and the secrets in [Config & Secrets](CONFIG_AND_SECRETS.md) §3.

**Shared origin means shared browser storage.** Prefix every storage key with the app name (`tavern_staff.`, `tavern_guest.`). Staff session tokens live in an `HttpOnly`, `Secure`, `SameSite=Strict` cookie scoped to `Path=/api/` and set by the server, never in `localStorage`, so nothing the guest app runs can read them.

## 3. Backend: Relic with Typed Endpoints (D3, D5)

**Why Relic**: Relic 2.0.0 (2026-11-12) is a standalone, shelf-style server library from the Serverpod team with typed, RFC-compliant headers, a router, middleware, and WebSockets. It is only an HTTP layer, so it brings none of Serverpod's lock-in. Serve with **`relic_native`**, the Relic 2 adapter on a native HTTP server, which answers about five times the requests per second of the pure-Dart `relic_io` adapter in the Relic benchmarks. Both adapters run the same handlers, router, and middleware, so tests call handlers directly and never depend on the adapter. If the native adapter ever fails to build or run in the container, falling back is one call (`app.serve()` instead of `app.serveNative()`). Handlers stay thin, so changing server library later only touches `lib/src/http/`.

**Typed endpoints, defined once.** `realm_protocol` provides the `Endpoint` type; each endpoint is a constant in the app's protocol package (here `tavern_protocol`):

```dart
const placeOrder = Endpoint<PlaceOrderRequest, OrderDto>.post(
  '/api/v1/orders',
  request: PlaceOrderRequest.fromJson,
  response: OrderDto.fromJson,
);
```

- The server registers it with `api.handle(placeOrder, (ctx, req) => ordersService.place(ctx, req))`. The helper decodes, validates, checks auth, encodes, and maps errors.
- Apps call it with `api.call(placeOrder, req)` and get a typed `Result<OrderDto, ApiError>`.
- A changed DTO or path is a compile error on both sides. No agent writes URLs, JSON keys, or status codes by hand.
- Errors are one `ApiError` DTO with an `ApiErrorCode` enum. Expected failures never throw across the wire.

**Module layout** inside the server (`apps/tavern_server/lib/src/<module>/`):
- `endpoints/`: registers the module's endpoints and stays thin (auth check, then call a service).
- `services/`: logic, unit-testable with fake repositories.
- `repositories/`: plain SQL through `package:postgres`, mapping rows to DTOs.

Tavern modules: `bootstrap`, `auth` (Tier 4, built on `realm_auth`), `staff` (accounts and profiles), `venue`, `tables`, `menu`, `orders` (including bills), `live` (WebSocket, built on `realm_server_kit`), `payments` (Tier 4), `integrations` (including `posFiscal`), `ai`.

**Shared server building blocks** go in `realm_server_kit` (the `api.handle` endpoint helper, the migrator, config and secret-file loading, per-IP rate limiting, the WebSocket hub) and `realm_auth` (accounts, sessions, invites, the setup link, password hashing). Neither knows about any app's domain, so every app server can use them.

`GET /api/v1/bootstrap` keeps its existing path and `realm_core` contract. Provider webhooks get raw-body routes so signatures can be checked.

**Live updates (D8)**: staff clients open `/api/v1/ws` after sign-in; the session cookie (`Path=/api/`) rides on the upgrade request, and the server rejects any upgrade whose `Origin` is not the instance's own origin. After an order transaction commits, the `orders` service publishes a typed `LiveEvent` (envelope from `realm_protocol`, Tavern event types from `tavern_protocol`) to connected clients. Events are hints; after any reconnect the client refetches the current state, so a missed event can never leave the board wrong. Guests get status updates the same way, scoped to their own order: placing an order returns an unguessable order token (at least 128 random bits), and the guest app uses it both to read that order's status (in an `Authorization` header) and to open its WebSocket (sent as the first WS message). Never put the token in a URL, so it stays out of Caddy and server logs. The token grants nothing else.

**Public endpoints** (bootstrap, menu, place order, guest order status) are rate-limited per IP in the server, and place-order also validates prices and availability server-side; the client total is never trusted.

## 4. Packages and Dependency Direction (D10)

The table below is authoritative; the diagram only shows the layering.

```
apps/tavern_staff, apps/tavern_guest    (thin shells: routes, DI wiring)
        │
packages/tavern_<feature>               (screens + cubits + repositories for one feature)
        │
packages/tavern_protocol                (Tavern DTOs + endpoint constants, pure Dart)
        │
packages/realm_ui   packages/realm_client   packages/realm_l10n
        │                  │
        │           packages/realm_protocol (Endpoint, ApiError, Result, LiveEvent envelope)
        │                  │
packages/realm_core  ◄─────┘            (pure Dart, no Flutter, no IO)

apps/tavern_server ──► tavern_protocol, realm_server_kit, realm_auth, realm_vault, realm_core
packages/realm_vault                    (pure Dart crypto, Tier 4)
```

| Package | Contains | May depend on | Never |
| :--- | :--- | :--- | :--- |
| `realm_core` | Value types, validation, money as integer minor units, `ClientEndpointConfig`, `VenueBootstrap` | `meta` | Flutter, IO, HTTP |
| `realm_protocol` | `Endpoint` descriptor type, `ApiError`, `Result`, `LiveEvent` envelope, DTOs shared by every app | `realm_core`, `freezed_annotation`, `json_annotation` | Flutter, HTTP clients, `dart:io` |
| `realm_ui` | Theme from `VenueBranding`, breakpoints, design-system widgets | `realm_core`, `material_ui` | Network, business logic |
| `realm_l10n` | ARB files + `flutter gen-l10n` output | Flutter | Venue copy (comes from the server) |
| `realm_client` | HTTP + WebSocket client for `Endpoint`s, bootstrap fetch, session storage | `realm_core`, `realm_protocol` | Widgets |
| `<app>_protocol` (e.g. `tavern_protocol`) | That app's `freezed` DTOs, `Endpoint` constants, live event types | `realm_core`, `realm_protocol`, `freezed_annotation`, `json_annotation` | Flutter, HTTP clients, `dart:io`, another app's packages |
| `<app>_<feature>` (e.g. `tavern_menu`) | One feature: `lib/src/ui/`, `lib/src/cubit/`, `lib/src/repositories/` | `realm_*` client packages, its own `<app>_protocol` | Another feature package; another app's packages; `api.call` outside `repositories/` |
| `realm_server_kit` | Endpoint helper, migrator, config and secret loading, rate limiting, WebSocket hub | `realm_core`, `realm_protocol`, `relic`, `postgres` | Flutter, any app's packages |
| `realm_auth` | Accounts, sessions, invites, setup link, password hashing, with its own migrations | `realm_core`, `realm_protocol`, `realm_server_kit`, crypto lib | Flutter, any app's packages |
| `realm_vault` | AEAD envelope encryption, key ring, `keyHint` masking, all under `lib/src/crypto/` | `realm_core`, crypto lib | DB access, HTTP |
| `realm_a2ui` | Optional generative UI ([A2UI](A2UI.md)) | `realm_ui`, `a2ui_*` | Required by any core feature |

Every package also takes `realm_lints` as a dev dependency and references siblings by version constraint, as [Monorepo](MONOREPO.md) requires.

**Directory names are load-bearing**: `cubit/`, `repositories/`, `services/`, `crypto/`, `auth/`, and `migrations/` match the path globs in [Review Policy](REVIEW_POLICY.md), so the right tier applies automatically (`cubit/`, `repositories/`, `services/` are Tier 3; `crypto/`, `auth/`, `migrations/`, `payment*/` are Tier 4). Do not rename them.

Paths the globs miss still get an explicit floor: **everything under `apps/*_server/` and in `realm_server_kit` is at least Tier 3** (including `endpoints/`, where authorization is checked, `lib/src/http/`, `live/`, `integrations/`, and `ai/`; `integrations/` is Tier 4 because it decrypts BYOK keys), and **`compose.yaml` and the Caddyfile are Tier 4** (production deploy). The next Review Policy update should add these as globs.

Rules:
- **`realm_*` packages are app-neutral.** They never import an app's packages (`tavern_*`, `grimoire_*`), and never carry one app's domain words. An app's packages never import another app's.
- **Features never import each other.** Cross-feature navigation goes through typed routes owned by the app; shared data goes down into `realm_client`, `realm_protocol`, or `realm_core`.
- **Apps hold no business logic.** An app is routes, provider wiring, and `main.dart`.
- **Small packages**: split a feature package once it passes about 3,000 lines of non-generated code.
- **Enforce, don't trust**: extend `scripts/check_hygiene.py` to fail on a forbidden import edge (follow-up work, see §13).

## 5. Database and Migrations (D4)

**Postgres, with SQLite as the runner-up.** SQLite would make backups a file copy, but Postgres handles many guests ordering at once without write locking, gives proper types (`timestamptz`, `numeric`, `jsonb`), and is what the existing BYOK storage design targets. On a 2 GB VPS it costs nothing extra. Plain SQL keeps the database replaceable: no ORM or schema DSL ties the code to a library.

- **Queries**: `package:postgres` 3.x with named parameters only (`Sql.named('... WHERE id = @id')`), never string interpolation. All SQL lives in server `repositories/`.
- **Migrations**: `apps/<app>_server/migrations/NNNN_<slug>.sql` (here `apps/tavern_server/migrations/`); a shared server package such as `realm_auth` ships its own `migrations/` folder, which the app's migrator applies first and records under the package's name, one file per change, never edited after merge. The server applies pending files at startup, each in a transaction under a Postgres advisory lock, and records them in `schema_migrations`. A file whose first line is `-- realm:no-transaction` runs outside a transaction and may hold only one statement (for `CREATE INDEX CONCURRENTLY`). Migration files are Tier 4.
- **Deploys roll forward; every migration still needs a rollback plan** ([Review Policy](REVIEW_POLICY.md) requires reversible migrations). Make changes additive (expand, then contract): a destructive change (drop or rename a column) ships in two releases, first stop reading the column, then drop it, so the previous server version keeps working against the new schema. State in the PR how to roll back (previous release + untouched schema, or the latest `pg_dump` restore).
- **Schema check**: the server test run (§10) applies every migration to an empty database and compares the result with a committed `schema.sql` dump, so drift is caught deterministically.
- Money columns are `bigint` minor units plus an ISO 4217 currency code. Never floating point.

## 6. Shared DTOs (D5)

**One rule**: if it crosses the wire, it is defined once in `realm_protocol`. Agents never write a class twice.

- New DTOs are `@freezed` classes with `json_serializable`; enums use `@JsonEnum(alwaysCreate: true)`; unknown enum values fail decoding.
- `realm_core` keeps the existing hand-validated contracts (`ClientEndpointConfig`, `VenueBootstrap`, `VenueBranding`, `VenueCapabilities`, `IntegrationKeyStatus`). They are small, security-relevant, and already tested; `realm_protocol` reuses them rather than duplicating them.
- Input validation lives in `realm_core` functions, called by the Cubit (fast feedback) and the server endpoint (authority). The server is always the authority.
- Changing any shared DTO is at least Tier 3 ([Review Policy](REVIEW_POLICY.md) rule 1).

## 7. App State and Routing (D6, D7)

**State: `flutter_bloc` Cubits, not Riverpod.** Both work. Cubits win for agents because the pattern is small and explicit (call a method, emit a state), the API has barely changed between versions so agent output does not mix generations, and `bloc_test` gives fast deterministic tests. Riverpod 3 changed its API substantially from 2.x, which makes agent-written code more likely to use the wrong version. Do not mix the two.
- One Cubit per screen or flow, in `<app>_<feature>/lib/src/cubit/`. Use a `Bloc` only when you need event transforms such as debounce.
- States are sealed `freezed` unions (`initial | loading | ready | failure`). Never use nullable flags such as `isLoading` plus `error`.
- Cubits talk to repositories only. Repositories return typed results; they do not throw for expected failures.
- Dependency injection uses `RepositoryProvider`/`BlocProvider` wired in the app. No service locator.
- Risk to watch: `flutter_bloc` 9.1.1 (2025-05) is the latest release. That is stable, not abandoned, but recheck before 2027.

**Routing: `go_router` with `go_router_builder`.** Routes are generated typed classes (`const MenuRoute(tableId: 'x').go(context)`), so a renamed parameter is a compile error. Real URLs matter on web: guests arrive from a table QR code link, and browser back/forward and refresh must work. Each app owns its route tree; features expose screens, not routes. The Tavern staff app is built with `--base-href /staff/`.

## 8. BYOK Secrets and Bootstrap (D11)

Storage, precedence, rotation, and RBAC are already decided in [Config & Secrets](CONFIG_AND_SECRETS.md) §3. This section only places them:
- `packages/realm_vault` does encryption and key-ring logic as pure functions, with test vectors and AAD-swap tests. It has no DB or HTTP code, so a Tier 4 review covers one small package.
- The server `integrations` module stores `realm_vault` output in one `integration_credentials` table, resolves file → env → vault precedence, and is the only code that decrypts.
- The `ai` module proxies all LLM calls behind a provider-neutral `LlmProvider` interface. Clients never see keys, only `VenueCapabilities.aiAssistantEnabled`.
- `GET /api/v1/bootstrap` is computed per request from config plus which keys resolve. It is public and cacheable for a short time, and it never includes `IntegrationKeyStatus`.
- AEAD library: `package:cryptography` (AES-GCM and XChaCha20-Poly1305 in pure Dart). Its last release is about a year old, so the `security-auditor` agent re-checks it before `realm_vault` lands.

## 9. Branding and Theming

- Startup order: resolve `ClientEndpointConfig` → fetch bootstrap → build `RealmTheme` from `VenueBranding` → first real frame. Show a neutral, unbranded splash until the bootstrap arrives.
- Cache the last good bootstrap in browser storage and use it on the next load, then refresh in the background.
- UI strings come from `realm_l10n`. Venue-specific copy (name, tagline, menu text) comes only from the server.

## 10. Testing Strategy (D12)

Fast and deterministic first. `./scripts/check.sh` runs every layer that is configured.

| Layer | Where | Tool | Rule |
| :--- | :--- | :--- | :--- |
| Unit | `realm_core`, `realm_protocol`, `realm_vault`, server `services/` | `dart test` | No IO, no clock (inject `Clock`), no randomness without a seed |
| Cubit | `<app>_<feature>/test/cubit/` | `bloc_test` + fake repositories | One test per state transition, failure paths included |
| Widget | `realm_ui`, `<app>_<feature>/test/ui/` | `flutter_test` | Light + dark, `>= 2` `VenueBranding` seeds, compact and expanded widths |
| Server | `apps/<app>_server/test/`, `realm_server_kit/test/`, `realm_auth/test/` | `dart test` against a real Postgres | Fresh database per run, all migrations applied, schema check (§5) |
| E2E smoke | `apps/*/integration_test/` | `integration_test` on Chrome | A few critical flows only (guest places order, staff sees it) |

- Every widget and screen also meets the testability and a11y contract in [Testing](TESTING_AND_DEBUGGING.md) §2 (`ValueKey`, `Semantics`, guideline assertions); every new app follows the checklist in §5 there.
- Fakes over mocks: each repository has a hand-written `Fake<Name>Repository` next to the interface, so tests read like the real code.
- Server tests need Postgres: a service container in CI, and a local Postgres in agent sessions. Until that exists, keep logic in `services/` so the unit layer covers it.
- CI fails if `./scripts/gen.sh` changes any file (stale generated code).

## 11. Agent Conventions

**Per-package `CLAUDE.md`** (contains `@AGENTS.md`) plus an `AGENTS.md` of at most about 25 lines with these headings: *Purpose* (one line), *Allowed deps*, *Public API* (exported file), *Commands* (test, gen), *Invariants*, *Tier*. [`packages/realm_ui/AGENTS.md`](../packages/realm_ui/AGENTS.md) is the model.

**Golden paths** (the one way):
- *New feature*: create `packages/<app>_<feature>` with `lib/src/ui/`, `lib/src/cubit/`, `lib/src/repositories/`, and `AGENTS.md` → DTOs and `Endpoint`s in `<app>_protocol` → `./scripts/gen.sh` → server endpoint + service + repository → app repository + fake → Cubit + tests → screen with `ValueKey`/`Semantics` + widget test with a11y guidelines ([Testing](TESTING_AND_DEBUGGING.md) §2) → typed route in the app.
- *New endpoint*: DTOs + `Endpoint` constant in `<app>_protocol` → `./scripts/gen.sh` → `endpoints/` registration (thin) → `services/` logic + unit tests → `repositories/` SQL → server test.
- *Schema change*: new `migrations/NNNN_<slug>.sql` (additive) → update `schema.sql` → repository SQL → server test → rollback plan in the PR (Tier 4).
- *New BYOK provider*: add to `IntegrationProvider` → adapter in the server `integrations` module → capability flag computed in `bootstrap` → Tier 4 review.

**Never**: hand-edit generated files (`*.g.dart`, `*.freezed.dart`), add a second state or DI library, build SQL with string interpolation, call HTTP directly from a feature, or put a secret in a client package.

## 12. Tavern: Sign-In, Payments, Tables, Bills, Languages

Decided by the operator on 2026-11-22: staff and guest apps first, web only and responsive, no offline ordering, one venue per instance, one cheap VPS, Relic, Cubits. The items below are decided unless marked *Proposed*.

**Staff accounts** (`auth` and `staff` modules, Tier 4):
- The person who installs the server becomes the **admin**. On first start with no admin, the server prints a one-time setup link to its log; opening it creates the admin account. If the admin loses access, `tavern_server reset-admin` on the host prints a new link.
- **The admin creates worker accounts** (email + role). Creating one produces a one-time invite link, shown as a link and a QR code, valid for 24 hours. The worker opens it and sets up sign-in. No outgoing email is needed.
- **Accounts and profiles are separate tables.** `accounts` holds identity (email, role, credentials); `staff_profiles` holds display name and other non-auth details. Profile code never touches credentials.
- **Email + password for everyone** (decided 2026-11-22). It works the same on a shared venue tablet and on a worker's own phone. The invite link is where a worker sets their password. Passwords are hashed with Argon2id (`package:cryptography`, the same library as `realm_vault`; `security-auditor` sets the cost parameters), at least 12 and at most 128 characters (longer input is rejected before hashing), checked against a short built-in list of common passwords. Passkeys were considered and deferred: they suit personal phones but not a tablet shared across shifts. They can be added later as an extra method behind the same `auth` interface.
- **Shared tablet**: every staff screen shows who is signed in, and signing out is one tap. A shift change is sign-out, sign-in. Signing out ends the session on the server, not only in the browser. A forgotten sign-out is covered by an idle timeout (below), so the next shift's orders are not recorded under the previous worker.
- **One-time tokens** (setup link and invite links) follow one rule set: at least 128 random bits; stored only as a hash; carried in the URL fragment (`/staff/#/setup/<token>`), which browsers never send to Caddy or the server, and submitted in a POST body; valid once. The setup token expires after 1 hour and stops working as soon as any admin exists. Invite tokens expire after 24 hours, and issuing a new invite voids the previous one for that account.
- **Revocation**: re-inviting a worker (for example after a lost device) deletes that account's password and ends all its sessions. The admin can also disable an account outright, changing a role ends that account's sessions, and changing a password ends every other session of that account. `tavern_server reset-admin` does the same for every admin account.
- **Sessions**: random session ids, stored as hashes, issued fresh at every sign-in, in the `HttpOnly` cookie from §2. Workers: 12 hours absolute and 30 minutes idle (the admin can change the idle limit, 5 to 120 minutes), enforced server-side. Only user-initiated requests reset the idle timer; the live WebSocket and background refreshes do not. Admin actions need an elevated session: the admin re-enters their password, which is valid for 30 minutes of inactivity and 8 hours at most, and every admin endpoint checks it server-side.
- **Brute force**: sign-in attempts are rate-limited per account and per IP, with a temporary lockout after repeated failures that backs off and then expires on its own, so an attacker can delay but never permanently lock out a known account (`auth` sets the exact limits and documents them in its `AGENTS.md`). At most a few Argon2id hashes run at once; extra sign-ins wait in a short queue, so password hashing cannot exhaust a small VPS. The admin's way back in is `reset-admin`; a worker's is a new invite.

**Payments** (`payments` module, Tier 4):
- Guests can pay **online through Besteron** (a BYOK `payments` provider; the operator's own Besteron credentials, stored per [Config & Secrets](CONFIG_AND_SECRETS.md) §3), or **in person by card or cash**, which staff record on the order (`paymentMethod: online | card | cash`).
- The Besteron adapter sits behind a provider-neutral `PaymentProvider` interface. Its API details come from Besteron's documentation when the module is built.
- **Online payment is confirmed only by Besteron's server-to-server notification**, never by the browser redirect. The webhook route verifies the signature over the raw body, then checks that order id, amount (integer minor units), and currency match the server's own copy of the order. Notifications are deduplicated by Besteron's transaction id with a unique database constraint, so retries and out-of-order deliveries are harmless. A paid order can never go back to unpaid; refunds are separate records.
- **Card and cash** are recorded only by a signed-in staff account. Every payment record, online or in person, goes to an append-only `payment_events` table (who, when, method, amount). Staff cannot record an in-person payment over an already-confirmed online payment.
- **Fiscal receipts**: the operator expects Besteron to handle receipts for online payments. In-person card and cash payments are fiscalised through a **`posFiscal` provider** in the `integrations` module, behind a provider-neutral `PosFiscalProvider` interface. The first adapter is **eBlagajna** (a Slovenian cloud cash register that confirms receipts with FURS), configured with the operator's own credentials (BYOK, [Config & Secrets](CONFIG_AND_SECRETS.md) §3). Without a configured provider, Tavern only records the payment method. Its API details come from eBlagajna's documentation when the adapter is built.

**Bills**: orders from a table collect on that table's open bill (at most one open bill per table). Staff close a bill by recording how it was paid; a bill can be split into part payments (each recorded in `payment_events`), moved to another table (merging into the bill open there), and single orders can move between bills while they are open. Totals are always computed server-side in integer minor units.

**Tables**: every table has its own QR code linking to `/t/<table-code>`. The code is random (not the table number), so nobody can order to another table by guessing a URL; the admin can regenerate it and print new codes from the staff app.

**Languages**: English and Slovenian (`en`, `sl`) in `realm_l10n`; the guest app follows the browser language and has a switcher. Menu text the venue enters is stored per language (`{"en": ..., "sl": ...}`), with English as the fallback.

## 13. Follow-Up Work

1. Scaffold `packages/realm_protocol` with the `Endpoint` type, `ApiError`, `Result`, and `./scripts/gen.sh`, plus the CI generated-code drift check.
2. Scaffold `packages/realm_server_kit` (Relic endpoint helper, migrator, Postgres test harness).
3. Scaffold `apps/tavern_server` (bootstrap endpoint, schema check), `compose.yaml`, and the Caddyfile. Uncomment `- apps/*` in the root `pubspec.yaml`.
4. Add `realm_client`, then `tavern_protocol` and the first Tavern feature package (guest menu) following §11.
5. Add the import-direction check to `scripts/check_hygiene.py`, including the app-neutral rule for `realm_*` (§4).
6. Scaffold `realm_auth` and `realm_vault` (Tier 4, after a `security-auditor` dependency check).
