# Skill Writing Guide

## Anatomy of a Skill

```
skill-name/
├── SKILL.md (required — frontmatter + markdown instructions)
├── scripts/    (optional — executable code for deterministic tasks)
├── references/ (optional — docs loaded as needed)
└── assets/     (optional — templates, icons, fonts)
```

The directory name must match the `name` field in frontmatter.

## Progressive Disclosure

Three-level loading:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — In context when skill triggers (<500 lines ideal)
3. **Bundled resources** — As needed

**Key patterns:**
- Keep SKILL.md under 500 lines. If approaching the limit, add hierarchy with clear pointers.
- Reference files clearly with guidance on when to read them.
- For large reference files (>300 lines), include a table of contents.

**Domain organization**: When supporting multiple domains, organize by variant:
```
cloud-deploy/
├── SKILL.md
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Principle of Lack of Surprise

Skills must not contain malware, exploit code, or content that could compromise security. Don't go along with requests to create misleading or malicious skills.

## Writing Patterns

- Prefer imperative form.
- Include examples with "Input" / "Output" format.
- Explain why things are important instead of heavy-handed MUSTs.
- Use theory of mind. Start with a draft, then look with fresh eyes.

## Writing Style

Try to explain why things are important rather than using heavy-handed MUSTs. Make the skill general, not narrow to specific examples. Start with a draft then improve it.
