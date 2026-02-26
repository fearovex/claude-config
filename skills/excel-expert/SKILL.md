---
name: excel-expert
description: >
  Expert in creating, reading, and analyzing Excel files with ExcelJS, SheetJS (JS/TS) and openpyxl, pandas (Python).
  Trigger: When working with Excel files, spreadsheets, or tabular data export/import.
---

# Excel Expert

> Expert in creating, reading, and analyzing Excel files using JavaScript/TypeScript and Python libraries.

## Description

Specialized knowledge for working with Excel files (.xlsx, .xls, .csv):
- Creating Excel files with formatting, formulas, and charts
- Reading and parsing Excel data
- Data analysis and transformation
- Library selection per use case

**Triggers**: excel, xlsx, spreadsheet, exceljs, sheetjs, openpyxl, pandas excel, csv parsing, workbook, worksheet, read excel, create excel, analyze excel, export excel, import excel

---

## Library Selection Guide

| Need | JS/TS Library | Python Library |
|------|--------------|----------------|
| Full formatting + styling | **ExcelJS** | **openpyxl** |
| Fast read/write, minimal deps | **SheetJS (xlsx)** | **xlrd / xlwt** |
| Data analysis | **danfo.js** | **pandas** |
| Simple CSV | **Papa Parse** | **csv module** |
| Charts in Excel | **ExcelJS** | **openpyxl + xlsxwriter** |

---

## JavaScript / TypeScript

### ExcelJS — Full Featured

```bash
npm install exceljs
```

#### Create a Workbook with Formatting

```typescript
import ExcelJS from 'exceljs';

async function createExcel(outputPath: string) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'MyApp';
  workbook.created = new Date();

  const sheet = workbook.addWorksheet('Sales Report', {
    pageSetup: { paperSize: 9, orientation: 'landscape' },
  });

  // Define columns
  sheet.columns = [
    { header: 'ID',       key: 'id',      width: 8  },
    { header: 'Name',     key: 'name',    width: 25 },
    { header: 'Amount',   key: 'amount',  width: 15 },
    { header: 'Date',     key: 'date',    width: 15 },
    { header: 'Status',   key: 'status',  width: 12 },
  ];

  // Style header row
  const headerRow = sheet.getRow(1);
  headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 12 };
  headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F58BB' } };
  headerRow.alignment = { vertical: 'middle', horizontal: 'center' };
  headerRow.height = 25;

  // Add data rows
  const data = [
    { id: 1, name: 'Alice',   amount: 1500.00, date: new Date('2024-01-15'), status: 'Paid'    },
    { id: 2, name: 'Bob',     amount: 2300.50, date: new Date('2024-01-20'), status: 'Pending' },
    { id: 3, name: 'Charlie', amount:  890.75, date: new Date('2024-01-22'), status: 'Paid'    },
  ];

  data.forEach(row => {
    const addedRow = sheet.addRow(row);

    // Format amount as currency
    addedRow.getCell('amount').numFmt = '$#,##0.00';

    // Format date
    addedRow.getCell('date').numFmt = 'yyyy-mm-dd';

    // Conditional color for status
    const statusCell = addedRow.getCell('status');
    if (row.status === 'Paid') {
      statusCell.font = { color: { argb: 'FF00AA00' }, bold: true };
    } else {
      statusCell.font = { color: { argb: 'FFCC6600' }, bold: true };
    }

    // Zebra striping
    if (addedRow.number % 2 === 0) {
      addedRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F5F5' } };
    }
  });

  // Add totals row
  const totalRow = sheet.addRow({
    id: '',
    name: 'TOTAL',
    amount: { formula: `SUM(C2:C${sheet.lastRow!.number})` },
    date: '',
    status: '',
  });
  totalRow.font = { bold: true };
  totalRow.getCell('amount').numFmt = '$#,##0.00';

  // Freeze header row
  sheet.views = [{ state: 'frozen', ySplit: 1 }];

  // Auto-filter
  sheet.autoFilter = { from: 'A1', to: 'E1' };

  // Add border to all cells with data
  sheet.eachRow({ includeEmpty: false }, row => {
    row.eachCell({ includeEmpty: true }, cell => {
      cell.border = {
        top:    { style: 'thin' },
        left:   { style: 'thin' },
        bottom: { style: 'thin' },
        right:  { style: 'thin' },
      };
    });
  });

  await workbook.xlsx.writeFile(outputPath);
  console.log(`Excel created at ${outputPath}`);
}
```

#### Read and Parse an Excel File

```typescript
import ExcelJS from 'exceljs';

interface RowData {
  id: number;
  name: string;
  amount: number;
  date: Date;
}

async function readExcel(filePath: string): Promise<RowData[]> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(filePath);

  const sheet = workbook.getWorksheet('Sales Report') ?? workbook.worksheets[0];
  const results: RowData[] = [];

  // Skip header (row 1), iterate from row 2
  sheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
    if (rowNumber === 1) return; // skip header

    results.push({
      id:     row.getCell(1).value as number,
      name:   row.getCell(2).value as string,
      amount: row.getCell(3).value as number,
      date:   row.getCell(4).value as Date,
    });
  });

  return results;
}
```

#### Read from Buffer (useful for uploads)

```typescript
async function readExcelFromBuffer(buffer: Buffer): Promise<Record<string, unknown>[]> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);

  const sheet = workbook.worksheets[0];
  const headers: string[] = [];
  const results: Record<string, unknown>[] = [];

  sheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) {
      // Capture headers from first row
      row.eachCell(cell => headers.push(String(cell.value ?? '')));
      return;
    }

    const record: Record<string, unknown> = {};
    row.eachCell((cell, colNumber) => {
      const key = headers[colNumber - 1];
      record[key] = cell.value;
    });
    results.push(record);
  });

  return results;
}
```

---

### SheetJS (xlsx) — Lightweight Read/Write

```bash
npm install xlsx
```

```typescript
import * as XLSX from 'xlsx';

// Read Excel → JSON
function excelToJson(filePath: string): unknown[] {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  return XLSX.utils.sheet_to_json(sheet, { defval: null });
}

// JSON → Excel
function jsonToExcel(data: unknown[], outputPath: string) {
  const sheet = XLSX.utils.json_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, sheet, 'Sheet1');

  // Column widths
  sheet['!cols'] = [{ wch: 10 }, { wch: 25 }, { wch: 15 }];

  XLSX.writeFile(workbook, outputPath);
}

// Read from ArrayBuffer (browser/upload)
function readFromArrayBuffer(buffer: ArrayBuffer): unknown[] {
  const workbook = XLSX.read(buffer, { type: 'array', cellDates: true });
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  return XLSX.utils.sheet_to_json(sheet);
}
```

---

## Python

### openpyxl — Full Featured

```python
from openpyxl import Workbook, load_workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.formatting.rule import ColorScaleRule
from datetime import date

def create_excel(output_path: str):
    wb = Workbook()
    ws = wb.active
    ws.title = "Sales Report"

    headers = ["ID", "Name", "Amount", "Date", "Status"]
    ws.append(headers)

    # Style header
    header_font = Font(bold=True, color="FFFFFF", size=12)
    header_fill = PatternFill("solid", fgColor="1F58BB")
    for col, _ in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[1].height = 25

    # Add data
    data = [
        (1, "Alice",   1500.00, date(2024, 1, 15), "Paid"),
        (2, "Bob",     2300.50, date(2024, 1, 20), "Pending"),
        (3, "Charlie",  890.75, date(2024, 1, 22), "Paid"),
    ]
    for row in data:
        ws.append(row)

    # Format columns
    ws.column_dimensions["C"].width = 15
    ws.column_dimensions["B"].width = 25
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row, min_col=3, max_col=3):
        for cell in row:
            cell.number_format = '$#,##0.00'

    # Freeze header
    ws.freeze_panes = "A2"

    # Auto-filter
    ws.auto_filter.ref = f"A1:E{ws.max_row}"

    wb.save(output_path)
```

### pandas — Data Analysis

```python
import pandas as pd

# Read Excel
def read_excel(file_path: str) -> pd.DataFrame:
    df = pd.read_excel(
        file_path,
        sheet_name=0,       # or sheet name string
        header=0,           # row index of headers
        parse_dates=['Date'],
        dtype={'ID': int, 'Name': str, 'Amount': float},
    )
    return df

# Analyze data
def analyze(df: pd.DataFrame) -> dict:
    return {
        'total_amount':   df['Amount'].sum(),
        'average_amount': df['Amount'].mean(),
        'count_paid':     df[df['Status'] == 'Paid'].shape[0],
        'by_status':      df.groupby('Status')['Amount'].sum().to_dict(),
        'monthly_totals': df.groupby(df['Date'].dt.month)['Amount'].sum().to_dict(),
    }

# Write Excel with multiple sheets + formatting
def write_excel(data: dict[str, pd.DataFrame], output_path: str):
    with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
        for sheet_name, df in data.items():
            df.to_excel(writer, sheet_name=sheet_name, index=False)

            # Access underlying openpyxl sheet for formatting
            ws = writer.sheets[sheet_name]
            for cell in ws[1]:  # header row
                cell.font = Font(bold=True)
```

---

## Common Patterns

### Validate Data on Read

```typescript
import { z } from 'zod';

const RowSchema = z.object({
  id:     z.number().int().positive(),
  name:   z.string().min(1),
  amount: z.number().nonnegative(),
  date:   z.date(),
});

async function readAndValidate(filePath: string) {
  const raw = await readExcel(filePath);
  const errors: { row: number; error: string }[] = [];
  const valid = [];

  for (const [i, row] of raw.entries()) {
    const result = RowSchema.safeParse(row);
    if (result.success) {
      valid.push(result.data);
    } else {
      errors.push({ row: i + 2, error: result.error.message });
    }
  }

  return { valid, errors };
}
```

### Export from API Route (Node/Express)

```typescript
import { Response } from 'express';
import ExcelJS from 'exceljs';

async function exportToExcel(data: Record<string, unknown>[], res: Response) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Export');

  if (data.length > 0) {
    sheet.columns = Object.keys(data[0]).map(key => ({ header: key, key, width: 20 }));
    data.forEach(row => sheet.addRow(row));
  }

  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename="export.xlsx"');

  await workbook.xlsx.write(res);
  res.end();
}
```

### Multiple Sheets

```typescript
async function createMultiSheet(outputPath: string) {
  const workbook = new ExcelJS.Workbook();

  const summarySheet = workbook.addWorksheet('Summary');
  const detailSheet  = workbook.addWorksheet('Detail');
  const configSheet  = workbook.addWorksheet('Config');

  // Cross-sheet formula reference
  summarySheet.getCell('B2').value = { formula: "Detail!C2+Detail!C3" };

  await workbook.xlsx.writeFile(outputPath);
}
```

---

## Gotchas & Best Practices

- **ExcelJS dates**: cells return `Date` objects — always check `instanceof Date` before using
- **SheetJS dates**: use `{ cellDates: true }` option or dates come as serial numbers
- **Merged cells**: read merged cell value from the top-left cell only; others return `null`
- **Large files**: use streaming API (`workbook.xlsx.createInputStream`) for >10k rows
- **Formulas**: ExcelJS stores formula strings — result is only populated after opening in Excel
- **Cell types**: check `cell.type` (`ExcelJS.ValueType`) before casting — can be `Number`, `String`, `Date`, `Formula`, `Null`
- **Column width**: ExcelJS uses character units, not pixels
- **Passwords / protection**: `sheet.protect('password', { selectLockedCells: true })`
