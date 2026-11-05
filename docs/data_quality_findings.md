# Data quality findings

This document records what the pipeline's data quality tests found in the CMS DE-SynPUF
Sample 1 data, and how each finding was handled.

**Latest full run (`dbt build`):** 60 nodes: 57 passed, 3 warnings, 0 errors, 0 skipped.
**Claims in `fct_claims`:** 857,563 claim segments (inpatient + outpatient).

---

## Testing strategy

Quality checks run at three layers:

| Layer | Tool | What it checks | On failure |
|---|---|---|---|
| Bronze | PySpark (`pipeline_core.quality`) | Required columns present, key columns not null or blank, minimum row counts | Ingestion run fails and is logged to `bronze.ingestion_log` |
| Silver / Gold | dbt generic tests | Uniqueness, not-null, accepted values, relationships between facts and dimensions, value ranges | Build fails (error) or reports (warn) |
| Gold | dbt singular tests | Business rules, SCD2 integrity, payment reconciliation, rate monitoring | Build fails (error) or reports (warn) |

---

## Summary of findings

| Check | Layer | Result | Rows affected | % of claims | Decision |
|---|---|---|---|---|---|
| Claims with no service dates | Silver (not_null) | WARN | 11,321 (11,253 outpatient, 68 inpatient) | 1.32% | Kept and mapped to an "Unknown" date member. See Finding 1. |
| Negative claim payments | Gold (accepted_range) | WARN | 2,621 (−$113,950 total) | 0.31% | Kept as likely adjustments or reversals. See Finding 2. |
| Payment reconciliation (staging vs. fact) | Gold (singular) | PASS | 0 | 0% | Every staged payment is present in `fct_claims` exactly once. |
| Undated claim rate below 2% | Gold (singular) | PASS | — | 1.32% | Monitoring threshold not breached. |
| Claims dated after death | Gold (singular) | PASS | 0 | 0% | No conflicts between claim dates and recorded death dates. |
| Claim end date before start date | Gold (singular) | PASS | 0 | 0% | All dated claims have valid date ranges. |
| SCD2: no overlapping beneficiary versions | Gold (singular) | PASS | 0 | 0% | Version date ranges are consistent. |
| SCD2: exactly one current version per beneficiary | Gold (singular) | PASS | 0 | 0% | Version history is complete. |
| Every claim linked to a beneficiary | Gold (not_null) | PASS | 0 | 0% | Point-in-time join plus current-version fallback covers all claims. |
| Claim keys unique | Gold (unique) | PASS | 0 | 0% | No duplicate claim segments. |

---

## Finding 1: Claims with no service dates

**What the test found:** 11,253 outpatient and 68 inpatient claims have a null `claim_from_date`.

**Investigation:**
- The raw `CLM_FROM_DT` value is null in bronze for all 11,321 claims, so this is a source
  data gap, not a date parsing bug.
- `CLM_THRU_DT` is also null on every one of these claims, so neither date is available as a fallback.
- The claims carry real payments: about $15.2M outpatient and $1.28M inpatient.

**Options considered:**

| Option | Why not chosen |
|---|---|
| Drop the claims | Fact totals would under-report payments by ~$16.5M, and reconciliation would fail |
| Keep them with null date keys | Joins to `dim_date` would silently drop these rows, producing wrong totals without warning |
| Quarantine in a separate table | Valid, but anyone summing payments from the fact table would get incomplete totals |
| **Unknown member (chosen)** | Keeps every claim in the fact, never drops rows on join, and labels the gap explicitly |

**Decision:**
- Added an "Unknown" row to `dim_date` (`date_key = -1`), and undated claims point to it.
- Undated claims link to the beneficiary's **current** version, since a point-in-time SCD2 join needs a date.
- Added an `is_undated` flag to `fct_claims`.
- `mart_beneficiary_annual_cost` explicitly excludes undated claims, since they can't be assigned to a year.
- The staging `not_null` test is set to **warn**, so the known gap stays visible on every run.
- A monitoring test (`assert_undated_claim_rate_below_threshold`) **fails the build** if undated
  claims exceed 2%, so a new upstream problem can't hide behind the known one.

---

## Finding 2: Negative claim payments

**What the test found:** 2,621 claims (0.31%) have a negative `claim_payment_amount`, totaling −$113,950.

**Investigation:**

| Claim type | Negative claims | Total | Most negative | Average |
|---|---|---|---|---|
| Outpatient | 2,566 | −$80,410 | −$100 | −$31.34 |
| Inpatient | 55 | −$33,540 | −$8,000 | −$609.82 |

- Outpatient negatives are numerous but small and capped at −$100, consistent with routine adjustments.
- Inpatient negatives are rare but larger, consistent with reversals of hospital stay payments.

**Decision:** Kept all negative payments. In claims data, negative amounts typically represent
adjustments or recoveries of earlier overpayments; removing them would overstate total spending.
The `accepted_range` test stays at **warn** so these remain visible on every run.

---

## Why some checks warn instead of fail

Warnings are used for known, documented properties of the source data, not pipeline bugs.
Failing the build on them would block every deployment without improving the data. Errors are
reserved for conditions that indicate a real defect: duplicate keys, broken relationships, SCD2
inconsistencies, payment reconciliation mismatches, or a known issue growing beyond its expected rate.

---

## Reproducing these numbers

Run in the Databricks SQL Editor against the dev schema:

```sql
-- Undated claims
SELECT claim_type, COUNT(*) AS undated_claims, SUM(claim_payment_amount) AS total_payment
FROM workspace.dbt_dev.fct_claims
WHERE is_undated
GROUP BY claim_type;

-- Negative payments
SELECT claim_type, COUNT(*) AS negative_claims, SUM(claim_payment_amount) AS total_negative,
       MIN(claim_payment_amount) AS most_negative, ROUND(AVG(claim_payment_amount), 2) AS avg_negative
FROM workspace.dbt_dev.fct_claims
WHERE claim_payment_amount < 0
GROUP BY claim_type;

-- Total claims
SELECT COUNT(*) AS total_claims FROM workspace.dbt_dev.fct_claims;
```