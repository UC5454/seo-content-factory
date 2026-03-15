#!/bin/bash
# ============================================================
# SEO Content Factory - Orchestrator (iTerm2 Visual Mode)
# ============================================================
#
# Full pipeline: KW input → SEO-optimized article + thumbnail + review
#
# Phase 0: SEO Analyst  (SEO/AIO analysis → brief + outline)
# Phase 1: Researcher   (SEO-focused research)
# Phase 2: Writer       (SEO-optimized article)
# Phase 3a: Designer    (thumbnail)           ┐
# Phase 3b: QA          (quality review)      ├ parallel
# Phase 3c: SEO Analyst (SEO/AIO scoring)     ┘
# Phase 4: Publisher    (Drive storage)
#
# Usage:
#   ./start-seo-factory.sh "target keyword" ["user memo"]
#
# Example:
#   ./start-seo-factory.sh "Gemini Code Assist"
#   ./start-seo-factory.sh "Claude Code tutorial" "CTA to https://example.com/contact"
# ============================================================

set -euo pipefail

# --- Configuration ---
# Override these via config.yaml or environment variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if exists
if [ -f "${PROJECT_DIR}/.env" ]; then
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# Load config or use defaults
# In production, these should come from config.yaml
# For now, set them as environment variables or override below
BASE_DIR="${SEO_FACTORY_BASE_DIR:-$PROJECT_DIR}"

SEO_ANALYST_DIR="${SEO_FACTORY_SEO_ANALYST_DIR:-${BASE_DIR}/example-team/seo-analyst}"
RESEARCHER_DIR="${SEO_FACTORY_RESEARCHER_DIR:-${BASE_DIR}/example-team/researcher}"
WRITER_DIR="${SEO_FACTORY_WRITER_DIR:-${BASE_DIR}/example-team/writer}"
DESIGNER_DIR="${SEO_FACTORY_DESIGNER_DIR:-${BASE_DIR}/example-team/designer}"
QA_DIR="${SEO_FACTORY_QA_DIR:-${BASE_DIR}/example-team/qa}"
PUBLISHER_DIR="${SEO_FACTORY_PUBLISHER_DIR:-${BASE_DIR}/example-team/publisher}"
PUBLISHER_INBOX="${SEO_FACTORY_PUBLISHER_INBOX:-${PUBLISHER_DIR}/INBOX.md}"

ITERM_PROFILE_SEO="${SEO_FACTORY_ITERM_SEO:-Default}"
ITERM_PROFILE_RESEARCHER="${SEO_FACTORY_ITERM_RESEARCHER:-Default}"
ITERM_PROFILE_WRITER="${SEO_FACTORY_ITERM_WRITER:-Default}"
ITERM_PROFILE_DESIGNER="${SEO_FACTORY_ITERM_DESIGNER:-Default}"
ITERM_PROFILE_QA="${SEO_FACTORY_ITERM_QA:-Default}"
ITERM_PROFILE_PUBLISHER="${SEO_FACTORY_ITERM_PUBLISHER:-Default}"

COMPANY_NAME="${SEO_FACTORY_COMPANY:-Your Company}"
CONTACT_URL="${SEO_FACTORY_CONTACT_URL:-https://example.com/contact}"

# Timeouts (seconds)
TIMEOUT_P0="${SEO_FACTORY_TIMEOUT_P0:-1200}"
TIMEOUT_P1="${SEO_FACTORY_TIMEOUT_P1:-900}"
TIMEOUT_P2="${SEO_FACTORY_TIMEOUT_P2:-1200}"
TIMEOUT_P3="${SEO_FACTORY_TIMEOUT_P3:-900}"
TIMEOUT_P3C="${SEO_FACTORY_TIMEOUT_P3C:-1200}"
TIMEOUT_P4="${SEO_FACTORY_TIMEOUT_P4:-600}"

# Google Drive folder ID for article storage
DRIVE_FOLDER_ID="${SEO_FACTORY_DRIVE_FOLDER_ID:-}"

# --- Input Sanitization ---
RAW_KW="$1"
KW=$(echo "$RAW_KW" | sed "s/['\`\$;|&]//g")
USER_MEMO="${2:-}"
if [ -n "$USER_MEMO" ]; then
    USER_MEMO=$(echo "$USER_MEMO" | sed "s/['\`\$;|&]//g")
fi

if [ -z "${KW}" ]; then
    echo "Error: Please specify a target keyword"
    echo "Usage: ./start-seo-factory.sh \"target keyword\" [\"user memo\"]"
    exit 1
fi

# --- Claude CLI Resolution ---
source "${SCRIPT_DIR}/resolve-claude.sh"
CLAUDE="$CLAUDE_CMD"

# --- Setup ---
TMP_DIR="${TMPDIR:-/tmp}/seo-factory-$$"
TODAY=$(date '+%Y-%m-%d')
START_TIME=$(date '+%H:%M:%S')
LOG_FILE="${SCRIPT_DIR}/seo-factory-log-$(date '+%Y%m%d-%H%M%S').log"

mkdir -p "${TMP_DIR}"

# Ensure output directories exist
for d in "$SEO_ANALYST_DIR" "$RESEARCHER_DIR" "$WRITER_DIR" "$DESIGNER_DIR" "$QA_DIR" "$PUBLISHER_DIR"; do
    mkdir -p "${d}/outputs" "${d}/daily-logs" 2>/dev/null || true
done

log() {
    local msg="[$(date '+%H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "${LOG_FILE}"
}

# --- Phase Runner Script ---
cat > "${TMP_DIR}/run-phase.sh" << 'RUNNER'
#!/bin/bash
EMPLOYEE_DIR="$1"
PROMPT_FILE="$2"
SENTINEL="$3"
CLAUDE=""
for _c in "/opt/homebrew/bin/claude" "/usr/local/bin/claude"; do
    [ -x "$_c" ] && CLAUDE="$_c" && break
done
[ -z "$CLAUDE" ] && CLAUDE=$(which claude 2>/dev/null || echo "/opt/homebrew/bin/claude")

cd "$EMPLOYEE_DIR"

OUTPUT_CHECK="$4"
if [ -n "$OUTPUT_CHECK" ] && [ -f "$OUTPUT_CHECK" ]; then
    mv "$OUTPUT_CHECK" "${OUTPUT_CHECK}.bak-$(date '+%Y%m%d%H%M%S')"
fi

PROMPT=$(cat "$PROMPT_FILE")
$CLAUDE "$PROMPT" --permission-mode bypassPermissions

touch "$SENTINEL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RUNNER
chmod +x "${TMP_DIR}/run-phase.sh"

# --- iTerm2 Window Launcher ---
open_iterm_phase() {
    local profile_name="$1"
    local employee_dir="$2"
    local prompt_file="$3"
    local sentinel="$4"
    local output_file="${5:-}"

    osascript << APPLESCRIPT
tell application "iTerm2"
    activate
    create window with profile "$profile_name"
    delay 0.5
    tell current session of current window
        write text "bash '${TMP_DIR}/run-phase.sh' '${employee_dir}' '${prompt_file}' '${sentinel}' '${output_file}'"
    end tell
end tell
APPLESCRIPT
}

wait_for_sentinel() {
    local sentinel="$1"
    local phase_name="$2"
    local timeout="${3:-900}"
    local elapsed=0

    while [ ! -f "$sentinel" ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ $elapsed -ge $timeout ]; then
            log "Timeout: ${phase_name} did not complete within ${timeout}s"
            return 1
        fi
    done
    rm -f "$sentinel"
    return 0
}

# ============================================================
# Main Pipeline
# ============================================================

echo "==================================================="
echo "  SEO Content Factory"
echo "==================================================="
echo "  Target KW: ${KW}"
echo "  Memo:      ${USER_MEMO:-none}"
echo "  Started:   ${TODAY} ${START_TIME}"
echo "  Log:       ${LOG_FILE}"
echo "==================================================="
echo ""

log "SEO Factory started: KW '${KW}'"

# --- Phase 0: SEO Analyst (SEO/AIO Analysis) ---

MEMO_SECTION=""
if [ -n "$USER_MEMO" ]; then
    MEMO_SECTION="
User Memo: ${USER_MEMO}
Reflect this memo in both the brief and the outline."
fi

cat > "${TMP_DIR}/p0-prompt.txt" << PROMPT
Read skills/seo-content-brief.md and execute the SEO brief creation workflow.

Target Keyword: ${KW}
Company: ${COMPANY_NAME}
Contact URL: ${CONTACT_URL}
${MEMO_SECTION}

Save output to: outputs/seo-brief.md
Write Phase 0 completion notice to: ${RESEARCHER_DIR}/INBOX.md
Record in daily-logs.
PROMPT

log "Phase 0: SEO Analyst (SEO/AIO Analysis)"
open_iterm_phase "${ITERM_PROFILE_SEO}" "${SEO_ANALYST_DIR}" "${TMP_DIR}/p0-prompt.txt" "${TMP_DIR}/p0-done" "${SEO_ANALYST_DIR}/outputs/seo-brief.md"

wait_for_sentinel "${TMP_DIR}/p0-done" "Phase 0" "$TIMEOUT_P0"
log "Phase 0 complete"

if [ ! -f "${SEO_ANALYST_DIR}/outputs/seo-brief.md" ]; then
    log "FATAL: seo-brief.md was not generated"
    "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Error: Phase 0 (SEO Analysis) failed"
    exit 1
fi

# --- Phase 1: Researcher (SEO-Focused Research) ---

cat > "${TMP_DIR}/p1-prompt.txt" << PROMPT
Read skills/research-topic.md and execute research.

Theme: ${KW}

IMPORTANT - SEO Factory special instructions:
1. Read the SEO brief first: ${SEO_ANALYST_DIR}/outputs/seo-brief.md
2. Focus on E-E-A-T backing data (Experience, Expertise, Authoritativeness, Trustworthiness)
3. Collect accurate FAQ answer data for Direct Answer targets
4. Deep-dive into differentiation topics from content gap analysis
5. All data must include source URL + publication date

Save output to: outputs/research.md
Write Phase 1 completion notice to: ${WRITER_DIR}/INBOX.md
Record in daily-logs.
PROMPT

log "Phase 1: Researcher (SEO-focused research)"
open_iterm_phase "${ITERM_PROFILE_RESEARCHER}" "${RESEARCHER_DIR}" "${TMP_DIR}/p1-prompt.txt" "${TMP_DIR}/p1-done" "${RESEARCHER_DIR}/outputs/research.md"

wait_for_sentinel "${TMP_DIR}/p1-done" "Phase 1" "$TIMEOUT_P1"
log "Phase 1 complete"

if [ ! -f "${RESEARCHER_DIR}/outputs/research.md" ]; then
    log "FATAL: research.md was not generated"
    "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Error: Phase 1 (Research) failed"
    exit 1
fi

# --- Phase 2: Writer (SEO-Optimized Writing) ---

cat > "${TMP_DIR}/p2-prompt.txt" << PROMPT
Read skills/write-article.md and write the article.

Research: ${RESEARCHER_DIR}/outputs/research.md

IMPORTANT - SEO Factory special instructions:
1. Read the SEO brief first (CRITICAL): ${SEO_ANALYST_DIR}/outputs/seo-brief.md
2. Follow the outline structure from Part 2 of the brief exactly
3. Insert CTAs at positions marked with 【CTA】tags
4. Place Citability blocks (134-167 words) at positions marked with 【AIO】tags
5. Insert experience/testimonials at positions marked with 【E-E-A-T:Experience】tags
6. Target KW "${KW}" density: 1-3% in title, h2, and body
7. All data must have inline citations (source + date + URL)
8. Direct Answer structure: conclusion in 1-2 sentences → detailed expansion

Save output to: outputs/article.md
Write Phase 2 completion notice to:
  - ${DESIGNER_DIR}/INBOX.md
  - ${QA_DIR}/INBOX.md
  - ${SEO_ANALYST_DIR}/INBOX.md
Record in daily-logs.
PROMPT

log "Phase 2: Writer (SEO-optimized writing)"
open_iterm_phase "${ITERM_PROFILE_WRITER}" "${WRITER_DIR}" "${TMP_DIR}/p2-prompt.txt" "${TMP_DIR}/p2-done" "${WRITER_DIR}/outputs/article.md"

wait_for_sentinel "${TMP_DIR}/p2-done" "Phase 2" "$TIMEOUT_P2"
log "Phase 2 complete"

if [ ! -f "${WRITER_DIR}/outputs/article.md" ]; then
    log "FATAL: article.md was not generated"
    "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Error: Phase 2 (Writing) failed"
    exit 1
fi

# --- Phase 3a/3b/3c: Triple Parallel Review ---

log "Phase 3a/3b/3c: Triple parallel review"

# Phase 3a: Designer (Thumbnail)
cat > "${TMP_DIR}/p3a-prompt.txt" << PROMPT
Read skills/create-thumbnail.md and create a thumbnail.
Article: ${WRITER_DIR}/outputs/article.md
Save output to: outputs/
Record in daily-logs.
PROMPT

# Phase 3b: QA (Quality Review)
cat > "${TMP_DIR}/p3b-prompt.txt" << PROMPT
Read skills/review-article.md and review the article.
Article: ${WRITER_DIR}/outputs/article.md
Research: ${RESEARCHER_DIR}/outputs/research.md
Save output to: outputs/review.md
Record in daily-logs.
PROMPT

# Phase 3c: SEO Analyst (SEO/AIO Review)
cat > "${TMP_DIR}/p3c-prompt.txt" << PROMPT
Read skills/seo-aio-review.md and execute SEO/AIO scoring.
Article: ${WRITER_DIR}/outputs/article.md
SEO Brief: ${SEO_ANALYST_DIR}/outputs/seo-brief.md
Research: ${RESEARCHER_DIR}/outputs/research.md
Save output to: outputs/seo-review.md
If rejecting, write improvement instructions to: ${WRITER_DIR}/INBOX.md
Record in daily-logs.
PROMPT

log "Phase 3a: Designer (thumbnail)"
open_iterm_phase "${ITERM_PROFILE_DESIGNER}" "${DESIGNER_DIR}" "${TMP_DIR}/p3a-prompt.txt" "${TMP_DIR}/p3a-done" "${DESIGNER_DIR}/outputs/thumbnail-concept.md"
sleep 1

log "Phase 3b: QA (quality review)"
open_iterm_phase "${ITERM_PROFILE_QA}" "${QA_DIR}" "${TMP_DIR}/p3b-prompt.txt" "${TMP_DIR}/p3b-done" "${QA_DIR}/outputs/review.md"
sleep 1

log "Phase 3c: SEO Analyst (SEO/AIO scoring)"
open_iterm_phase "${ITERM_PROFILE_SEO}" "${SEO_ANALYST_DIR}" "${TMP_DIR}/p3c-prompt.txt" "${TMP_DIR}/p3c-done" "${SEO_ANALYST_DIR}/outputs/seo-review.md"

# Wait for all three
FAIL_3A=0; FAIL_3B=0; FAIL_3C=0

(wait_for_sentinel "${TMP_DIR}/p3a-done" "Phase 3a" "$TIMEOUT_P3") &
WAIT_3A=$!
(wait_for_sentinel "${TMP_DIR}/p3b-done" "Phase 3b" "$TIMEOUT_P3") &
WAIT_3B=$!
(wait_for_sentinel "${TMP_DIR}/p3c-done" "Phase 3c" "$TIMEOUT_P3C") &
WAIT_3C=$!

wait $WAIT_3A || FAIL_3A=1
wait $WAIT_3B || FAIL_3B=1
wait $WAIT_3C || FAIL_3C=1

[ $FAIL_3A -eq 0 ] && log "Phase 3a complete" || log "Warning: Phase 3a failed/timeout"
[ $FAIL_3B -eq 0 ] && log "Phase 3b complete" || log "Warning: Phase 3b failed/timeout"
[ $FAIL_3C -eq 0 ] && log "Phase 3c complete" || log "Warning: Phase 3c failed/timeout"

# --- Check SEO Review Result ---

SEO_REVIEW_FILE="${SEO_ANALYST_DIR}/outputs/seo-review.md"
SEO_REJECTED=0

if [ -f "${SEO_REVIEW_FILE}" ]; then
    if grep -qi "reject\|差し戻し" "${SEO_REVIEW_FILE}"; then
        SEO_REJECTED=1
        log "SEO/AIO Review: REJECTED. Improvement instructions sent to Writer."
        "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory: Article rejected by SEO review. Writer needs to revise."
    fi
fi

# --- Collect Output Paths ---
ARTICLE_FILE="${WRITER_DIR}/outputs/article.md"
RESEARCH_FILE="${RESEARCHER_DIR}/outputs/research.md"
REVIEW_FILE="${QA_DIR}/outputs/review.md"
SEO_BRIEF_FILE="${SEO_ANALYST_DIR}/outputs/seo-brief.md"
CONCEPT_FILE="${DESIGNER_DIR}/outputs/thumbnail-concept.md"

THUMBNAIL_FILE=""
for ext in webp png jpg; do
    if [ -f "${DESIGNER_DIR}/outputs/thumbnail.${ext}" ]; then
        THUMBNAIL_FILE="${DESIGNER_DIR}/outputs/thumbnail.${ext}"
        break
    fi
done

# --- Phase 4: Publisher (if not rejected) ---

if [ $SEO_REJECTED -eq 1 ]; then
    log "Skipping Phase 4 due to rejection"
    END_TIME=$(date '+%H:%M:%S')
    echo "==================================================="
    echo "  SEO Factory: Paused (SEO Review Rejected)"
    echo "==================================================="
    echo "  Review: ${SEO_REVIEW_FILE}"
    echo "  Writer needs to revise, then re-run Phase 3c"
    echo "==================================================="
    rm -rf "${TMP_DIR}"
    exit 0
fi

cat > "${TMP_DIR}/p4-prompt.txt" << PROMPT
Publish the factory outputs.

Theme: ${KW} (SEO Content Factory output)

Output files:
- Article: ${ARTICLE_FILE}
- Research: ${RESEARCH_FILE}
- QA Review: ${REVIEW_FILE}
- SEO Brief: ${SEO_BRIEF_FILE}
- SEO/AIO Review: ${SEO_REVIEW_FILE}
- Thumbnail directory: ${DESIGNER_DIR}/outputs/
- Thumbnail concept: ${CONCEPT_FILE}

Save Drive links to: ${TMP_DIR}/drive-links.txt
Format:
FOLDER_URL=https://drive.google.com/drive/folders/xxx
ARTICLE_URL=https://docs.google.com/document/d/xxx/edit
PROMPT

log "Phase 4: Publisher (storage & sharing)"
open_iterm_phase "${ITERM_PROFILE_PUBLISHER}" "${PUBLISHER_DIR}" "${TMP_DIR}/p4-prompt.txt" "${TMP_DIR}/p4-done" ""

wait_for_sentinel "${TMP_DIR}/p4-done" "Phase 4" "$TIMEOUT_P4"
log "Phase 4 complete"

# Read Drive links
FOLDER_URL=""
ARTICLE_URL=""
if [ -f "${TMP_DIR}/drive-links.txt" ]; then
    source "${TMP_DIR}/drive-links.txt" 2>/dev/null || true
fi

# --- Final Report ---
END_TIME=$(date '+%H:%M:%S')

log "--- Final Report ---"
log "Outputs:"
log "  SEO Brief:   ${SEO_BRIEF_FILE} $([ -f "${SEO_BRIEF_FILE}" ] && echo "OK" || echo "MISSING")"
log "  Research:     ${RESEARCH_FILE} $([ -f "${RESEARCH_FILE}" ] && echo "OK" || echo "MISSING")"
log "  Article:      ${ARTICLE_FILE} $([ -f "${ARTICLE_FILE}" ] && echo "OK" || echo "MISSING")"
log "  Thumbnail:    ${THUMBNAIL_FILE:-none} $([ -n "${THUMBNAIL_FILE}" ] && echo "OK" || echo "MISSING")"
log "  QA Review:    ${REVIEW_FILE} $([ -f "${REVIEW_FILE}" ] && echo "OK" || echo "MISSING")"
log "  SEO Review:   ${SEO_REVIEW_FILE} $([ -f "${SEO_REVIEW_FILE}" ] && echo "OK" || echo "MISSING")"
log "  Drive: ${FOLDER_URL:-not uploaded}"

"${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Complete: ${KW}"

rm -rf "${TMP_DIR}"

echo ""
echo "==================================================="
echo "  SEO Content Factory Complete"
echo "==================================================="
echo "  Target KW:  ${KW}"
echo "  Started:     ${START_TIME} / Finished: ${END_TIME}"
echo "  Log:         ${LOG_FILE}"
echo ""
echo "  Outputs:"
echo "    SEO Brief:   ${SEO_BRIEF_FILE}"
echo "    Research:     ${RESEARCH_FILE}"
echo "    Article:      ${ARTICLE_FILE}"
echo "    Thumbnail:    ${THUMBNAIL_FILE:-not generated}"
echo "    QA Review:    ${REVIEW_FILE}"
echo "    SEO Review:   ${SEO_REVIEW_FILE}"
echo ""
echo "  Google Drive:"
echo "    Folder:      ${FOLDER_URL:-not uploaded}"
echo "    Article Doc:  ${ARTICLE_URL:-not uploaded}"
echo "==================================================="
