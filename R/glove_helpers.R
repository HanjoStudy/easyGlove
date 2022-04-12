# https://rpubs.com/alyssafahringer/176732

#' glove_closest_to
#' @description return the word associations closest to provided word
#' @param word_vec word vector to calculate on
#' @param top_n top n to return
#' @importFrom text2vec sim2
#' @export
#'
glove_closest_to <- function(word_vectors, word_vec, top_n = 10) {
  token_in <- word_vectors[word_vec, , drop = FALSE]
  cos_dist <- sim2(x = word_vectors, y = token_in, method = "cosine", norm = "l2")
  out <- sort(cos_dist[,1], decreasing = TRUE)

  names(out) <- trimws(gsub("_"," ",names(out)))
  names(out) <- gsub("\\s+", "_", names(out))
  out <- out[!duplicated(names(out))]

  out <- head(out[names(out) != word_vec], top_n)

  class(out) <- c("model.glove", class(out))
  return(out)
}

#' similarities
#' @description return the word similarities in terms of provided words
#' @param word_vec word vector to calculate on
#' @importFrom broom tidy
#' @export
#'
similarities <- function(word_vectors, word_vec) {
  token_in <- word_vectors[word_vec, , drop = FALSE]
  cos_dist <- sim2(x = word_vectors, y = token_in, method = "cosine", norm = "l2")
  cos_dist %>% t() %>% tidy() %>% rename(word = .rownames)
}

#' glove_vec
#' @description returns GloVe vector for a word
#' @param word word vector to return
#' @export
#'
word_vec <- function(word_vectors, word) {
  word_vectors[word, , drop = FALSE]
}

#' closest_to
#' @description function that will determine words that are close to specific word
#' @param word_vectors all vectors from glove model
#' @param word word vector to return
#' @export
#'
closest_to <- function(word_vec, word_vectors, top_n = 10) {
  cos_dist <- sim2(x = word_vectors, y = word_vec, method = "cosine", norm = "l2")

  out <- sort(cos_dist[,1], decreasing = TRUE)

  names(out) <- trimws(gsub("_"," ",names(out)))
  names(out) <- gsub("\\s+", "_", names(out))
  out <- out[!duplicated(names(out))]

  out <- head(out, top_n)

  return(out)
}
