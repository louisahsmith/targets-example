library(targets)
library(tarchetypes)
tar_source()

targets_setup <- list(
  tar_target(
    csv,
    "data/nlsy.csv",
    format = "file"
  ),
  tar_target(
    dat,
    readr::read_csv(csv, show_col_types = FALSE)
  )
)

targets_1 <- list(
  tar_target(
    model_1,
    model_function(outcome_var = "sleep_wkdy", sex_val = 1, dat = dat)
  ),
  tar_target(
    coef_1,
    coef_function(model_1)
  )
)

targets_2 <- tar_map(
  values = tidyr::crossing(
    outcome = c("sleep_wkdy", "sleep_wknd"),
    sex = 1:2
  ),
  tar_target(
    model_2,
    model_function(outcome_var = outcome, sex_val = sex, dat = dat)
  ),
  tar_target(
    coef_2,
    coef_function(model_2)
  )
)

combined <- tar_combine(
  combined_coefs_2,
  targets_2[["coef_2"]],
  command = vctrs::vec_c(!!!.x)
)

targets_3 <- list(
  tar_target(
    outcome_target,
    c("sleep_wkdy", "sleep_wknd")
  ),
  tar_target(
    sex_target,
    1:2
  ),
  tar_target(
    model_3,
    model_function(outcome_var = outcome_target, sex_val = sex_target, dat = dat),
    pattern = cross(outcome_target, sex_target)
  ),
  tar_target(
    coef_3,
    coef_function(model_3),
    pattern = map(model_3)
  )
)

targets_4 <- tar_rep(
    bootstrap_coefs,
    dat |>
      dplyr::slice_sample(prop = 1, replace = TRUE) |>
      model_function(outcome_var = "sleep_wkdy", sex_val = 1, dat = _) |>
      coef_function(),
    batches = 10,
    reps = 10
  )

sensitivity_scenarios <- tibble::tibble(
  error = c("small", "medium", "large"),
  mean = c(1, 2, 3),
  sd = c(0.5, 0.75, 1)
)

targets_5 <- tar_map_rep(
  sensitivity_analysis,
  dat |> 
    dplyr::mutate(sleep_wkdy = sleep_wkdy + rnorm(nrow(dat), mean, sd)) |>
    model_function(outcome_var = "sleep_wkdy", sex_val = 1, dat = _) |>
    coef_function() |> 
    data.frame(coef = _),
  values = sensitivity_scenarios,
  batches = 10,
  reps = 10
)

list(
  targets_setup,
  targets_1,
  targets_2,
  combined,
  targets_3,
  targets_4,
  targets_5
)

# tar_read(coef_1)
# tar_load(starts_with("coef_2"))
# tar_read(combined_coefs_2)
# tar_read(coef_3)
# tar_read(bootstrap_coefs)
# tar_read(sensitivity_analysis)

# tar_read(sensitivity_analysis) |>
#   dplyr::group_by(error) |> 
#   dplyr::summarize(q25 = quantile(coef, .25),
#                    median = median(coef),
#                    q75 = quantile(coef, .75))
