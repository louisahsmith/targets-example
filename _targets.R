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
    model_function(outcome_val = "sleep_wkdy", sex_val = 1, dat = dat)
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
    model_function(outcome_val = outcome, sex_val = sex, dat = dat)
  ),
  tar_target(
    coef_2,
    coef_function(model_2)
  )
)

combined <- tar_combine(
  combined_coefs_2,
  targets_2[["coef_2"]],
  command = vctrs::vec_c(!!!.x),
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
    model_function(outcome_val = outcome_target, sex_val = sex_target, dat = dat),
    pattern = cross(outcome_target, sex_target)
  ),
  tar_target(
    coef_3,
    coef_function(model_3),
    pattern = map(model_3)
  )
)

targets_4 <- list(
  tar_rep(
    bootstrap_coefs,
    dat |>
      dplyr::slice_sample(prop = 1, replace = TRUE) |>
      model_function(
        outcome_val = "sleep_wkdy",
        sex_val = 1, dat = _
      ) |>
      coef_function(),
    batches = 10,
    reps = 10
  )
)

list(
  targets_setup,
  targets_1,
  targets_2,
  combined,
  targets_3,
  targets_4
)

# tar_load(coef_1)
# tar_load(starts_with("coef_2"))
# tar_read(combined_coefs_2)
# tar_read(coef_3)
# tar_read(coef_4)
# tar_load(bootstrap_coefs)
