# System sprawdzania i oddawania zadan studentow.

#' Kreator konfiguracji Git i GitHub Classroom
#' @export
github_setup <- function() {
  cli::cli_h1("KONFIGURACJA GITHUB DLA KURSU")
  
  cli::cli_inform("Ten kreator pomoze Ci skonfigurowac dane Git oraz token dostepu do GitHub.")
  
  has_acct <- readline("Czy masz juz konto na github.com? (t/n): ")
  if (tolower(trimws(has_acct)) != "t") {
    cli::cli_alert_info("Otwieram strone rejestracji w przegladarce: https://github.com/signup")
    utils::browseURL("https://github.com/signup")
    readline("Nacisnij ENTER, gdy zalozysz konto na GitHubie...")
  }
  
  cli::cli_h2("Generowanie Tokenu GitHub (PAT)")
  cli::cli_inform(c(
    "GitHub wymaga tokenu dostepu (PAT) zamiast zwyklego hasla.",
    "Otworze dla Ciebie strone tworzenia tokenu. Parametry:",
    " - Nazwa: kurslm",
    " - Zaznacz uprawnienie: 'repo' (dostep do repozytoriow)"
  ))
  
  readline("Nacisnij ENTER, aby otworzyc strone tworzenia tokenu...")
  utils::browseURL("https://github.com/settings/tokens/new?description=kurslm&scopes=repo")
  
  token <- readline("Skopiuj i wklej wygenerowany token (zaczyna sie od ghp_): ")
  token <- trimws(token)
  
  if (!str_starts(token, "ghp_")) {
    cli::cli_alert_warning("Token nie wyglada na prawidlowy (powinien zaczynac sie od ghp_).")
  }
  
  cli::cli_h2("Dane Tozsamosci")
  imie <- readline("Podaj swoje imie: ")
  nazwisko <- readline("Podaj swoje nazwisko: ")
  email <- readline("Podaj email (ten sam co na GitHub): ")
  github_user <- readline("Podaj swoj login GitHub: ")
  
  imie <- trimws(imie)
  nazwisko <- trimws(nazwisko)
  email <- trimws(email)
  github_user <- trimws(github_user)
  
  # Zapis danych
  student_file <- file.path(Sys.getenv("USERPROFILE", Sys.getenv("HOME")), ".kurslm_credentials")
  credentials <- list(
    imie = imie,
    nazwisko = nazwisko,
    email = email,
    github_user = github_user,
    github_token = token
  )
  saveRDS(credentials, student_file)
  
  # Konfiguracja lokalna Git
  cli::cli_inform("Konfiguruje Git...")
  system2("git", c("config", "--global", "user.name", shQuote(paste(imie, nazwisko))))
  system2("git", c("config", "--global", "user.email", shQuote(email)))
  
  # Jesli jestesmy w repozytorium git, konfigurujemy lokalnie i dodajemy token
  if (file.exists(".git")) {
    system2("git", c("config", "user.name", shQuote(paste(imie, nazwisko))))
    system2("git", c("config", "user.email", shQuote(email)))
    
    # Probujemy zaktualizowac remote url, aby zawieral token
    tryCatch({
      origin_url <- system2("git", c("remote", "get-url", "origin"), stdout = TRUE, stderr = TRUE)
      if (length(origin_url) > 0 && !any(grepl("fatal", origin_url))) {
        clean_url <- gsub("https://github.com/", "", origin_url)
        new_url <- paste0("https://", github_user, ":", token, "@github.com/", clean_url)
        system2("git", c("remote", "set-url", "origin", new_url))
        cli::cli_alert_success("Zabezpieczono automatyczne uwierzytelnianie Git przy pushu.")
      }
    }, error = function(e) NULL)
  }
  
  cli::cli_alert_success("Konfiguracja ukonczona pomyslnie!")
  invisible(credentials)
}

#' Sprawdz kompletnosc i jakosc zadan w srodowisku
#' @export
sprawdz_zadania <- function() {
  cli::cli_h2("RAPORT KOMPLETNOSCI ZADAN")
  
  env <- .GlobalEnv
  zmienne <- ls(envir = env)
  
  # Wykrywanie zadan na podstawie zmiennych moj_prompt_zad[N]
  prompty_zmienne <- zmienne[str_detect(zmienne, "^moj_prompt_zad[0-9]+$")]
  if (length(prompty_zmienne) == 0) {
    cli::cli_alert_danger("Nie znaleziono zadnych zmiennych promptow (np. moj_prompt_zad1) w srodowisku!")
    return(invisible(FALSE))
  }
  
  numery_zadan <- sort(as.integer(str_extract(prompty_zmienne, "[0-9]+")))
  
  wszystkie_ok <- TRUE
  tabelka <- data.frame(
    Zadanie = integer(),
    Prompt = character(),
    Wyniki = character(),
    Interpretacja = character(),
    Nierozpoznane_pct = character(),
    Status = character(),
    stringsAsFactors = FALSE
  )
  
  for (i in numery_zadan) {
    p_name <- paste0("moj_prompt_zad", i)
    w_name <- paste0("wyniki_zad", i)
    int_name <- paste0("moja_interpretacja_zad", i)
    
    # 1. Walidacja promptu
    prompt_ok <- FALSE
    prompt_desc <- "brak"
    if (exists(p_name, envir = env)) {
      prompt_val <- get(p_name, envir = env)
      if (is.character(prompt_val) && nchar(trimws(prompt_val)) > 0) {
        if (str_detect(prompt_val, "\\[TUTAJ|\\[UZUPELNIJ|\\[WPISZ|\\[CHALLENGE")) {
          prompt_desc <- "placeholder"
        } else {
          prompt_ok <- TRUE
          prompt_desc <- paste0("ok (", nchar(prompt_val), " znakow)")
        }
      } else {
        prompt_desc <- "pusty"
      }
    }
    
    # 2. Walidacja wynikow
    wyniki_ok <- FALSE
    wyniki_desc <- "brak"
    nierozpoznane_pct <- "NA"
    if (exists(w_name, envir = env)) {
      wyniki_val <- get(w_name, envir = env)
      if (is.data.frame(wyniki_val) && nrow(wyniki_val) > 0) {
        wyniki_ok <- TRUE
        wyniki_desc <- paste0("ok (", nrow(wyniki_val), " wierszy)")
        
        # Obliczenie odsetka nierozpoznanych
        if ("klasyfikacja" %in% names(wyniki_val)) {
          nierozp_n <- sum(wyniki_val$klasyfikacja == "nierozpoznane", na.rm = TRUE)
          nierozp_pct <- round((nierozp_n / nrow(wyniki_val)) * 100, 1)
          nierozpoznane_pct <- paste0(nierozp_pct, "%")
          if (nierozp_pct > 30) {
            wyniki_desc <- paste0(wyniki_desc, " (wysoki % nierozp!)")
          }
        }
      } else {
        wyniki_desc <- "puste dane"
      }
    }
    
    # 3. Walidacja interpretacji
    int_ok <- FALSE
    int_desc <- "brak"
    if (exists(int_name, envir = env)) {
      int_val <- get(int_name, envir = env)
      if (is.character(int_val) && nchar(trimws(int_val)) > 0) {
        slowa <- unlist(strsplit(trimws(int_val), "\\s+"))
        if (length(slowa) > 20) {
          int_ok <- TRUE
          int_desc <- paste0("ok (", length(slowa), " slow)")
        } else {
          int_desc <- paste0("za krotka (", length(slowa), " slow)")
        }
      } else {
        int_desc <- "pusta"
      }
    }
    
    # Status zadania
    status <- "❌"
    if (prompt_ok && wyniki_ok && int_ok) {
      status <- "✅"
    } else if (prompt_ok || wyniki_ok || int_ok) {
      status <- "⚠️"
      wszystkie_ok <- FALSE
    } else {
      wszystkie_ok <- FALSE
    }
    
    # Wyswietlanie szczegolowe w konsoli
    if (status == "✅") {
      cli::cli_alert_success("Zadanie {i}: Prompt: {prompt_desc} | Wyniki: {wyniki_desc} | Interpretacja: {int_desc}")
    } else if (status == "⚠️") {
      cli::cli_alert_warning("Zadanie {i}: Prompt: {prompt_desc} | Wyniki: {wyniki_desc} | Interpretacja: {int_desc}")
    } else {
      cli::cli_alert_danger("Zadanie {i}: Prompt: {prompt_desc} | Wyniki: {wyniki_desc} | Interpretacja: {int_desc}")
    }
  }
  
  if (wszystkie_ok) {
    cli::cli_alert_success("Wszystkie wykonane zadania sa kompletne!")
  } else {
    cli::cli_alert_warning("Wykryto braki w zadaniach. Uzupelnij je przed oddaniem.")
  }
  
  invisible(wszystkie_ok)
}

#' Oddaj zadanie na GitHub Classroom
#' @param renderuj Czy wyrenderowac plik Rmd do PDF? (domyslnie TRUE)
#' @export
oddaj <- function(renderuj = TRUE) {
  # 1. Sprawdzenie studenta
  student_file <- file.path(Sys.getenv("USERPROFILE", Sys.getenv("HOME")), ".kurslm_credentials")
  if (!file.exists(student_file)) {
    cli::cli_alert_warning("Nie skonfigurowano tozsamosci. Uruchamiam kreator github_setup()...")
    cred <- github_setup()
  } else {
    cred <- readRDS(student_file)
  }
  
  # 2. Diagnostyka
  sprawdz_zadania()
  
  # 3. Detekcja pliku Rmd
  pliki_rmd <- list.files(pattern = "\\.Rmd$")
  if (length(pliki_rmd) == 0) {
    stop("Brak pliku .Rmd w biezacym katalogu roboczym. Upewnij sie, ze pracujesz w katalogu stworzonym przez nowe_spotkanie().")
  }
  
  rmd_plik <- pliki_rmd[1] # Bierzemy pierwszy znaleziony
  cli::cli_alert_info("Wykryto plik zadania: {rmd_plik}")
  
  # Ustalamy numer spotkania z nazwy pliku lub folderu
  spotkanie <- str_extract(rmd_plik, "S[0-9]+")
  if (is.na(spotkanie)) {
    spotkanie <- "SXX"
  }
  
  pdf_plik <- NA_character_
  if (renderuj) {
    cli::cli_inform("Renderuje plik Rmd do formatu PDF...")
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
    safe_nazwisko <- iconv(cred$nazwisko, to = "ASCII//TRANSLIT")
    safe_imie <- iconv(cred$imie, to = "ASCII//TRANSLIT")
    safe_nazwisko <- gsub("[^a-zA-Z0-9]", "", safe_nazwisko)
    safe_imie <- gsub("[^a-zA-Z0-9]", "", safe_imie)
    
    pdf_plik <- paste0(safe_nazwisko, "_", safe_imie, "_", spotkanie, "_", timestamp, ".pdf")
    
    render_status <- tryCatch({
      rmarkdown::render(rmd_plik, output_format = "pdf_document", output_file = pdf_plik, quiet = TRUE)
      TRUE
    }, error = function(e) {
      cli::cli_alert_danger("Blad podczas renderowania do PDF: {e$message}")
      cli::cli_alert_info("Upewnij sie, ze masz zainstalowany LaTeX (TinyTeX). Uruchom tinytex::install_tinytex() w razie potrzeby.")
      FALSE
    })
    
    if (!render_status) {
      stop("Renderowanie do PDF przerwane. Oddanie anulowane.")
    }
    
    cli::cli_alert_success("Wygenerowano plik PDF: {pdf_plik}")
  }
  
  # 4. Git commit & push
  if (!file.exists(".git")) {
    cli::cli_alert_danger("Katalog roboczy nie jest repozytorium Git. Czy zostal sklonowany z GitHub Classroom?")
    return(invisible(FALSE))
  }
  
  cli::cli_inform("Dodaje pliki do Gita...")
  system2("git", c("add", shQuote(rmd_plik)))
  if (!is.na(pdf_plik) && file.exists(pdf_plik)) {
    system2("git", c("add", shQuote(pdf_plik)))
  }
  
  commit_msg <- paste("Oddanie", spotkanie, "-", cred$imie, cred$nazwisko, format(Sys.time(), "%Y-%m-%d %H:%M"))
  cli::cli_inform("Tworze commit...")
  system2("git", c("commit", "-m", shQuote(commit_msg)))
  
  # Dynamiczne wstawienie tokenu przed pushem, jesli jest dostepny
  tryCatch({
    origin_url <- system2("git", c("remote", "get-url", "origin"), stdout = TRUE, stderr = TRUE)
    if (length(origin_url) > 0 && !any(grepl("fatal", origin_url)) && !is.null(cred$github_token)) {
      if (!grepl(cred$github_token, origin_url, fixed = TRUE)) {
        # Czyscimy z ewentualnego innego tokenu lub hasla
        clean_url <- gsub("https://[^@]+@github.com/", "github.com/", origin_url)
        clean_url <- gsub("https://github.com/", "github.com/", clean_url)
        new_url <- paste0("https://", cred$github_user, ":", cred$github_token, "@", clean_url)
        system2("git", c("remote", "set-url", "origin", new_url))
      }
    }
  }, error = function(e) NULL)
  
  cli::cli_inform("Wysylam do GitHub Classroom (git push)...")
  push_res <- system2("git", c("push"), stdout = TRUE, stderr = TRUE)
  
  if (any(grepl("Rejected|error|fatal", push_res, ignore.case = TRUE))) {
    cli::cli_alert_danger("Blad podczas wysylania kodu na serwer:")
    cli::cli_inform(push_res)
    return(invisible(FALSE))
  }
  
  cli::cli_alert_success("Praca zostala pomyslnie oddana na GitHub Classroom!")
  invisible(TRUE)
}
