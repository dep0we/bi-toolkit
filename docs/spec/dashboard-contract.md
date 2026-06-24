# Assay Dashboard Contract

`dashboard-render.sh` reads one JSON contract and produces one static HTML
dashboard, meaning a browser page saved as a file. JSON means a structured
key-value data file. The contract is kept small so dashboards are deterministic,
meaning repeated input gives the same layout.

The schema version, meaning the contract version for the file, is
`assay-dashboard/v1`.

```json
{
  "schemaVersion": "assay-dashboard/v1",
  "analysisId": "retention-q2",
  "title": "Q2 Retention Dashboard",
  "audience": "finance leadership",
  "refreshNote": "Monthly after finance close.",
  "panels": [
    {
      "type": "kpi",
      "title": "Net retention",
      "data": {
        "label": "Net retention",
        "value": "108%",
        "delta": "+4 points versus prior quarter",
        "note": "Tied to the finance source."
      }
    },
    {
      "type": "bar",
      "title": "Revenue by segment",
      "data": {
        "labels": ["Enterprise", "Mid-market", "SMB"],
        "values": [92000, 47000, 18000],
        "source": "Finance source"
      }
    },
    {
      "type": "line",
      "title": "Retention trend",
      "data": {
        "points": [
          { "x": "2026-04", "y": 102 },
          { "x": "2026-05", "y": 105 },
          { "x": "2026-06", "y": 108 }
        ],
        "source": "Finance source"
      }
    },
    {
      "type": "table",
      "title": "Accounts to review",
      "data": {
        "columns": ["Owner", "Account", "Status"],
        "rows": [
          ["Finance", "Acme", "Reviewed"],
          ["Sales", "Northwind", "Needs follow-up"]
        ]
      }
    }
  ]
}
```

## Required Fields

- `schemaVersion`: must be `assay-dashboard/v1`.
- `analysisId`: optional in the file, but if present it must match the command.
- `title`: dashboard title.
- `audience`: approved audience for delivery.
- `refreshNote`: refresh cadence and data timing.
- `panels`: ordered dashboard sections.

## Panel Types

- `kpi`: KPI (main number watched for decisions). Data fields are `label`,
  `value`, optional `delta`, and optional `note`.
- `bar`: comparison across groups. Data can be `labels` plus `values`, or
  `items` with `label` and `value`.
- `line`: time series (values tracked over time). Data can be `points` with
  `x` and `y`, or `labels` plus `values`.
- `table`: detail rows. Data fields are `columns` and `rows`.

The renderer creates inline SVG (browser-drawn chart image format) for charts
and writes no external script or stylesheet references. Tool-specific exports
for Power BI / Tableau / Looker / Metabase are future work driven by intake;
this contract produces the universal static-HTML view, meaning a browser page
saved as a file.
