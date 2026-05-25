# Eksport wynikow i podsumowan.

#' Zapisz wyniki do pliku RDS
#' @export
zapisz_wyniki <- function(wyniki, spotkanie, nazwa) {
  katalog <- file.path("wyniki", tolower(spotkanie))
  dir.create(katalog, recursive = TRUE, showWarnings = FALSE)
  sciezka <- file.path(katalog, paste0(nazwa, ".rds"))
  saveRDS(wyniki, sciezka)
  message("Zapisano wyniki: ", sciezka)
  invisible(sciezka)
}

#' Zapisz wyniki do pliku CSV
#' @export
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

#' Pokaz podsumowanie wynikow spotkania
#' @export
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

#' Zbierz prace studentow z klonowanych repozytoriow GitHub
#' @param katalog_nadrzedny Sciezka do folderu z repozytoriami studentow
#' @param spotkanie Nazwa spotkania, np. "S02"
#' @export
zbierz_prace <- function(katalog_nadrzedny, spotkanie = "S02") {
  foldery <- list.dirs(katalog_nadrzedny, recursive = FALSE)
  if (length(foldery) == 0) {
    cli::cli_alert_warning("Brak podfolderow w katalogu: {katalog_nadrzedny}")
    return(invisible(NULL))
  }
  
  wyniki_lista <- list()
  for (f in foldery) {
    repo_name <- basename(f)
    if (repo_name == "archiwum" || repo_name == ".git") next
    
    # Szukamy plikow .Rmd w folderze studenta
    pliki_rmd <- list.files(f, pattern = paste0("^", spotkanie, ".*\\.Rmd$"), ignore.case = TRUE, full.names = TRUE)
    if (length(pliki_rmd) == 0) {
      pliki_rmd <- list.files(f, pattern = "\\.Rmd$", full.names = TRUE)
    }
    
    # Szukamy plikow .pdf w folderze studenta
    pliki_pdf <- list.files(f, pattern = paste0(".*", spotkanie, ".*\\.pdf$"), ignore.case = TRUE, full.names = TRUE)
    if (length(pliki_pdf) == 0) {
      pliki_pdf <- list.files(f, pattern = "\\.pdf$", full.names = TRUE)
    }
    
    rmd_obecny <- length(pliki_rmd) > 0
    pdf_obecny <- length(pliki_pdf) > 0
    
    pdf_nazwa <- if (pdf_obecny) basename(pliki_pdf[1]) else NA_character_
    
    # Analizujemy zawartosc Rmd (jesli istnieje) w poszukiwaniu promptow i interpretacji
    prompty_liczba <- 0
    interpretacje_slowa <- 0
    placeholdery_obecne <- FALSE
    
    if (rmd_obecny) {
      linie <- readLines(pliki_rmd[1], warn = FALSE, encoding = "UTF-8")
      calosc <- paste(linie, collapse = "\n")
      
      # Liczymy moj_prompt_zad
      prompty_liczba <- length(grep("moj_prompt_zad", linie))
      
      # Sprawdzamy placeholdery
      placeholdery_obecne <- any(grepl("\\[TUTAJ|\\[UZUPELNIJ|\\[WPISZ|\\[CHALLENGE", linie))
      
      # Liczymy slowa w przypisaniach interpretacji
      interpretacje_bloki <- regmatches(calosc, gregexpr("moja_interpretacja_zad\\d+\\s*(<-|=)\\s*\"([^\"]+)\"", calosc))[[1]]
      if (length(interpretacje_bloki) > 0) {
        interpretacje_slowa <- sum(vapply(interpretacje_bloki, function(x) {
          match <- regexec("\"([^\"]+)\"", x)
          text <- regmatches(x, match)[[1]][2]
          if (is.na(text)) return(0)
          length(unlist(strsplit(trimws(text), "\\s+")))
        }, numeric(1)))
      }
    }
    
    wyniki_lista[[repo_name]] <- data.frame(
      Student_Repo = repo_name,
      Rmd_Obecny = rmd_obecny,
      Pdf_Obecny = pdf_obecny,
      Pdf_Plik = pdf_nazwa,
      Liczba_Promptow = prompty_liczba,
      Interpretacja_Slowa = interpretacje_slowa,
      Placeholdery = placeholdery_obecne,
      stringsAsFactors = FALSE
    )
  }
  
  kurs_as_tibble(do.call(rbind, wyniki_lista))
}

#' Pokaz przeglad prac studentow w formie czytelnej tabeli
#' @param prace Dane wygenerowane przez zbierz_prace()
#' @export
pokaz_przeglad_prac <- function(prace) {
  if (is.null(prace) || nrow(prace) == 0) {
    message("Brak danych do wyswietlenia.")
    return(invisible(NULL))
  }
  
  if (requireNamespace("gt", quietly = TRUE)) {
    prace %>%
      gt::gt() %>%
      gt::tab_header(
        title = "Przeglad Prac Studentow",
        subtitle = "Zestawienie kompletnosci i jakosci zadan"
      ) %>%
      gt::cols_label(
        Student_Repo = "Repozytorium",
        Rmd_Obecny = "Rmd",
        Pdf_Obecny = "PDF",
        Pdf_Plik = "Nazwa pliku PDF",
        Liczba_Promptow = "Prompty (Liczba)",
        Interpretacja_Slowa = "Slowa (Interpretacja)",
        Placeholdery = "Placeholdery"
      ) %>%
      gt::data_color(
        columns = c(Rmd_Obecny, Pdf_Obecny),
        fn = function(x) ifelse(x, "#d4edda", "#f8d7da")
      ) %>%
      gt::data_color(
        columns = Placeholdery,
        fn = function(x) ifelse(x, "#f8d7da", "#d4edda")
      )
  } else {
    print(prace)
  }
}
