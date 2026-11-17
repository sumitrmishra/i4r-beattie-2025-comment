# DCAS compliance checklist

| Item | Status | Note |
|---|---|---|
| Data availability statement | PASS | In README |
| Dataset manifest (source, access, licence) | PASS | OSF data, public, redistribution permitted |
| One-command master script | PASS | `Rscript run_all.R` |
| Computational requirements stated | PASS | R version, packages, seeds and runtime (about 5 minutes) in README; versions in `output/sessionInfo.txt` |
| Every report table mapped to code | PASS | README map; Tables 1–2 are assessments without code |
| No absolute or machine-specific paths | PASS | All paths relative to `replication_package/` |
| Seeds set for every random step | PASS | 20261113 (and 62) |
| Results reproduce | PASS | Every reported value was run and checked by the author; logs in `output/logs/` |
| Code licence | PASS | MIT (`LICENSE`) |
| AI-use statement | PASS | In README |
| Confidential data | Not applicable | No personal or restricted data |
