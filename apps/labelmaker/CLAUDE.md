# LabelMaker App — CLAUDE.md

LabelMaker is a **general-purpose label canvas editor** using **CQRS + Event Sourcing**. All writes go through an append-only event table; projection tables are rebuilt from events.

Currently v1: a live SVG canvas editor with composable label objects and auto-sizing text. No persistence or printing yet.

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

SPA using `Browser.application` with a composable label object editor:

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
│   ├── LabelObject.elm   # Label object types, tree operations, constructors
│   └── LabelTypes.elm    # Brother QL label specs (25 types, copied from FrostByte)
├── main.js               # Elm init + text measurement JS handler (Canvas API)
└── Page/
    ├── Home.elm          # Facade: Model, Msg, OutMsg, init, update, view
    ├── Home/
    │   ├── Types.elm     # Designer model, msgs, OutMsg, measurement collection
    │   └── View.elm      # Two-column layout: SVG preview + editor controls
    ├── NotFound.elm      # Facade
    └── NotFound/
        └── View.elm      # 404 page
```

**Architecture pattern:** Same as FrostByte — each page exposes Model, Msg, OutMsg, init, update, view. Pages communicate up via OutMsg. Home page `init` returns a 3-tuple `(Model, Cmd Msg, OutMsg)` to trigger initial text measurements.

**Routes:** `/` (Home — label designer)

**Styling:** Tailwind CSS with custom "label" color palette (warm brown tones)

**Served on:** Port `:8080` via Caddy

## Composable Label Object System

Labels are built from a tree of composable objects defined in `Data/LabelObject.elm`:

```elm
type LabelObject
    = Container { id, x, y, width, height, content : List LabelObject }
    | TextObj { id, content, properties : TextProperties }
    | VariableObj { id, name, properties : TextProperties }
    | ImageObj { id, url }
    | ShapeObj { id, properties : ShapeProperties }
```

**Design principles:**
- Objects fill their parent container (no explicit dimensions on non-Container objects)
- Positioning is only done via Container (wrap an object in a Container with x, y, width, height)
- Multiple objects at the same level overlap (z-ordered by list position)
- Shapes fill the container: Rectangle = full area, Circle = inscribed, Line = diagonal
- Each object has an `id : ObjectId` for selection, measurement tracking, and future persistence

**Supporting types:**
- `Color { r, g, b, a }` — RGBA color
- `TextProperties { fontSize, fontFamily, color }` — `fontSize` is the max for auto-fit (min derived as `max 6 (fontSize / 3)`)
- `ShapeProperties { shapeType, color }` — `ShapeType` is `Rectangle | Circle | Line`

**Tree operations:** `findObject`, `updateObjectInTree`, `removeObjectFromTree`, `addObjectTo`, `allTextObjectIds`

**Constructors:** `newText`, `newVariable`, `newContainer`, `newShape`, `newImage` — all take a `nextId : Int` parameter

## Label Canvas Editor (Home Page)

The Home page is a live label canvas editor with composable objects and auto-sizing text.

### Model

- `labelTypeId` — Selected Brother QL label type (default: `"62"` = 62mm endless)
- `labelWidth`, `labelHeight` — Label dimensions in pixels (from `Data.LabelTypes`)
- `cornerRadius` — For round labels (width/2), 0 otherwise
- `rotate` — `True` for die-cut rectangular labels (display swapped for landscape)
- `content : List LabelObject` — Object tree (default: one `VariableObj "nombre"`)
- `selectedObjectId : Maybe ObjectId` — Currently selected object for property editing
- `sampleValues : Dict String String` — Variable name to sample value mapping for preview
- `computedTexts : Dict ObjectId ComputedText` — Per-object auto-fit results (fittedFontSize + lines)
- `nextId : Int` — Auto-incrementing ID counter for new objects
- `padding : Int` — Inner padding in pixels (default: 20)

### Text Fitting Flow

1. Any layout-affecting change (label type, object properties, sample values, padding) emits `RequestTextMeasures` via OutMsg with a batch of requests
2. `Main.elm` sends all requests through `Ports.requestTextMeasure` via `Cmd.batch`
3. `collectMeasurements` in Types.elm walks the object tree, threading container bounds, emitting one request per text/variable object
4. JavaScript (`main.js`) uses Canvas API `measureText()` to shrink font from max to min until text fits width, then checks `maxHeight` for vertical fitting
5. Results sent back via `Ports.receiveTextMeasureResult` → `Main.elm` → `GotTextMeasureResult` msg
6. Each result is stored in `computedTexts` dict keyed by object ID
7. SVG preview re-renders with computed font sizes and wrapped lines

### View Layout

**Left column — SVG preview:**
- White rectangle at label dimensions (swapped if `rotate=True`)
- Recursive rendering of object tree (`renderObject`)
- Click objects on canvas to select them (dashed blue border overlay)
- Click background to deselect
- Scaled to fit max 500px width
- Dimension info below

**Right column — Editor controls (scrollable):**
1. **Label settings** (top): label type dropdown, dimensions, padding
2. **Object tree** (middle): hierarchical list with type icons, click-to-select, delete buttons, indented container children
3. **Add toolbar**: buttons to add Text, Variable, Container, Rectangle, Circle, Line, Image (appends to root or inside selected container)
4. **Property editor** (bottom): context-sensitive controls for selected object:
   - Container: x, y, width, height
   - TextObj: content, font family, font size, RGB color
   - VariableObj: variable name, sample value, font family, font size, RGB color
   - ShapeObj: shape type dropdown, RGB color
   - ImageObj: URL input

### Messages

- `SelectObject (Maybe ObjectId)` — Select/deselect an object
- `AddObject LabelObject` — Add object to root or inside selected container
- `RemoveObject ObjectId` — Remove object from tree
- `UpdateObjectProperty ObjectId PropertyChange` — Apply a property change to an object
- `UpdateSampleValue String String` — Set sample value for a variable name
- `LabelTypeChanged`, `HeightChanged`, `PaddingChanged` — Label-level settings
- `GotTextMeasureResult` — Receive measurement result from JS

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

**TextMeasureRequest fields:** `requestId`, `text`, `fontFamily`, `maxFontSize`, `minFontSize`, `maxWidth`, `maxHeight`

**TextMeasureResult fields:** `requestId`, `fittedFontSize`, `lines` (List String)

`Main.elm` subscribes to `receiveTextMeasureResult` and forwards results to the active page. The `RequestTextMeasures` OutMsg from the Home page triggers a batch of port commands (one per text/variable object).

The JS handler in `main.js` performs two-pass fitting: first shrinks font to fit `maxWidth`, then if `maxHeight > 0`, further shrinks to fit wrapped lines within the vertical constraint.

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
