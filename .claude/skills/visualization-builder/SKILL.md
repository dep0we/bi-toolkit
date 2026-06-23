---
name: visualization-builder
description: Create clear BI visualizations and dashboard views. Use when choosing chart types, designing dashboard layouts, creating presentation visuals, or making numbers easier for business stakeholders to understand.
---

# Visualization Builder

Used in the assay lifecycle at: Stage 4d (data product) and Stage 9 (shared)

## Quick Start

Create visuals that make the decision easy to see. Start from the message, audience, and medium, then choose the chart whose consequence is clearest: fast comparison, trend detection, distribution (shape of values), relationship, or composition.

## Context Requirements

1. **Data**: measures, dimensions, time grain, sample size (number of records), and available fields.
2. **Message**: the one takeaway the visual must support.
3. **Audience**: executive, operational, technical, public, or mixed.
4. **Medium**: dashboard, slide, report, notebook, or interactive view.
5. **Brand**: color rules, formatting standards, accessibility (readable by people with different needs), and required labels.

## Context Gathering

### For Data

"What data are we visualizing?

Please include:
- Measures (numbers being compared), dimensions (ways to group), and time period.
- Grain (one row means what) and sample size (number of records).
- Required comparisons: categories, periods, cohorts (groups tracked over time), or segments (groups that behave similarly)."

### For Message

"What is the one takeaway?

Choose the closest consequence:
- Trend over time: should viewers see direction or timing?
- Group comparison: should viewers see who is higher or lower?
- Composition: should viewers see what makes up the total?
- Relationship: should viewers see two measures moving together?
- Distribution (shape of values): should viewers see spread or outliers (unusual values that distort results)?"

### For Audience

"Who will use the visual?

- **Executive**: fewer details, clear decision signal.
- **Operational**: more filters, thresholds, and exception lists.
- **Technical**: enough detail to audit calculations.
- **Public**: self-explanatory labels and no internal shorthand."

### For Medium and Brand

"Where will this appear, and what rules apply?

Please share dashboard dimensions, slide/report format, color palette, logo rules, accessibility (readable by people with different needs), and any required source notes."

## Workflow

### Step 1: Choose Chart Type

Match chart type to consequence:

| Need | Use | Avoid when |
| --- | --- | --- |
| Show change over time | Line chart | Categories are unordered |
| Compare groups | Bar chart, horizontal for many groups | Exact time trend matters |
| Show parts of a whole | Stacked bar or small multiples | Many slices make labels unreadable |
| Show relationship | Scatter plot | One value is not numeric |
| Show distribution (shape of values) | Histogram or box plot | Audience only needs totals |
| Show geography | Map plus ranked table | Location is not the decision |
| Show hierarchy | Treemap or table | Exact comparison is important |
| Show flow | Sankey or step funnel | Counts do not move through stages |

State the tradeoff in plain language: "A bar chart makes the ranking obvious; a pie chart hides small differences."

### Step 2: Design a Publication-Quality Visual

Build the visual with:
- A title that states the finding, not just the metric name.
- Axis labels with units and date range.
- Direct labels where they reduce legend scanning.
- Source note and generated date.
- Color used to show meaning, not decoration.
- Accessible contrast and no reliance on color alone.

### Step 3: Apply Visual Hierarchy

Guide attention:
- Emphasize the measure that drives the decision.
- De-emphasize reference lines, gridlines, and secondary series.
- Use annotations (short explanations on the chart) only where they clarify action.
- Keep decimal places and date formats consistent.

### Step 4: Add Context and Annotations

Add the minimum context needed to avoid misreading:
- Baseline (normal comparison point).
- Target or threshold (line that changes action).
- Data exclusions.
- Outlier notes when unusual values change the story.
- Metric definition if the label could be interpreted more than one way.

### Step 5: Create Dashboard Layout

For data products, design dashboard flow:
1. Top row: decision metrics and status.
2. Main view: trend or ranking that explains the status.
3. Drill-downs: filters, segments, or exception tables.
4. Footer: source-of-truth (official system for the number), refresh time, and owner.

Use stable positions for recurring views so operators can spot changes quickly.

## Context Validation

Before finalizing:

- [ ] The visual answers one clear question.
- [ ] The chart type matches the decision consequence.
- [ ] Labels define any technical term inline.
- [ ] Source, date range, and metric definition are visible.
- [ ] Color, scale, and axis choices do not exaggerate the result.
- [ ] Dashboard views include refresh cadence and source-of-truth.

## Output Template

```markdown
Visualization Recommendation
Generated: [timestamp]

## Context Summary
- Data:
- Audience:
- Medium:
- Key message:

## Methodology
[Chart selection approach and design checks]

## Key Findings
1. **Recommended Visual**: [Chart/dashboard view] - [Why this makes the decision clear]
2. **Main Tradeoff**: [What this chart emphasizes] - [What it hides or downplays]
3. **Required Context**: [Labels, source, caveats] - [Why viewers need it]

## Detailed Design
- Chart type:
- Encodings: [x-axis, y-axis, color, size, filters]
- Annotation plan:
- Source and refresh note:
- Accessibility checks:

## Recommendations
1. [Build action] - [Expected outcome]
2. [Review action] - [Expected outcome]

## Limitations & Assumptions
- [Data or design limitation]
- [Audience assumption]

## Next Steps
1. [Create visual]
2. [Validate with stakeholder]
```

## Common Scenarios

### Scenario 1: "Create exec presentation visual"
Use one finding-led chart, direct labels, and a short source note. Remove controls that only matter during exploration.

### Scenario 2: "Build interactive dashboard"
Prioritize stable layout, clear filters, refresh time, and validation status.

### Scenario 3: "Show comparison between groups"
Use sorted bars unless the group order has business meaning.

### Scenario 4: "Display time series with seasonality"
Use a line chart with same-period comparison, such as year-over-year, if seasonal patterns matter.

### Scenario 5: "Visualize complex relationships"
Use scatter plots, small multiples, or a table-plus-chart pair; explain correlation (two measures moving together) without implying cause.

## Handling Missing Context

If data is missing, request grain, fields, and sample size. If message is missing, ask what decision changes. If audience is missing, default to the least technical stakeholder and include audit notes separately.

## Advanced Options

- Dashboard wireframe.
- Chart critique.
- Accessibility review.
- Before/after redesign.
- Presentation-ready visual specification.
