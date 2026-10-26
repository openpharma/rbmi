# Light wrapper around the Cro et al. supplementary latent-MVN algorithm.
# See cro_latent_mvn_reference.R for the pasted source with prose commented;
# its trial-specific analysis is retained.
# Changes: remove paste artifacts and unused library calls; expose settings;
# preserve factor columns for matrix inputs; qualify calls; return draws instead of running the trial-specific GLM.
# The original algorithm, including its sign convention (Y = 0 iff Z > 0),
# intercept-only latent imputation and treatment coding 1/2, is retained.
# This is reference code, not a general-purpose or validated rbmi implementation.
# In particular, use the demonstrated monotone dropout data with Reference = 1;
# covariate-adjusted imputation and other reference levels need separate review.
cro_latent_mvn <- function(
    Ycat,
    treat1,
    Method = "J2R",
    Reference = 1,
    X = NULL,
    beta.start = NULL,
    l1cov.start = NULL,
    l1cov.prior = NULL,
    MethodVar = NULL,
    RefVar = NULL,
    nburn = 500,
    nbetween = 500,
    nimp = 1000,
    output = 1,
    out.iter = 10,
    seed = 123435
) {
    for (package in c("jomo", "mice", "gear")) {
        if (!requireNamespace(package, quietly = TRUE)) {
            stop("Package '", package, "' is required.", call. = FALSE)
        }
    }
    # Factor columns must retain their levels during the original setup loop.
    Y.cat <- as.data.frame(Ycat)
    treat <- treat1
    if (nimp < 2) {
        nimp <- 2
        cat("Minimum number of imputations: 2.")
    }
    Y.numcat <- NULL
    for (i in 1:ncol(Y.cat)) {
        Y.cat[, i] <- factor(Y.cat[, i]) #turns Y.cat into factor if not already Y.cat.
        Y.numcat <- cbind(Y.numcat, nlevels(Y.cat[, i]))
        #this assumes Ycat contains factors. Y.numcat a vector with no. of categories in each Y.
    }
    if (is.null(X)) {
        X <- matrix(1, nrow(Y.cat), 1)
    }
    if (is.null(beta.start)) {
        beta.start <- matrix(0, ncol(X), ((sum(Y.numcat) - length(Y.numcat))))
    }
    if (is.null(l1cov.start)) {
        l1cov.start <- diag(1, ncol(beta.start))
    }
    if (is.null(l1cov.prior)) {
        l1cov.prior <- diag(1, ncol(beta.start))
    }
    if (is.null(MethodVar)) {
        MethodVar <- matrix(Method, nrow(Y.cat), 1)
    }
    if (is.null(RefVar)) {
        RefVar <- matrix(Reference, nrow(Y.cat), 1)
    }
    #For Methodvar recode MAR/CR/J2R/CIR/LMCF to 1 if MAR; 2 if CR; 3 if J2R; 4 if CIR and 5 if LMCF
    MethodVar[
        MethodVar == "MAR" |
            MethodVar == "mar" |
            MethodVar == "Mar" |
            MethodVar == "MAr" |
            MethodVar == "MaR" |
            MethodVar == "mAr" |
            MethodVar == "maR" |
            MethodVar == "mAR"
    ] <- 1
    MethodVar[
        MethodVar == "CR" |
            MethodVar == "cr" |
            MethodVar == "Cr" |
            MethodVar == "cR"
    ] <- 2
    MethodVar[
        MethodVar == "J2R" |
            MethodVar == "J2r" |
            MethodVar == "j2R" |
            MethodVar == "j2r"
    ] <- 3
    MethodVar[
        MethodVar == "CIR" |
            MethodVar == "cir" |
            MethodVar == "Cir" |
            MethodVar == "ciR"
    ] <- 4
    MethodVar[
        MethodVar == "LMCF" |
            MethodVar == "lmcf" |
            MethodVar == "Lmcf" |
            MethodVar == "LMcf"
    ] <- 5
    MethodVar <- as.factor(MethodVar)
    MethodVarLevels <- levels(MethodVar)
    MethodVarLevels <- as.numeric(MethodVarLevels)
    MethodVar <- as.matrix(MethodVar)
    RefVar <- as.factor(RefVar)
    RefLevels <- levels(RefVar)
    RefLevels <- as.numeric(RefLevels)
    NRefLevels <- nlevels(RefVar)
    RefVar <- as.matrix(RefVar)
    if (any(is.na(Y.cat))) {
        if (ncol(Y.cat) == 1) {
            miss.pat <- matrix(c(1, 0), 2, 1)
            n.patterns <- 2
        } else {
            miss.pat <- mice::md.pattern(Y.cat, plot = F)
            miss.pat <- miss.pat[, colnames(Y.cat)]
            n.patterns <- nrow(miss.pat) - 1
        }
    } else {
        miss.pat <- matrix(0, 2, ncol(Y.cat) + 1)
        n.patterns <- nrow(miss.pat) - 1
    }
    miss.pat.id <- rep(0, nrow(Y.cat))
    for (i in 1:nrow(Y.cat)) {
        k <- 1
        flag <- 0
        while ((k <= n.patterns) & (flag == 0)) {
            if (all(!is.na(Y.cat[i, ]) == miss.pat[k, 1:(ncol(miss.pat))])) {
                miss.pat.id[i] <- k
                flag <- 1
            } else {
                k <- k + 1
            }
        }
    }
    for (i in 1:ncol(X)) {
        if (is.factor(X[, i])) X[, i] <- as.numeric(X[, i])
    }
    stopifnot(
        nrow(beta.start) == ncol(X),
        ncol(beta.start) == ((sum(Y.numcat) - length(Y.numcat))),
        nrow(l1cov.start) == ncol(l1cov.start),
        nrow(l1cov.start) == ncol(beta.start),
        nrow(l1cov.prior) == ncol(l1cov.prior),
        nrow(l1cov.prior) == nrow(l1cov.start)
    )
    betait <- matrix(0, nrow(beta.start), ncol(beta.start))
    for (i in 1:nrow(beta.start)) {
        for (j in 1:ncol(beta.start)) {
            betait[i, j] <- beta.start[i, j]
        }
    }
    covit <- matrix(0, nrow(l1cov.start), ncol(l1cov.start))
    for (i in 1:nrow(l1cov.start)) {
        for (j in 1:ncol(l1cov.start)) {
            covit[i, j] <- l1cov.start[i, j]
        }
    }
    colnamycat <- colnames(Y.cat)
    colnamx <- colnames(X)
    colnamT <- colnames(treat)
    Y.cat <- data.matrix(Y.cat)
    #change Y.cat to 0 if 1 - change Y.cat to 1 if 2 (as required for later use with jomo):
    Y.cat[which(Y.cat == 1)] <- 0
    Y.cat[which(Y.cat == 2)] <- 1
    storage.mode(Y.cat) <- "numeric"
    X <- data.matrix(X)
    storage.mode(X) <- "numeric"
    stopifnot(!any(is.na(X)))
    Y <- cbind(Y.cat)
    Yi <- cbind(matrix(0, nrow(Y.cat), (sum(Y.numcat) - length(Y.numcat))))
    h <- 1
    for (i in 1:length(Y.numcat)) {
        for (j in 1:nrow(Y)) {
            if (is.na(Y.cat[j, i])) {
                Yi[j, h:(h + Y.numcat[i] - 2)] <- NA
            }
        }
        h <- h + Y.numcat[i] - 1
    }
    if (output != 1) {
        out.iter <- nburn + nbetween
    }
    imp <- matrix(0, nrow(Y) * (nimp + 1), ncol(Y) + ncol(X) + 3)
    imp[1:nrow(Y), 1:ncol(Y)] <- Y
    imp[1:nrow(X), (ncol(Y) + 1):(ncol(Y) + ncol(X))] <- X
    imp[1:nrow(X), (ncol(Y) + ncol(X) + 1)] <- c(1:nrow(Y))
    imp[1:nrow(X), (ncol(Y) + ncol(X) + 3)] <- treat1
    Yimp <- Yi
    Zimp <- matrix(Yimp, nrow(Yimp), ncol(Yimp))
    Ui <- matrix(Yimp, nrow(Yimp), ncol(Yimp)) #matrix with 0's or NA where missing for all
    rcount <- (1 * nrow(X)) + 1
    rcount2 <- 2 * nrow(X)
    impZ <- matrix(0, nrow(Y) * (nimp + 1), ncol(Y) + ncol(X) + 4) #create matrix to keep the Z's in.
    impZ[1:nrow(Y), 1:ncol(Y)] <- Y
    impZ[1:nrow(X), (ncol(Y) + 1):(ncol(Y) + ncol(X))] <- X
    impZ[1:nrow(X), (ncol(Y) + ncol(X) + 1)] <- c(1:nrow(Y))
    impZ[1:nrow(X), (ncol(Y) + ncol(X) + 3)] <- treat1
    impZ[1:nrow(X), (ncol(Y) + ncol(X) + 4)] <- miss.pat.id
    for (i in 1:nimp) {
        imp[rcount:rcount2, (ncol(Y) + 1):(ncol(Y) + ncol(X))] <- X
        imp[rcount:rcount2, (ncol(Y) + ncol(X) + 1)] <- c(1:nrow(Y))
        imp[rcount:rcount2, (ncol(Y) + ncol(X) + 2)] <- i
        imp[rcount:rcount2, (ncol(Y) + ncol(X) + 3)] <- treat1
        rcount <- ((i + 1) * nrow(X)) + 1
        rcount2 <- ((i + 2) * nrow(X))
    }
    rcount <- (1 * nrow(X)) + 1
    rcount2 <- 2 * nrow(X)
    for (i in 1:nimp) {
        impZ[rcount:rcount2, (ncol(Y) + 1):(ncol(Y) + ncol(X))] <- X
        impZ[rcount:rcount2, (ncol(Y) + ncol(X) + 1)] <- c(1:nrow(Y))
        impZ[rcount:rcount2, (ncol(Y) + ncol(X) + 2)] <- i
        impZ[rcount:rcount2, (ncol(Y) + ncol(X) + 3)] <- treat1
        impZ[rcount:rcount2, (ncol(Y) + ncol(X) + 4)] <- miss.pat.id
        rcount <- ((i + 1) * nrow(X)) + 1
        rcount2 <- ((i + 2) * nrow(X))
    }
    treat <- data.matrix(treat)
    t1 <- c(1)
    t2 <- c(2)
    Y.cat1 <- Y.cat[treat %in% t1, , drop = FALSE]
    Y.cat2 <- Y.cat[treat %in% t2, , drop = FALSE]
    X1 <- X[treat %in% t1, ]
    X2 <- X[treat %in% t2, ]
    X1 <- data.matrix(X1)
    X2 <- data.matrix(X2)
    Y.cat1 <- data.frame(Y.cat1)
    Y.cat1 <- data.frame(lapply(Y.cat1, factor))
    Y.cat2 <- data.frame(Y.cat2)
    Y.cat2 <- data.frame(lapply(Y.cat2, factor))
    if (!is.null(seed)) {
        set.seed(seed)
    }
    burn <- nburn + ((nimp - 1) * nbetween)
    #If no missing data in treatment arm 1:
    if (all(!is.na(Y.cat1[,]))) {
        #add an extra row on Y.cat1 with NA for all the values
        nrow(Y.cat1)
        dummy <- data.frame(matrix(NA, 1, ncol(Y.cat1)))
        names(dummy) <- names(Y.cat1)
        Y.cat1 <- rbind(Y.cat1, dummy)
        dummyX <- matrix(1, 1, ncol(X1)) #unadjusted case.
        X1 <- c(X1, dummyX)
        X1 <- data.frame(X1)
    }
    #If no missing data in treatment arm 2:
    if (all(!is.na(Y.cat2[,]))) {
        #add an extra row on Y.cat2 with NA for all the values
        nrow(Y.cat2)
        dummy <- data.frame(matrix(NA, 1, ncol(Y.cat2)))
        names(dummy) <- names(Y.cat2)
        Y.cat2 <- rbind(Y.cat2, dummy)
        dummyX <- matrix(1, 1, ncol(X2)) #unadjusted case
        X2 <- c(X2, dummyX)
        X2 <- data.frame(X2)
    }
    mcmc1 <- jomo::jomo1cat.MCMCchain(
        Y.cat = Y.cat1,
        Y.numcat = Y.numcat,
        X = X1,
        beta.start = beta.start,
        l1cov.start = l1cov.start,
        nburn = burn,
        output = 1,
        out.iter = 10
    )
    mcmc2 <- jomo::jomo1cat.MCMCchain(
        Y.cat = Y.cat2,
        Y.numcat = Y.numcat,
        X = X2,
        beta.start = beta.start,
        l1cov.start = l1cov.start,
        nburn = burn,
        output = 1,
        out.iter = 10
    )
    #Drop the burn in and the burn between
    burn1 <- 1 + ((nimp - 1) * nbetween)
    mcmc1betaneed <- array(
        0,
        dim = c(nrow(beta.start), ncol(beta.start), (nimp))
    )
    mcmc1betaneedT <- array(
        0,
        dim = c(nrow(beta.start), ncol(beta.start), (burn1))
    )
    mcmc1betaneedT <- mcmc1$collectbeta[,, nburn:burn, drop = FALSE]
    row_between <- seq_len(dim(mcmc1betaneedT)[3]) %% nbetween
    burn_keep <- which(row_between == 1)
    mcmc1betaneed <- mcmc1betaneedT[,, burn_keep, drop = FALSE]
    mcmc2betaneed <- array(
        0,
        dim = c(nrow(beta.start), ncol(beta.start), (nimp))
    )
    mcmc2betaneedT <- array(
        0,
        dim = c(nrow(beta.start), ncol(beta.start), (burn1))
    )
    mcmc2betaneedT <- mcmc2$collectbeta[,, nburn:burn, drop = FALSE]
    mcmc2betaneed <- mcmc2betaneedT[,, burn_keep, drop = FALSE]
    mcmc1omeganeed <- array(
        0,
        dim = c(nrow(l1cov.start), ncol(l1cov.start), (nimp))
    )
    mcmc2omeganeed <- array(
        0,
        dim = c(nrow(l1cov.start), ncol(l1cov.start), (nimp))
    )
    mcmc1omeganeedT <- array(
        0,
        dim = c(nrow(l1cov.start), ncol(l1cov.start), (burn1))
    )
    mcmc2omeganeedT <- array(
        0,
        dim = c(nrow(l1cov.start), ncol(l1cov.start), (burn1))
    )
    mcmc1omeganeedT <- mcmc1$collectomega[,, nburn:burn, drop = FALSE]
    mcmc2omeganeedT <- mcmc2$collectomega[,, nburn:burn, drop = FALSE]
    mcmc1omeganeed <- mcmc1omeganeedT[,, burn_keep, drop = FALSE]
    mcmc2omeganeed <- mcmc2omeganeedT[,, burn_keep, drop = FALSE]
    #We now have the beta's [means] and omegas [variances] by treatment arm:
    #mcmc1$collectbeta, mcmc2$collectbeta, mcmc1$collectomega and mcmc2$collectomega.
    #For patients with no missing data copy complete data into newly imputed data
    if (sum(miss.pat[1, ]) == length(miss.pat[1, ])) {
        positioncomplete <- which(miss.pat.id == 1)
        for (i in 1:nimp) {
            posititionimp <- positioncomplete + i * nrow(Y.cat)
            imp[posititionimp, 1:ncol(Y.cat)] <- Y.cat[
                positioncomplete,
                1:ncol(Y.cat),
                drop = FALSE
            ]
            #0's remain where have missing data for all Y's
        }
        startbuild <- 2
    } else {
        startbuild <- 1
    }
    #Now impute for the people with missing data:
    #1 - For each treatment group & missing data pattern and method (i) create a new array for mean and
    #covariance [so one for each imputation draw] (ii) compute appropriate joint distribution using
    #beta's and omega's
    #2 - then using (1) draw Z's (sequentially from 1 to number of Y's i.e draw Z1 then Z1| Z2 then
    #Z1|Z2,Z3 etc..)
    #3 - then using (2) get the Y's and put these into Y.cat
    #4 - then put Y.cat [complete and imputed Y] into imputed data
    for (j in 1:2) {
        #Treat always 1 or 2
        for (k in startbuild:n.patterns) {
            for (q in MethodVarLevels) {
                #recoded above so always 1 to 5
                for (v in NRefLevels) {
                    imp_pos <- which(
                        miss.pat.id == k &
                            treat == j &
                            MethodVar == q &
                            RefVar == v
                    )
                    if (!(is.integer(imp_pos) && length(imp_pos) == 0)) {
                        #if there are people in this combination of treat/pattern id/method/reference then impute:
                        subsetS <- Y.cat[imp_pos, , drop = FALSE]
                        if (is.null(nrow(subsetS))) {
                            #if only one person in this pattern
                            index_miss <- which(is.na(subsetS), arr.ind = T)
                            index_Nmiss <- which(!is.na(subsetS), arr.ind = T)
                        } else {
                            #if more than one person in the miss/treat/etc combination
                            subsetSNA <- colSums(is.na(subsetS))
                            index_miss <- which(subsetSNA != 0, arr.ind = T)
                            index_Nmiss <- which(subsetSNA == 0, arr.ind = T)
                        }
                        Lindex_miss <- length(index_miss)
                        Lindex_Nmiss <- length(index_Nmiss)
                        #Start with an empty array for mean and covariance
                        betapost <- array(
                            0,
                            dim = c(nrow(beta.start), ncol(beta.start), (nimp))
                        )
                        omegapost <- array(
                            0,
                            dim = c(
                                nrow(l1cov.start),
                                ncol(l1cov.start),
                                (nimp)
                            )
                        )
                        #Form joint distribution as required [for each imputation]:
                        #Define own arm beta and omega:
                        if (j == 1) {
                            mcmcTREATbetaneed <- mcmc1betaneed
                            mcmcTREATomeganeed <- mcmc1omeganeed
                        }
                        if (j == 2) {
                            mcmcTREATbetaneed <- mcmc2betaneed
                            mcmcTREATomeganeed <- mcmc2omeganeed
                        }
                        #If one of the reference methods: 2,3 or 4:
                        if (q %in% c(2, 3, 4)) {
                            #Define reference arm beta and omega:
                            if (v == 1) {
                                mcmcREFbetaneed <- mcmc1betaneed
                                mcmcREFomeganeed <- mcmc1omeganeed
                            }
                            if (v == 2) {
                                mcmcREFbetaneed <- mcmc2betaneed
                                mcmcREFomeganeed <- mcmc2omeganeed
                            }
                        }
                        #MAR=1
                        if (MethodVar[imp_pos[1], 1] == 1) {
                            betapost <- array(
                                mcmcTREATbetaneed,
                                dim = c(
                                    nrow(beta.start),
                                    ncol(beta.start),
                                    (nimp)
                                )
                            )
                            omegapost <- array(
                                mcmcTREATomeganeed,
                                dim = c(
                                    nrow(l1cov.start),
                                    ncol(l1cov.start),
                                    (nimp)
                                )
                            )
                        }
                        #CR=2
                        if (MethodVar[imp_pos[1], 1] == 2) {
                            betapost <- array(
                                mcmcREFbetaneed,
                                dim = c(
                                    nrow(beta.start),
                                    ncol(beta.start),
                                    (nimp)
                                )
                            )
                            omegapost <- array(
                                mcmcREFomeganeed,
                                dim = c(
                                    nrow(l1cov.start),
                                    ncol(l1cov.start),
                                    (nimp)
                                )
                            )
                        }
                        #J2R=3
                        if (MethodVar[imp_pos[1], 1] == 3) {
                            betapost <- array(
                                mcmcTREATbetaneed,
                                dim = c(
                                    nrow(beta.start),
                                    ncol(beta.start),
                                    (nimp)
                                )
                            )
                            betapost[, index_miss, ] <- mcmcREFbetaneed[,
                                index_miss,
                            ]
                            omegapost <- array(
                                mcmcREFomeganeed,
                                dim = c(
                                    nrow(l1cov.start),
                                    ncol(l1cov.start),
                                    (nimp)
                                )
                            )
                        }
                        #CIR=4
                        if (MethodVar[imp_pos[1], 1] == 4) {
                            betapost <- array(
                                mcmcTREATbetaneed,
                                dim = c(
                                    nrow(beta.start),
                                    ncol(beta.start),
                                    (nimp)
                                )
                            )
                            cc <- sort(index_miss)
                            for (w in 1:Lindex_miss) {
                                if (cc[w] == 1) {
                                    betapost[, 1, ] <- mcmcREFbetaneed[, 1, ]
                                } else {
                                    betapost[, cc[w], ] <- betapost[,
                                        cc[w] - 1,
                                    ] +
                                        mcmcREFbetaneed[, cc[w], ] -
                                        mcmcREFbetaneed[, cc[w] - 1, ]
                                }
                            }
                            omegapost <- array(
                                mcmcREFomeganeed,
                                dim = c(
                                    nrow(l1cov.start),
                                    ncol(l1cov.start),
                                    (nimp)
                                )
                            )
                        }
                        #LMCF=5
                        if (MethodVar[imp_pos[1], 1] == 5) {
                            betapost <- array(
                                mcmcTREATbetaneed,
                                dim = c(
                                    nrow(beta.start),
                                    ncol(beta.start),
                                    (nimp)
                                )
                            )
                            cc <- sort(index_miss)
                            for (w in 1:Lindex_miss) {
                                if (cc[w] > 1) {
                                    betapost[, cc[w], ] <- betapost[,
                                        cc[w] - 1,
                                    ]
                                }
                            }
                            omegapost <- array(
                                mcmcTREATomeganeed,
                                dim = c(
                                    nrow(l1cov.start),
                                    ncol(l1cov.start),
                                    (nimp)
                                )
                            )
                        }
                        test_ind <- matrix(0, nrow(Y), 1)
                        test_ind[imp_pos, 1] <- 1 #matrix where 1 indicates part of current group imputing for
                        #For each imputation [for each person with missing data]
                        #draw first Z1 from appropriate normal distribution:
                        for (m in 1:nimp) {
                            #Draw First Z:
                            Zimp[imp_pos, 1] <- rnorm(
                                length(imp_pos),
                                betapost[1, 1, m],
                                1
                            ) #always sd=1 as binary latent
                            #Compare Zimp to Y - note original Y as 0 and 1
                            Y1_test <- Y[, 1, drop = FALSE]
                            Zimp2_test <- Zimp[, 1, drop = FALSE]
                            Z1 <- which(
                                Y1_test == 0 & Zimp2_test > 0 & test_ind == 1
                            )
                            Z2 <- which(
                                Y1_test == 1 & Zimp2_test <= 0 & test_ind == 1
                            )
                            tst <- c(Z1, Z2)
                            Z3 <- which(is.na(Y1_test) & test_ind == 1)
                            if (length(Z3) > 0) {
                                tst <- c(Z1, Z2, Z3)
                            }
                            test <- imp_pos[!imp_pos %in% tst] #those in group that need a new Z drawn
                            counter_1 <- 0
                            while (length(test) >= 1) {
                                counter_1 <- counter_1 + 1
                                #always sd=1 as binary latent
                                Zimp[test, 1] <- rnorm(
                                    length(test),
                                    mean = betapost[1, 1, m],
                                    sd = 1
                                )
                                Zimp2_test <- Zimp[, 1, drop = FALSE]
                                Z1 <- which(
                                    Y1_test == 0 &
                                        Zimp2_test > 0 &
                                        test_ind == 1
                                )
                                Z2 <- which(
                                    Y1_test == 1 &
                                        Zimp2_test <= 0 &
                                        test_ind == 1
                                )
                                tst <- c(Z1, Z2)
                                test <- imp_pos[!imp_pos %in% tst]
                            }
                            #Loop over remaining number of Z's and draw Z's
                            if (ncol(Y.cat) > 1) {
                                for (z in 2:ncol(Y.cat)) {
                                    pminus1 <- z - 1
                                    Zgiven <- seq(1, pminus1, by = 1)
                                    S11post <- matrix(
                                        0,
                                        length(Zgiven),
                                        length(Zgiven)
                                    )
                                    S12post <- matrix(
                                        0,
                                        length(Zgiven),
                                        length(z)
                                    )
                                    S22post <- matrix(0, length(z), length(z))
                                    S11post <- matrix(
                                        omegapost[Zgiven, Zgiven, m],
                                        length(Zgiven),
                                        length(Zgiven)
                                    )
                                    S12post <- matrix(
                                        omegapost[Zgiven, z, m],
                                        length(Zgiven),
                                        length(z)
                                    )
                                    S22post <- matrix(
                                        omegapost[z, z, m],
                                        length(z),
                                        length(z)
                                    )
                                    chola <- chol(S11post[,])
                                    te <- as.matrix(gear::solve_chol(
                                        chola,
                                        S12post[,]
                                    ))
                                    conds <- S22post[,] - (t(S12post[,]) %*% te)
                                    U <- chol(conds)
                                    means_1 <- matrix(
                                        betapost[1, Zgiven, m],
                                        byrow = TRUE,
                                        length(imp_pos),
                                        length(Zgiven)
                                    )
                                    means_2 <- matrix(
                                        betapost[1, z, m],
                                        byrow = TRUE,
                                        length(imp_pos),
                                        length(z)
                                    )
                                    raw <- matrix(
                                        Zimp[imp_pos, Zgiven],
                                        byrow = FALSE,
                                        length(imp_pos),
                                        length(Zgiven)
                                    )
                                    dime <- length(imp_pos) * length(z)
                                    Normal_Z <- matrix(
                                        rnorm(dime),
                                        nrow = length(imp_pos)
                                    )
                                    mean_val <- means_2 +
                                        ((raw - means_1) %*% te)
                                    Zimp[imp_pos, z] <- mean_val +
                                        (Normal_Z %*% U)
                                    if (any(!is.na(Y[imp_pos, z]))) {
                                        Y1_test <- Y[, z]
                                        Zimp2_test <- Zimp[, z]
                                        Z1 <- which(
                                            Y1_test == 0 &
                                                Zimp2_test > 0 &
                                                test_ind == 1
                                        )
                                        Z2 <- which(
                                            Y1_test == 1 &
                                                Zimp2_test <= 0 &
                                                test_ind == 1
                                        )
                                        tst <- c(Z1, Z2)
                                        test <- imp_pos[!imp_pos %in% tst] #those in group that need a new Z drawn
                                        counter_2 <- 0
                                        while (length(test) >= 1) {
                                            #Draw new z's - with break condition using Carpenter, Kenward 2013:
                                            counter_2 <- counter_2 + 1
                                            if (counter_2 == 1000000) {
                                                #calculate the probability that Z<0
                                                #then if Y =0 draw from uniform 0 to p
                                                #otherwise draw from u uniform p to 1
                                                alarm <- 1
                                                U
                                                U_n <- matrix(
                                                    U,
                                                    byrow = TRUE,
                                                    length(test),
                                                    length(z)
                                                )
                                                Q_n <- matrix(
                                                    0,
                                                    byrow = TRUE,
                                                    length(test),
                                                    length(z)
                                                )
                                                means_1_n <- matrix(
                                                    betapost[1, Zgiven, m],
                                                    byrow = TRUE,
                                                    length(test),
                                                    length(Zgiven)
                                                )
                                                means_2_n <- matrix(
                                                    betapost[1, z, m],
                                                    byrow = TRUE,
                                                    length(test),
                                                    length(z)
                                                )
                                                raw_n <- matrix(
                                                    Zimp[test, Zgiven],
                                                    byrow = FALSE,
                                                    length(test),
                                                    length(Zgiven)
                                                )
                                                mean_val_n <- means_2_n +
                                                    ((raw_n - means_1_n) %*% te)
                                                Pi <- pnorm(
                                                    Q_n,
                                                    mean = mean_val_n,
                                                    sd = U_n
                                                )
                                                #For each person that needs a new Z:
                                                for (pos in 1:length(Pi)) {
                                                    person <- test[pos]
                                                    if (
                                                        Y1_test[person] == 1 &
                                                            test_ind[person] ==
                                                                1
                                                    ) {
                                                        Ui[person, z] <- runif(
                                                            1,
                                                            min = Pi[pos],
                                                            max = 1
                                                        )
                                                    }
                                                    if (
                                                        Y1_test[person] == 0 &
                                                            test_ind[person] ==
                                                                1
                                                    ) {
                                                        Ui[person, z] <- runif(
                                                            1,
                                                            min = 0,
                                                            max = Pi[pos]
                                                        )
                                                    }
                                                    Ui[person, z] <- qnorm(
                                                        Ui[person, z],
                                                        mean = mean_val_n[pos],
                                                        sd = U_n[pos]
                                                    )
                                                    Zimp[person, z] <- Ui[
                                                        person,
                                                        z
                                                    ]
                                                }
                                                break
                                            }
                                            #If corresponding Y is observed - accept/reject stage
                                            dime <- length(test) * length(z)
                                            Normal_Z <- matrix(
                                                rnorm(dime),
                                                nrow = length(test)
                                            )
                                            positionT <- which(
                                                imp_pos %in% test == TRUE
                                            )
                                            Zimp[test, z] <- mean_val[
                                                positionT
                                            ] +
                                                (Normal_Z %*% U)
                                            Zimp2_test <- Zimp[, z]
                                            Z1 <- which(
                                                Y1_test == 0 &
                                                    Zimp2_test > 0 &
                                                    test_ind == 1
                                            )
                                            Z2 <- which(
                                                Y1_test == 1 &
                                                    Zimp2_test <= 0 &
                                                    test_ind == 1
                                            )
                                            tst <- c(Z1, Z2)
                                            test <- imp_pos[!imp_pos %in% tst]
                                        }
                                    }
                                }
                            }
                            #Now drawn Z values - add in newly imputed Y values based on Z:
                            Yimp[imp_pos, index_miss] <- ifelse(
                                Zimp[imp_pos, index_miss] > 0,
                                0,
                                1
                            )
                            #Put this data into imputation m
                            imp_pos_k <- imp_pos + (nrow(Y) * m)
                            imp[imp_pos_k, index_miss] <- Yimp[
                                imp_pos,
                                index_miss
                            ]
                            imp[imp_pos_k, index_Nmiss] <- Y[
                                imp_pos,
                                index_Nmiss
                            ]
                            impZ[imp_pos_k, index_miss] <- Zimp[
                                imp_pos,
                                index_miss
                            ]
                            impZ[imp_pos_k, index_Nmiss] <- Zimp[
                                imp_pos,
                                index_Nmiss
                            ]
                            #Reset items for next imputation iteration:
                            Yimp <- Yi
                            Zimp <- matrix(Yimp, nrow(Yimp), ncol(Yimp))
                        }
                    }
                }
            }
        }
        #reset for posting new data:
        Y <- cbind(Y.cat)
        Yi <- cbind(matrix(0, nrow(Y.cat), (sum(Y.numcat) - length(Y.numcat))))
        h <- 1
        for (i in 1:length(Y.numcat)) {
            for (j in 1:nrow(Y)) {
                if (is.na(Y.cat[j, i])) {
                    Yi[j, h:(h + Y.numcat[i] - 2)] <- NA
                }
            }
            h <- h + Y.numcat[i] - 1
        }
        Yimp <- Yi
        Zimp <- matrix(Yimp, nrow(Yimp), ncol(Yimp))
    }
    imp <- data.frame(imp)
    #We now have the imputed data set in data frame imp - post imputation processing below
    imp[, ncol(imp)] <- as.factor(imp[, ncol(imp)])
    if (is.null(colnamycat)) {
        colnamycat <- paste("Y", 1:ncol(Y.cat), sep = "")
    }
    if (is.null(colnamx)) {
        colnamx <- paste("X", 1:ncol(X), sep = "")
    }
    if (is.null(colnamT)) {
        colnamT <- ("Treat")
    }
    if (ncol(X) == 1) {
        colnames(imp) <- c(colnamycat, colnamx, "id", "Imputation", colnamT)
    }

    colnames(impZ) <- c(colnames(imp), "missing_pattern")
    list(
        imp = imp,
        impZ = as.data.frame(impZ),
        beta = list(reference = mcmc1betaneed, active = mcmc2betaneed),
        omega = list(reference = mcmc1omeganeed, active = mcmc2omeganeed)
    )
}
