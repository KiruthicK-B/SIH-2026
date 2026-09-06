import re

from fastapi import Depends, FastAPI
from pydantic import BaseModel
from rapidfuzz import fuzz

from auth import require_auth
from canonical_schema import CANONICAL_FIELDS, KNOWN_SYNONYMS

app = FastAPI(title="OneDesk MDM Service")


@app.get("/health")
def health():
    return {"status": "ok", "service": "mdm-service"}


class SampleField(BaseModel):
    field: str
    sampleValue: str = ""


class SuggestMappingRequest(BaseModel):
    sourceSystem: str
    fields: list[SampleField]


class MappingSuggestion(BaseModel):
    sourceField: str
    sourceSystem: str
    suggestedTarget: str | None
    confidence: float
    rationale: str


def normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


CONFIDENT_THRESHOLD = 0.5


def suggest_for_field(source_field: str) -> tuple[str | None, float, str]:
    key = source_field.strip().lower()

    # Fast path: exact known synonym, seen across real department schema drift.
    if key in KNOWN_SYNONYMS:
        return KNOWN_SYNONYMS[key], 0.95, f"Known synonym mapping ('{source_field}' commonly maps to this field)"

    # Fallback: fuzzy string similarity against canonical field names, since a
    # citizen record adapter's field names won't always match a documented synonym.
    best_field = None
    best_score = 0.0
    normalized_source = normalize(source_field)
    for candidate in CANONICAL_FIELDS:
        score = fuzz.WRatio(normalized_source, normalize(candidate["field"])) / 100
        if score > best_score:
            best_score = score
            best_field = candidate["field"]

    if best_score < CONFIDENT_THRESHOLD:
        return None, best_score, "No confident match — needs manual mapping"

    return best_field, round(best_score, 2), f"Fuzzy string match against canonical schema (score {round(best_score * 100)})"


@app.post("/suggest-mapping", response_model=list[MappingSuggestion], dependencies=[Depends(require_auth)])
def suggest_mapping(req: SuggestMappingRequest):
    """
    Deterministic fast path for the AI-assisted schema-mapping feature (see
    DataStandardsTab.tsx): rapidfuzz + a known-synonym table, no external model call
    — always available, sub-second, and the platform's own "graceful degradation"
    principle applied to this feature itself (an LLM rationale layer could enrich
    this later without changing the response contract, but isn't required to work).
    """
    results = []
    for f in req.fields:
        target, confidence, rationale = suggest_for_field(f.field)
        results.append(
            MappingSuggestion(
                sourceField=f.field,
                sourceSystem=req.sourceSystem,
                suggestedTarget=target,
                confidence=confidence,
                rationale=rationale,
            )
        )
    return results


@app.get("/canonical-fields", dependencies=[Depends(require_auth)])
def canonical_fields():
    return CANONICAL_FIELDS
