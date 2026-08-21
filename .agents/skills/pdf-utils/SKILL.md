---
name: pdf-utils
description: "PDF processing — extract text, parse tables, generate reports"
triggers: "PDF, extract PDF, parse PDF, merge PDF, generate PDF, PDF table, PDF invoice, read PDF, PDF to text, PDF to markdown"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1460
---

## When to Use
PDF processing — extract text, parse tables, generate report

## Tools
| Tool | Use | Speed | Install |
|------|-----|-------|---------|
| **pdf-parse** | Text extraction | ~100ms/page | `npm i pdf-parse` |
| **pdf2json** | Tables + structure | ~150ms/page | `npm i pdf2json` |
| **MinerU** | Complex/scanned | ~2-5s/page | `py -m pip install mineru` |

## Mode 1: Simple Text
```bash
node -e "const pdf=require('pdf-parse'),fs=require('fs');
pdf(fs.readFileSync('doc.pdf')).then(d=>console.log(d.text))"
```

## Mode 2: Table Extraction
```bash
node -e "const P=require('pdf2json'),p=new P();
p.on('pdfParser_dataReady',d=>console.log(JSON.stringify(d)));
p.loadPDF('invoice.pdf')"
```

## Mode 3: Complex Documents (MinerU)
```bash
py -m mineru input.pdf -o output_dir -m pipeline
# Output: Markdown with tables, 86-95% accuracy
```
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/pdf-utils/reference.md

---
