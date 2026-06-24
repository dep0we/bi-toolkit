# Reports And Dashboards

Deliverables are the files you give to people. The kit can render reports and dashboards after the delivery gates pass.

Previous: [Agents And Models](07-agents-and-models.md) | [Index](README.md) | Next: [Recurring And Monitoring](09-recurring-and-monitoring.md)

## Report Engine

The report engine reads a JSON report contract. JSON means structured key-value data. It always writes a self-contained HTML report, meaning a browser page saved as a file.

Type:

```bash
bash .claude/workflows/report-render.sh <analysis-id> <deliverable-json>
```

Usually Claude runs this during:

```text
/assay deliver <analysis-id>
```

What you will see:

```text
assay-report-html:.assay/deliverables/renewal-revenue-q2/report-20260624T153000Z.html
assay-report-pdf:.assay/deliverables/renewal-revenue-q2/report-20260624T153000Z.pdf
assay-report-receipt:.assay/receipts/renewal-revenue-q2-deliverable-receipt.json
```

If no PDF tool is installed:

```text
assay-report-pdf-note:No PDF renderer, meaning a tool that makes PDF files, was available. Open the HTML report and use print-to-PDF if a PDF is needed.
```

PDF means print-ready file for sharing. Print-to-PDF means using the browser print dialog to save a PDF file.

## Report Contents

The report contract supports:

- title;
- audience;
- conclusion;
- key findings;
- evidence;
- methodology (chosen analysis approach);
- caveats (limits that affect trust);
- reconciliation notes;
- score;
- figures;
- next steps.

The report is self-contained. That means it does not need outside scripts or websites to display.

## PDF Requirements

The report engine tries these PDF renderers (tools that make PDF files):

- `pandoc`;
- `wkhtmltopdf`;
- Chrome;
- Chromium.

HTML reports always work if Python 3 is available. PDF is best effort.

If PDF does not generate, open the HTML file in your browser and choose print-to-PDF.

## Dashboard Engine

The dashboard engine reads an `assay-dashboard/v1` JSON contract and writes a static HTML dashboard, meaning a browser page saved as a file.

Type:

```bash
bash .claude/workflows/dashboard-render.sh <analysis-id> <dashboard-json>
```

Usually Claude runs this during:

```text
/assay deliver <analysis-id>
```

What you will see:

```text
assay-dashboard-html:.assay/deliverables/renewal-scorecard/dashboard-20260624T153000Z.html
assay-dashboard-receipt:.assay/receipts/renewal-scorecard-deliverable-receipt.json
```

## Dashboard Panel Types

The dashboard renderer supports:

| Type | Meaning | Use it for |
| --- | --- | --- |
| `kpi` | Main number watched for decisions. | Revenue, margin, retention, backlog, risk count. |
| `bar` | Comparison across groups. | Segment, owner, location, product, channel. |
| `line` | Values tracked over time. | Trends, weekly movement, monthly totals. |
| `table` | Detail rows. | Exceptions, owners, follow-up lists. |

Charts use inline SVG (browser-drawn chart image format). They render offline without a chart library.

## Dashboard Required Fields

The dashboard contract needs:

```json
{
  "schemaVersion": "assay-dashboard/v1",
  "analysisId": "renewal-scorecard",
  "title": "Renewal Scorecard",
  "audience": "sales leadership",
  "refreshNote": "Weekly after Monday finance refresh.",
  "panels": []
}
```

`panels` must contain at least one panel.

## Branding

Brand settings live in `assay.config.jsonc`:

```json
"report": {
  "orgName": "Your Organization",
  "logoPath": "",
  "accentColor": "#2563eb",
  "footer": "Confidential - share only with the approved audience.",
  "outputFormats": ["html", "pdf"]
}
```

What each field does:

- `orgName`: name shown in the report header.
- `logoPath`: local logo image path, if any.
- `accentColor`: six-digit hex color, such as `#2563eb`.
- `footer`: confidentiality or sharing note.
- `outputFormats`: requested formats for reports.

Tool-specific exports for Power BI, Tableau, Looker, or Metabase are future work in the current repo. The verified engine today produces universal static HTML.

