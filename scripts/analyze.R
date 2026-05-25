data <- read.csv("data/final_dataset.csv")

metrics <- c("brightness_median", "saturation_median", "hue_median")

data$group <- factor(data$group, levels = c("ai", "human"))
data$category <- factor(data$category)

dir.create("results/recomputed", recursive = TRUE, showWarnings = FALSE)

desc <- aggregate(
  data[metrics],
  by = list(category = data$category, group = data$group),
  FUN = function(x) c(n = length(x), mean = mean(x), sd = sd(x), min = min(x), max = max(x))
)
write.csv(desc, "results/recomputed/descriptive_statistics.csv", row.names = FALSE)

cohens_d <- function(x, y) {
  nx <- length(x)
  ny <- length(y)
  pooled_sd <- sqrt(((nx - 1) * var(x) + (ny - 1) * var(y)) / (nx + ny - 2))
  (mean(x) - mean(y)) / pooled_sd
}

t_results <- data.frame()

for (cat in levels(data$category)) {
  subset_cat <- data[data$category == cat, ]
  for (metric in metrics) {
    ai_values <- subset_cat[subset_cat$group == "ai", metric]
    human_values <- subset_cat[subset_cat$group == "human", metric]
    tt <- t.test(ai_values, human_values)
    d <- cohens_d(ai_values, human_values)
    row <- data.frame(
      category = cat,
      metric = metric,
      ai_mean = mean(ai_values),
      human_mean = mean(human_values),
      t = unname(tt$statistic),
      df = unname(tt$parameter),
      p = tt$p.value,
      cohens_d = d
    )
    t_results <- rbind(t_results, row)
  }
}

write.csv(t_results, "results/recomputed/welch_t_tests.csv", row.names = FALSE)

manova_model <- manova(
  cbind(brightness_median, saturation_median, hue_median) ~ group * category,
  data = data
)

manova_summary <- summary(manova_model, test = "Pillai")
capture.output(manova_summary, file = "results/recomputed/manova_pillai.txt")

