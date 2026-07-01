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
  int<lower=0> y[N, K];                 // Event counts by patient and period
  array[K] matrix[N, P] X;              // Period-specific design matrices
  matrix[N, K] log_offset;              // log(T_ij)
}

parameters {
  vector[P] beta;                       // Regression coefficients
  real<lower=0> phi;                    // Dispersion parameter (as in SAS GENMOD)
}

transformed parameters {
  matrix<lower=0>[N, K] mu;
  matrix<lower=0, upper=1>[N, K] p;
  vector<lower=0, upper=1>[N] p0;
  real<lower=0> inv_phi;

  inv_phi = inv(phi);
  // Keep phi as GENMOD dispersion: E[Y_ij] = mu_ij and Var(Y_ij) = mu_ij + phi * mu_ij^2.
  // In the negative-multinomial PMF this is achieved by using shape r = 1/phi
  // and p_ij = mu_ij / (r + sum_k mu_ik).

  for (j in 1:K) {
    mu[, j] = exp(log_offset[, j] + X[j] * beta);
  }

  for (n in 1:N) {
    real denom = inv_phi + sum(to_vector(mu[n, ]));
    for (j in 1:K) {
      p[n, j] = mu[n, j] / denom;
    }
    p0[n] = 1 - sum(to_vector(p[n, ]));
  }
}

model {
  // No explicit prior for beta, which corresponds to an improper uniform prior, matching SAS defaults.

  // Match SAS default prior on dispersion parameter (shape/rate)
  phi ~ gamma(0.0001, 0.0001);

  for (n in 1:N) {
    target += neg_multinomial_lpmf(y[n] | inv_phi, to_vector(p[n, ]));
  }
}
