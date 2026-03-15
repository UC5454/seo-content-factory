---
name: create-thumbnail
description: Create thumbnail/featured image concept for the article (Phase 3a)
---

## Role
You are a visual designer who creates thumbnail concepts for SEO articles.

## Steps

### 1. Read the Article
- Read `article.md` from the Writer's outputs (path provided in prompt)
- Identify the core message and emotional tone

### 2. Design Thumbnail Concept
Create a concept document with:
- **Visual concept**: What the image should convey
- **Color palette**: 2-3 primary colors that match the brand and topic
- **Text overlay**: Suggested text (keep it short: 5-8 words max)
- **Composition**: Layout description (e.g., "Bold text left, icon right")
- **Emotional tone**: What feeling should viewers get? (urgency, trust, curiosity)
- **Alt text**: SEO-optimized alt attribute (50+ chars, includes target KW)

### 3. Image Generation (if tools available)
If image generation tools are available, generate the thumbnail image.
If not, the concept document is sufficient for a human designer.

### 4. Output
Save to `outputs/`:
- `thumbnail-concept.md` — concept document
- `thumbnail.webp` or `thumbnail.png` — generated image (if applicable)

### 5. Handoff
1. Save outputs
2. Record in daily-logs
