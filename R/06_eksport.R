# Eksport wynikow i podsumowan.

zapisz_wyniki <- function(wyniki, spotkanie, nazwa) {
  katalog <- file.path("wyniki", tolower(spotkanie))
  dir.create(katalog, recursive = TRUE, showWarnings = FALSE)
  sciezka <- file.path(katalog, paste0(nazwa, ".rds"))
  saveRDS(wyniki, sciezka)
  message("Zapisano wyniki: ", sciezka)
  invisible(sciezka)
}

zapisz_csv <- function(dane, spotkanie, nazwa) {
  katalog <- file.path("wyniki", tolower(spotkanie))
  dir.create(katalog, recursive = TRUE, showWarnings = FALSE)
  sciezka <- file.path(katalog, paste0(nazwa, ".csv"))
  if (requireNamespace("readr", quietly = TRUE)) {
    readr::write_csv(dane, sciezka)
  } else {
    write.csv(dane, sciezka, row.names = FALSE, fileEncoding = "UTF-8")
  }
  message("Zapisano CSV: ", sciezka)
  invisible(sciezka)
}

pokaz_podsumowanie_spotkania <- function(spotkanie) {
  katalog <- file.path("wyniki", tolower(spotkanie))
  pliki <- list.files(katalog, pattern = "\\.rds$", full.names = TRUE)
  if (length(pliki) == 0) {
    message("Brak zapisanych wynikow dla: ", spotkanie)
    return(invisible(NULL))
  }
  opis <- data.frame(
    plik = basename(pliki),
    rozmiar_kb = round(file.info(pliki)$size / 1024, 1),
    data_modyfikacji = file.info(pliki)$mtime,
    stringsAsFactors = FALSE
  )
  pokaz_tabele(opis, paste("Podsumowanie spotkania", toupper(spotkanie)))
}
