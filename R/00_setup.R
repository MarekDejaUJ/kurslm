# Setup kursu LLM w analizie tekstu.
# Ten plik jest jedynym elementem technicznym, ktory student musi uruchomic.

czas_start <- Sys.time()

kurs_auto_install <- isTRUE(getOption("kurs_auto_install", TRUE))
kurs_tryb_mock <- isTRUE(getOption("kurs_tryb_mock", FALSE))

pakiety_wymagane <- c(
  "cli", "glue", "dplyr", "tidyr", "purrr", "stringr", "tibble", "readr",
  "ggplot2", "rollama", "gt", "kableExtra", "igraph", "wordcloud2",
  "syuzhet", "irr", "yardstick", "sotu", "gutenbergr", "rmarkdown", "knitr"
)

kurs_info <- function(...) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_inform(...)
  } else {
    message(paste(unlist(list(...)), collapse = "\n"))
  }
}

kurs_warn <- function(...) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_warn(...)
  } else {
    warning(paste(unlist(list(...)), collapse = "\n"), call. = FALSE)
  }
}

kurs_install_missing <- function(pakiety) {
  brakujace <- pakiety[!vapply(pakiety, requireNamespace, logical(1), quietly = TRUE)]
  if (length(brakujace) == 0) {
    return(invisible(TRUE))
  }

  if (!kurs_auto_install) {
    kurs_warn(c(
      "Brakuje pakietow, ale automatyczna instalacja jest wylaczona.",
      "i" = paste(brakujace, collapse = ", ")
    ))
    return(invisible(FALSE))
  }

  kurs_info(c(
    "Instaluje brakujace pakiety R.",
    "i" = paste(brakujace, collapse = ", ")
  ))

  for (pakiet in brakujace) {
    tryCatch(
      install.packages(pakiet, dependencies = TRUE),
      error = function(e) kurs_warn(c(
        paste0("Nie udalo sie zainstalowac pakietu ", pakiet, "."),
        "i" = conditionMessage(e)
      ))
    )
  }

  invisible(TRUE)
}

kurs_load_available <- function(pakiety) {
  for (pakiet in pakiety) {
    if (requireNamespace(pakiet, quietly = TRUE)) {
      suppressPackageStartupMessages(
        library(pakiet, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
      )
    }
  }
  invisible(TRUE)
}

kurs_install_missing(pakiety_wymagane)
kurs_load_available(pakiety_wymagane)

MODELE <- list(
  "qwen3-0.6b" = "qwen3:0.6b",
  "bielik-4.5b" = "SpeakLeash/bielik-4.5b-v3.0-instruct",
  "qwen3-4b" = "qwen3:4b",
  "phi4-mini" = "phi4-mini",
  "qwen3-8b" = "qwen3:8b"
)

options(kurs_modele = MODELE)
options(kurs_model_pl = MODELE[["bielik-4.5b"]])
options(kurs_model_en = MODELE[["qwen3-4b"]])
options(kurs_model_demo = MODELE[["qwen3-0.6b"]])
options(kurs_model_porownanie = MODELE[["phi4-mini"]])
options(kurs_model_symulacja = MODELE[["qwen3-8b"]])

kurs_ollama_dziala <- function() {
  if (kurs_tryb_mock) {
    return(FALSE)
  }
  dostepny <- nzchar(Sys.which("ollama"))
  if (!dostepny) {
    return(FALSE)
  }
  wynik <- tryCatch(
    system2("ollama", c("list"), stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  length(wynik) > 0
}

options(kurs_ollama_ok = kurs_ollama_dziala())

kurs_pull_model <- function(model, wymagany = FALSE) {
  if (kurs_tryb_mock || !isTRUE(getOption("kurs_ollama_ok", FALSE))) {
    return(invisible(FALSE))
  }
  wynik <- tryCatch(
    system2("ollama", c("list"), stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  if (any(grepl(model, wynik, fixed = TRUE))) {
    return(invisible(TRUE))
  }

  if (!wymagany && !isTRUE(getOption("kurs_auto_pull", FALSE))) {
    kurs_warn(c(
      paste0("Model ", model, " nie jest jeszcze pobrany."),
      "i" = paste0("Pobierz go poleceniem: ollama pull ", model)
    ))
    return(invisible(FALSE))
  }

  kurs_info(paste0("Pobieram model Ollama: ", model))
  tryCatch(
    system2("ollama", c("pull", model), stdout = TRUE, stderr = TRUE),
    error = function(e) kurs_warn(c(
      paste0("Nie udalo sie pobrac modelu ", model, "."),
      "i" = conditionMessage(e)
    ))
  )
  invisible(TRUE)
}

if (!kurs_tryb_mock && !isTRUE(getOption("kurs_ollama_ok", FALSE))) {
  kurs_warn(c(
    "Nie wykryto dzialajacej Ollamy.",
    "i" = "Zajecia mozna nadal przegladac; wywolania LLM zadzialaja po uruchomieniu Ollamy albo w trybie mock."
  ))
}

if (!kurs_tryb_mock && isTRUE(getOption("kurs_ollama_ok", FALSE))) {
  modele_studenckie <- MODELE[c("qwen3-0.6b", "bielik-4.5b", "qwen3-4b", "phi4-mini")]
  invisible(lapply(modele_studenckie, kurs_pull_model, wymagany = FALSE))
  if (isTRUE(getOption("kurs_sprawdz_model_symulacji", FALSE))) {
    kurs_pull_model(MODELE[["qwen3-8b"]], wymagany = FALSE)
  }
}

skrypty_kursu <- c(
  "R/01_modele.R",
  "R/02_dane.R",
  "R/03_wizualizacje.R",
  "R/04_walidacja.R",
  "R/06_eksport.R"
)

for (skrypt in skrypty_kursu) {
  if (file.exists(skrypt)) {
    source(skrypt, local = FALSE, encoding = "UTF-8")
  } else {
    kurs_warn(paste0("Brakuje skryptu: ", skrypt))
  }
}

czas_koniec <- round(as.numeric(difftime(Sys.time(), czas_start, units = "secs")), 1)
tryb <- if (kurs_tryb_mock) "mock" else if (isTRUE(getOption("kurs_ollama_ok", FALSE))) "Ollama" else "bez Ollamy"
kurs_info(c(
  paste0("Srodowisko gotowe. Tryb: ", tryb, ". Czas: ", czas_koniec, " s."),
  "i" = paste0("Modele: ", paste(names(MODELE), collapse = ", "))
))

invisible(TRUE)
