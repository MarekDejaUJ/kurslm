.onAttach <- function(libname, pkgname) {
  pakiety_wymagane <- c(
    "cli", "glue", "dplyr", "tidyr", "purrr", "stringr", "tibble", "readr",
    "ggplot2", "rollama", "gt", "kableExtra", "igraph", "wordcloud2",
    "syuzhet", "irr", "yardstick", "sotu", "gutenbergr", "rmarkdown", "knitr", "tinytex"
  )
  
  # Witaj studenta
  packageStartupMessage("=========================================================================")
  packageStartupMessage(" Witamy w pakiecie 'kurslm'!")
  packageStartupMessage(" Kurs: LLM w analizie tekstu dla profesjonalistow informacji")
  packageStartupMessage("=========================================================================")
  packageStartupMessage(" Uruchom sprawdz_srodowisko(), aby zweryfikowac konfiguracje Ollama i LaTeX.")
  packageStartupMessage(" Uruchom nowe_spotkanie(n), aby zaczac zadania dla spotkania o numerze n.")
  packageStartupMessage(" Uruchom ustaw_studenta() lub github_setup(), aby skonfigurowac tozsamosc.")
  packageStartupMessage("=========================================================================")
}
