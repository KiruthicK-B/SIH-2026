import { AppShell } from '@/components/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'

export default function About() {
  return (
    <AppShell>
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-white">About ORCA</h1>
        <p className="mb-4 text-xs text-slate-400">Marine Intelligence Platform — SIH 2026, PS 26176</p>

        <Card>
          <CardContent className="space-y-4 text-sm leading-relaxed text-slate-300">
            <p>
              <strong className="text-white">ORCA</strong> is an agentic AI conversational platform for marine
              intelligence, built to help fishers and coastal operators quickly answer three questions: where the
              fish likely are, whether it's safe to go, and what hazards to watch for.
            </p>
            <p>
              Under the hood, a natural-language query is routed through a small pipeline of specialized agents —
              a planner that reads intent and location, data agents that simulate satellite-derived sea-surface
              temperature and chlorophyll-a, a weather agent for wave/wind/lightning/cyclone conditions, a
              geospatial agent for distance and boundary checks, a risk agent that composes everything into a
              single safety score, and an explanation agent that narrates the reasoning behind the answer.
            </p>
            <p>
              This build is a <strong className="text-white">frontend-only proof of concept</strong>: every dataset
              is simulated in the browser with a deterministic seeded generator, so results are stable and
              internally consistent without depending on any external service.
            </p>
          </CardContent>
        </Card>

        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Agent Pipeline</CardTitle>
          </CardHeader>
          <CardContent>
            <ol className="list-decimal space-y-1.5 pl-4 text-xs text-slate-300">
              <li>PlannerAgent — intent, location, date</li>
              <li>MarineDataAgent — SST, chlorophyll, PFZ grid</li>
              <li>OceanAnalyticsAgent — PFZ likelihood</li>
              <li>WeatherAgent — wave, wind, lightning, cyclone</li>
              <li>GeospatialAgent — distance, nearest PFZ, geofencing</li>
              <li>RiskAgent — composite safety score</li>
              <li>ExplanationAgent — reasoning trail</li>
              <li>VisualizationAgent — map layers, alerts, panels</li>
              <li>ChatAgent — conversation state</li>
            </ol>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
