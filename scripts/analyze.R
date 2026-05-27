if (!requireNamespace("car", quietly = TRUE)) {
  stop("The 'car' package is required for Levene tests.")
}

dir.create("results", showWarnings = FALSE)

raw_data <- read.csv("data/final_dataset.csv", stringsAsFactors = FALSE)

category_map <- c(
  portrait = "Portre",
  landscape = "Manzara",
  abstract = "Soyut",
  cityscape = "Kentsel"
)

metric_map <- c(
  brightness_median = "Brightness",
  saturation_median = "Saturation",
  hue_median = "Hue"
)

category_levels <- c("Portre", "Manzara", "Soyut", "Kentsel")
group_levels <- c("AI", "Human")
metric_cols <- names(metric_map)

data <- data.frame(
  image_id = raw_data$index_in_set,
  brightness_median = raw_data$brightness_median,
  brightness_stdev = raw_data$brightness_stdev,
  saturation_median = raw_data$saturation_median,
  saturation_stdev = raw_data$saturation_stdev,
  hue_median = raw_data$hue_median,
  hue_stdev = raw_data$hue_stdev,
  group = ifelse(raw_data$group == "ai", "AI", "Human"),
  category = unname(category_map[raw_data$category])
)

data$category <- factor(data$category, levels = category_levels)
data$group <- factor(data$group, levels = group_levels)
data <- data[order(data$category, data$group, data$image_id), ]

significance_label <- function(p_value) {
  if (p_value < .001) {
    "***"
  } else if (p_value < .01) {
    "**"
  } else if (p_value < .05) {
    "*"
  } else {
    "ns"
  }
}

cohens_d <- function(x, y) {
  nx <- length(x)
  ny <- length(y)
  pooled_sd <- sqrt(((nx - 1) * var(x) + (ny - 1) * var(y)) / (nx + ny - 2))
  (mean(x) - mean(y)) / pooled_sd
}

effect_size_label <- function(d_value) {
  abs_d <- abs(d_value)
  if (abs_d < .2) {
    "ihmal edilebilir"
  } else if (abs_d < .5) {
    "kucuk"
  } else if (abs_d < .8) {
    "orta"
  } else {
    "buyuk"
  }
}

descriptive_results <- data.frame()
cohens_d_results <- data.frame()
levene_results <- data.frame()
t_test_results <- data.frame()

for (cat_name in category_levels) {
  category_data <- data[data$category == cat_name, ]

  for (metric_col in metric_cols) {
    metric_name <- unname(metric_map[metric_col])
    ai_values <- category_data[category_data$group == "AI", metric_col]
    human_values <- category_data[category_data$group == "Human", metric_col]

    for (group_name in group_levels) {
      group_values <- category_data[category_data$group == group_name, metric_col]
      descriptive_results <- rbind(
        descriptive_results,
        data.frame(
          Kategori = cat_name,
          Metrik = metric_name,
          Grup = group_name,
          n = length(group_values),
          Ortalama = round(mean(group_values), 2),
          SD = round(sd(group_values), 2),
          Min = min(group_values),
          Max = max(group_values)
        )
      )
    }

    d_value <- cohens_d(ai_values, human_values)
    cohens_d_results <- rbind(
      cohens_d_results,
      data.frame(
        Kategori = cat_name,
        Metrik = metric_name,
        Cohens_d = round(d_value, 3),
        Etki_Buyuklugu = effect_size_label(d_value)
      )
    )

    levene_data <- data.frame(
      value = c(ai_values, human_values),
      group = factor(
        c(rep("AI", length(ai_values)), rep("Human", length(human_values))),
        levels = group_levels
      )
    )
    levene_test <- car::leveneTest(value ~ group, data = levene_data, center = median)
    levene_f <- levene_test[["F value"]][1]
    levene_p <- levene_test[["Pr(>F)"]][1]

    levene_results <- rbind(
      levene_results,
      data.frame(
        Kategori = cat_name,
        Metrik = metric_name,
        AI_Varyans = round(var(ai_values), 2),
        Human_Varyans = round(var(human_values), 2),
        Oran_Human_AI = round(var(human_values) / var(ai_values), 2),
        Levene_F = round(levene_f, 3),
        p_degeri = round(levene_p, 4),
        Anlamlilik = significance_label(levene_p)
      )
    )

    t_test <- t.test(ai_values, human_values)
    t_test_results <- rbind(
      t_test_results,
      data.frame(
        Kategori = cat_name,
        Metrik = metric_name,
        t_degeri = round(unname(t_test$statistic), 3),
        df = round(unname(t_test$parameter), 1),
        p_degeri = round(t_test$p.value, 4),
        Anlamlilik = significance_label(t_test$p.value),
        AI_Ortalama = round(mean(ai_values), 2),
        Human_Ortalama = round(mean(human_values), 2)
      )
    )
  }
}

write.csv(descriptive_results, "results/02_betimsel_istatistikler.csv", row.names = FALSE)
write.csv(cohens_d_results, "results/03_cohens_d.csv", row.names = FALSE)
write.csv(levene_results, "results/04_levene_testi.csv", row.names = FALSE)
write.csv(t_test_results, "results/05_t_testleri.csv", row.names = FALSE)

manova_model <- manova(
  cbind(brightness_median, saturation_median, hue_median) ~ group * category,
  data = data
)

manova_summary <- as.data.frame(summary(manova_model, test = "Pillai")$stats)
manova_summary$Pillai <- round(manova_summary$Pillai, 6)
manova_summary$`approx F` <- round(manova_summary$`approx F`, 4)
manova_summary$`Pr(>F)` <- formatC(manova_summary$`Pr(>F)`, format = "e", digits = 3)
write.csv(manova_summary, "results/06_manova.csv")

cat("Analysis outputs written to results/02-06 files.\n")
