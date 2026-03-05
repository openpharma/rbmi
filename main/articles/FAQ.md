# rbmi: Frequently Asked Questions

## 1 Introduction

This document provides answers to common questions about the `rbmi`
package. It is intended to be read after the `rbmi: Quickstart`
vignette.

  

### 1.1 Is `rbmi` validated?

With regards to software in the pharmaceutical industry, validation is
the act of ensuring that the software meets the needs and requirements
of users given the conditions of actual use. The FDA provides general
principles and guidance for validation but leaves it to individual
sponsors to define their specific validation processes. Therefore, no
individual R package can claim to be ‘validated’ independently, as
validation depends on the entire software stack and the specific
processes of each company.

That being said, some of the core components of any validation process
are the design specification (what is the software supposed to do) as
well as the testing / test results that demonstrate that the design
specification has been met. For `rbmi`, the design specification is
documented extensively, both at a macro level in vignettes and
literature publications, and at a micro level in detailed function
manuals. This is supported by our extensive suite of unit and
integration tests, which ensure the software consistently produces
correct output across a wide range of input scenarios.

This documentation and test coverage enable `rbmi` to be easily
installed and integrated into any R system, in alignment with the
system’s broader validation process.

  

### 1.2 How do the methods in `rbmi` compare to the mixed model for repeated measures (MMRM) implemented in the `mmrm` package?

`rbmi` was designed to complement and, occasionally, replace standard
MMRM analyses for clinical trials with longitudinal endpoints.

**Strengths** of `rbmi` compared to the standard MMRM model are:

- `rbmi` was designed to allow for analyses which are fully aligned with
  the the estimand definition. To facilitate this, it implements methods
  under a range of different missing data assumptions including standard
  missing-at-random (MAR), extended MAR (via inclusion of time-varying
  covariates), reference-based missingness, and not
  missing-not-at-random (MNAR; via \\\delta\\-adjustments). In contrast,
  the standard MMRM model is only valid under a standard MAR assumption
  which is not always plausible. For example, the standard MAR
  assumption is rather implausible for implementing a treatment policy
  strategy for the intercurrent event “treatment discontinuation” if a
  substantial proportion of subjects are lost-to-follow-up after
  discontinuation.
- The \\\delta\\-adjustment methods implemented in `rbmi` can be used
  for sensitivity analyses of a primary MMRM- or rbmi-type analysis.

**Weaknesses** of `rbmi` compared to the standard MMRM model are:

- MMRM models have been the de-facto standard analysis method for more
  than a decade. `rbmi` is currently less established.
- `rbmi` is computationally more intensive and using it requires more
  careful planning.

  

### 1.3 How does `rbmi` compare to general-purpose software for multiple imputation (MI) such as `mice`?

`rbmi` covers only “MMRM-type” settings, i.e. settings with a single
longitudinal continuous outcome which may be missing at some visits and
hence require imputation.

For these settings, it has several **advantages** over general-purpose
MI software:

- `rbmi` supports imputation under a range of different missing data
  assumptions whereas general-purpose MI software is mostly focused on
  MAR-based imputation. In particular, it is unclear how to implement
  jump to reference (JR) or copy increments in reference (CIR) methods
  with such software.
- The `rbmi` interface is fully streamlined to this setting which
  arguably makes the implementation more straightforward than for
  general-purpose MI software.
- The MICE algorithm is stochastic and inference is always based on
  Rubin’s rules. In contrast, method “conditional mean imputation plus
  jackknifing” (`method="method_condmean(type = "jackknife")"`) in
  `rbmi` does not require any tuning parameters, is fully deterministic,
  and provides frequentist-consistent inference also for reference-based
  imputations (where Rubin’s rule is very conservative leading to actual
  type I error rates which can be far below their nominal values).

However, `rbmi` is much more limited in its functionality than
general-purpose MI software.

  

### 1.4 How to handle missing data in baseline covariates in `rbmi`?

`rbmi` does not support imputation of missing baseline covariates.
Therefore, missing baseline covariates need to be handled outside of
`rbmi`. The best approach for handling missing baseline covariates needs
to be made on a case-by-case basis but in the context of randomized
trials, relatively simple approach are often sufficient (White and
Thompson ([2005](#ref-White2005))).

  

### 1.5 Why does `rbmi` by default use an ANCOVA analysis model and not an MMRM analysis model?

The theoretical justification for the conditional mean imputation method
requires that the analysis model leads to a point estimator which is a
linear function of the outcome vector (Wolbers et al.
([2022](#ref-Wolbers2021))). This is the case for ANCOVA but not for
general MMRM models. For the other imputation methods, both ANCOVA and
MMRM are valid analysis methods. An MMRM analysis model could be
implemented by providing a custom analysis function to the
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md)
function.

For further explanations, we also cite the end of section 2.4 of the
conditional mean imputation paper (Wolbers et al.
([2022](#ref-Wolbers2021))):

> The proof relies on the fact that the ANCOVA estimator is a linear
> function of the outcome vector. **For complete data, the ANCOVA
> estimator leads to identical parameter estimates as an MMRM model** of
> all longitudinal outcomes with an arbitrary common covariance
> structure across treatment groups **if treatment-by-visit interactions
> as well as covariate-by-visit-interactions** are included in the
> analysis model for all covariates,17 (p. 197). Hence, the same proof
> also applies to such MMRM models. We expect that conditional mean
> imputation is also valid if a general MMRM model is used for the
> analysis but more involved argument would be required to formally
> justify this.

  

### 1.6 How can I analyse the change-from-baseline in the analysis model when imputation was done on the original outcomes?

This can be achieved using custom analysis functions as outlined in
Section 7 of the Advanced Vignette. e.g.

``` r

ancova_modified <- function(data, ...) {
    data2 <- data %>% mutate(ENDPOINT = ENDPOINT - BASELINE)
    rbmi::ancova(data2, ...)
}

anaObj <- rbmi::analyse(
    imputeObj,
    ancova_modified,
    vars = vars
 )
```

  

White, Ian R, and Simon G Thompson. 2005. “Adjusting for Partially
Missing Baseline Measurements in Randomized Trials.” *Statistics in
Medicine* 24 (7): 993–1007.

Wolbers, Marcel, Alessandro Noci, Paul Delmar, Craig Gower-Page, Sean
Yiu, and Jonathan W Bartlett. 2022. “Standard and Reference-Based
Conditional Mean Imputation.” *Pharmaceutical Statistics* 21 (6):
1246–57.
