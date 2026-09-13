# RetinaXAI — Frontend POC

Explainable AI-based diabetic retinopathy (DR) screening platform for rural/telemedicine deployment — SIH 2026, PS 26038.

> **Detect. Explain. Assist.**

## What this is

This is a **frontend-only interactive prototype** of the full RetinaXAI platform described in the project
specification. It demonstrates the complete clinician and operator workflow — image upload, quality
assessment, AI analysis, DR grading, lesion/vessel/Grad-CAM explainability, clinical evidence fusion, and
telemedicine workflow simulation — using a deterministic, in-browser mock AI pipeline instead of the real
MATLAB (U-Net / ResNet-50 / Grad-CAM) backend described in the spec.

**No real fundus images are diagnosed.** Uploading an image runs lightweight, genuinely-computed image
quality checks (focus, illumination, field of view, contrast via canvas pixel analysis) and then a
seeded pseudo-random generator — keyed off the image's own pixel content — produces a clinically plausible,
internally consistent DR grade, lesion counts, vessel metrics, anatomical landmarks, and Grad-CAM-style
heatmap. The same image always reproduces the same result. **This is a UX/workflow demo, not a diagnostic
tool**, and it must never be used on real patient images for real clinical decisions.

## Full spec vs. this prototype

| Layer | Full spec | This prototype |
|---|---|---|
| Frontend | React.js, HTML, CSS, JS | ✅ Implemented — React 19 + TypeScript + Vite + Tailwind CSS |
| Backend | Python + Flask REST API | Not implemented — all logic runs client-side |
| AI Engine | MATLAB (U-Net, ResNet-50, Grad-CAM) | Simulated with a deterministic, seeded mock pipeline (`src/lib/imageAnalysis.ts`) |
| Database | MySQL / PostgreSQL | Not implemented — screenings persist only in memory for the session |
| Simulation | Simulink telemedicine model | Reimplemented as an interactive in-app queueing model (`src/pages/operator/SimulinkSimulation.tsx`) |

## Screens implemented

**Patient / Clinician flow:** Splash/Welcome → Login → Dashboard → Upload Image → Image Quality Assessment →
AI Analysis Progress → Screening Result Summary.

**Clinician detailed views:** Lesion Overlay, Vessel Segmentation, Optic Disc & Fovea Localization, Grad-CAM
Interpretation, Full Screening Report (print/PDF export + share).

**Operator / admin flow:** Operator Dashboard (throughput, pending review, activity chart), Workflow
Simulation (interactive patient-load / AI-capacity / ophthalmologist-capacity model).

Plus supporting list views: Screenings, Patients, Reports, Profile.

## Running locally

```bash
npm install
npm run dev
```

```bash
npm run build   # production build
```

## Clinical safety

RetinaXAI (both the full spec and this prototype) is designed as a **screening and clinical
decision-support aid**, not an autonomous diagnostic system. Every screening result view carries a
persistent disclaimer, and referable cases are explicitly routed to an "Ophthalmologist Review" state.
Final diagnosis and treatment decisions remain with a qualified ophthalmologist.
