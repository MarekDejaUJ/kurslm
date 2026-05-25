# Skrypt prowadzacego: generowanie danych respondentow.
# Ten plik nie jest automatycznie uruchamiany przy ladowaniu pakietu.

if (!exists("zapytaj", mode = "function")) {
  library(kurslm)
}

kurs_losuj_profil <- function(id) {
  typy <- c("biblioteka_akademicka", "biblioteka_publiczna", "archiwum", "muzeum")
  stanowiska <- c("bibliotekarz", "katalogujacy", "kierownik", "informatyk", "inny")
  data.frame(
    id = id,
    wiek = sample(22:65, 1),
    plec = sample(c("K", "M", "I"), 1, prob = c(0.62, 0.35, 0.03)),
    staz_pracy_lat = sample(0:40, 1),
    typ_instytucji = sample(typy, 1),
    stanowisko = sample(stanowiska, 1),
    stringsAsFactors = FALSE
  )
}

kurs_prompt_respondenta <- function(profil, pytanie, ton) {
  paste0(
    "Jestes respondentem ankiety. Profil: stanowisko=", profil$stanowisko,
    ", instytucja=", profil$typ_instytucji,
    ", wiek=", profil$wiek,
    ", staz=", profil$staz_pracy_lat, " lat. ",
    "Odpowiedz po polsku naturalnym jezykiem, 2-5 zdan. Ton odpowiedzi: ", ton, ". ",
    "Nie wspominaj, ze jestes modelem. Pytanie: ", pytanie
  )
}

kurs_odpowiedz_fallback <- function(pytanie, ton) {
  if (identical(ton, "wymijajacy")) {
    return("Trudno mi teraz odpowiedziec jednoznacznie. To zalezy od konkretnych narzedzi i decyzji instytucji.")
  }
  if (identical(ton, "krotki")) {
    return("AI moze byc pomocna, ale wymaga ostroznosci.")
  }
  if (identical(ton, "sceptyczny")) {
    return("Widze pewne zastosowania, ale obawiam sie bledow, utraty kompetencji i braku przejrzystosci decyzji.")
  }
  if (identical(ton, "entuzjastyczny")) {
    return("Widze duzy potencjal w automatyzacji rutynowych zadan, lepszym wyszukiwaniu i nowych uslugach dla uzytkownikow.")
  }
  paste0("W odniesieniu do pytania: ", pytanie, " uwazam, ze AI moze wspierac prace, ale powinna pozostac narzedziem kontrolowanym przez ludzi.")
}

generuj_respondentow <- function(n_respondentow = 200, sciezka = "dane/respondenci_200.csv",
                                model = "minimax-m2", temperature = 0.9, thinking = TRUE,
                                seed = 42) {
  set.seed(seed)
  dir.create(dirname(sciezka), showWarnings = FALSE, recursive = TRUE)

  pytania <- c(
    pyt1_korzysci_ai = "Jakie korzysci widzi Pan/Pani z zastosowania AI w instytucjach kultury?",
    pyt2_obawy_ai = "Jakie obawy budzi w Panu/Pani zastosowanie AI w Pana/Pani pracy?",
    pyt3_przyszlosc = "Jak wyobraza sobie Pan/Pani swoja instytucje za 5 lat w kontekscie AI?"
  )

  dane <- vector("list", n_respondentow)
  for (i in seq_len(n_respondentow)) {
    profil <- kurs_losuj_profil(i)
    los <- runif(1)
    ton <- if (los < 0.03) {
      "wymijajacy"
    } else if (los < 0.08) {
      "krotki"
    } else if (los < 0.18) {
      "entuzjastyczny"
    } else if (los < 0.28) {
      "sceptyczny"
    } else {
      "zrownowazony"
    }

    odpowiedzi <- lapply(pytania, function(pytanie) {
      if (isTRUE(getOption("kurs_tryb_mock", FALSE))) {
        kurs_odpowiedz_fallback(pytanie, ton)
      } else {
        prompt <- kurs_prompt_respondenta(profil, pytanie, ton)
        tryCatch(
          zapytaj(prompt, model = model, temperature = temperature, thinking = thinking)$odpowiedz,
          error = function(e) kurs_odpowiedz_fallback(pytanie, ton)
        )
      }
    })

    wiersz <- cbind(profil, as.data.frame(odpowiedzi, stringsAsFactors = FALSE))
    wiersz$pyt1_dlugosc <- nchar(wiersz$pyt1_korzysci_ai)
    wiersz$pyt2_dlugosc <- nchar(wiersz$pyt2_obawy_ai)
    wiersz$pyt3_dlugosc <- nchar(wiersz$pyt3_przyszlosc)
    wiersz$jezyk <- "pl"
    dane[[i]] <- wiersz
  }

  wynik <- do.call(rbind, dane)
  if (requireNamespace("readr", quietly = TRUE)) {
    readr::write_csv(wynik, sciezka)
  } else {
    write.csv(wynik, sciezka, row.names = FALSE, fileEncoding = "UTF-8")
  }
  message("Zapisano dane respondentow: ", sciezka)
  kurs_as_tibble(wynik)
}
