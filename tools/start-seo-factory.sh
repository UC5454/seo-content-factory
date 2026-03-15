#!/bin/bash
# ============================================================
# SEO Content Factory - Orchestrator
# ============================================================
#
# Terminal-agnostic design: works on any terminal emulator
# (iTerm2, Antigravity, Terminal.app, Warp, Linux terminals, etc.)
#
# Modes:
#   Default (headless): Runs claude CLI directly as subprocesses
#   --visual:           Opens new terminal windows (macOS only, auto-detects terminal)
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
#   ./start-seo-factory.sh --visual "target keyword" ["user memo"]
#
# Examples:
#   ./start-seo-factory.sh "Gemini Code Assist"
#   ./start-seo-factory.sh "Claude Code tutorial" "CTA to https://example.com/contact"
#   ./start-seo-factory.sh --visual "Gemini Code Assist"
# ============================================================

set -euo pipefail

# --- Parse flags ---
VISUAL_MODE=false
if [ "${1:-}" = "--visual" ]; then
    VISUAL_MODE=true
    shift
fi

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if exists
if [ -f "${PROJECT_DIR}/.env" ]; then
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

BASE_DIR="${SEO_FACTORY_BASE_DIR:-$PROJECT_DIR}"

SEO_ANALYST_DIR="${SEO_FACTORY_SEO_ANALYST_DIR:-${BASE_DIR}/example-team/seo-analyst}"
RESEARCHER_DIR="${SEO_FACTORY_RESEARCHER_DIR:-${BASE_DIR}/example-team/researcher}"
WRITER_DIR="${SEO_FACTORY_WRITER_DIR:-${BASE_DIR}/example-team/writer}"
DESIGNER_DIR="${SEO_FACTORY_DESIGNER_DIR:-${BASE_DIR}/example-team/designer}"
QA_DIR="${SEO_FACTORY_QA_DIR:-${BASE_DIR}/example-team/qa}"
PUBLISHER_DIR="${SEO_FACTORY_PUBLISHER_DIR:-${BASE_DIR}/example-team/publisher}"
PUBLISHER_INBOX="${SEO_FACTORY_PUBLISHER_INBOX:-${PUBLISHER_DIR}/INBOX.md}"

COMPANY_NAME="${SEO_FACTORY_COMPANY:-Your Company}"
CONTACT_URL="${SEO_FACTORY_CONTACT_URL:-https://example.com/contact}"

# Timeouts (seconds)
TIMEOUT_P0="${SEO_FACTORY_TIMEOUT_P0:-1200}"
TIMEOUT_P1="${SEO_FACTORY_TIMEOUT_P1:-900}"
TIMEOUT_P2="${SEO_FACTORY_TIMEOUT_P2:-1200}"
TIMEOUT_P3="${SEO_FACTORY_TIMEOUT_P3:-900}"
TIMEOUT_P3C="${SEO_FACTORY_TIMEOUT_P3C:-1200}"
TIMEOUT_P4="${SEO_FACTORY_TIMEOUT_P4:-600}"

# --- Input Sanitization ---
RAW_KW="${1:-}"
KW=$(echo "$RAW_KW" | sed "s/['\`\$;|&]//g")
USER_MEMO="${2:-}"
if [ -n "$USER_MEMO" ]; then
    USER_MEMO=$(echo "$USER_MEMO" | sed "s/['\`\$;|&]//g")
fi

if [ -z "${KW}" ]; then
    echo "Error: Please specify a target keyword"
    echo ""
    echo "Usage:"
    echo "  ./start-seo-factory.sh \"target keyword\" [\"user memo\"]"
    echo "  ./start-seo-factory.sh --visual \"target keyword\" [\"user memo\"]"
    echo ""
    echo "Options:"
    echo "  --visual    Open each phase in a new terminal window (macOS)"
    echo "              Without this flag, runs headless (works on any OS/terminal)"
    exit 1
fi

# --- Claude CLI Resolution ---
source "${SCRIPT_DIR}/resolve-claude.sh"
CLAUDE="$CLAUDE_CMD"

# --- Setup ---
TMP_DIR="${TMPDIR:-/tmp}/seo-factory-$$"
TODAY=$(date '+%Y-%m-%d')
START_TIME=$(date '+%H:%M:%S')
LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/seo-factory-$(date '+%Y%m%d-%H%M%S').log"

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

# ============================================================
# Phase Execution: Terminal-Agnostic
# ============================================================

# Headless mode: run claude CLI directly as a subprocess
run_phase_headless() {
    local phase_name="$1"
    local employee_dir="$2"
    local prompt="$3"
    local phase_log="${LOG_DIR}/${phase_name}.log"

    log "${phase_name}: Starting (headless)"

    (
        cd "$employee_dir"
        $CLAUDE "$prompt" --permission-mode bypassPermissions > "$phase_log" 2>&1
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            log "${phase_name}: claude exited with code $exit_code"
        fi
    )

    log "${phase_name}: Complete"
}

# Headless mode: run in background, return PID
run_phase_headless_bg() {
    local phase_name="$1"
    local employee_dir="$2"
    local prompt="$3"
    local phase_log="${LOG_DIR}/${phase_name}.log"

    log "${phase_name}: Starting (headless, background)"

    (
        cd "$employee_dir"
        $CLAUDE "$prompt" --permission-mode bypassPermissions > "$phase_log" 2>&1
    ) &
    echo $!
}

# Visual mode: detect terminal and open new window
# Supports: iTerm2, Antigravity, Terminal.app, Warp
open_terminal_window() {
    local phase_name="$1"
    local employee_dir="$2"
    local prompt="$3"
    local phase_log="${LOG_DIR}/${phase_name}.log"

    # Detect which terminal is running
    local terminal_app=""
    if [ -n "${TERM_PROGRAM:-}" ]; then
        terminal_app="$TERM_PROGRAM"
    elif pgrep -q "iTerm2"; then
        terminal_app="iTerm.app"
    fi

    local cmd="cd '${employee_dir}' && ${CLAUDE} \"\$(cat '${TMP_DIR}/${phase_name}-prompt.txt')\" --permission-mode bypassPermissions 2>&1 | tee '${phase_log}'"

    # Write prompt to temp file for visual mode
    echo "$prompt" > "${TMP_DIR}/${phase_name}-prompt.txt"

    case "$terminal_app" in
        iTerm.app|iTerm2)
            osascript << APPLE
tell application "iTerm2"
    activate
    create window with default profile
    delay 0.5
    tell current session of current window
        write text "cd '${employee_dir}' && ${CLAUDE} \"\\\$(cat '${TMP_DIR}/${phase_name}-prompt.txt')\" --permission-mode bypassPermissions 2>&1 | tee '${phase_log}'; touch '${TMP_DIR}/${phase_name}-done'"
    end tell
end tell
APPLE
            ;;
        Apple_Terminal)
            osascript << APPLE
tell application "Terminal"
    activate
    do script "cd '${employee_dir}' && ${CLAUDE} \"\$(cat '${TMP_DIR}/${phase_name}-prompt.txt')\" --permission-mode bypassPermissions 2>&1 | tee '${phase_log}'; touch '${TMP_DIR}/${phase_name}-done'"
end tell
APPLE
            ;;
        *)
            # Fallback: any terminal that supports `open -a`
            # Works with Antigravity, Warp, Alacritty, etc. via headless
            log "${phase_name}: Unknown terminal '${terminal_app:-none}', falling back to headless"
            run_phase_headless "$phase_name" "$employee_dir" "$prompt"
            touch "${TMP_DIR}/${phase_name}-done"
            return 0
            ;;
    esac
}

# Wait for visual mode completion
wait_for_visual() {
    local phase_name="$1"
    local timeout="${2:-900}"
    local elapsed=0

    while [ ! -f "${TMP_DIR}/${phase_name}-done" ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ $elapsed -ge $timeout ]; then
            log "Timeout: ${phase_name} did not complete within ${timeout}s"
            return 1
        fi
    done
    rm -f "${TMP_DIR}/${phase_name}-done"
    return 0
}

# Unified phase runner
run_phase() {
    local phase_name="$1"
    local employee_dir="$2"
    local prompt="$3"
    local required_output="${4:-}"
    local timeout="${5:-900}"

    if [ "$VISUAL_MODE" = true ]; then
        open_terminal_window "$phase_name" "$employee_dir" "$prompt"
        wait_for_visual "$phase_name" "$timeout"
    else
        run_phase_headless "$phase_name" "$employee_dir" "$prompt"
    fi

    # Verify required output
    if [ -n "$required_output" ] && [ ! -f "$required_output" ]; then
        log "FATAL: ${required_output} was not generated by ${phase_name}"
        "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Error: ${phase_name} failed to produce output"
        exit 1
    fi
}

# Run phase in background (for parallel phases), returns PID
run_phase_bg() {
    local phase_name="$1"
    local employee_dir="$2"
    local prompt="$3"
    local phase_log="${LOG_DIR}/${phase_name}.log"

    if [ "$VISUAL_MODE" = true ]; then
        open_terminal_window "$phase_name" "$employee_dir" "$prompt"
        # Return a waiter subprocess PID
        (wait_for_visual "$phase_name" "${4:-900}") &
        echo $!
    else
        run_phase_headless_bg "$phase_name" "$employee_dir" "$prompt"
    fi
}

# ============================================================
# Main Pipeline
# ============================================================

MODE_LABEL="headless"
[ "$VISUAL_MODE" = true ] && MODE_LABEL="visual"

echo "==================================================="
echo "  SEO Content Factory"
echo "==================================================="
echo "  Target KW: ${KW}"
echo "  Memo:      ${USER_MEMO:-none}"
echo "  Mode:      ${MODE_LABEL}"
echo "  Started:   ${TODAY} ${START_TIME}"
echo "  Log:       ${LOG_FILE}"
echo "==================================================="
echo ""

log "SEO Factory started: KW '${KW}' (mode: ${MODE_LABEL})"

# --- Phase 0: SEO Analyst ---

MEMO_SECTION=""
if [ -n "$USER_MEMO" ]; then
    MEMO_SECTION="
User Memo: ${USER_MEMO}
Reflect this memo in both the brief and the outline."
fi

P0_PROMPT="Read skills/seo-content-brief.md and execute the SEO brief creation workflow.

Target Keyword: ${KW}
Company: ${COMPANY_NAME}
Contact URL: ${CONTACT_URL}
${MEMO_SECTION}

Save output to: outputs/seo-brief.md
Write Phase 0 completion notice to: ${RESEARCHER_DIR}/INBOX.md
Record in daily-logs."

log "Phase 0: SEO Analyst (SEO/AIO Analysis)"
run_phase "phase-0-seo" "$SEO_ANALYST_DIR" "$P0_PROMPT" "${SEO_ANALYST_DIR}/outputs/seo-brief.md" "$TIMEOUT_P0"

# --- Phase 1: Researcher ---

P1_PROMPT="Read skills/research-topic.md and execute research.

Theme: ${KW}

IMPORTANT - SEO Factory special instructions:
1. Read the SEO brief first: ${SEO_ANALYST_DIR}/outputs/seo-brief.md
2. Focus on E-E-A-T backing data
3. Collect accurate FAQ answer data for Direct Answer targets
4. Deep-dive into differentiation topics from content gap analysis
5. All data must include source URL + publication date

Save output to: outputs/research.md
Write Phase 1 completion notice to: ${WRITER_DIR}/INBOX.md
Record in daily-logs."

log "Phase 1: Researcher (SEO-focused research)"
run_phase "phase-1-research" "$RESEARCHER_DIR" "$P1_PROMPT" "${RESEARCHER_DIR}/outputs/research.md" "$TIMEOUT_P1"

# --- Phase 2: Writer ---

P2_PROMPT="Read skills/write-article.md and write the article.

Research: ${RESEARCHER_DIR}/outputs/research.md

*** CRITICAL: This article will be scored by a strict SEO/AIO review (Phase 3c). Only 90+ out of 100 passes. Follow ALL rules below or the article WILL be rejected. ***

0. READ THE SEO BRIEF FIRST (entire document): ${SEO_ANALYST_DIR}/outputs/seo-brief.md
   Pay special attention to Part 2 (outline) and the 'Writer Must-Read' section at the end.

1. FOLLOW THE OUTLINE 100%: Match the brief's heading structure exactly. Changing it = 0 points for Brief Compliance.

2. HOOK IN FIRST 3 LINES: Start with shocking data, a paradox, or a candid confession. NEVER 'In this article, we will explore...' (-5 points).

3. 2+ FIRST-HAND EXPERIENCES: Include specific dates, places, and numbers. 'We tried it and it was great' is too vague (-10 points). Target: 'After implementing X in Feb 2026, task time dropped by 42%'.

4. 15+ CITATIONS: 50%+ must be primary sources (government stats, academic papers, official announcements). Every citation needs: source name + date + URL.

5. DIRECT ANSWER STRUCTURE: Every h2 section opens with 1-2 sentence conclusion THEN expands. NEVER 'Let us look at...' (-5 points). Target: 'X is a Y that does Z. Specifically...'

6. CITABILITY BLOCKS: Place 134-167 word self-contained summary paragraphs at AIO-tagged sections. These must be quotable by AI without additional context.

7. 2+ TABLES: Comparison data MUST be in markdown tables. Writing comparisons in prose = -3 points each.

8. KW DENSITY 1.5-2.5%: Target keyword '${KW}' in natural context. Over 3% = over-optimization penalty.

9. RELATED KW 80%+ COVERAGE: Check the brief's Part 6 keyword list and intentionally weave them in.

10. ZERO AI-SOUNDING PHRASES:
    BANNED: 'It is important to note' / 'It is worth mentioning' / 'Notably' / em dashes / slash parallels ('efficiency/quality') = -3 points EACH
    BANNED: Same sentence ending 3 times in a row = -2 points
    BANNED: 'Furthermore'/'Additionally'/'Moreover' 5+ times = -3 points
    BANNED: Bullet points exceeding 50% of body text = -5 points

11. FAIR & BALANCED: Include counterarguments and limitations. One-sided promotion = -8 points for Trustworthiness.

12. NATURAL CTAs (2-4): Insert at CTA-tagged positions. Zero pushiness. Must feel like a natural part of the narrative.

Save output to: outputs/article.md
Write Phase 2 completion notice to:
  - ${DESIGNER_DIR}/INBOX.md
  - ${QA_DIR}/INBOX.md
  - ${SEO_ANALYST_DIR}/INBOX.md
Record in daily-logs."

log "Phase 2: Writer (SEO-optimized writing)"
run_phase "phase-2-write" "$WRITER_DIR" "$P2_PROMPT" "${WRITER_DIR}/outputs/article.md" "$TIMEOUT_P2"

# --- Phase 3: Triple Parallel Review ---

log "Phase 3: Triple parallel review"

P3A_PROMPT="Read skills/create-thumbnail.md and create a thumbnail.
Article: ${WRITER_DIR}/outputs/article.md
Save output to: outputs/
Record in daily-logs."

P3B_PROMPT="Read skills/review-article.md and review the article.
Article: ${WRITER_DIR}/outputs/article.md
Research: ${RESEARCHER_DIR}/outputs/research.md
Save output to: outputs/review.md
Record in daily-logs."

P3C_PROMPT="Read skills/seo-aio-review.md and execute SEO/AIO scoring.
Article: ${WRITER_DIR}/outputs/article.md
SEO Brief: ${SEO_ANALYST_DIR}/outputs/seo-brief.md
Research: ${RESEARCHER_DIR}/outputs/research.md
Save output to: outputs/seo-review.md
If rejecting, write improvement instructions to: ${WRITER_DIR}/INBOX.md
Record in daily-logs."

# Launch 3 phases in parallel
PID_3A=$(run_phase_bg "phase-3a-design" "$DESIGNER_DIR" "$P3A_PROMPT" "$TIMEOUT_P3")
PID_3B=$(run_phase_bg "phase-3b-qa" "$QA_DIR" "$P3B_PROMPT" "$TIMEOUT_P3")
PID_3C=$(run_phase_bg "phase-3c-seo" "$SEO_ANALYST_DIR" "$P3C_PROMPT" "$TIMEOUT_P3C")

# Wait for all three
FAIL_3A=0; FAIL_3B=0; FAIL_3C=0
wait $PID_3A || FAIL_3A=1
wait $PID_3B || FAIL_3B=1
wait $PID_3C || FAIL_3C=1

[ $FAIL_3A -eq 0 ] && log "Phase 3a complete: Designer" || log "Warning: Phase 3a failed/timeout"
[ $FAIL_3B -eq 0 ] && log "Phase 3b complete: QA" || log "Warning: Phase 3b failed/timeout"
[ $FAIL_3C -eq 0 ] && log "Phase 3c complete: SEO Review" || log "Warning: Phase 3c failed/timeout"

# --- Check SEO Review ---

SEO_REVIEW_FILE="${SEO_ANALYST_DIR}/outputs/seo-review.md"
SEO_REJECTED=0

if [ -f "${SEO_REVIEW_FILE}" ]; then
    if grep -qi "reject\|差し戻し\|CRITICAL\|79以下" "${SEO_REVIEW_FILE}"; then
        SEO_REJECTED=1
        log "SEO/AIO Review: REJECTED"
        "${SCRIPT_DIR}/notify-complete.sh" "SEO Factory: Article rejected. Writer revision needed."
    fi
fi

# --- Collect Outputs ---
ARTICLE_FILE="${WRITER_DIR}/outputs/article.md"
RESEARCH_FILE="${RESEARCHER_DIR}/outputs/research.md"
REVIEW_FILE="${QA_DIR}/outputs/review.md"
SEO_BRIEF_FILE="${SEO_ANALYST_DIR}/outputs/seo-brief.md"

THUMBNAIL_FILE=""
for ext in webp png jpg; do
    [ -f "${DESIGNER_DIR}/outputs/thumbnail.${ext}" ] && THUMBNAIL_FILE="${DESIGNER_DIR}/outputs/thumbnail.${ext}" && break
done

# --- Phase 4: Publisher (if approved) ---

if [ $SEO_REJECTED -eq 1 ]; then
    log "Skipping Phase 4 (rejected)"
    END_TIME=$(date '+%H:%M:%S')
    echo "==================================================="
    echo "  SEO Factory: Paused (SEO Review Rejected)"
    echo "==================================================="
    echo "  SEO Review:  ${SEO_REVIEW_FILE}"
    echo "  Phase log:   ${LOG_DIR}/phase-3c-seo.log"
    echo "  Action:      Writer revises, then re-run Phase 3c"
    echo "==================================================="
    rm -rf "${TMP_DIR}"
    exit 0
fi

P4_PROMPT="Publish the factory outputs.

Theme: ${KW} (SEO Content Factory output)

Output files:
- Article: ${ARTICLE_FILE}
- Research: ${RESEARCH_FILE}
- QA Review: ${REVIEW_FILE}
- SEO Brief: ${SEO_BRIEF_FILE}
- SEO/AIO Review: ${SEO_REVIEW_FILE}
- Thumbnail directory: ${DESIGNER_DIR}/outputs/
Record in daily-logs.

Save Drive links to: ${TMP_DIR}/drive-links.txt
Format:
FOLDER_URL=https://...
ARTICLE_URL=https://..."

log "Phase 4: Publisher"
run_phase "phase-4-publish" "$PUBLISHER_DIR" "$P4_PROMPT" "" "$TIMEOUT_P4"

# Read Drive links
FOLDER_URL=""
ARTICLE_URL=""
[ -f "${TMP_DIR}/drive-links.txt" ] && source "${TMP_DIR}/drive-links.txt" 2>/dev/null || true

# --- Final Report ---
END_TIME=$(date '+%H:%M:%S')

log "=== Final Report ==="
log "SEO Brief:   ${SEO_BRIEF_FILE} $([ -f "${SEO_BRIEF_FILE}" ] && echo OK || echo MISSING)"
log "Research:     ${RESEARCH_FILE} $([ -f "${RESEARCH_FILE}" ] && echo OK || echo MISSING)"
log "Article:      ${ARTICLE_FILE} $([ -f "${ARTICLE_FILE}" ] && echo OK || echo MISSING)"
log "Thumbnail:    ${THUMBNAIL_FILE:-none}"
log "QA Review:    ${REVIEW_FILE} $([ -f "${REVIEW_FILE}" ] && echo OK || echo MISSING)"
log "SEO Review:   ${SEO_REVIEW_FILE} $([ -f "${SEO_REVIEW_FILE}" ] && echo OK || echo MISSING)"
log "Drive:        ${FOLDER_URL:-not uploaded}"

"${SCRIPT_DIR}/notify-complete.sh" "SEO Factory Complete: ${KW}"

rm -rf "${TMP_DIR}"

echo ""
echo "==================================================="
echo "  SEO Content Factory Complete"
echo "==================================================="
echo "  Target KW:  ${KW}"
echo "  Mode:       ${MODE_LABEL}"
echo "  Duration:   ${START_TIME} → ${END_TIME}"
echo "  Log:        ${LOG_FILE}"
echo "  Phase logs: ${LOG_DIR}/phase-*.log"
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
echo "    Article:     ${ARTICLE_URL:-not uploaded}"
echo "==================================================="
