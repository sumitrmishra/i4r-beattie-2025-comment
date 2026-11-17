# Part 2: verification of the I4R report's claims (sections follow the report)
pacman::p_load(tidyverse, data.table, haven,
               fixest, modelsummary, tsibble,
               rstanarm, posterior, bayesplot)

dt = zap_labels(read_sav("data/Madiera data 2024.sav"))
items <- grep("^Q16_", names(dt), value = TRUE)


#---------Section 3-----------#
# The abstract's linear-versus-quadratic contrast between satisfied and less satisfied runners
dt <- dt[complete.cases(dt[items]), ]

# Keeps only runners with no missingness
# 41 runners remain, the same as in the paper.
# create the group
dt = dt |>
  mutate(id = row_number()) |>
  mutate(group = ifelse(Race_Sat == 5, 1, 0))

# linear (rise) and quadratic (hill) trend score for each runner
scores = dt |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2])) |>
  group_by(id, group) |>
  summarise(lin  = sum(coping * (time - 6)),
            quad = sum(coping * ((time - 6)^2 - 10)),
            .groups = "drop")

# do the two groups differ? (this test is not in the paper)
scores |>
  pivot_longer(c(lin, quad), names_to = "trend", values_to = "score") |>
  group_by(trend) |>
  summarise(mean_0 = mean(score[group == 0]),
            mean_1 = mean(score[group == 1]),
            t      = t.test(score ~ group, var.equal = TRUE)$statistic,
            p      = t.test(score ~ group, var.equal = TRUE)$p.value) |>
  mutate(F = t^2)

# Section 3: quadratic trend with satisfaction as a continuous score (1-5) instead of the split
scores = scores |> left_join(dt |> select(id, Race_Sat), by = "id")
summary(lm(quad ~ Race_Sat, data = scores))$coefficients

# Section 3: multivariate group-by-time test (all 10 trend shapes at once)
Y = as.matrix(select(dt, starts_with("Q16_")))
D = Y %*% contr.poly(11)
summary(manova(D ~ dt$group), test = "Wilks")


# Section 3: mixed models on all 48 runners (nlme)
long = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  mutate(id = row_number()) |>
  filter(!is.na(Race_Sat)) |>
  mutate(group = ifelse(Race_Sat == 5, 1, 0)) |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2]),
         tL = contr.poly(11)[time, 1], tQ = contr.poly(11)[time, 2],
         tf = factor(time)) |>
  filter(!is.na(coping))
contrasts(long$tf) = contr.poly(11)

fits = function(f, qname) {
  cs  = nlme::gls(f, data = long, correlation = nlme::corCompSymm(form = ~ time | id))
  ar1 = nlme::gls(f, data = long, correlation = nlme::corAR1(form = ~ time | id))
  un  = nlme::gls(f, data = long, correlation = nlme::corSymm(form = ~ time | id),
                  weights = nlme::varIdent(form = ~ 1 | time),
                  control = nlme::glsControl(msMaxIter = 200, opt = "optim"))
  qp = function(m) summary(m)$tTable[qname, "p-value"]
  c(CS = qp(cs), AR1 = qp(ar1), UN = qp(un), AIC_gap = AIC(cs) - AIC(ar1))
}
fits(coping ~ (tL + tQ) * group, "tQ:group")    # time as two trends
fits(coping ~ tf * group,        "tf.Q:group")  # time as 11 checkpoints


#---------Section 4-----------#
# Robustness table: six interactions under five inference methods
# cells: 1 OLS, 2 case bootstrap, 3 Freedman-Lane permutation, 4 HC3, 5 ordinal model (LR test)
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  mutate(ce_c = CE - mean(CE),
         mt_c = MTI - mean(MTI))

# row 1 (MT) - cell 1
m = feols(Race_Sat ~ ce_c * mt_c, data = dt)
print(m)

# row 1 - cell 2
set.seed(20261113)
# 5,000 draws (the PROCESS default)
boot1 = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  coef(lm(Race_Sat ~ ce_c * mt_c, data = s))["ce_c:mt_c"]
})
quantile(boot1, c(.025, .975))

# 10,000 draws
boot2 = replicate(10000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  coef(lm(Race_Sat ~ ce_c * mt_c, data = s))["ce_c:mt_c"]
})
quantile(boot2, c(.025, .975))

# 5,000 draws with a different seed
set.seed(62)
boot3 = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  coef(lm(Race_Sat ~ ce_c * mt_c, data = s))["ce_c:mt_c"]
})
quantile(boot3, c(.025, .975))

# row 1 - cell 3
t_int = function(y) summary(lm(y ~ ce_c * mt_c, data = dt))$coefficients["ce_c:mt_c", "t value"]
t_obs = t_int(dt$Race_Sat)

set.seed(20261113)
red  = lm(Race_Sat ~ ce_c + mt_c, data = dt)          # model without the interaction
t_fl = replicate(5000, t_int(fitted(red) + sample(resid(red))))
mean(abs(t_fl) >= abs(t_obs))                          # permutation p


# row 1 - cell 4
m  = lm(Race_Sat ~ ce_c * mt_c, data = dt)
t3 = coef(m)["ce_c:mt_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:mt_c"]
2 * pt(-abs(t3), m$df.residual)


# row 1 - cell 5
dt = dt |> mutate(sat = factor(Race_Sat, ordered = TRUE))

full = MASS::polr(sat ~ ce_c * mt_c, data = dt, Hess = TRUE)
red  = MASS::polr(sat ~ ce_c + mt_c, data = dt, Hess = TRUE)
anova(red, full)          # likelihood-ratio p

row1 = tibble(Model   = "MT",
              OLS_p   = summary(lm(Race_Sat ~ ce_c * mt_c, data = dt))$coefficients["ce_c:mt_c", 4],
              perm_p  = mean(abs(t_fl) >= abs(t_obs)),
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = anova(red, full)$`Pr(Chi)`[2],
              boot_lo = quantile(boot1, .025),
              boot_hi = quantile(boot1, .975))


# row 2 (MT, adjusted)
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI, BRS, CDRISC) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI),
         sat  = factor(Race_Sat, ordered = TRUE))

# row 2 - cell 1
f_full = Race_Sat ~ ce_c * mt_c + BRS + CDRISC
f_red  = Race_Sat ~ ce_c + mt_c + BRS + CDRISC
m = lm(f_full, data = dt)

# row 2 - cell 2
set.seed(20261113)
boot = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |> mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  coef(lm(f_full, data = s))["ce_c:mt_c"]
})

# row 2 - cell 3
t_int = function(y) { dt$y = y; summary(lm(update(f_full, y ~ .), data = dt))$coefficients["ce_c:mt_c", "t value"] }
set.seed(20261113)
red = lm(f_red, data = dt)
perm_p = mean(abs(replicate(5000, t_int(fitted(red) + sample(resid(red))))) >= abs(t_int(dt$Race_Sat)))

# row 2 - cell 4
t3 = coef(m)["ce_c:mt_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:mt_c"]

# row 2 - cell 5
ord_p = anova(MASS::polr(update(f_red, sat ~ .), data = dt, Hess = TRUE),
              MASS::polr(update(f_full, sat ~ .), data = dt, Hess = TRUE))$`Pr(Chi)`[2]

tibble(OLS_p = summary(m)$coefficients["ce_c:mt_c", 4], perm_p = perm_p,
       HC3_p = 2 * pt(-abs(t3), m$df.residual), ord_p = ord_p,
       boot_lo = quantile(boot, .025), boot_hi = quantile(boot, .975)) |> round(3)

row2 = tibble(Model   = "MT, adjusted",
              OLS_p   = summary(m)$coefficients["ce_c:mt_c", 4],
              perm_p  = perm_p,
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = ord_p,
              boot_lo = quantile(boot, .025),
              boot_hi = quantile(boot, .975))


# row 3 (CD-RISC) - cell 1
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, CDRISC) |>
  mutate(ce_c = CE - mean(CE), cd_c = CDRISC - mean(CDRISC))

m = feols(Race_Sat ~ ce_c * cd_c, data = dt)
print(m)

# row 3 - cell 2
set.seed(20261113)
boot = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), cd_c = CDRISC - mean(CDRISC))
  coef(lm(Race_Sat ~ ce_c * cd_c, data = s))["ce_c:cd_c"]
})
quantile(boot, c(.025, .975))

# row 3 - cell 3
t_int = function(y) summary(lm(y ~ ce_c * cd_c, data = dt))$coefficients["ce_c:cd_c", "t value"]
t_obs = t_int(dt$Race_Sat)

set.seed(20261113)
red  = lm(Race_Sat ~ ce_c + cd_c, data = dt)
t_fl = replicate(5000, t_int(fitted(red) + sample(resid(red))))
mean(abs(t_fl) >= abs(t_obs))


# row 3 - cell 4
m  = lm(Race_Sat ~ ce_c * cd_c, data = dt)
t3 = coef(m)["ce_c:cd_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:cd_c"]
2 * pt(-abs(t3), m$df.residual)

# row 3 - cell 5
dt = dt |> mutate(sat = factor(Race_Sat, ordered = TRUE))

full = MASS::polr(sat ~ ce_c * cd_c, data = dt, Hess = TRUE)
red  = MASS::polr(sat ~ ce_c + cd_c, data = dt, Hess = TRUE)
anova(red, full)          # likelihood-ratio p in the last column

row3 = tibble(Model   = "CD-RISC",
              OLS_p   = summary(m)$coefficients["ce_c:cd_c", 4],
              perm_p  = mean(abs(t_fl) >= abs(t_obs)),
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = anova(red, full)$`Pr(Chi)`[2],
              boot_lo = quantile(boot, .025),
              boot_hi = quantile(boot, .975))

# row 4 (CD-RISC, adjusted) - cell 1
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, CDRISC, BRS, MTI) |>
  mutate(ce_c = CE - mean(CE), cd_c = CDRISC - mean(CDRISC))

m = feols(Race_Sat ~ ce_c * cd_c + BRS + MTI, data = dt)
print(m)

# row 4 - cell 2
set.seed(20261113)
boot = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), cd_c = CDRISC - mean(CDRISC))
  coef(lm(Race_Sat ~ ce_c * cd_c + BRS + MTI, data = s))["ce_c:cd_c"]
})
quantile(boot, c(.025, .975))

# row 4 - cell 3
t_int = function(y) summary(lm(y ~ ce_c * cd_c + BRS + MTI, data = dt))$coefficients["ce_c:cd_c", "t value"]
t_obs = t_int(dt$Race_Sat)

set.seed(20261113)
red  = lm(Race_Sat ~ ce_c + cd_c + BRS + MTI, data = dt)
t_fl = replicate(5000, t_int(fitted(red) + sample(resid(red))))
mean(abs(t_fl) >= abs(t_obs))

# row 4 - cell 4
m  = lm(Race_Sat ~ ce_c * cd_c + BRS + MTI, data = dt)
t3 = coef(m)["ce_c:cd_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:cd_c"]
2 * pt(-abs(t3), m$df.residual)

# row 4 - cell 5
dt = dt |> mutate(sat = factor(Race_Sat, ordered = TRUE))

full = MASS::polr(sat ~ ce_c * cd_c + BRS + MTI, data = dt, Hess = TRUE)
red  = MASS::polr(sat ~ ce_c + cd_c + BRS + MTI, data = dt, Hess = TRUE)
anova(red, full)          # likelihood-ratio p in the last column

row4 = tibble(Model   = "CD-RISC, adjusted",
              OLS_p   = summary(m)$coefficients["ce_c:cd_c", 4],
              perm_p  = mean(abs(t_fl) >= abs(t_obs)),
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = anova(red, full)$`Pr(Chi)`[2],
              boot_lo = quantile(boot, .025),
              boot_hi = quantile(boot, .975))

# row 5 (BRS) - cell 1
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, BRS) |>
  mutate(ce_c = CE - mean(CE), brs_c = BRS - mean(BRS))

m = feols(Race_Sat ~ ce_c * brs_c, data = dt)
print(m)

# row 5 - cell 2
set.seed(20261113)
boot = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), brs_c = BRS - mean(BRS))
  coef(lm(Race_Sat ~ ce_c * brs_c, data = s))["ce_c:brs_c"]
})
quantile(boot, c(.025, .975))

# row 5 - cell 3
t_int = function(y) summary(lm(y ~ ce_c * brs_c, data = dt))$coefficients["ce_c:brs_c", "t value"]
t_obs = t_int(dt$Race_Sat)

set.seed(20261113)
red  = lm(Race_Sat ~ ce_c + brs_c, data = dt)
t_fl = replicate(5000, t_int(fitted(red) + sample(resid(red))))
mean(abs(t_fl) >= abs(t_obs))

# row 5 - cell 4
m  = lm(Race_Sat ~ ce_c * brs_c, data = dt)
t3 = coef(m)["ce_c:brs_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:brs_c"]
2 * pt(-abs(t3), m$df.residual)

# row 5 - cell 5
dt = dt |> mutate(sat = factor(Race_Sat, ordered = TRUE))

full = MASS::polr(sat ~ ce_c * brs_c, data = dt, Hess = TRUE)
red  = MASS::polr(sat ~ ce_c + brs_c, data = dt, Hess = TRUE)
anova(red, full)          # likelihood-ratio p in the last column

row5 = tibble(Model   = "BRS",
              OLS_p   = summary(m)$coefficients["ce_c:brs_c", 4],
              perm_p  = mean(abs(t_fl) >= abs(t_obs)),
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = anova(red, full)$`Pr(Chi)`[2],
              boot_lo = quantile(boot, .025),
              boot_hi = quantile(boot, .975))

# row 6 (BRS, adjusted) - cell 1
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, BRS, MTI, CDRISC) |>
  mutate(ce_c = CE - mean(CE), brs_c = BRS - mean(BRS))

m = feols(Race_Sat ~ ce_c * brs_c + MTI + CDRISC, data = dt)
print(m)

# row 6 - cell 2
set.seed(20261113)
boot = replicate(5000, {
  s = slice_sample(dt, prop = 1, replace = TRUE) |>
    mutate(ce_c = CE - mean(CE), brs_c = BRS - mean(BRS))
  coef(lm(Race_Sat ~ ce_c * brs_c + MTI + CDRISC, data = s))["ce_c:brs_c"]
})
quantile(boot, c(.025, .975))

# row 6 - cell 3
t_int = function(y) summary(lm(y ~ ce_c * brs_c + MTI + CDRISC, data = dt))$coefficients["ce_c:brs_c", "t value"]
t_obs = t_int(dt$Race_Sat)

set.seed(20261113)
red  = lm(Race_Sat ~ ce_c + brs_c + MTI + CDRISC, data = dt)
t_fl = replicate(5000, t_int(fitted(red) + sample(resid(red))))
mean(abs(t_fl) >= abs(t_obs))

# row 6 - cell 4
m  = lm(Race_Sat ~ ce_c * brs_c + MTI + CDRISC, data = dt)
t3 = coef(m)["ce_c:brs_c"] / sqrt(diag(sandwich::vcovHC(m, type = "HC3")))["ce_c:brs_c"]
2 * pt(-abs(t3), m$df.residual)


# row 6 - cell 5
dt = dt |> mutate(sat = factor(Race_Sat, ordered = TRUE))

full = MASS::polr(sat ~ ce_c * brs_c + MTI + CDRISC, data = dt, Hess = TRUE)
red  = MASS::polr(sat ~ ce_c + brs_c + MTI + CDRISC, data = dt, Hess = TRUE)
anova(red, full)          # likelihood-ratio p in the last column

row6 = tibble(Model   = "BRS, adjusted",
              OLS_p   = summary(m)$coefficients["ce_c:brs_c", 4],
              perm_p  = mean(abs(t_fl) >= abs(t_obs)),
              HC3_p   = 2 * pt(-abs(t3), m$df.residual),
              ord_p   = anova(red, full)$`Pr(Chi)`[2],
              boot_lo = quantile(boot, .025),
              boot_hi = quantile(boot, .975))


tab = bind_rows(row1, row2, row3, row4, row5, row6) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))
tab

#---------Section 5-----------#
# Coping frequency and satisfaction: the influential observation
dt = zap_labels(
  read_sav("data/Madiera data 2024.sav")
  ) |>
  mutate(id = row_number()) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x))) |>
  mutate(CF = rowMeans(pick(starts_with("Q16_"))))

r_full = cor(dt$Race_Sat, dt$CF)

loo = map_dfr(seq_len(nrow(dt)), \(i) {
  ct = cor.test(dt$Race_Sat[-i], dt$CF[-i])
  tibble(dropped = dt$id[i], r = ct$estimate, p = ct$p.value)
})

loo |> arrange(desc(abs(r - r_full)))

# complete series (n = 41)
cor.test(dt$Race_Sat, dt$CF)                        # Pearson:  -.355, p = .023
cor.test(dt$Race_Sat, dt$CF, method = "spearman")   # Spearman: -.147, p = .359
cor.test(dt$Race_Sat, dt$CF, method = "kendall")    # Kendall:  -.109, p = .376

# complete series without respondent 3 (n = 40)
dt3 = dt |> filter(id != 3)
cor.test(dt3$Race_Sat, dt3$CF)                      # Pearson:  -.205, p = .204

# all available data (n = 48)
da = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  mutate(CF = rowMeans(pick(starts_with("Q16_")), na.rm = TRUE)) |>
  filter(!is.nan(CF), !is.na(Race_Sat))
cor.test(da$Race_Sat, da$CF)                        # Pearson:  -.161, p = .274
cor.test(da$Race_Sat, da$CF, method = "spearman")   # Spearman: -.070, p = .639

# Section 5: bootstrap 95% interval for r
s5 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x))) |>
  mutate(CF = rowMeans(pick(starts_with("Q16_"))))
set.seed(20261113)
boot_r = replicate(5000, { s = slice_sample(s5, prop = 1, replace = TRUE); cor(s$Race_Sat, s$CF) })
quantile(boot_r, c(.025, .975))

# Section 5: Cook's distance (coping frequency regressed on satisfaction, as in the report)
cd = cooks.distance(lm(CF ~ Race_Sat, data = s5))
max(cd)            # .86
which.max(cd)      # the row in s5 for respondent 3

# Section 5: permutation test for the correlation (shuffle satisfaction 5,000 times)
set.seed(20261113)
r_obs = cor(s5$Race_Sat, s5$CF)
perm  = replicate(5000, cor(sample(s5$Race_Sat), s5$CF))
mean(abs(perm) >= abs(r_obs))


#---------Section 6-----------#
# Mental toughness scores above the scale maximum
dm = zap_labels(read_sav("data/Madiera data 2024.sav")) |> drop_na(MTI)

range(dm$MTI)                                      # 4.14 to 8.00
sum(dm$MTI > 7)                                    # 8 runners above 7
all(abs(dm$MTI * 7 - round(dm$MTI * 7)) < 1e-6)    # TRUE:  all multiples of 1/7
all(abs(dm$MTI * 8 - round(dm$MTI * 8)) < 1e-6)    # FALSE: not multiples of 1/8
range(round(dm$MTI * 7))                           # 29 to 56
mean(dm$MTI * 7 / 8); sd(dm$MTI * 7 / 8)           # 5.39, 0.82
# Section 6: how many scores are multiples of 1/8, and how many equal 8
sum(abs(dm$MTI * 8 - round(dm$MTI * 8)) < 1e-6)    # 8
sum(dm$MTI == 8)                                    # 2


# Section 6: rescaled MT (x 7/8), no controls
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  mutate(ce_c = CE - mean(CE),
         mt_c = MTI * 7/8 - mean(MTI * 7/8))

feols(Race_Sat ~ ce_c * mt_c, data = dt)

# Section 6: rescaled MT (x 7/8), adjusted for both resilience measures
d6 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI, BRS, CDRISC) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI * 7/8 - mean(MTI * 7/8))
feols(Race_Sat ~ ce_c * mt_c + BRS + CDRISC, data = d6)

# Section 6: simple slopes at +/- 1 SD of rescaled MT
m6 = lm(Race_Sat ~ ce_c * mt_c + BRS + CDRISC, data = d6)
V6 = vcov(m6); s6 = sd(d6$mt_c)
map_dfr(c(high = 1, low = -1), \(k) {
  w  = k * s6
  b  = coef(m6)["ce_c"] + w * coef(m6)["ce_c:mt_c"]
  se = sqrt(V6["ce_c", "ce_c"] + w^2 * V6["ce_c:mt_c", "ce_c:mt_c"] + 2 * w * V6["ce_c", "ce_c:mt_c"])
  tibble(MT = ifelse(k > 0, "high", "low"), b = b, p = 2 * pt(-abs(b / se), m6$df.residual))
})


# Section 6: cap the 8 out-of-range MT scores at 7, then refit
cap7 = function(covs = NULL) {
  d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
    drop_na(all_of(c("Race_Sat", "CE", "MTI", covs))) |>
    mutate(MTc = pmin(MTI, 7), ce_c = CE - mean(CE), mt_c = MTc - mean(MTc))
  f = as.formula(paste("Race_Sat ~", paste(c("ce_c * mt_c", covs), collapse = " + ")))
  summary(lm(f, data = d))$coefficients["ce_c:mt_c", ]
}
cap7()                        # without controls: p = .031
cap7(c("BRS", "CDRISC"))      # adjusted:         p = .055

# Section 6: drop the 8 out-of-range MT scores, then refit
dx = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  filter(MTI <= 7) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))

nrow(dx)                                   # should be 40
feols(Race_Sat ~ ce_c * mt_c, data = dx)
feols(Race_Sat ~ ce_c * mt_c + BRS + CDRISC, data = dx)   # adjusted (n = 38)


#---------Section 7-----------#
# Table 1 checkpoint means and the deposit's own labels
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x)))
items = dt |> select(starts_with("Q16_"))

tibble(item = 1:11,
       M  = round(colMeans(items), 2),
       SD = round(map_dbl(items, sd), 2))

# Section 7: the deposit's own labels for the 11 coping columns
labs = map_chr(read_sav("data/Madiera data 2024.sav") |> select(starts_with("Q16_")),
               ~ attr(.x, "label"))
labs

# Section 7: does column 6 (the peak) differ from column 7? Paired t-test, 41 runners
d7 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x)))
x6 = d7[[grep("^Q16_6", names(d7), value = TRUE)]]
x7 = d7[[grep("^Q16_7", names(d7), value = TRUE)]]
mean(x6) - mean(x7)                       # 0.07
t.test(x6, x7, paired = TRUE)$p.value     # .73


#---------Section 8-----------#
# Which sample size reproduces the paper's percentages (Participants, p. 5)?
# A percentage "fits" N if some whole number of people out of N rounds to it.
pct = c(male = 89.6, female = 10.4,
        very_comp = 4.2, competitive = 31.3, in_between = 43.8, recreational = 20.8,
        elite = 8.5, middle_pack = 85.1, back_pack = 6.4)
fits = function(N) sapply(pct, \(p) any(abs(100 * (0:N) / N - p) <= 0.05 + 1e-9))
rbind(N47 = fits(47), N48 = fits(48))


#---------Section 9-----------#
# Misprints, the power analysis and the deposit's labels
# a) Three simple-slope coefficients and one high-group F test are misprinted
raw = zap_labels(read_sav("data/Madiera data 2024.sav"))

# simple slopes of CE at +/- 1 SD of the moderator, as PROCESS computes them
ss = function(mod, covs) {
  d = raw |>
    drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  m = lm(as.formula(paste("Race_Sat ~ ce_c * w_c +", paste(covs, collapse = " + "))), data = d)
  V = vcov(m)
  s = sd(d[[mod]])
  map_dfr(c(1, -1), \(k) {
    w  = k * s
    b  = coef(m)["ce_c"] + w * coef(m)["ce_c:w_c"]
    se = sqrt(V["ce_c", "ce_c"] + w^2 * V["ce_c:w_c", "ce_c:w_c"] + 2 * w * V["ce_c", "ce_c:w_c"])
    q  = qt(.975, m$df.residual)
    tibble(model = mod, level = ifelse(k > 0, "high", "low"),
           b = b, p = 2 * pt(-abs(b / se), m$df.residual),
           lo = b - q * se, hi = b + q * se)
  })
}

bind_rows(ss("MTI",    c("BRS", "CDRISC")),
          ss("CDRISC", c("BRS", "MTI")),
          ss("BRS",    c("MTI", "CDRISC"))) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# Section 9: the satisfied group's F = 17.09, at the printed 17 df vs the correct 12 df (13 runners)
c(p_17df = pf(17.09, 1, 17, lower.tail = FALSE), eta_17df = 17.09 / (17.09 + 17),
  p_12df = pf(17.09, 1, 12, lower.tail = FALSE), eta_12df = 17.09 / (17.09 + 12))

# b) Table 2 and the Discussion carry four value errors.
raw   = zap_labels(read_sav("data/Madiera data 2024.sav"))
items = grep("^Q16_", names(raw), value = TRUE)
# the first check: coping effectiveness mean
ce48 = raw |> drop_na(CE)
ce46 = raw |> drop_na(Race_Sat, MTI, BRS, CDRISC, CE)
ce41 = raw |> filter(if_all(all_of(items), ~ !is.na(.x)))
c(all_48 = mean(ce48$CE), n46 = mean(ce46$CE), n41 = mean(ce41$CE), sd_48 = sd(ce48$CE)) |> round(3)
loo = map_dbl(seq_len(nrow(ce48)), \(i) mean(ce48$CE[-i]))
range(loo) |> round(3)
# the second check: BRS-CDRISC correlation
cor.test(raw$BRS, raw$CDRISC)                        # r = .350, df = 44, p = .017

crit_r = function(n) { t = qt(.995, n - 2); t / sqrt(t^2 + n - 2) }
c(n46 = crit_r(46), n47 = crit_r(47)) |> round(3)    # .376  .372

pf(2.68, 3, 43, lower.tail = FALSE)                  # printed F: p = .059

brs = raw |> drop_na(Race_Sat, CE, BRS) |>
  mutate(ce_c = CE - mean(CE), b_c = BRS - mean(BRS))
s = summary(lm(Race_Sat ~ ce_c * b_c, data = brs))
pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE)   # data: p = .058

# variance explained by the models
r2 = function(mod, covs = NULL) {
  d = raw |> drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  f = as.formula(paste("Race_Sat ~", paste(c("ce_c * w_c", covs), collapse = " + ")))
  summary(lm(f, data = d))$r.squared
}
c(MT     = r2("MTI"),    MT_adj     = r2("MTI",    c("BRS", "CDRISC")),
  CDRISC = r2("CDRISC"), CDRISC_adj = r2("CDRISC", c("BRS", "MTI")),
  BRS    = r2("BRS"),    BRS_adj    = r2("BRS",    c("MTI", "CDRISC"))) |> round(4)


# c) power analysis
# G*Power's "linear multiple regression: fixed model" uses a noncentral F with lambda = f2 * N
pow  = function(N, f2, u, k) { df2 = N - k - 1; 1 - pf(qf(.95, u, df2), u, df2, ncp = f2 * N) }
need = function(f2, u, k, target = .80) { N = k + 3; while (pow(N, f2, u, k) < target) N = N + 1; N }

# 1. Required N for 80% power, f2 = .15, alpha = .05
sapply(1:5, \(k) need(.15, k, k))          # whole model, 1-5 predictors: 55 68 77 85 92
need(.15, 1, 3)                            # interaction term alone:       55

# 2. Power actually achieved with N = 47 (CE, moderator, interaction = 3 predictors)
pow(47, .15, 1, 3)                         # interaction, medium effect: .74
pow(47, .15, 3, 3)                         # whole model, medium effect: .55
pow(47, .02, 1, 3)                         # interaction, small effect:  .16

# Section 9: power at the paper's n = 65 for one tested predictor
pow(65, .15, 1, 3)                         # .87


# Section 9: what the deposit itself contains (labels kept, not zapped)
lab = read_sav("data/Madiera data 2024.sav")
attr(lab$CDRISC, "labels")                 # CD-RISC value labels: 1 to 5
attr(lab$BRS, "labels")                    # BRS value labels: only two levels
length(unique(na.omit(lab$BRS)))           # 15 distinct BRS values
range(lab$BRS, na.rm = TRUE)               # 2.667 to 5
sapply(lab, \(x) class(zap_labels(x)))     # every column numeric: no text, ID or date columns


#---------Section 10----------#
# Data integrity: duplicates, structure, repeated blocks
# 1. Duplicated rows: compare every pair of runners on the cells both have observed
d10 = as.data.frame(zap_labels(read_sav("data/Madiera data 2024.sav")))
d10 = d10[rowSums(!is.na(d10)) > 0, ]                      # drop the blank row: 48 runners

pairs = combn(nrow(d10), 2)
cmp10 = map_dfr(seq_len(ncol(pairs)), \(k) {
  a = unlist(d10[pairs[1, k], ]); b = unlist(d10[pairs[2, k], ])
  both = !is.na(a) & !is.na(b)
  tibble(joint = sum(both), diff = sum(abs(a[both] - b[both]) > 1e-9))
})
cmp10 = cmp10 |> filter(joint >= 10)                        # pairs with at least 10 shared cells
nrow(cmp10)                                                 # 1,033 pairs
min(cmp10$diff)                                             # fewest differing cells: 4
sum(cmp10$diff == 0)                                        # identical pairs: 0


# 2. Not generated data: largest eigenvalue of the correlations vs shuffled data
eig_test = function(X, B = 5000) {
  X  = X[complete.cases(X), ]
  ev = function(M) max(eigen(cor(M), symmetric = TRUE, only.values = TRUE)$values)
  obs  = ev(X)
  null = replicate(B, ev(as.data.frame(lapply(X, sample))))   # shuffle each column separately
  c(n = nrow(X), largest = obs, null_max = max(null), p = (sum(null >= obs) + 1) / (B + 1))
}
set.seed(20261113)
eig_test(zap_labels(read_sav("data/Madiera data 2024.sav")) |> select(Race_Sat, MTI, BRS, CDRISC, CE))
eig_test(zap_labels(read_sav("data/Madiera data 2024.sav")) |> select(starts_with("Q16_")))

# 3. No repeated block at any offset
d10b = as.data.frame(zap_labels(read_sav("data/Madiera data 2024.sav")))
d10b = d10b[rowSums(!is.na(d10b)) > 0, ]                  # drop the blank row: 48 runners
key  = apply(d10b, 1, \(r) paste(r, collapse = "|"))       # each runner's 16 values as one string
n    = length(key)
runs = sapply(1:(n - 1), \(k) {                            # for every offset k = 1, ..., 47
  same = key[1:(n - k)] == key[(1 + k):n]                  # is runner i identical to runner i + k?
  r = rle(same); if (any(r$values)) max(r$lengths[r$values]) else 0
})
c(rows = n, offsets_checked = length(runs), longest_repeat = max(runs))