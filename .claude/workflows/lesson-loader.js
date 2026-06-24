export function lessonLoaderPrompt({ project, request, phase }) {
  return `Load active BI lessons for ${project} before ${phase}.
Read seed-memory/MEMORY.md first. MEMORY.md is the lesson index, meaning one bullet per lesson. Then read the seed-memory/*.md files that are most relevant to this request:
REQUEST: ${request}

Always include lessons about metric definitions (exact calculation rules), reconciliation (matching official source), methodology forks (choices that change numbers), plain language (clear words with definitions), and recurring reports when they apply.

Return a compact brief with one bullet per lesson:
- rule to apply;
- how to apply it in this run;
- file name that taught the lesson.

Use at most 10 bullets. Keep each bullet short and imperative. If seed-memory/MEMORY.md and seed-memory/*.md do not exist, return exactly: NO ACTIVE LESSONS FOUND`;
}

export function lessonBrief(raw) {
  const text = String(raw ?? '').trim();
  if (!text || /^NO ACTIVE LESSONS FOUND\b/.test(text)) return '';
  return `\nACTIVE BI LESSONS (apply these; do not repeat the warned-against mistake):\n${text}\n`;
}
