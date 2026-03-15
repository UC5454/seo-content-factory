---
name: seo-content-brief
description: Generate SEO/AIO brief (instructions + outline) from a target keyword (Phase 0)
---

## Overview

This skill analyzes a target keyword, performs competitive analysis on top 10 search results,
and generates a comprehensive SEO brief including:
- Search intent classification
- Competitor structure analysis
- E-E-A-T strategy
- AIO/GEO strategy (AI search optimization)
- Content outline with CTA/AIO/E-E-A-T tags
- Schema.org markup recommendations

## Workflow

```
[KW input] → [Search intent classification] → [Top 10 competitor analysis]
→ [PAA/LSI/co-occurrence collection] → [E-E-A-T strategy design]
→ [AIO/GEO strategy design] → [Brief generation] → [Outline generation]
→ [Schema design] → [Quality gate verification] → [seo-brief.md output]
```

## Steps

### 0. Input Confirmation

- Confirm the target keyword
- Check for user memo (optional)
- Confirm target site/operator info (customize in config.yaml)

### 1. Search Intent Classification

Classify the keyword into one of four categories:

| Classification | Characteristics | Impact on Article Design |
|---|---|---|
| Informational | "what is", "how to", "guide" | Comprehensive guide. Emphasize E-E-A-T Experience |
| Commercial Investigation | "comparison", "best", "review" | Comparison table + selection guide. Direct CTA connection |
| Transactional | "buy", "sign up", "free trial" | LP-style. Place CTA early |
| Navigational | Brand/service names | Official info supplementation. Differentiate with unique perspective |

### 2. Competitor Analysis (Top 10)

Search the target keyword and analyze top 10 articles:

#### 2.1 Structure Analysis

```markdown
| # | URL | Title | Est. Word Count | h2 Count | h3 Count | Intent Match | E-E-A-T Elements | Schema |
```

#### 2.2 Heading Pattern Analysis

- List ALL h2 headings from top 10 articles
- Topics covered by all → **Required topics** (must include)
- Topics covered by ≤3 → **Differentiation opportunities**

#### 2.3 Content Gap Identification

- Topics NOT covered by top articles but needed per search intent
- Unique information only your company/author can provide

### 3. Primary Source Database Lookup (E-E-A-T Experience Core)

**Automatically search the Primary Source Database for first-hand data matching the target keyword.**

#### Database Info
- Spreadsheet ID: configured in `config.yaml` → `primary_source_db.spreadsheet_id`
- 5 sheets: Experiences, Case Studies, Speaking/Media, Original Data, Testimonials

#### Lookup Steps

1. Read all 5 sheets from the spreadsheet
2. Match the **"Related KW" column** against the target keyword (fuzzy match on comma-separated values)
3. Extract all matching entries and include them in the brief:

```markdown
### Primary Source Candidates (from Database)

#### Experiences (→ E-E-A-T Experience)
- EXP-XXX: {title} ({date})
  - Result: {quantitative outcome}
  - Learning: {insight}
  → Article placement: {which section, how to use it}

#### Case Studies (→ Expertise + Trust)
- CASE-XXX: {client} ({industry})
  - Challenge → Result: {metrics}
  → Article placement: {which section}

#### Speaking/Media (→ Authoritativeness)
- MEDIA-XXX: {event} ({date}, {audience size})
  → Use as author authority proof

#### Original Data
- DATA-XXX: {survey title}
  → Use as evidence in {section}

#### Testimonials
- VOICE-XXX: {quote}
  → Use near CTA for trust reinforcement
```

4. **If zero matches**: Note "No matching primary source data. Writer should draft experience sections in author's voice, marked for author review before publication."

5. **Respect the "Public OK?" column**: Never use entries marked as non-public.

### 4. Related Keyword Collection

- **PAA (People Also Ask)**: Question list from search results
- **Related searches**: Bottom of SERP suggestions
- **LSI keywords**: Co-occurring terms
- **Autocomplete**: Search box suggestions

### 4. E-E-A-T Strategy Design

**Since Dec 2025 Core Update, E-E-A-T applies to ALL competitive queries.**

| E-E-A-T Element | Implementation | Specific Approach |
|---|---|---|
| **Experience** | First-hand experience in intro section | "We actually implemented X and the result was..." |
| **Expertise** | Industry-specific data + terminology | Quantitative data + expert analysis |
| **Authoritativeness** | Cite authoritative sources | Government stats, academic papers, official guides |
| **Trustworthiness** | Source attribution, update dates, author info | Inline citations for all data |

### 5. AIO/GEO Strategy (AI Search Optimization)

**Target citations in Google AI Overviews, ChatGPT, Perplexity.**

#### 5.1 Citability Design

- **134-167 word blocks**: Place summary passages at the start of each h2 section
- **Direct Answer structure**: Answer in 1-2 sentences → expand with details
- **Definition + Number + Source triad**: Information density that AI prefers to cite

#### 5.2 Structural Design

- **Clear heading hierarchy**: h2→h3→h4 logical nesting (no level skipping)
- **Strategic use of lists**: Comparisons, procedures, catalogs in list format
- **Table utilization**: Comparison data in markdown tables

#### 5.3 Multi-Modal Support

- **Image alt design**: Define optimal alt attributes per section
- **Diagram/infographic proposals**: Visual elements for AI Overviews display

### 6. Brief Output

Output the following to `outputs/seo-brief.md`:

```markdown
# SEO Content Brief: {keyword}

## Created
YYYY-MM-DD

## Part 1: Instructions
### Target Keyword: {keyword}
### Search Intent: {classification + rationale}
### Target Persona: {age, role, expertise level, pain points}
### Search Intent (Manifest/Latent): ...
### User Needs: {from PAA + related searches}
### Article Goal: ...
### Best Outcome for User: ...
### Required Content: {must-have + differentiation topics}
### Unique Value Proposition: {what only this author/company can provide}
### E-E-A-T Strategy: {per element}
### AIO/GEO Strategy: {citation targets, citability blocks, direct answers}
### Competitor Summary: {top 5 strengths/weaknesses table}
### Target Word Count: {competitor average ± 20%}
### Additional Notes: {from user memo}

## Part 2: Outline
{heading list with h2:/h3:/h4: prefixes}
{CTA/AIO/E-E-A-T/Schema tags on relevant headings}

## Part 3: Schema Design
{recommended JSON-LD schemas}

## Part 4: AIO/GEO Strategy Detail
## Part 5: Competitor Analysis Data
## Part 6: Related Keywords List
## Part 7: Quality Gate Check Results
```

### 7. Quality Gate

Verify before output:
- [ ] All brief items reflected in outline
- [ ] All required topics from competitors covered
- [ ] 2+ differentiation points exist
- [ ] CTA placement is natural (2-4 locations)
- [ ] E-E-A-T elements embedded in each section
- [ ] Citability blocks placed at all h2 sections
- [ ] Target word count ≥ competitor average
- [ ] h2→h3→h4 hierarchy is logical (no skips)
- [ ] PAA/related KWs naturally incorporated

### 8. Schema Recommendations

```json
// Required
- Article / BlogPosting (author, datePublished, dateModified)
- BreadcrumbList
- Organization

// Recommended (content-dependent)
- FAQPage (if Q&A section exists; rich results only for govt/medical authority sites since Aug 2023)
- VideoObject (if video embeds exist)
- Product / SoftwareApplication (for tool comparison articles)

// NEVER recommend
- HowTo (deprecated Sept 2023)
- SpecialAnnouncement (deprecated Jul 2025)
```
