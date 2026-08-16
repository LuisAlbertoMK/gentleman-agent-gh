---
name: pdf-utils
description: "PDF processing — extract text, parse tables, generate reports"
triggers: "PDF, extract PDF, parse PDF, merge PDF, generate PDF, PDF table, PDF invoice, read PDF, PDF to text, PDF to markdown"
changelog: docs/ciclos/cycle28-20260815.md
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

## Examples

### Example 1: Extract text from single PDF
```javascript
// extract-text.js
const pdf = require('pdf-parse');
const fs = require('fs');

async function extractText(pdfPath) {
  const data = await pdf(fs.readFileSync(pdfPath));
  return data.text;
}

// Usage: node extract-text.js document.pdf > output.txt
```

### Example 2: Parse invoice tables to JSON
```javascript
// parse-invoice.js
const PDFParser = require('pdf2json');
const fs = require('fs');

function parseInvoice(pdfPath) {
  return new Promise((resolve, reject) => {
    const parser = new PDFParser();
    parser.on('pdfParser_dataReady', pdfData => {
      const tables = pdfData.Pages.flatMap(page => 
        page.Tables?.map(t => t.Rows.map(r => r.map(c => c.Text))) || []
      );
      resolve(tables);
    });
    parser.on('pdfParser_dataError', err => reject(err));
    parser.loadPDF(pdfPath);
  });
}
```

### Example 3: Batch extract with error logging
```powershell
# batch-extract.ps1
$errorLog = "batch-errors.log"
Get-ChildItem invoices/*.pdf | ForEach-Object {
  try {
    $output = "$($_.FullName).txt"
    node -e "
      const pdf=require('pdf-parse'), fs=require('fs');
      pdf(fs.readFileSync('$($_.FullName)')).then(d=>fs.writeFileSync('$output', d.text))
    " -ErrorAction Stop
  } catch {
    "$($_.FullName) failed: $_" | Out-File -Append $errorLog
  }
}
```

### Example 4: MinerU for scanned documents with tables
```bash
# Extract with table preservation
py -m mineru scanned-invoice.pdf -o output/ -m pipeline -l en

# Output: output/scanned-invoice.md with markdown tables
# Tables auto-converted from PDF layout
```

### Example 5: Merge multiple PDFs into single report
```javascript
// merge-reports.js
const { PDFDocument } = require('pdf-lib');
const fs = require('fs');

async function mergePDFs(paths, outputPath) {
  const merged = await PDFDocument.create();
  for (const path of paths) {
    const pdfBytes = fs.readFileSync(path);
    const pdf = await PDFDocument.load(pdfBytes);
    const copiedPages = await merged.copyPages(pdf, pdf.getPageIndices());
    copiedPages.forEach(p => merged.addPage(p));
  }
  fs.writeFileSync(outputPath, await merged.save());
}
```

## Testing

### Test 1: Unit test text extraction
```javascript
// extract.test.js
const pdf = require('pdf-parse');
const fs = require('fs');

test('extracts text from sample PDF', async () => {
  const buffer = fs.readFileSync('fixtures/sample.pdf');
  const data = await pdf(buffer);
  
  expect(data.text.length).toBeGreaterThan(50);
  expect(data.text).not.toMatch(/[\f\x00]/); // no garbage
  expect(data.numpages).toBeGreaterThan(0);
});
```

### Test 2: Integration test table parsing
```javascript
// table-parsing.test.js
const PDFParser = require('pdf2json');

test('parses invoice table rows correctly', async () => {
  const tables = await parseInvoice('fixtures/invoice.pdf');
  
  expect(tables.length).toBeGreaterThan(0);
  const firstTable = tables[0];
  expect(firstTable.length).toBeGreaterThan(1); // header + data rows
  expect(firstTable[0]).toContain('Item'); // header row
  expect(firstTable[1]).toContain('Description'); // data row
});
```

### Test 3: End-to-end batch processing
```javascript
// batch.test.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

test('batch extracts all PDFs in directory', () => {
  const testDir = 'fixtures/batch-test';
  const files = fs.readdirSync(testDir).filter(f => f.endsWith('.pdf'));
  
  execSync(`node batch-extract.js ${testDir}`, { encoding: 'utf8' });
  
  files.forEach(file => {
    const txtPath = path.join(testDir, `${file}.txt`);
    expect(fs.existsSync(txtPath)).toBe(true);
    const content = fs.readFileSync(txtPath, 'utf8');
    expect(content.length).toBeGreaterThan(10);
  });
});
```

## Edge Cases

### Edge Case 1: Encrypted/Password-protected PDFs
```javascript
// Symptom: "Permission denied" or empty extraction
// Fix: Decrypt first with qpdf
// qpdf --password=YOUR_PASS --decrypt input.pdf output.pdf
// Then process output.pdf normally
```

### Edge Case 2: Scanned PDFs without OCR layer
```javascript
// Symptom: pdf-parse returns empty or ~50 chars of garbage
// Detection: data.text.length < 100 || /^[\s\f\x00]*$/.test(data.text)
// Fix: Skip pdf-parse/pdf2json → go straight to MinerU
```

### Edge Case 3: Large PDFs causing OOM (>200 pages)
```javascript
// Symptom: Process crashes with "JavaScript heap out of memory"
// Fix: Process in chunks
async function processLargePDF(pdfPath, chunkSize = 50) {
  const pdf = await PDFDocument.load(fs.readFileSync(pdfPath));
  const totalPages = pdf.getPageCount();
  
  for (let i = 0; i < totalPages; i += chunkSize) {
    const chunk = await PDFDocument.create();
    const pages = await chunk.copyPages(pdf, 
      Array.from({length: Math.min(chunkSize, totalPages - i)}, (_, j) => i + j)
    );
    pages.forEach(p => chunk.addPage(p));
    // Process chunk...
  }
}
```

### Edge Case 4: Corrupted PDF with malformed structure
```javascript
// Symptom: pdf-parse hangs or throws cryptic error
// Fallback chain: pdf-parse → pdf2json → MinerU → [skip]
try {
  return await pdfParse(buffer);
} catch (e1) {
  try {
    return await pdf2jsonParse(buffer);
  } catch (e2) {
    // Last resort: MinerU (handles some corruption)
    return await minerUParse(pdfPath);
  }
}
```

## Validation
After extraction, validate output before using it:
- Text: check `d.text.length > 50 && !/\f|\x00/.test(d.text)` (garbage guard)
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
1. Use MinerU for simple text (overkill, 20x slower)
2. Skip OCR for scanned docs (returns garbage)
3. No validation after extraction (silent data corruption)
4. Process huge PDFs in one go (OOM crash)

## Refs
codebase-memory · command-wrapper · research
