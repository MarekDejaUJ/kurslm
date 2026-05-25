# Metody walidacji klasyfikacji LLM.

stworz_zloty_standard <- function(korpus, etykiety_ludzkie = NULL, n = 20) {
  dane <- utils::head(as.data.frame(korpus, stringsAsFactors = FALSE), n)
  if (is.null(etykiety_ludzkie)) {
    etykiety_ludzkie <- rep(NA_character_, nrow(dane))
  }
  if (length(etykiety_ludzkie) != nrow(dane)) {
    stop("Liczba etykiet ludzkich musi byc rowna liczbie fragmentow.")
  }
  dane$etykieta_ludzka <- etykiety_ludzkie
  kurs_as_tibble(dane)
}

test_retest <- function(korpus, prompt, model = "auto", k = 3, n = 15,
                        etykiety = c("pozytywny", "negatywny", "neutralny")) {
  baza <- utils::head(as.data.frame(korpus, stringsAsFactors = FALSE), n)
  wynik <- baza[, intersect(c("id", "text", "jezyk", "zrodlo", "typ_korpusu"), names(baza)), drop = FALSE]
  for (i in seq_len(k)) {
    czesc <- klasyfikuj_zbior(baza, prompt, etykiety, model = model, n = n)
    wynik[[paste0("run_", i)]] <- czesc$klasyfikacja
  }
  kolumny <- paste0("run_", seq_len(k))
  wynik$zgodnosc_pelna <- apply(wynik[, kolumny, drop = FALSE], 1, function(x) length(unique(x)) == 1)
  attr(wynik, "stabilnosc") <- mean(wynik$zgodnosc_pelna)
  kurs_as_tibble(wynik)
}

policz_metryki <- function(predykcje, zloty_standard, pred_col = "klasyfikacja",
                           truth_col = "etykieta_ludzka") {
  pred <- as.data.frame(predykcje, stringsAsFactors = FALSE)
  gold <- as.data.frame(zloty_standard, stringsAsFactors = FALSE)
  if (!pred_col %in% names(pred)) {
    stop("Brakuje kolumny predykcji: ", pred_col)
  }
  if (!truth_col %in% names(gold)) {
    stop("Brakuje kolumny zlotego standardu: ", truth_col)
  }
  n <- min(nrow(pred), nrow(gold))
  p <- pred[[pred_col]][seq_len(n)]
  y <- gold[[truth_col]][seq_len(n)]
  ok <- !is.na(y) & nzchar(y)
  p <- p[ok]
  y <- y[ok]
  if (length(y) == 0) {
    stop("Brak uzupelnionych etykiet w zlotym standardzie.")
  }

  tab <- table(Prawda = y, Predykcja = p)
  accuracy <- mean(p == y)
  klasy <- union(unique(y), unique(p))
  f1 <- vapply(klasy, function(kl) {
    tp <- sum(p == kl & y == kl)
    fp <- sum(p == kl & y != kl)
    fn <- sum(p != kl & y == kl)
    precision <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
    recall <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
    if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA_real_ else 2 * precision * recall / (precision + recall)
  }, numeric(1))

  wynik <- list(
    accuracy = accuracy,
    f1_macro = mean(f1, na.rm = TRUE),
    f1_per_klasa = f1,
    confusion_matrix = tab
  )
  print(wynik)
  invisible(wynik)
}

policz_kappa <- function(rater_a, rater_b, wagi = "unweighted") {
  dane <- data.frame(a = rater_a, b = rater_b)
  dane <- dane[complete.cases(dane), , drop = FALSE]
  if (requireNamespace("irr", quietly = TRUE) && nrow(dane) > 1) {
    wynik <- irr::kappa2(dane, weight = wagi)
    print(wynik)
    return(wynik)
  }
  zgodnosc <- mean(dane$a == dane$b)
  wynik <- list(value = NA_real_, agreement = zgodnosc, note = "Pakiet irr niedostepny; pokazano tylko zgodnosc procentowa.")
  print(wynik)
  wynik
}

policz_alpha <- function(macierz_raterow, metoda = "nominal") {
  mat <- as.matrix(macierz_raterow)
  if (requireNamespace("irr", quietly = TRUE)) {
    wynik <- irr::kripp.alpha(t(mat), method = metoda)
    print(wynik)
    return(wynik)
  }
  wynik <- list(value = NA_real_, note = "Pakiet irr niedostepny.")
  print(wynik)
  wynik
}

analizuj_bledy <- function(predykcje, zloty_standard, pred_col = "klasyfikacja",
                           truth_col = "etykieta_ludzka", n = 5) {
  pred <- as.data.frame(predykcje, stringsAsFactors = FALSE)
  gold <- as.data.frame(zloty_standard, stringsAsFactors = FALSE)
  ile <- min(nrow(pred), nrow(gold))
  wynik <- data.frame(
    id = gold$id[seq_len(ile)],
    text = gold$text[seq_len(ile)],
    prawda = gold[[truth_col]][seq_len(ile)],
    predykcja = pred[[pred_col]][seq_len(ile)],
    typ_bledu = NA_character_,
    stringsAsFactors = FALSE
  )
  wynik <- wynik[!is.na(wynik$prawda) & wynik$prawda != wynik$predykcja, , drop = FALSE]
  kurs_as_tibble(utils::head(wynik, n))
}

trianguluj <- function(korpus, predykcje_llm, metoda_leksykon = "bing", pred_col = "klasyfikacja",
                       zloty_standard = NULL) {
  dane <- utils::head(as.data.frame(korpus, stringsAsFactors = FALSE), nrow(predykcje_llm))
  pred <- as.data.frame(predykcje_llm, stringsAsFactors = FALSE)

  leksykon <- if (requireNamespace("syuzhet", quietly = TRUE)) {
    wartosci <- syuzhet::get_sentiment(dane$text, method = metoda_leksykon)
    ifelse(wartosci > 0.05, "pozytywny", ifelse(wartosci < -0.05, "negatywny", "neutralny"))
  } else {
    ifelse(grepl("crisis|fear|war|obaw|zagroz", dane$text, ignore.case = TRUE), "negatywny", "neutralny")
  }

  wynik <- data.frame(
    id = dane$id,
    text = dane$text,
    llm = pred[[pred_col]],
    leksykon = leksykon,
    stringsAsFactors = FALSE
  )
  if (!is.null(zloty_standard)) {
    wynik$zloty_standard <- utils::head(as.data.frame(zloty_standard)$etykieta_ludzka, nrow(wynik))
  }
  kurs_as_tibble(wynik)
}

porownaj_frameworki_walidacja <- function(korpus, prompty_lista, model, etykiety, n = 12) {
  wynik <- porownaj_frameworki(korpus, prompty_lista, etykiety = etykiety, model = model, n = n)
  kolumny <- setdiff(names(wynik), c("id", "text", "jezyk", "zrodlo", "typ_korpusu"))
  zgodnosc <- matrix(NA_real_, nrow = length(kolumny), ncol = length(kolumny), dimnames = list(kolumny, kolumny))
  for (a in kolumny) {
    for (b in kolumny) {
      zgodnosc[a, b] <- mean(wynik[[a]] == wynik[[b]], na.rm = TRUE)
    }
  }
  attr(wynik, "zgodnosc") <- zgodnosc
  kurs_as_tibble(wynik)
}
