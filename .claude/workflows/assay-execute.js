import { lessonBrief, lessonLoaderPrompt } from './lesson-loader.js'

export const meta = {
  name: 'assay-execute',
  description: 'Phase 6 of the assay loop. Runs the analysis to the operator rulings through Sonnet sub-agents, then performs adversarial review in rounds with plain-language and methodology rigor lenses until a clean round. Stops at PR-ready and never delivers.',
  phases: [
    { title: 'Lessons' },
    { title: 'Prep' },
    { title: 'Run' },
    { title: 'Review' },
    { title: 'Package' },
  ],
}

// ============================================================================
// assay-execute - adapted from dev-process-kit arc-execute.
//
// This workflow produces a PR-ready analysis package, not an operator delivery.
// It applies ruled methodology decisions, runs the analysis, and loops through
// adversarial review rounds until a clean round is reached.
// ============================================================================

let A = args ?? {}
if (typeof A === 'string') { try { A = JSON.parse(A) } catch { A = {} } }
const REQUEST = A.request ?? A.analysis ?? 'the current analysis request'
const SPEC = A.spec ?? 'the current assay spec receipt'
const DECISIONS = A.decisions ?? {}
const MAX_ROUNDS = Math.max(2, A.maxRounds ?? 3)
const CFG = A.config ?? {}
const PROJECT = CFG.projectName ?? 'this assay project'
const DESIGN_DOCS = CFG.designDocs ?? 'CLAUDE.md, assay.config, the spec receipt, and any analysis notes already captured'
const RULINGS = Object.entries(DECISIONS).map(([k, v]) => `  - ${k}: ${v}`).join('\n') || '  (none -- no Tier-A methodology forks)'
const SOURCE_OF_TRUTH = CFG.sourceOfTruth ?? {}
const STACK = CFG.stack ?? {}
const TEST_CMD = CFG.testCommand ? `\`${CFG.testCommand}\`` : 'the project validation commands, query dry-runs, and reconciliation checks named in assay.config'

const PLAIN_LANGUAGE_RULE = `Every operator-facing sentence must define technical or statistical terms inline in 4-8 words, for example "cohort (group tracked over time)", and must frame choices by business consequence, not jargon.`

const DEFAULT_PREP_DIMENSIONS = [
  { key: 'query-plan', prompt: 'Query plan: which data sources, joins (matching records across tables), filters, and date windows must be used.' },
  { key: 'data-quality', prompt: 'Data quality: missing values, duplicates, outliers (unusual values that can skew), freshness, and known source gaps.' },
  { key: 'methodology', prompt: 'Methodology: metric definitions, comparison groups, statistical method, threshold, and assumptions.' },
  { key: 'reconciliation', prompt: 'Reconciliation: how each result will tie to source-of-truth (authoritative system used to verify).' },
  { key: 'plain-language', prompt: 'Plain language: where the analysis needs inline definitions and consequence-first wording.' },
]
const PREP_DIMENSIONS = CFG.prepDimensions ?? DEFAULT_PREP_DIMENSIONS

const DEFAULT_REVIEW_LENSES = [
  { key: 'data-correctness', prompt: 'Find wrong numbers, broken joins (matching records across tables), bad filters, date-window mistakes, duplicate counting, or stale extracts.' },
  { key: 'methodology', prompt: 'Find weak metric definitions, invalid comparison groups, wrong statistical method, overclaiming, or assumptions that should have been escalated.' },
  { key: 'reconciliation', prompt: 'Find any result that does not tie to source-of-truth (authoritative system used to verify) or lacks a documented variance (difference from expected value).' },
  { key: 'plain-language', prompt: `Find jargon leaks and unclear operator-facing text. Enforce this rule: ${PLAIN_LANGUAGE_RULE}` },
  { key: 'shortcut-hunt', prompt: 'Assume a corner was cut. Find where the analysis took the easy path over the trustworthy path. P0/P1 blocks if it can change the answer, confidence, or stakeholder decision; P2 reports polish or maintainability only.', shortcut: true },
]
const REVIEW_LENSES = CFG.reviewLenses ?? DEFAULT_REVIEW_LENSES

const XF = CFG.crossFamily ?? {}
const XF_ENABLED = XF.enabled !== false
const XF_AVAILABLE = A.codexAvailable === true
const XF_EXEC = XF.exec ?? 'codex exec'
let crossFamilyReviewed = false

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'location', 'issue', 'fix'],
        properties: {
          severity: { type: 'string', enum: ['P0', 'P1', 'P2'] },
          location: { type: 'string' },
          issue: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

const SHORTCUT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['shortcuts'],
  properties: {
    shortcuts: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'location', 'easyPath', 'trustworthyPath', 'principleViolated'],
        properties: {
          severity: { type: 'string', enum: ['P0', 'P1', 'P2'] },
          location: { type: 'string' },
          easyPath: { type: 'string' },
          trustworthyPath: { type: 'string' },
          principleViolated: { type: 'string' },
        },
      },
    },
  },
}

const XF_REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['reviewRan', 'findings'],
  properties: {
    reviewRan: { type: 'boolean', description: 'true only if the cross-family CLI answered this round' },
    findings: FINDINGS_SCHEMA.properties.findings,
  },
}

const RUN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['summary', 'artifacts', 'queriesRun', 'assumptionsApplied', 'newTierAForks'],
  properties: {
    summary: { type: 'string' },
    artifacts: { type: 'array', items: { type: 'string' } },
    queriesRun: { type: 'array', items: { type: 'string' } },
    assumptionsApplied: { type: 'array', items: { type: 'string' } },
    newTierAForks: {
      type: 'array',
      description: 'material methodology forks encountered that were not ruled by the operator',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'why', 'options'],
        properties: {
          title: { type: 'string' },
          why: { type: 'string' },
          options: { type: 'array', items: { type: 'string' } },
        },
      },
    },
  },
}

phase('Lessons')
const LESSONS_RAW = await agent(
  lessonLoaderPrompt({ project: PROJECT, request: REQUEST, phase: 'execute' }),
  { label: 'load-active-lessons', phase: 'Lessons', model: 'sonnet' },
)
const LESSONS = lessonBrief(LESSONS_RAW)
log(LESSONS ? 'Loaded active BI lessons - injecting into prep/run/review' : 'No active BI lessons found - proceeding without lesson brief')

function crossFamilyReviewerThunk(roundNo) {
  if (!XF_ENABLED) return null
  if (XF_AVAILABLE) {
    return () => agent(
      `Cross-family methodology review, round ${roundNo}, for this analysis.
Run \`${XF_EXEC}\` with a short prompt containing the request, ruled methodology, and key result summary. Ask it to find confirmation bias (seeing what you expect), weak methodology, reconciliation gaps, and overclaiming.
REQUEST: ${REQUEST}
RULINGS:
${RULINGS}

Report findings faithfully. Set reviewRan=true only if the CLI answered. ${PLAIN_LANGUAGE_RULE}`,
      { schema: XF_REVIEW_SCHEMA, label: `review:cross-family:r${roundNo}`, phase: 'Review', model: 'sonnet' },
    )
  }
  return () => agent(
    `Fresh cold-read analysis review, round ${roundNo}. Real cross-family review did not run. Read the artifacts and source notes cold. Hunt especially for weak methodology, source-of-truth gaps, and overclaiming. Set reviewRan=false.`,
    { schema: XF_REVIEW_SCHEMA, label: `review:cold-read-no-xfamily:r${roundNo}`, phase: 'Review', model: 'opus' },
  )
}

phase('Prep')
const prep = (await parallel(PREP_DIMENSIONS.map(d => () =>
  agent(
    `Pre-run risk scan for ${PROJECT}.
REQUEST: ${REQUEST}
SPEC: ${SPEC}
STACK: ${JSON.stringify(STACK)}
SOURCE OF TRUTH: ${JSON.stringify(SOURCE_OF_TRUTH)}
OPERATOR RULINGS:
${RULINGS}
${LESSONS}

Dimension: ${d.prompt}
List concrete risks the analysis runner must handle, each with severity and fix. Empty list if none. ${PLAIN_LANGUAGE_RULE}`,
    { schema: FINDINGS_SCHEMA, label: `prep:${d.key}`, phase: 'Prep', model: 'sonnet' },
  ),
))).filter(Boolean).flatMap(r => r.findings)
log(`Prep surfaced ${prep.length} analysis risks`)

phase('Run')
const run = await agent(
  `Act as the Sonnet query-runner, eda-profiler, and reconciler workers for ${PROJECT}. Run the analysis to the operator's rulings.
REQUEST: ${REQUEST}
SPEC: ${SPEC}
STACK: ${JSON.stringify(STACK)}
SOURCE OF TRUTH: ${JSON.stringify(SOURCE_OF_TRUTH)}
OPERATOR RULINGS (fixed constraints; do not substitute easier choices):
${RULINGS}
${LESSONS}
PREP FINDINGS:
${JSON.stringify(prep, null, 2)}

Run only the ruled analysis. Profile data first, then run queries or calculations, then prepare reconciliation evidence. Use ${TEST_CMD}.

Critical stop rule: if you hit a new Tier-A methodology fork that the operator did not rule on, do not decide it. Leave that thread incomplete and record it in newTierAForks.

Produce PR-ready analysis artifacts only: reproducible notes, query names, result tables, and validation inputs. Do not write the final operator delivery.`,
  { schema: RUN_SCHEMA, label: 'run-analysis', phase: 'Run', model: 'sonnet' },
)

if (run?.newTierAForks?.length) {
  log(`HALT: analysis hit ${run.newTierAForks.length} unforeseen Tier-A fork(s)`)
  return { request: REQUEST, status: 'blocked-on-decision', newTierAForks: run.newTierAForks, run }
}

phase('Review')
log(XF_ENABLED
  ? (XF_AVAILABLE
      ? 'Cross-family reviewer enabled and reachable; adding outside methodology review to every round.'
      : 'Cross-family reviewer enabled but not reachable; using a fresh cold read and flagging that no true cross-family review ran.')
  : 'Cross-family reviewer disabled in config.')

let round = 0
let lastFix = 'initial analysis run'
const roundLog = []
let converged = false
let openFindings = []
let openShortcuts = []
let reportedP2s = []

while (round < MAX_ROUNDS) {
  round++
  const lensThunks = REVIEW_LENSES.map(l => () =>
    agent(
      `Adversarial analysis review round ${round} for ${PROJECT}. Scrutinize the most recent work: ${lastFix}.
REQUEST: ${REQUEST}
SPEC: ${SPEC}
RUN SUMMARY: ${run?.summary}
ARTIFACTS: ${(run?.artifacts ?? []).join(', ')}
${LESSONS}

Lens: ${l.prompt}
Read the analysis artifacts, query outputs, assumptions, and reconciliation notes. Report real findings only. P0/P1 blocks if it can change the number, confidence, reproducibility, or stakeholder decision. P2 reports non-blocking polish. ${PLAIN_LANGUAGE_RULE}`,
      { schema: l.shortcut ? SHORTCUT_SCHEMA : FINDINGS_SCHEMA, label: `review:${l.key}:r${round}`, phase: 'Review', model: 'opus' },
    ),
  )
  const xfThunk = crossFamilyReviewerThunk(round)
  const batch = await parallel([...lensThunks, ...(xfThunk ? [xfThunk] : [])])
  const xfRev = xfThunk ? batch[lensThunks.length] : null
  const reviews = batch.slice(0, lensThunks.length).filter(Boolean)
  if (xfRev?.reviewRan === true) crossFamilyReviewed = true

  const allFindings = [...reviews.flatMap(r => r.findings ?? []), ...(xfRev?.findings ?? [])]
  const allShortcuts = reviews.flatMap(r => r.shortcuts ?? [])
  const blocking = allFindings.filter(f => f.severity === 'P0' || f.severity === 'P1')
  const blockingShortcuts = allShortcuts.filter(s => s.severity === 'P0' || s.severity === 'P1')
  const p2s = [...allFindings.filter(f => f.severity === 'P2'), ...allShortcuts.filter(s => s.severity === 'P2')]
  const total = blocking.length + blockingShortcuts.length
  roundLog.push({ round, blocking: blocking.length, blockingShortcuts: blockingShortcuts.length, p2: p2s.length })
  openFindings = blocking
  openShortcuts = blockingShortcuts
  reportedP2s = p2s
  log(`Round ${round}: ${blocking.length} blocking findings + ${blockingShortcuts.length} blocking shortcuts + ${p2s.length} P2`)

  if (total === 0 && round >= 2) { converged = true; log(`Converged at round ${round}`); break }
  if (total === 0) continue

  const fix = await agent(
    `Round ${round} analysis convergence pass. Fix all blocking review findings together.
REQUEST: ${REQUEST}
ARTIFACTS: ${(run?.artifacts ?? []).join(', ')}
BLOCKING FINDINGS:
${JSON.stringify(blocking, null, 2)}
BLOCKING SHORTCUTS:
${JSON.stringify(blockingShortcuts, null, 2)}
NON-BLOCKING P2s:
${JSON.stringify(p2s, null, 2)}
${LESSONS}

Work as Sonnet query-runner, eda-profiler, and reconciler workers. Re-run affected queries or calculations, update artifacts, and self-check that the fix addresses the failure class. If a fix requires a new Tier-A methodology ruling, stop and return that as the only result. Do not write final delivery copy.
Return a one-line description of what changed.`,
    { label: `fix:r${round}`, phase: 'Review', model: 'sonnet' },
  )
  lastFix = fix ?? `round ${round} analysis fixes`
}

if (!converged) {
  log(`DID NOT CONVERGE after ${round} rounds`)
  return {
    request: REQUEST,
    status: 'did-not-converge',
    rulingsApplied: DECISIONS,
    artifacts: run?.artifacts ?? [],
    rounds: roundLog,
    openFindings,
    openShortcuts,
    reportedP2s,
    crossFamilyReviewed,
    note: `Review hit the ${MAX_ROUNDS}-round cap with blocking findings still open. Last changes are not clean-round verified. Nothing delivered.`,
  }
}

phase('Package')
const packageCheck = await agent(
  `Prepare the analysis package for PR review only. Confirm the artifacts include: ruled methodology decisions, query or calculation steps, result tables, source-of-truth reconciliation inputs, assumptions, and open risks.
Do not deliver to stakeholders. Enforce plain-language labels and inline definitions in any operator-facing notes.
REQUEST: ${REQUEST}
ARTIFACTS: ${(run?.artifacts ?? []).join(', ')}
${LESSONS}`,
  { schema: FINDINGS_SCHEMA, label: 'package-check', phase: 'Package', model: 'sonnet' },
)

return {
  request: REQUEST,
  status: 'pr-ready',
  rulingsApplied: DECISIONS,
  artifacts: run?.artifacts ?? [],
  queriesRun: run?.queriesRun ?? [],
  assumptionsApplied: run?.assumptionsApplied ?? [],
  rounds: roundLog,
  converged: true,
  reportedP2s,
  crossFamilyReviewed,
  packageCheckFindings: packageCheck?.findings ?? [],
  note: `Converged at round ${round}. Analysis package is PR-ready only; validation and delivery remain separate gates. Nothing delivered.`,
}
