
model_function <- function(outcome_val, sex_val = 1:2, dat) {
  lm(as.formula(paste(outcome_val, " ~ age_bir + income + factor(region)")) ,
     data = dat, subset = sex %in% sex_val)
}

coef_function <- function(model) {
  coef(model)[["age_bir"]]
}
