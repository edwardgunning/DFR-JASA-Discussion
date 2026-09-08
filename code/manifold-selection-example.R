# Packages
library(ggplot2)
library(lattice)
library(data.table)

# NOTE: We have used the authors data-generation examples from:
# https://github.com/SUIIAO/Deep-Frechet-Regression/blob/main/simulation/distributional/DenSimu.R#L38


# Define simulation parameters
N <- 100 # Number of observations per sample
nOut <- 100 # Number of test samples
sigma0 <- 3 # Base standard deviation
kappa <- 1 # Shape parameter for gamma distribution
n <- 500
set.seed(1)

# Generate predictor data for training and test sets
# (NOTE: WE ONLY USE TRAIN IN COMMENTARY)
x <- data.frame(
  X1 = runif(n, -1, 0), X2 = runif(n, 0, 1), X3 = runif(n, 1, 2),
  X4 = rnorm(n, 0, 1), X5 = rnorm(n, -10, 3), X6 = rnorm(n, 10, 3),
  X7 = sample(c(0, 1), n, TRUE, c(0.4, 0.6)),
  X8 = sample(c(0, 1), n, TRUE, c(0.3, 0.7)),
  X9 = sample(c(0, 1), n, TRUE, c(0.6, 0.3)) # NOTE: I UNDERSTAND THESE DON'T SUM TO 1
  # BUT THEY'RE INHERITED FROM https://github.com/SUIIAO/Deep-Frechet-Regression/blob/main/simulation/distributional/DenSimuManifold.R
)
xout <- data.frame(
  X1 = runif(nOut, -1, 0), X2 = runif(nOut, 0, 1), X3 = runif(nOut, 1, 2),
  X4 = rnorm(nOut, 0, 1), X5 = rnorm(nOut, -10, 3), X6 = rnorm(nOut, 10, 3),
  X7 = sample(c(0, 1), nOut, TRUE, c(0.4, 0.6)),
  X8 = sample(c(0, 1), nOut, TRUE, c(0.3, 0.7)),
  X9 = sample(c(0, 1), nOut, TRUE, c(0.6, 0.3)) # NOTE: I UNDERSTAND THESE DON'T SUM TO 1
  # BUT THEY'RE INHERITED FROM https://github.com/SUIIAO/Deep-Frechet-Regression/blob/main/simulation/distributional/DenSimuManifold.R
)

# NOTE, KEEP SMALL TYPO FOR CONSISTENCY WITH AUTHORS' EXAMPLE. R WILL RE-NORMALIZE PROBABILITIES ANYWAY!

# Original Example: -------------------------------------------------------
# Generate response data
y <- list()
yMean <- matrix(nrow = n, ncol = N - 1)
expect_eta_Z_vec <- expect_sigma_Z_vec <- numeric(n)
mu.sd <- NULL
for (i in 1:n) {
  # Generate expected mean and standard deviation
  expect_eta_Z_vec[i] <- expect_eta_Z <- 3 * (sin(pi * x[i, 1]) + cos(pi * x[i, 2])) * x[i, 8] +
    (5 * x[i, 4]^2 + x[i, 5]) * x[i, 7]

  expect_sigma_Z_vec[i] <- expect_sigma_Z <- sigma0 + 0.5 * (sin(pi * x[i, 1]) + cos(pi * x[i, 2])) * x[i, 8] +
    abs(5 * x[i, 4]^2 + x[i, 5]) * x[i, 7]

  # Sample mean and standard deviation
  mu <- rnorm(1, mean = expect_eta_Z, sd = 1)
  sigma <- rgamma(1, shape = expect_sigma_Z^2 / kappa, scale = kappa / expect_sigma_Z)

  # Generate response and true quantile values
  y[[i]] <- sort(mu + sigma * rnorm(N)) # rnorm(N, mean = mu, sd = sigma)
  yMean[i, ] <- expect_eta_Z + expect_sigma_Z * qnorm(c(1:(N - 1)) / N)

  mu.sd <- rbind(mu.sd, data.frame(mu, sigma))
}
y_mat <- do.call(rbind, y)

matplot(t(y_mat), type = "l", col = scales::alpha(1, 0.1), lty = 1)


# Perturbed-off-manifold example ------------------------------------------
# From: https://github.com/SUIIAO/Deep-Frechet-Regression/blob/main/simulation/distributional/DenSimuRobust.R
y_pert <- list()
yMean_pert <- matrix(nrow = n, ncol = N - 1)
mu.sd_pert <- NULL
for (i in 1:n) {
  # Sample mean and standard deviation
  mu <- rnorm(1, mean = expect_eta_Z_vec[i], sd = 2)
  sigma <- rgamma(1, shape = expect_sigma_Z_vec[i]^2 / kappa, scale = kappa / expect_sigma_Z_vec[i])

  # Generate response and true quantile values
  y_pert[[i]] <- sort(mu + sigma * rnorm(N)) # rnorm(N, mean = mu, sd = sigma)
  yMean_pert[i, ] <- expect_eta_Z_vec[i] + expect_sigma_Z_vec[i] * qnorm(c(1:(N - 1)) / N)

  mu.sd_pert <- rbind(mu.sd_pert, data.frame(mu, sigma))
}
y_mat_pert <- do.call(rbind, y_pert)


# Skew Normal Example: ----------------------------------------------------

y_group <- list()
mu.sd.skew.group <- NULL
eta_latent <- as.numeric(scale(expect_eta_Z_vec))
log_sigma_latent <- as.numeric(scale(log(expect_sigma_Z_vec)))
for (i in 1:n) {
  # Generate expected mean and standard deviation
  expect_eta_Z <- expect_eta_Z_vec[i]
  expect_sigma_Z <- expect_sigma_Z_vec[i]

  # X9 is not used in eta or sigma, so this is a group-specific shape effect.
  # Here the group-specific skewness is weaker and less entangled with the
  # mean direction, making it more likely to appear after the mean and scale
  # directions in the ISOMAP embedding.
  mu_curve <- 2 * plogis(1.25 * (eta_latent[i]^2 - 1)) - 1
  expect_alpha_Z <- (2 * x[i, 9] - 1) * (3.50 + 0.75 * mu_curve)

  # Sample mean, standard deviation, and skewness
  mu <- rnorm(1, mean = expect_eta_Z, sd = 1)
  sigma <- rgamma(1, shape = expect_sigma_Z^2 / kappa, scale = kappa / expect_sigma_Z)
  alpha <- rnorm(1, mean = expect_alpha_Z, sd = 0.25)

  delta <- alpha / sqrt(1 + alpha^2)
  omega_sq <- sigma^2 / (1 - ((2 * delta^2) / pi))
  omega <- sqrt(omega_sq)
  xi <- mu - omega * delta * sqrt(2 / pi)
  y_sample <- sn::rsn(n = N, xi = xi, omega = omega, alpha = alpha)

  y_group[[i]] <- sort(y_sample)
  mu.sd.skew.group <- rbind(
    mu.sd.skew.group,
    data.frame(mu, sigma, alpha,
      expect_alpha = expect_alpha_Z,
      mu_curve, group = x[i, 9]
    )
  )
}

y_mat_group <- do.call(rbind, y_group)



# -------------------------------------------------------------------------
grid_p <- c(1:ncol(y_mat)) / (ncol(y_mat) + 1)

png(file = here::here(
  "figures",
  "qfs-group-third-isomap.png"
), width = 12, height = 4, units = "in", res = 400)
par(mfrow = c(1, 3), mar = c(5, 6, 4, 2) + 0.05, cex = 1)
matplot(grid_p, t(y_mat),
  main = "Original Simulation",
  xlab = expression(p),
  ylab = expression(hat(Q)(p)),
  type = "l",
  lty = 1, col = scales::alpha(1, 0.1)
)
matplot(grid_p, t(y_mat_pert),
  main = "Perturbed Sensitivity",
  xlab = expression(p),
  ylab = expression(hat(Q)(p)),
  type = "l", lty = 1, col = scales::alpha(1, 0.1)
)
matplot(grid_p,
  t(y_mat_group),
  main = "Skew-normal",
  xlab = expression(p),
  ylab = expression(hat(Q)(p)),
  type = "l", lty = 1,
  col = scales::alpha(1, 0.1)
)
dev.off()

phi_1 <- function(p) {
  rep(1, length(p))
}
phi_2 <- function(p) {
  qnorm(p = p)
}
phi_3 <- function(p) {
  qnorm(p = p)^2
}

Phi <- cbind(
  phi_1(grid_p),
  phi_2(grid_p),
  phi_3(grid_p)
)
Phi_orth <- sqrt(nrow(Phi)) * qr.Q(qr(Phi))
crossprod(Phi_orth) / nrow(Phi_orth)

coef_y <- y_mat %*% Phi_orth / nrow(Phi_orth)
coef_y_pert <- y_mat_pert %*% Phi_orth / nrow(Phi_orth)
coef_y_group <- y_mat_group %*% Phi_orth / nrow(Phi_orth)

y_mat_proj <- coef_y %*% t(Phi_orth)
y_mat_pert_proj <- coef_y_pert %*% t(Phi_orth)
y_mat_group_proj <- coef_y_group %*% t(Phi_orth)

par(mfrow = c(1, 3))
plot(coef_y[, 1], coef_y[, 2], pch = 20, main = "Original")
plot(coef_y_pert[, 1], coef_y_pert[, 2], pch = 20, main = "Perturbed")
plot(coef_y_group[, 1], coef_y_group[, 2],
  pch = 20,
  col = mu.sd.skew.group$group + 1, main = "Skew-normal"
)
par(mfrow = c(1, 1))


# Plot Manifold data: -----------------------------------------------------
png(file = here::here(
  "figures",
  "manifold-data-group-third-isomap.png"
), width = 12, height = 4, units = "in", res = 400)
coef_all <- rbind(coef_y, coef_y_pert, coef_y_group)
xlim_3d <- range(coef_all[, 1])
ylim_3d <- range(coef_all[, 2])
zlim_3d <- range(coef_all[, 3])

coef_y_df <- data.frame(coef_y, group = factor(x$X9))
coef_y_pert_df <- data.frame(coef_y_pert, group = factor(x$X9))
coef_y_group_df <- data.frame(coef_y_group, group = factor(mu.sd.skew.group$group))

names(coef_y_df)[1:3] <- names(coef_y_pert_df)[1:3] <- c("c1", "c2", "c3")
names(coef_y_group_df)[1:3] <- c("c1", "c2", "c3")
screen_3d <- list(z = 35, x = -65)

p1 <- lattice::cloud(c3 ~ c1 * c2,
  data = coef_y_df,
  groups = group,
  xlim = xlim_3d, ylim = ylim_3d, zlim = zlim_3d,
  screen = screen_3d,
  pch = 20, col = c("dodgerblue3", "tomato3"),
  xlab = "1", ylab = "Phi", zlab = "Phi^2",
  main = "Original Simulation"
)

p2 <- lattice::cloud(c3 ~ c1 * c2,
  data = coef_y_pert_df,
  groups = group,
  xlim = xlim_3d, ylim = ylim_3d, zlim = zlim_3d,
  screen = screen_3d,
  pch = 20, col = c("dodgerblue3", "tomato3"),
  xlab = "1", ylab = "Phi", zlab = "Phi^2",
  main = "Perturbed Sensitivity"
)

p3 <- lattice::cloud(c3 ~ c1 * c2,
  data = coef_y_group_df,
  groups = group,
  xlim = xlim_3d, ylim = ylim_3d, zlim = zlim_3d,
  screen = screen_3d,
  pch = 20, col = c("dodgerblue3", "tomato3"),
  xlab = "1", ylab = "Phi", zlab = "Phi^2",
  main = "Skew-normal"
) # ,
# auto.key = list(columns = 2, title = "X9"))

print(p1, split = c(1, 1, 3, 1), more = TRUE)
print(p2, split = c(2, 1, 3, 1), more = TRUE)
print(p3, split = c(3, 1, 3, 1), more = FALSE)
dev.off()


# Now look at ISOMAP eigenvalues: -----------------------------------------
# settings:
r <- 3
manifold <- list(k = 10)
# distances:
dist.den_1 <- as.matrix(dist(y_mat, upper = T, diag = T)) / sqrt(ncol(y_mat))
dist.den_2 <- as.matrix(dist(y_mat_pert, upper = T, diag = T)) / sqrt(ncol(y_mat_pert))
dist.den_3 <- as.matrix(dist(y_mat_group, upper = T, diag = T)) / sqrt(ncol(y_mat_group))

# isomaps
isomap_object_1 <- vegan::isomap(dist.den_1, k = manifold$k, ndim = r)
isomap_object_2 <- vegan::isomap(dist.den_2, k = manifold$k, ndim = r)
isomap_object_3 <- vegan::isomap(dist.den_3, k = manifold$k, ndim = r)


par(mfrow = c(1, 3))

plot_isomap_eig <- function(eig, main, n_eig = 10, ylim = range(c(eig, 0))) {
  eig <- eig[seq_len(min(n_eig, length(eig)))]
  cols <- ifelse(eig >= 0, "grey30", "tomato3")
  k <- seq_along(eig)
  plot(
    k,
    eig,
    type = "p",
    pch = 20,
    cex = 1.5,
    col = cols,
    ylim = ylim,
    xlab = "ISOMAP dimension",
    ylab = "Signed eigenvalue",
    main = main
  )
  segments(
    x0 = k, y0 = 0, x1 = k, y1 = eig,
    col = "black", lwd = 2
  )
  abline(h = 0, lty = 2)
}


all_eigs <- c(
  isomap_object_1$eig,
  isomap_object_2$eig,
  isomap_object_3$eig
)
ylims <- c(0, max(all_eigs))
png(
  file = here::here("figures", "isomap-eigenvalues-group-third-isomap.png"),
  width = 10, height = 3.5, units = "in", res = 400
)
par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
plot_isomap_eig(isomap_object_1$eig, "Original Simulation", ylim = ylims)
plot_isomap_eig(isomap_object_2$eig, "Sensitivity", ylim = ylims)
plot_isomap_eig(isomap_object_3$eig, "Skew-normal", ylim = ylims)
dev.off()

par(mfrow = c(1, 3))
plot_isomap_eig(isomap_object_1$eig, "Original")
plot_isomap_eig(isomap_object_2$eig, "Perturbed")
plot_isomap_eig(isomap_object_3$eig, "Skew-normal")


# Final, look at geodesic reconstructions: --------------------------------
pointwise_distance_loss <- function(D_true, z) {
  D_hat <- as.matrix(dist(z))
  loss <- numeric(nrow(D_true))

  for (i in seq_len(nrow(D_true))) {
    ind <- setdiff(seq_len(nrow(D_true)), i)
    loss[i] <- sum((D_true[i, ind] - D_hat[i, ind])^2) /
      sum(D_true[i, ind]^2)
  }

  loss
}


D_geo_1 <- as.matrix(vegan::isomapdist(dist.den_1, k = manifold$k))
eps_1 <- pointwise_distance_loss(D_true = D_geo_1, z = isomap_object_1$points)

D_geo_2 <- as.matrix(vegan::isomapdist(dist.den_2, k = manifold$k))
eps_2 <- pointwise_distance_loss(D_true = D_geo_2, z = isomap_object_2$points)


D_geo_3 <- as.matrix(vegan::isomapdist(dist.den_3, k = manifold$k))
isomap_object_3 <- vegan::isomap(dist.den_3, k = manifold$k, ndim = 4)
eps_3_k1 <- pointwise_distance_loss(D_true = D_geo_3, z = isomap_object_3$points[, 1, drop = F])
eps_3_k2 <- pointwise_distance_loss(D_true = D_geo_3, z = isomap_object_3$points[, 1:2])
eps_3_k3 <- pointwise_distance_loss(D_true = D_geo_3, z = isomap_object_3$points[, 1:3])
eps_3_k4 <- pointwise_distance_loss(D_true = D_geo_3, z = isomap_object_3$points[, 1:4])


boxplot(eps_3_k1, eps_3_k2, eps_3_k3, eps_3_k4)


dt_plot <- data.table(X9 = factor(x$X9), eps_3_k1, eps_3_k2, eps_3_k3, eps_3_k4)
dt_plot_lng <- melt.data.table(dt_plot,
  id.vars = "X9",
  value.name = "loss",
  variable.name = "k",
  variable.factor = FALSE
)
dt_plot_lng[, k := stringr::str_remove(k, "eps_3_k")]
dt_plot_lng[, k := as.numeric(k)]
p1 <- ggplot(data = dt_plot_lng) +
  aes(x = factor(k), fill = X9, y = loss) +
  geom_boxplot() +
  labs(
    x = expression("ISOMAP Dimension" ~ (K)),
    y = "Individual Distance Reconstructions"
  ) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold")
  ) +
  ggtitle("Individual Distance Reconstructions for Skew-normal Example") +
  scale_fill_manual(values = c("dodgerblue3", "tomato3"))


ylims <- range(eps_1, eps_2, eps_3_k2, eps_3_k3)


par(mfrow = c(2, 2))
boxplot(eps_1 ~ x$X9, ylim = ylims, col = c("dodgerblue3", "tomato3"))
boxplot(eps_2 ~ x$X9, ylim = ylims, col = c("dodgerblue3", "tomato3"))
boxplot(eps_3_k2 ~ x$X9, ylim = ylims, col = c("dodgerblue3", "tomato3"))
boxplot(eps_3_k3 ~ x$X9, ylim = ylims, col = c("dodgerblue3", "tomato3"))


pca_3 <- prcomp(y_mat_group)

dt_plot_2 <- data.frame(
  Dim3 = isomap_object_3$points[, 3],
  expect_alpha = mu.sd.skew.group$expect_alpha,
  X9 = factor(x$X9)
)
p2 <- ggplot(dt_plot_2) +
  aes(x = expect_alpha, y = Dim3, colour = X9) +
  geom_point() +
  scale_colour_manual(values = c("dodgerblue3", "tomato3")) +
  labs(
    x = expression(E ~ "[" ~ alpha ~ "]"),
    y = "ISOMAP Dim. 3",
    title = "Third ISOMAP Dimension"
  ) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold")
  )

ggpubr::ggarrange(p1,
  p2,
  ncol = 2,
  nrow = 1,
  widths = c(0.65, 0.35),
  common.legend = TRUE, legend = "right"
)


ggsave(
  filename = here::here("figures", "bottom-row-plot.pdf"),
  device = "pdf",
  width = 12,
  height = 4.5
)
