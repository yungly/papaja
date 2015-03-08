#' Format statistics (APA 6th edition) from ANOVAs
#'
#' These methods take input objects of the \code{aov} type and return them in a format that is suitable for in-line printing.
#'
#' @param x Output object. See details.
#' @param es \code{character} The effect-size measure to be calculated. Either "ges" for generalized eta-squared or "pes" for partial eta-squared.
#' @param observed \code{character} The names of the factors that are observed, (i.e., not manipulated). Is necessary for calculation of generalized eta-squared.
#' @param in_paren \code{logical}. Indicates if the formated string will be reported inside parentheses. See details.
#' @details details
#'
#'
#' @return a named list
#'
#' @family apa_print
#' @examples
#' NULL
#' @export

apa_print.aov <- function(x, ...) {
  df <- arrange_anova(x)
  values <- .anova(df, ...)
  values
}


#' @rdname apa_print.aov
#' @method apa_print summary.aov

apa_print.summary.aov <- function(x, ...) {
  df <- arrange_anova(x)
  values <- .anova(df, ...)
  values
}


#' @rdname apa_print.aov
#' @method apa_print aovlist

apa_print.aovlist <- function(x, ...) {
  x <- lapply(summary(x), arrange_anova)
  df <- do.call("rbind", x)
  df <- data.frame(df, row.names = NULL)
  values <- .anova(df, ...)
  values
}


#' Format statistics (APA 6th edition) from ANOVAs
#'
#' These methods take input objects of the \code{anova} type and return them in a format that is suitable for in-line printing.
#'
#' @param x Output object. See details.
#' @param es \code{character} The effect-size measure to be calculated. Either "ges" for generalized eta-squared or "pes" for partial eta-squared.
#' @param observed \code{character} The names of the factors that are observed, (i.e., not manipulated). Is necessary for calculation of generalized eta-squared.
#' @param correction \code{character} In the case of repeated-measures ANOVA, the type of sphericity correction to be used. Either "GG" for Greenhouse-Geisser or "HF" for Huyn-Feldt methods. "none" is also possible.
#' @param in_paren \code{logical}. Indicates if the formatted string will be reported inside parentheses. See details.
#' @details details
#'
#'
#' @return a named list
#'
#' @family apa_print
#' @examples
#' NULL
#' @export

apa_print.anova <- function(x, ...) {
  df <- arrange_anova(x)
  values <- .anova(df, ...)
  values
}


#' @rdname apa_print.anova
#' @method apa_print Anova.mlm

apa_print.Anova.mlm <- function(x, correction = "GG", ...) {

  x <- car::summary(x)
  x$sphericity.tests
  tmp <- x$univariate.tests
  class(tmp) <- NULL
  t.out <- data.frame(tmp)
  colnames(t.out) <- colnames(tmp)

  if(nrow(x$sphericity.tests) > 0) {
    if (correction[1] == "GG") {
      t.out[row.names(x$pval.adjustments), "num Df"] <- t.out[row.names(x$pval.adjustments), "num Df"] * x$pval.adjustments[, "GG eps"]
      t.out[row.names(x$pval.adjustments), "den Df"] <- t.out[row.names(x$pval.adjustments), "den Df"] * x$pval.adjustments[, "GG eps"]
      t.out[row.names(x$pval.adjustments), "Pr(>F)"] <- x$pval.adjustments[,"Pr(>F[GG])"]
    } else {
      if (correction[1] == "HF") {
        if (any(x$pval.adjustments[,"HF eps"] > 1)) warning("HF eps > 1 treated as 1")
        t.out[row.names(x$pval.adjustments), "num Df"] <- t.out[row.names(x$pval.adjustments), "num Df"] * pmin(1, x$pval.adjustments[, "HF eps"])
        t.out[row.names(x$pval.adjustments), "den Df"] <- t.out[row.names(x$pval.adjustments), "den Df"] * pmin(1, x$pval.adjustments[, "HF eps"])
        t.out[row.names(x$pval.adjustments), "Pr(>F)"] <- x$pval.adjustments[,"Pr(>F[HF])"]
      } else {
        if (correction[1] == "none") {
          TRUE
        } else stop("None supported argument to correction.")
      }
    }
  }

  df <- as.data.frame(t.out)

  # obtain positons of statistics in data.frame
  old <- c("SS", "num Df", "Error SS", "den Df", "F", "Pr(>F)")
  nu <- c("sumsq", "df", "sumsq_err", "df2", "statistic", "p.value")
  colnames(df) == old
  for (i in 1:length(old)){
    colnames(df)[colnames(df) == old[i]] <- nu[i]
  }

  df$term <- rownames(df)
  df <- data.frame(df, row.names = NULL)
  values <- .anova(df, ...)
  values
}

.anova <- function(x, observed = NULL, es = "ges", in_paren = FALSE) {

  in_paren(in_paren)

  # from here on every class of input object is handled the same way

  # calculate generalized eta squared
  # This code is as copy from afex by Henrik Singmann who said that it is basically a copy from ezANOVA by Mike Lawrence
  if(!is.null(observed)) {
    obs <- rep(FALSE, nrow(x))
    for(i in observed){
      if (!any(str_detect(rownames(x),str_c("\\<", i, "\\>")))) stop(str_c("Observed variable not in data: ", i))
      obs <- obs | str_detect(rownames(x), str_c("\\<", i, "\\>"))
    }
    obs_SSn1 <- sum(x$sumsq*obs)
    obs_SSn2 <- x$sumsq*obs
  } else {
    obs_SSn1 <- 0
    obs_SSn2 <- 0
  }
  x$ges <- x$sumsq / (x$sumsq+sum(unique(x$sumsq_err)) + obs_SSn1-obs_SSn2)
  # calculate partial eta squared
  x$pes <- x$sumsq / (x$sumsq+x$sumsq_err)

  # rounding and filling with zeros
  x[, "statistic"] <- printnum(x[, "statistic"], digits = 2, margin = 2)
  x["p.value"] <- printp(x[, "p.value"])
  x[, c("df", "df2")] <- round(x[, c("df","df2")], digits = 2)
  x[, c("ges","pes")] <- printnum(x[, c("ges","pes")], digits = 3, margin = 2, gt1 = FALSE)

  # add 'equals' where necessary
  eq <- (1:nrow(x))[!grepl(x[, "p.value"], pattern="<|>|=")]
  for (i in eq) {
    x[, "p.value"][i] <- paste0("= ", x[, "p.value"][i])
  }

  # concatenate character strings
  x$md.text <- as.character(NA)

  for (i in 1:nrow(x)) {
    x$md.text[i] <- paste0("*F*", op, x$df[i], ", ", x$df2[i], cp, " = ", x$statistic[i], ", *p* ", x$p.value[i])
    if("ges" %in% es) {
      x$md.text[i] <- paste0(x$md.text[i],", $\\eta^2_G$ = ", x$ges[i])
    }
    if("pes" %in% es) {
      x$md.text[i] <- paste0(x$md.text[i], ", $\\eta^2_p$ = ", x$pes[i])
    }
  }

  # return as named list
  values <- as.list(x$md.text)
  names(values) <- x$term
  values
}


## Helper functions

arrange_anova <- function(x, ...) UseMethod("arrange_anova", x)

arrange_anova.anova <- function(x, ...) {
  object <- as.data.frame(anova)
  x <- data.frame(array(NA, dim = c(nrow(object)-1, 7)), row.names = NULL)
  colnames(x) <- c("term", "sumsq", "df", "sumsq_err", "df2", "statistic", "p.value")
  x[, c("sumsq", "df", "statistic", "p.value")] <- object[-nrow(object), c("Sum Sq", "Df", "F value", "Pr(>F)")]
  x$sumsq_err <- object[nrow(object), "Sum Sq"]
  x$df2 <- object[nrow(object), "Df"]
  x$term <- rownames(object)[-nrow(object)]
  x
}

arrange_anova.aov <- function(x, ...) {
  x <- broom::tidy(aov)
  x$sumsq_err <- x[nrow(x), "sumsq"]
  x$df2 <- x[nrow(x), "df"]
  x <- x[-nrow(x), ]
  x
}

arrange_anova.summary.aov <- function(x, ...) {
  x <- arrange_anova(aov[[1]])
}


# load("~/Dropbox/Pudel/Pudel1/Daten/Daten_Pudel1.RData")

# library(papaja)
# library(afex)
# library(broom)
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),within="Instruktion",fun.aggregate=mean,na.rm=TRUE,return="Anova")
# object <- ez.glm(data=Daten.Lrn,id="id",dv="Reaktionszeit",between=c("Material"),within="Block.Nr",fun.aggregate=mean,na.rm=TRUE,return="Anova")
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),fun.aggregate=mean,na.rm=TRUE,return="lm")
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),within="Instruktion",fun.aggregate=mean,na.rm=TRUE,return="univ")
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),within="Instruktion",fun.aggregate=mean,na.rm=TRUE,return="nice")
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),within="Instruktion",fun.aggregate=mean,na.rm=TRUE,return="aov")
# object <- ez.glm(data=Daten.Gen,id="id",dv="korrekt.2nd",between=c("Material","Generierung","Reihenfolge"),fun.aggregate=mean,na.rm=TRUE,return="aov")

# class(object)
# x <- object
# apa_print(object)

