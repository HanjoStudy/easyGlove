
#' model_glove
#' @description runs a GloVe model on the text within the articles or provided texts
#' @param txt character vector of the text to analyse
#' @import text2vec
#' @import logger
#' @import tm
#' @importFrom dplyr as_tibble mutate select
#' @importFrom furrr future_map
#' @importFrom parallel makePSOCKcluster stopCluster
#' @importFrom future plan
#' @importFrom glue glue
#' @return tibble
#' @export
#'
model_glove <- function(txt, ngrams = 1, term_count_min = 5, skip_grams_window = 10L,
                        runs = 10, embedding_dim = 200, co_oc_max, cores = 8, verbose = TRUE){
  
  if(verbose)
    log_info("Start cleaning text")

  if(cores){
    if(verbose)
      log_info(glue("Starting parrallel split of text with [{cores}] cores"))
    
    out <- split(txt, rep_len(1:cores, length(txt)))
    cl <- makePSOCKcluster(cores)
    on.exit(stopCluster(cl))
    plan(cluster, workers = cl)
    res <- future_map(out, clean_text, .progress = verbose)
    tokens <- reduce(res, c)
    
  } else {
    tokens <- clean_text(txt)
  }
  if(verbose)
    log_info("Tokenize using itoken after cleaning")
  
  it <- itoken(tokens, progressbar = verbose)
  
  if(verbose)
    log_info("Create vocabulary")
  vocab <- create_vocabulary(it, ngram = c(1, ngrams),
                             stopwords = tm::stopwords("english"))
  vocab <- prune_vocabulary(vocab, term_count_min = term_count_min)
  
  if(missing(co_oc_max)){
    x_max <- length(vocab$doc_count)/100
  }
  
  if(verbose)
    log_info(glue("Create tcm with x_max = [{x_max}]"))

  vectorizer <- vocab_vectorizer(vocab)
  tcm <- create_tcm(it, vectorizer, skip_grams_window = skip_grams_window)

  glove <- GlobalVectors$new(rank = embedding_dim, x_max = x_max)
  wv_main <- glove$fit_transform(tcm, n_iter = runs, convergence_tol = 0.01, n_threads = cores)
  wv_context <- glove$components

  word_vectors <- wv_main + t(wv_context)
  rownames(word_vectors) <- rownames(tcm)

  class(word_vectors) <- c("model.glove", class(word_vectors))
  return(word_vectors)
}

#' plot_glove
#' @description brings back the text of journals that contain a certain word
#' @param word_sim output from glove estimate
#' @param txt_size max text size in wordcloud
#' @param bg background of ggplot
#'
#' @import ggplot2
#' @import ggwordcloud
#' @importFrom dplyr tibble
#' @return tibble
#' @export
#'

plot_glove <- function(word_sim, txt_size = 15, bg = "transparent"){

  tibble(word_txt = names(word_sim), proximity = round(word_sim, 2)) %>%
    filter(proximity != 1) %>%
    ggplot(., aes(label = word_txt, size = proximity, color = proximity)) +
    geom_text_wordcloud() +
    scale_color_viridis_c() +
    scale_size_area(max_size = txt_size) +
    theme_minimal(base_size = 15) +
    labs(color = "") +
    theme(legend.position = "none",
          rect = element_rect(fill = bg) )

}

