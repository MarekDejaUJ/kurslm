# Wizualizacje i tabele kursowe.

PALETA <- c(
  pozytywny = "#4CAF50",
  negatywny = "#F44336",
  neutralny = "#9E9E9E",
  akcentA = "#2196F3",
  akcentB = "#FF9800",
  nierozpoznane = "#795548"
)

pokaz_tabele <- function(dane, tytul = NULL, n = 20) {
  dane <- utils::head(as.data.frame(dane), n)
  if (requireNamespace("gt", quietly = TRUE)) {
    tab <- gt::gt(dane)
    if (!is.null(tytul)) {
      tab <- gt::tab_header(tab, title = tytul)
    }
    return(tab)
  }
  if (!is.null(tytul)) {
    message(tytul)
  }
  print(dane)
  invisible(dane)
}

pokaz_rozklad <- function(wyniki, kolumna_klasyfikacja = "klasyfikacja", tytul = "Rozklad klasyfikacji") {
  dane <- as.data.frame(wyniki)
  if (!kolumna_klasyfikacja %in% names(dane)) {
    stop("Brakuje kolumny: ", kolumna_klasyfikacja)
  }
  podsumowanie <- as.data.frame(table(dane[[kolumna_klasyfikacja]]), stringsAsFactors = FALSE)
  names(podsumowanie) <- c("etykieta", "liczba")
  podsumowanie$procent <- round(100 * podsumowanie$liczba / sum(podsumowanie$liczba), 1)

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(podsumowanie)
    return(invisible(podsumowanie))
  }

  ggplot2::ggplot(podsumowanie, ggplot2::aes(x = etykieta, y = liczba, fill = etykieta)) +
    ggplot2::geom_col(width = 0.7, show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = paste0(procent, "%")), vjust = -0.3, size = 3.5) +
    ggplot2::scale_fill_manual(values = PALETA, na.value = PALETA[["akcentA"]]) +
    ggplot2::labs(title = tytul, x = NULL, y = "Liczba fragmentow") +
    ggplot2::theme_minimal()
}

pokaz_porownanie <- function(wyniki, kolumny = NULL, tytul = "Porownanie wynikow") {
  dane <- as.data.frame(wyniki)
  if (is.null(kolumny)) {
    kolumny <- setdiff(names(dane), c("id", "text", "jezyk", "zrodlo", "typ_korpusu", "odpowiedz_surowa", "model", "czas", "myslenie"))
  }
  dlugie <- do.call(rbind, lapply(kolumny, function(kol) {
    data.frame(wymiar = kol, etykieta = dane[[kol]], stringsAsFactors = FALSE)
  }))

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(table(dlugie$wymiar, dlugie$etykieta))
    return(invisible(dlugie))
  }

  ggplot2::ggplot(dlugie, ggplot2::aes(x = wymiar, fill = etykieta)) +
    ggplot2::geom_bar(position = "fill") +
    ggplot2::scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::labs(title = tytul, x = NULL, y = "Udzial", fill = "Etykieta") +
    ggplot2::theme_minimal()
}

pokaz_porownanie_modeli <- function(wyniki, tytul = "Porownanie modeli") {
  kolumna <- if ("model_alias" %in% names(wyniki)) "model_alias" else "model"
  pokaz_porownanie(wyniki, kolumny = c(kolumna, "klasyfikacja"), tytul = tytul)
}

pokaz_confusion_matrix <- function(predykcje, prawda, tytul = "Macierz pomylek") {
  tab <- table(Prawda = prawda, Predykcja = predykcje)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(tab)
    return(invisible(tab))
  }
  dane <- as.data.frame(tab)
  ggplot2::ggplot(dane, ggplot2::aes(x = Predykcja, y = Prawda, fill = Freq)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = Freq)) +
    ggplot2::scale_fill_gradient(low = "#F5F5F5", high = PALETA[["akcentA"]]) +
    ggplot2::labs(title = tytul, x = "Predykcja", y = "Zloty standard") +
    ggplot2::theme_minimal()
}

pokaz_heatmapa_zgodnosci <- function(macierz_porownawcza, tytul = "Heatmapa zgodnosci") {
  dane <- as.data.frame(as.table(as.matrix(macierz_porownawcza)))
  names(dane) <- c("A", "B", "wartosc")
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(dane)
    return(invisible(dane))
  }
  ggplot2::ggplot(dane, ggplot2::aes(A, B, fill = wartosc)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = round(wartosc, 2)), size = 3) +
    ggplot2::scale_fill_gradient(low = "#F5F5F5", high = PALETA[["akcentA"]]) +
    ggplot2::labs(title = tytul, x = NULL, y = NULL) +
    ggplot2::theme_minimal()
}

pokaz_triangulacje <- function(dane_3metod, tytul = "Triangulacja metod") {
  pokaz_porownanie(dane_3metod, tytul = tytul)
}

pokaz_siec_podmiotow <- function(wyniki_ekstrakcji) {
  dane <- as.data.frame(wyniki_ekstrakcji)
  if (!"ekstrakcja" %in% names(dane)) {
    return(pokaz_tabele(dane, "Wyniki ekstrakcji"))
  }
  terminy <- unlist(strsplit(paste(dane$ekstrakcja, collapse = ","), ",|;|\\n"))
  terminy <- trimws(terminy)
  terminy <- terminy[nzchar(terminy)]
  czestosc <- sort(table(terminy), decreasing = TRUE)
  pokaz_tabele(data.frame(podmiot = names(czestosc), liczba = as.integer(czestosc)), "Najczestsze podmioty")
}

pokaz_chmure <- function(terminy) {
  if (is.data.frame(terminy) && "ekstrakcja" %in% names(terminy)) {
    terminy <- unlist(strsplit(paste(terminy$ekstrakcja, collapse = ","), ",|;|\\n"))
  }
  terminy <- trimws(as.character(terminy))
  terminy <- terminy[nzchar(terminy)]
  czestosc <- sort(table(terminy), decreasing = TRUE)
  dane <- data.frame(word = names(czestosc), freq = as.integer(czestosc), stringsAsFactors = FALSE)
  if (requireNamespace("wordcloud2", quietly = TRUE) && nrow(dane) > 0) {
    return(wordcloud2::wordcloud2(dane))
  }
  pokaz_rozklad(data.frame(klasyfikacja = dane$word), "klasyfikacja", "Najczestsze terminy")
}

pokaz_piramide_walidacji <- function(wyniki) {
  dane <- data.frame(
    poziom = c("Trafnosc", "Stabilnosc", "Triangulacja"),
    wartosc = c(
      wyniki$accuracy %||% NA_real_,
      wyniki$stabilnosc %||% NA_real_,
      wyniki$triangulacja %||% NA_real_
    )
  )
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(dane)
    return(invisible(dane))
  }
  ggplot2::ggplot(dane, ggplot2::aes(x = poziom, y = wartosc, fill = poziom)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = c(PALETA[["akcentA"]], PALETA[["akcentB"]], PALETA[["pozytywny"]])) +
    ggplot2::labs(title = "Piramida walidacji", x = NULL, y = "Wartosc") +
    ggplot2::theme_minimal()
}

pokaz_thinking_vs_not <- function(wyniki) {
  pokaz_porownanie(wyniki, kolumny = c("think", "no_think"), tytul = "Thinking vs non-thinking")
}

pokaz_macierz_eksperymentu <- function(wynik) {
  dane <- as.data.frame(wynik)
  if (!all(c("model_alias", "framework", "klasyfikacja") %in% names(dane))) {
    return(pokaz_tabele(dane, "Eksperyment"))
  }
  podsumowanie <- aggregate(klasyfikacja ~ model_alias + framework, data = dane, function(x) length(unique(x)))
  names(podsumowanie)[3] <- "liczba_etykiet"
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(podsumowanie)
    return(invisible(podsumowanie))
  }
  ggplot2::ggplot(podsumowanie, ggplot2::aes(framework, model_alias, fill = liczba_etykiet)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = liczba_etykiet)) +
    ggplot2::scale_fill_gradient(low = "#F5F5F5", high = PALETA[["akcentB"]]) +
    ggplot2::labs(title = "Model x framework: zroznicowanie klasyfikacji", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
}

pokaz_tabele_zbiorcza <- function(wynik) {
  pokaz_tabele(wynik, "Tabela zbiorcza eksperymentu")
}

pokaz_heatmapa_tonazyku <- function(wyniki_ton, wyniki_perswazja) {
  wspolne <- data.frame(
    ton = wyniki_ton$klasyfikacja,
    perswazja = wyniki_perswazja$klasyfikacja,
    stringsAsFactors = FALSE
  )
  pokaz_heatmapa_zgodnosci(table(wspolne$ton, wspolne$perswazja), "Ton retoryczny x strategia perswazji")
}

pokaz_eksploracje <- function(dane) {
  dane <- as.data.frame(dane)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    print(summary(dane))
    return(invisible(dane))
  }
  kol <- intersect(c("pyt1_dlugosc", "pyt2_dlugosc", "pyt3_dlugosc"), names(dane))[1]
  if (is.na(kol)) {
    return(pokaz_tabele(utils::head(dane), "Eksploracja danych"))
  }
  ggplot2::ggplot(dane, ggplot2::aes(x = .data[[kol]])) +
    ggplot2::geom_histogram(bins = 20, fill = PALETA[["akcentA"]], color = "white") +
    ggplot2::labs(title = paste("Rozklad dlugosci odpowiedzi:", kol), x = "Liczba znakow", y = "Liczba odpowiedzi") +
    ggplot2::theme_minimal()
}

analiza_krzyzowa <- function(dane, kolumna_klasyfikacja, kolumna_metryka) {
  dane <- as.data.frame(dane)
  tab <- table(dane[[kolumna_metryka]], dane[[kolumna_klasyfikacja]])
  wynik <- list(tabela = tab, test_chi2 = suppressWarnings(chisq.test(tab)))
  print(tab)
  wynik
}

pokaz_podsumowanie_projektu <- function(wszystkie_wyniki) {
  nazwy <- names(wszystkie_wyniki)
  opis <- data.frame(
    element = nazwy,
    liczba_wierszy = vapply(wszystkie_wyniki, function(x) {
      if (is.data.frame(x)) nrow(x) else length(x)
    }, numeric(1)),
    stringsAsFactors = FALSE
  )
  pokaz_tabele(opis, "Podsumowanie projektu")
}
