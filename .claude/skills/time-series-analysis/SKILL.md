---
name: time-series-analysis
description: Analyze metrics over time, detect patterns, flag unusual movement, and produce cautious forecasts. Use during assay execution when an analysis needs trend, seasonality, anomaly, or forecast work.
---

# Time Series Analysis

Used in the assay lifecycle at: Stage 6 (shared execution)

## Quick Start

Analyze time series data, meaning values measured in time order, to find trend (longer-term direction), seasonality (repeating calendar pattern), anomalies (unexpected values needing review), and forecasts (future estimates with uncertainty). State every forecast as a planning range, not a promise.

## Context Requirements

Before analyzing time series, collect:

1. **Time series data**: values measured over time, with a date or timestamp.
2. **Time granularity**: the time bucket used, such as daily or monthly.
3. **Forecast horizon**: how far ahead the estimate will be used.
4. **Known events**: holidays, campaigns, outages, price changes, launches, or incidents that may explain movement.
5. **Business context**: what drives this metric and what decision the result will support.
6. **Source of truth**: the trusted system for the metric, so the final number can be reconciled.

## Context Gathering

### For Time Series Data

"I need historical data with timestamps:

```text
date       | metric_value
2024-01-01 | 1250
2024-01-02 | 1320
2024-01-03 | 1180
```

Regular intervals are best because gaps can make patterns look stronger or weaker than they are. For seasonality (repeating calendar pattern), aim for at least two full cycles: two years for daily or weekly patterns, and three years for monthly patterns.

What time period do you have, and are any dates missing?"

### For Granularity

"What is the natural time bucket for this decision?

- Hourly: operational volume, traffic, API calls.
- Daily: signups, revenue, sessions.
- Weekly: business operating metrics.
- Monthly: finance, subscriptions, board reporting.
- Quarterly: long-range planning.

Choose the bucket that matches how leaders act. A daily chart may distract from a monthly budget decision; a monthly chart may hide an operations problem."

### For Forecast Horizon

"How far ahead will this forecast be used?

- Short-term, 1-7 days: staffing and operations.
- Medium-term, 1-3 months: budget and pipeline planning.
- Long-term, 6-12 months: strategy, with wider uncertainty.

Forecast accuracy usually falls as the horizon gets longer, so longer forecasts need wider planning buffers."

### For Known Patterns and Events

"What known events or repeating patterns affect this metric?

- Day of week, month-end, quarter-end, fiscal-year timing.
- Holidays, campaigns, pricing changes, launches, outages.
- External factors such as weather, market changes, or competitor activity.

If we do not account for these, the model may mistake a known event for a true business shift."

## Workflow

### Step 1: Load and Inspect the Series

Load the data, sort by date, confirm the inferred frequency (detected time spacing), count missing periods, and plot the raw series.

Checkpoint with the operator: "The date range is [start] to [end], with [count] observations and [gap count] missing periods. Is this the right history for the decision?"

### Step 2: Check Stability Before Modeling

Test stationarity (whether the pattern stays broadly stable) with the Augmented Dickey-Fuller test, a stability test for time series. Define p-value inline as "chance the result is just noise" whenever reporting it.

Use the result by consequence:

- Stable enough: model changes around a steady baseline.
- Not stable: trend or seasonality may need differencing (compare each value to a prior value) or detrending (remove the long-term direction).

Do not present the test as a pass/fail decision by itself; explain what it changes about the forecast approach.

### Step 3: Decompose the Pattern

Break the series into:

- Trend (longer-term direction).
- Seasonality (repeating calendar pattern).
- Residual (leftover movement after trend and seasonality).

Quantify whether trend or seasonality is strong enough to affect the decision. A strong weekly pattern can change staffing plans; a weak pattern may not justify a separate adjustment.

### Step 4: Detect Anomalies

Use at least one practical anomaly method:

- IQR, interquartile range (middle-half spread), for unusual values.
- MAD, median absolute deviation (typical distance from middle), for robust outlier checks.
- Residual checks, meaning leftover movement after known patterns, for event-driven spikes or drops.

List anomaly dates, values, and likely explanations. Separate data-quality issues from real business events because the consequence is different: fix bad data, but investigate real movement.

### Step 5: Build the Forecast

Start with a simple baseline such as moving average or seasonal naive, then use ARIMA (time-series model using past values) or another appropriate model when the data supports it.

Hold out recent history as a test period. Report:

- MAE, mean absolute error (average miss size).
- RMSE, root mean squared error (penalizes large misses).
- MAPE, mean absolute percentage error (average percent miss), only when values are not near zero.
- AIC, model fit penalty score, only as a model-comparison detail, not a business conclusion.

If a simple model performs about as well as a complex one, prefer the simple model because it is easier to explain and maintain.

### Step 6: Show Forecast Uncertainty

Visualize historical data, forecast, and confidence interval (likely range around estimate). Translate uncertainty into business planning language:

- Narrow range: can plan closer to the forecast.
- Moderate range: use the forecast with a buffer.
- Wide range: use as direction only, not as a target.

### Step 7: Generate Insights and Recommendations

Summarize:

1. Direction: growing, declining, or stable.
2. Repeating pattern: what calendar behavior matters.
3. Anomalies: which dates need follow-up.
4. Forecast: likely range and confidence.
5. Decision consequence: what the operator should do differently.

Save useful artifacts such as a time-series plot, decomposition chart, anomaly list, forecast chart, forecast table, and model notes.

## Context Validation

Before proceeding, verify:

- [ ] Historical data covers enough cycles for the pattern being claimed.
- [ ] Missing dates and duplicate dates are understood.
- [ ] Known events are documented.
- [ ] Forecast horizon matches the decision.
- [ ] The result can be reconciled to source of truth.
- [ ] Uncertainty is reported as a range, not hidden.

## Output Template

```text
TIME SERIES ANALYSIS REPORT
Metric: [metric]
Period: [date range]
Source of truth: [system/table/report]

Historical Analysis
- Trend (longer-term direction): [summary and business meaning]
- Seasonality (repeating calendar pattern): [summary and business meaning]
- Stability check: [plain-language result; p-value (chance the result is just noise) if used]
- Anomalies (unexpected values needing review): [count and key dates]

Forecast
- Horizon: [period]
- Model: [baseline/ARIMA/other, with reason]
- Accuracy on held-out history: [MAE/RMSE/MAPE in plain language]
- Forecast range: [low to high]
- Confidence: [high/moderate/low and why]

Key Insights
1. [Observation] - [decision consequence]
2. [Observation] - [decision consequence]
3. [Observation] - [decision consequence]

Recommendations
1. [Action] - [expected outcome]
2. [Action] - [expected outcome]

Limitations and Assumptions
- [Known data gap or modeling assumption]
- [Known event not fully captured]

Files Generated
- [plot or data file]
```

## Common Scenarios

- Forecast next quarter revenue: include trend, seasonality, forecast range, and source-of-truth reconciliation.
- Detect traffic anomalies: establish baseline, flag dates, and separate outages from true demand changes.
- Explain metric change: decompose trend, seasonality, and residual movement before naming causes.
- Capacity planning: forecast expected and peak ranges, then add an uncertainty buffer.
- Compare year-over-year growth: normalize for seasonality before calling a trend real.

## Handling Missing Context

If the series has gaps, explain choices by consequence: fill gaps when continuity matters, aggregate to a wider time bucket when daily noise distracts, or stop if gaps make the result unreliable.

If history is limited, say: "With only [count] observations, the forecast range will be wide. I can produce a directional estimate, but it should not drive a high-stakes decision without more history or an explicit assumption."

