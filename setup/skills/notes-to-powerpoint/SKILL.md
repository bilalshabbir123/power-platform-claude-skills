---
name: notes-to-powerpoint
description: Transform rough ideas, bullet points, or text outlines into professional PowerPoint pitch decks. Create investor presentations, sales decks, or business proposals with proper structure and design. Use when the user mentions pitch deck, investor presentation, PowerPoint from notes, startup pitch, or wants to create slides from ideas.
license: MIT
compatibility: claude
metadata:
  category: productivity
---

## What I Do

Turn rough notes, bullet points, or text outlines into a polished PowerPoint (.pptx) pitch deck. Structured for investor pitches, sales presentations, or business proposals. Output is a downloadable .pptx file.

## Process

```
1. READ SKILL  -> Always read /mnt/skills/public/pptx/SKILL.md before writing any code
2. PARSE INPUT -> Read the user's notes/outline from the uploaded file or chat
3. STRUCTURE   -> Map content to standard 10-slide pitch deck format
4. BUILD DECK  -> Create each slide with professional layout and color scheme
5. SAVE        -> Output to /mnt/user-data/outputs/pitch_deck.pptx
6. PRESENT     -> Use present_files tool to deliver the file
```

## Standard Pitch Deck Structure

```
Slide 1:  Title — Company name + tagline
Slide 2:  Problem — The pain point you're solving
Slide 3:  Solution — Your answer + key benefits
Slide 4:  Product/Demo — Screenshot placeholder or key UI
Slide 5:  Market Size — TAM / SAM / SOM
Slide 6:  Business Model — Pricing, revenue streams
Slide 7:  Traction — Users, revenue, growth metrics
Slide 8:  Competition — Landscape + your differentiation
Slide 9:  Team — Founders + key hires
Slide 10: The Ask — Funding amount + use of funds
```

## Design Specification

```python
# Color scheme (professional blue)
PRIMARY   = RGBColor(31, 71, 136)   # Dark blue — headers, title slide bg
SECONDARY = RGBColor(79, 129, 189)  # Medium blue — accents
ACCENT    = RGBColor(155, 187, 89)  # Green — highlights, ask slide
TEXT      = RGBColor(51, 51, 51)    # Dark gray — body text
WHITE     = RGBColor(255, 255, 255) # White — text on dark backgrounds

# Slide dimensions
Slide width:  10 inches
Slide height: 7.5 inches

# Font sizes
Title slides:    60pt bold
Section headers: 44pt, PRIMARY color
Body text:       22-24pt
Small labels:    14pt
```

## Implementation

```python
# Install: pip install python-pptx --break-system-packages
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor

PRIMARY = RGBColor(31, 71, 136)
ACCENT = RGBColor(155, 187, 89)
WHITE = RGBColor(255, 255, 255)
TEXT = RGBColor(51, 51, 51)

prs = Presentation()
prs.slide_width = Inches(10)
prs.slide_height = Inches(7.5)

# --- Slide 1: Title (dark background) ---
slide = prs.slides.add_slide(prs.slide_layouts[6])  # Blank
bg = slide.background.fill
bg.solid()
bg.fore_color.rgb = PRIMARY

title_box = slide.shapes.add_textbox(Inches(1), Inches(2.5), Inches(8), Inches(1))
tf = title_box.text_frame
tf.text = "[Company Name]"  # Replace with actual name
tf.paragraphs[0].font.size = Pt(60)
tf.paragraphs[0].font.bold = True
tf.paragraphs[0].font.color.rgb = WHITE
tf.paragraphs[0].alignment = PP_ALIGN.CENTER

sub_box = slide.shapes.add_textbox(Inches(1), Inches(3.8), Inches(8), Inches(0.8))
tf2 = sub_box.text_frame
tf2.text = "[Tagline]"  # Replace with actual tagline
tf2.paragraphs[0].font.size = Pt(28)
tf2.paragraphs[0].font.color.rgb = WHITE
tf2.paragraphs[0].alignment = PP_ALIGN.CENTER

# --- Slides 2-9: Content slides (title + bullets) ---
def add_content_slide(prs, title_text, bullets):
    slide = prs.slides.add_slide(prs.slide_layouts[1])
    slide.shapes.title.text = title_text
    slide.shapes.title.text_frame.paragraphs[0].font.size = Pt(44)
    slide.shapes.title.text_frame.paragraphs[0].font.color.rgb = PRIMARY
    tf = slide.placeholders[1].text_frame
    tf.text = bullets[0]
    for bullet in bullets[1:]:
        p = tf.add_paragraph()
        p.text = bullet
        p.level = 1
        p.font.size = Pt(22)
    return slide

# Add content slides — populate bullets from user's notes
add_content_slide(prs, "The Problem", ["[Problem statement]", "[Pain point 1]", "[Pain point 2]"])
add_content_slide(prs, "Our Solution", ["[Solution overview]", "[Key benefit 1]", "[Key benefit 2]"])
add_content_slide(prs, "Market Opportunity", ["TAM: $[X]B", "SAM: $[X]B", "SOM: $[X]M"])
add_content_slide(prs, "Business Model", ["[Pricing tier 1]", "[Pricing tier 2]", "ARPU: $[X]/month"])
add_content_slide(prs, "Traction", ["✓ [Metric 1]", "✓ [Metric 2]", "✓ [Metric 3]"])
add_content_slide(prs, "Competition", ["[Competitor A]: [weakness]", "[Competitor B]: [weakness]", "Us: [differentiator]"])
add_content_slide(prs, "Our Team", ["[Founder 1]: [background]", "[Founder 2]: [background]"])

# --- Slide 10: The Ask (accent background) ---
slide = prs.slides.add_slide(prs.slide_layouts[6])
bg = slide.background.fill
bg.solid()
bg.fore_color.rgb = ACCENT

ask_box = slide.shapes.add_textbox(Inches(1), Inches(2), Inches(8), Inches(2))
tf = ask_box.text_frame
tf.text = "Raising $[X]M [Seed/Series A]"
tf.paragraphs[0].font.size = Pt(48)
tf.paragraphs[0].font.bold = True
tf.paragraphs[0].font.color.rgb = WHITE
tf.paragraphs[0].alignment = PP_ALIGN.CENTER

use_box = slide.shapes.add_textbox(Inches(1.5), Inches(4.5), Inches(7), Inches(1.5))
tf2 = use_box.text_frame
tf2.text = "Use of funds: [X]% Engineering | [X]% Sales & Marketing | [X]% Operations"
tf2.paragraphs[0].font.size = Pt(22)
tf2.paragraphs[0].font.color.rgb = WHITE
tf2.paragraphs[0].alignment = PP_ALIGN.CENTER

prs.save('/mnt/user-data/outputs/pitch_deck.pptx')
print("Done!")
```

## How to Trigger

- "Create a pitch deck from these notes"
- "Turn this outline into investor slides"
- "Build me a 10-slide startup pitch"
- "Make a sales deck / business proposal from this"

## Rules

- Always read `/mnt/skills/public/pptx/SKILL.md` first for best practices
- Replace ALL placeholder text with content from the user's actual notes
- If user doesn't provide info for a slide (e.g., no traction data), note it as "[To be added]" — never invent metrics
- Save to `/mnt/user-data/outputs/` and use `present_files` to deliver

## Customization

If user requests: different color scheme, more/fewer slides, speaker notes, industry-specific content, or financial projection charts — adapt accordingly before building.
