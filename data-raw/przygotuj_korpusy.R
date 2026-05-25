# Skrypt przygotowujacy pregenerowane korpusy dla pakietu kurslm.
# Ten skrypt powinien byc uruchomiony przez dewelopera w celu stworzenia danych dystrybucyjnych.

# Tworzenie katalogu docelowego
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)

# Ladowanie funkcji pomocniczych z R
source("R/setup.R")
source("R/modele.R")
source("R/dane.R")

# 1. Przygotowanie korpusu politycznego (SOTU)
cli::cli_inform("Przygotowuje korpus polityczny (SOTU)...")
korpus_pol <- wczytaj_korpus_polityczny(n = 100, sciezka = "nonexistent.rds")
# Zapisujemy same teksty do RDS w inst/extdata/
saveRDS(korpus_pol, "inst/extdata/korpus_polityczny.rds")
cli::cli_alert_success("Zapisano korpus_polityczny.rds")

# 2. Przygotowanie korpusu naukowego
cli::cli_inform("Przygotowuje korpus naukowy...")
teksty_naukowe <- c(
  "This study examines how digital catalogues influence information seeking behavior among university students. Using a mixed methods design, we combine log data with interviews and show that interface cues shape both search persistence and perceived credibility.",
  "Large language models offer new opportunities for qualitative coding, but their reliability depends on prompt design, category clarity, and validation against human annotations. We evaluate model stability across repeated classifications of short research abstracts.",
  "The paper proposes a framework for comparing lexical sentiment tools and generative models in cultural heritage datasets. Results suggest that lexicon-based methods remain useful for triangulation, especially when model outputs are unstable.",
  "We analyze professional attitudes toward artificial intelligence in libraries, archives, and museums. Respondents describe efficiency gains, but also concerns about transparency, deskilling, copyright, and institutional accountability.",
  "A corpus of policy documents was segmented into rhetorical units and classified by stance. The findings indicate that uncertainty is often framed as a management problem rather than as a limitation of available evidence.",
  "This article investigates the evolution of retrieval systems in archival research. We trace the shift from paper-based inventories to semantic search engines powered by dense vector embeddings, highlighting changes in user query complexity.",
  "We present an analysis of metadata quality in institutional repositories. By evaluating completeness and consistency across 10,000 records, we show that automated enrichment pipelines significantly reduce retrieval errors.",
  "Generative AI poses unique challenges for academic integrity in higher education. This paper surveys university policies on AI usage and analyzes student perceptions of fair use in writing assignments.",
  "Digital curation requires long-term planning, file format monitoring, and persistent identifier maintenance. We evaluate the cost-effectiveness of decentralized storage systems for small-scale community archives.",
  "Information literacy programs are increasingly incorporating critical algorithms studies. We describe a workshop design that helps undergraduate students recognize bias in search engine results and social media feeds."
)
# Augmentujemy teksty powtarzajac je, aby uzyskac odpowiednia liczbe wierszy (np. 80)
teksty_naukowe_full <- rep(teksty_naukowe, length.out = 80)
saveRDS(data.frame(id = seq_along(teksty_naukowe_full), text = teksty_naukowe_full, stringsAsFactors = FALSE), "inst/extdata/korpus_naukowy.rds")
cli::cli_alert_success("Zapisano korpus_naukowy.rds")

# 3. Przygotowanie korpusu faktograficznego
cli::cli_inform("Przygotowuje korpus faktograficzny...")
teksty_faktograficzne <- c(
  "The Library of Alexandria was one of the most famous libraries of the ancient world. It functioned as part of a larger research institution and became a symbol of scholarly ambition, textual collection, and the fragility of cultural memory.",
  "The printing press transformed the circulation of texts in Europe during the fifteenth century. Movable type made reproduction faster and cheaper, contributing to religious debate, scientific communication, and the growth of public reading cultures.",
  "Wikipedia is a multilingual online encyclopedia maintained by volunteer contributors. Its articles are revised continuously, which makes it both a practical reference source and an object of research on collaborative knowledge production.",
  "The Dewey Decimal Classification organizes library materials by subject using numerical notation. Although widely adopted, it has also been criticized for historical biases embedded in its categories.",
  "Digital preservation refers to the set of policies and technical actions used to maintain access to digital objects over time. It includes format migration, metadata management, integrity checking, and institutional planning.",
  "The British Library is the national library of the United Kingdom and one of the largest libraries in the world. It contains over 150 million items, including historical manuscripts, maps, and national archives.",
  "The Internet Archive is a non-profit digital library that offers free public access to digitized materials, including websites, books, audio recordings, and software. It is famous for its Wayback Machine tool.",
  "An abstracting and indexing service is a product that provides summaries and bibliographic metadata of academic literature. Famous examples include Scopus, Web of Science, and PubMed.",
  "The Dublin Core Metadata Element Set is a standard for cross-domain information resource description. It defines 15 core elements, such as Title, Creator, Subject, Description, and Date.",
  "Optical Character Recognition (OCR) is the electronic conversion of images of typed or handwritten text into machine-encoded text. It is critical for digitizing historical newspapers and books."
)
teksty_faktograficzne_full <- rep(teksty_faktograficzne, length.out = 80)
saveRDS(data.frame(id = seq_along(teksty_faktograficzne_full), text = teksty_faktograficzne_full, stringsAsFactors = FALSE), "inst/extdata/korpus_faktograficzny.rds")
cli::cli_alert_success("Zapisano korpus_faktograficzny.rds")

# 4. Generowanie respondentow (w trybie mock, aby nie odpytywac serwera w chmurze przy budowaniu pakietu)
cli::cli_inform("Generuje respondentow (tryb mock)...")
options(kurs_tryb_mock = TRUE)
source("inst/prowadzacy/symulacja_respondenci.R")
resp <- generuj_respondentow(n_respondentow = 200, sciezka = "inst/extdata/respondenci_200.csv")
cli::cli_alert_success("Zapisano respondenci_200.csv")

cli::cli_alert_success("Przygotowanie korpusow ukonczone!")
