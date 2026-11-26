# Shared trial inputs and Stan draw model for the binary extension notes.

## ---- import-antidepressant-data
archive <- if (file.exists("high_low_datasets.zip")) {
    "high_low_datasets.zip"
} else {
    file.path("misc", "high_low_datasets.zip")
}
stopifnot(file.exists(archive))
extraction_dir <- tempfile("antidepressant-")
dir.create(extraction_dir)
sas_file <- unzip(
    archive,
    files = "high1.sas7bdat",
    exdir = extraction_dir
)
antidepressant_raw <- haven::read_sas(sas_file)
unlink(extraction_dir, recursive = TRUE)

# Keep the original fields and derive the binary response without imputation.
antidepressant <- antidepressant_raw
antidepressant$arm <- factor(
    antidepressant$TRT,
    levels = c("1", "2"),
    labels = c("Placebo", "Active")
)
antidepressant$response <- with(
    antidepressant,
    as.integer(-change / basval > 0.5)
)
stopifnot(
    !anyDuplicated(antidepressant[c("PATIENT", "week")]),
    !anyNA(antidepressant$arm),
    all(antidepressant$basval > 0)
)
patients <- unique(antidepressant[c("PATIENT", "arm")])
visit_weeks <- sort(unique(antidepressant$week))


## ---- prepare-probit-inputs
Ycat <- matrix(
    NA_integer_,
    nrow = nrow(patients),
    ncol = length(visit_weeks),
    dimnames = list(
        as.character(patients$PATIENT),
        paste0("week", visit_weeks)
    )
)
Ycat[cbind(
    match(antidepressant$PATIENT, patients$PATIENT),
    match(antidepressant$week, visit_weeks)
)] <- antidepressant$response
treat1 <- as.integer(patients$arm)
stopifnot(
    all(treat1 %in% 1:2),
    all(Ycat[!is.na(Ycat)] %in% 0:1),
    all(colSums(is.na(Ycat)) == c(0, 18, 30, 52, 69))
)


## ---- probit-stan-source
probit_stan_code <- r"(
functions {
  // Normal quantile from a log probability, without tail clipping.
  real std_normal_quantile_log(real lp) {
    real small_lp = lp < log(0.5) ? lp : log1m_exp(lp);
    real q;
    if (small_lp > -36) {
      q = inv_Phi(exp(small_lp));
    } else {
      q = -sqrt(-2 * small_lp);
      for (k in 1:6) {
        real lcdf = normal_lcdf(q | 0, 1);
        q -= (lcdf - small_lp) * exp(lcdf - normal_lpdf(q | 0, 1));
      }
    }
    return lp < log(0.5) ? q : -q;
  }
}
data {
  int<lower=1> D; // number of visits
  int<lower=1> P; // number of predictors
  int<lower=1> G; // number of covariance groups
  int<lower=1> R; // number of rows in the design matrix
  int<lower=1> B; // number of blocks
  int<lower=0> U; // number of auxiliary variables
  matrix[R, P] X; // design matrix
  vector[R] sign_y; // observed signs of the response
  array[B] int<lower=1, upper=D> K; // number of visits per block
  array[B, D] int<lower=1, upper=D> visit; // visit indices for each block
  array[B] int<lower=1> n_subject; // number of subjects per block
  array[B] int<lower=1, upper=R> start; // starting row index for each block
  array[B] int<lower=1, upper=G> cov_group; // covariance group for each block
  real<lower=0> beta_sd; // zero selects a flat coefficient prior
  real<lower=0> lkj_eta; // LKJ correlation prior parameter
}
parameters {
  vector[P] beta; // regression coefficients
  array[G] cholesky_factor_corr[D] L_Omega; // Cholesky factors of correlation matrices
  vector[U] u_raw; // auxiliary variables
}
transformed parameters {
  array[G] corr_matrix[D] Omega; // correlation matrices for each group
  for (g in 1:G) // compute correlation matrix for each group from its Cholesky factor
    Omega[g] = multiply_lower_tri_self_transpose(L_Omega[g]);
}
model {
  vector[R] mu = X * beta; // linear predictor for each row
  int u_pos = 1; // initialize position index for auxiliary variables in u_raw
  u_raw ~ std_normal(); // prior for auxiliary variables
  if (beta_sd > 0) beta ~ normal(0, beta_sd); // prior for regression coefficients
  for (g in 1:G) L_Omega[g] ~ lkj_corr_cholesky(lkj_eta); // prior for Cholesky factors of correlation matrices
  for (b in 1:B) { // loop over blocks
    array[K[b]] int v = visit[b, 1:K[b]]; // visit indices for this block
    matrix[K[b], K[b]] L = cholesky_decompose( // Cholesky factor for this block's covariance submatrix
      Omega[cov_group[b]][v, v]);
    for (i in 1:n_subject[b]) { // loop over subjects within this block
      vector[K[b] - 1] e; // auxiliary vector for conditional calculations
      for (j in 1:K[b]) { // loop over visits within this subject
        int r = start[b] + (i - 1) * K[b] + j - 1; // row index for this observation
        real conditional_mu = mu[r]; // conditional mean for this observation
        real log_mass; // log CDF mass for this observation
        if (j > 1) conditional_mu += L[j, 1:(j - 1)] * head(e, j - 1); // update conditional mean
        log_mass = normal_lcdf(sign_y[r] * conditional_mu / L[j, j] | 0, 1); // compute log CDF
        target += log_mass; // increment target with log mass
        if (j < K[b]) { // update auxiliary vector for next step if not the last visit
          e[j] = -sign_y[r] * std_normal_quantile_log(normal_lcdf(u_raw[u_pos] | 0, 1) + log_mass);
          u_pos += 1; // move to next auxiliary variable
        }
      }
    }
  }
}
)"


## ---- probit-r-functions

# Y: Binary response matrix of size N x D, where N is the number of subjects and D is the number of visits. Each entry should be 0 or 1.
# arm: Factor or integer vector indicating the treatment arm for each subject.
# X: Optional design array of size N x D x P, where P is the number of predictors. If NULL, a saturated design is used.
# same_cov: Logical indicating whether all arms share the same covariance matrix.
# beta_sd: Standard deviation for the normal prior on regression coefficients. Must be non-negative.
# lkj_eta: Shape parameter for the LKJ prior on correlation matrices. Must be positive.
prepare_probit_data <- function(Y, arm, X = NULL, same_cov = FALSE,
                                beta_sd = 0, lkj_eta = 1) {
    Y <- as.matrix(Y)
    stopifnot(
        is.numeric(Y), length(dim(Y)) == 2L,
        nrow(Y) > 0L, ncol(Y) > 0L,
        all(Y[!is.na(Y)] %in% 0:1), length(arm) == nrow(Y),
        !anyNA(arm), length(same_cov) == 1L, is.logical(same_cov),
        !is.na(same_cov), length(beta_sd) == 1L,
        is.finite(beta_sd), beta_sd >= 0,
        length(lkj_eta) == 1L, is.finite(lkj_eta), lkj_eta > 0
    )
    arm <- droplevels(factor(arm))
    N <- nrow(Y)
    D <- ncol(Y)
    A <- nlevels(arm)
    saturated <- is.null(X)
    if (saturated) {
        # X[i, d, p] gives subject i's design row at visit d.
        X <- array(0, c(N, D, A * D))
        for (i in seq_len(N)) {
            for (d in seq_len(D)) {
                X[i, d, (as.integer(arm[i]) - 1L) * D + d] <- 1
            }
        }
        coefficient_names <- paste(rep(levels(arm), each = D),
            rep(colnames(Y) %||% seq_len(D), A),
            sep = ":"
        )
    } else {
        stopifnot(
            is.array(X), length(dim(X)) == 3L,
            identical(dim(X)[1:2], c(N, D)), dim(X)[3] > 0L,
            is.numeric(X), all(is.finite(X))
        )
        coefficient_names <- dimnames(X)[[3]] %||% paste0("beta", seq_len(dim(X)[3]))
    }
    if (beta_sd == 0) {
        if (!saturated) stop("Use a proper beta_sd > 0 with a custom design.")
        for (a in levels(arm)) {
            for (d in seq_len(D)) {
                yy <- Y[arm == a, d]
                if (!all(0:1 %in% yy)) {
                    stop("Flat priors require both outcomes in every arm and visit.")
                }
            }
        }
    }
    observed <- !is.na(Y)
    keep <- which(rowSums(observed) > 0L)
    if (!length(keep)) stop("No observed outcomes.")
    cg <- if (same_cov) rep(1L, N) else as.integer(arm)
    # Group patients by covariance group and arbitrary observed-visit pattern.
    key <- paste(cg, apply(observed, 1, paste0, collapse = ""), sep = ":")
    blocks <- split(keep, factor(key[keep], levels = unique(key[keep])))
    K <- vapply(blocks, function(ii) sum(observed[ii[1], ]), integer(1))
    n_subject <- lengths(blocks)
    visit <- matrix(1L, length(blocks), D)
    rows <- lapply(seq_along(blocks), function(b) {
        ii <- blocks[[b]]
        # Reverse only the internal integration order; output visit order is unchanged.
        vv <- rev(which(observed[ii[1], ]))
        visit[b, seq_along(vv)] <<- vv
        cbind(subject = rep(ii, each = length(vv)), visit = rep(vv, length(ii)))
    })
    cells <- do.call(rbind, rows)
    P <- dim(X)[3]
    x_obs <- vapply(seq_len(P), function(p) matrix(X[, , p], N, D)[cells], numeric(nrow(cells)))
    x_obs <- matrix(x_obs, nrow(cells), P)
    y_obs <- Y[cells]
    if (qr(x_obs)$rank < P && beta_sd == 0) stop("Rank-deficient flat-prior design.")
    data <- list(
        D = D, P = P, G = if (same_cov) 1L else A,
        R = length(y_obs), B = length(blocks), U = length(y_obs) - length(keep), X = x_obs,
        sign_y = 2 * y_obs - 1,
        K = unname(K), visit = visit, n_subject = unname(n_subject),
        start = as.integer(cumsum(c(1L, head(K * n_subject, -1L)))),
        cov_group = vapply(blocks, function(ii) cg[ii[1]], integer(1)),
        beta_sd = beta_sd, lkj_eta = lkj_eta
    )
    list(
        data = data, coefficient_names = coefficient_names,
        arm_levels = levels(arm), visit_names = colnames(Y) %||% as.character(seq_len(D)),
        cells = cells, excluded_subjects = setdiff(seq_len(N), keep),
        same_cov = same_cov, saturated = saturated
    )
}


## ---- probit_draws
`%||%` <- function(x, y) if (is.null(x)) y else x

fit_probit_draws <- function(prepared, model, chains = 4L, parallel_chains = chains,
                             iter_warmup = 1500L, iter_sampling = 2000L,
                             seed = 20261026L, adapt_delta = 0.99,
                             step_size_cap = 0.005, thin = 1L, ...) {
    stopifnot(length(step_size_cap) == 1L, is.finite(step_size_cap), step_size_cap > 0)
    # Adapt the metric, then sample with a conservative fixed step size.
    warm <- model$sample(
        data = prepared$data, chains = chains,
        parallel_chains = parallel_chains, iter_warmup = iter_warmup,
        iter_sampling = 1L, seed = seed, adapt_delta = adapt_delta,
        max_treedepth = 12L, step_size = 0.05, refresh = 0, sig_figs = 18, diagnostics = NULL, ...
    )
    dat <- prepared$data
    variables <- c("beta", "L_Omega", if (dat$U > 0L) "u_raw")
    d <- posterior::as_draws_matrix(warm$draws(variables))
    initial <- lapply(seq_len(chains), function(ch) {
        list(
            beta = as.numeric(d[ch, paste0("beta[", seq_len(dat$P), "]")]),
            L_Omega = lapply(seq_len(dat$G), function(g) {
                nm <- outer(seq_len(dat$D), seq_len(dat$D), function(j, k) {
                    sprintf("L_Omega[%d,%d,%d]", g, j, k)
                })
                matrix(as.numeric(d[ch, as.vector(nm)]), dat$D, dat$D)
            }),
            u_raw = if (dat$U > 0L) as.numeric(d[ch, paste0("u_raw[", seq_len(dat$U), "]")]) else numeric()
        )
    })
    sampling_seed <- as.integer(seed %% .Machine$integer.max + 1)
    fit <- model$sample(
        data = dat, chains = chains, parallel_chains = parallel_chains,
        iter_warmup = 0L, iter_sampling = iter_sampling, thin = thin, seed = sampling_seed,
        init = initial, metric = "diag_e", inv_metric = warm$inv_metric(matrix = FALSE),
        adapt_engaged = FALSE,
        step_size = pmin(step_size_cap, warm$metadata()$step_size_adaptation),
        max_treedepth = 12L, refresh = 0
    )
    structure(
        list(
            fit = fit, warmup_fit = warm, prepared = prepared,
            initialisation = initial, diagnostics = fit$diagnostic_summary()
        ),
        class = "probit_draw_fit"
    )
}


## ---- extract-probit-draws
extract_probit_draws <- function(object, n_samples = NULL, seed = 123L) {
    # Select paired beta/Omega rows; retain full chains in object$fit for diagnostics.
    d <- posterior::as_draws_matrix(object$fit$draws(c("beta", "Omega")))
    if (is.null(n_samples)) n_samples <- nrow(d)
    stopifnot(
        length(n_samples) == 1L, is.finite(n_samples), n_samples >= 1L,
        n_samples == floor(n_samples)
    )
    if (n_samples > nrow(d)) {
        stop("Requested ", n_samples, " posterior draws, but only ", nrow(d),
            " are available.", call. = FALSE
        )
    }
    set.seed(seed)
    take <- sample.int(nrow(d), n_samples, replace = FALSE)
    dat <- object$prepared$data
    beta <- lapply(take, function(i) {
        setNames(
            as.numeric(d[i, paste0("beta[", seq_len(dat$P), "]")]),
            object$prepared$coefficient_names
        )
    })
    sigma <- lapply(take, function(i) {
        lapply(seq_len(dat$G), function(g) {
            nm <- outer(seq_len(dat$D), seq_len(dat$D), function(j, k) {
                sprintf("Omega[%d,%d,%d]", g, j, k)
            })
            matrix(as.numeric(d[i, as.vector(nm)]), dat$D, dat$D,
                dimnames = rep(list(object$prepared$visit_names), 2)
            )
        })
    })
    list(beta = beta, sigma = sigma, metadata = object$prepared[
        c("coefficient_names", "arm_levels", "visit_names", "same_cov")
    ])
}
