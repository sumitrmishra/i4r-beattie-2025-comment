#set page(paper: "us-letter", margin: 1in, numbering: none)
#set text(font: "Libertinus Serif", size: 11pt)
#set par(justify: true)
#show figure.where(kind: table): set figure.caption(position: top)


#align(center)[
  #text(size: 16pt)[A comment on “What determines performance satisfaction in mountain ultra marathon runners? An exploration of coping, resilience, and mental toughness”] \
  Sumit Mishra (Krea University) \
  email: sumit.mishra\@krea.edu.in
]


#align(center)[
  *Abstract*
]

#cite(<beattie2025>, form: "prose") examine the factors that influence performance satisfaction in mountain ultra marathon runners. Their main variables of interest are coping, resilience, and mental toughness. The paper, using a reported sample of 47 runners who completed a survey, finds that the interaction between coping effectiveness and mental toughness (and resilience) had a positive and significant association with satisfaction when mental toughness was high, but not when mental toughness was low. Additionally, when they examined within-race data, they argue for a quadratic relationship for those runners who were less satisfied with their performance and a linear one for those who were satisfied. The study also had a qualitative part on the coping strategy effectiveness and its relationship with satisfaction. This replication focuses entirely on the quantitative portion of the paper. Using the AI-generated report provided by I4R and my own reconstruction of the statistical analysis based on the article’s methodological description, I report four main findings. First, the paper's results reproduce from the dataset provided with the replication package, apart from some misprints. Second, contrary to the abstract's claim, the satisfaction groups do not differ in the quadratic trend. Third, among the interactions reported in the paper, the resilience (CD-RISC) moderation is the most robust and the mental toughness moderation is fragile. Fourth, coping frequency and race performance satisfaction are reported to correlate negatively ($r = -0.35$). If we remove one influential observation, the correlation becomes weaker and the statistical significance vanishes ($r = -0.21, p = 0.204$). There are other minor issues. The power calculation cannot be reproduced, mental toughness score exceeds the scale's maximum, the data contain 48 respondents rather than the 47 reported, and the data lacks the item-level data needed to check reliabilities and demographics.

#pagebreak()

= Introduction
#cite(<beattie2025>, form: "prose"), henceforth BPW, explore the factors that influence performance satisfaction in mountain ultra marathon runners. The paper reports results from a survey that contacted 147 runners who completed the pre-race survey. Out of these 147 runners, 116 agreed to be contacted for the post-race survey and 47 completed the questionnaire. Two questionnaires were served to the participants collecting data on pre-race measures (mental toughness, resilience) and post-race measures (coping effectiveness, coping frequency, and performance satisfaction). The paper's main outcome of interest was performance satisfaction measured on a scale that runs between 1 (extremely unsatisfied) and 5 (extremely satisfied). The main result of the paper is that there exists a significant interactive association between mental toughness (and resilience) and coping effectiveness on performance satisfaction. Table 2 of the paper presents their main correlations showing a "moderate positive correlation" between mental toughness and resilience. They also show that race satisfaction is significantly correlated with mean coping frequency ($r = -0.35, p < 0.05$).

In the present report prepared for the Institute for Replication during November 2026, I examine whether BPW's findings are computationally reproducible and provide additional insights into the analysis presented in the paper. I obtained the dataset from the OSF repository. The package contained a single SPSS dataset. I evaluated the quantitative findings in the paper using the paper's text and its methodological descriptions. My replication code and documentation are available at #link("https://doi.org/10.5281/zenodo.24246040")[Zenodo] @mishra2026package. The package contains checks beyond what is covered in the report including simulation-based power calculations, a paired comparison of checkpoints 6 and 7, and a check of the reported percentages against the sample size. These do not affect the conclusions of this replication report.

In terms of computational reproducibility, I cannot directly assess the results because none of the original cleaning or analysis code is available in the package. Furthermore, the OSF repository's datafile contains 49 observations including one completely missing row of data leaving us with data for 48 respondents whereas the article reports 47 runners. I cannot explain why mental toughness scores exceed the scale's maximum for eight observations in the dataset. Using the reconstructed statistical specification described in the article, I show that the relationship between coping effectiveness and satisfaction moderated by mental toughness is significant if we use classical OLS ($p = 0.040$) but not under other inference procedures, such as HC3 standard errors, an ordinal model, or the bootstrap although a permutation test that I ran agrees with the plain OLS result. The significant coping frequency-race performance correlation is dependent on restricting the sample to runners with non-missing checkpoint data and one influential observation in the data (runner 3).

Overall, my evaluation raises some concerns around the reliability and robustness of BPW's main quantitative results although I do note that some of the results are more robust than others. The absence of code for the paper prevents me from identifying the exact source of the discrepancies. Additionally, providing a full replication package would not only improve the reproducibility of the paper but also strengthen the trust in the article's main quantitative claims.

= Computational Reproducibility
I used the replication package available at #link("https://osf.io/24ema/")[OSF]. It contains one SPSS .sav file which includes most of the variables reported in the paper except for the demographic variables and qualitative data. The data, I note, only include the final score variables, but there are no raw items that can guide us to reconstruct these scores. No cleaning or analysis code is available in the package; I cannot verify any coding error but I do note that the mental toughness scored on 8-items is presumably divided by 7. Values for this variable in eight rows of the data exceed the scale's maximum value of 7. This error does not change the main conclusions of the paper, but it does move the size of the mental toughness coefficients. Since no results are impacted in terms of conclusions or p-values, I retain the original scores in Section 3 (see @tab-mti)#footnote[Capping and dropping does lower the p-value for the MT interaction.].

There is no data dictionary but I was able to infer the value labels from the SPSS file. However, some of these labels are inconsistent. The paper describes CD-RISC range to be 0--4 but the dataset labels the values between 1 and 5. BRS is labelled as 'BBRS' with two different value labels ('0-2.5' and '2.6-5'), although it takes 15 unique values. The paper used SPSS with Hayes' PROCESS macro (Model 1; unknown version; #cite(<hayes2013>, form: "author"), #cite(<hayes2013>, form: "year")) and G*Power 3.1.9.7 @faul2007 for the power analysis. I used R 4.6.1 @rcore2026 for the analysis but also ran an independent cross-check within Stata (Version 19.5; #cite(<stata2025>, form: "author"), #cite(<stata2025>, form: "year")). Since I was able to reproduce the results in the paper using the choices made by the original authors rather than relying on their analysis code, I deem the analysis to be partially reproducible.
@tab-reproducibility summarises the availability of the data and code and the extent of computational reproducibility.

#figure(
  table(
    columns: (3fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [], [*Fully*], [*Partial*], [*No*],
    ),
    table.hline(stroke: 0.5pt),

    [Raw data provided],                   [], [], [x],
    [Cleaning code provided],              [], [], [x],
    [Analysis data provided],              [], [x], [],
    [Analysis code provided],              [], [], [x],
    [Reproducible from raw data],           [], [], [x],
    [Reproducible from analysis data],      [], [x], [],

    table.hline(stroke: 0.8pt),
  ),
  caption: [Computational reproducibility],
) <tab-reproducibility>

The second table records the documentation available with the replication package. There is neither any README file nor any other documentation that explains how each variable in the dataset was constructed. I know, from the paper, that the authors used SPSS for the quantitative analysis, but I could not locate the version used. The package also lacks any instruction for executing the analyses and instructions for obtaining the raw data. As a result, I had to infer analytical choices from the published article, and I could not verify how the original data was collected, cleaned, and finally transformed into the data deposited on OSF.
#[
  #set par(justify: false)
  #set text(hyphenate: false)

  #figure(
    table(
      columns: (3fr, 1.2fr, 1.2fr, 1fr),
      align: (left, center, center, center),
      stroke: none,
      inset: 5pt,

      table.hline(stroke: 0.8pt),
      table.header(
        [],
        [*Provided \ and clear*],
        [*Provided \ but unclear*],
        [*Not \ provided*],
      ),
      table.hline(stroke: 0.5pt),

      [README document],
      [], [], [x],

      [Data dictionary],
      [], [], [x],

      [How to obtain data not present in the replication
      package (if applicable)],
      [], [], [x],

      [Documentation for primary collected surveys or
      experimental data (if applicable)],
      [], [], [x],

      [Code execution instructions],
      [], [], [x],

      [Computational requirements: libraries/packages,
      running time],
      [], [], [x],

      table.hline(stroke: 0.8pt),
    ),
    caption: [Availability of replication documentation],
  ) <tab-documentation>
]


= Commentary

== The paper is conditionally reproducible
I systematically reviewed each of the tables and figures. The results presented in the paper reproduce given my reconstruction of the analysis in the paper. For instance, BPW find a significant $"CE" times "MT"$ interaction (p. 9); I was able to reproduce this result ($hat(beta) = 1.37, p = 0.040$). BPW report a significant $"CE" times "CD-RISC"$ interaction and my own re-run confirms the results ($hat(beta) = 3.56, p = 0.002$). BPW argue that "across time, as fatigue increases, coping frequency will subsequently increase to compensate" (p. 11). Each of the one-way repeated-measures ANOVA results on p11 ($F = 4.24, 15.56, 12.46$) was found to be reproducible. There are misprints; CE mean is 2.73 but it is reported 2.79 in the paper. On p13, BPW write that "For the high satisfaction group, there was a significant linear trend across time F(1,17)"; it should be $F(1, 12)$. All results are reported in @tab-repro. I suggest that authors clarify some of the printed numbers.

== The abstract's linear versus quadratic contrast is not supported by a direct group test

The abstract of the paper makes the following claim.
#quote(block: true)[
From a within-race perspective, coping frequency had a linear trend across time for those who were satisfied with their race performance, whereas a quadratic relationship was revealed for those who were less satisfied with their performance.
]

The paper reports subsample results to support this claim. For the high satisfaction subsample, the linear trend is significant (quadratic is not). For the low satisfaction subsample, both are reported to be significant. These within-group tests, as reported in BPW, reproduce in my reanalysis. However, a battery of formal group trend tests suggests that this claim is slightly exaggerated. The two groups do not differ in quadratic trends ($p = 0.200$) but they do differ in the linear trend ($p = 0.040$). When I replaced the high-versus-low split#footnote[satisfaction = 5 (13 runners) versus satisfaction = 1–4 (28 runners).] with satisfaction measured as a continuous variable, there is no evidence that the quadratic relationship varies with satisfaction level ($p = 0.630$). Among the mixed models that I ran, the best-fitting model (random intercept + AR(1)) yielded a p-value of 0.202 for the quadratic group difference. @tab-contrast reports each of the tests that I ran.

== The mental toughness moderation is fragile, BRS partly robust, and CD-RISC robust

The paper makes the following claims. First, BPW argue that small samples "are less of an issue due to the Bayesian statistics and bootstrapping procedures" (p. 6). Second, BPW report their results to be "robust in displaying similar interactive effects across three separate moderating variables" (p. 19). I put these claims to the test by re-examining the coping-effectiveness by moderator interaction. I apply five different inference procedures. MT is significant under OLS ($p = 0.040$) but not under HC3 ($p = 0.200$) or the ordinal model ($p = 0.062$). The bootstrap 95\% CI for MT moderation is $(-0.85, 2.32)$. The CD-RISC moderation survives each of the tests and the bootstrap CI for BRS includes zero (−0.19, 4.12). It is worth mentioning here that BPW argue that the PROCESS macro of SPSS safeguards the robustness of their small-$n$ results, but my re-run suggests that this claim is not true. BPW's reported intervals are plain OLS intervals, not bootstrapped. I also ran a battery of Bayesian estimation procedures for the main interaction models and the findings remain qualitatively similar. The Bayesian-bootstrap confidence interval for the MT interaction includes zero (−0.16 to 2.20), and an MCMC posterior excludes zero under a weak prior (0.09 to 4.18) but not when I used a sceptical prior (−0.42 to 2.44). The CD-RISC interaction excludes zero under both priors. Taken together, Bayesian approaches confirm that the mental toughness interaction results are non-robust. The authors should clarify the actual PROCESS version and the options used and also report HC3 or bootstrap intervals for all the interactions. 
The authors should also follow the best practices while working with interactive terms in their regression and report marginal associations with confidence bands across each moderator's range rather than slopes at $plus.minus 1 "SD"$ @brambor2006 @hainmueller2019. All the frequentist results are contained in @tab-robust; Bayesian results are in the replication package but not included as a table for the sake of brevity.


I also ran additional diagnostic checks to understand the stability of these results. Under a Bonferroni correction, the MT interaction turns out to be statistically insignificant ($p = 0.120$). With random noise of 25% of each explanatory variable's SD added to CE and the moderator, the MT interaction is significant in 42% of runs. Additionally, I also tested the interactions by putting together all interactions into one single model. In the joint model, only $"CE" times "CD-RISC"$ remains statistically significant ($hat(beta) = 3.87, p = 0.022$); MT ($p = 0.581$) and BRS ($p = 0.449$) are not. The test for joint significance rejects the null that no moderator changes the association between CE and race satisfaction ($p = 0.009$; HC3 $p = 0.011$; permutation-based $p = 0.009$). CD-RISC moderation, under all these tests, is still significant and robust. Finally, I folded the three moderators into a summary index following #cite(<anderson2008>, form: "prose")#footnote[The index can be thought of as a psychological resource score which uses the weighted average of MT, BRS, and CD-RISC scores, rescaled to zero mean and SD 1. The score which overlaps the least with others gets assigned greater weightage.] and interacted it with CE. The CE slope goes up by 1.34 satisfaction points for each SD the runner lies higher on the index ($hat(beta) = 1.34, "SE" = 0.44, p = 0.004, "HC3" p = 0.002$).


The paper reports that the study is "slightly underpowered" (p. 6). Following #cite(<gelman2014>, form: "prose"), I conduct a design analysis which points to limited power. If the true interactions equal their estimates, power is 0.54 (MT), 0.91 (CD-RISC), and 0.63 (BRS). If they are half as large, statistically significant estimates would overstate them by factors of 2.43 (MT), 1.62 (CD-RISC), and 2.21 (BRS). These are reported in @tab-robust2.

== Table 2's only significant correlation with the outcome is dependent on one influential observation

Table 2 of BPW reports correlations between the main outcome variable (satisfaction) and all the correlates. The only variable that turns out to be significant is the mean coping frequency ($r = -0.35, p = 0.023, n = 41$). This correlation is presented as the first sentence in the Results section of the paper#footnote["the more coping that MUM runners engaged with, the less satisfied they were with subjective performance." (p. 8)]. With a sample this small, it is important to look at influential observations. Row 3 of the dataset is the one with the largest Cook's distance (0.86); this runner reported the lowest level of satisfaction (1) and the highest coping frequency (5) at all 11 checkpoints. If we remove this runner from the sample, the correlation weakens and is no longer statistically significant ($r = -0.21, p = 0.204$). 
The association is also not significant with a rank-based correlation (Spearman $r = -0.15, p = 0.359$) or when coping is averaged over the available checkpoints for all 48 runners ($r = -0.16, p = 0.274$). I must also acknowledge that a permutation test supports the originally reported correlation ($p = 0.021, n = 41$).
@tab-cf contains these findings.

== A catalogue of minor issues
There are several other minor issues in the paper which do not affect the main results therein, but are worth looking into.

BPW report (p. 10) that the coefficient on CE is $hat(beta) = -0.41$ when CD-RISC was low; my rerun suggests it is -1.05. Similarly, the coefficients on high BRS (adjusted) and low BRS (adjusted) are 1.82 and -0.41 respectively; the printed values in the paper are 0.51 and -0.51 respectively (p. 11). 
BPW report that "there was a significant linear trend across time F(1, 17) = 17.09, p < 0.001." It should be $F(1, 12)$ and $p = 0.001$. Table 2's $"BRS" times "CD-RISC"$ correlation is reported to be 0.35 ($p < 0.01$); the correlation is alright but the p-value is 0.017. The overall test of the BRS model is reported as $p = 0.05$; this should be 0.058. The discussion section reports that models predicted 9-24% of the variance; this should be reported as approximately 14% to 29%. Finally, Table 1 reports 10 means but the data contains 11. Table 1 of the paper omits mentioning Rosario whereas the data contains no label for Machico. The table also omits the series peak (mean = 2.59). The checkpoint labels do not match the paper's list. So, it is not possible to accurately map the means to their corresponding checkpoints.
The paper reports that, for detecting 80% power, the minimum sample size should be 65. However, the sample size is 48 and BPW argue that this difference only makes the study 'slightly underpowered'. My re-run suggests that for 80% power (f² = .15, α = .05, one tested predictor among three), the minimum sample size is 55 and with $n = 65$, power = 86.7%.
In addition to data integrity issues discussed elsewhere in the report, I checked for duplicates in the data. I did not find any data duplication in the datafile. Each pair of runners differs on at least four checkpoints. 

= Conclusion
My reanalysis of BPW reproduces findings reported in the paper's text but I am equally concerned about the fragility of some of the results. Despite not having access to a README, a code or the raw datafile, I was able to reproduce BPW's results. The paper contains several misprints but those are benign and do not affect the paper's main results. Some of the claims in the paper do need to be reassessed. The abstract's linear-versus-quadratic claim does not survive additional checks; the best fitting mixed model yielded a p-value of 0.202. Among the interaction models presented in the paper, MT is the least robust and the CD-RISC results are the most robust. The design analysis suggests low power and inflated estimates (exaggeration factors are reported between 1.6 and 2.4). Therefore, the paper's claim that their findings are robust across the three moderators is slightly overstated. The coping frequency-satisfaction correlation, the only significant correlation between a predictor and the outcome, is fragile and is dependent upon one outlier in the data. Without this one runner, the correlation becomes weaker and it is no longer statistically significant.
The absence of raw data, cleaning or analysis code, and documentation prevents me from identifying sources of other issues in the paper. Overall, the study's main findings are statistically fragile, conditionally so.

= Funding disclosure

The author received no funding for this report. The author does not hold a paid or unpaid position with a financial, political or ideological stake in the original article, and the report was not written under contract with any organization.

= Conflict of Interest disclosure

The author of this report has no conflict of interest with the authors of the original article. The author is not a colleague, co-author, family member, student, former student or doctoral supervisor of any of the original authors, and shares no close personal relationship with, or rivalry towards, any of them.

= Artificial Intelligence disclosure

This commentary builds on the AI-generated report provided by the Institute for Replication @barbarioli2026, whose claims I verified against the deposited data as described in Section 3. In addition, I used Claude Code (Anthropic; model Claude Opus 5.5) to draft and test R code for the reanalysis, to check the reported results against the original article and the I4R report, and to suggest wording and table layouts. I reviewed all AI-generated output, ran every analysis myself, and take full responsibility for the content of this report.

#bibliography("references.bib", style: "apa")


= Tables and Figures

== Tables

#figure(
  [
  #table(
    columns: (2.4fr, 0.6fr, 1.1fr, 1.1fr, 1.1fr, 1.2fr),
    align: (left, center, center, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Model*], [*n*], [*Original MTI*], [*Rescaled \ (× 7/8)*], [*Capped \ at 7*], [*Scores above \ 7 dropped*],
    ),
    table.hline(stroke: 0.5pt),

    [CE × MT, no controls],             [48], [1.37 (.040)], [1.57 (.040)], [1.70 (.031)], [2.02 (.029)],
    [CE × MT, adjusted for resilience], [46], [1.29 (.071)], [1.47 (.071)], [1.63 (.055)], [2.03 (.049)],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Cells show the interaction estimate (p-value). Eight runners have MTI scores above the scale maximum of 7. "Capped at 7" sets them to 7; "Scores above 7 dropped" removes them (n = 40 without controls, 38 adjusted).]]
  ],
  caption: [Mental toughness interaction under alternative treatments of out-of-range MTI scores],
) <tab-mti>

#figure(
  [
  #table(
    columns: (2.6fr, 1.4fr, 1.4fr, 1.2fr),
    align: (left, center, center, left),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Quantity*], [*Paper*], [*Replication*], [*Verdict*],
    ),
    table.hline(stroke: 0.5pt),

    [Table 1: checkpoint means], [10 printed], [11 in data], [10 match; 6th omitted],
    [Table 2: 15 correlations], [], [largest gap < .01], [Reproduces],
    [Table 2: coping effectiveness mean], [2.79], [2.73], [Misprint],
    [Table 2: CF × satisfaction], [−.35\*], [−.35 (p = .023)], [Reproduces],

    table.hline(stroke: 0.3pt),
    [CE × MT], [1.37, p = .04], [1.37, p = .040], [Reproduces],
    [CE × MT, adjusted], [1.28, p = .07], [1.29, p = .071], [Reproduces],
    [CE × CD-RISC], [3.56, p = .001], [3.56, p = .002], [Reproduces],
    [CE × CD-RISC, adjusted], [3.85, p = .001], [3.86, p = .001], [Reproduces],
    [CE × BRS], [2.00, p = .024], [2.01, p = .024], [Reproduces],
    [CE × BRS, adjusted], [2.15, p = .021], [2.15, p = .021], [Reproduces],

    table.hline(stroke: 0.3pt),
    [Change over time (Wilks)], [F(10,31) = 4.23], [F(10,31) = 4.24], [Reproduces],
    [Linear trend], [F(1,40) = 15.55], [F(1,40) = 15.56], [Reproduces],
    [Quadratic trend], [F(1,40) = 12.46], [F(1,40) = 12.46], [Reproduces],
    [Satisfied group, linear], [F(1,17) = 17.09], [F(1,12) = 17.10], [df misprinted],
    [Less satisfied, quadratic], [F(1,27) = 16.85], [F(1,27) = 16.86], [Reproduces],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Small differences reflect the paper truncating rather than rounding.]]
  ],
  caption: [Published results and their replication from the deposited data],
) <tab-repro>


#figure(
  [
  #table(
    columns: (3fr, 0.6fr, 1.6fr, 0.9fr),
    align: (left, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Test of the group difference*], [*n*], [*Statistic*], [*p*],
    ),
    table.hline(stroke: 0.5pt),

    [Quadratic trend, two-group comparison],     [41], [t(39) = 1.30],             [.200],
    [Linear trend, two-group comparison],        [41], [t(39) = 2.12],             [.040],
    [Quadratic trend, satisfaction continuous],  [41], [],                         [.630],
    [All trend shapes jointly (Wilks)],          [41], [F(10,30) = 2.02],          [.066],
    [Quadratic trend, runner-block bootstrap],   [41], [95% CI: −11.12 to 41.23], [],

    table.hline(stroke: 0.3pt),
    [Mixed model, compound symmetry],            [48], [],                         [.039],
    [Mixed model, AR(1)],                        [48], [],                         [.313],
    [Mixed model, unstructured],                 [48], [],                         [.481],
    [Mixed model, random intercept + AR(1)],     [48], [],                         [.202],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Satisfied n = 13, less satisfied n = 28. t is satisfied minus less satisfied. Mixed models use all available ratings and test the quadratic difference, with time entered as linear and quadratic trends; AIC favours the random-intercept + AR(1) model (1343, against 1351 for AR(1) and 1423 for compound symmetry).]]
  ],
  caption: [Tests of whether satisfied and less satisfied runners differ in their coping-frequency trend],
) <tab-contrast>

#figure(
  [
  #table(
    columns: (2fr, 0.8fr, 1fr, 0.8fr, 0.9fr, 1.4fr),
    align: (left, center, center, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Moderator*], [*OLS p*], [*Permutation p*], [*HC3 p*], [*Ordinal p*], [*Bootstrap 95% CI*],
    ),
    table.hline(stroke: 0.5pt),

    [MT],                   [.040], [.043],  [.200],  [.062],  [−0.85, 2.32],
    [MT, adjusted],         [.071], [.071],  [.241],  [.087],  [−1.06, 2.39],
    [CD-RISC],              [.002], [.001],  [<.001], [<.001], [1.64, 5.10],
    [CD-RISC, adjusted],    [.001], [<.001], [<.001], [<.001], [1.72, 5.72],
    [BRS],                  [.024], [.023],  [.037],  [.017],  [−0.19, 4.12],
    [BRS, adjusted],        [.021], [.021],  [.025],  [.015],  [−0.15, 4.20],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Permutation: Freedman–Lane residual permutation @freedman1983 (5,000 draws). HC3 @long2000: heteroskedasticity-robust standard errors. Ordinal: proportional-odds model, likelihood-ratio test. Bootstrap: case resampling (5,000 draws), percentile interval for the interaction coefficient. Adjusted models control for the other two scales. Seed 20261113.]]
  ],
  caption: [The coping-effectiveness × moderator interaction under five inference methods],
) <tab-robust>


#figure(
  [
  #table(
    columns: (3fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Check*], [*MT*], [*CD-RISC*], [*BRS*],
    ),
    table.hline(stroke: 0.5pt),

    table.cell(colspan: 4)[_Multiple testing (adjusted p-values)_],
    [Holm, 3 tests],          [.048], [.005], [.048],
    [Bonferroni, 3 tests],    [.120], [.005], [.072],
    [Holm, 6 tests],          [.085], [.008], [.085],
    [Benjamini–Hochberg, 6 tests], [.048], [.005], [.036],
    [Sharpened q, 6 tests],        [.034], [.005], [.025],
    [Romano–Wolf, 6 tests],        [.073], [.012], [.068],
    [Westfall–Young, 6 tests],     [.065], [.004], [.057],

    table.hline(stroke: 0.3pt),
    table.cell(colspan: 4)[_Added noise (share of 2,000 runs with p < .05)_],
    [10% of SD],              [.63],  [1.00], [.99],
    [25% of SD],              [.42],  [1.00], [.77],

    table.hline(stroke: 0.3pt),
    table.cell(colspan: 4)[_Design analysis (Gelman & Carlin, 2014)_],
    [Power if true effect = estimate],          [.54],  [.91],  [.63],
    [Exaggeration if true effect = half the estimate], [2.43], [1.62], [2.21],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Models without controls. Six-test corrections include the three adjusted models. Noise is added to coping effectiveness and the moderator. Exaggeration is the Type M error ratio. Multiple-testing corrections follow Holm and Benjamini–Hochberg @holm1979 @benjamini1995; sharpened q-values follow @anderson2008. Romano–Wolf @romano2005stepwise: step-down on the largest |t| over a joint case bootstrap (5,000 draws). Westfall–Young @westfall1993resampling: free step-down on the smallest p over a joint Freedman–Lane permutation (5,000 draws). Seed 20261113.]]
  ],
  caption: [Further robustness checks on the coping-effectiveness × moderator interaction],
) <tab-robust2>


#figure(
  [
  #table(
    columns: (3fr, 0.6fr, 1.4fr, 0.9fr),
    align: (left, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Analysis*], [*n*], [*r*], [*p*],
    ),
    table.hline(stroke: 0.5pt),

    [Pearson, complete series (as in Table 2)], [41], [−.35], [.023],
    [Spearman, complete series],                [41], [−.15], [.359],
    [Kendall, complete series],                 [41], [−.11], [.376],
    [Pearson, without respondent 3],            [40], [−.21], [.204],
    [Pearson, all available ratings],           [48], [−.16], [.274],
    [Spearman, all available ratings],          [48], [−.07], [.639],

    table.hline(stroke: 0.3pt),
    [Bootstrap 95% CI, complete series],        [41], [−.63 to .06], [],
    [Permutation test, complete series],        [41], [],            [.021],
    [Drop one runner at a time: range of r],    [40], [−.42 to −.21], [],
    [Drops that make p ≥ .05],                  [40], [respondents 3 and 11], [.204, .055],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ Respondent 3 rated every checkpoint at the scale maximum and satisfaction at 1; its Cook's distance is .86 (coping frequency regressed on satisfaction).]]
  ],
  caption: [Correlation between mean coping frequency and performance satisfaction under alternative analyses],
) <tab-cf>


#figure(
  [
  #table(
    columns: (2.6fr, 1.4fr, 1.8fr, 0.7fr),
    align: (left, center, center, center),
    stroke: none,
    inset: 5pt,

    table.hline(stroke: 0.8pt),
    table.header(
      [*Item*], [*Paper*], [*Data*], [*Page*],
    ),
    table.hline(stroke: 0.5pt),

    table.cell(colspan: 4)[_Misprinted statistics_],
    [Simple slope, low CD-RISC (adjusted)],   [−.41],               [−1.05],                  [10],
    [Simple slope, high BRS (adjusted)],      [.51],                [1.82],                   [11],
    [Simple slope, low BRS (adjusted)],       [−.51],               [−.41],                   [11],
    [Satisfied group, linear trend],          [F(1,17), p < .001],  [F(1,12), p = .001],     [13],
    [Table 2: coping effectiveness mean],     [2.79],               [2.73],                   [8],
    [Table 2: BRS × CD-RISC],                 [.35\*\*],            [.35\* (p = .017)],       [8],
    [BRS model, overall test],                [p = .05],            [p = .058],               [11],
    [Variance explained (Discussion)],        [9–24%],              [14–29%],                 [17],

    table.hline(stroke: 0.3pt),
    table.cell(colspan: 4)[_Sample, scales and tables_],
    [Sample size],                            [47],                 [48 (49 rows, one blank)], [1, 5],
    [Mental toughness range],                 [1–7],                [8 scores above 7; maximum 8.00], [6],
    [CD-RISC response scale],                 [0–4],                [labelled 1–5],           [6],
    [Table 1: checkpoint means],              [10],                 [11; peak (2.59) omitted], [7],
    [Power analysis, n for 80% power],        [65],                 [55 (65 gives 87%)],      [5–6],

    table.hline(stroke: 0.8pt),
  )
  #align(left)[#text(size: 9pt)[_Note:_ None changes a published conclusion. Simple slopes are coping-effectiveness effects at ±1 SD of the moderator; their printed intervals and p-values match the data.]]
  ],
  caption: [Minor issues],
) <tab-minor>


== Figures

This commentary contains no figures.
