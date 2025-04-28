library(openxlsx)

input_dir <- "C:/users/ben13/Uni/year 3/Dissertation/Season Stats"
wb <- createWorkbook()

addWorksheet(wb, "All Seasons")
writeData(wb, "All Seasons", all_seasons_combined)

addWorksheet(wb, "Standardisation")
writeData(wb, "Career Stats", all_seasons_standardised) # old GPG standardisation

addWorksheet(wb, "Career Stats")
writeData(wb, "Career Stats", career_stats_summary)

saveWorkbook(wb, "Master Stats.xlsx", overwrite = TRUE)
