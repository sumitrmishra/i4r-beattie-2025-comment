# Part 3: my own independent work (small-n diagnostics, Bayesian analysis, other checks)
pacman::p_load(tidyverse, data.table, haven,
               fixest, modelsummary, tsibble,
               rstanarm, posterior, bayesplot)

#-------------Independent checks (SM)------------#


#======== 1. Small-n diagnostics ========#

# 1.1 Power for the interaction
# (1) pwr package
pwr::pwr.f2.test(u = 3, v = 47 - 3 - 1, f2 = .15, sig.level = .05)$power   # whole model: .55
pwr::pwr.f2.test(u = 1, v = 47 - 3 - 1, f2 = .15, sig.level = .05)$power   # interaction: .72
r = pwr::pwr.f2.test(u = 3, f2 = .15, sig.level = .05, power = .80)
ceiling(r$v) + 3 + 1                                                        # required N: 77

# (2) simulation: fake studies of N runners with a known interaction of size f2
set.seed(20261113)
sim = function(N, f2, reps = 5000) {
  b = sqrt(f2)                       # with standard-normal x, w and noise, this gives the chosen f2
  mean(replicate(reps, {
    x = rnorm(N); w = rnorm(N); y = b * x * w + rnorm(N)
    summary(lm(y ~ x * w))$coefficients["x:w", 4] < .05
  }))
}
sim(47, .15)    # about .64
sim(47, .02)    # about .15

# 1.2 Design analysis: power, Type S and Type M errors (Gelman & Carlin 2014)

raw = zap_labels(read_sav("data/Madiera data 2024.sav"))
z2  = function(x) (x - mean(x)) / (2 * sd(x))

# interaction estimate, SE and df on the 2-SD scale
est = function(mod, covs = NULL) {
  d = raw |> drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(across(all_of(c("CE", mod, covs)), z2), W = .data[[mod]])
  m  = lm(as.formula(paste("Race_Sat ~", paste(c("CE * W", covs), collapse = " + "))), data = d)
  ct = summary(m)$coefficients["CE:W", ]
  c(b = ct[[1]], se = ct[[2]], df = m$df.residual)
}

# retrodesign function (Gelman & Carlin 2014)
retrodesign = function(A, s, df, alpha = .05, n.sims = 1e5) {
  z    = qt(1 - alpha / 2, df)
  p.hi = 1 - pt(z - A / s, df); p.lo = pt(-z - A / s, df)
  power = p.hi + p.lo
  e   = A + s * rt(n.sims, df); sig = abs(e) > s * z
  c(power = power, typeS = p.lo / power, typeM = mean(abs(e)[sig]) / A)
}

set.seed(20261113)
e = est("MTI")                                       # MT; CD-RISC and BRS on the next two lines
sapply(c(1, .5, .25), \(f) retrodesign(f * e[["b"]], e[["se"]], e[["df"]]))
e = est("CDRISC"); sapply(c(1, .5, .25), \(f) retrodesign(f * e[["b"]], e[["se"]], e[["df"]]))
e = est("BRS");    sapply(c(1, .5, .25), \(f) retrodesign(f * e[["b"]], e[["se"]], e[["df"]]))


#======== 2. Bayesian analysis ========#

# 2.1 Bayesian bootstrap: linear model, MT interaction
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))

set.seed(20261113)
bb = replicate(5000, {
  w = rexp(nrow(dt)); w = w / sum(w)        # random weights from a flat Dirichlet
  coef(lm(Race_Sat ~ ce_c * mt_c, data = dt, weights = w))["ce_c:mt_c"]
})
quantile(bb, c(.025, .975))   # 95% interval
mean(bb <= 0)                 # share of draws at or below zero

# 2.2 Bayesian bootstrap: ordinal model, MT interaction
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  mutate(ce_c = CE - mean(CE), mt_c = MTI - mean(MTI),
         sat  = factor(Race_Sat, ordered = TRUE))

set.seed(20261113)
n  = nrow(dt)
bb = replicate(5000, {
  w   = rexp(n); w = n * w / sum(w)      # random Dirichlet weights, scaled to sum to n
  fit = tryCatch(suppressWarnings(MASS::polr(sat ~ ce_c * mt_c, data = dt, weights = w)),
                 error = function(e) NULL)
  if (is.null(fit)) NA else coef(fit)["ce_c:mt_c"]
})
sum(is.na(bb))                                  # failed fits: 0
quantile(bb, c(.025, .975), na.rm = TRUE)       # 95% interval
mean(bb <= 0, na.rm = TRUE)                     # share of draws at or below zero

# 2.3 Bayesian MCMC (rstanarm): weak (SD 10) and sceptical (SD 1) priors; MT first
z2 = function(x) (x - mean(x)) / (2 * sd(x))

dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  drop_na(Race_Sat, CE, MTI) |>
  mutate(CE = z2(CE), W = z2(MTI))

fit_mt = function(prior_sd) stan_glm(Race_Sat ~ CE * W, data = dt,
                                     prior           = normal(0, prior_sd, autoscale = FALSE),   # slopes
                                     prior_intercept = normal(0, 10, autoscale = FALSE),
                                     chains = 4, iter = 4000, seed = 20261113, refresh = 0)

f = fit_mt(10)                      # weak prior; then fit_mt(1) for the sceptical one
summarise_draws(as_draws_array(as.array(f)),
                mean, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail)
mean(as.matrix(f)[, "CE:W"] > 0)    # probability the interaction is positive

# MCMC for any moderator (used for CD-RISC and BRS)
raw = zap_labels(read_sav("data/Madiera data 2024.sav"))

fit_mod = function(mod, prior_sd) {
  dt = raw |> drop_na(all_of(c("Race_Sat", "CE", mod))) |>
    mutate(CE = z2(CE), W = z2(.data[[mod]]))
  stan_glm(Race_Sat ~ CE * W, data = dt,
           prior           = normal(0, prior_sd, autoscale = FALSE),
           prior_intercept = normal(0, 10, autoscale = FALSE),
           chains = 4, iter = 4000, seed = 20261113, refresh = 0)
}

# one table: posterior summary of the interaction for all six fits
mcmc_row = function(f, mod, prior_sd) {
  s = summarise_draws(as_draws_array(as.array(f)), mean, ~quantile(.x, c(.025, .975)), rhat) |>
    filter(variable == "CE:W")
  tibble(mod, prior_sd, mean = s$mean, lo = s$`2.5%`, hi = s$`97.5%`, rhat = s$rhat,
         p_pos = mean(as.matrix(f)[, "CE:W"] > 0))
}

bind_rows(mcmc_row(fit_mt(10), "MT", 10),            mcmc_row(fit_mt(1), "MT", 1),
          mcmc_row(fit_mod("CDRISC", 10), "CD-RISC", 10), mcmc_row(fit_mod("CDRISC", 1), "CD-RISC", 1),
          mcmc_row(fit_mod("BRS", 10), "BRS", 10),        mcmc_row(fit_mod("BRS", 1), "BRS", 1))


#======== 3. Other robustness checks ========#

# 3.1 Multiple testing: Holm, BH, Bonferroni (3 and 6 tests)
raw = zap_labels(read_sav("data/Madiera data 2024.sav"))

# p-value of the CE x moderator interaction, as in the paper's models
int_p = function(mod, covs = NULL) {
  d = raw |> drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[mod]] - mean(.data[[mod]]))
  f = as.formula(paste("Race_Sat ~", paste(c("ce_c * w_c", covs), collapse = " + ")))
  summary(lm(f, data = d))$coefficients["ce_c:w_c", 4]
}

tibble(test = c("MT", "CD-RISC", "BRS"),
       p    = c(int_p("MTI"), int_p("CDRISC"), int_p("BRS"))) |>
  mutate(holm       = p.adjust(p, "holm"),
         bh         = p.adjust(p, "BH"),
         bonferroni = p.adjust(p, "bonferroni"))

tibble(test = c("MT", "MT, adjusted", "CD-RISC", "CD-RISC, adjusted", "BRS", "BRS, adjusted"),
       p    = c(int_p("MTI"),    int_p("MTI",    c("BRS", "CDRISC")),
                int_p("CDRISC"), int_p("CDRISC", c("BRS", "MTI")),
                int_p("BRS"),    int_p("BRS",    c("MTI", "CDRISC")))) |>
  mutate(holm = p.adjust(p, "holm"),
         bh   = p.adjust(p, "BH"))


# sharpened q-values, 6 tests (Anderson 2008; Benjamini, Krieger & Yekutieli 2006)
sharpened_q = function(p) {
  m = length(p); r = rank(p, ties.method = "first"); ps = sort(p); q = rep(1, m)
  for (qq in seq(1, .001, by = -.001)) {
    q1 = qq / (1 + qq)
    k  = max(c(0, which(ps <= q1 * seq_len(m) / m)))            # stage 1: rejections at q1
    q2 = q1 * m / (m - k)                                        # stage 2: adjust for estimated true nulls
    q[r <= max(c(0, which(ps <= q2 * seq_len(m) / m)))] = qq
  }
  q
}

p6 = c(int_p("MTI"),    int_p("MTI",    c("BRS", "CDRISC")),
       int_p("CDRISC"), int_p("CDRISC", c("BRS", "MTI")),
       int_p("BRS"),    int_p("BRS",    c("MTI", "CDRISC")))
round(sharpened_q(p6), 3)

# Romano-Wolf step-down: joint case bootstrap of the six interaction t-statistics
fam = list(MT = "MTI",    MT_adj = c("MTI", "BRS", "CDRISC"),
           CD = "CDRISC", CD_adj = c("CDRISC", "BRS", "MTI"),
           BRS = "BRS",   BRS_adj = c("BRS", "MTI", "CDRISC"))

int_est = function(d, v) {                       # estimate and SE of CE x moderator
  d = d |> drop_na(all_of(c("Race_Sat", "CE", v))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[v[1]]] - mean(.data[[v[1]]]))
  f = as.formula(paste("Race_Sat ~", paste(c("ce_c * w_c", v[-1]), collapse = " + ")))
  summary(lm(f, data = d))$coefficients["ce_c:w_c", 1:2]
}

d48 = raw |> filter(!is.na(Race_Sat))
est = sapply(fam, \(v) int_est(d48, v))          # row 1: estimate, row 2: SE
t0  = abs(est[1, ] / est[2, ])

set.seed(20261113)
tb = t(replicate(5000, {
  s = d48[sample(nrow(d48), replace = TRUE), ]
  sapply(names(fam), \(k) { e = int_est(s, fam[[k]]); abs((e[1] - est[1, k]) / e[2]) })   # centred t
}))

stepdown = function(t0, tb) {
  o = order(t0, decreasing = TRUE); p = numeric(length(t0))
  for (j in seq_along(o)) p[o[j]] = mean(apply(tb[, o[j:length(o)], drop = FALSE], 1, max) >= t0[o[j]])
  p[o] = cummax(p[o]); p
}
round(stepdown(t0, tb), 3)

# Westfall-Young free step-down min-p: joint Freedman-Lane permutation
fl = lapply(fam, \(v) {
  d  = d48 |> drop_na(all_of(c("Race_Sat", "CE", v))) |>
    mutate(ce_c = CE - mean(CE), w_c = .data[[v[1]]] - mean(.data[[v[1]]]))
  m0 = lm(as.formula(paste("Race_Sat ~", paste(c("ce_c + w_c", v[-1]), collapse = " + "))), data = d)   # model without the interaction
  list(d = d, fit = fitted(m0), e = resid(m0), id = which(complete.cases(d48[c("Race_Sat", "CE", v)])),
       f = as.formula(paste("ys ~", paste(c("ce_c * w_c", v[-1]), collapse = " + "))))
})

set.seed(20261113)
pp = t(replicate(5000, {
  u = runif(nrow(d48))                           # one shuffle of runners, shared by all six models
  sapply(fl, \(r) { r$d$ys = r$fit + r$e[order(u[r$id])]
  summary(lm(r$f, data = r$d))$coefficients["ce_c:w_c", 4] })
}))
round(stepdown(-p6, -pp), 3)                     # min-p: smaller p is more extreme

# null of complete irrelevance: no moderator changes the CE effect (common sample)
d46 = raw |> drop_na(Race_Sat, CE, MTI, BRS, CDRISC) |>
  mutate(across(c(CE, MTI, BRS, CDRISC), ~ .x - mean(.x)))
m0 = lm(Race_Sat ~ CE + MTI + BRS + CDRISC, data = d46)
m1 = lm(Race_Sat ~ CE * (MTI + BRS + CDRISC), data = d46)
anova(m0, m1)                                        # joint F-test of the three interactions

k = grep(":", names(coef(m1))); V = sandwich::vcovHC(m1, type = "HC3")
W = drop(t(coef(m1)[k]) %*% solve(V[k, k]) %*% coef(m1)[k]) / 3
pf(W, 3, m1$df.residual, lower.tail = FALSE)         # HC3 Wald p

set.seed(20261113)
Fp = replicate(5000, { d46$ys = fitted(m0) + sample(resid(m0))
anova(lm(ys ~ CE + MTI + BRS + CDRISC, d46), lm(ys ~ CE * (MTI + BRS + CDRISC), d46))$F[2] })
mean(Fp >= anova(m0, m1)$F[2])                       # Freedman-Lane permutation p

summary(m1)$coefficients[k, ]                        # joint model: each interaction, holding the other two fixed


# Anderson (2008) summary index of the three scales (inverse-covariance weights)
Z  = scale(as.matrix(d46[c("MTI", "BRS", "CDRISC")]))
w  = rowSums(solve(cov(Z)))
d46$idx = as.vector(scale(Z %*% w))
mi = lm(Race_Sat ~ CE * idx, data = d46)
round(w / sum(w), 3)                                  # weights: .298 .379 .323
summary(mi)$coefficients["CE:idx", ]                  # 1.34 (SE .44), p = .004
lmtest::coeftest(mi, vcov = sandwich::vcovHC(mi, type = "HC3"))["CE:idx", ]   # HC3 p = .002

# 3.2 Added noise: MT
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |> drop_na(Race_Sat, CE, MTI)

# add noise of a given size (fraction of each variable's SD) to CE and MTI, then refit
noisy_fit = function(frac) {
  d = dt |> mutate(CE   = CE  + rnorm(n(), 0, frac * sd(CE)),
                   MTI  = MTI + rnorm(n(), 0, frac * sd(MTI)),
                   ce_c = CE - mean(CE), mt_c = MTI - mean(MTI))
  summary(lm(Race_Sat ~ ce_c * mt_c, data = d))$coefficients["ce_c:mt_c", c(1, 4)]
}

set.seed(20261113)
map_dfr(c(.10, .25), \(f) {
  r = t(replicate(2000, noisy_fit(f)))
  tibble(noise = f, median_b = median(r[, 1]), median_p = median(r[, 2]),
         share_sig = mean(r[, 2] < .05))
})

# added noise for any moderator (MT, CD-RISC, BRS)
raw = zap_labels(read_sav("data/Madiera data 2024.sav"))

noisy_fit = function(d, mod, frac) {
  d = d |> mutate(CE   = CE + rnorm(n(), 0, frac * sd(CE)),
                  W    = .data[[mod]] + rnorm(n(), 0, frac * sd(.data[[mod]])),
                  ce_c = CE - mean(CE), w_c = W - mean(W))
  summary(lm(Race_Sat ~ ce_c * w_c, data = d))$coefficients["ce_c:w_c", c(1, 4)]
}

noise_table = function(mod, fracs = c(.10, .25), reps = 2000) {
  d = raw |> drop_na(all_of(c("Race_Sat", "CE", mod)))
  map_dfr(fracs, \(f) {
    r = t(replicate(reps, noisy_fit(d, mod, f)))
    tibble(moderator = mod, noise = f, median_b = median(r[, 1]),
           median_p = median(r[, 2]), share_sig = mean(r[, 2] < .05))
  })
}

set.seed(20261113)
noise_table("MTI")
noise_table("CDRISC")
noise_table("BRS")


# 3.3 All six models with variables scaled by 2 SD (Gelman 2008)
raw = zap_labels(read_sav("data/Madiera data 2024.sav"))
z2  = function(x) (x - mean(x)) / (2 * sd(x))

fit2 = function(mod, covs = NULL) {
  d = raw |> drop_na(all_of(c("Race_Sat", "CE", mod, covs))) |>
    mutate(across(all_of(c("CE", mod, covs)), z2), W = .data[[mod]])
  f  = as.formula(paste("Race_Sat ~", paste(c("CE * W", covs), collapse = " + ")))
  ct = summary(lm(f, data = d))$coefficients
  tibble(model = paste(mod, ifelse(is.null(covs), "", "adjusted")), n = nrow(d),
         term  = c("CE", "moderator", "CE x moderator"),
         b  = ct[c("CE", "W", "CE:W"), 1],
         se = ct[c("CE", "W", "CE:W"), 2],
         p  = ct[c("CE", "W", "CE:W"), 4])
}

bind_rows(fit2("MTI"),    fit2("MTI",    c("BRS", "CDRISC")),
          fit2("CDRISC"), fit2("CDRISC", c("BRS", "MTI")),
          fit2("BRS"),    fit2("BRS",    c("MTI", "CDRISC")))


#======== 4. Checkpoint data ========#

# 4.1 Correlations between checkpoints, by distance (41 complete series)
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  mutate(id = row_number()) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x)))          # 41 complete series

# time-series form: one row per runner per checkpoint
long = dt |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2])) |>
  select(id, time, coping)

# correlation between every pair of checkpoints, grouped by how far apart they are
wide = long |> pivot_wider(names_from = time, values_from = coping) |> select(-id)
R    = cor(wide)
gap  = abs(outer(1:11, 1:11, "-"))

tibble(r = R[upper.tri(R)], gap = gap[upper.tri(gap)]) |>
  group_by(gap) |> summarise(mean_r = mean(r), pairs = n())

mean(R[upper.tri(R) & gap == 1])     # adjacent:            .641
mean(R[upper.tri(R) & gap >= 5])     # five or more apart:  .269

# 4.2 Runner-block bootstrap: linear and quadratic group differences
dt = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  mutate(id = row_number()) |>
  filter(if_all(starts_with("Q16_"), ~ !is.na(.x))) |>
  mutate(group = ifelse(Race_Sat == 5, 1, 0))

# one block per runner: their 11 checkpoints summarised as rise and hill scores
blocks = dt |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2])) |>
  group_by(id, group) |>
  summarise(lin  = sum(coping * (time - 6)),
            quad = sum(coping * ((time - 6)^2 - 10)), .groups = "drop")

diff_means = function(b) c(lin  = mean(b$lin[b$group == 1])  - mean(b$lin[b$group == 0]),
                           quad = mean(b$quad[b$group == 1]) - mean(b$quad[b$group == 0]))

set.seed(20261113)
bt = replicate(5000, {
  b = blocks |> group_by(group) |> slice_sample(prop = 1, replace = TRUE) |> ungroup()
  diff_means(b)
})
apply(bt, 1, quantile, c(.025, .975))      # 95% intervals
rowMeans(bt <= 0)                          # share of draws at or below zero

# 4.3 Mixed models for the quadratic group difference: random intercept + AR(1), AR(1), compound symmetry
long = zap_labels(read_sav("data/Madiera data 2024.sav")) |>
  mutate(id = row_number()) |>
  filter(!is.na(Race_Sat)) |>
  mutate(group = ifelse(Race_Sat == 5, 1, 0)) |>
  pivot_longer(starts_with("Q16_"), names_to = "item", values_to = "coping") |>
  mutate(time = as.integer(str_match(item, "^Q16_(\\d+)")[, 2]),
         tL = contr.poly(11)[time, 1], tQ = contr.poly(11)[time, 2]) |>
  filter(!is.na(coping))

f      = coping ~ (tL + tQ) * group
ri_ar1 = nlme::lme(f, random = ~ 1 | id, correlation = nlme::corAR1(form = ~ time | id), data = long)
ar1    = nlme::gls(f, data = long, correlation = nlme::corAR1(form = ~ time | id))
cs     = nlme::gls(f, data = long, correlation = nlme::corCompSymm(form = ~ time | id))

summary(ri_ar1)$tTable["tQ:group", ]               # quadratic group difference
c(RI_AR1 = AIC(ri_ar1), AR1 = AIC(ar1), CS = AIC(cs))
