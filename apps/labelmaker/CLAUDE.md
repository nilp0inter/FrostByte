# LabelMaker App — CLAUDE.md

LabelMaker is a **general-purpose label canvas editor** using **CQRS + Event Sourcing**. All writes go through an append-only event table; projection tables are rebuilt from events.

Currently v1: a live SVG canvas editor with auto-sizing text. No persistence or printing yet.

## Three-Schema Architecture

```
labelmaker_data   — Persistent storage: event store (append-only)
labelmaker_logic  — Business logic: projection tables, event handlers, replay, helpers
labelmaker_api    — External interface: read views + RPC write functions (exposed via PostgREST)
```

- `labelmaker_data` schema is created once via migration and never dropped
- `labelmaker_logic` and `labelmaker_api` schemas are idempotent (DROP + CREATE) and can be redeployed without data loss
- All writes INSERT into `labelmaker_data.event`; a trigger calls `labelmaker_logic.apply_event()` to update projections
- `labelmaker_logic.replay_all_events()` truncates all projections and rebuilds from the event store

## Key Database Objects

**Data schema (persistent — `labelmaker_data`):**
- **`labelmaker_data.event`**: Append-only event store (id BIGSERIAL, type TEXT, payload JSONB, created_at TIMESTAMPTZ)

**Logic schema (idempotent — `labelmaker_logic`):**
- **`labelmaker_logic.apply_event()`**: CASE dispatcher (currently empty — no event types yet)
- **`labelmaker_logic.replay_all_events()`**: Truncates projections and rebuilds from events

**API schema (idempotent — `labelmaker_api`):**
- **`labelmaker_api.event`**: View exposing the event store

## Database File Structure

```
apps/labelmaker/database/
├── migrations/001-initial.sql    # Data schema (event table, indexes, extensions)
├── logic.sql                     # Logic schema (event handlers, replay) — idempotent
├── api.sql                       # API schema (views, RPC functions) — idempotent
├── seed.sql                      # Seed data as events (empty)
├── migrate.sh                    # Auto-migration (runs in labelmaker_db_migrator container)
└── deploy.sh                     # Manual redeploy from host (uses docker exec)
```

### Deploying Schema Changes

Schema changes are **auto-applied on every `docker compose up`** by the `labelmaker_db_migrator` one-shot container. For manual redeploy:

```bash
./apps/labelmaker/database/deploy.sh
```

**Note:** After manual `deploy.sh`, restart PostgREST to refresh its schema cache: `docker restart kitchen_postgrest`

## Elm Client Structure

SPA using `Browser.application` with a label canvas editor:

```
apps/labelmaker/client/src/
├── Main.elm              # Entry point, routing, port subscriptions, OutMsg handling
├── Route.elm             # Route type: Home | NotFound
├── Types.elm             # Shared types (RemoteData, Notification)
├── Ports.elm             # Port module: text measurement (requestTextMeasure/receiveTextMeasureResult)
├── Api.elm               # HTTP functions (placeholder)
├── Api/
│   ├── Decoders.elm      # JSON decoders (placeholder)
│   └── Encoders.elm      # JSON encoders (placeholder)
├── Components.elm        # Header, notification, loading
├── Data/
│   └── LabelTypes.elm    # Brother QL label specs (25 types, copied from FrostByte)
├── main.js               # Elm init + text measurement JS handler (Canvas API)
└── Page/
    ├── Home.elm          # Facade: Model, Msg, OutMsg, init, update, view
    ├── Home/
    │   ├── Types.elm     # Designer model, msgs, OutMsg, requestMeasurement helper
    │   └── View.elm      # Two-column layout: SVG preview + editor controls
    ├── NotFound.elm      # Facade
    └── NotFound/
        └── View.elm      # 404 page
```

**Architecture pattern:** Same as FrostByte — each page exposes Model, Msg, OutMsg, init, update, view. Pages communicate up via OutMsg. Home page `init` returns a 3-tuple `(Model, Cmd Msg, OutMsg)` to trigger initial text measurement.

**Routes:** `/` (Home — label designer)

**Styling:** Tailwind CSS with custom "label" color palette (warm brown tones)

**Served on:** Port `:8080` via Caddy

## Label Canvas Editor (Home Page)

The Home page is a live label canvas editor with auto-sizing text.

### Model

- `labelTypeId` — Selected Brother QL label type (default: `"62"` = 62mm endless)
- `labelWidth`, `labelHeight` — Label dimensions in pixels (from `Data.LabelTypes`)
- `cornerRadius` — For round labels (width/2), 0 otherwise
- `rotate` — `True` for die-cut rectangular labels (display swapped for landscape)
- `variableName` — Template variable name (default: `"nombre"`)
- `sampleValue` — Sample text shown on canvas (default: `"Pollo con arroz"`)
- `fontFamily` — Font used for rendering (default: `"Atkinson Hyperlegible"`)
- `maxFontSize`, `minFontSize` — Font size range for auto-sizing (default: 48/16)
- `padding` — Inner padding in pixels (default: 20)
- `computedText` — `Maybe ComputedText` with `fittedFontSize` and `lines` (from JS measurement)

### Text Fitting Flow

1. Any layout-affecting change (label type, sample value, font size, padding) emits `RequestTextMeasure` via OutMsg
2. `Main.elm` sends the request through `Ports.requestTextMeasure`
3. JavaScript (`main.js`) uses Canvas API `measureText()` to shrink font from max to min until text fits width
4. If text still doesn't fit at min size, it word-wraps into multiple lines
5. Result sent back via `Ports.receiveTextMeasureResult` → `Main.elm` → `GotTextMeasureResult` msg
6. SVG preview re-renders with computed font size and wrapped lines

### View Layout

**Left column — SVG preview:**
- White rectangle at label dimensions (swapped if `rotate=True`)
- Bold text centered vertically and horizontally
- Scaled to fit max 500px width
- Dimension info below

**Right column — Editor controls:**
- Label type dropdown (25 Brother QL types)
- Width (read-only) + height (editable for endless labels)
- Variable name input (with `{{` `}}` decorators)
- Sample value input
- Max/min font size inputs
- Padding input

### Label Type Selection Logic

When a label type is selected:
- **Endless labels**: height = silver ratio (width * 2.414), cornerRadius = 0, rotate = false
- **Die-cut rectangular**: height from spec, cornerRadius = 0, rotate = true (landscape display)
- **Round die-cut**: height = width, cornerRadius = width/2, rotate = false

## Working with Ports

Ports are defined in `Ports.elm` and handled in `main.js`:

```elm
-- Request text measurement
port requestTextMeasure : TextMeasureRequest -> Cmd msg
-- Receive measurement result
port receiveTextMeasureResult : (TextMeasureResult -> msg) -> Sub msg
```

**TextMeasureRequest fields:** `requestId`, `text`, `fontFamily`, `maxFontSize`, `minFontSize`, `maxWidth`

**TextMeasureResult fields:** `requestId`, `fittedFontSize`, `lines` (List String)

`Main.elm` subscribes to `receiveTextMeasureResult` and forwards results to the active page. The `RequestTextMeasure` OutMsg from the Home page triggers the port command.

## Installing Elm Packages

**IMPORTANT:** Do not manually edit `apps/labelmaker/client/elm.json` to add dependencies. Elm requires proper dependency resolution which only `elm install` can perform correctly.

```bash
cd apps/labelmaker/client
docker run --rm -v "$(pwd)":/app -w /app node:20-alpine sh -c "npm install -g elm && echo y | elm install <package-name>"
```

To verify compilation:

```bash
docker run --rm -v "$(pwd)":/app -w /app node:20-alpine sh -c "npm install -g elm && elm make src/Main.elm --output=/dev/null"
```

## API Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/db/event` | GET | Event store |
| `/api/printer/print` | POST | Print PNG label |
| `/api/printer/health` | GET | Printer service health check |

## Adding a New Page

Same pattern as FrostByte:

1. Create `Page/NewPage.elm` (facade) + `Page/NewPage/Types.elm` + `Page/NewPage/View.elm`
2. Add route in `Route.elm`
3. Wire up in `Main.elm` (Page type, Msg type, initPage, update, viewPage)
4. Add nav link in `Components.elm`
