# Pakiet R `kurslm` — plan struktury i wdrożenia

## Repozytorium: `github.com/MarekDejaUJ/kurslm`

---

## 1. WORKFLOW STUDENTA (po zainstalowaniu pakietu)

```r
# Raz na początku semestru (lub administrator na pracowni):
# install.packages("remotes")
# remotes::install_github("MarekDejaUJ/kurslm")

# Na każdych zajęciach:
library(kurslm)

# Sprawdzenie środowiska (Ollama, modele, połączenie):
sprawdz_srodowisko()
# ✅ Ollama działa (v0.9.2)
# ✅ qwen3:4b — gotowy
# ✅ bielik-4.5b — gotowy
# ⚠️ qwen3:0.6b — brak (potrzebny w S01, S05). Pobierz: pobierz_modele("qwen3-0.6b")
# ⚠️ phi4-mini — brak (potrzebny w S05). Pobierz: pobierz_modele("phi4-mini")

# Pobranie brakujących modeli:
pobierz_modele()        # pobiera WSZYSTKIE z planu
pobierz_modele("qwen3-0.6b")  # lub konkretny

# Rozpoczęcie spotkania:
nowe_spotkanie(2)
# ✅ Skopiowano S02_sentyment.Rmd do /home/student/kurslm_s02/
# ✅ Utworzono katalog wyniki/
# 📂 Otwórz plik: /home/student/kurslm_s02/S02_sentyment.Rmd

# Student otwiera .Rmd i pracuje. Wszystkie funkcje dostępne z library(kurslm).
# Na końcu zajęć:
zapisz_wyniki(list(zad1 = wyniki_zad1, ...), spotkanie = "s02")
```

**Co to zmienia na pracowni:**
- Pakiet zainstalowany raz — przeżywa restarty komputera
- `library(kurslm)` ładuje WSZYSTKO (funkcje, palety, dane) — zero `source()`
- `nowe_spotkanie(n)` tworzy czysty katalog roboczy z gotowym .Rmd
- `sprawdz_srodowisko()` mówi studentowi co brakuje, zanim zacznie
- Nie trzeba klonować repo ani kopiować plików ręcznie

---

## 2. STRUKTURA PAKIETU

```
kurslm/
│
├── DESCRIPTION                         # metadane pakietu
├── NAMESPACE                           # eksportowane funkcje (generowany przez roxygen2)
├── LICENSE                             # MIT lub GPL-3
├── README.md                           # instrukcja instalacji i użycia
├── .Rbuildignore                       # wyklucza inst/prowadzacy, testy itp.
│
├── R/                                  # ← FUNKCJE EKSPORTOWANE
│   ├── setup.R                         # sprawdz_srodowisko(), pobierz_modele(), nowe_spotkanie()
│   ├── modele.R                        # zapytaj(), klasyfikuj(), klasyfikuj_zbior(), generuj(),
│   │                                   #   wyciagnij(), porownaj_modele(), porownaj_thinking()
│   ├── dane.R                          # wczytaj_korpus_polityczny(), _naukowy(), _faktograficzny(),
│   │                                   #   wczytaj_respondentow(), przygotuj_fragmenty()
│   ├── wizualizacje.R                  # pokaz_rozklad(), pokaz_porownanie(), pokaz_confusion_matrix(),
│   │                                   #   pokaz_heatmapa_zgodnosci(), pokaz_triangulacje(),
│   │                                   #   pokaz_tabele(), pokaz_siec_podmiotow(), pokaz_chmure(),
│   │                                   #   pokaz_porownanie_modeli(), pokaz_thinking_vs_not(),
│   │                                   #   pokaz_piramide_walidacji()
│   ├── walidacja.R                     # test_retest(), policz_metryki(), policz_kappa(),
│   │                                   #   policz_alpha(), analizuj_bledy(), trianguluj(),
│   │                                   #   porownaj_frameworki_walidacja()
│   ├── eksport.R                       # zapisz_wyniki(), zapisz_csv(), pokaz_podsumowanie_spotkania()
│   ├── config.R                        # MODELE lista, PALETA kolorów, stałe konfiguracyjne
│   └── zzz.R                           # .onAttach() — komunikat powitalny
│
├── inst/
│   ├── rmd/                            # ← SZABLONY .Rmd (kopiowane przez nowe_spotkanie())
│   │   ├── S01_generowanie.Rmd
│   │   ├── S02_sentyment.Rmd
│   │   ├── S03_ekstrakcja.Rmd
│   │   ├── S04_analiza_dyskursu.Rmd
│   │   ├── S05_porownanie_modeli.Rmd
│   │   ├── S06_walidacja.Rmd
│   │   └── S07_projekt_koncowy.Rmd
│   │
│   ├── extdata/                        # ← DANE DOŁĄCZONE DO PAKIETU
│   │   ├── korpus_polityczny.rds       # SOTU fragmenty (pregenerowane)
│   │   ├── korpus_naukowy.rds          # abstrakty (pregenerowane)
│   │   └── korpus_faktograficzny.rds   # fragmenty encyklopedyczne
│   │   # respondenci_200.csv NIE jest tu — generuje prowadzący osobno
│   │
│   └── prowadzacy/                     # ← SKRYPTY TYLKO DLA PROWADZĄCEGO
│       ├── symulacja_respondenci.R
│       └── README_prowadzacy.md
│
├── man/                                # ← DOKUMENTACJA (generowana przez roxygen2)
│   └── (po devtools::document())
│
├── data/                               # ← LAZY-LOADED DATA (opcjonalnie, zamiast inst/extdata)
│   └── korpus_polityczny.rda           # alternatywa: data("korpus_polityczny")
│
└── tests/
    └── testthat/
        ├── test-modele.R               # testy: czy zapytaj() zwraca tekst
        ├── test-dane.R                 # testy: czy korpusy się ładują
        └── test-walidacja.R            # testy: czy kappa oblicza się poprawnie
```

---

## 3. DESCRIPTION

```
Package: kurslm
Title: Kurs LLM w Analizie Tekstu dla Profesjonalistów Informacji
Version: 0.1.0
Authors@R: person("Marek", "Deja", 
                  email = "marek.deja@uj.edu.pl", 
                  role = c("aut", "cre"),
                  comment = c(ORCID = "XXXX-XXXX-XXXX-XXXX"))
Description: Pakiet dydaktyczny do kursu analizy tekstu z użyciem lokalnych modeli 
    językowych (LLM) przez Ollama. Zawiera funkcje do klasyfikacji sentymentu, 
    ekstrakcji informacji, analizy dyskursu i walidacji wyników. Obsługuje modele 
    Qwen3, Bielik i phi4-mini. Materiały do 7 spotkań seminaryjnych.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: true
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.2
Depends:
    R (>= 4.1.0)
Imports:
    dplyr,
    tidyr,
    stringr,
    purrr,
    tibble,
    glue,
    ggplot2,
    gt,
    cli,
    rollama,
    syuzhet,
    irr,
    yardstick,
    igraph,
    sotu
Suggests:
    kableExtra,
    wordcloud2,
    gutenbergr,
    knitr,
    rmarkdown,
    testthat (>= 3.0.0)
Config/testthat/edition: 3
```

---

## 4. KLUCZOWE FUNKCJE — SPECYFIKACJA API

### setup.R — zarządzanie środowiskiem

```r
#' Sprawdź czy środowisko jest gotowe do pracy
#' @export
sprawdz_srodowisko <- function(verbose = TRUE) {
  # 1. Czy Ollama działa? (ping localhost:11434)
  # 2. Które modele z MODELE są pobrane? (rollama::list_models())
  # 3. Które spotkania wymagają których modeli?
  # Zwraca: tibble(model, alias, status, potrzebne_w)
  # Drukuje: kolorowy raport (cli)
}

#' Pobierz brakujące modele Ollama
#' @param modele NULL = wszystkie wymagane, lub wektor aliasów np. c("qwen3-0.6b", "phi4-mini")
#' @export
pobierz_modele <- function(modele = NULL) {
  # rollama::pull_model() z progress barem
  # Obsługa: brak Ollama, brak internetu, timeout
}

#' Przygotuj katalog roboczy dla danego spotkania
#' @param nr Numer spotkania (1-7)
#' @param katalog Katalog docelowy (domyślnie: ~/kurslm_s{nr}/)
#' @export
nowe_spotkanie <- function(nr, katalog = NULL) {
  # 1. Tworzy katalog roboczy
  # 2. Kopiuje .Rmd z inst/rmd/
  # 3. Tworzy podkatalogi: wyniki/, dane/ (symlinki do inst/extdata)
  # 4. Jeśli S06/S07 i brak respondenci_200.csv — ostrzeżenie
  # 5. Otwiera plik w RStudio (jeśli dostępne): rstudioapi::navigateToFile()
}
```

### config.R — stałe konfiguracyjne

```r
#' Lista modeli kursu
#' @export
MODELE <- list(
  "qwen3-0.6b"  = "qwen3:0.6b",
  "bielik-4.5b"  = "SpeakLeash/bielik-4.5b-v3.0-instruct",
  "qwen3-4b"     = "qwen3:4b",
  "phi4-mini"    = "phi4-mini",
  "qwen3-8b"     = "qwen3:8b"
)

#' Paleta kolorów kursu
#' @export
PALETA <- list(
  pozytywny = "#4CAF50", negatywny = "#F44336", neutralny = "#9E9E9E",
  akcentA = "#2196F3", akcentB = "#FF9800", akcentC = "#9C27B0",
  tlo = "#FAFAFA", tekst = "#212121"
)

#' Modele wymagane per spotkanie
#' @keywords internal
MODELE_PER_SPOTKANIE <- list(
  S01 = c("bielik-4.5b", "qwen3-0.6b"),
  S02 = c("qwen3-4b"),
  S03 = c("qwen3-4b"),
  S04 = c("qwen3-4b"),
  S05 = c("qwen3-0.6b", "bielik-4.5b", "qwen3-4b", "phi4-mini"),
  S06 = c("qwen3-4b", "bielik-4.5b"),
  S07 = c("bielik-4.5b")
)
```

### modele.R — kluczowe zmiany vs wersja source()

```r
#' @export
zapytaj <- function(prompt, model = "auto", temperature = 0.3, thinking = NULL) {
  # Rozwiązuje alias: "bielik-4.5b" → "SpeakLeash/bielik-4.5b-v3.0-instruct"
  model_id <- resolve_model(model)  # wewnętrzna funkcja
  # ... reszta logiki bez zmian
}
```

**Zmiana kluczowa vs source()**: zamiast `getOption("kurs_model_pl")` pakiet eksportuje
`MODELE` jako named list i `resolve_model()` jako wewnętrzną funkcję. Nie trzeba `options()`.

### dane.R — dane wbudowane w pakiet

```r
#' Wczytaj korpus polityczny (SOTU) dołączony do pakietu
#' @param n Liczba fragmentów (max 80)
#' @export
wczytaj_korpus_polityczny <- function(n = 80) {
  sciezka <- system.file("extdata", "korpus_polityczny.rds", package = "kurslm")
  if (sciezka == "") stop("Korpus polityczny nie znaleziony w pakiecie.")
  korpus <- readRDS(sciezka)
  if (n < nrow(korpus)) korpus <- dplyr::slice_sample(korpus, n = n)
  korpus
}
```

**Zmiana kluczowa**: dane ładowane przez `system.file()` z `inst/extdata/`, nie z katalogu roboczego.
Student nie musi mieć plików RDS — są wbudowane w pakiet.

---

## 5. PLIKI .Rmd — ZMIANA VS WERSJA SOURCE()

### Stara wersja (source):
```r
source("R/00_setup.R")  # ← wymaga pliku w katalogu roboczym
```

### Nowa wersja (pakiet):
```r
library(kurslm)  # ← ładuje WSZYSTKO
```

To jedyna zmiana. Reszta .Rmd (prompty, wywołania funkcji, refleksje) zostaje identyczna.

---

## 6. PREGENEROWANIE KORPUSÓW (jednorazowe, przed publikacją pakietu)

Przed `devtools::build()` prowadzący uruchamia skrypt przygotowawczy:

```r
# data-raw/przygotuj_korpusy.R (nie włączane do pakietu, tylko do budowy)
library(sotu)
library(dplyr)
library(stringr)
library(purrr)

# Korpus polityczny
set.seed(2024)
# ... (logika fragmentacji z PLAN_KURSU.md)
saveRDS(political_fragments, "inst/extdata/korpus_polityczny.rds")

# Korpus naukowy
# ... (gutenbergr lub ręcznie przygotowane abstrakty)
saveRDS(science_fragments, "inst/extdata/korpus_naukowy.rds")

# Korpus faktograficzny
# ...
saveRDS(factual_fragments, "inst/extdata/korpus_faktograficzny.rds")
```

To `data-raw/` — standardowy katalog R packages do skryptów przygotowujących dane.

---

## 7. RESPONDENCI — OSOBNY WORKFLOW

`respondenci_200.csv` NIE jest w pakiecie (byłby za duży i zależny od modelu).
Prowadzący generuje go osobno:

```r
library(kurslm)
# Skrypt dostępny w:
sciezka_skryptu <- system.file("prowadzacy", "symulacja_respondenci.R", package = "kurslm")
# Prowadzący kopiuje go i uruchamia:
file.copy(sciezka_skryptu, "~/symulacja_respondenci.R")
# Edytuje parametry (model, seed), uruchamia
# Wynik: respondenci_200.csv
# Prowadzący umieszcza CSV na dysku sieciowym pracowni lub w Moodle
```

W S06/S07 student wskazuje ścieżkę:
```r
respondenci <- wczytaj_respondentow("~/Pobrane/respondenci_200.csv")
# lub ścieżka sieciowa pracowni:
respondenci <- wczytaj_respondentow("Z:/kurslm/respondenci_200.csv")
```

---

## 8. INSTALACJA NA PRACOWNI — SCENARIUSZE

### Scenariusz A: Administrator instaluje raz (zalecany)

```bash
# W terminalu administratora (z prawami zapisu do R library):
Rscript -e 'install.packages("remotes"); remotes::install_github("MarekDejaUJ/kurslm")'
```

Pakiet ląduje w systemowej bibliotece R → przeżywa restarty.

### Scenariusz B: Student instaluje sam (jeśli brak admina)

```r
# Jeśli student ma zapis do domowego R library (zwykle ~/.local/lib/R):
install.packages("remotes")
remotes::install_github("MarekDejaUJ/kurslm")
# Problem: znika po restarcie, jeśli home jest czyszczony
```

### Scenariusz C: Preinstalacja w obrazie systemu

Jeśli pracownia używa obrazów (np. SCCM, FOG):
1. Administrator dodaje `remotes::install_github("MarekDejaUJ/kurslm")` do skryptu budowy obrazu
2. Pakiet jest w każdym klonie

### Scenariusz D: Pakiet z CRAN-like repo (zaawansowane)

Prowadzący stawia lokalne repo drat na serwerze wydziałowym:
```r
# Na serwerze:
drat::insertPackage("kurslm_0.1.0.tar.gz")

# Na pracowni (jednorazowo w Rprofile.site):
options(repos = c(UJ = "https://repo.uj.edu.pl/R", CRAN = "https://cran.r-project.org"))

# Potem normalnie:
install.packages("kurslm")
```

---

## 9. OLLAMA NA PRACOWNI — UWAGI

Pakiet R jest jednym elementem. Ollama to drugi:

1. **Ollama musi być zainstalowana** na każdym komputerze pracowni (lub na serwerze sieciowym).
2. **Modele muszą być pobrane** — to 2.5-5 GB per model.
3. **Opcja sieciowa**: jeden serwer Ollama na pracowni, studenci łączą się zdalnie:
   ```r
   # W .Rprofile lub na początku zajęć:
   Sys.setenv(OLLAMA_HOST = "http://serwer-pracowni:11434")
   ```
   Wtedy modele pobrane raz na serwerze, nie na każdej stacji.

4. **Funkcja `sprawdz_srodowisko()`** w pakiecie automatycznie testuje połączenie
   i raportuje brakujące modele — student wie co zrobić zanim zacznie.

---

## 10. PROMPT DLA CLAUDE CODE — BUDOWA PAKIETU

```
Zbuduj pakiet R o nazwie "kurslm" na podstawie pliku PLAN_KURSU.md i PLAN_PAKIETU.md.
Pakiet dydaktyczny do kursu LLM dla bibliotekarzy. Repozytorium: MarekDejaUJ/kurslm.

STRUKTURA:
kurslm/
├── DESCRIPTION (patrz PLAN_PAKIETU.md sekcja 3)
├── NAMESPACE (generowany przez roxygen2)
├── R/
│   ├── config.R — MODELE (lista aliasów), PALETA (kolory), MODELE_PER_SPOTKANIE
│   ├── setup.R — sprawdz_srodowisko(), pobierz_modele(), nowe_spotkanie()
│   ├── modele.R — zapytaj(), klasyfikuj(), klasyfikuj_zbior(), generuj(), wyciagnij(),
│   │              porownaj_modele(), porownaj_thinking(), resolve_model() [internal]
│   ├── dane.R — wczytaj_korpus_polityczny/naukowy/faktograficzny(), wczytaj_respondentow()
│   │            Dane z system.file("extdata", ..., package="kurslm")
│   ├── wizualizacje.R — wszystkie pokaz_*() z PALETA
│   ├── walidacja.R — test_retest(), policz_metryki/kappa/alpha(), analizuj_bledy(), trianguluj()
│   ├── eksport.R — zapisz_wyniki(), zapisz_csv()
│   └── zzz.R — .onAttach() komunikat powitalny
├── inst/rmd/ — 7 plików .Rmd (S01-S07), używają library(kurslm) zamiast source()
├── inst/extdata/ — korpus_polityczny.rds, korpus_naukowy.rds, korpus_faktograficzny.rds
├── inst/prowadzacy/ — symulacja_respondenci.R + README
├── data-raw/ — skrypty pregenerujące korpusy (nie w pakiecie)
├── man/ — generowane przez devtools::document()
└── tests/testthat/

ZASADY PAKIETU R:
1. Każda eksportowana funkcja ma dokumentację roxygen2 (@export, @param, @return, @examples).
2. Wewnętrzne funkcje (resolve_model, normalize_label, parse_thinking) mają @keywords internal.
3. Importy przez DESCRIPTION Imports + importFrom w NAMESPACE (nie library() w kodzie!).
4. Używaj dplyr::.data w tidyverse NSE, żeby uniknąć NOTE w R CMD check.
5. Polskie nazwy funkcji, angielska dokumentacja roxygen (standard R packages).
   Komunikaty konsoli (cli) po polsku.
6. LazyData: true — dane z data/ ładowane leniwie.
7. Testuj: devtools::check() musi przejść bez ERROR i WARNING.

MODELE (3 RODZINY):
- qwen3-0.6b, bielik-4.5b, qwen3-4b, phi4-mini, qwen3-8b
- Auto-dobór: model="auto" → sprawdza kolumnę jezyk w korpusie
- Thinking mode: zapytaj(thinking=TRUE) dodaje /think, parsuje <think>

PLIKI .Rmd W PAKIECIE:
- Używają library(kurslm) zamiast source("R/00_setup.R")
- Student pisze TYLKO: moj_prompt <- "...", wywołanie funkcji, moja_interpretacja <- "..."
- nowe_spotkanie(n) kopiuje .Rmd do katalogu roboczego studenta

DANE W PAKIECIE:
- Korpusy pregenerowane w data-raw/, zapisane do inst/extdata/ jako RDS
- wczytaj_korpus_*() używa system.file() do lokalizacji
- respondenci_200.csv NIE jest w pakiecie — generowany przez prowadzącego

KOLEJNOŚĆ IMPLEMENTACJI:
1. DESCRIPTION + config.R + zzz.R (fundament pakietu)
2. modele.R (zapytaj, klasyfikuj, thinking mode)
3. dane.R + data-raw/przygotuj_korpusy.R
4. wizualizacje.R
5. walidacja.R + eksport.R
6. setup.R (sprawdz_srodowisko, pobierz_modele, nowe_spotkanie)
7. inst/rmd/*.Rmd (7 spotkań)
8. inst/prowadzacy/symulacja_respondenci.R
9. man/ (devtools::document())
10. tests/
11. devtools::check() → napraw NOTE/WARNING
12. README.md z instrukcją instalacji

Po każdym kroku pokaż co zrobiłeś i czekaj na OK.
```

---

## 11. HARMONOGRAM WDROŻENIA

| Krok | Co | Czas | Kto |
|------|----|------|-----|
| 1 | Claude Code buduje szkielet pakietu (DESCRIPTION, R/, inst/) | 2-3h | prowadzący + CC |
| 2 | Pregenerowanie korpusów (data-raw/) | 1h | prowadzący |
| 3 | Claude Code implementuje funkcje R/ | 4-6h | prowadzący + CC |
| 4 | Claude Code tworzy 7 plików .Rmd w inst/rmd/ | 2-3h | prowadzący + CC |
| 5 | devtools::check() + poprawki | 1-2h | prowadzący + CC |
| 6 | Push na GitHub | 15 min | prowadzący |
| 7 | Test instalacji na czystej maszynie | 30 min | prowadzący |
| 8 | Instalacja na pracowni (administrator) | 30 min | admin IT |
| 9 | Test z pierwszym spotkaniem (S01) | 1h | prowadzący |
| 10 | Generowanie respondenci_200.csv (przed S06) | 2-3h | prowadzący |
