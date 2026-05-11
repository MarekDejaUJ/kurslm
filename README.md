# LLM w analizie tekstu dla profesjonalistów informacji

Repo zawiera przebudowaną wersję zajęć w układzie `S01`-`S07`. Studenci pracują w plikach `.Rmd`, a cała mechanika techniczna jest schowana w katalogu `R/`.

## Jak uruchomić zajęcia

1. Uruchom Ollama.
2. Otwórz wybrany plik, np. `S01_generowanie.Rmd`.
3. Uruchom pierwszy chunk:

```r
source("R/00_setup.R")
przygotuj_spotkanie("S01")
```

`R/00_setup.R` instaluje brakujące pakiety, ładuje funkcje kursowe, sprawdza Ollamę i ustawia aliasy modeli.

## Modele Ollama

Domyślny stos kursu:

- `qwen3-0.6b`: demo ograniczeń małego modelu,
- `SpeakLeash/bielik-4.5b-v3.0-instruct`: główny model do danych polskich,
- `qwen3:4b`: główny model do danych angielskich i trybu thinking,
- `phi4-mini`: model porównawczy,
- `qwen3:8b`: tylko dla prowadzącego, do symulacji respondentów.

Jeśli model nie jest pobrany, setup pokaże polecenie `ollama pull ...`. Automatyczne pobieranie można włączyć opcją:

```r
options(kurs_auto_pull = TRUE)
source("R/00_setup.R")
```

## Tryb testowy bez Ollamy

Do sprawdzania renderowania i struktury plików można użyć trybu mock:

```r
options(kurs_tryb_mock = TRUE, kurs_auto_install = FALSE)
source("R/00_setup.R")
```

W tym trybie funkcje zwracają deterministyczne odpowiedzi testowe, więc da się sprawdzić przepływ zajęć bez wywołań LLM.

## Dane

Kurs domyślnie korzysta z odtwarzalnych danych angielskich i fallbacków wbudowanych w `R/02_dane.R`. Jeśli prowadzący dostarczy własne korpusy, należy umieścić je w katalogu `dane/`:

- `dane/korpus_polityczny.rds`,
- `dane/korpus_naukowy.rds`,
- `dane/korpus_faktograficzny.rds`,
- `dane/respondenci_200.csv`.

Każdy korpus powinien mieć kolumnę `text`; mile widziane są też `id`, `jezyk`, `zrodlo`, `typ_korpusu`.

## Symulacja respondentów

Przed spotkaniem `S06` prowadzący może wygenerować dane ankietowe:

```r
source("R/05_symulacja_respondenci.R")
generuj_respondentow(n_respondentow = 200)
```

Skrypt zapisze `dane/respondenci_200.csv`.

## Struktura

- `S01_generowanie.Rmd`: generowanie i pierwszy RTF,
- `S02_sentyment.Rmd`: sentyment i emocje,
- `S03_ekstrakcja.Rmd`: ekstrakcja informacji,
- `S04_analiza_dyskursu.Rmd`: ton, perswazja, propaganda, ramowanie,
- `S05_porownanie_modeli.Rmd`: modele, frameworki, korpusy, thinking,
- `S06_walidacja.Rmd`: złoty standard, test-retest, metryki, triangulacja,
- `S07_projekt_koncowy.Rmd`: pipeline projektu końcowego.

Stare pliki `m3`, `m4`, `m5` zostały zachowane jako materiał źródłowy, ale właściwy kurs jest w plikach `S*.Rmd`.
