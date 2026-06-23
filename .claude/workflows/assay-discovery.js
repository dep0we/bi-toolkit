export const meta = {
  name: 'assay-discovery',
  description: 'Phase 5 of the assay loop. Surfaces every methodology decision fork for an analysis, tiers each A/B/C, runs a two-voice adversarial panel on Tier-A forks, and returns plain-language decision packets for the operator to rule on. Computes no results.',
  phases: [
    { title: 'Discover' },
    { title: 'Re-classify' },
    { title: 'Panel' },
  ],
}

// ============================================================================
// assay-discovery - adapted from dev-process-kit arc-discovery.
//
// This is the decision-first methodology lock for analysis work. It does no
// result computation, runs no final metric queries, and writes no deliverable.
// The output is a set of plain-language ruling packets for the operator.
// ============================================================================

let A = args ?? {}
if (typeof A === 'string') { try { A = JSON.parse(A) } catch { A = {} } }
const REQUEST = A.request ?? A.analysis ?? 'the current analysis request'
const SPEC = A.spec ?? 'the current assay spec receipt'
const CFG = A.config ?? {}

const PROJECT = CFG.projectName ?? 'this assay project'
const DESIGN_DOCS = CFG.designDocs ?? 'CLAUDE.md, assay.config, the spec receipt, and any analysis notes already captured'
const XF = CFG.crossFamily ?? {}
const XF_ENABLED = XF.enabled !== false
const XF_EXEC = XF.exec ?? 'codex exec'
const CROSS_FAMILY = A.codexAvailable === true && XF_ENABLED

const PLAIN_LANGUAGE_RULE = `Every operator-facing sentence must define technical or statistical terms inline in 4-8 words, for example "p-value (chance the result is just noise)", and must frame options by business consequence, not jargon.`

const DEFAULT_TRIPWIRES = `
A methodology decision is TIER A (operator must rule; the analyst may NOT decide it silently) if it hits ANY of:
  1. Changes the metric definition, numerator, denominator, or source-of-truth (authoritative system used to verify).
  2. Changes the population, cohort (group tracked over time), segment, filter, eligibility rule, or time window.
  3. Changes missing-data, null (blank or unknown value), duplicate, outlier (unusual value that can skew), or data-quality treatment.
  4. Changes the statistical method, model, threshold, comparison group, baseline, confidence interval (likely range around estimate), or p-value (chance result is noise).
  5. Changes whether the answer can drive money, headcount, strategy, customer commitments, or executive reporting.
  6. Uses a proxy metric (stand-in measure) because the desired metric is unavailable.
  7. Introduces an assumption stakeholders could reasonably dispute.
  8. Would change the number or conclusion a stakeholder acts on.

TIER B (analyst may decide, but must record the reason): a real fork inside an already-ruled method, such as query shape, chart choice for review, field aliasing, or minor quality treatment that cannot change the conclusion.

TIER C (analyst just does it): mechanical profiling, following an already-ruled pattern, formatting, or a single obvious choice with no effect on the answer.

TIE-BREAK: if unsure whether a fork is A or B, classify it A. Ambiguity resolves up.`

const TRIPWIRES = CFG.tripwires ?? DEFAULT_TRIPWIRES

const FORKS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['forks'],
  properties: {
    forks: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'title', 'tier', 'tripwires', 'description', 'options', 'leaning', 'principle'],
        properties: {
          id: { type: 'string', description: 'short kebab-case slug' },
          title: { type: 'string' },
          tier: { type: 'string', enum: ['A', 'B', 'C'] },
          tripwires: { type: 'array', items: { type: 'string' }, description: 'which numbered tripwires this hits, empty if none' },
          description: { type: 'string', description: 'what methodology fork the analysis faces' },
          options: { type: 'array', items: { type: 'string' }, minItems: 2 },
          leaning: { type: 'string', description: 'which option best protects trust in the answer, and why' },
          principle: { type: 'string', description: 'the named assay principle or spec rule that governs this fork' },
        },
      },
    },
  },
}

const RETIER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['rulings'],
  properties: {
    rulings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'tier', 'why'],
        properties: {
          id: { type: 'string' },
          tier: { type: 'string', enum: ['A', 'B', 'C'] },
          why: { type: 'string' },
        },
      },
    },
  },
}

const ADVISOR_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['recommendedOption', 'reasoning', 'shortcutWarning'],
  properties: {
    recommendedOption: { type: 'string' },
    reasoning: { type: 'string', description: 'why this method best protects trust in the answer' },
    shortcutWarning: { type: 'string', description: 'the tempting shortcut and how it could mislead the decision, or "none"' },
  },
}

const PACKET_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['plainTitle', 'plainFraming', 'options', 'recommendation', 'methodologyCaveat', 'agreement', 'divergenceNote'],
  properties: {
    plainTitle: { type: 'string' },
    plainFraming: { type: 'string', description: 'one or two plain sentences an operator can rule on cold' },
    options: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['label', 'consequence'],
        properties: {
          label: { type: 'string' },
          consequence: { type: 'string' },
        },
      },
    },
    recommendation: { type: 'string', description: 'the recommended option label plus one-line reason' },
    methodologyCaveat: { type: 'string', description: 'precise method term in parentheses for audit trail and future searches' },
    agreement: { type: 'string', enum: ['converge', 'diverge'] },
    divergenceNote: { type: 'string', description: 'if diverge, what the choice hinges on; else "advisors agree"' },
  },
}

phase('Discover')
const discovered = await agent(
  `Read the analysis request and the project rules in ${DESIGN_DOCS}.
REQUEST: ${REQUEST}
SPEC RECEIPT OR SPEC SUMMARY: ${SPEC}

Enumerate EVERY methodology decision fork this analysis will face before results are computed. Include metric definitions, source choices, populations, windows, treatment of missing values, outliers (unusual values that can skew), duplicates, comparison groups, statistical method, thresholds, and assumptions.

Classify each fork by this checklist:
${TRIPWIRES}

${PLAIN_LANGUAGE_RULE}
Be exhaustive about Tier A. Missing a Tier-A methodology fork means a result can look precise while resting on an unruled assumption.`,
  { schema: FORKS_SCHEMA, label: 'discover-methodology-forks', phase: 'Discover', model: 'opus' },
)
const forks = discovered?.forks ?? []
log(`Discovered ${forks.length} methodology forks (${forks.filter(f => f.tier === 'A').length} provisionally Tier A)`)

phase('Re-classify')
const retier = await agent(
  `Independently re-classify these methodology forks. Do not defer to the first reviewer.
${JSON.stringify(forks.map(f => ({ id: f.id, title: f.title, description: f.description, firstTier: f.tier })), null, 2)}

Use this checklist exactly:
${TRIPWIRES}

Your job is to catch under-escalation: forks wrongly marked B or C that could change the answer, confidence, or stakeholder action.`,
  { schema: RETIER_SCHEMA, label: 'reclassify-methodology', phase: 'Re-classify', model: 'opus' },
)

const retierById = Object.fromEntries((retier?.rulings ?? []).map(r => [r.id, r.tier]))
const RANK = { A: 3, B: 2, C: 1 }
for (const f of forks) {
  const second = retierById[f.id]
  if (second && RANK[second] > RANK[f.tier]) {
    log(`Escalated ${f.id}: ${f.tier} -> ${second} (reviewers disagreed; resolving up)`)
    f.tier = second
  }
}

const tierA = forks.filter(f => f.tier === 'A')
const tierB = forks.filter(f => f.tier === 'B')
const tierC = forks.filter(f => f.tier === 'C')

phase('Panel')
const packets = await parallel(tierA.map(fork => async () => {
  const grounded = agent(
    `You advise the operator on a material methodology decision for ${PROJECT}. Read ${DESIGN_DOCS} first.
REQUEST: ${REQUEST}
FORK TITLE: ${fork.title}
WHAT IT IS: ${fork.description}
OPTIONS: ${fork.options.join(' | ')}

Recommend the option that best protects a trustworthy analysis result. Tie the reason to the spec, source-of-truth (authoritative system used to verify), or assay principle. Name the tempting shortcut and why it could mislead the business decision.
${PLAIN_LANGUAGE_RULE}`,
    { schema: ADVISOR_SCHEMA, label: `panel:grounded:${fork.id}`, phase: 'Panel', model: 'opus' },
  )

  const skepticPrompt = CROSS_FAMILY
    ? `Run a cross-family second opinion with \`${XF_EXEC}\`. Use a short prompt with the request, fork, and options inline. Ask it to catch confirmation bias (seeing what you expect), methodology weakness, and stakeholder-risk blind spots.
REQUEST: ${REQUEST}
FORK TITLE: ${fork.title}
WHAT IT IS: ${fork.description}
OPTIONS: ${fork.options.join(' | ')}

Report its recommendation faithfully. If the CLI is unreachable or returns empty, say so and reason as an independent skeptic. ${PLAIN_LANGUAGE_RULE}`
    : `You are an independent skeptic outside this project's assumptions.
REQUEST: ${REQUEST}
FORK TITLE: ${fork.title}
WHAT IT IS: ${fork.description}
OPTIONS: ${fork.options.join(' | ')}

Assume the analyst will be tempted by the easiest method. Attack that method. Weight trustworthiness, auditability (easy to trace later), and decision risk over speed. ${PLAIN_LANGUAGE_RULE}`

  const skeptic = agent(skepticPrompt, { schema: ADVISOR_SCHEMA, label: `panel:skeptic:${fork.id}`, phase: 'Panel', model: 'sonnet' })
  const [g, s] = await Promise.all([grounded, skeptic])

  return agent(
    `Two advisors weighed in on a material methodology fork. Translate this into ONE plain-language decision packet an operator can rule on cold.
${PLAIN_LANGUAGE_RULE}

FORK: ${fork.title} -- ${fork.description}
OPTIONS: ${fork.options.join(' | ')}
GOVERNING PRINCIPLE: ${fork.principle}
PROJECT-GROUNDED ADVISOR: recommends "${g?.recommendedOption}" -- ${g?.reasoning} | shortcut warning: ${g?.shortcutWarning}
SKEPTIC ADVISOR: recommends "${s?.recommendedOption}" -- ${s?.reasoning} | shortcut warning: ${s?.shortcutWarning}

Set agreement to "converge" if both advisors point to the same option, else "diverge". If they diverge, the divergenceNote must say plainly what the operator's ruling hinges on.`,
    { schema: PACKET_SCHEMA, label: `panel:translate:${fork.id}`, phase: 'Panel', model: 'sonnet' },
  ).then(packet => ({ id: fork.id, fork, grounded: g, skeptic: s, packet }))
}))

return {
  request: REQUEST,
  codexUsed: CROSS_FAMILY,
  computedResults: false,
  tierA: packets.filter(Boolean),
  tierB: tierB.map(f => ({ id: f.id, title: f.title, options: f.options, leaning: f.leaning, principle: f.principle })),
  tierC: tierC.map(f => ({ id: f.id, title: f.title })),
}
