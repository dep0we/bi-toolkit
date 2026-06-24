# Data Safety

This policy protects BI work that uses sensitive data. Sensitive data means
personal identifying info (PII), health info (PHI), payroll, or customer
records.

The rule is simple: do not deliver or export sensitive analysis until the
audience and handling are written down.

## What Counts As Sensitive

- **PII** means personal identifying info: names, emails, phone numbers, home
  addresses, employee IDs, account IDs, or anything that can identify a person.
- **PHI** means health info: diagnosis, treatment, insurance, appointment, or
  medical record details.
- **Payroll** means pay, bonus, commission, tax, bank, salary, or benefit data.
- **Customer records** means customer-level orders, contracts, usage, support,
  renewal, billing, or contact details.
- **Internal** means company-only business data that does not identify a person,
  patient, employee pay record, or customer record.
- **None** means no sensitive or internal company data is involved.

If you are unsure, classify the work as sensitive and ask before sharing.

## Audiences

Every delivery needs a named audience. Audience means who will receive the
answer.

Examples:

- internal finance leadership;
- store operations managers;
- one named vendor under contract;
- a public slide deck.

Sensitive data should go only to people who need it for the decision. A broader
audience needs a broader reason written in the data-safety receipt.

## Row-Level Detail Vs Aggregate

Row-level detail means individual records are shown. Aggregate means grouped
summary numbers are shown.

Use aggregate whenever it answers the question. Share row-level detail only when
the decision needs individual records, such as fixing a payroll issue or
contacting affected customers.

## Exporting Extracts

Export means data leaves the analysis workspace. Examples include email
attachments, CSV files, spreadsheets, shared-drive files, BI downloads, or files
sent to a vendor.

Before exporting sensitive data, record:

- the data classification;
- the delivery audience;
- whether data leaves the company;
- the export destination;
- whether row-level detail or aggregate data is shared;
- the operator sign-off.

If data leaves the company, the destination must be on the approved export
destination list in `assay.config.jsonc`.

## External AI Providers

External AI providers are outside services that receive prompts, files, or
context.

Do not send sensitive data to an external AI provider unless the operator has
explicitly approved that destination for this work. This includes pasting rows,
uploading extracts, sharing screenshots, or placing sensitive examples in
instruction files.

Use summaries or fake examples when possible. If real sensitive data is needed,
write down why, who approved it, where it is going, and whether it is row-level
detail or aggregate.

## The Delivery Gate

`datacheck` runs before `/assay deliver`. It blocks when classification is
unknown, when sensitive data lacks a data-safety receipt, when the handling is
incomplete, or when data leaves the company for an unapproved destination.

The gate passes when the work is clearly none or internal with no sensitive
flags, or when sensitive handling has a complete operator-signed receipt.
