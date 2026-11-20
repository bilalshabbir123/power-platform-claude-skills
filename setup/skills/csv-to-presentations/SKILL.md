---
name: csv-to-presentations
description: Convert any tabular data (CSV, Excel) into presentation-ready PowerPoint slides with charts and tables. Perfect for quarterly reports, data presentations, and executive summaries. Use when user wants to create slides from data, present metrics, or turn spreadsheets into PowerPoint.
license: MIT
compatibility: claude
metadata:
  category: data
---

## What I Do

Convert uploaded CSV or Excel data into a professional PowerPoint (.pptx) presentation with auto-generated charts, data tables, and a title slide. Output is a downloadable .pptx file.

## Process

```
1. READ SKILL  -> Always read /mnt/skills/public/pptx/SKILL.md before writing any code
2. LOAD DATA   -> Read the uploaded CSV/Excel file with pandas
3. INSPECT     -> Understand column names, data types, numeric columns, date/category columns
4. BUILD DECK  -> Title slide + summary table slide + one chart slide per key metric
5. SAVE        -> Output to /mnt/user-data/outputs/presentation.pptx
6. PRESENT     -> Use present_files tool to deliver the file
```

## Implementation

```python
import pandas as pd
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.dml.color import RGBColor

# Load data
df = pd.read_csv('/mnt/user-data/uploads/your_file.csv')

prs = Presentation()
prs.slide_width = Inches(10)
prs.slide_height = Inches(7.5)

# --- Title Slide ---
slide = prs.slides.add_slide(prs.slide_layouts[0])
slide.shapes.title.text = "Performance Report"
slide.placeholders[1].text = "Data Overview"

# --- Data Summary Table Slide ---
slide = prs.slides.add_slide(prs.slide_layouts[5])
slide.shapes.title.text = "Key Metrics Summary"

rows, cols = df.shape[0] + 1, df.shape[1]
table = slide.shapes.add_table(rows, cols, Inches(1), Inches(2), Inches(8), Inches(4)).table

# Header row
for col_idx, col_name in enumerate(df.columns):
    cell = table.cell(0, col_idx)
    cell.text = col_name
    cell.fill.solid()
    cell.fill.fore_color.rgb = RGBColor(31, 71, 136)
    cell.text_frame.paragraphs[0].font.color.rgb = RGBColor(255, 255, 255)
    cell.text_frame.paragraphs[0].font.bold = True

# Data rows
for row_idx, row_data in df.iterrows():
    for col_idx, value in enumerate(row_data):
        table.cell(row_idx + 1, col_idx).text = str(value)

# --- Chart Slide (adapt column names to actual data) ---
slide = prs.slides.add_slide(prs.slide_layouts[5])
slide.shapes.title.text = "Trend Chart"

chart_data = CategoryChartData()
chart_data.categories = df.iloc[:, 0].tolist()       # first column as categories
chart_data.add_series('Value', df.iloc[:, 1].tolist()) # second column as values

chart = slide.shapes.add_chart(
    XL_CHART_TYPE.LINE, Inches(1), Inches(2), Inches(8), Inches(5), chart_data
).chart
chart.has_legend = True

prs.save('/mnt/user-data/outputs/presentation.pptx')
print("Done!")
```

## Requirements

```bash
pip install pandas python-pptx openpyxl --break-system-packages
```

## How to Trigger

- "Turn this CSV into slides"
- "Create a PowerPoint from this data"
- "Make a presentation from my spreadsheet for Monday's meeting"

## Slide Structure (Default)

1. **Title slide** — Report name + date
2. **Summary table** — Full dataset as formatted table
3. **Chart per numeric column** — Line chart for time-series, bar chart for comparisons

## Rules

- Always read `/mnt/skills/public/pptx/SKILL.md` first for best practices
- Detect date/category columns automatically — use as chart X-axis
- Use blue header rows (`RGBColor(31, 71, 136)`) with white text for professional styling
- If data has more than 10 rows, summarize or sample for chart readability
- Always save to `/mnt/user-data/outputs/` and use `present_files` to deliver
