# Plan kursu: LLM w analizie tekstu dla profesjonalistów informacji
## Dokument organizacyjny + prompt wdrożeniowy dla Claude Code

---

## 1. ARCHITEKTURA PLIKÓW

```
kurs_llm/
│
├── R/                                  # ← CAŁA MECHANIKA (ukryta przed studentami)
│   ├── 00_setup.R                      # instalacja pakietów, ładowanie Ollama, test modeli
│   ├── 01_modele.R                     # wrappery: zapytaj(), klasyfikuj(), wyciagnij()
│   ├── 02_dane.R                       # ładowanie korpusów, fragmentacja, samplowanie
│   ├── 03_wizualizacje.R              # heatmapy, confusion matrix, wykresy zgodności
│   ├── 04_walidacja.R                 # kappa, alpha, F1, macierz pomyłek, test-retest
│   ├── 05_symulacja_respondenci.R     # skrypt prowadzącego: 200 respondentów via LLM
│   └── 06_eksport.R                   # zapis RDS/CSV, ładne tabele (gt/kableExtra)
│
├── dane/                               # ← KORPUSY TEKSTOWE
│   ├── korpus_polityczny.rds          # SOTU fragmenty EN
│   ├── korpus_naukowy.rds             # abstrakty arXiv/PubMed EN
│   ├── korpus_faktograficzny.rds      # Wikipedia / encyklopedyczne
│   ├── respondenci_200.csv            # ← wygenerowane przez prowadzącego przed S06
│   └── zloty_standard/                # podkatalogi per spotkanie
│
├── wyniki/                             # ← ZAPISYWANE W TRAKCIE ZAJĘĆ
│   ├── s01/ ... s07/
│
├── S01_generowanie.Rmd                # Spotkanie 1
├── S02_sentyment.Rmd                  # Spotkanie 2
├── S03_ekstrakcja.Rmd                 # Spotkanie 3
├── S04_analiza_dyskursu.Rmd           # Spotkanie 4
├── S05_porownanie_modeli.Rmd          # Spotkanie 5
├── S06_walidacja.Rmd                  # Spotkanie 6
├── S07_projekt_koncowy.Rmd            # Spotkanie 7
│
└── README.md                           # instrukcja uruchomienia
```

### Zasada naczelna: plik .Rmd zawiera TYLKO

1. `source("R/00_setup.R")` (raz, na początku)
2. Tekst instrukcji po polsku
3. Szablon frameworka do wypełnienia
4. `moj_prompt <- "..."` — jedyne co student pisze
5. Wywołanie gotowej funkcji, np. `klasyfikuj_zbior(korpus, moj_prompt, etykiety, n = 15)`
6. Pytania do refleksji
7. Blok `moja_interpretacja <- "..."` — akapit z własnym wnioskowaniem

---

## 2. MODELE — STOS OLLAMA (3 RODZINY)

Kurs używa modeli z **trzech rodzin**: Qwen3 (wielojęzyczny, Alibaba), Bielik (natywnie polski, SpeakLeash) i phi4 (Microsoft). Dywersyfikacja pozwala porównywać architektury i uniknąć problemu zawodności Bielika na tekstach angielskich.

### Zasada doboru modelu do korpusu

- **Korpus angielski** (SOTU, abstracts EN, Britannica) → **Qwen3 4B**
- **Korpus polski** (exposé, abstrakty PL, respondenci) → **Bielik 4.5B**
- **Porównanie międzymodelowe** (S05) → wszystkie 4 modele
- **Demo ograniczeń** (S01) → **Qwen3 0.6B** (523 MB — widocznie zły)
- **Symulacja respondentów** (prowadzący) → **Qwen3 8B** (thinking mode)

### Tabela modeli

| Rola | Model | Rodzina | Ollama pull | RAM (Q4) |
|------|-------|---------|-------------|----------|
| **Demo ograniczeń** | Qwen3 0.6B | Qwen (Alibaba) | `ollama pull qwen3:0.6b` | 523 MB |
| **Główny roboczy PL** | Bielik 4.5B v3 Instruct | Bielik (SpeakLeash) | `ollama pull SpeakLeash/bielik-4.5b-v3.0-instruct` | ~3 GB |
| **Główny roboczy EN+PL** | Qwen3 4B | Qwen (Alibaba) | `ollama pull qwen3:4b` | 2.5 GB |
| **Porównanie wielojęzyczne** | phi4-mini | Phi (Microsoft) | `ollama pull phi4-mini` | ~2.5 GB |
| **Symulacja respondentów** | Qwen3 8B | Qwen (Alibaba) | `ollama pull qwen3:8b` | 5.2 GB |

### Uzasadnienie wyboru

**Qwen3 0.6B** (zamiast Bielik 1.5B) — przy 523 MB jest uczciwie zły. Bielik 1.5B jest "za dobry" na demo ograniczeń, a za słaby na realne zadania. Qwen3 0.6B obsługuje 119 języków, ale jakość jest widocznie niska — idealne do lekcji "co się psuje z małym modelem".

**Bielik 4.5B** — natywny polski model, najlepszy stosunek PL-jakość/rozmiar. Na Open PL LLM Leaderboard: 56.13 (lepiej niż Qwen2.5-7B-Instruct: 54.93). Niezbędny do polskich korpusów.

**Qwen3 4B** — na korpusach angielskich znacząco lepszy od Bielika. Dorównuje Qwen2.5-72B-Instruct. Ma natywny tryb thinking/non-thinking (/think, /no_think) — otwiera unikalne ćwiczenie w S05. 119 języków, 256K kontekstu.

**phi4-mini** (3.8B) — trzeci punkt porównawczy z innej rodziny. Pozwala odpowiedzieć: "Czy rodzina modelu ma znaczenie?"

**Qwen3 8B** (zamiast Bielik 11B) — symulacja respondentów. Dorównuje Qwen2.5-14B przy niższym RAM. Tryb thinking przydatny przy generowaniu zróżnicowanych polskich odpowiedzi.

### Aliasy w 00_setup.R

```r
MODELE <- list(
  "qwen3-0.6b"  = "qwen3:0.6b",
  "bielik-4.5b"  = "SpeakLeash/bielik-4.5b-v3.0-instruct",
  "qwen3-4b"     = "qwen3:4b",
  "phi4-mini"    = "phi4-mini",
  "qwen3-8b"     = "qwen3:8b"
)
options(kurs_model_pl = MODELE[["bielik-4.5b"]])
options(kurs_model_en = MODELE[["qwen3-4b"]])
options(kurs_model_demo = MODELE[["qwen3-0.6b"]])
```

### Auto-dobór modelu w 01_modele.R

Gdy `model = "auto"`, skrypt sprawdza kolumnę `jezyk` w korpusie:
- `jezyk == "pl"` → bielik-4.5b
- `jezyk == "en"` → qwen3-4b
- brak kolumny → bielik-4.5b (fallback)

---

## 3. KORPUSY TEKSTOWE

### A. Korpus polityczny (S01, S02, S04) — angielski
- **Źródło**: pakiet `sotu` (State of the Union)
- **Model domyślny**: qwen3-4b
- **Uzupełnienie PL**: exposé premierów RP (CSV, Wikisource/Sejm.gov.pl) → bielik-4.5b
- **Fragmentacja**: okna 15 zdań, krok 7, min 1200 znaków

### B. Korpus naukowy (S02, S03, S05)
- **Opcja EN**: gutenbergr (Darwin, Mill) lub abstrakty arXiv → qwen3-4b
- **Opcja PL**: abstrakty z Repozytorium UJ (CSV) → bielik-4.5b
- **Fragmentacja**: pełne abstrakty (300-1500 znaków)

### C. Korpus faktograficzny (S03, S04)
- **Opcja EN**: gutenbergr (Britannica) → qwen3-4b
- **Opcja PL**: Wikipedia offline → bielik-4.5b
- **Fragmentacja**: akapity, 500-2000 znaków

### D. Dane respondentów (S06, S07) — polski
- **Generowanie**: qwen3-8b (prowadzący, thinking=TRUE, temp=0.9)
- **Analiza przez studentów**: bielik-4.5b
- **Format**: CSV, 200 wierszy × (3 pytania otwarte + metryki)

---

## 4. PLAN 7 SPOTKAŃ

### Matryca: model × spotkanie

| Spotkanie | Główny model | Dodatkowe modele | Korpus (język) |
|-----------|-------------|------------------|----------------|
| S01 | bielik-4.5b | **qwen3-0.6b** (demo) | brak (generowanie PL) |
| S02 | qwen3-4b (EN) | — | polityczny EN + naukowy EN |
| S03 | qwen3-4b (EN) | bielik-4.5b (PL opcja) | faktograficzny + naukowy |
| S04 | qwen3-4b (EN) | — | polityczny EN + naukowy EN |
| S05 | **wszystkie 4** | qwen3-4b /think vs /no_think | polityczny + naukowy |
| S06 | bielik-4.5b (PL), qwen3-4b (EN) | syuzhet (triangulacja) | wyniki S02-S05 + respondenci |
| S07 | bielik-4.5b | — | respondenci PL |

---

### S01: Generowanie tekstu i pierwsze prompty
**Temat**: Co to jest prompt? Jak model generuje tekst? Pierwsze eksperymenty.
**Korpus**: Żaden — studenci generują tekst od zera (po polsku).
**Modele**: bielik-4.5b (główny PL) + qwen3-0.6b (demo ograniczeń)

| # | Zadanie | Model | Typ | Student pisze |
|---|---------|-------|-----|---------------|
| 1 | Wygeneruj opis biblioteki przyszłości (200 słów) | bielik-4.5b | generowanie | prompt PL |
| 2 | Wygeneruj ten sam opis, ale zmień jeden element promptu | bielik-4.5b | generowanie | prompt PL (wariant) |
| 3 | Wygeneruj streszczenie naukowe na podany temat | bielik-4.5b | generowanie | prompt PL |
| 4 | Ten sam prompt na qwen3-0.6b — co się psuje? | **qwen3-0.6b** | porównanie | komentarz PL |
| 5 | Napisz prompt "zły" (bez struktury) i "dobry" (z RTF) — porównaj | bielik-4.5b | refleksja | 2 prompty + akapit |

**Frameworki**: RTF (intro), zero-shot vs instrukcja
**Blok refleksji**: "Co różni dobry prompt od złego? Jak rozmiar modelu wpłynął na wynik?"

**Funkcje z source()**: generuj(), porownaj_modele(), pokaz_porownanie()

---

### S02: Analiza sentymentu i emocji
**Temat**: Klasyfikacja tekstu — sentyment, emocje polityczne, emocje naukowe.
**Korpus**: polityczny EN + naukowy EN
**Modele**: qwen3-4b

| # | Zadanie | Model | Framework | Student pisze |
|---|---------|-------|-----------|---------------|
| 1 | Sentyment (pozytywny/negatywny/neutralny) na SOTU | qwen3-4b | RTF | prompt PL |
| 2 | Emocje polityczne (nadzieja/strach/duma/gniew/solidarność/determinacja/neutralne) | qwen3-4b | CO-STAR | prompt PL |
| 3 | Emocje naukowe (pewność/wątpliwość/entuzjazm/ostrożność/neutralne) | qwen3-4b | CO-STAR | prompt PL |
| 4 | Porównanie: ten sam fragment, dwa frameworki (RTF vs CO-STAR) | qwen3-4b | porównanie | 2 prompty + akapit |

**Frameworki**: RTF, CO-STAR, zero-shot
**Blok refleksji**: "Czy emocje 'naukowe' są trudniejsze niż 'polityczne'? Dlaczego?"

**Funkcje z source()**: klasyfikuj_sentyment(), klasyfikuj_emocje(), pokaz_rozklad(), porownaj_frameworki()

---

### S03: Ekstrakcja informacji
**Temat**: Wyciąganie strukturyzowanych danych z tekstu.
**Korpus**: faktograficzny EN + naukowy EN
**Modele**: qwen3-4b

| # | Zadanie | Model | Framework | Student pisze |
|---|---------|-------|-----------|---------------|
| 1 | Ekstrakcja podmiotów politycznych z SOTU | qwen3-4b | AUTOMAT | prompt PL |
| 2 | Ekstrakcja terminów naukowych z abstracts | qwen3-4b | AUTOMAT | prompt PL |
| 3 | Streszczenie: TEMAT / METODA / WYNIK (z abstracts) | qwen3-4b | RISEN | prompt PL |
| 4 | Ekstrakcja dat i wydarzeń z tekstu faktograficznego | qwen3-4b | AUTOMAT | prompt PL |
| 5 | Porównanie AUTOMAT vs RISEN | qwen3-4b | porównanie | 2 prompty + akapit |

**Frameworki**: AUTOMAT, RISEN
**Blok refleksji**: "'Atypical cases' z AUTOMAT — czy miał znaczenie?"

**Funkcje z source()**: wyciagnij_podmioty(), wyciagnij_strukture(), pokaz_siec_podmiotow(), pokaz_chmure_terminow()

---

### S04: Analiza dyskursu i tonu
**Temat**: Ton retoryczny, techniki perswazji, ramowanie (framing).
**Korpus**: polityczny EN (główny) + naukowy EN (kontrast)
**Modele**: qwen3-4b

| # | Zadanie | Model | Framework | Student pisze |
|---|---------|-------|-----------|---------------|
| 1 | Ton retoryczny (inspiracyjny/pojednawczy/konfrontacyjny/informacyjny/defensywny) | qwen3-4b | CRISPE | prompt PL |
| 2 | Strategia perswazji (apel do strachu/dumy/jedności/rozumu/brak) | qwen3-4b | Few-shot | prompt PL + 4 przykłady |
| 3 | Wykrywanie technik propagandowych | qwen3-4b | Chain-of-Thought | prompt PL |
| 4 | Ramowanie: "bohater vs antagonista" (jednoczący/polaryzujący/opisowy) | qwen3-4b | RISEN | prompt PL |

**Frameworki**: CRISPE, Few-shot, Chain-of-Thought, RISEN
**Blok refleksji**: "Czy CoT poprawiło wykrywanie propagandy? Przeanalizuj 2 przykłady."

**Funkcje z source()**: klasyfikuj_ton(), klasyfikuj_fewshot(), analizuj_cot(), pokaz_heatmapa_tonazyku()

---

### S05: Porównanie modeli i frameworków
**Temat**: Systematyczne porównanie — model × framework × korpus × thinking mode.
**Korpus**: polityczny EN + naukowy EN
**Modele**: qwen3-0.6b, bielik-4.5b, qwen3-4b, phi4-mini

| # | Zadanie | Modele | Student pisze |
|---|---------|--------|---------------|
| 1 | Jeden prompt × **4 modele** × korpus polityczny | qwen3-0.6b, bielik-4.5b, qwen3-4b, phi4-mini | 1 prompt PL |
| 2 | Jeden prompt × 1 model × **2 korpusy** | qwen3-4b | 1 prompt PL |
| 3 | **3 frameworki** (RTF, CO-STAR, AUTOMAT) × 1 model × 1 korpus | qwen3-4b | 3 prompty PL |
| 4 | **Thinking vs non-thinking**: /think i /no_think na qwen3-4b | qwen3-4b | 1 prompt PL + akapit |
| 5 | Zestawienie tabelaryczne: model × framework × korpus × thinking | --- (automatyczne) | --- |
| 6 | Akapit: "Który czynnik ma największy wpływ?" | --- | akapit PL |

**Nowe ćwiczenie (zad. 4): Tryb thinking Qwen3**
Student pisze JEDEN prompt i uruchamia go dwukrotnie — raz z /think, raz z /no_think.
Porównuje: trafność, czas, stabilność. Model generuje blok <think>...</think> przed odpowiedzią.

**Frameworki**: RTF, CO-STAR, AUTOMAT
**Blok refleksji**: "Napisz 5-8 zdań. Który czynnik był najważniejszy?"

**Funkcje z source()**: eksperyment_pelny(), porownaj_thinking(), pokaz_macierz_eksperymentu(), pokaz_thinking_vs_not()

---

### S06: Walidacja — czy to działa?
**Temat**: Złoty standard, test-retest, kappa, alpha, F1, analiza błędów, triangulacja.
**Korpus**: wyniki z S02-S05 + respondenci_200.csv (PL)
**Modele**: bielik-4.5b (PL), qwen3-4b (EN), syuzhet (leksykon)

**UWAGA**: Prowadzący uruchamia `05_symulacja_respondenci.R` przed tym spotkaniem.

| # | Zadanie | Model | Student pisze |
|---|---------|-------|---------------|
| 1 | Złoty standard (20 fragmentów ręcznie) | — (praca ludzka) | 20 etykiet + codebook |
| 2 | Test-retest × 3 uruchomienia | qwen3-4b lub bielik-4.5b | prompt PL (z S02) |
| 3 | Macierz pomyłek + accuracy + F1 | --- (automatyczne) | --- |
| 4 | Cohen's kappa: dwa frameworki z S05 | --- (automatyczne) | --- |
| 5 | Krippendorff's alpha: 3 klasyfikatory | --- (automatyczne) | --- |
| 6 | Analiza błędów: typologia 5 pomyłek | --- | 5 kategorii |
| 7 | Triangulacja: LLM vs syuzhet | qwen3-4b + syuzhet | --- + akapit |

**Blok refleksji**: "Akapit metodologiczny: czy klasyfikacje z S02-S05 były wiarygodne?"

**Funkcje z source()**: stworz_zloty_standard(), test_retest(), policz_metryki(), policz_kappa(), policz_alpha(), analizuj_bledy(), trianguluj(), pokaz_piramide_walidacji()

---

### S07: Analiza danych respondentów — projekt końcowy
**Temat**: Pełny pipeline na danych ankietowych.
**Korpus**: respondenci_200.csv (PL)
**Modele**: bielik-4.5b

| # | Zadanie | Model | Student pisze |
|---|---------|-------|---------------|
| 1 | Eksploracja danych | --- (automatyczne) | --- |
| 2 | Klasyfikacja Pytanie 1 — sentyment | bielik-4.5b | prompt PL (CO-STAR) |
| 3 | Klasyfikacja Pytanie 2 — emocje | bielik-4.5b | prompt PL (AUTOMAT) |
| 4 | Ekstrakcja tematów z Pytania 3 | bielik-4.5b | prompt PL (RISEN) |
| 5 | Walidacja: test-retest + złoty standard (5 odp.) | bielik-4.5b | 5 etykiet + prompt |
| 6 | Analiza krzyżowa: sentyment × demografika | --- (automatyczne) | --- |
| 7 | **Mini-raport**: wstęp, metoda, wyniki, wnioski | --- | tekst PL (~400 słów) |

**Blok refleksji = mini-raport**: student pisze pełne podsumowanie.

**Funkcje z source()**: wczytaj_respondentow(), pokaz_eksploracje(), klasyfikuj_odpowiedzi(), wyciagnij_tematy(), analiza_krzyzowa(), pokaz_podsumowanie_projektu()

---

## 5. SKRYPTY SOURCE — SPECYFIKACJA

### 00_setup.R
```
- install.packages() z tryCatch (tylko brakujące)
- library() — tidyverse, rollama, glue, gt, kableExtra, igraph, 
  wordcloud2, syuzhet, irr, yardstick, sotu, gutenbergr, cli
- Test Ollama (ping)
- Pull modeli (priorytet): qwen3:4b, bielik-4.5b, qwen3:0.6b, phi4-mini, (opcja: qwen3:8b)
- Ustawienie aliasów i domyślnych modeli
- source() reszty skryptów
- Komunikat: "✅ Środowisko gotowe. Modele: [lista]."
```

### 01_modele.R
```
zapytaj(prompt, model = "auto", temperature = 0.3, thinking = NULL)
  → auto-dobór modelu na podstawie języka korpusu
  → obsługa Qwen3 thinking: /think, /no_think, parsowanie <think>...</think>
  → rollama::query() z retry 2x, timeout 60s
  → zwraca list(odpowiedz, myslenie, czas, model)

klasyfikuj(tekst, prompt_szablon, etykiety, model, ...)
klasyfikuj_zbior(korpus, prompt_szablon, etykiety, model="auto", n=15, thinking=NULL)
  → cli::cli_progress_bar, polskie komunikaty
wyciagnij(tekst, prompt_szablon, model="auto")
generuj(prompt, model="auto", max_tokens=500)
porownaj_modele(prompt, modele, tekst=NULL)
porownaj_thinking(korpus, prompt, etykiety, model="qwen3-4b", n=10)
  → klasyfikuj z thinking=TRUE i FALSE, porównaj wyniki + czas
```

### 02_dane.R
```
wczytaj_korpus_polityczny(n=80, ...) → dodaje jezyk="en"
wczytaj_korpus_naukowy(sciezka) → dodaje jezyk (auto-detect)
wczytaj_korpus_faktograficzny(sciezka)
przygotuj_fragmenty(tekst_wektor, okno, krok, min, max, n)
wczytaj_respondentow(sciezka) → dodaje jezyk="pl"
```

### 03_wizualizacje.R
```
PALETA: pozytywny=#4CAF50, negatywny=#F44336, neutralny=#9E9E9E, akcentA=#2196F3, akcentB=#FF9800
pokaz_rozklad(), pokaz_porownanie(), pokaz_porownanie_modeli()
pokaz_confusion_matrix(), pokaz_heatmapa_zgodnosci(), pokaz_triangulacje()
pokaz_tabele(), pokaz_siec_podmiotow(), pokaz_chmure()
pokaz_piramide_walidacji(), pokaz_thinking_vs_not()
```

### 04_walidacja.R
```
test_retest(), policz_metryki(), policz_kappa(), policz_alpha()
analizuj_bledy(), trianguluj(), porownaj_frameworki_walidacja()
```

### 05_symulacja_respondenci.R (SKRYPT PROWADZĄCEGO)
```
Model: qwen3-8b (domyślnie; alt: bielik-4.5b)
n_respondentow: 200, temperature: 0.9, thinking: TRUE
Kolumny: id, wiek, plec, staz_pracy_lat, typ_instytucji, stanowisko,
  pyt1_korzysci_ai, pyt2_obawy_ai, pyt3_przyszlosc, pyt1/2/3_dlugosc
Szum: 5% krótkie, 3% wymijające, 10% entuzjastyczne, 10% sceptyczne
Persona prompt z demografią. Zapis CSV UTF-8.
```

### 06_eksport.R
```
zapisz_wyniki(), zapisz_csv(), pokaz_podsumowanie_spotkania()
```

---

## 6. STRUKTURA .Rmd — SZABLON

(Identyczna jak w v1 — source() + prompt + funkcja + refleksja)

---

## 7. PROMPT DLA CLAUDE CODE

```
Zreorganizuj kurs LLM dla bibliotekarzy. Potrzebuję 7 plików .Rmd (spotkania S01-S07) 
i 7 skryptów R w katalogu R/. Pełny plan jest w pliku PLAN_KURSU.md — przeczytaj go 
i zaimplementuj krok po kroku.

ARCHITEKTURA:
- R/00_setup.R — instalacja/ładowanie pakietów, test Ollama, pull modeli, source() reszty
- R/01_modele.R — wrappery: zapytaj(), klasyfikuj(), klasyfikuj_zbior(), wyciagnij(), generuj(),
  porownaj_modele(), porownaj_thinking(). Auto-dobór modelu wg języka korpusu.
  Obsługa Qwen3 thinking mode (/think, /no_think, parsowanie <think> bloków).
- R/02_dane.R — ładowanie korpusów z kolumną jezyk
- R/03_wizualizacje.R — wszystkie pokaz_*() funkcje, spójna PALETA, pokaz_thinking_vs_not()
- R/04_walidacja.R — test_retest(), policz_metryki/kappa/alpha(), analizuj_bledy(), trianguluj()
- R/05_symulacja_respondenci.R — 200 respondentów via qwen3-8b, thinking=TRUE, temp=0.9
- R/06_eksport.R — zapisz_wyniki(), zapisz_csv()

MODELE (3 RODZINY):
- Demo: qwen3:0.6b (alias "qwen3-0.6b")
- Główny PL: SpeakLeash/bielik-4.5b-v3.0-instruct (alias "bielik-4.5b")
- Główny EN+PL: qwen3:4b (alias "qwen3-4b") — thinking mode
- Porównanie: phi4-mini
- Symulacja: qwen3:8b (alias "qwen3-8b") — tylko prowadzący
Domyślne: kurs_model_pl=bielik-4.5b, kurs_model_en=qwen3-4b, kurs_model_demo=qwen3-0.6b.
Gdy model="auto", dobieraj wg kolumny jezyk w korpusie.

ZASADY:
1. .Rmd KRÓTKIE: source() + prompt + wywołanie funkcji + refleksja. Zero dodatkowego kodu R.
2. Prompty po POLSKU. Etykiety po polsku.
3. Każde spotkanie S02-S07 używa 3 frameworków: RTF, CO-STAR, AUTOMAT, CRISPE, RISEN, Few-shot, CoT.
4. Każde zadanie kończy się: moja_interpretacja_zadX <- "[KOMENTARZ]"
5. Polskie komunikaty w konsoli, cli::cli_progress_bar, tryCatch.
6. ggplot2 + gt/kableExtra. PALETA z 03_wizualizacje.R. theme_minimal(). Tytuły PL.
7. W S05: porownaj_thinking() — qwen3-4b z /think i /no_think, parsowanie <think>.
8. 05_symulacja: qwen3-8b, 200 respondentów, persona prompt, temp=0.9, thinking=TRUE.

KOLEJNOŚĆ:
1. R/00_setup.R + R/01_modele.R (fundamenty + thinking)
2. R/02_dane.R + R/03_wizualizacje.R
3. R/04_walidacja.R
4. S01 + S02 (testowanie)
5. S03-S05
6. R/05_symulacja + S06-S07
7. README.md

Przeczytaj PLAN_KURSU.md, zacznij od kroku 1. Pokaż co zrobiłeś, czekaj na OK.
```

---

## 8. MINIMALNE WYMAGANIA SPRZĘTOWE

- **Student (8 GB RAM)**: bielik-4.5b (3 GB) + qwen3-0.6b (0.5 GB) = 3.5 GB + system
- **Student (16 GB RAM)**: bielik-4.5b + qwen3-4b + phi4-mini rotacyjnie
- **Prowadzący (16 GB RAM)**: qwen3-8b (5.2 GB) + wolne na system

---

## 9. OTWARTE DECYZJE DLA PROWADZĄCEGO

1. **Korpus naukowy** — arXiv EN (łatwiej) czy Repozytorium UJ PL (bliżej)?
   → Sugestia: oba jako RDS; EN w S02-S03, porównanie EN vs PL w S05.

2. **Korpus faktograficzny** — Britannica EN (gutenbergr) czy Wikipedia PL (offline)?
   → Sugestia: Wikipedia offline (prowadzący pobiera 100 artykułów raz).

3. **S07 indywidualny czy grupowy?** → Indywidualny, peer review mini-raportu w parach.

4. **Etykiety PL czy EN?** → Plan: polskie. Qwen3 może wolieć angielskie na EN korpusie.
   Reguła: "etykiety w języku promptu". Przetestować przed kursem.

5. **200 respondentów wystarczy?** → Tak. Opcja: 300 dla subgrupowych analiz w S07.

6. **Qwen3 thinking — konfiguracja?** → Ollama v0.9.0+ natywne wsparcie. /think i /no_think
   w treści promptu. Bloki <think> parsowane w 01_modele.R.

# Stary Plan nowego dla kontekstu kursu: LLM w analizie tekstu dla profesjonalistów informacji
## Dokument organizacyjny + prompt wdrożeniowy dla Claude Code

---

## 1. ARCHITEKTURA PLIKÓW

```
kurs_llm/
│
├── R/                                  # ← CAŁA MECHANIKA (ukryta przed studentami)
│   ├── 00_setup.R                      # instalacja pakietów, ładowanie Ollama, test modeli
│   ├── 01_modele.R                     # wrappery: zapytaj(), klasyfikuj(), wyciagnij()
│   ├── 02_dane.R                       # ładowanie korpusów, fragmentacja, samplowanie
│   ├── 03_wizualizacje.R              # heatmapy, confusion matrix, wykresy zgodności
│   ├── 04_walidacja.R                 # kappa, alpha, F1, macierz pomyłek, test-retest
│   ├── 05_symulacja_respondenci.R     # skrypt prowadzącego: 200 respondentów via LLM
│   └── 06_eksport.R                   # zapis RDS/CSV, ładne tabele (gt/kableExtra)
│
├── dane/                               # ← KORPUSY TEKSTOWE (gotowe, nie generowane przez studentów)
│   ├── korpus_polityczny.rds          # SOTU fragmenty (z source 02)
│   ├── korpus_naukowy.rds             # abstrakty arXiv/PubMed (z source 02)
│   ├── korpus_faktograficzny.rds      # Wikipedia / encyklopedyczne (z source 02)
│   ├── respondenci_200.csv            # ← wygenerowane przez prowadzącego przed S6
│   └── zloty_standard/                # podkatalogi per spotkanie
│
├── wyniki/                             # ← ZAPISYWANE W TRAKCIE ZAJĘĆ
│   ├── s01/ ... s07/
│
├── S01_generowanie.Rmd                # Spotkanie 1
├── S02_sentyment.Rmd                  # Spotkanie 2
├── S03_ekstrakcja.Rmd                 # Spotkanie 3
├── S04_analiza_dyskursu.Rmd           # Spotkanie 4
├── S05_porownanie_modeli.Rmd          # Spotkanie 5
├── S06_walidacja.Rmd                  # Spotkanie 6
├── S07_projekt_koncowy.Rmd            # Spotkanie 7
│
└── README.md                           # instrukcja uruchomienia
```

### Zasada naczelna: plik .Rmd zawiera TYLKO

1. `source("R/00_setup.R")` (raz, na początku)
2. Tekst instrukcji po polsku
3. Szablon frameworka do wypełnienia
4. `moj_prompt <- "..."` — jedyne co student pisze
5. Wywołanie gotowej funkcji, np. `pokaz_sentyment(korpus, moj_prompt, model = "bielik-4.5b")`
6. Pytania do refleksji
7. Blok `moja_interpretacja <- "..."` — akapit z własnym wnioskowaniem

### Co student NIGDY nie widzi
- Kod rollama/ollama, parsowanie JSON, glue, purrr::map
- Logikę normalizacji odpowiedzi (str_detect itd.)
- Parametry wizualizacji (ggplot, gt, heatmap)
- Obsługę błędów sieciowych / timeoutów

---

## 2. MODELE — STOS OLLAMA

| Model | Ollama ID | Rozmiar | Rola w kursie |
|-------|-----------|---------|---------------|
| Bielik 1.5B | `SpeakLeash/bielik-1.5b-v3.0-instruct` | 1.5B | Demo ograniczeń małego modelu |
| Bielik 4.5B | `SpeakLeash/bielik-4.5b-v3.0-instruct` | 4.5B | **Główny model roboczy** (najlepszy stosunek PL-jakość/rozmiar) |
| Bielik Minitron 7B | `SpeakLeash/bielik-minitron-7b-v3.0-instruct` | 7B | Porównanie z 4.5B |
| Bielik 11B | `SpeakLeash/bielik-11b-v3.0-instruct` | 11B | "Złoty standard" LLM; opcjonalny |
| phi4-mini | `phi4-mini` | 3.8B | Porównanie: model wielojęzyczny vs natywnie polski |

Domyślny model we wszystkich funkcjach: `bielik-4.5b` (alias ustawiony w 00_setup.R).
Porównanie modeli w S05 — studenci uruchamiają ten sam prompt na 3 modelach.

---

## 3. KORPUSY TEKSTOWE

### A. Korpus polityczny (S01, S02, S04)
- **Źródło**: pakiet `sotu` (State of the Union) — angielski
- **Uzupełnienie polskie**: fragmenty exposé premierów RP (dostarczane jako CSV przez prowadzącego,
  tekst z Wikisource/Sejm.gov.pl — domaine publique)
- **Fragmentacja**: okna 15 zdań, krok 7, min 1200 znaków

### B. Korpus naukowy/akademicki (S02, S03, S05)
- **Źródło opcja 1**: pakiet `gutenbergr` → Darwin "On the Origin of Species",
  Mill "On Liberty" (public domain, angielski, naukowy rejestr)
- **Źródło opcja 2**: abstrakty z arXiv (prowadzący pobiera 200 abstracts z cs.DL
  lub cs.CL przez API i zapisuje jako dane/korpus_naukowy.rds)
- **Źródło opcja 3 (polski)**: abstrakty polskich artykułów z Repozytorium UJ
  (prowadzący pobiera ręcznie 100-150 abstracts i zapisuje jako CSV)
- **Fragmentacja**: pełne abstrakty (300-1500 znaków), bez okien

### C. Korpus faktograficzny (S03, S04)
- **Źródło**: pakiet `gutenbergr` → encyklopedia Britannica (stare edycje, public domain)
- **Alternatywa**: Wikipedia API (polskie artykuły), pobrane offline przez prowadzącego
- **Fragmentacja**: akapity, 500-2000 znaków

### D. Dane respondentów (S06, S07)
- **Źródło**: wygenerowane przez skrypt prowadzącego (05_symulacja_respondenci.R)
- **Format**: CSV, 200 wierszy × (3 pytania otwarte + metryki)
- **Szczegóły**: patrz sekcja 6

---

## 4. PLAN 7 SPOTKAŃ

---

### S01: Generowanie tekstu i pierwsze prompty
**Temat**: Co to jest prompt? Jak model generuje tekst? Pierwsze eksperymenty.
**Korpus**: Żaden gotowy — studenci generują tekst od zera.
**Modele**: bielik-4.5b (główny) + bielik-1.5b (porównanie)

| # | Zadanie | Typ | Student pisze |
|---|---------|-----|---------------|
| 1 | Wygeneruj opis biblioteki przyszłości (200 słów) | generowanie | prompt PL |
| 2 | Wygeneruj ten sam opis, ale zmień jeden element promptu | generowanie | prompt PL (wariant) |
| 3 | Wygeneruj streszczenie naukowe na podany temat | generowanie | prompt PL |
| 4 | Porównaj wynik bielik-1.5b vs bielik-4.5b na tym samym prompcie | porównanie | komentarz PL |
| 5 | Napisz prompt typu "zły" (bez struktury) i "dobry" (z RTF) — porównaj | refleksja | 2 prompty + akapit |

**Frameworki**: RTF (intro), zero-shot vs instrukcja
**Blok refleksji**: "Co różni dobry prompt od złego? Napisz 3-4 zdania."

**Funkcje z source()**:
- `generuj(prompt, model)` → zwraca tekst + czas + liczba tokenów
- `porownaj_modele(prompt, modele = c("bielik-4.5b", "bielik-1.5b"))` → tabela porównawcza
- `pokaz_porownanie(wynik)` → wizualizacja side-by-side

---

### S02: Analiza sentymentu i emocji
**Temat**: Klasyfikacja tekstu — sentyment, emocje polityczne, emocje naukowe
**Korpus**: polityczny + naukowy (mix)
**Modele**: bielik-4.5b

| # | Zadanie | Framework | Student pisze |
|---|---------|-----------|---------------|
| 1 | Sentyment (pos/neg/neu) na korpusie politycznym | RTF | prompt PL |
| 2 | Emocje polityczne (nadzieja/strach/duma/gniew/solidarność/determinacja/neutralne) | CO-STAR | prompt PL |
| 3 | Emocje naukowe (pewność/wątpliwość/entuzjazm/ostrożność/neutralne) | CO-STAR | prompt PL |
| 4 | Porównanie: ten sam fragment, dwa frameworki (RTF vs CO-STAR) | porównanie | 2 prompty + akapit |

**Frameworki**: RTF, CO-STAR, zero-shot
**Blok refleksji**: "Czy emocje 'naukowe' są trudniejsze niż 'polityczne'? Dlaczego?"

**Funkcje z source()**:
- `klasyfikuj_sentyment(korpus, prompt, model, n = 15)` → tabela z wynikami + rozkład
- `klasyfikuj_emocje(korpus, prompt, etykiety, model, n = 15)` → jw. z walidacją etykiet
- `pokaz_rozklad(wyniki, tytul)` → wykres słupkowy rozkładu
- `porownaj_frameworki(korpus, lista_promptow, model, n = 10)` → macierz zgodności

---

### S03: Ekstrakcja informacji
**Temat**: Wyciąganie strukturyzowanych danych z tekstu — podmioty, fakty, relacje
**Korpus**: faktograficzny + naukowy
**Modele**: bielik-4.5b

| # | Zadanie | Framework | Student pisze |
|---|---------|-----------|---------------|
| 1 | Ekstrakcja podmiotów politycznych (państwa, org., osoby) | AUTOMAT | prompt PL |
| 2 | Ekstrakcja terminów naukowych z abstracts | AUTOMAT | prompt PL |
| 3 | Streszczenie w formacie: TEMAT / METODA / WYNIK (z abstracts) | RISEN | prompt PL |
| 4 | Ekstrakcja dat i wydarzeń z tekstu faktograficznego | AUTOMAT | prompt PL |
| 5 | Porównanie AUTOMAT vs RISEN na ekstrakcji | porównanie | 2 prompty + akapit |

**Frameworki**: AUTOMAT, RISEN
**Blok refleksji**: "Element 'Atypical cases' z AUTOMAT — czy miał znaczenie? Jak go użyłeś?"

**Funkcje z source()**:
- `wyciagnij_podmioty(korpus, prompt, model, n = 12)` → tabela z podmiotami
- `wyciagnij_strukture(korpus, prompt, model, n = 10)` → tabela wielopolowa (TEMAT/METODA/WYNIK)
- `pokaz_siec_podmiotow(wyniki)` → prosty graf współwystępowania (igraph)
- `pokaz_chmure_terminow(wyniki)` → wordcloud z wyekstrahowanych terminów

---

### S04: Analiza dyskursu i tonu
**Temat**: Ton retoryczny, techniki perswazji, ramowanie (framing)
**Korpus**: polityczny (główny) + naukowy (kontrast)
**Modele**: bielik-4.5b

| # | Zadanie | Framework | Student pisze |
|---|---------|-----------|---------------|
| 1 | Ton retoryczny (inspiracyjny/pojednawczy/konfrontacyjny/informacyjny/defensywny) | CRISPE | prompt PL |
| 2 | Strategia perswazji (apel do strachu/dumy/jedności/rozumu/brak) | Few-shot | prompt PL + 4 przykłady |
| 3 | Wykrywanie technik propagandowych (loaded language/fałszywy dylemat/bandwagon/autorytet/brak) | Chain-of-Thought | prompt PL |
| 4 | Ramowanie: "bohater vs antagonista" + klasyfikacja (jednoczący/polaryzujący/opisowy) | RISEN | prompt PL |

**Frameworki**: CRISPE, Few-shot, Chain-of-Thought, RISEN
**Blok refleksji**: "Czy CoT rzeczywiście poprawiło wykrywanie propagandy? Przeanalizuj 2 przykłady."

**Funkcje z source()**:
- `klasyfikuj_ton(korpus, prompt, etykiety, model, n = 12)` → tabela + rozkład
- `klasyfikuj_fewshot(korpus, prompt, etykiety, model, n = 12)` → jw.
- `analizuj_cot(korpus, prompt, etykiety, model, n = 8)` → tabela z rozumowaniem + etykietą
- `pokaz_heatmapa_tonazyku(wyniki_ton, wyniki_perswazja)` → heatmapa krzyżowa

---

### S05: Porównanie modeli i frameworków
**Temat**: Systematyczne porównanie — co zmienia model? co zmienia framework? co zmienia korpus?
**Korpus**: polityczny + naukowy (te same fragmenty na obu)
**Modele**: bielik-1.5b, bielik-4.5b, phi4-mini (opcja: bielik-7b)

| # | Zadanie | Student pisze |
|---|---------|---------------|
| 1 | Jeden prompt sentymentowy × 3 modele × 1 korpus polityczny | 1 prompt PL |
| 2 | Jeden prompt sentymentowy × 1 model × 2 korpusy (polityczny vs naukowy) | 1 prompt PL |
| 3 | Trzy frameworki (RTF, CO-STAR, AUTOMAT) × 1 model × 1 korpus | 3 prompty PL |
| 4 | Tabelaryczne zestawienie: model × framework × korpus | --- (automatyczne) |
| 5 | Akapit: "Który czynnik (model/framework/korpus) ma największy wpływ?" | akapit PL |

**Frameworki**: RTF, CO-STAR, AUTOMAT (zestawienie)
**Blok refleksji**: "Napisz 5-8 zdań podsumowujących, który czynnik był najważniejszy."

**Funkcje z source()**:
- `eksperyment_pelny(korpus_lista, prompt_lista, model_lista, etykiety, n = 10)` → duży data.frame
- `pokaz_macierz_eksperymentu(wynik)` → heatmapa 3D (model × framework × metryka)
- `pokaz_tabele_zbiorczą(wynik)` → gt/kableExtra z formatowaniem

---

### S06: Walidacja — czy to działa?
**Temat**: Złoty standard, test-retest, kappa, alpha, F1, analiza błędów, triangulacja
**Korpus**: wyniki z S02-S05 + respondenci_200.csv
**Modele**: bielik-4.5b (główny), syuzhet (leksykon — triangulacja)

**UWAGA**: Przed tym spotkaniem prowadzący uruchamia `05_symulacja_respondenci.R`
i generuje `dane/respondenci_200.csv`.

| # | Zadanie | Student pisze |
|---|---------|---------------|
| 1 | Tworzenie złotego standardu (kodowanie 20 fragmentów ręcznie) | 20 etykiet + codebook |
| 2 | Test-retest: ten sam prompt × 3 uruchomienia | prompt PL (z S02) |
| 3 | Macierz pomyłek + accuracy + F1 per klasa | --- (automatyczne) |
| 4 | Cohen's kappa: dwa frameworki z S05 | --- (automatyczne) |
| 5 | Krippendorff's alpha: 3 klasyfikatory jednocześnie | --- (automatyczne) |
| 6 | Analiza błędów: typologia 5 pomyłek | 5 kategorii błędów |
| 7 | Triangulacja: LLM vs leksykon (syuzhet) | --- (automatyczne) + akapit |

**Blok refleksji**: "Napisz akapit metodologiczny: czy Twoje klasyfikacje z S02-S05 były wiarygodne?"

**Funkcje z source()**:
- `stworz_zloty_standard(korpus, n = 20)` → interaktywne kodowanie
- `test_retest(korpus, prompt, model, k = 3, n = 15)` → tabela + Fleiss kappa
- `policz_metryki(predykcje, zloty_standard)` → accuracy, F1, confusion matrix
- `policz_kappa(rater_a, rater_b)` → Cohen's kappa + interpretacja
- `policz_alpha(macierz_raterow)` → Krippendorff alpha + interpretacja
- `analizuj_bledy(predykcje, zloty_standard, n = 5)` → wyświetla błędy do zakodowania
- `trianguluj(korpus, predykcje_llm, metoda_leksykon = "bing")` → heatmapa 3 metod
- `pokaz_piramide_walidacji(wyniki_walidacji)` → graficzne podsumowanie

---

### S07: Analiza danych respondentów — projekt końcowy
**Temat**: Pełny pipeline analityczny na danych ankietowych wygenerowanych przez LLM
**Korpus**: respondenci_200.csv (3 pytania otwarte + metryki)
**Modele**: bielik-4.5b

| # | Zadanie | Student pisze |
|---|---------|---------------|
| 1 | Eksploracja danych: rozkłady odpowiedzi, długość, metryki demograficzne | --- (automatyczne) |
| 2 | Klasyfikacja odpowiedzi na Pytanie 1 (sentyment) | prompt PL (CO-STAR) |
| 3 | Klasyfikacja odpowiedzi na Pytanie 2 (emocje) | prompt PL (AUTOMAT) |
| 4 | Ekstrakcja tematów z Pytania 3 (otwarte) | prompt PL (RISEN) |
| 5 | Walidacja: test-retest + złoty standard (5 odpowiedzi) | 5 etykiet + prompt |
| 6 | Analiza krzyżowa: sentyment × metryka demograficzna | --- (automatyczne) |
| 7 | **Mini-raport**: 1 strona podsumowania (wstęp, metoda, wyniki, wnioski) | tekst PL (~400 słów) |

**Blok refleksji = mini-raport**: student pisze pełne podsumowanie analizy.

**Funkcje z source()**:
- `wczytaj_respondentow(sciezka)` → czyści, opisuje dane
- `pokaz_eksploracje(dane)` → histogramy, rozkłady, tabela opisowa
- `klasyfikuj_odpowiedzi(dane, kolumna, prompt, etykiety, model)` → klasyfikacja + rozkład
- `wyciagnij_tematy(dane, kolumna, prompt, model, n_tematow = 8)` → lista tematów + przypisanie
- `analiza_krzyzowa(dane, kolumna_klasyfikacja, kolumna_metryka)` → tabela kontyngencji + chi²
- `pokaz_podsumowanie_projektu(wszystkie_wyniki)` → dashboard: 4 wykresy na jednej stronie

---

## 5. SKRYPTY SOURCE — SPECYFIKACJA

### 00_setup.R
```
Odpowiedzialność:
- install.packages() z tryCatch (tylko brakujące)
- library() — tidyverse, rollama, glue, gt, kableExtra, igraph, 
  wordcloud2, syuzhet, irr, yardstick, sotu, gutenbergr
- Test połączenia z Ollama (ping)
- Pobranie modeli jeśli brak:
  ollama pull SpeakLeash/bielik-4.5b-v3.0-instruct (+ aliasy)
- Ustawienie domyślnego modelu: options(kurs_model = "bielik-4.5b")
- source() reszty skryptów z R/
- Komunikat: "✅ Środowisko gotowe. Modele: [lista]. Czas: Xs."
```

### 01_modele.R
```
Kluczowe funkcje:

zapytaj(prompt, model = getOption("kurs_model"), temperature = 0.3)
  → rollama::query() z obsługą błędów, timeout, retry
  → zwraca czysty tekst (trimws)

klasyfikuj(tekst, prompt_szablon, etykiety, model, ...)
  → glue prompt + tekst
  → zapytaj()
  → normalizacja: str_detect po etykietach
  → zwraca etykietę lub "nierozpoznane"

klasyfikuj_zbior(korpus, prompt_szablon, etykiety, model, n, kolumna_tekst = "text")
  → purrr::map_chr po korpusie
  → progress bar (cli)
  → zwraca tibble z dołączoną kolumną klasyfikacji

wyciagnij(tekst, prompt_szablon, model)
  → jak klasyfikuj(), ale bez normalizacji etykiet
  → zwraca surowy tekst odpowiedzi

generuj(prompt, model, max_tokens = 500)
  → zapytaj() bez tekstu wejściowego
  → zwraca wygenerowany tekst
```

### 02_dane.R
```
Kluczowe funkcje:

wczytaj_korpus_polityczny(n = 80, dlugosc_min = 1200, okno = 15, krok = 7)
  → sotu_text → zdania → okna → filtr → sample → rds
  
wczytaj_korpus_naukowy(sciezka = "dane/korpus_naukowy.rds")
  → wczytuje gotowy RDS (przygotowany przez prowadzącego)
  → fallback: gutenbergr::gutenberg_download() + fragmentacja

wczytaj_korpus_faktograficzny(sciezka = "dane/korpus_faktograficzny.rds")
  → jw.

przygotuj_fragmenty(tekst_wektor, okno, krok, min_znakow, max_znakow, n)
  → generyczna fragmentacja sliding window

wczytaj_respondentow(sciezka = "dane/respondenci_200.csv")
  → read_csv z walidacją kolumn
```

### 03_wizualizacje.R
```
Kluczowe funkcje:

pokaz_rozklad(wyniki, kolumna_klasyfikacja, tytul = "")
  → ggplot: barplot z etykietami %

pokaz_porownanie(wyniki, kolumny, tytul = "")
  → ggplot: grouped barplot lub heatmapa

pokaz_confusion_matrix(predykcje, prawda, tytul = "")
  → yardstick::conf_mat() + autoplot(type = "heatmap")

pokaz_heatmapa_zgodnosci(macierz_porownawcza, tytul = "")
  → ggplot::geom_tile z annotacjami

pokaz_triangulacje(dane_3metod)
  → heatmapa: fragment × metoda, kolorowana etykietami

pokaz_tabele(dane, tytul = "")
  → gt::gt() z formatowaniem, kolorami, nagłówkami

pokaz_siec_podmiotow(wyniki_ekstrakcji)
  → igraph z prostym spring layout

pokaz_chmure(terminy)
  → wordcloud2 lub ggwordcloud

pokaz_piramide_walidacji(wyniki)
  → ggplot: piramida 3-warstwowa z metrykami
```

### 04_walidacja.R
```
Kluczowe funkcje:

test_retest(korpus, prompt, model, k = 3, n = 15, etykiety = NULL)
  → uruchamia klasyfikuj_zbior() k razy
  → liczy % pełnej zgodności + Fleiss kappa
  → zwraca tibble z k kolumnami + podsumowanie

policz_metryki(predykcje, prawda)
  → yardstick: accuracy, precision, recall, f_meas (macro + per class)
  → confusion matrix
  → zwraca listę

policz_kappa(rater_a, rater_b, wagi = "unweighted")
  → irr::kappa2() + interpretacja Landis & Koch

policz_alpha(macierz_raterow, metoda = "nominal")
  → irr::kripp.alpha() + interpretacja Krippendorff

analizuj_bledy(predykcje, prawda, teksty, n = 5)
  → filtruje pomyłki
  → wyświetla do ręcznej klasyfikacji typów błędów

trianguluj(korpus, predykcje_llm, metoda = "bing", zloty_standard = NULL)
  → syuzhet::get_sentiment() → kategoryzacja
  → porównanie 3 metod + Fleiss kappa
  → zwraca dane + wizualizację

porownaj_frameworki_walidacja(korpus, prompty_lista, model, etykiety, n = 12)
  → klasyfikuje jednym modelem z wieloma promptami
  → liczy kappa między parami
  → zwraca macierz zgodności
```

### 05_symulacja_respondenci.R (SKRYPT PROWADZĄCEGO)
```
# ════════════════════════════════════════════════════════
# Ten skrypt uruchamia PROWADZĄCY przed spotkaniem S06.
# Generuje dane 200 "respondentów" via LLM.
# ════════════════════════════════════════════════════════

Parametry:
- model: wybrany przez prowadzącego (domyślnie bielik-11b-v3.0)
- n_respondentow: 200
- temperature: 0.9 (wysoka, dla zróżnicowania)
- seed: ustawiany przed uruchomieniem

Struktura danych wyjściowych (respondenci_200.csv):
| Kolumna              | Typ       | Opis |
|----------------------|-----------|------|
| id                   | integer   | 1-200 |
| wiek                 | integer   | 22-65 (losowany z rozkładu) |
| plec                 | character | "K" / "M" / "I" |
| staz_pracy_lat       | integer   | 0-40 |
| typ_instytucji       | character | "biblioteka_akademicka" / "biblioteka_publiczna" / "archiwum" / "muzeum" |
| stanowisko           | character | "bibliotekarz" / "katalogujacy" / "kierownik" / "informatyk" / "inny" |
| pyt1_korzysci_ai     | character | Odpowiedź na: "Jakie korzyści widzi Pan/Pani z zastosowania AI w instytucjach kultury?" |
| pyt2_obawy_ai        | character | Odpowiedź na: "Jakie obawy budzi w Panu/Pani zastosowanie AI w Pana/Pani pracy?" |
| pyt3_przyszlosc      | character | Odpowiedź na: "Jak wyobraża sobie Pan/Pani swoją instytucję za 5 lat w kontekście AI?" |
| pyt1_dlugosc         | integer   | nchar(pyt1) |
| pyt2_dlugosc         | integer   | nchar(pyt2) |
| pyt3_dlugosc         | integer   | nchar(pyt3) |

Logika generowania:
1. Losuj profil demograficzny (wiek, płeć, staż, typ instytucji, stanowisko)
2. Dla każdego profilu stwórz prompt systemowy z persona:
   "Jesteś [stanowisko] w [typ_instytucji], masz [staz] lat doświadczenia,
    [dodatkowy kontekst zależny od profilu].
    Odpowiedz na pytanie ankietowe naturalnym językiem, 2-5 zdań.
    Odpowiadaj PO POLSKU. Bądź autentyczny — masz własne zdanie."
3. Wygeneruj odpowiedź na każde z 3 pytań osobno
4. Dodaj realistyczny szum:
   - 5% respondentów daje bardzo krótkie odpowiedzi (1 zdanie)
   - 3% daje nietematyczne/wymijające odpowiedzi
   - 10% jest wyraźnie entuzjastycznych, 10% sceptycznych
5. Zapisz jako CSV z kodowaniem UTF-8
```

### 06_eksport.R
```
Kluczowe funkcje:

zapisz_wyniki(wyniki, spotkanie, nazwa)
  → saveRDS do wyniki/sXX/nazwa.rds

zapisz_csv(dane, spotkanie, nazwa)
  → write_csv z UTF-8

pokaz_podsumowanie_spotkania(spotkanie)
  → wczytuje wszystkie .rds z danego spotkania
  → generuje tabelę zbiorczą
```

---

## 6. STRUKTURA .Rmd — SZABLON

Każdy plik .Rmd ma identyczną strukturę:

```rmd
---
title: "Spotkanie X: [Tytuł]"
output: html_document
---

# Spotkanie X: [Tytuł]

[2-3 zdania wprowadzenia po polsku]

## Przygotowanie środowiska

''''{r setup, message=FALSE, warning=FALSE}
source("R/00_setup.R")
''''

---

## Zadanie 1: [Nazwa]

[Opis zadania — 3-4 zdania]

**Framework: [NAZWA]** — przypomnienie:
- [Element 1] — ...
- [Element 2] — ...
- ...

''''{r zad1}
# ══════════════════════════════════════════
# TWOJE ZADANIE: Uzupełnij prompt poniżej
# ══════════════════════════════════════════

moj_prompt <- "
[UZUPEŁNIJ WEDŁUG SCHEMATU [FRAMEWORK]]

Tekst: {text}
"

# Wyniki (jedna linia kodu):
wyniki_zad1 <- klasyfikuj_zbior(korpus_polityczny, moj_prompt,
                                 etykiety = c("pozytywny", "negatywny", "neutralny"),
                                 n = 15)
pokaz_rozklad(wyniki_zad1, "klasyfikacja", "Sentyment — mój prompt")
pokaz_tabele(wyniki_zad1)
''''

### Pytania do refleksji:
1. ...
2. ...
3. ...

''''{r zad1_refleksja}
moja_interpretacja_zad1 <- "
[TUTAJ WPISZ 3-5 ZDAŃ KOMENTARZA DO WYNIKÓW]
"
''''

---

[... kolejne zadania ...]

## Zapis wyników

''''{r zapis}
zapisz_wyniki(list(zad1 = wyniki_zad1, zad2 = wyniki_zad2, ...),
              spotkanie = "s02", nazwa = "analiza_sentymentu")
''''
```

---

## 7. PROMPT DLA CLAUDE CODE

Poniższy prompt służy do wdrożenia całej reorganizacji w IDE:

---

```
Zreorganizuj kurs LLM dla bibliotekarzy. Potrzebuję 7 plików .Rmd (spotkania S01-S07) 
i 7 skryptów R w katalogu R/. Pełny plan jest w pliku PLAN_KURSU.md — przeczytaj go 
i zaimplementuj krok po kroku.

ARCHITEKTURA:
- R/00_setup.R — instalacja/ładowanie pakietów, test Ollama, pull modeli Bielik, source() reszty
- R/01_modele.R — wrappery: zapytaj(), klasyfikuj(), klasyfikuj_zbior(), wyciagnij(), generuj()
- R/02_dane.R — ładowanie korpusów: polityczny (sotu), naukowy (RDS), faktograficzny (RDS), respondenci (CSV)
- R/03_wizualizacje.R — pokaz_rozklad(), pokaz_confusion_matrix(), pokaz_heatmapa_zgodnosci(), 
  pokaz_triangulacje(), pokaz_tabele(), pokaz_siec_podmiotow(), pokaz_chmure()
- R/04_walidacja.R — test_retest(), policz_metryki(), policz_kappa(), policz_alpha(), 
  analizuj_bledy(), trianguluj(), porownaj_frameworki_walidacja()
- R/05_symulacja_respondenci.R — skrypt prowadzącego: generuje 200 respondentów (CSV) 
  z 3 pytaniami otwartymi + metryki demograficzne, profil zależy od losowanych cech
- R/06_eksport.R — zapisz_wyniki(), zapisz_csv(), pokaz_podsumowanie_spotkania()

ZASADY:
1. Pliki .Rmd mają BYĆ KRÓTKIE. Student widzi TYLKO:
   - source("R/00_setup.R") na początku
   - Opis zadania po polsku
   - Framework do wypełnienia (schemat)
   - moj_prompt <- "..." (jedyne co pisze)
   - Jedno wywołanie funkcji: wyniki <- klasyfikuj_zbior(korpus, moj_prompt, etykiety, n=15)
   - pokaz_rozklad(wyniki) / pokaz_tabele(wyniki)
   - Pytania do refleksji
   - moja_interpretacja <- "..." (akapit studenta)
   Nic więcej. Żadnego kodu R poza tymi wywołaniami.

2. Wszystkie prompty po POLSKU. Etykiety klasyfikacyjne po polsku 
   (pozytywny/negatywny/neutralny, nadzieja/strach/duma itd.)

3. Modele Ollama:
   - Domyślny: SpeakLeash/bielik-4.5b-v3.0-instruct (alias "bielik-4.5b")
   - Porównawcze: SpeakLeash/bielik-1.5b-v3.0-instruct, phi4-mini
   - Opcjonalny: SpeakLeash/bielik-minitron-7b-v3.0-instruct
   - Do symulacji respondentów: SpeakLeash/bielik-11b-v3.0-instruct

4. Każde spotkanie (S02-S07) używa dokładnie 3 frameworków promptowania. 
   Frameworki do użycia: RTF, CO-STAR, AUTOMAT, CRISPE, RISEN, Few-shot, Chain-of-Thought.

5. Każde zadanie w .Rmd kończy się blokiem:
   moja_interpretacja_zadX <- "[TUTAJ WPISZ KOMENTARZ]"

6. Funkcje w R/ muszą mieć polskie komunikaty w konsoli ("⏳ Klasyfikuję 15 fragmentów...", 
   "✅ Gotowe. Czas: Xs."), progress bar (cli::cli_progress_bar), i obsługę błędów 
   (tryCatch z czytelnym komunikatem po polsku).

7. Wizualizacje: ggplot2 + gt/kableExtra. Kolory spójne (skala: "#4CAF50", "#F44336", "#9E9E9E", 
   "#2196F3", "#FF9800"). Tytuły po polsku. theme_minimal().

8. Plik 05_symulacja_respondenci.R: generuje dane/respondenci_200.csv. 
   Kolumny: id, wiek, plec, staz_pracy_lat, typ_instytucji, stanowisko, 
   pyt1_korzysci_ai, pyt2_obawy_ai, pyt3_przyszlosc, pyt1_dlugosc, pyt2_dlugosc, pyt3_dlugosc.
   Każdy respondent ma persona prompt z demografią. Temperature=0.9.
   5% daje krótkie odpowiedzi, 3% wymijające, 10% entuzjastyczne, 10% sceptyczne.

KOLEJNOŚĆ IMPLEMENTACJI:
1. Najpierw R/00_setup.R i R/01_modele.R (fundamenty)
2. Potem R/02_dane.R i R/03_wizualizacje.R
3. Potem R/04_walidacja.R
4. Potem S01_generowanie.Rmd i S02_sentyment.Rmd (do testowania)
5. Potem reszta .Rmd
6. Na końcu R/05_symulacja_respondenci.R i S06-S07
7. README.md z instrukcją uruchomienia

Przeczytaj PLAN_KURSU.md i zacznij od kroku 1. Po każdym kroku pokaż, co zrobiłeś 
i czekaj na moje OK przed następnym.
```

---

## 8. MODELE POLSKIE — REKOMENDACJA KOŃCOWA

### Stack produkcyjny kursu

| Rola | Model | Ollama pull | RAM (Q4) | Uwagi |
|------|-------|-------------|----------|-------|
| **Główny roboczy** | Bielik 4.5B v3 Instruct | `ollama pull SpeakLeash/bielik-4.5b-v3.0-instruct` | ~3 GB | Najlepszy PL/rozmiar; pokonuje Qwen2.5-7B na PL benchmarkach |
| Demo ograniczeń | Bielik 1.5B v3 Instruct | `ollama pull SpeakLeash/bielik-1.5b-v3.0-instruct` | ~1 GB | Widocznie gorszy — idealne do S01 i S05 |
| Porównanie wielojęzyczne | phi4-mini | `ollama pull phi4-mini` | ~2.5 GB | Dobry EN, słabszy PL — kontrast |
| Opcja 7B | Bielik Minitron 7B v3 | `ollama pull SpeakLeash/bielik-minitron-7b-v3.0-instruct` | ~4.5 GB | Jeśli komputery studentów dają radę |
| Symulacja respondentów | Bielik 11B v3 Instruct | `ollama pull SpeakLeash/bielik-11b-v3.0-instruct` | ~7 GB | Tylko prowadzący; najlepsza jakość PL |

### Dlaczego Bielik 4.5B a nie 7B jako domyślny?

Bielik 4.5B v3.0-Instruct to model oparty na Qwen2.5-3B skalowany metodą Depth Up-Scaling 
do 4.5B parametrów, z natywnym polskim tokenizerem. Na Open PL LLM Leaderboard (5-shot) 
uzyskuje 56.13 — lepiej niż Qwen2.5-7B-Instruct (54.93) i Mistral-Nemo-Instruct (55.27). 
Na EQ-Bench (implicature + phraseology + sentiment) pokonuje nawet Bielik-11B-v2 w kilku 
subkategoriach. Przy ~3 GB RAM w Q4 zmieści się na laptopach studentów.

### Aliasy w 00_setup.R

```r
MODELE <- list(
  "bielik-4.5b"  = "SpeakLeash/bielik-4.5b-v3.0-instruct",
  "bielik-1.5b"  = "SpeakLeash/bielik-1.5b-v3.0-instruct",
  "bielik-7b"    = "SpeakLeash/bielik-minitron-7b-v3.0-instruct",
  "bielik-11b"   = "SpeakLeash/bielik-11b-v3.0-instruct",
  "phi4-mini"    = "phi4-mini"
)
options(kurs_model = MODELE[["bielik-4.5b"]])
```

---

## 9. OTWARTE DECYZJE DLA PROWADZĄCEGO

1. **Korpus naukowy** — czy użyć angielskich abstracts z arXiv (łatwiej pobrać programatycznie) 
   czy polskich abstracts z Repozytorium UJ (trudniej pobrać, ale bliżej kontekstu studentów)?
   → Sugestia: przygotuj oba jako RDS; w S02-S03 daj angielski, w S05 porównaj angielski vs polski.

2. **Korpus faktograficzny** — Britannica z gutenbergr (XIX w. angielski) 
   czy polska Wikipedia (współczesna, ale wymaga scrapowania)?
   → Sugestia: Wikipedia offline (prowadzący pobiera 100 artykułów raz).

3. **Czy S07 to projekt indywidualny czy grupowy?** 
   → Sugestia: indywidualny, ale mini-raport jest wspólnie recenzowany (peer review w parach).

4. **Czy etykiety klasyfikacyjne mają być po polsku czy po angielsku?**
   → Plan zakłada polskie. Ale Bielik może dawać lepsze wyniki z angielskimi etykietami. 
   Warto przetestować przed kursem.

5. **Czy 200 respondentów wystarczy?**
   → Tak — daje sensowne rozkłady statystyczne. 
   Prowadzący może zwiększyć do 300 jeśli S07 wymaga subgrupowych analiz.
