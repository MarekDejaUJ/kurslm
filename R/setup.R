# Setup i konfiguracja srodowiska kursu kurslm.

# Globalna lista modeli i domyslne konfiguracje
.onLoad <- function(libname, pkgname) {
  MODELE <- list(
    "qwen3-0.6b" = "qwen3:0.6b",
    "bielik-4.5b" = "SpeakLeash/bielik-4.5b-v3.0-instruct",
    "qwen3-4b" = "qwen3:4b",
    "minimax-cloud" = "minimax-m2.5:cloud",
    "qwen3-8b" = "qwen3:8b"
  )
  
  if (is.null(getOption("kurs_modele"))) options(kurs_modele = MODELE)
  if (is.null(getOption("kurs_model_pl"))) options(kurs_model_pl = MODELE[["bielik-4.5b"]])
  if (is.null(getOption("kurs_model_en"))) options(kurs_model_en = MODELE[["qwen3-4b"]])
  if (is.null(getOption("kurs_model_demo"))) options(kurs_model_demo = MODELE[["qwen3-0.6b"]])
  if (is.null(getOption("kurs_model_porownanie"))) options(kurs_model_porownanie = MODELE[["minimax-cloud"]])
  if (is.null(getOption("kurs_model_symulacja"))) options(kurs_model_symulacja = MODELE[["qwen3-8b"]])
  if (is.null(getOption("kurs_tryb_mock"))) options(kurs_tryb_mock = FALSE)
}

#' Przelacz domyslny model polski na chmurowy minimax
#' @export
uzyj_chmury <- function() {
  modele <- getOption("kurs_modele")
  options(kurs_model_pl = modele[["minimax-cloud"]])
  cli::cli_alert_success("Przelaczono model polski na: {modele[['minimax-cloud']]} (Chmura)")
  cli::cli_alert_info("Upewnij sie, ze jestes zalogowany do Ollama Cloud. Uruchom 'ollama login' w terminalu.")
  invisible(TRUE)
}

#' Przelacz domyslny model polski na lokalny bielik
#' @export
uzyj_bielika <- function() {
  modele <- getOption("kurs_modele")
  options(kurs_model_pl = modele[["bielik-4.5b"]])
  cli::cli_alert_success("Przelaczono model polski na lokalny: {modele[['bielik-4.5b']]}")
  invisible(TRUE)
}

#' Sprawdz srodowisko techniczne kursu
#' @export
sprawdz_srodowisko <- function() {
  cli::cli_h1("WERYFIKACJA SRODOWISKA KURSU")
  
  # 1. Sprawdzenie Ollama
  ollama_ok <- FALSE
  dostepny_cli <- nzchar(Sys.which("ollama"))
  if (dostepny_cli) {
    wersja <- tryCatch({
      out <- system2("ollama", "--version", stdout = TRUE, stderr = TRUE)
      gsub("ollama version is ", "", out[1])
    }, error = function(e) "nieznana")
    
    serwer_dziala <- tryCatch({
      out <- system2("ollama", "list", stdout = TRUE, stderr = TRUE)
      length(out) > 0
    }, error = function(e) FALSE)
    
    if (serwer_dziala) {
      cli::cli_alert_success("Ollama dziala (wersja: {wersja})")
      ollama_ok <- TRUE
    } else {
      cli::cli_alert_danger("Serwer Ollama nie dziala (uruchom aplikacje Ollama)")
    }
  } else {
    cli::cli_alert_danger("Ollama nie jest zainstalowana w systemie")
  }
  
  # 2. Sprawdzenie modeli
  if (ollama_ok) {
    dostepne_modele <- tryCatch({
      out <- system2("ollama", "list", stdout = TRUE, stderr = TRUE)
      if (length(out) > 1) {
        vapply(strsplit(out[-1], "\\s+"), `[`, 1, FUN.VALUE = character(1))
      } else {
        character()
      }
    }, error = function(e) character())
    
    modele_wymagane <- getOption("kurs_modele", list())
    
    for (m_alias in names(modele_wymagane)) {
      m_nazwa <- modele_wymagane[[m_alias]]
      
      if (identical(m_alias, "minimax-cloud")) {
        jest_obecny <- any(grepl(m_nazwa, dostepne_modele, fixed = TRUE))
        if (jest_obecny) {
          cli::cli_alert_success("Model chmurowy {m_alias} ({m_nazwa}) -- dostepny w Ollama")
        } else {
          cli::cli_alert_warning("Model chmurowy {m_alias} ({m_nazwa}) -- brak. Upewnij sie, ze zostal zalogowany w Ollama (ollama login).")
        }
      } else {
        jest_obecny <- any(grepl(m_nazwa, dostepne_modele, fixed = TRUE))
        if (jest_obecny) {
          cli::cli_alert_success("Model lokalny {m_alias} ({m_nazwa}) -- gotowy")
        } else {
          cli::cli_alert_warning("Model lokalny {m_alias} ({m_nazwa}) -- brak. Pobierz: pobierz_modele('{m_alias}')")
        }
      }
    }
  }
  
  # 3. Sprawdzenie LaTeX / TinyTeX
  latex_ok <- FALSE
  if (requireNamespace("tinytex", quietly = TRUE)) {
    if (tinytex::is_tinytex()) {
      cli::cli_alert_success("LaTeX (TinyTeX) -- zainstalowany i gotowy do renderowania PDF")
      latex_ok <- TRUE
    } else {
      pdflatex_path <- Sys.which("pdflatex")
      if (nzchar(pdflatex_path)) {
        cli::cli_alert_success("LaTeX (pdflatex) -- wykryto w systemie: {pdflatex_path}")
        latex_ok <- TRUE
      } else {
        cli::cli_alert_warning("Brak LaTeX (TinyTeX). Zainstaluj, aby renderowac PDF: tinytex::install_tinytex()")
      }
    }
  } else {
    cli::cli_alert_warning("Brak pakietu 'tinytex'. Zainstaluj i uruchom: install.packages('tinytex'); tinytex::install_tinytex()")
  }
  
  # 4. Sprawdzenie studenta
  student_file <- file.path(Sys.getenv("USERPROFILE", Sys.getenv("HOME")), ".kurslm_credentials")
  if (file.exists(student_file)) {
    cred <- tryCatch(readRDS(student_file), error = function(e) list())
    if (!is.null(cred$imie) && !is.null(cred$nazwisko)) {
      cli::cli_alert_success("Dane studenta: {cred$imie} {cred$nazwisko} ({cred$email})")
    } else {
      cli::cli_alert_warning("Dane studenta nieustawione. Uruchom ustaw_studenta() lub github_setup()")
    }
  } else {
    cli::cli_alert_warning("Dane studenta nieustawione. Uruchom ustaw_studenta() lub github_setup()")
  }
  
  invisible(ollama_ok && latex_ok)
}

#' Pobierz wymagane modele Ollama
#' @param modele NULL (wszystkie) lub wektor aliasow modeli
#' @export
pobierz_modele <- function(modele = NULL) {
  wymagane_slownik <- getOption("kurs_modele")
  
  if (is.null(modele)) {
    wybrane <- wymagane_slownik
    # Omijamy model chmurowy minimax-cloud przy automatycznym masowym pobieraniu
    wybrane <- wybrane[names(wybrane) != "minimax-cloud"]
  } else {
    wybrane <- wymagane_slownik[modele]
    wybrane <- wybrane[!is.na(wybrane)]
  }
  
  if (length(wybrane) == 0) {
    cli::cli_alert_info("Brak pasujacych modeli lokalnych do pobrania.")
    return(invisible(FALSE))
  }
  
  for (m_alias in names(wybrane)) {
    m_nazwa <- wybrane[[m_alias]]
    cli::cli_inform("Rozpoczynam pobieranie modelu: {m_alias} ({m_nazwa})...")
    system2("ollama", c("pull", m_nazwa))
  }
  
  cli::cli_alert_success("Procedura pobierania modeli zakonczona.")
  invisible(TRUE)
}

#' Konfiguracja tozsamosci studenta (bez gihuba)
#' @param imie Imie studenta
#' @param nazwisko Nazwisko studenta
#' @param email Adres email studenta
#' @export
ustaw_studenta <- function(imie = NULL, nazwisko = NULL, email = NULL) {
  if (is.null(imie)) imie <- readline("Podaj imie: ")
  if (is.null(nazwisko)) nazwisko <- readline("Podaj nazwisko: ")
  if (is.null(email)) email <- readline("Podaj email: ")
  
  student_file <- file.path(Sys.getenv("USERPROFILE", Sys.getenv("HOME")), ".kurslm_credentials")
  
  dane <- list(
    imie = trimws(imie),
    nazwisko = trimws(nazwisko),
    email = trimws(email)
  )
  
  saveRDS(dane, student_file)
  cli::cli_alert_success("Zapisano dane studenta do: {student_file}")
  invisible(dane)
}

#' Utworz katalog dla nowego spotkania i skopiuj szablon .Rmd
#' @param n Numer spotkania (1-7)
#' @export
nowe_spotkanie <- function(n) {
  spotkanie_str <- sprintf("S%02d", as.integer(n))
  katalog_docelowy <- file.path(getwd(), paste0("kurslm_", tolower(spotkanie_str)))
  
  # Mapowanie plikow szablonow
  pliki_szablony <- c(
    "S01" = "S01_generowanie.Rmd",
    "S02" = "S02_sentyment.Rmd",
    "S03" = "S03_ekstrakcja.Rmd",
    "S04" = "S04_analiza_dyskursu.Rmd",
    "S05" = "S05_porownanie_modeli.Rmd",
    "S06" = "S06_walidacja.Rmd",
    "S07" = "S07_projekt_koncowy.Rmd"
  )
  
  nazwa_szablonu <- pliki_szablony[spotkanie_str]
  if (is.na(nazwa_szablonu)) {
    stop("Niepoprawny numer spotkania. Wybierz liczbe od 1 do 7.")
  }
  
  sciezka_szablonu <- system.file("rmd", nazwa_szablonu, package = "kurslm")
  if (sciezka_szablonu == "") {
    stop("Nie znaleziono pliku szablonu w pakiecie. Reinstaluj pakiet.")
  }
  
  # Tworzenie katalogu
  dir.create(katalog_docelowy, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(katalog_docelowy, "wyniki"), recursive = TRUE, showWarnings = FALSE)
  
  # Kopiowanie szablonu
  cel_plik <- file.path(katalog_docelowy, nazwa_szablonu)
  file.copy(sciezka_szablonu, cel_plik, overwrite = TRUE)
  
  cli::cli_alert_success("Pobrano materialy do: {katalog_docelowy}")
  cli::cli_alert_info("Otworz plik: {cel_plik} i rozpocznij prace.")
  
  # Ustawienie opcji biezacego spotkania
  options(kurs_biezace_spotkanie = spotkanie_str)
  
  invisible(cel_plik)
}
