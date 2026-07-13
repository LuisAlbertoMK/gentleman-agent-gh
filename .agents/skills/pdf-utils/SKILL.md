---
name: pdf-utils
description: "PDF processing — extract text, parse tables, generate reports"
triggers: "PDF, extract PDF, parse PDF, merge PDF, generate PDF, PDF table, PDF invoice, read PDF, PDF to text, PDF to markdown"
license: Apache-2.0
metadata:
  tags: [documents, processing, data]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: Karpathy compression (<2.5KB)"
  dependencies: [command-wrapper]
  env:
    GENTLEMAN_AGENT_ROOT: "Repo root"
---

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

## Decision Tree
```
Simple text? → pdf-parse (fastest)
Tables? → pdf2json (structured)
Scanned/complex? → MinerU (AI-powered)
Batch >10? → script wrapper
```

## Anti-Patterns
Use MinerU for simple text (overkill) · Skip OCR for scanned docs · No validation after extraction

## Refs
codebase-memory · command-wrapper · research
