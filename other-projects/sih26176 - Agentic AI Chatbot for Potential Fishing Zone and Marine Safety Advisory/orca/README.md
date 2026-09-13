# ORCA — Marine Intelligence Platform (Frontend POC)

Agentic AI conversational platform for marine intelligence — SIH 2026, PS 26176.

## What this is

A **frontend-only, UI-ready proof of concept** of ORCA: a chat-first assistant that answers questions about
potential fishing zones (PFZ), marine safety, and hazard alerts along the Indian coast, backed by a modular
multi-agent pipeline and a live map. All oceanographic, weather, and boundary data is **simulated** with a
deterministic, seeded generator — there are no external API calls, so the demo runs fully offline.

**This is a decision-support UX demo, not a real PFZ/weather service.** Do not use it for actual fishing or
navigation decisions.

## Agent architecture

Nine agent modules live under `src/agents/`, wired together by `src/agents/orcaPipeline.ts` on every chat turn:

1. **PlannerAgent** — parses intent (PFZ+safety, hazard query, chlorophyll/SST exploration, or a follow-up),
   resolves location/date from the message and prior conversation context, and asks for clarification when
   the location is unknown.
2. **MarineDataAgent** — simulated SST, chlorophyll-a, and PFZ advisory grid.
3. **OceanAnalyticsAgent** — derives PFZ likelihood from chlorophyll + SST-gradient proxy.
4. **WeatherAgent** — simulated wave height, wind, lightning risk, cyclone alerts, and tides.
5. **GeospatialAgent** — Haversine distance, nearest-PFZ search, safer-alternative search, and
   point-in-polygon geofencing against maritime boundaries.
6. **RiskAgent** — composes wave/wind/lightning/cyclone/boundary risk into a 0–100 safety score and category.
7. **ExplanationAgent** — builds the step-by-step reasoning trail shown in the "Show reasoning" panel.
8. **VisualizationAgent** — decides which map layers, alert badges, and result panels to surface.
9. **ChatAgent** — manages multi-turn conversation state as pure, immutable session transitions.

The pipeline logic has no DOM dependency, so it can be (and was) verified headlessly with `tsx` outside the
browser — see "Verified flows" below.

## Conversation flows implemented

- **PFZ + safety** — "Where is the nearest PFZ today from Chennai? Is it safe tomorrow morning?", with
  follow-ups: "What about the day after?", "Show a safer nearby zone.", "Why is this zone risky?"
- **Hazard query** — "Are there any lightning or cyclone alerts near Visakhapatnam today?"
- **Chlorophyll/SST exploration** — "Which regions show high chlorophyll and favorable SST today?"
- **Location clarification** — if no port/city is mentioned and none is in context, ORCA asks before
  computing anything.

## Pages

- **Dashboard** (`/`) — stat cards, PFZ map preview, inline chat, weather/tides, active alerts, data-layer
  toggles, quick actions — mirrors the reference mockup.
- **Chat with ORCA** (`/chat`) — full-page conversation.
- **Marine Map** (`/marine-map`) — full map with independent layer toggles (PFZ / waves / lightning /
  boundaries), synced to the most recent chat result when available.
- **Alerts** (`/alerts`) — hazard alerts from the current conversation plus a snapshot across all ports.
- **PFZ Finder** (`/pfz-finder`) — pick a port and day, see the nearest zone and top candidates.
- **Weather & Ocean** (`/weather`), **Tides** (`/tides`), **Routes & Navigation** (`/routes`),
  **Boundaries** (`/boundaries`) — dedicated views over the same agent data.
- **Reports** (`/reports`) — session-only observation submission form.
- **Settings** (`/settings`), **About** (`/about`).

## Tech stack

React 19 · TypeScript · Vite · Tailwind CSS v4 · React Router 7 · react-leaflet / Leaflet (dark CARTO basemap)
· lucide-react. State is Context API (`OrcaChatProvider`) wrapping a `useOrcaChat` hook.

## Running locally

```bash
npm install
npm run dev
```

```bash
npm run build   # production build
```

## Known simplification

Map tiles are fetched from the public CARTO dark basemap over the network at runtime (`{s}.basemaps.cartocdn.com`)
— everything else (PFZ grid, weather, boundaries, chat logic) is generated locally with no network calls.
