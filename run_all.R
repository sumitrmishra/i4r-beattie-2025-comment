# run_all.R -- reproduces every result in the replication report.
# Run from the replication_package/ folder:  Rscript run_all.R
# Each script's full output (code and results) is saved to output/logs/.

scripts = c("sm_1_paper_replication.R",   # Part 1: the paper's tables and figures
            "sm_2_i4r_verification.R",    # Part 2: the I4R report's claims
            "sm_3_own_work.R")            # Part 3: independent analyses

dir.create("output/logs", recursive = TRUE, showWarnings = FALSE)

for (s in scripts) {
  log = file.path("output/logs", sub("\\.R$", ".log", s))
  con = file(log, open = "wt")
  sink(con); sink(con, type = "message")
  start = Sys.time()
  ok = tryCatch({
    source(file.path("scripts/R", s), echo = TRUE, max.deparse.length = Inf, local = new.env())
    TRUE
  }, error = function(e) { message("ERROR: ", conditionMessage(e)); FALSE },
     finally = { sink(type = "message"); sink(); close(con) })
  cat(sprintf("%-28s %s  (%.1f min)\n", s, if (ok) "done" else "FAILED - see log",
              as.numeric(difftime(Sys.time(), start, units = "mins"))))
}

writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
