# Data sources

## CMS DE-SynPUF (Sample 1)
- **Publisher:** Centers for Medicare & Medicaid Services (CMS)
- **What it is:** Synthetic Medicare claims for 2008–2010, designed to resemble real
  claims structure without containing any real patient data.
- **Files used:** Beneficiary Summary (2008, 2009, 2010), Inpatient Claims, Outpatient Claims
- **Approximate size:** 
   inpatient_claims	 66773
   beneficiary_2009	 114538
   beneficiary_2008	 116352
   beneficiary_2010	 112754
   outpatient_claims 790790
- **Not committed to this repo:** files are downloaded from CMS and uploaded to a
  Unity Catalog volume at `/Volumes/workspace/raw/synpuf`.

## How to reproduce
1. Download the five Sample 1 files listed above from cms.gov.
https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf
2. Unzip and upload the CSVs to `/Volumes/workspace/raw/synpuf`.
3. Run the bronze ingestion job (see README).
