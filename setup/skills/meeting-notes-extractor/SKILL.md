---
name: meeting-notes-extractor
description: Transform meeting transcripts from Zoom, Teams, or Google Meet into structured Word documents with action items, decisions, and next steps. Extract owners, deadlines, and key discussion points. Use when user mentions meeting notes, transcripts, action items, meeting minutes, or Zoom/Teams recordings.
license: MIT
compatibility: claude
metadata:
  category: productivity
---

## What I Do

Process meeting transcripts and produce a professional Word (.docx) meeting minutes document with action items table, key decisions, discussion summary, and next steps — ready to share with the team.

## Process

```
1. READ SKILL  -> Always read /mnt/skills/public/docx/SKILL.md before writing any code
2. LOAD FILE   -> Read the uploaded transcript from /mnt/user-data/uploads/
3. EXTRACT     -> Pull out: attendees, action items (owner + deadline), decisions, discussion points
4. BUILD DOC   -> Create structured Word document with tables and formatted sections
5. SAVE        -> Output to /mnt/user-data/outputs/meeting_minutes.docx
6. PRESENT     -> Use present_files tool to deliver the file
```

## Document Structure

The output Word document contains these sections in order:

1. **Meeting Information** — Date, duration, attendees, meeting type (table format)
2. **Action Items** — 4-column table: Action | Owner | Deadline | Status
3. **Key Decisions** — Bulleted list of decisions made
4. **Discussion Summary** — Narrative summary of main topics covered
5. **Next Steps** — Numbered list of follow-ups and next meeting info

## Extraction Logic

When reading the transcript, look for these signals:

**Action items**: Keywords like "will do", "assigned to", "follow up", "action item", "by [date]", "[Name] to [verb]"

**Decisions**: Keywords like "decided", "agreed", "we'll go with", "confirmed", "resolved", "conclusion"

**Attendees**: Speaker names at the start of transcript lines (e.g., "John Smith: ...")

**Deadlines**: Date mentions near action item keywords

## Implementation

```python
# Install: pip install python-docx --break-system-packages
from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from datetime import datetime

# Read transcript
with open('/mnt/user-data/uploads/transcript.txt', 'r') as f:
    transcript = f.read()

# --- Parse transcript (adapt based on actual content) ---
# Extract speaker names from lines like "Speaker Name: ..."
import re
speakers = list(set(re.findall(r'^([A-Z][a-z]+ [A-Z][a-z]+):', transcript, re.MULTILINE)))

# Action items — look for action keywords and extract surrounding context
action_items = []  # Populate by scanning transcript for action keywords

# Decisions — look for decision keywords
decisions = []  # Populate by scanning transcript for decision keywords

# --- Build Word Document ---
doc = Document()

# Title
title = doc.add_heading('Meeting Minutes', 0)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Meeting Information table
doc.add_heading('Meeting Information', level=1)
info_table = doc.add_table(rows=4, cols=2)
info_table.style = 'Light Grid Accent 1'
info_data = [
    ('Date:', datetime.now().strftime('%B %d, %Y')),
    ('Attendees:', ', '.join(speakers) if speakers else 'See transcript'),
    ('Duration:', '[Extract from transcript]'),
    ('Meeting Type:', '[Extract from transcript]'),
]
for i, (key, value) in enumerate(info_data):
    info_table.rows[i].cells[0].text = key
    info_table.rows[i].cells[1].text = value

# Action Items table
doc.add_heading('Action Items', level=1)
action_table = doc.add_table(rows=1, cols=4)
action_table.style = 'Medium Shading 1 Accent 1'
for i, header in enumerate(['Action', 'Owner', 'Deadline', 'Status']):
    cell = action_table.rows[0].cells[i]
    cell.text = header
    cell.paragraphs[0].runs[0].bold = True

for action, owner, deadline, status in action_items:
    row = action_table.add_row()
    row.cells[0].text = action
    row.cells[1].text = owner
    row.cells[2].text = deadline
    row.cells[3].text = status

# Key Decisions
doc.add_heading('Key Decisions', level=1)
for decision in decisions:
    p = doc.add_paragraph(style='List Bullet')
    p.text = decision

# Discussion Summary
doc.add_heading('Discussion Summary', level=1)
doc.add_paragraph('[Write 2-3 sentence summary of main topics and outcomes]')

# Next Steps
doc.add_heading('Next Steps', level=1)
doc.add_paragraph('1. All action item owners to provide updates by next meeting')
doc.add_paragraph('2. Next meeting: [date from transcript or TBD]')

doc.save('/mnt/user-data/outputs/meeting_minutes.docx')
print("Done!")
```

## How to Trigger

- "Extract action items from this Zoom transcript"
- "Turn this meeting transcript into meeting notes"
- "Create meeting minutes from this Teams recording"
- "Summarize this meeting and list all action items with owners"

## Rules

- Always read `/mnt/skills/public/docx/SKILL.md` first for Word document best practices
- If the transcript doesn't clearly identify owners for action items, flag them as "TBD"
- If no deadlines are mentioned, use "To be confirmed"
- Never invent action items or decisions — only extract what's in the transcript
- Save to `/mnt/user-data/outputs/` and use `present_files` to deliver
