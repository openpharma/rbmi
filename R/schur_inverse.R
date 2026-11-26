#' Invert a symmetric block matrix using its scalar Schur complement
#'
#' Computes the inverse of the block matrix with rows `(A, B)` and
#' `(t(B), C)`, where `C` is scalar. Positivity checks and any
#' model-specific fallback belong to the caller.
#'
#' @param A Leading square block, which must be invertible.
#' @param B Cross block, supplied as a vector.
#' @param C Scalar final block.
#'
#' @return The inverse of the full block matrix, without dimension names,
#'   or `NULL` if the Schur complement is zero or nonfinite.
#' @keywords internal
schur_inverse <- function(A, B, C) {
    block_inverse <- solve(A)
    projection <- drop(block_inverse %*% B)
    schur <- C - sum(B * projection)
    if (!is.finite(schur) || schur == 0) {
        return(NULL)
    }

    unname(rbind(
        cbind(
            block_inverse + tcrossprod(projection) / schur,
            -projection / schur
        ),
        c(-projection / schur, 1 / schur)
    ))
}
