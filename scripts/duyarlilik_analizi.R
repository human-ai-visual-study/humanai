library(pwr)

data_candidates <- c(
  "results/01_tum_veri.csv",
  "../results/01_tum_veri.csv",
  "r_cikti/01_tum_veri.csv",
  "../r_cikti/01_tum_veri.csv",
  "../../r_cikti/01_tum_veri.csv"
)

data_path <- data_candidates[file.exists(data_candidates)][1]
if (is.na(data_path)) {
  stop("01_tum_veri.csv bulunamadi.")
}

output_candidates <- c("results", "../results", "r_cikti", "../r_cikti", "../../r_cikti")
output_dir <- output_candidates[dir.exists(output_candidates)][1]
if (is.na(output_dir)) {
  stop("Cikti klasoru bulunamadi.")
}

data <- read.csv(data_path, stringsAsFactors = FALSE)

alpha_values <- data.frame(
  alpha_label = c("alpha_0.05", "bonferroni_0.0042"),
  alpha = c(.05, .0042),
  stringsAsFactors = FALSE
)

counts <- aggregate(
  image_id ~ category + group,
  data = data,
  FUN = length
)
names(counts)[names(counts) == "image_id"] <- "n"

categories <- sort(unique(data$category))
results <- data.frame()

for (cat_name in categories) {
  cat_counts <- counts[counts$category == cat_name, ]
  n_ai <- cat_counts$n[cat_counts$group == "AI"]
  n_human <- cat_counts$n[cat_counts$group == "Human"]

  if (length(n_ai) != 1 || length(n_human) != 1) {
    stop(paste("Eksik grup sayisi:", cat_name))
  }

  for (i in seq_len(nrow(alpha_values))) {
    detectable_d <- pwr.t2n.test(
      n1 = n_ai,
      n2 = n_human,
      sig.level = alpha_values$alpha[i],
      power = .80,
      alternative = "two.sided"
    )$d

    results <- rbind(
      results,
      data.frame(
        category = cat_name,
        n_ai = n_ai,
        n_human = n_human,
        alpha_label = alpha_values$alpha_label[i],
        alpha = alpha_values$alpha[i],
        target_power = .80,
        detectable_d = detectable_d
      )
    )
  }
}

write.csv(
  results,
  file.path(output_dir, "09_duyarlilik_analizi.csv"),
  row.names = FALSE
)

summary_lines <- c(
  "Duyarlilik analizi",
  paste("Veri dosyasi:", data_path),
  paste("Cikti klasoru:", output_dir),
  "",
  "Test: iki bagimsiz grup karsilastirmasi",
  "Kuyruk: iki yonlu",
  "Hedef guc: .80",
  "",
  capture.output(print(results, row.names = FALSE))
)

writeLines(summary_lines, file.path(output_dir, "09_duyarlilik_analizi.txt"))

print(results, row.names = FALSE)
