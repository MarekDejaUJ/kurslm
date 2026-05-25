# Ladowanie i przygotowanie korpusow.

kurs_tibble <- function(...) {
  if (requireNamespace("tibble", quietly = TRUE)) {
    tibble::tibble(...)
  } else {
    data.frame(..., stringsAsFactors = FALSE)
  }
}

kurs_read_rds_if_exists <- function(sciezka) {
  if (file.exists(sciezka)) {
    return(readRDS(sciezka))
  }
  NULL
}

kurs_standard_korpus <- function(dane, jezyk = "en", typ_korpusu = "tekst", zrodlo = NA_character_) {
  dane <- as.data.frame(dane, stringsAsFactors = FALSE)
  if (!"text" %in% names(dane)) {
    kandydat <- intersect(c("tekst", "content", "abstract", "fragment", "body"), names(dane))[1]
    if (!is.na(kandydat)) {
      dane$text <- dane[[kandydat]]
    }
  }
  if (!"id" %in% names(dane)) {
    dane$id <- seq_len(nrow(dane))
  }
  if (!"jezyk" %in% names(dane)) {
    dane$jezyk <- jezyk
  }
  if (!"zrodlo" %in% names(dane)) {
    dane$zrodlo <- zrodlo
  }
  if (!"typ_korpusu" %in% names(dane)) {
    dane$typ_korpusu <- typ_korpusu
  }
  kurs_as_tibble(dane[, unique(c("id", "text", "jezyk", "zrodlo", "typ_korpusu", setdiff(names(dane), c("id", "text", "jezyk", "zrodlo", "typ_korpusu"))))])
}

przygotuj_fragmenty <- function(tekst_wektor, okno = 15, krok = 7, min_znakow = 500,
                                max_znakow = 2000, n = 80) {
  fragmenty <- character()
  for (tekst in tekst_wektor) {
    zdania <- unlist(strsplit(tekst, "(?<=[.!?])\\s+", perl = TRUE))
    zdania <- zdania[nzchar(trimws(zdania))]
    if (length(zdania) < okno) {
      kandydat <- paste(zdania, collapse = " ")
      if (nchar(kandydat) >= min_znakow) {
        fragmenty <- c(fragmenty, substr(kandydat, 1, max_znakow))
      }
      next
    }
    starty <- seq(1, length(zdania) - okno + 1, by = krok)
    for (start in starty) {
      kandydat <- paste(zdania[start:(start + okno - 1)], collapse = " ")
      if (nchar(kandydat) >= min_znakow) {
        fragmenty <- c(fragmenty, substr(kandydat, 1, max_znakow))
      }
    }
  }
  fragmenty <- unique(fragmenty)
  if (length(fragmenty) > n) {
    set.seed(42)
    fragmenty <- sample(fragmenty, n)
  }
  fragmenty
}

kurs_fallback_polityczny <- function() {
  c(
    "Our democracy asks more from us than attention in moments of crisis. It asks for patience, shared responsibility, and a willingness to build institutions that survive disagreement. The nation has faced war, recession, and uncertainty before, yet public service has repeatedly turned anxiety into collective purpose.",
    "The economy is growing, but growth alone does not answer the fears of families who wonder whether their work will be valued tomorrow. A government worthy of trust must invest in education, infrastructure, and fair access to opportunity while speaking honestly about the costs of delay.",
    "Security cannot be reduced to military strength. It also depends on alliances, civic confidence, scientific capacity, and the belief that public facts still matter. When adversaries test our resolve, unity is not a slogan; it is a practical condition of democratic survival.",
    "We honor those who served not by repeating ceremonial phrases, but by protecting the institutions and communities for which they sacrificed. Patriotism is measured in care for veterans, respect for law, and the courage to correct our failures.",
    "There are moments when compromise looks slow and frustration looks strong. But the work of a republic is rarely theatrical. It is the steady repair of roads, schools, courts, hospitals, and the public trust that connects them."
  )
}

kurs_fallback_naukowy <- function() {
  c(
    "This study examines how digital catalogues influence information seeking behavior among university students. Using a mixed methods design, we combine log data with interviews and show that interface cues shape both search persistence and perceived credibility.",
    "Large language models offer new opportunities for qualitative coding, but their reliability depends on prompt design, category clarity, and validation against human annotations. We evaluate model stability across repeated classifications of short research abstracts.",
    "The paper proposes a framework for comparing lexical sentiment tools and generative models in cultural heritage datasets. Results suggest that lexicon-based methods remain useful for triangulation, especially when model outputs are unstable.",
    "We analyze professional attitudes toward artificial intelligence in libraries, archives, and museums. Respondents describe efficiency gains, but also concerns about transparency, deskilling, copyright, and institutional accountability.",
    "A corpus of policy documents was segmented into rhetorical units and classified by stance. The findings indicate that uncertainty is often framed as a management problem rather than as a limitation of available evidence."
  )
}

kurs_fallback_faktograficzny <- function() {
  c(
    "The Library of Alexandria was one of the most famous libraries of the ancient world. It functioned as part of a larger research institution and became a symbol of scholarly ambition, textual collection, and the fragility of cultural memory.",
    "The printing press transformed the circulation of texts in Europe during the fifteenth century. Movable type made reproduction faster and cheaper, contributing to religious debate, scientific communication, and the growth of public reading cultures.",
    "Wikipedia is a multilingual online encyclopedia maintained by volunteer contributors. Its articles are revised continuously, which makes it both a practical reference source and an object of research on collaborative knowledge production.",
    "The Dewey Decimal Classification organizes library materials by subject using numerical notation. Although widely adopted, it has also been criticized for historical biases embedded in its categories.",
    "Digital preservation refers to the set of policies and technical actions used to maintain access to digital objects over time. It includes format migration, metadata management, integrity checking, and institutional planning."
  )
}

#' Wczytaj korpus polityczny (SOTU)
#' @export
wczytaj_korpus_polityczny <- function(n = 80, sciezka = "dane/korpus_polityczny.rds",
                                      okno = 15, krok = 7, min_znakow = 500) {
  # Sprawdzenie w zasobach pakietu, jesli sciezka jest domyslna
  if (identical(sciezka, "dane/korpus_polityczny.rds")) {
    pkg_path <- system.file("extdata", "korpus_polityczny.rds", package = "kurslm")
    if (nzchar(pkg_path) && file.exists(pkg_path)) {
      sciezka <- pkg_path
    }
  }
  
  lokalny <- kurs_read_rds_if_exists(sciezka)
  if (!is.null(lokalny)) {
    return(utils::head(kurs_standard_korpus(lokalny, jezyk = "en", typ_korpusu = "polityczny", zrodlo = "lokalny RDS"), n))
  }

  teksty <- NULL
  if (requireNamespace("sotu", quietly = TRUE)) {
    env <- new.env(parent = emptyenv())
    try(utils::data("sotu_text", package = "sotu", envir = env), silent = TRUE)
    if (exists("sotu_text", envir = env)) {
      teksty <- as.character(get("sotu_text", envir = env))
    }
  }

  if (is.null(teksty) || length(teksty) == 0) {
    teksty <- kurs_fallback_polityczny()
    fragmenty <- teksty
  } else {
    fragmenty <- przygotuj_fragmenty(teksty, okno = okno, krok = krok, min_znakow = min_znakow, n = n)
  }

  kurs_standard_korpus(
    kurs_tibble(id = seq_along(fragmenty), text = fragmenty),
    jezyk = "en",
    typ_korpusu = "polityczny",
    zrodlo = if (is.null(teksty)) "fallback" else "SOTU/fallback"
  )
}

#' Wczytaj korpus naukowy
#' @export
wczytaj_korpus_naukowy <- function(n = 80, sciezka = "dane/korpus_naukowy.rds") {
  # Sprawdzenie w zasobach pakietu, jesli sciezka jest domyslna
  if (identical(sciezka, "dane/korpus_naukowy.rds")) {
    pkg_path <- system.file("extdata", "korpus_naukowy.rds", package = "kurslm")
    if (nzchar(pkg_path) && file.exists(pkg_path)) {
      sciezka <- pkg_path
    }
  }

  lokalny <- kurs_read_rds_if_exists(sciezka)
  if (!is.null(lokalny)) {
    return(utils::head(kurs_standard_korpus(lokalny, jezyk = "en", typ_korpusu = "naukowy", zrodlo = "lokalny RDS"), n))
  }
  teksty <- rep(kurs_fallback_naukowy(), length.out = max(n, length(kurs_fallback_naukowy())))
  kurs_standard_korpus(kurs_tibble(id = seq_len(length(teksty)), text = teksty), jezyk = "en", typ_korpusu = "naukowy", zrodlo = "fallback")
}

#' Wczytaj korpus faktograficzny
#' @export
wczytaj_korpus_faktograficzny <- function(n = 80, sciezka = "dane/korpus_faktograficzny.rds") {
  # Sprawdzenie w zasobach pakietu, jesli sciezka jest domyslna
  if (identical(sciezka, "dane/korpus_faktograficzny.rds")) {
    pkg_path <- system.file("extdata", "korpus_faktograficzny.rds", package = "kurslm")
    if (nzchar(pkg_path) && file.exists(pkg_path)) {
      sciezka <- pkg_path
    }
  }

  lokalny <- kurs_read_rds_if_exists(sciezka)
  if (!is.null(lokalny)) {
    return(utils::head(kurs_standard_korpus(lokalny, jezyk = "en", typ_korpusu = "faktograficzny", zrodlo = "lokalny RDS"), n))
  }
  teksty <- rep(kurs_fallback_faktograficzny(), length.out = max(n, length(kurs_fallback_faktograficzny())))
  kurs_standard_korpus(kurs_tibble(id = seq_len(length(teksty)), text = teksty), jezyk = "en", typ_korpusu = "faktograficzny", zrodlo = "fallback")
}

#' Wczytaj respondentow
#' @export
wczytaj_respondentow <- function(sciezka = "dane/respondenci_200.csv", n = 200) {
  # Sprawdzenie w zasobach pakietu, jesli sciezka jest domyslna
  if (identical(sciezka, "dane/respondenci_200.csv")) {
    pkg_path <- system.file("extdata", "respondenci_200.csv", package = "kurslm")
    if (nzchar(pkg_path) && file.exists(pkg_path)) {
      sciezka <- pkg_path
    }
  }

  if (file.exists(sciezka)) {
    if (requireNamespace("readr", quietly = TRUE)) {
      dane <- readr::read_csv(sciezka, show_col_types = FALSE)
    } else {
      dane <- read.csv(sciezka, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    }
    if (!"jezyk" %in% names(dane)) {
      dane$jezyk <- "pl"
    }
    return(kurs_as_tibble(dane))
  }

  set.seed(42)
  typy <- c("biblioteka_akademicka", "biblioteka_publiczna", "archiwum", "muzeum")
  stanowiska <- c("bibliotekarz", "katalogujacy", "kierownik", "informatyk", "inny")
  dane <- data.frame(
    id = seq_len(n),
    wiek = sample(22:65, n, replace = TRUE),
    plec = sample(c("K", "M", "I"), n, replace = TRUE, prob = c(0.62, 0.35, 0.03)),
    staz_pracy_lat = sample(0:40, n, replace = TRUE),
    typ_instytucji = sample(typy, n, replace = TRUE),
    stanowisko = sample(stanowiska, n, replace = TRUE),
    stringsAsFactors = FALSE
  )
  dane$pyt1_korzysci_ai <- paste(
    "AI moze pomoc w szybszym opracowaniu zbiorow i lepszym odpowiadaniu na pytania uzytkownikow.",
    "Wazne jest jednak zachowanie kontroli pracownika nad wynikiem."
  )
  dane$pyt2_obawy_ai <- paste(
    "Najwieksza obawa dotyczy bledow, niejasnej odpowiedzialnosci oraz zbyt duzego zaufania do automatycznych podpowiedzi."
  )
  dane$pyt3_przyszlosc <- paste(
    "Za piec lat instytucja bedzie prawdopodobnie korzystac z AI jako narzedzia wspierajacego wyszukiwanie, opis i edukacje.",
    "Nie zastapi to relacji z odbiorcami."
  )
  dane$pyt1_dlugosc <- nchar(dane$pyt1_korzysci_ai)
  dane$pyt2_dlugosc <- nchar(dane$pyt2_obawy_ai)
  dane$pyt3_dlugosc <- nchar(dane$pyt3_przyszlosc)
  dane$jezyk <- "pl"
  kurs_as_tibble(dane)
}

#' Przygotuj srodowisko pod konkretne spotkanie
#' @export
przygotuj_spotkanie <- function(spotkanie, env = parent.frame()) {
  spotkanie <- toupper(gsub("_", "", spotkanie))
  if (spotkanie %in% c("S01", "01")) {
    return(invisible(TRUE))
  }
  if (spotkanie %in% c("S02", "02")) {
    assign("korpus_polityczny", wczytaj_korpus_polityczny(n = 60), envir = env)
    assign("korpus_naukowy", wczytaj_korpus_naukowy(n = 60), envir = env)
  }
  if (spotkanie %in% c("S03", "03")) {
    assign("korpus_faktograficzny", wczytaj_korpus_faktograficzny(n = 60), envir = env)
    assign("korpus_naukowy", wczytaj_korpus_naukowy(n = 60), envir = env)
    assign("korpus_polityczny", wczytaj_korpus_polityczny(n = 60), envir = env)
  }
  if (spotkanie %in% c("S04", "04")) {
    assign("korpus_polityczny", wczytaj_korpus_polityczny(n = 60), envir = env)
    assign("korpus_naukowy", wczytaj_korpus_naukowy(n = 60), envir = env)
  }
  if (spotkanie %in% c("S05", "05")) {
    assign("korpus_polityczny", wczytaj_korpus_polityczny(n = 60), envir = env)
    assign("korpus_naukowy", wczytaj_korpus_naukowy(n = 60), envir = env)
  }
  if (spotkanie %in% c("S06", "06")) {
    assign("korpus_polityczny", wczytaj_korpus_polityczny(n = 60), envir = env)
    assign("respondenci", wczytaj_respondentow(n = 200), envir = env)
  }
  if (spotkanie %in% c("S07", "07")) {
    assign("respondenci", wczytaj_respondentow(n = 200), envir = env)
  }
  invisible(TRUE)
}
