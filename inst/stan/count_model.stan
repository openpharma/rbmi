functions {
  /*
  * Negative multinomial log-PMF in standard p-parameterization.
  * p is the vector (p_1, ..., p_K) with sum(p) < 1.
  * The remaining probability is p_0 = 1 - sum(p).
  */
  real neg_multinomial_lpmf(int[] y, real r, vector p) {
    real y_sum = sum(y);
    return lgamma(r + y_sum)
      - lgamma(r)
      - sum(lgamma(to_vector(y) + 1.0))
      + dot_product(to_vector(y), log(p))
      + r * log1m(sum(p));
  }
}

data {
  int<lower=1> N;                       // Number of patients
  int<lower=1> K;                       // Number of periods (2 or 3)
  int<lower=1> P;                       // Number of regression coefficients
  int<lower=1> G;                       // Number of dispersion parameter groups
  int<lower=1, upper=G> group[N];       // Dispersion parameter group by patient
  int<lower=0> y[N, K];                 // Event counts by patient and period
  array[K] matrix[N, P] X;              // Period-specific design matrices
  matrix[N, K] log_offset;              // log(T_ij)
  matrix[N, K] is_avail;                // 1 if patient i is available in period j, 0 otherwise
}

parameters {
  vector[P] beta;                       // Regression coefficients
  // Values below 1e-6 are effectively the Poisson limit for these models. The
  // floor avoids the extreme near-zero geometry of the Gamma(.0001, .0001)
  // prior while retaining the SAS GENMOD dispersion parameterization.
  vector<lower=1e-6>[G] phi;
}

transformed parameters {
  matrix<lower=0>[N, K] mu = rep_matrix(0.0, N, K);
  matrix<lower=0, upper=1>[N, K] p = rep_matrix(0.0, N, K);
  vector<lower=0, upper=1>[N] p0;
  vector<lower=0>[G] inv_phi;

  inv_phi = inv(phi);
  // Keep phi as GENMOD dispersion: E[Y_ij] = mu_ij and Var(Y_ij) = mu_ij + phi * mu_ij^2.
  // In the negative-multinomial PMF this is achieved by using shape r = 1/phi
  // and p_ij = mu_ij / (r + sum_k mu_ik).

  for (j in 1:K) {
    // Be careful to only use the available patients in this period.
    for (n in 1:N) {
      if (is_avail[n, j] == 1) {
        mu[n, j] = exp(log_offset[n, j] + X[j][n, ] * beta);
      }
    }
  }

  for (n in 1:N) {
    real denom = inv_phi[group[n]] + sum(to_vector(mu[n, ]));
    for (j in 1:K) {
      if (is_avail[n, j] == 1) {
        p[n, j] = mu[n, j] / denom;
      }
      // otherwise p[n, j] remains 0, which is correct since
      // this period does not exist for this patient and thus the patient cannot
      // have any events in this period.
    }
    p0[n] = 1 - sum(to_vector(p[n, ]));
  }
}

model {
  // No explicit prior for beta, which corresponds to an improper uniform prior, matching SAS defaults.

  // Match SAS default prior on dispersion parameter (shape/rate)
  phi ~ gamma(0.0001, 0.0001);

  for (n in 1:N) {
    // Be careful to only use the available periods.
    int n_avail = 0;
    int y_avail[K];
    vector[K] p_avail;

    for (j in 1:K) {
      if (is_avail[n, j] == 1) {
        n_avail += 1;
        y_avail[n_avail] = y[n, j];
        p_avail[n_avail] = p[n, j];
      }
    }

    if (n_avail > 0) {
      target += neg_multinomial_lpmf(
        y_avail[1:n_avail] | inv_phi[group[n]], p_avail[1:n_avail]
      );
    }
  }
}
