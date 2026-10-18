# Data sources

## CMS DE-SynPUF (Sample 1)
- **Publisher:** Centers for Medicare & Medicaid Services (CMS)
- **What it is:** Synthetic Medicare claims for 2008–2010, designed to resemble real
  claims structure without containing any real patient data.
- **Files used:** Beneficiary Summary (2008, 2009, 2010), Inpatient Claims, Outpatient Claims
- **Approximate size:** ~115K beneficiaries per year, ~66K inpatient and ~790K outpatient claim records
- **Not committed to this repo:** files are downloaded from CMS and uploaded to a
  Unity Catalog volume at `/Volumes/workspace/raw/synpuf`.

## How to reproduce
1. Download the five Sample 1 files listed above from cms.gov.
https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf
2. Unzip and upload the CSVs to `/Volumes/workspace/raw/synpuf`.
3. Run the bronze ingestion job (see README).
