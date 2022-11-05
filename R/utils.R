#' clean_text
#' @description efficient wrapper around cleaning of text to facilitate parralel cleaning
#' @param txt txt vector
#' @export
#'
clean_text <- function(txt){
  txt %>%
    removePunctuation %>%
    stripWhitespace %>%
    removeNumbers %>%
    tolower %>%
    removeWords(., unique(stopwords("SMART"))) %>%
    strsplit(., split = " ",
             fixed = T)
}
