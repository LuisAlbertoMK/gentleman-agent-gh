# SEO Skill Analysis — 2026-07-29

**Project**: gentleman-agent-gh
**Scope**: .agents/skills/seo/
**Files**: SKILL.md, references/audit-checklist.md
**Trigger**: User request "veamos mejora la skill de SEO"

## Summary

SEO skill v2.1→v3.0 upgrade. Two categories of gaps found: **(A) structural** — missing modern skill sections per skill-improver standard; **(B) content** — outdated for 2026 SEO landscape (AI Overviews, E-E-A-T, INP).

## Findings

| Finding | Severity | Details |
|---------|----------|---------|
| Missing Activation Contract / Hard Rules / Output Format | HIGH | Skill lacks WHEN/WHEN NOT, Hard Rules, and structured Output per skill-improver standard |
| AI Overviews / SGE / AI Mode absent | HIGH | Google SERP now includes AI-generated answers via RAG — win condition shifted to being the cited source |
| E-E-A-T framework absent | HIGH | Critical for both rankings and AI citation selection; no mention of Experience/Expertise/Authority/Trust |
| INP missing (CWV incomplete) | MED | INP replaced FID in March 2024 — skill only mentioned generic CWV |
| llms.txt description outdated | MED | Skill said "emerging, no spec" — Google (June 2026) explicitly says unnecessary for Google Search AI |
| ProfilePage schema missing | MED | Required for E-E-A-T author signals; skill had Article/Product/FAQ/BreadcrumbList only |
| Triggers incomplete | MED | Missing: EEAT, SGE, AI Overview, INP, GA4, topical authority, AEO, GEO |
| No audit cadence | LOW | No pre-deploy / monthly / quarterly rhythm defined |
| No AI visibility monitoring | LOW | No Search Console Generative AI report usage, no citation tracking |

## Files Changed

- .agents/skills/seo/SKILL.md — v2.1→v3.0 (63→146 líneas)
- .agents/skills/seo/references/audit-checklist.md — updated with E-E-A-T, CWV/INP, AI visibility items

## Engram Persistence

- Observation ID: obs-2d6d3edaf5fb98fa
- topic_key: nalysis/seo-skill
- Saved: 2026-07-29

## Trend Analysis

First analysis of SEO skill — no prior baseline.
