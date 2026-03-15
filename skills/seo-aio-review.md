---
name: seo-aio-review
description: SEO/AIO scoring and quality gate for completed articles (Phase 3c)
---

## Overview

Quantitative scoring of article quality across three axes:
- **SEO Score** (100 points): On-page optimization
- **AIO/GEO Score** (100 points): AI search citation readiness
- **E-E-A-T Score** (100 points): Experience, Expertise, Authoritativeness, Trustworthiness

## Inputs

- `article.md` — completed article from Writer
- `seo-brief.md` — SEO brief from Phase 0
- `research.md` — research from Phase 1

## SEO Scoring (100 points)

### Title & Meta (15 pts)
| Check | Points | Criteria |
|---|---|---|
| Title length | 5 | 30-60 characters |
| KW position | 5 | KW within first 30 chars |
| Meta description | 5 | 120-160 chars, includes CTA |

### Heading Structure (20 pts)
| Check | Points | Criteria |
|---|---|---|
| h1 uniqueness | 3 | Exactly one h1 |
| h2-h3-h4 hierarchy | 5 | No level skipping, logical nesting |
| KW in headings | 5 | 50%+ of h2s contain KW or related terms |
| Heading appeal | 4 | "Makes you want to read" phrasing |
| Heading count | 3 | Within ±20% of competitor average |

### Content Quality (30 pts)
| Check | Points | Criteria |
|---|---|---|
| Word count | 5 | ≥ competitor average |
| KW density | 5 | 1-3% of body text |
| Related KW coverage | 5 | 70%+ of brief's related KW list covered |
| Internal links | 5 | 3-10 natural placements |
| Citations | 5 | 10+ sources with inline attribution |
| CTA placement | 5 | 2-4 locations, contextually natural |

### Technical SEO (10 pts)
| Check | Points | Criteria |
|---|---|---|
| Image alt design | 3 | All images have KW-containing alt |
| URL structure | 2 | English slug, KW included, ≤3 levels |
| Schema compliance | 5 | Matches brief's Schema design |

### Brief Compliance (25 pts)
| Check | Points | Criteria |
|---|---|---|
| Required topics | 10 | All must-have topics from brief covered |
| Differentiation | 8 | 2+ unique elements implemented |
| User memo | 7 | Specified target/tone/CTA reflected |

## AIO/GEO Scoring (100 points)

### Citability (25 pts)
| Check | Points | Criteria |
|---|---|---|
| Summary passages | 10 | 134-167 word blocks at each h2 |
| Direct Answer structure | 8 | Conclusion in 1-2 sentences → expansion |
| Definition+Number+Source | 7 | Triad present in key sections |

### Structural Readability (20 pts)
| Check | Points | Criteria |
|---|---|---|
| Heading clarity | 7 | AI can accurately parse structure |
| Lists & tables | 7 | Comparisons/procedures are structured |
| Passage independence | 6 | Each section stands alone meaningfully |

### Multi-Modal (15 pts)
| Check | Points | Criteria |
|---|---|---|
| Image alt informativeness | 5 | AI can understand image content from alt |
| Diagrams & tables | 5 | Visual elements for AI Overview display |
| Structured data integration | 5 | Schema supports AI citation |

### Authority Signals (20 pts)
| Check | Points | Criteria |
|---|---|---|
| Source authority | 8 | % of govt/academic/official sources |
| Author information | 6 | Author's E-E-A-T clearly stated |
| Brand mention readiness | 6 | Company expertise demonstrated |

### Technical AIO (20 pts)
| Check | Points | Criteria |
|---|---|---|
| FAQ schema candidates | 7 | Q&A sections are Schema-ready |
| Passage length optimization | 7 | 134-167 word blocks for AI citation |
| Meta completeness | 6 | Published date, updated date, author explicit |

## E-E-A-T Scoring (100 points)

| Element | Points | Check |
|---|---|---|
| Experience | 30 | First-hand experience described ("we tried", "I tested") |
| Expertise | 25 | Industry-specific knowledge used accurately |
| Authoritativeness | 20 | Authoritative source citations, author credentials mentioned |
| Trustworthiness | 25 | Sources cited, update dates, bias disclosed, accurate numbers |

## Scoring Formula

```
Total = SEO × 0.25 + AIO × 0.25 + E-E-A-T × 0.25 + Brief Compliance × 0.25
```

| Total Score | Verdict | Action |
|---|---|---|
| 85+ | **Approved** | Proceed to Phase 4 |
| 70-84 | **Conditional** | Approve with minor improvement notes |
| ≤69 | **Rejected** | Send improvement instructions to Writer |

## Output

Save to `outputs/seo-review.md`:

```markdown
# SEO/AIO Review: {keyword}

## Review Date: YYYY-MM-DD

## Score Summary
| Category | Score | Verdict |
|---|---|---|
| SEO | XX/100 | Good/Needs Improvement/Poor |
| AIO/GEO | XX/100 | Good/Needs Improvement/Poor |
| E-E-A-T | XX/100 | Good/Needs Improvement/Poor |
| **Total** | **XX/100** | **Approved/Conditional/Rejected** |

## Detailed Scores
{per-item scoring with rationale}

## Improvement Instructions (if rejected)
### CRITICAL (must fix)
### HIGH (strongly recommended)
### MEDIUM (recommended)

## Final Schema
{production-ready JSON-LD}

## Pre-publish Checklist (if approved)
- [ ] Title & meta description finalized
- [ ] URL slug confirmed
- [ ] Schema implementation requested
- [ ] Image alt attributes finalized
- [ ] Internal links verified
- [ ] Publish date set
```
