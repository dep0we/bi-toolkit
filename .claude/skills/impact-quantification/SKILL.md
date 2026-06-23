---
name: impact-quantification
description: Estimate and communicate the business impact of analytical findings. Use when sizing opportunities, comparing recommended actions, calculating ROI (return compared with investment), or prioritizing next steps by business value.
---

# Impact Quantification

Used in the assay lifecycle at: Stage 9 (shared)

## Quick Start

Estimate the practical value of an insight or recommendation in plain language: money saved or gained, time saved, risk reduced, customers affected, and what happens if the team does nothing.

## Context Requirements

Before quantifying impact, collect:

1. **Insight or recommendation**: What changed, what was found, or what action is being considered.
2. **Impact categories**: Which outcomes matter: revenue, cost, time, risk, customer experience, compliance, or operational effort.
3. **Sizing method**: How the estimate will be calculated, including the formula and the source for each input.
4. **Assumptions**: Inputs that are believed but not fully proven; explain the consequence if each is wrong.
5. **Thresholds**: What level of impact changes the decision.

## Context Gathering

If context is missing, ask only for what blocks the estimate.

### For Insight or Recommendation

"What insight or action should I size? Please include the metric affected, the audience that will act on it, and the decision this estimate should support."

### For Impact Categories

"Which business outcomes should this estimate include: revenue, cost, time, risk, customer experience, or something else? I will state the consequence for each category so the tradeoff is clear."

### For Sizing Method

"How should the impact be calculated? If you do not have a formula, I can propose one and label each assumption, which means an input we are using before it is fully proven."

### For Assumptions and Thresholds

"What assumptions should I use, and what impact level would make this worth acting on? For example, '$50K annual savings' or 'reduces monthly manual work by 20 hours.'"

### Handling Partial Context

If only partial context is available:
- Proceed with the available inputs and mark every missing input.
- Use conservative defaults only when the consequence is clear.
- Show a range when one exact number would overstate certainty.
- Ask for stakeholder confirmation before treating the estimate as final.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] The recommendation or insight is specific enough to size.
- [ ] The affected business outcome is clear.
- [ ] Each input has a source or is labeled as an assumption.
- [ ] The estimate will support a named decision.

### Step 2: Choose the Sizing Method

Frame the choice by consequence:
- **Direct value**: Use when the action clearly changes dollars, hours, or volume.
- **Avoided loss**: Use when the action prevents churn, errors, refunds, rework, or risk.
- **Scenario range**: Use when inputs are uncertain; show low, expected, and high cases.
- **Break-even**: Use when deciding whether the benefit is large enough to justify effort.

Define any term inline. Examples: ROI (return compared with investment), sensitivity analysis (testing if assumptions change the answer), confidence (how sure the evidence is).

### Step 3: Calculate and Check

1. List the formula in business words.
2. Tie each input to a source-of-truth (official system for this metric) when available.
3. Calculate base case, conservative case, and upside case when uncertainty matters.
4. Check whether the result changes the recommendation.
5. Note any weak input that could reverse the decision.

### Step 4: Synthesize Findings

Present:
- The headline impact.
- The decision consequence.
- The biggest assumption.
- The confidence level, defined as how sure evidence supports answer.
- Recommended next action.

### Step 5: Iterate Based on Feedback

When stakeholders challenge the estimate:
- Update only the disputed input.
- Show how the decision changes, if it does.
- Keep prior versions in the decision record when the estimate supports a gated assay decision.

## Context Validation

Before publishing:
- [ ] No unsupported exact numbers are presented as facts.
- [ ] Assumptions are visible.
- [ ] Ranges are used where uncertainty is meaningful.
- [ ] The estimate names the action it supports.
- [ ] The result is plain enough for a BI operator to repeat.

## Output Template

```markdown
# Impact Quantification

Generated: [timestamp]

## Decision Supported
- Decision: [what this estimate helps decide]
- Recommendation sized: [action or insight]
- Audience: [who will act]

## Headline Impact
- Expected value: [amount, time, risk, or customer effect]
- Conservative case: [lower estimate]
- Upside case: [higher estimate]
- Consequence: [what changes if the team acts]

## Method
- Formula in plain language: [input x input = impact]
- ROI (return compared with investment): [if applicable]
- Source-of-truth (official system for this metric): [system or file]

## Inputs and Assumptions
| Input | Value | Source | If wrong, consequence |
|---|---:|---|---|
| [input] | [value] | [source] | [impact on decision] |

## Findings
1. [Finding] - [business consequence]
2. [Finding] - [business consequence]
3. [Finding] - [business consequence]

## Recommendation
- Action: [recommended action]
- Expected outcome: [business result]
- Confidence (how sure evidence supports answer): [low/medium/high]

## Limitations
- [limitation or missing input]
- [what would improve the estimate]

## Next Steps
1. [confirm assumption]
2. [run follow-up analysis or act]
```

## Common Context Gaps & Solutions

**Scenario: User asks for impact without business context**  
Response: "I can size this, but I need the decision it supports and the outcome that matters most. Without that, I can only produce a generic estimate."

**Scenario: Partial inputs are available**  
Response: "I will produce a range and label the missing inputs. That keeps the estimate useful without pretending the unknowns are settled."

**Scenario: Objectives are unclear**  
Response: "What decision will this inform, and what impact level would change that decision?"

**Scenario: Technical terms appear**  
Response: "I will define each term inline, such as confidence (how sure evidence supports answer), before using it."

## Advanced Options

After the basic estimate, offer:
- **Scenario range**: Show low, expected, and high outcomes.
- **Sensitivity analysis (testing if assumptions change the answer)**: Identify which assumption matters most.
- **Break-even point**: Show the minimum impact needed to justify action.
- **Comparison table**: Rank multiple options by impact and effort.
