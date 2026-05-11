# Integracja GitHub Classroom — specyfikacja

## 1. PERSPEKTYWA STUDENTA (zero wiedzy o Git)

### Jednorazowo na początku semestru (S01):

```r
library(kurslm)

# Krok 1: Kreator prowadzi przez wszystko
github_setup()
```

Kreator wyświetla w konsoli (interaktywnie):

```
══════════════════════════════════════════════════
🔧 KONFIGURACJA GITHUB — krok 1 z 4
══════════════════════════════════════════════════

Będziemy potrzebować konta GitHub do oddawania zadań.
Czy masz już konto na github.com? (t/n): n

══════════════════════════════════════════════════
📝 KROK 1: Załóż konto GitHub
══════════════════════════════════════════════════

Otwieram stronę rejestracji w przeglądarce...

  → Wejdź na: https://github.com/signup
  → Użyj adresu e-mail uczelnianego (@student.uj.edu.pl)
  → Zapamiętaj login i hasło

Naciśnij ENTER gdy konto będzie gotowe...

══════════════════════════════════════════════════
🔑 KROK 2: Token dostępu (zamiast hasła)
══════════════════════════════════════════════════

GitHub wymaga tokena zamiast hasła. Utworzę go za Ciebie.
Otwieram stronę tworzenia tokena...

  → Otworzy się strona: github.com/settings/tokens/new
  → Nazwa: "kurslm"
  → Zaznacz: "repo" (dostęp do repozytoriów)
  → Kliknij "Generate token"
  → SKOPIUJ token (zaczyna się od ghp_...)

Wklej token tutaj: ghp_xxxxxxxxxxxxxxxxxxxx
✅ Token zapisany bezpiecznie.

══════════════════════════════════════════════════
📋 KROK 3: Dane do commitów
══════════════════════════════════════════════════

Podaj imię: Marek
Podaj nazwisko: Deja
E-mail (ten sam co na GitHub): marek.deja@student.uj.edu.pl
✅ Konfiguracja Git zapisana.

══════════════════════════════════════════════════
🎓 KROK 4: Dołącz do kursu
══════════════════════════════════════════════════

Prowadzący podał link do kursu na GitHub Classroom.
Wklej link z Moodle: https://classroom.github.com/a/xYz123...

Otwieram w przeglądarce... Zaakceptuj zaproszenie i wróć tutaj.

Naciśnij ENTER gdy zaakceptujesz...

══════════════════════════════════════════════════
✅ GOTOWE! Konfiguracja zakończona.
══════════════════════════════════════════════════

Twoje dane:
  GitHub: @marek-deja
  Repozytorium: kurslm-2026/s01-marek-deja
  Token: zapisany w ~/.kurslm_credentials

Od teraz na każdych zajęciach wystarczy:
  nowe_spotkanie(2)   ← pobierz materiały
  oddaj()             ← wyślij pracę
```

### Na każdych zajęciach (S02, S03, ...):

```r
library(kurslm)

# Pobierz materiały do nowego spotkania:
nowe_spotkanie(2)
# ✅ Pobrano zadanie S02 z GitHub Classroom
# ✅ Otwarto: ~/kurslm/S02_sentyment.Rmd
# 💡 Pracuj w pliku .Rmd. Gdy skończysz: oddaj()

# ... student pracuje ...

# Sprawdź przed oddaniem:
sprawdz_zadania()

# Oddaj:
oddaj()
# ✅ Zapisano zmiany
# ✅ Wysłano na GitHub (commit: "S02 oddanie — Deja Marek")
# 🔗 https://github.com/kurslm-2026/s02-marek-deja
```

### Jeśli coś pójdzie nie tak:

```r
# Sprawdź status połączenia:
github_status()
# ✅ Git skonfigurowany (Marek Deja <marek.deja@student.uj.edu.pl>)
# ✅ Token ważny (wygasa: 2026-12-31)
# ✅ Repozytorium: kurslm-2026/s02-marek-deja
# ✅ Ostatni push: 2026-05-11 14:32

# Napraw problemy:
github_napraw()
# → Diagnozuje i naprawia: brak tokena, wygasły token, brak repo
```

---

## 2. PERSPEKTYWA PROWADZĄCEGO

### Przed semestrem (jednorazowo):

1. **Utwórz organizację** na GitHub: `kurslm-2026` (lub `kurslm-uj-2026`)
2. **Utwórz GitHub Classroom** → połącz z organizacją
3. **Dla każdego spotkania utwórz Assignment**:
   - S01: template repo = `MarekDejaUJ/kurslm-s01-template`
   - S02: template repo = `MarekDejaUJ/kurslm-s02-template`
   - ...
   - Deadline: data zajęć + 7 dni
   - Individual assignment (nie grupowe)

4. **Template repo** per spotkanie zawiera:
   ```
   kurslm-sXX-template/
   ├── SXX_temat.Rmd        ← plik roboczy studenta
   ├── .gitignore            ← ignoruje wyniki_cache/, .Rhistory
   └── README.md             ← "Otwórz .Rmd w RStudio i pracuj"
   ```

5. **Wklej linki do zaproszeń** na Moodle (jeden link per spotkanie)

### Po zajęciach:

```r
# Pobranie wszystkich prac (za pomocą GitHub Classroom CLI lub gh):
# gh classroom clone student-repos -a S02

# Lub w R:
prace <- pobierz_prace_github(
  organizacja = "kurslm-2026",
  assignment = "s02",
  katalog = "~/oceny/s02/"
)
# → Klonuje/pulluje wszystkie repozytoria studentów
# → Zwraca tibble ze ścieżkami

# Dalej jak wcześniej:
prace_dane <- zbierz_prace("~/oceny/s02/")
pokaz_przeglad_prac(prace_dane)
```

---

## 3. ARCHITEKTURA TECHNICZNA

### Pakiety R do Git (bez instalacji Git na komputerze!)

```
gert          — R-native Git (wbudowany libgit2, zero zależności systemowych)
gitcreds      — bezpieczne przechowywanie tokenów
credentials   — backend dla gert (HTTPS auth)
gh            — GitHub API (opcjonalnie, do sprawdzania repo)
```

**Kluczowe**: `gert` zawiera libgit2 — **nie trzeba instalować Git na pracowni**.
To eliminuje największą barierę na komputerach uczelnianych, gdzie studenci
nie mają uprawnień do instalacji oprogramowania.

### Dodanie do DESCRIPTION:

```
Imports:
    ...,
    gert (>= 2.0.0),
    gitcreds
Suggests:
    ...,
    gh
```

### Przechowywanie danych konfiguracyjnych

```
~/.kurslm_credentials    — token PAT (zaszyfrowany przez gitcreds)
~/.kurslm_student        — imię, nazwisko, email, github_login
~/.kurslm_config         — bieżące spotkanie, ścieżka repo, organizacja
```

Jeśli home jest czyszczony → `github_setup()` wykrywa brak i prosi o dane ponownie.
Token może być też w zmiennej środowiskowej (ustawianej przez admina w Rprofile.site):
```r
Sys.setenv(GITHUB_PAT = "ghp_...")
```

---

## 4. SPECYFIKACJA FUNKCJI

### github_setup() — jednorazowy kreator

```r
#' Konfiguracja GitHub dla kursu (interaktywny kreator)
#' @export
github_setup <- function() {
  cli::cli_h1("Konfiguracja GitHub")
  
  # 1. Sprawdź czy już skonfigurowane
  if (github_jest_skonfigurowany()) {
    cli::cli_alert_success("GitHub już skonfigurowany!")
    cli::cli_text("Użyj {.fn github_status} aby sprawdzić szczegóły.")
    cli::cli_text("Użyj {.fn github_reset} aby skonfigurować od nowa.")
    return(invisible(TRUE))
  }
  
  # 2. Konto GitHub
  ma_konto <- readline_tak_nie("Czy masz już konto na github.com?")
  if (!ma_konto) {
    cli::cli_alert_info("Otwieram stronę rejestracji...")
    utils::browseURL("https://github.com/signup")
    readline("Naciśnij ENTER gdy konto będzie gotowe...")
  }
  
  # 3. Token PAT
  cli::cli_h2("Token dostępu")
  cli::cli_alert_info("Otwieram stronę tworzenia tokena...")
  utils::browseURL(paste0(
    "https://github.com/settings/tokens/new",
    "?scopes=repo&description=kurslm"
  ))
  cli::cli_text('Zaznacz "repo", kliknij "Generate token", skopiuj.')
  
  token <- readline("Wklej token (ghp_...): ")
  stopifnot(startsWith(token, "ghp_") || startsWith(token, "github_pat_"))
  
  # Zapisz token bezpiecznie
  gitcreds::gitcreds_set(
    url = "https://github.com",
    credentials = gitcreds::gitcreds_new(
      protocol = "https",
      host = "github.com",
      username = "token",
      password = token
    )
  )
  
  # 4. Dane studenta
  cli::cli_h2("Dane do commitów")
  imie     <- readline("Podaj imię: ")
  nazwisko <- readline("Podaj nazwisko: ")
  email    <- readline("E-mail (ten sam co na GitHub): ")
  
  gert::git_config_global_set("user.name", paste(imie, nazwisko))
  gert::git_config_global_set("user.email", email)
  
  # Zapisz do pliku konfiguracyjnego
  zapisz_dane_studenta(imie, nazwisko, email)
  
  # 5. Link do Classroom (opcjonalnie — może być podany później)
  cli::cli_h2("Dołącz do kursu")
  link <- readline("Wklej link z Moodle (lub ENTER aby pominąć): ")
  if (nchar(link) > 10) {
    utils::browseURL(link)
    readline("Naciśnij ENTER gdy zaakceptujesz zaproszenie...")
  }
  
  cli::cli_alert_success("Konfiguracja zakończona!")
}
```

### nowe_spotkanie() — wersja z GitHub Classroom

```r
#' Rozpocznij nowe spotkanie (pobierz z GitHub Classroom)
#' @param nr Numer spotkania (1-7)
#' @param link Link do zaproszenia GitHub Classroom (opcjonalny — 
#'   jeśli brak, użyj linku z konfiguracji lub poproś studenta)
#' @param katalog Katalog roboczy (domyślnie ~/kurslm/)
#' @export
nowe_spotkanie <- function(nr, link = NULL, katalog = NULL) {
  
  # Ścieżka domyślna
  if (is.null(katalog)) {
    katalog <- file.path(path.expand("~"), "kurslm")
  }
  
  # Sprawdź czy GitHub skonfigurowany
  if (!github_jest_skonfigurowany()) {
    cli::cli_alert_warning("GitHub nie skonfigurowany. Uruchamiam kreator...")
    github_setup()
  }
  
  spotkanie_dir <- file.path(katalog, sprintf("s%02d", nr))
  
  if (dir.exists(spotkanie_dir) && plik_git_istnieje(spotkanie_dir)) {
    # Repo już sklonowane — pull najnowszych zmian
    cli::cli_alert_info("Repo już istnieje. Pobieram aktualizacje...")
    gert::git_pull(repo = spotkanie_dir)
    
  } else {
    # Pierwsze uruchomienie — potrzebujemy link lub URL repo
    if (is.null(link)) {
      # Spróbuj pobrać z konfiguracji
      link <- pobierz_link_classroom(nr)
    }
    if (is.null(link)) {
      # Poproś studenta
      link <- readline(sprintf(
        "Wklej link do zadania S%02d z Moodle: ", nr
      ))
    }
    
    # Jeśli to link classroom → otwórz w przeglądarce, poczekaj na akceptację
    if (grepl("classroom.github", link)) {
      cli::cli_alert_info("Otwieram zaproszenie w przeglądarce...")
      utils::browseURL(link)
      readline("Zaakceptuj zadanie i naciśnij ENTER...")
      
      # Pobierz URL repo (student musi podać lub parsujemy z classroom)
      repo_url <- readline("Wklej URL swojego repozytorium (https://github.com/...): ")
    } else {
      repo_url <- link
    }
    
    # Klonuj
    cli::cli_alert_info("Klonuję repozytorium...")
    gert::git_clone(
      url = repo_url,
      path = spotkanie_dir,
      verbose = TRUE
    )
  }
  
  # Otwórz .Rmd w RStudio
  rmd_plik <- list.files(spotkanie_dir, pattern = "\\.Rmd$", full.names = TRUE)[1]
  if (!is.na(rmd_plik) && rstudioapi_dostepne()) {
    rstudioapi::navigateToFile(rmd_plik)
  }
  
  cli::cli_alert_success("Spotkanie S{sprintf('%02d', nr)} gotowe!")
  cli::cli_text("Plik: {.file {rmd_plik}}")
  cli::cli_text("Gdy skończysz: {.fn oddaj}")
  
  invisible(spotkanie_dir)
}
```

### oddaj() — wersja z git push

```r
#' Oddaj pracę (commit + push na GitHub)
#' @param wiadomosc Opcjonalna wiadomość commita
#' @param renderuj Czy renderować .Rmd do HTML przed oddaniem?
#' @export
oddaj <- function(wiadomosc = NULL, renderuj = FALSE) {
  
  # 1. Znajdź repozytorium (katalog roboczy musi być repo git)
  repo <- znajdz_repo()
  if (is.null(repo)) {
    cli::cli_abort(c(
      "Nie znaleziono repozytorium Git w bieżącym katalogu.",
      "i" = "Czy uruchomiłeś {.fn nowe_spotkanie}?"
    ))
  }
  
  # 2. Diagnostyka przed oddaniem
  diag <- sprawdz_zadania(ciche = TRUE)
  
  if (diag$kompletnosc < 50) {
    cli::cli_alert_warning(
      "Kompletność: {diag$kompletnosc}%. Czy na pewno chcesz oddać? (t/n)"
    )
    if (readline() != "t") return(invisible(FALSE))
  }
  
  # 3. Opcjonalne renderowanie
  if (renderuj) {
    rmd <- list.files(repo, "\\.Rmd$", full.names = TRUE)[1]
    if (!is.na(rmd)) {
      cli::cli_alert_info("Renderuję {.file {basename(rmd)}}...")
      tryCatch(
        rmarkdown::render(rmd, quiet = TRUE),
        error = function(e) cli::cli_alert_warning("Renderowanie nie powiodło się: {e$message}")
      )
    }
  }
  
  # 4. Zapisz diagnostykę do pliku
  jsonlite::write_json(
    diag, 
    file.path(repo, "diagnostyka.json"), 
    pretty = TRUE, auto_unbox = TRUE
  )
  
  # 5. Git add + commit + push
  student <- wczytaj_dane_studenta()
  nr_spotkania <- wykryj_spotkanie(repo)
  
  if (is.null(wiadomosc)) {
    wiadomosc <- sprintf(
      "S%02d oddanie \u2014 %s %s [%d%% kompletne]",
      nr_spotkania, student$imie, student$nazwisko, diag$kompletnosc
    )
  }
  
  cli::cli_alert_info("Zapisuję zmiany...")
  gert::git_add(".", repo = repo)
  gert::git_commit(wiadomosc, repo = repo)
  
  cli::cli_alert_info("Wysyłam na GitHub...")
  tryCatch({
    gert::git_push(repo = repo)
    cli::cli_alert_success("Praca oddana!")
    
    # Pokaż link do repo
    remote <- gert::git_remote_list(repo = repo)
    url <- remote$url[remote$name == "origin"]
    url_web <- sub("\\.git$", "", sub("^git@github.com:", "https://github.com/", url))
    cli::cli_text("{.url {url_web}}")
    
  }, error = function(e) {
    cli::cli_alert_danger("Błąd wysyłania: {e$message}")
    cli::cli_text("Spróbuj: {.fn github_napraw}")
  })
  
  invisible(TRUE)
}
```

### zapisz_postep() — zapis pośredni (nie oddanie, tylko backup)

```r
#' Zapisz postęp pracy (commit bez push — lokalny backup)
#' @param wiadomosc Opcjonalna wiadomość
#' @export
zapisz_postep <- function(wiadomosc = NULL) {
  repo <- znajdz_repo()
  if (is.null(wiadomosc)) {
    wiadomosc <- sprintf("postęp — %s", format(Sys.time(), "%H:%M"))
  }
  gert::git_add(".", repo = repo)
  gert::git_commit(wiadomosc, repo = repo)
  cli::cli_alert_success("Postęp zapisany lokalnie.")
  cli::cli_text("Aby wysłać na GitHub: {.fn oddaj}")
}
```

### github_status() — diagnostyka połączenia

```r
#' Sprawdź status konfiguracji GitHub
#' @export
github_status <- function() {
  cli::cli_h2("Status GitHub")
  
  # Git config
  name  <- tryCatch(gert::git_config_global()$value[
    gert::git_config_global()$name == "user.name"], error = function(e) NA)
  email <- tryCatch(gert::git_config_global()$value[
    gert::git_config_global()$name == "user.email"], error = function(e) NA)
  
  if (!is.na(name)) {
    cli::cli_alert_success("Git: {name} <{email}>")
  } else {
    cli::cli_alert_danger("Git nie skonfigurowany")
  }
  
  # Token
  token_ok <- tryCatch({
    creds <- gitcreds::gitcreds_get(url = "https://github.com")
    TRUE
  }, error = function(e) FALSE)
  
  if (token_ok) {
    cli::cli_alert_success("Token GitHub: aktywny")
  } else {
    cli::cli_alert_danger("Token GitHub: brak lub wygasły")
  }
  
  # Repo w bieżącym katalogu
  repo <- tryCatch(gert::git_find(), error = function(e) NULL)
  if (!is.null(repo)) {
    remote <- gert::git_remote_list(repo = repo)
    cli::cli_alert_success("Repozytorium: {remote$url[1]}")
    
    log <- gert::git_log(repo = repo, max = 1)
    cli::cli_alert_info("Ostatni commit: {log$message} ({format(log$time, '%Y-%m-%d %H:%M')})")
  } else {
    cli::cli_alert_info("Brak repozytorium w bieżącym katalogu")
  }
}
```

### github_napraw() — auto-naprawa problemów

```r
#' Napraw typowe problemy z GitHub
#' @export
github_napraw <- function() {
  cli::cli_h2("Diagnostyka i naprawa")
  
  problemy <- 0
  
  # 1. Brak tokena
  token_ok <- tryCatch({gitcreds::gitcreds_get("https://github.com"); TRUE},
                       error = function(e) FALSE)
  if (!token_ok) {
    cli::cli_alert_warning("Problem: brak tokena GitHub")
    cli::cli_text("Otwieram stronę tworzenia tokena...")
    utils::browseURL("https://github.com/settings/tokens/new?scopes=repo&description=kurslm")
    token <- readline("Wklej nowy token: ")
    gitcreds::gitcreds_set(url = "https://github.com",
      credentials = gitcreds::gitcreds_new("https", "github.com", "token", token))
    cli::cli_alert_success("Token zapisany.")
    problemy <- problemy + 1
  }
  
  # 2. Brak git config
  name <- tryCatch(gert::git_config_global()$value[
    gert::git_config_global()$name == "user.name"], error = function(e) NA)
  if (is.na(name) || length(name) == 0) {
    cli::cli_alert_warning("Problem: brak konfiguracji Git")
    imie <- readline("Imię: ")
    nazwisko <- readline("Nazwisko: ")
    email <- readline("E-mail: ")
    gert::git_config_global_set("user.name", paste(imie, nazwisko))
    gert::git_config_global_set("user.email", email)
    zapisz_dane_studenta(imie, nazwisko, email)
    cli::cli_alert_success("Git skonfigurowany.")
    problemy <- problemy + 1
  }
  
  # 3. Push rejected (needs pull first)
  repo <- tryCatch(gert::git_find(), error = function(e) NULL)
  if (!is.null(repo)) {
    tryCatch({
      gert::git_pull(repo = repo)
      cli::cli_alert_success("Repozytorium zsynchronizowane.")
    }, error = function(e) {
      cli::cli_alert_warning("Konflikt — spróbuję rozwiązać automatycznie...")
      # force pull z theirs strategy
    })
  }
  
  if (problemy == 0) {
    cli::cli_alert_success("Nie znaleziono problemów!")
  } else {
    cli::cli_alert_success("Naprawiono {problemy} problem{ifelse(problemy>1,'ów','')}")
  }
}
```

---

## 5. GITHUB CLASSROOM — SETUP PROWADZĄCEGO

### Template repos (tworzy prowadzący raz)

Dla każdego spotkania osobny template repo na GitHubie:

```
MarekDejaUJ/kurslm-s01-template/
├── S01_generowanie.Rmd     ← z library(kurslm), bez source()
├── .gitignore
│   # Ignoruj pliki tymczasowe R
│   .Rhistory
│   .RData
│   *.Rproj.user
│   # Ale NIE ignoruj wyników — chcemy je w repo
└── README.md
    # Spotkanie 1: Generowanie tekstu
    # 1. Otwórz S01_generowanie.Rmd w RStudio
    # 2. Pracuj w pliku, wypełniając prompty
    # 3. Na końcu uruchom: oddaj()
```

### Tworzenie assignments w GitHub Classroom

```
Classroom: "Kurs LLM 2026" (organizacja: kurslm-2026)

Assignment 1: "S01 Generowanie tekstu"
  - Template: MarekDejaUJ/kurslm-s01-template
  - Deadline: 2026-10-15 23:59
  - Individual
  - Public repo (studenci widzą swoje)

Assignment 2: "S02 Analiza sentymentu"
  - Template: MarekDejaUJ/kurslm-s02-template
  - Deadline: 2026-10-22 23:59
  ...
```

### Autograding (opcjonalne, w GitHub Actions)

```yaml
# .github/classroom/autograding.json w template repo
{
  "tests": [
    {
      "name": "Kompletność promptów",
      "setup": "Rscript -e 'install.packages(\"jsonlite\", repos=\"https://cran.r-project.org\")'",
      "run": "Rscript -e 'j <- jsonlite::fromJSON(\"diagnostyka.json\"); stopifnot(j$kompletnosc >= 80)'",
      "timeout": 30,
      "points": 5
    },
    {
      "name": "Plik diagnostyka.json istnieje",
      "run": "test -f diagnostyka.json",
      "timeout": 5,
      "points": 1
    }
  ]
}
```

Autograding sprawdza tylko kompletność (czy oddano, czy wypełniono).
Jakość merytoryczną ocenia prowadzący ręcznie.

---

## 6. SCENARIUSZE BRZEGOWE

### Student zgubił token / home wyczyszczony
```r
library(kurslm)
github_napraw()
# → Wykrywa brak tokena, prowadzi przez tworzenie nowego
# → Wykrywa brak konfiguracji, pyta o dane
```

### Student chce pracować w domu
```r
# Na domowym komputerze:
install.packages("remotes")
remotes::install_github("MarekDejaUJ/kurslm")
library(kurslm)
github_setup()              # jednorazowo
nowe_spotkanie(2)           # klonuje repo
# ... pracuje ...
oddaj()                     # push
```

### Dwa komputery (pracownia + dom)
```r
# Na drugim komputerze:
nowe_spotkanie(2)
# → Wykrywa że repo już istnieje na GitHub
# → Klonuje z najnowszym stanem
# → Student kontynuuje
```

### Student zapomniał oddać na pracowni
```r
# Jeśli zapisał postęp (zapisz_postep()):
# → Commit jest lokalny, ale nie wypchnięty
# → Po ponownym uruchomieniu R na pracowni (jeśli home przetrwał):
oddaj()  # wypycha zaległy commit

# Jeśli NIE zapisał i home wyczyszczony:
# → Praca stracona. Dlatego .Rmd ma na dole przypomnienie:
# "💾 Zapisuj postęp regularnie: zapisz_postep()"
```

### Konflikt mergowy (student edytował na dwóch komputerach)
```r
oddaj()
# ⚠️ Nie mogę wysłać — są zmiany na serwerze.
# Czy pobrać zmiany z serwera? (t/n): t
# → git pull --rebase
# → Jeśli konflikt: nadpisuje wersję serwerową lokalną (studenckie repo,
#   nie ma ryzyka utraty cudzej pracy)
```

---

## 7. KOMPLETNA LISTA NOWYCH FUNKCJI

### Eksportowane (student widzi):

| Funkcja | Kiedy | Co robi |
|---------|-------|---------|
| `github_setup()` | Raz na semestr | Kreator: konto → token → config → classroom |
| `github_status()` | Diagnostyka | Raport: token, config, repo, ostatni commit |
| `github_napraw()` | Gdy coś nie działa | Auto-naprawa: token, config, pull |
| `nowe_spotkanie(n)` | Każde zajęcia | Clone/pull repo + otwórz .Rmd |
| `sprawdz_zadania()` | Przed oddaniem | Raport kompletności |
| `oddaj()` | Koniec zajęć | git add + commit + push + diagnostyka |
| `zapisz_postep()` | W trakcie | git add + commit (bez push) |

### Wewnętrzne (student nie widzi):

| Funkcja | Co robi |
|---------|---------|
| `resolve_model()` | Alias → pełna nazwa Ollama |
| `github_jest_skonfigurowany()` | Sprawdza token + config |
| `znajdz_repo()` | Szuka .git w bieżącym i nadrzędnych katalogach |
| `wykryj_spotkanie()` | Z nazwy .Rmd lub repo wyciąga numer spotkania |
| `zapisz_dane_studenta()` | Zapisuje do ~/.kurslm_student |
| `wczytaj_dane_studenta()` | Wczytuje z ~/.kurslm_student |
| `readline_tak_nie()` | Wrapper na readline z walidacją t/n |
| `rstudioapi_dostepne()` | Czy jesteśmy w RStudio? |
| `pobierz_link_classroom()` | Z konfiguracji lub pyta studenta |

### Nowe zależności w DESCRIPTION:

```
Imports:
    ...,
    gert (>= 2.0.0),
    gitcreds,
    jsonlite
Suggests:
    ...,
    gh,
    rstudioapi
```
