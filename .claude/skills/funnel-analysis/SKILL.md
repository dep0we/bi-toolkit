---
name: funnel-analysis
description: Analyze multi-step journeys to measure conversion (people reaching the next step), find drop-off points, compare segments, and recommend improvements. Use for signup, checkout, onboarding, renewal, lead, or operational process funnels.
---

# Funnel Analysis

Used in the assay lifecycle at: Stage 6 (analysis)

## Quick Start

Analyze a sequence of steps to see where people, accounts, tickets, or transactions stop moving forward. Explain each drop-off by consequence: lost revenue, delayed onboarding, wasted effort, or added risk.

## Context Requirements

Before analyzing the funnel, collect:

1. **Funnel steps**: The ordered actions that define the journey.
2. **Event data**: Records showing who completed each step and when.
3. **Time window**: How long someone has to move from start to finish.
4. **Success criteria**: What counts as completing each step.
5. **Segments**: Optional comparison groups, such as channel, device, region, plan, or cohort (group tracked over time).

## Context Gathering

### For Funnel Steps

"Please define the funnel steps in order and what each one means. For example: view product, add to cart, begin checkout, enter payment, complete purchase. Which step is the final success?"

### For Event Data

"Please provide event data showing the user or entity, event name, and timestamp. A file, query, or existing table is fine. I need enough detail to tell whether each person reached each step."

### For Time Window

"How long should someone have to complete the funnel: same session, same day, seven days, thirty days, or no limit? The choice changes the count, so I will state the consequence of the window."

### For Success Criteria

"For each step, what counts as completion? For example, does 'payment' mean opening the page, submitting the form, or receiving confirmation?"

### For Segments

"Which groups should be compared? Examples: acquisition channel, device type, new versus returning users, region, plan tier, or cohort (group tracked over time)."

## Workflow

### Step 1: Load and Validate Event Data

Check:
- [ ] Event names cover every funnel step.
- [ ] Each record has a stable user or entity identifier.
- [ ] Timestamps use a known timezone.
- [ ] The data covers the requested time period.
- [ ] Duplicate events will not double count completion.

Report the loaded row count, unique entities, date range, and event names before calculating the funnel.

### Step 2: Define Funnel Configuration

Document:
- Step number.
- Business step name.
- Event or condition that marks completion.
- Time window.
- Whether steps must happen in order.

Explain the consequence of each choice. Example: "Using a 7-day window will count slower buyers; using same-session will focus only on immediate checkout friction."

### Step 3: Build Funnel Data

For each entity that reaches Step 1:
1. Find the first Step 1 timestamp.
2. Check later steps in order within the selected time window.
3. Stop counting later steps after the first missed required step.
4. Store the first completion time for each reached step.
5. Keep one row per entity for auditable counts.

### Step 4: Calculate Funnel Metrics

Calculate:
- Users or entities reaching each step.
- Conversion (people reaching the next step) from the top.
- Step-to-step conversion.
- Drop-off count.
- Drop-off rate.

Use plain labels. Example: "Step 3 lost 1,240 users, meaning 38% of people who reached checkout did not continue."

### Step 5: Visualize Funnel

Create:
- A step-by-step count chart.
- A step-to-step conversion chart.
- A segment comparison chart when segments are requested.

Use titles that state the business question, not just the metric name.

### Step 6: Analyze Drop-Off Points

Identify:
- Biggest absolute loss.
- Worst step-to-step conversion.
- Steps with acceptable performance.
- Whether the issue is concentrated in a segment.

Prioritize by consequence, not just percentage. A small percentage on a large step can matter more than a high percentage on a tiny step.

### Step 7: Time-to-Convert Analysis

For people who reach each later step, calculate:
- Median (middle value, ignores outliers) time between steps.
- 25th and 75th percentile (range around the middle) if useful.
- Long delays that suggest friction or process backlog.

### Step 8: Segment Comparison

Compare groups only when the group has enough volume to support action. Define cohort (group tracked over time), segment (group compared to others), and outlier (value far from the pattern) inline when used.

## Context Validation

Before reporting:
- [ ] Funnel steps are ordered and unambiguous.
- [ ] Event data includes every necessary step.
- [ ] Time window matches the real journey.
- [ ] Success criteria are confirmed.
- [ ] Segment comparisons have enough volume to avoid misleading conclusions.

## Output Template

```markdown
# Funnel Analysis Report

Period: [date range]
Funnel: [name]
Time window: [window and consequence]

## Funnel Overview
| Step | Reached | From top | From prior step | Drop-off |
|---|---:|---:|---:|---:|
| 1. [step] | [count] | 100% | 100% | - |
| 2. [step] | [count] | [%] | [%] | [count / %] |

## Key Findings
1. Critical drop-off: [step] lost [count], causing [business consequence].
2. Segment gap: [segment] converts [x] lower than [comparison], causing [consequence].
3. Time delay: median (middle value, ignores outliers) time from [step] to [step] is [time].

## Segment Comparison
| Segment | Started | Completed | Conversion (people reaching final step) | Consequence |
|---|---:|---:|---:|---|
| [segment] | [count] | [count] | [%] | [effect] |

## Recommendations
1. [Action] - [expected outcome]
2. [Action] - [expected outcome]
3. [Action] - [expected outcome]

## Files Generated
- [chart or table]
- [funnel rows]
- [segment comparison]

## Limitations
- [data or method limit]
- [what would improve confidence]
```

## Common Scenarios

**Signup funnel is weak**: Compare each signup step, then show which step blocks activation and what action would recover the most users.

**Checkout conversion dropped**: Check payment, shipping, device, and traffic source segments. Tie each gap to potential revenue effect.

**Onboarding takes too long**: Use time-to-convert to find where accounts stall and whether delays differ by customer type.

**Findings conflict**: Separate overall funnel results from segment results and explain which decision each view supports.

## Advanced Options

- **Cohort comparison (group tracked over time)**: Compare funnel changes by signup or start month.
- **Experiment comparison**: Compare control and variant groups when an A/B test exists.
- **Root-cause drilldown**: Inspect records around the worst step.
- **Alerting threshold**: Define when future funnel movement should trigger review.
