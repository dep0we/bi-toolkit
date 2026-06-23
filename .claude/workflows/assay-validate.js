export const meta = {
  name: 'assay-validate',
  description: 'Phase 7/8 of the assay loop. Reconciles results to source-of-truth and scores confidence (how sure the answer is right), data completeness (how much relevant data was present), methodology soundness (whether the approach survives expert review), and reproducibility (can someone re-run the same work). Blocks below threshold (minimum allowed score).',
  phases: [
    { title: 'Reconcile' },
    { title: 'Score' },
    { title: 'Gate' },
  ],
}

// ============================================================================
// assay-validate - the back gate for analysis and data-product work.
//
// This workflow does not deliver. It reconciles results to source-of-truth,
// performs adversarial scoring, and returns a pass/block receipt.
// ============================================================================

let A = args ?? {}
if (typeof A === 'string') { try { A = JSON.parse(A) } catch { A = {} } }
const REQUEST = A.request ?? A.analysis ?? 'the current analysis request'
const ANALYSIS_ID = A.analysisId ?? A.analysis_id ?? A.id ?? 'current-analysis'
const SPEC = A.spec ?? 'the current assay spec receipt'
const RESULTS = A.results ?? A.artifacts ?? 'the current result artifacts'
const CFG = A.config ?? {}
const PROJECT = CFG.projectName ?? 'this assay project'
const SOURCE_OF_TRUTH = CFG.sourceOfTruth ?? {}
const THRESHOLDS = CFG.scoreThresholds ?? { confidence: 3, dataCompleteness: 3, methodologySoundness: 3, reproducibility: 3 }
const HIGH_STAKES = A.highStakes ?? false

const PLAIN_LANGUAGE_RULE = `Every operator-facing sentence must define technical or statistical terms inline in 4-8 words, for example "variance (difference from expected value)", and must frame choices by business consequence, not jargon.`

const RECON_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['reconciled', 'checks', 'variances', 'unreconciledResults', 'receipt'],
  properties: {
    reconciled: { type: 'boolean' },
    checks: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['result', 'sourceOfTruth', 'status', 'evidence'],
        properties: {
          result: { type: 'string' },
          sourceOfTruth: { type: 'string' },
          status: { type: 'string', enum: ['matched', 'accepted-variance', 'unmatched', 'not-checked'] },
          evidence: { type: 'string' },
        },
      },
    },
    variances: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['result', 'amount', 'reason', 'accepted'],
        properties: {
          result: { type: 'string' },
          amount: { type: 'string' },
          reason: { type: 'string' },
          accepted: { type: 'boolean' },
        },
      },
    },
    unreconciledResults: { type: 'array', items: { type: 'string' } },
    receipt: { type: 'string', description: 'plain-language validation receipt text' },
  },
}

const SCORE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['scores', 'overallRationale', 'blockingConcerns'],
  properties: {
    scores: {
      type: 'object',
      additionalProperties: false,
      required: ['confidence', 'dataCompleteness', 'methodologySoundness', 'reproducibility'],
      properties: {
        confidence: {
          type: 'object',
          additionalProperties: false,
          required: ['score', 'reason'],
          properties: { score: { type: 'number' }, reason: { type: 'string' } },
        },
        dataCompleteness: {
          type: 'object',
          additionalProperties: false,
          required: ['score', 'reason'],
          properties: { score: { type: 'number' }, reason: { type: 'string' } },
        },
        methodologySoundness: {
          type: 'object',
          additionalProperties: false,
          required: ['score', 'reason'],
          properties: { score: { type: 'number' }, reason: { type: 'string' } },
        },
        reproducibility: {
          type: 'object',
          additionalProperties: false,
          required: ['score', 'reason'],
          properties: { score: { type: 'number' }, reason: { type: 'string' } },
        },
      },
    },
    overallRationale: { type: 'string' },
    blockingConcerns: { type: 'array', items: { type: 'string' } },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'dimension', 'issue', 'fix'],
        properties: {
          severity: { type: 'string', enum: ['P0', 'P1', 'P2'] },
          dimension: { type: 'string', enum: ['confidence', 'data-completeness', 'methodology-soundness', 'reproducibility', 'plain-language', 'source-of-truth'] },
          issue: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

phase('Reconcile')
const reconciliation = await agent(
  `Act as the Sonnet reconciler worker for ${PROJECT}. Reconcile every reported result to source-of-truth (authoritative system used to verify).
REQUEST: ${REQUEST}
SPEC: ${SPEC}
RESULTS OR ARTIFACTS: ${JSON.stringify(RESULTS)}
SOURCE OF TRUTH MAP: ${JSON.stringify(SOURCE_OF_TRUTH)}

For each result, identify the source-of-truth, rerun or inspect the needed check, record evidence, and mark unmatched or not-checked results clearly. Variance means difference from expected value; explain every variance in plain language.
${PLAIN_LANGUAGE_RULE}`,
  { schema: RECON_SCHEMA, label: 'reconcile-results', phase: 'Reconcile', model: 'sonnet' },
)

if (!reconciliation?.reconciled || reconciliation.unreconciledResults?.length) {
  log(`BLOCK: ${reconciliation?.unreconciledResults?.length ?? 0} result(s) unreconciled`)
  return {
    request: REQUEST,
    analysisId: ANALYSIS_ID,
    status: 'blocked',
    gate: 'validationcheck',
    highStakes: HIGH_STAKES,
    reconciliation,
    validationReceipt: {
      kind: 'validation',
      reconciled: false,
      reconciliation: reconciliation?.receipt ?? reconciliation?.checks ?? 'Reconciliation did not complete.',
      checks: reconciliation?.checks ?? [],
      variances: reconciliation?.variances ?? [],
      unreconciledResults: reconciliation?.unreconciledResults ?? ['reconciliation did not complete'],
    },
    scores: null,
    blockers: reconciliation?.unreconciledResults ?? ['reconciliation did not complete'],
    note: 'Validation blocked because at least one result does not tie to source-of-truth. Nothing delivered.',
  }
}

phase('Score')
const score = await agent(
  `Score this result on the assay rubric from 1-5. Use plain language.
REQUEST: ${REQUEST}
SPEC: ${SPEC}
RECONCILIATION RECEIPT: ${reconciliation.receipt}
CHECKS: ${JSON.stringify(reconciliation.checks, null, 2)}
VARIANCES: ${JSON.stringify(reconciliation.variances, null, 2)}

Dimensions:
- confidence: how sure we are the answer is right, considering sample size (how many records), noise (random movement), and sensitivity (how much the result changes when assumptions move).
- dataCompleteness: how much relevant data we had and which gaps remain.
- methodologySoundness: whether the approach would survive an expert read.
- reproducibility: whether someone else could re-run this and get the same number.

${PLAIN_LANGUAGE_RULE}`,
  { schema: SCORE_SCHEMA, label: 'score-results', phase: 'Score', model: 'opus' },
)

const redTeam = await agent(
  `Act as the Sonnet red-teamer worker. Attack the validation receipt and score.
REQUEST: ${REQUEST}
SPEC: ${SPEC}
RECONCILIATION: ${JSON.stringify(reconciliation)}
SCORE: ${JSON.stringify(score)}

Find any overclaim, missing source-of-truth check, weak method, data gap, or reproducibility gap. P0/P1 blocks delivery; P2 reports non-blocking improvements.
${PLAIN_LANGUAGE_RULE}`,
  { schema: REVIEW_SCHEMA, label: 'red-team-score', phase: 'Score', model: 'sonnet' },
)

phase('Gate')
const scores = score?.scores ?? {}
const belowThreshold = [
  ['confidence', scores.confidence?.score, THRESHOLDS.confidence ?? 3],
  ['data-completeness', scores.dataCompleteness?.score, THRESHOLDS.dataCompleteness ?? 3],
  ['methodology-soundness', scores.methodologySoundness?.score, THRESHOLDS.methodologySoundness ?? 3],
  ['reproducibility', scores.reproducibility?.score, THRESHOLDS.reproducibility ?? 3],
].filter(([, actual, threshold]) => typeof actual !== 'number' || actual < threshold)

const blockingFindings = (redTeam?.findings ?? []).filter(f => f.severity === 'P0' || f.severity === 'P1')

const validationReceipt = {
  kind: 'validation',
  reconciled: true,
  reconciliation: reconciliation.receipt ?? reconciliation.checks,
  checks: reconciliation.checks ?? [],
  variances: reconciliation.variances ?? [],
}

const adversarialReviewReceipt = {
  kind: 'adversarial-review',
  scores: {
    confidence: scores.confidence?.score,
    dataCompleteness: scores.dataCompleteness?.score,
    methodologySoundness: scores.methodologySoundness?.score,
    reproducibility: scores.reproducibility?.score,
  },
  rationale: score?.overallRationale ?? '',
  blockingConcerns: score?.blockingConcerns ?? [],
  redTeamFindings: redTeam?.findings ?? [],
}

if (belowThreshold.length || blockingFindings.length) {
  log(`BLOCK: ${belowThreshold.length} score dimension(s) below threshold and ${blockingFindings.length} blocking red-team finding(s)`)
  return {
    request: REQUEST,
    analysisId: ANALYSIS_ID,
    status: 'blocked',
    gate: 'validationcheck',
    highStakes: HIGH_STAKES,
    reconciliation,
    validationReceipt,
    scores: score,
    adversarialReviewReceipt,
    redTeam,
    belowThreshold: belowThreshold.map(([dimension, actual, threshold]) => ({ dimension, actual: actual ?? null, threshold })),
    blockingFindings,
    note: 'Validation blocked because the result is below the assay score threshold (minimum allowed score) or failed adversarial review (review that attacks the answer). Nothing delivered.',
  }
}

return {
  request: REQUEST,
  analysisId: ANALYSIS_ID,
  status: 'passed',
  gate: 'validationcheck',
  highStakes: HIGH_STAKES,
  reconciliation,
  validationReceipt,
  scores: score,
  adversarialReviewReceipt,
  redTeam,
  belowThreshold: [],
  blockingFindings: [],
  note: 'Validation passed. This is a validation receipt only; delivery still requires the delivery stage.',
}
