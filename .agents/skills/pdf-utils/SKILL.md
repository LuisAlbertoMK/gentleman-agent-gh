---
name: pdf-utils
description: "PDF processing — extract text, parse tables, generate reports"
triggers: "PDF, extract PDF, parse PDF, merge PDF, generate PDF, PDF table, PDF invoice, read PDF, PDF to text, PDF to markdown"
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

## Validation
After extraction, validate output before using it:
- Text: check `d.text.length > 50 && !/\^L|\x00/.test(d.text)` (garbage guard)
- Tables: verify row count matches expected items
- Scanned: spot-check 3 random pages for OCR quality

## Batch Processing (>10 files)
```powershell
foreach ($file in Get-ChildItem invoices/*.pdf) {
  try {
    node -e "const p=require('pdf-parse'),f=require('fs');
p(f.readFileSync('$file')).then(d=>f.writeFileSync('$file.txt',d.text))" -ErrorAction Stop
  } catch {
    "$file failed: $_" | Out-File -Append batch-errors.log
  }
}
```

## Error Handling
| Problem | Symptom | Fix |
|---------|---------|-----|
| Corrupted PDF | pdf-parse hangs/throws | Try pdf2json first, then MinerU as last resort |
| Encrypted PDF | "Permission denied" | `qpdf --password=... --decrypt` then retry |
| Scanned w/o OCR | Empty text | Skip pdf-parse → MinerU directly |
| Huge PDF (>200p) | OOM | Process in 50-page chunks |

**Fallback chain**: pdf-parse → pdf2json → MinerU → `[skip]` with log entry

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
