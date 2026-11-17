# Part 1: replication of the original paper's material
pacman::p_load(tidyverse, data.table, haven,
               fixest, modelsummary, tsibble,
               rstanarm, posterior, bayesplot)

dt = zap_labels(read_sav("data/Madiera data 2024.sav"))

# Table 1 of the paper (p. 7)
# (1) coping means: data vs the 10 printed in Table 1
t1 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x)))          # 41 complete series
t1_items = t1 |> select(starts_with("Q16_"))

printed_M  = c(1.41, 1.68, 1.88, 1.93, 2.20, 2.51, 2.49, 2.41, 2.29, 2.24)
printed_SD = c(.94, 1.12, 1.20, 1.17, 1.10, 1.18, 1.12, 1.16, 1.28, 1.30)

cmp = tibble(item = 1:11, M = colMeans(t1_items), SD = map_dbl(t1_items, sd)) |>
  filter(item != 6) |>                                       # Table 1 has no value for item 6
  mutate(printed_M = printed_M, printed_SD = printed_SD,
         gap_M = abs(M - printed_M), gap_SD = abs(SD - printed_SD))
cmp
c(largest_gap_M = max(cmp$gap_M), largest_gap_SD = max(cmp$gap_SD))

# (2) distance and elevation columns as printed in Table 1
gain     = c(1505, 140, 1480, 625, 900, 1310, 425, 590, 35, 20, 85)
cum_gain = c(1505, 1645, 3125, 3750, 4650, 5960, 6385, 6975, 7010, 7030, 7115)
loss     = c(380, 985, 205, 1355, 1070, 230, 705, 690, 815, 305, 395)
cum_loss = c(380, 1365, 1570, 2925, 3995, 4225, 4930, 5620, 6435, 6740, 7135)
cum_km   = c(14.5, 21.7, 32.5, 47.0, 61.0, 71.5, 80.9, 90.4, 98.9, 103.9, 115.7)

all(cumsum(gain) == cum_gain)    # gains add up
all(cumsum(loss) == cum_loss)    # losses add up
all(diff(cum_km) > 0)            # distance always increases


# Table 2 of the paper (p. 8)
# Coping frequency: only for runners who answered all 11 checkpoints
items <- grep("^Q16_", names(dt), value = TRUE)
dt$CF <- ifelse(rowSums(is.na(dt[items])) == 0, rowMeans(dt[items]), NA)
vars <- c("Race_Sat", "MTI", "BRS", "CDRISC", "CE", "CF")

# Means and SDs
round(sapply(dt[vars], function(x) c(n = sum(!is.na(x)), M = mean(x, na.rm = TRUE), SD = sd(x, na.rm = TRUE))), 2)

# Correlations, pairwise (each pair uses every runner with both values)
round(cor(dt[vars], use = "pairwise.complete.obs"), 2)

# p-values
p <- outer(vars, vars, Vectorize(function(a, b) cor.test(dt[[a]], dt[[b]])$p.value))
dimnames(p) <- list(vars, vars)
round(p, 3)


# Figure 1 and text p. 9: MT models, without and with the resilience controls
fig1 = function(covs = NULL) {
  d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
    drop_na(all_of(c("Race_Sat", "CE", "MTI", covs))) |>
    mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  full = lm(as.formula(paste("Race_Sat ~", paste(c("ce_c * mt_c", covs), collapse = " + "))), data = d)
  red  = update(full, . ~ . - ce_c:mt_c)                    # same model without the interaction
  s    = summary(full)
  cat("\nn =", nrow(d), " R2 =", round(s$r.squared, 4),
      sprintf(" F(%d,%d) = %.2f, p = %.3f", s$fstatistic[2], s$fstatistic[3], s$fstatistic[1],
              pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE)),
      " dR2 =", round(s$r.squared - summary(red)$r.squared, 3), "\n")
  print(round(cbind(b = coef(full), confint(full), p = s$coefficients[, 4]), 3))
  print(anova(red, full))                                   # F test for the interaction
}
fig1()                          # MT, no controls
fig1(c("BRS", "CDRISC"))        # MT, adjusted for both resilience measures


# Figure 1: simple slopes of CE at +/- 1 SD of MT, adjusted model
d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI, BRS, CDRISC) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
m = lm(Race_Sat ~ ce_c * mt_c + BRS + CDRISC, data = d)
V = vcov(m); q = qt(.975, m$df.residual)

map_dfr(c(high = 1, low = -1), \(k) {
  w  = k * sd(d$MTI)
  b  = coef(m)["ce_c"] + w * coef(m)["ce_c:mt_c"]
  se = sqrt(V["ce_c", "ce_c"] + w^2 * V["ce_c:mt_c", "ce_c:mt_c"] + 2 * w * V["ce_c", "ce_c:mt_c"])
  tibble(MT = ifelse(k > 0, "high", "low"), b = b, lo = b - q * se, hi = b + q * se,
         p = 2 * pt(-abs(b / se), m$df.residual))
})

# Figure 1: predicted lines from the adjusted MT model (controls at their means)
d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI, BRS, CDRISC) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
m = lm(Race_Sat ~ ce_c * mt_c + BRS + CDRISC, data = d)

pred = function(x, w) predict(m, newdata = tibble(ce_c = x, mt_c = w,
                                                  BRS = mean(d$BRS), CDRISC = mean(d$CDRISC)))
w_hi = sd(d$MTI); w_lo = -sd(d$MTI)
b_hi = coef(m)["ce_c"] + w_hi * coef(m)["ce_c:mt_c"]
b_lo = coef(m)["ce_c"] + w_lo * coef(m)["ce_c:mt_c"]

x_cross = (pred(0, w_lo) - pred(0, w_hi)) / (b_hi - b_lo)    # where the two lines cross
c(x_cross = x_cross, y_cross = pred(x_cross, w_hi))
c(span_high = 2.50 / b_hi, span_low = -0.50 / b_lo, sd_CE = sd(d$CE))   # CE range implied by the figure

# Figures 2 and 3: model checks for any moderator (text, pp. 10-11)
fig_models = function(mod, covs = NULL) {
  d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
    drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  full = lm(as.formula(paste("Race_Sat ~", paste(c("ce_c * w_c", covs), collapse = " + "))), data = d)
  red  = update(full, . ~ . - ce_c:w_c)
  s    = summary(full)
  cat("\n", mod, if (!is.null(covs)) "adjusted", " n =", nrow(d), " R2 =", round(s$r.squared, 4),
      sprintf(" F(%d,%d) = %.2f, p = %.3f", s$fstatistic[2], s$fstatistic[3], s$fstatistic[1],
              pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE)),
      " dR2 =", round(s$r.squared - summary(red)$r.squared, 3), "\n")
  print(round(cbind(b = coef(full), confint(full), p = s$coefficients[, 4]), 3))
  print(anova(red, full))
}
fig_models("CDRISC")                     # Figure 2, no controls
fig_models("CDRISC", c("BRS", "MTI"))    # Figure 2, adjusted


# Figures 2 and 3: simple slopes of CE at +/- 1 SD of the moderator (adjusted models)
slopes = function(mod, covs) {
  d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
    drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  m = lm(as.formula(paste("Race_Sat ~ ce_c * w_c +", paste(covs, collapse = " + "))), data = d)
  V = vcov(m); q = qt(.975, m$df.residual)
  map_dfr(c(high = 1, low = -1), \(k) {
    w  = k * sd(d[[mod]])
    b  = coef(m)["ce_c"] + w * coef(m)["ce_c:w_c"]
    se = sqrt(V["ce_c", "ce_c"] + w^2 * V["ce_c:w_c", "ce_c:w_c"] + 2 * w * V["ce_c", "ce_c:w_c"])
    tibble(level = ifelse(k > 0, "high", "low"), b = b, lo = b - q * se, hi = b + q * se,
           p = 2 * pt(-abs(b / se), m$df.residual))
  })
}
slopes("CDRISC", c("BRS", "MTI"))    # Figure 2


# Figures 2 and 3: plotted lines from the adjusted model (controls at their means)
fig_lines = function(mod, covs, rise_hi, rise_lo) {
  d = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
    drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  m    = lm(as.formula(paste("Race_Sat ~ ce_c * w_c +", paste(covs, collapse = " + "))), data = d)
  nd   = function(x, w) bind_cols(tibble(ce_c = x, w_c = w), summarise(d, across(all_of(covs), mean)))
  pred = function(x, w) predict(m, newdata = nd(x, w))
  w_hi = sd(d[[mod]]); w_lo = -w_hi
  b_hi = coef(m)["ce_c"] + w_hi * coef(m)["ce_c:w_c"]
  b_lo = coef(m)["ce_c"] + w_lo * coef(m)["ce_c:w_c"]
  x_cross = (pred(0, w_lo) - pred(0, w_hi)) / (b_hi - b_lo)
  c(slope_hi = b_hi, slope_lo = b_lo, x_cross = x_cross, y_cross = pred(x_cross, w_hi),
    span_hi = rise_hi / b_hi, span_lo = rise_lo / b_lo, sd_CE = sd(d$CE))
}
# Figure 2, read by eye: high line 2.27 -> 5.12 (rise 2.85), low line 3.88 -> 2.48 (fall 1.40)
fig_lines("CDRISC", c("BRS", "MTI"), 2.85, -1.40)


fig_models("BRS")                        # Figure 3, no controls
fig_models("BRS", c("MTI", "CDRISC"))    # Figure 3, adjusted


slopes("BRS", c("MTI", "CDRISC"))    # Figure 3

# Figure 3, read by eye: high line runs off the top (rise unreadable), low line 3.52 -> 2.97
fig_lines("BRS", c("MTI", "CDRISC"), NA, -0.55)


# Figure 4 and Results p. 11: change in coping frequency across the 11 checkpoints
f4 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x)))              # 41 complete series
Y  = as.matrix(select(f4, starts_with("Q16_")))
round(colMeans(Y), 2)                                            # the 11 points in Figure 4

D = Y %*% contr.poly(11)                                         # 10 trend scores per runner
summary(manova(D ~ 1), test = "Wilks", intercept = TRUE)         # overall change over time

trend = function(k) {                                            # k = 1 linear, 2 quadratic
  s = D[, k]; n = length(s); F = n * mean(s)^2 / var(s)
  c(F = F, p = pf(F, 1, n - 1, lower.tail = FALSE), eta_p2 = F / (F + n - 1))
}
trend(1); trend(2)


# Figure 5 and Results p. 13: coping-frequency trends within each satisfaction group
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


# trend within each group (what the paper reports, p. 13)
scores |>
  pivot_longer(c(lin, quad), names_to = "trend", values_to = "score") |>
  group_by(group, trend) |>
  summarise(n    = n(),
            mean = mean(score),
            t    = t.test(score)$statistic,
            p    = t.test(score)$p.value,
            .groups = "drop") |>
  mutate(F = t^2)

# Figure 5: mean coping frequency at each checkpoint, by satisfaction group
f5 = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x))) |>
  mutate(group = ifelse(Race_Sat == 5, "high", "low"))

f5 |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2])) |>
  group_by(group, time) |>
  summarise(M = mean(coping), .groups = "drop") |>
  pivot_wider(names_from = group, values_from = M)
