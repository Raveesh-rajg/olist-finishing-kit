> Historical draft/template. Use the root README for current implementation status. Unfilled or example figures below are not verified results.

# Olist finishing kit — how to use these files

1. **README_for_repo.md** → replaces the repo's README.md (fill the Tableau URL
   and cost TODO after steps 3-4).
2. **DECISIONS.md, COST_ANALYSIS.md, DATA_QUALITY_FINDINGS.md** → into the
   repo's `docs/`. Run the embedded queries in Snowsight and replace every
   TODO with the measured number.
3. **export_marts_for_tableau.sql** → run in Snowsight, download 3 CSVs.
4. **TABLEAU_DASHBOARD_SPEC.md** → build the 3 tabs in Tableau Public.
5. **RESUME_BULLETS.md** → fill [MEASURE] slots from steps 2-3, then move the
   bullets to your resume file.

Git flow per your convention: branch `docs/finishing-lap` → commit docs +
README → PR → merge → delete branch. The Tableau URL lands in a second small
PR once published.
