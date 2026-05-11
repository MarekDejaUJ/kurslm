# System oddawania zadań — specyfikacja

## 1. PROBLEM

- Studenci piszą TYLKO: prompty (`moj_prompt_*`) i interpretacje (`moja_interpretacja_*`)
- Wyniki (`wyniki_*`) generowane przez funkcje pakietu — ważne do oceny, ale nie pisane ręcznie
- Pracownia się czyści po restarcie — student musi wyeksportować PRZED zamknięciem
- Prowadzący potrzebuje sprawdzić: kompletność, jakość promptów, trafność interpretacji
- 7 spotkań × N studentów = dużo plików → potrzebny standaryzowany format

---

## 2. ROZWIĄZANIE: dwie funkcje w pakiecie

### `sprawdz_zadania()` — autodiagnostyka PRZED oddaniem

Student uruchamia na końcu zajęć. Funkcja skanuje środowisko i raportuje:

```r
sprawdz_zadania()
# ══════════════════════════════════════════════
# 📋 RAPORT KOMPLETNOŚCI — Spotkanie S02
# ══════════════════════════════════════════════
# 
# Zadanie 1 (sentyment RTF):
#   ✅ Prompt wypełniony (327 znaków)
#   ✅ Wyniki wygenerowane (15 fragmentów, 0 nierozpoznanych)
#   ✅ Interpretacja napisana (4 zdania, 89 słów)
#
# Zadanie 2 (emocje CO-STAR):
#   ✅ Prompt wypełniony (412 znaków)
#   ✅ Wyniki wygenerowane (15 fragmentów, 2 nierozpoznane)
#   ⚠️ Interpretacja BRAK — wpisz moja_interpretacja_zad2
#
# Zadanie 3 (emocje naukowe):
#   ❌ Prompt niewypełniony — zawiera "[TUTAJ"
#   ❌ Wyniki brak
#   ❌ Interpretacja brak
#
# ══════════════════════════════════════════════
# PODSUMOWANIE: 2/4 zadania kompletne, 1 częściowe, 1 brak
# ⚠️ Uzupełnij brakujące elementy przed oddaniem!
# ══════════════════════════════════════════════
```

**Co sprawdza:**
- Czy `moj_prompt_*` istnieje i nie zawiera `[TUTAJ`, `[UZUPEŁNIJ`, `[WPISZ`
- Czy `wyniki_*` istnieje i ma sensowne dane (nie puste, nie same "nierozpoznane")
- Czy `moja_interpretacja_*` istnieje i ma > 20 słów
- Ile etykiet "nierozpoznane" — sygnał jakości promptu

### `oddaj()` — eksport paczki do oddania

```r
oddaj()
# ✅ Zapisano: Deja_Marek_S02.zip (148 KB)
# 📂 Lokalizacja: ~/kurslm_s02/Deja_Marek_S02.zip
# 
# Zawartość:
#   meta.json          — student, spotkanie, data, czas, modele
#   prompty.json       — wszystkie moj_prompt_* (tekst)
#   interpretacje.json — wszystkie moja_interpretacja_* (tekst)
#   wyniki.rds         — wszystkie wyniki_* (dane)
#   raport.html        — renderowany .Rmd (opcjonalnie)
#   diagnostyka.json   — wynik sprawdz_zadania() (kompletność)
```

**Logika oddaj():**

```r
#' Przygotuj paczkę do oddania
#' @param imie Imię studenta (pobierane z Sys.info() lub pytane)
#' @param nazwisko Nazwisko studenta
#' @param renderuj Czy renderować .Rmd do HTML? (domyślnie TRUE)
#' @param katalog_docelowy Gdzie zapisać ZIP
#' @export
oddaj <- function(imie = NULL, nazwisko = NULL, renderuj = TRUE, 
                  katalog_docelowy = getwd()) {
  
  # 1. Identyfikacja studenta
  #    - Jeśli imie/nazwisko NULL → pobierz z pliku .student 
  #      (tworzony raz przez ustaw_studenta())
  #    - Format nazwy: Nazwisko_Imie_S02.zip
  
  # 2. Zbieranie danych ze środowiska
  #    - ls(pattern = "^moj_prompt") → prompty
  #    - ls(pattern = "^moja_interpretacja") → interpretacje
  #    - ls(pattern = "^wyniki_") → wyniki
  #    - Numer spotkania z nazwy .Rmd lub z atrybutu
  
  # 3. Diagnostyka (sprawdz_zadania() wewnętrznie)
  
  # 4. Metadane
  #    meta <- list(
  #      student = paste(nazwisko, imie),
  #      spotkanie = nr_spotkania,
  #      data = Sys.time(),
  #      czas_pracy = difftime(Sys.time(), czas_startu),
  #      modele = rollama::list_models(),
  #      wersja_pakietu = packageVersion("kurslm"),
  #      kompletnosc = diagnostyka$procent
  #    )
  
  # 5. Renderowanie .Rmd → HTML (opcjonalne, wolne)
  #    Jeśli renderuj=TRUE i knitr dostępne:
  #    rmarkdown::render() z quiet=TRUE
  
  # 6. Pakowanie do ZIP
  #    Struktura ZIP:
  #    Nazwisko_Imie_S02/
  #    ├── meta.json
  #    ├── prompty.json
  #    ├── interpretacje.json
  #    ├── wyniki.rds
  #    ├── diagnostyka.json
  #    └── raport.html (opcjonalnie)
  
  # 7. Komunikat końcowy
  #    "✅ Plik gotowy: ~/kurslm_s02/Deja_Marek_S02.zip"
  #    "📤 Prześlij na Moodle / GitHub / dysk sieciowy"
}
```

### `ustaw_studenta()` — jednorazowa identyfikacja

```r
ustaw_studenta()
# Podaj imię: Marek
# Podaj nazwisko: Deja
# ✅ Zapisano do ~/.kurslm_student
# Nie musisz podawać tego ponownie.
```

Plik `~/.kurslm_student` przeżywa restarty (jeśli home nie jest czyszczony).
Jeśli jest czyszczony — `oddaj()` pyta o dane.

---

## 3. FORMAT PLIKU ODDANIA

### prompty.json (czytelny dla prowadzącego)

```json
{
  "spotkanie": "S02",
  "student": "Deja Marek",
  "prompty": {
    "zad1_sentyment": {
      "framework": "RTF",
      "tresc": "Jesteś analitykiem dyskursu politycznego...",
      "dlugosc_znakow": 327,
      "model": "qwen3-4b"
    },
    "zad2_emocje_polityczne": {
      "framework": "CO-STAR",
      "tresc": "Kontekst: Analizujesz fragmenty orędzi...",
      "dlugosc_znakow": 412,
      "model": "qwen3-4b"
    }
  }
}
```

### interpretacje.json

```json
{
  "zad1": {
    "tresc": "Rozkład sentymentu jest zdominowany przez...",
    "liczba_slow": 89
  },
  "zad2": {
    "tresc": "Emocje polityczne okazały się trudniejsze...",
    "liczba_slow": 112
  }
}
```

### diagnostyka.json (do szybkiego przeglądu)

```json
{
  "kompletnosc_procent": 75,
  "zadania": {
    "zad1": {"prompt": true, "wyniki": true, "interpretacja": true, "nierozpoznane_pct": 0},
    "zad2": {"prompt": true, "wyniki": true, "interpretacja": false, "nierozpoznane_pct": 13},
    "zad3": {"prompt": false, "wyniki": false, "interpretacja": false, "nierozpoznane_pct": null},
    "zad4": {"prompt": true, "wyniki": true, "interpretacja": true, "nierozpoznane_pct": 0}
  }
}
```

---

## 4. ODBIÓR I OCENA — PERSPEKTYWA PROWADZĄCEGO

### Funkcja `zbierz_prace()` (w inst/prowadzacy/)

```r
# Prowadzący wskazuje katalog z ZIPami (z Moodle, dysku sieciowego):
prace <- zbierz_prace("~/Pobrane/S02_prace/", spotkanie = "s02")

# Zwraca tibble:
# | student       | kompletnosc | zad1_prompt | zad1_nierozp | zad1_interp_slowa | ...
# |---------------|-------------|-------------|--------------|-------------------|
# | Deja Marek    | 100%        | TRUE        | 0%           | 89                |
# | Kowalski Jan  | 75%         | TRUE        | 13%          | 0 (brak)          |
# | Nowak Anna    | 50%         | FALSE       | NA           | 0                 |

# Szybki przegląd:
pokaz_przeglad_prac(prace)
# → heatmapa: student × zadanie (zielony/żółty/czerwony)
```

### Co prowadzący może ocenić automatycznie:

| Kryterium | Automatyczne? | Jak |
|-----------|---------------|-----|
| Kompletność (wszystkie prompty wypełnione) | ✅ TAK | diagnostyka.json |
| Długość interpretacji (> 50 słów?) | ✅ TAK | interpretacje.json |
| % nierozpoznanych odpowiedzi (jakość promptu) | ✅ TAK | wyniki.rds |
| Zgodność z frameworkiem (czy użył RTF/CO-STAR) | ⚠️ CZĘŚCIOWO | heurystyki na tekście promptu |
| Merytoryczna jakość promptu | ❌ NIE | ręczna ocena prowadzącego |
| Merytoryczna jakość interpretacji | ❌ NIE | ręczna ocena prowadzącego |

### Heurystyki jakości promptu (automatyczne):

```r
# Wewnętrzna funkcja oceny promptu
ocen_prompt <- function(tekst_promptu, framework) {
  wynik <- list()
  
  # Czy nie jest pusty / placeholder
  wynik$wypelniony <- !str_detect(tekst_promptu, "\\[TUTAJ|\\[UZUPEŁNIJ|\\[WPISZ")
  
  # Czy ma minimalną długość (>100 znaków)
  wynik$dlugosc_ok <- nchar(tekst_promptu) > 100
  
  # Czy zawiera {text} placeholder (potrzebny do glue)
  wynik$placeholder_ok <- str_detect(tekst_promptu, "\\{text\\}")
  
  # Czy zawiera elementy frameworka
  if (framework == "RTF") {
    wynik$framework_elementy <- sum(c(
      str_detect(tekst_promptu, regex("rola|role|jesteś|you are", TRUE)),
      str_detect(tekst_promptu, regex("zadanie|task|sklasyfikuj|classify", TRUE)),
      str_detect(tekst_promptu, regex("format|odpowiedz|respond|jedno słowo", TRUE))
    ))
  }
  # ... analogicznie dla CO-STAR, AUTOMAT, itp.
  
  wynik
}
```

---

## 5. KANAŁY PRZESYŁANIA — PORÓWNANIE

| Kanał | Wysiłek studenta | Wysiłek prowadzącego | Automatyzacja | Przeżywa restart? |
|-------|------------------|----------------------|---------------|--------------------|
| **Moodle (upload ZIP)** | oddaj() → upload | pobierz → zbierz_prace() | ⚠️ częściowa | ✅ (na serwerze) |
| **GitHub Classroom** | oddaj() → git push | clone → zbierz_prace() | ✅ pełna (Actions) | ✅ (na GitHubie) |
| **Dysk sieciowy** | oddaj(katalog="Z:/kurslm/") | zbierz_prace("Z:/kurslm/") | ⚠️ częściowa | ✅ (na serwerze) |
| **E-mail** | oddaj() → attach → send | ręczne pobieranie | ❌ | ✅ |
| **USB** | oddaj() → kopiuj | ręczne zbieranie | ❌ | ⚠️ (jeśli nie zgubi) |

### REKOMENDACJA: Moodle + oddaj()

Uzasadnienie:
1. UJ ma Moodle — zero dodatkowej infrastruktury
2. Student robi: `oddaj()` → upload ZIP na Moodle (2 kliknięcia)
3. Prowadzący pobiera wszystkie ZIPy jednym przyciskiem z Moodle
4. `zbierz_prace()` rozpakuje i wygeneruje tabelę zbiorczą
5. Moodle daje deadline, powiadomienia, historię — za darmo
6. Nie wymaga konta GitHub od studentów (bariera wejścia)

### ALTERNATYWA: GitHub Classroom (jeśli studenci mają konta)

Zalety: autograding via GitHub Actions, historia zmian, CI/CD.
Wada: wymaga konta GitHub od każdego studenta + konfiguracja Classroom.

Jeśli GitHub Classroom — `oddaj()` może automatycznie commitować i pushować:

```r
oddaj(metoda = "github")
# → git add -A && git commit -m "S02 oddanie" && git push
```

### OPCJA HYBRYDOWA: Moodle + automatyczne sprawdzanie

Na Moodle można skonfigurować feedback plugin, ale prościej:
prowadzący uruchamia `zbierz_prace()` i wrzuca wynik z powrotem na Moodle jako feedback.

---

## 6. WORKFLOW KOMPLETNY — OD ZAJĘĆ DO OCENY

```
STUDENT (na zajęciach):                    PROWADZĄCY (po zajęciach):

library(kurslm)                            
nowe_spotkanie(2)                          
# ... pracuje w Rmd ...                    
# ... pisze prompty ...                    
# ... pisze interpretacje ...              
                                           
sprawdz_zadania()                          
# → widzi co brakuje                      
# → uzupełnia                             
                                           
oddaj()                                    
# → Deja_Marek_S02.zip                    
# → upload na Moodle                      
                                           
                                           # Pobiera ZIPy z Moodle
                                           prace <- zbierz_prace("~/S02/")
                                           pokaz_przeglad_prac(prace)
                                           # → heatmapa kompletności
                                           
                                           # Szybki przegląd promptów:
                                           pokaz_prompty(prace, zadanie = "zad1")
                                           # → tabela: student | prompt | długość | nierozp%
                                           
                                           # Szczegółowa ocena (ręczna):
                                           # czyta interpretacje, ocenia jakość
                                           
                                           # Feedback na Moodle
```

---

## 7. DODANIE DO PLANU PAKIETU

### Nowe funkcje do R/

```
R/oddawanie.R:
  - sprawdz_zadania()      @export
  - oddaj()                @export  
  - ustaw_studenta()       @export
  - ocen_prompt()          @keywords internal
  - zbierz_zadania_env()   @keywords internal  (skanuje environment)

R/prowadzacy.R (lub w inst/prowadzacy/):
  - zbierz_prace()         (nie eksportowana — skrypt prowadzącego)
  - pokaz_przeglad_prac()  (nie eksportowana)
  - pokaz_prompty()        (nie eksportowana)
```

### Nowe zależności w DESCRIPTION

```
Imports:
  ...,
  jsonlite,    # zapis prompty.json, meta.json
  zip           # tworzenie ZIP (lżejsze niż utils::zip)
Suggests:
  ...,
  rstudioapi   # otwieranie plików w RStudio
```

---

## 8. ZMIANA W .Rmd — DODANIE BLOKU ODDANIA

Na końcu każdego .Rmd (przed ## Zapis wyników):

```rmd
## Sprawdzenie i oddanie

''''{r sprawdzenie}
# Sprawdź kompletność przed oddaniem:
sprawdz_zadania()
''''

''''{r oddanie, eval=FALSE}
# Gdy wszystko gotowe — wygeneruj paczkę:
oddaj()
# Prześlij wygenerowany ZIP na Moodle.
''''
```
