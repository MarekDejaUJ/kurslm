# Wrappery do pracy z modelami LLM.

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x
}

kurs_as_tibble <- function(x) {
  if (requireNamespace("tibble", quietly = TRUE)) {
    tibble::as_tibble(x)
  } else {
    as.data.frame(x, stringsAsFactors = FALSE)
  }
}

kurs_new_tibble <- function(...) {
  if (requireNamespace("tibble", quietly = TRUE)) {
    tibble::tibble(...)
  } else {
    data.frame(..., stringsAsFactors = FALSE)
  }
}

kurs_model_alias <- function(model) {
  modele <- getOption("kurs_modele", list())
  tryb_lokalny <- isTRUE(getOption("kurs_tryb_lokalny", FALSE))
  
  if (length(model) == 0 || is.null(model) || is.na(model)) {
    model <- "auto"
  }
  
  if (identical(model, "auto")) {
    return(getOption("kurs_model_pl"))
  }
  
  # Standardyzacja aliasu (jezeli podano pelna sciezke modelu lub zly alias)
  alias <- model
  if (model %in% c("SpeakLeash/bielik-4.5b-v3.0-instruct", "bielik-4.5b", "hf.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF:Q8_0")) {
    alias <- "bielik-4.5b"
  } else if (model %in% c("pllum-4b", "hf.co/Jerzman/PLLuM-4B-instruct-2512-Q4_K_M-GGUF:Q4_K_M", "qwen3-0.6b")) {
    alias <- "pllum-4b"
  } else if (model %in% c("qwen3-4b", "qwen3:4b")) {
    alias <- "qwen3-4b"
  } else if (model %in% c("minimax-m2", "minimax-m2:cloud", "qwen3-8b", "qwen3:8b")) {
    alias <- "minimax-m2"
  } else if (model %in% c("minimax-m2.5", "minimax-m2.5:cloud", "minimax-cloud")) {
    alias <- "minimax-m2.5"
  }
  
  # Przekierowanie chmurowe (domyslnie tryb_lokalny = FALSE)
  if (!tryb_lokalny) {
    if (alias %in% c("bielik-4.5b", "pllum-4b", "minimax-m2")) {
      return(modele[["minimax-m2"]])
    } else if (alias %in% c("qwen3-4b", "minimax-m2.5")) {
      return(modele[["minimax-m2.5"]])
    }
  }
  
  # Tryb lokalny lub model spoza mapowania
  if (!is.null(modele[[alias]])) {
    return(modele[[alias]])
  }
  
  model
}

kurs_model_auto <- function(jezyk = NULL) {
  jezyk <- tolower(as.character(jezyk %||% "pl")[1])
  if (identical(jezyk, "en")) {
    getOption("kurs_model_en")
  } else {
    getOption("kurs_model_pl")
  }
}

kurs_wstaw_tekst <- function(prompt_szablon, text) {
  if (requireNamespace("glue", quietly = TRUE)) {
    as.character(glue::glue(prompt_szablon, text = text, .open = "{", .close = "}"))
  } else {
    gsub("{text}", text, prompt_szablon, fixed = TRUE)
  }
}

kurs_as_text <- function(x) {
  if (is.character(x)) {
    return(paste(x, collapse = "\n"))
  }
  if (is.list(x)) {
    kandydaci <- c("response", "message", "content", "text", "answer")
    for (k in kandydaci) {
      if (!is.null(x[[k]])) {
        return(kurs_as_text(x[[k]]))
      }
    }
    return(paste(unlist(x), collapse = "\n"))
  }
  as.character(x)
}

kurs_parse_thinking <- function(tekst) {
  tekst <- kurs_as_text(tekst)
  myslenie <- NA_character_
  odpowiedz <- tekst
  trafienie <- regexpr("<think>[\\s\\S]*?</think>", tekst, perl = TRUE)
  if (trafienie[1] != -1) {
    blok <- regmatches(tekst, trafienie)
    myslenie <- gsub("^<think>|</think>$", "", blok)
    odpowiedz <- trimws(sub("<think>[\\s\\S]*?</think>", "", tekst, perl = TRUE))
  }
  list(odpowiedz = trimws(odpowiedz), myslenie = trimws(myslenie))
}

kurs_hash_index <- function(tekst, n) {
  if (n <= 1) {
    return(1L)
  }
  raw <- charToRaw(enc2utf8(substr(tekst, 1, 2000)))
  (sum(as.integer(raw)) %% n) + 1L
}

kurs_mock_klasyfikacja <- function(tekst, etykiety) {
  etykiety[kurs_hash_index(tekst, length(etykiety))]
}

kurs_normalizuj_etykiete <- function(odpowiedz, etykiety) {
  odpowiedz_mala <- tolower(trimws(kurs_as_text(odpowiedz)))
  etykiety_male <- tolower(etykiety)

  dokladny <- match(odpowiedz_mala, etykiety_male)
  if (!is.na(dokladny)) {
    return(etykiety[dokladny])
  }

  for (i in seq_along(etykiety_male)) {
    wzorzec <- paste0("\\b", gsub("([\\W])", "\\\\\\1", etykiety_male[i], perl = TRUE), "\\b")
    if (grepl(wzorzec, odpowiedz_mala, perl = TRUE)) {
      return(etykiety[i])
    }
  }

  "nierozpoznane"
}

zapytaj <- function(prompt, model = "auto", temperature = 0.3, thinking = NULL, jezyk = NULL,
                   retries = 2, screen = FALSE) {
  model_docelowy <- if (identical(model, "auto")) kurs_model_auto(jezyk) else kurs_model_alias(model)
  prompt_wysylany <- prompt

  if (!is.null(thinking)) {
    prefix <- if (isTRUE(thinking)) "/think\n" else "/no_think\n"
    prompt_wysylany <- paste0(prefix, prompt_wysylany)
  }

  czas <- system.time({
    if (isTRUE(getOption("kurs_tryb_mock", FALSE))) {
      wynik <- paste0("Odpowiedz testowa modelu ", model_docelowy, ": ", substr(prompt_wysylany, 1, 120))
    } else {
      if (!requireNamespace("rollama", quietly = TRUE)) {
        stop("Brakuje pakietu rollama. Uruchom library(kurslm) w celu instalacji i weryfikacji srodowiska.")
      }

      ostatni_blad <- NULL
      wynik <- NULL
      for (proba in seq_len(retries)) {
        wynik <- tryCatch(
          rollama::query(prompt_wysylany, model = model_docelowy, screen = screen, temperature = temperature),
          error = function(e) {
            ostatni_blad <<- e
            NULL
          }
        )
        if (!is.null(wynik)) {
          break
        }
      }
      if (is.null(wynik)) {
        stop("Zapytanie do modelu nie powiodlo sie: ", conditionMessage(ostatni_blad))
      }
    }
  })

  parsed <- kurs_parse_thinking(wynik)
  list(
    odpowiedz = parsed$odpowiedz,
    myslenie = parsed$myslenie,
    czas = unname(czas[["elapsed"]]),
    model = model_docelowy
  )
}

generuj <- function(prompt, model = "auto", max_tokens = 500, temperature = 0.7, thinking = NULL) {
  prompt_pelny <- paste0(prompt, "\n\nMaksymalna dlugosc odpowiedzi: ", max_tokens, " tokenow.")
  res <- zapytaj(prompt_pelny, model = model, temperature = temperature, thinking = thinking)
  kurs_new_tibble(
    prompt = prompt,
    wynik = res$odpowiedz,
    model = res$model,
    czas = res$czas,
    myslenie = res$myslenie
  )
}

klasyfikuj <- function(tekst, prompt_szablon, etykiety, model = "auto", jezyk = NULL,
                       temperature = 0.2, thinking = NULL) {
  if (isTRUE(getOption("kurs_tryb_mock", FALSE))) {
    etykieta <- kurs_mock_klasyfikacja(tekst, etykiety)
    return(list(
      klasyfikacja = etykieta,
      odpowiedz_surowa = etykieta,
      model = if (identical(model, "auto")) kurs_model_auto(jezyk) else kurs_model_alias(model),
      czas = 0,
      myslenie = NA_character_
    ))
  }

  prompt <- kurs_wstaw_tekst(prompt_szablon, tekst)
  res <- zapytaj(prompt, model = model, temperature = temperature, thinking = thinking, jezyk = jezyk)
  list(
    klasyfikacja = kurs_normalizuj_etykiete(res$odpowiedz, etykiety),
    odpowiedz_surowa = res$odpowiedz,
    model = res$model,
    czas = res$czas,
    myslenie = res$myslenie
  )
}

klasyfikuj_zbior <- function(korpus, prompt_szablon, etykiety, model = "auto", n = 15,
                             kolumna_tekst = "text", kolumna_wynik = "klasyfikacja",
                             temperature = 0.2, thinking = NULL) {
  dane <- as.data.frame(korpus, stringsAsFactors = FALSE)
  if (!kolumna_tekst %in% names(dane)) {
    stop("Brakuje kolumny tekstowej: ", kolumna_tekst)
  }
  dane <- utils::head(dane, n)
  liczba <- nrow(dane)
  if (liczba == 0) {
    stop("Korpus jest pusty.")
  }

  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_progress_bar("Klasyfikuje fragmenty", total = liczba)
    on.exit(cli::cli_progress_done(), add = TRUE)
  } else {
    message("Klasyfikuje ", liczba, " fragmentow...")
  }

  wyniki <- vector("list", liczba)
  for (i in seq_len(liczba)) {
    jezyk <- dane$jezyk[i] %||% NULL
    wyniki[[i]] <- klasyfikuj(
      tekst = dane[[kolumna_tekst]][i],
      prompt_szablon = prompt_szablon,
      etykiety = etykiety,
      model = model,
      jezyk = jezyk,
      temperature = temperature,
      thinking = thinking
    )
    if (requireNamespace("cli", quietly = TRUE)) {
      cli::cli_progress_update()
    }
  }

  dane[[kolumna_wynik]] <- vapply(wyniki, `[[`, character(1), "klasyfikacja")
  dane$odpowiedz_surowa <- vapply(wyniki, `[[`, character(1), "odpowiedz_surowa")
  dane$model <- vapply(wyniki, `[[`, character(1), "model")
  dane$czas <- vapply(wyniki, `[[`, numeric(1), "czas")
  dane$myslenie <- vapply(wyniki, function(x) as.character(x$myslenie %||% NA_character_), character(1))

  kurs_as_tibble(dane)
}

wyciagnij <- function(tekst, prompt_szablon, model = "auto", jezyk = NULL,
                      temperature = 0.2, thinking = NULL) {
  if (isTRUE(getOption("kurs_tryb_mock", FALSE))) {
    return(list(
      ekstrakcja = paste0("wynik_testowy: ", substr(tekst, 1, 80)),
      odpowiedz_surowa = paste0("wynik_testowy: ", substr(tekst, 1, 80)),
      model = if (identical(model, "auto")) kurs_model_auto(jezyk) else kurs_model_alias(model),
      czas = 0,
      myslenie = NA_character_
    ))
  }

  prompt <- kurs_wstaw_tekst(prompt_szablon, tekst)
  res <- zapytaj(prompt, model = model, temperature = temperature, thinking = thinking, jezyk = jezyk)
  list(
    ekstrakcja = res$odpowiedz,
    odpowiedz_surowa = res$odpowiedz,
    model = res$model,
    czas = res$czas,
    myslenie = res$myslenie
  )
}

wyciagnij_strukture <- function(korpus, prompt_szablon, model = "auto", n = 10,
                                kolumna_tekst = "text", temperature = 0.2,
                                thinking = NULL) {
  dane <- as.data.frame(korpus, stringsAsFactors = FALSE)
  dane <- utils::head(dane, n)
  liczba <- nrow(dane)

  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_progress_bar("Wyciagam informacje", total = liczba)
    on.exit(cli::cli_progress_done(), add = TRUE)
  }

  wyniki <- vector("list", liczba)
  for (i in seq_len(liczba)) {
    wyniki[[i]] <- wyciagnij(
      tekst = dane[[kolumna_tekst]][i],
      prompt_szablon = prompt_szablon,
      model = model,
      jezyk = dane$jezyk[i] %||% NULL,
      temperature = temperature,
      thinking = thinking
    )
    if (requireNamespace("cli", quietly = TRUE)) {
      cli::cli_progress_update()
    }
  }

  dane$ekstrakcja <- vapply(wyniki, `[[`, character(1), "ekstrakcja")
  dane$odpowiedz_surowa <- vapply(wyniki, `[[`, character(1), "odpowiedz_surowa")
  dane$model <- vapply(wyniki, `[[`, character(1), "model")
  dane$czas <- vapply(wyniki, `[[`, numeric(1), "czas")
  dane$myslenie <- vapply(wyniki, function(x) as.character(x$myslenie %||% NA_character_), character(1))
  kurs_as_tibble(dane)
}

porownaj_modele <- function(prompt, modele, tekst = NULL, temperature = 0.3) {
  if (!is.null(tekst)) {
    prompt <- kurs_wstaw_tekst(prompt, tekst)
  }
  wyniki <- lapply(modele, function(model) {
    res <- zapytaj(prompt, model = model, temperature = temperature)
    data.frame(
      model_alias = model,
      model = res$model,
      odpowiedz = res$odpowiedz,
      czas = res$czas,
      stringsAsFactors = FALSE
    )
  })
  kurs_as_tibble(do.call(rbind, wyniki))
}

porownaj_prompty <- function(prompty, model = "auto", tekst = NULL, temperature = 0.3) {
  nazwy <- names(prompty)
  if (is.null(nazwy) || any(nazwy == "")) {
    nazwy <- paste0("prompt_", seq_along(prompty))
  }
  wyniki <- Map(function(nazwa, prompt) {
    prompt_pelny <- if (is.null(tekst)) prompt else kurs_wstaw_tekst(prompt, tekst)
    res <- zapytaj(prompt_pelny, model = model, temperature = temperature)
    data.frame(
      prompt = nazwa,
      model = res$model,
      odpowiedz = res$odpowiedz,
      czas = res$czas,
      stringsAsFactors = FALSE
    )
  }, nazwy, prompty)
  kurs_as_tibble(do.call(rbind, wyniki))
}

porownaj_frameworki <- function(korpus, prompty_lista, etykiety = NULL, model = "auto",
                                n = 10, kolumna_tekst = "text") {
  nazwy <- names(prompty_lista)
  if (is.null(nazwy) || any(nazwy == "")) {
    nazwy <- paste0("framework_", seq_along(prompty_lista))
  }
  baza <- as.data.frame(korpus, stringsAsFactors = FALSE)
  baza <- utils::head(baza, n)
  wynik <- baza[, intersect(c("id", kolumna_tekst, "jezyk", "zrodlo", "typ_korpusu"), names(baza)), drop = FALSE]

  for (i in seq_along(prompty_lista)) {
    nazwa <- make.names(nazwy[i])
    if (is.null(etykiety)) {
      czesc <- wyciagnij_strukture(baza, prompty_lista[[i]], model = model, n = n, kolumna_tekst = kolumna_tekst)
      wynik[[nazwa]] <- czesc$ekstrakcja
    } else {
      czesc <- klasyfikuj_zbior(baza, prompty_lista[[i]], etykiety, model = model, n = n, kolumna_tekst = kolumna_tekst)
      wynik[[nazwa]] <- czesc$klasyfikacja
    }
  }
  kurs_as_tibble(wynik)
}

porownaj_modele_zbior <- function(korpus, prompt, etykiety, modele, n = 10,
                                  kolumna_tekst = "text") {
  wyniki <- lapply(modele, function(model) {
    czesc <- klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n, kolumna_tekst = kolumna_tekst)
    czesc$model_alias <- model
    czesc
  })
  kurs_as_tibble(do.call(rbind, wyniki))
}

porownaj_korpusy <- function(korpus_lista, prompt, etykiety, model = "auto", n = 10) {
  nazwy <- names(korpus_lista)
  wyniki <- Map(function(nazwa, korpus) {
    czesc <- klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n)
    czesc$korpus <- nazwa
    czesc
  }, nazwy, korpus_lista)
  kurs_as_tibble(do.call(rbind, wyniki))
}

porownaj_thinking <- function(korpus, prompt, etykiety, model = "qwen3-4b", n = 10) {
  z_think <- klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n, thinking = TRUE)
  bez_think <- klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n, thinking = FALSE)

  wynik <- data.frame(
    id = z_think$id,
    text = z_think$text,
    think = z_think$klasyfikacja,
    no_think = bez_think$klasyfikacja,
    czas_think = z_think$czas,
    czas_no_think = bez_think$czas,
    zgodne = z_think$klasyfikacja == bez_think$klasyfikacja,
    myslenie = z_think$myslenie,
    stringsAsFactors = FALSE
  )
  kurs_as_tibble(wynik)
}

eksperyment_pelny <- function(korpus_lista, prompt_lista, model_lista, etykiety, n = 10) {
  wyniki <- list()
  licznik <- 1L
  for (nazwa_korpusu in names(korpus_lista)) {
    for (nazwa_promptu in names(prompt_lista)) {
      for (model in model_lista) {
        czesc <- klasyfikuj_zbior(
          korpus_lista[[nazwa_korpusu]],
          prompt_lista[[nazwa_promptu]],
          etykiety,
          model = model,
          n = n
        )
        czesc$korpus <- nazwa_korpusu
        czesc$framework <- nazwa_promptu
        czesc$model_alias <- model
        wyniki[[licznik]] <- czesc
        licznik <- licznik + 1L
      }
    }
  }
  kurs_as_tibble(do.call(rbind, wyniki))
}

analizuj_cot <- function(korpus, prompt, etykiety, model = "auto", n = 8) {
  klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n, thinking = TRUE)
}

klasyfikuj_odpowiedzi <- function(dane, kolumna, prompt, etykiety, model = "auto", n = 30) {
  korpus <- data.frame(
    id = dane$id %||% seq_len(nrow(dane)),
    text = dane[[kolumna]],
    jezyk = dane$jezyk %||% "pl",
    stringsAsFactors = FALSE
  )
  wynik <- klasyfikuj_zbior(korpus, prompt, etykiety, model = model, n = n)
  metryki <- as.data.frame(utils::head(dane, n), stringsAsFactors = FALSE)
  metryki$klasyfikacja <- wynik$klasyfikacja
  metryki$odpowiedz_surowa <- wynik$odpowiedz_surowa
  metryki$model <- wynik$model
  metryki$czas <- wynik$czas
  kurs_as_tibble(metryki)
}

wyciagnij_tematy <- function(dane, kolumna, prompt, model = "auto", n_tematow = 8, n = 30) {
  korpus <- data.frame(
    id = dane$id %||% seq_len(nrow(dane)),
    text = dane[[kolumna]],
    jezyk = dane$jezyk %||% "pl",
    stringsAsFactors = FALSE
  )
  wynik <- wyciagnij_strukture(korpus, prompt, model = model, n = n)
  wynik$limit_tematow <- n_tematow
  wynik
}
