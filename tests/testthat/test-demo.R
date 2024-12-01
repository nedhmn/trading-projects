# ---------------------------------------------------------------------------- #
# File: tests\testthat\demo.R
# Description: Unit testing demo using testthat
# ---------------------------------------------------------------------------- #

#' Test Demo
#'
#' @description
#' Dummy test on multiplcation logic
test_that("multiplication works", {
    expect_equal(2 * 2, 4)
})
