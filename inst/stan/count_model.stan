functions {
  // Stirling remainder lgamma(x) - [(x - 1/2) log(x) - x + log(2 pi) / 2] for
  // x >= 100; the first omitted term, 1 / (1188 x^9), is below 1e-21.
  real stirling_remainder(real x) {
    real z = inv(square(x));
    return inv(x) * (1.0 / 12 - z * (1.0 / 360 - z * (1.0 / 1260 - z / 1680)));
  }

  // log[Gamma(1/phi + Y) / (Gamma(1/phi) * (1/phi)^Y)] = sum_{k=1}^{Y-1} log1p(k * phi)
  // in O(1) operations, accurate to the rounding of its terms:
  // - Y <= 32: the finite sum;
  // - Y * phi < 0.01: its power series in phi (Faulhaber sums, 6 terms,
  //   relative error below (Y * phi)^6 / 28);
  // - 1/phi >= 100: the Stirling form (1/phi + Y - 1/2) log1p(Y * phi) - Y
  //   plus the difference of Stirling remainders, whose rounding error is of
  //   order eps * Y. lgamma differences would lose eps * (1/phi) * log(1/phi);
  // - otherwise (1/phi < 100): lgamma differences, which are then accurate.
  real log_rising_ratio(int Y, real phi) {
    if (Y <= 32) {
      real out = 0;
      for (k in 1:(Y - 1)) {
        out += log1p(k * phi);
      }
      return out;
    }
    if (Y * phi < 1e-2) {
      real n = Y - 1;
      real S1 = n * (n + 1) / 2;
      real S2 = n * (n + 1) * (2 * n + 1) / 6;
      real S3 = square(S1);
      real S4 = n * (n + 1) * (2 * n + 1) * (3 * square(n) + 3 * n - 1) / 30;
      real S5 = square(n) * square(n + 1) * (2 * square(n) + 2 * n - 1) / 12;
      real S6 = n * (n + 1) * (2 * n + 1) * (3 * n^4 + 6 * n^3 - 3 * n + 1) / 42;
      return phi * S1 - phi^2 * S2 / 2 + phi^3 * S3 / 3 - phi^4 * S4 / 4
             + phi^5 * S5 / 5 - phi^6 * S6 / 6;
    }
    if (phi <= 1e-2) {
      real k = inv(phi);
      return (k + Y - 0.5) * log1p(Y * phi) - Y
             + stirling_remainder(k + Y) - stirling_remainder(k);
    }
    return lgamma(inv(phi) + Y) - lgamma(inv(phi)) + Y * log(phi);
  }

  // log1p(x) - x, accurate for small x (series up to x^6 for x < 1e-3)
  real log1p_minus_x(real x) {
    if (x < 1e-3) {
      return -square(x) / 2 + x^3 / 3 - x^4 / 4 + x^5 / 5 - x^6 / 6;
    }
    return log1p(x) - x;
  }
}

data {
  int<lower=1> N;                       // Number of patients
  int<lower=1> R;                       // Number of observed cells
  int<lower=1> P;                       // Number of regression coefficients
  int<lower=1> G;                       // Number of dispersion parameter groups
  array[N] int<lower=1, upper=G> group; // Dispersion parameter group by patient
  array[R] int<lower=1, upper=N> subject; // Patient index for each observed cell
  array[R] int<lower=0> y;              // Observed cell counts
  matrix[R, P] X;                       // Cell-level design matrix
  vector[R] log_offset;                 // log cell exposure
}

transformed data {
  array[N] int<lower=0> y_sum;
  for (n in 1:N) {
    y_sum[n] = 0;
  }
  for (r in 1:R) {
    y_sum[subject[r]] += y[r];
  }
}

parameters {
  vector[P] beta;                       // Regression coefficients
  vector<lower={{ machine_double_eps }}>[G] phi; // Dispersion parameters
}

transformed parameters {
  vector[R] eta = log_offset + X * beta;
}

model {
  vector[N] mu_sum = rep_vector(0, N);

  // No explicit prior for beta, which corresponds to an improper uniform prior, matching SAS defaults.

  // Match SAS default prior on dispersion parameter (shape/rate)
  phi ~ gamma(0.0001, 0.0001);

  for (r in 1:R) {
    mu_sum[subject[r]] += exp(eta[r]);
    target += y[r] * eta[r] - lgamma(y[r] + 1);
  }

  for (n in 1:N) {
    real dispersion = phi[group[n]];
    real x = dispersion * mu_sum[n];

    // -(1/phi + y_sum) * log1p(x), written so that the leading -mu_sum is
    // separated from the small dispersion-dependent remainder; otherwise the
    // gradient with respect to phi cancels catastrophically as phi -> 0.
    target += log_rising_ratio(y_sum[n], dispersion)
              - mu_sum[n] - y_sum[n] * log1p(x) - log1p_minus_x(x) / dispersion;
  }
}
