pcre <- function(pattern, text, subpattern)
{

  stopifnot(as.integer(subpattern)==subpattern)

	.Call("_gregexpr",pattern,text,subpattern)

}

#
# A function for replacing word IDs.
#
# Most of the time, this will be used to replace numerical word IDs by
# alphabetical IDs.  This is useful for sentences that have more than 10 words.
#

# d$wn <- replace.syms(d$wn, unique(d$wn), LETTERS[unique(d$wn)])

#library(gdata)

replace.syms <- function(x, r, res.type=as.character, na.value=NA) {

  stopifnot(length(unique(r))==length(r))
  stopifnot(length(unique(x[!is.na(x)]))==length(r))

  x <- factor(x, labels=r)
  if (!is.na(na.value))
    x <- suppressWarnings(NAToUnknown(x, na.value))
  res.type(x)

}

# Get that package from my webpage:
# library(scanpath)
# plot.scanpaths(dur~wn|id, d)

#
# Finding specific events in the eye movement record:
#
# TODO: nth!=1 case
# TODO: groups

# Implementation: pseudo code for the case without groups: (groups are just
# ignored)

# * syms is the sequence of word identifiers in the order in which they were
#   fixated.
# * trial indicates to which trial each fixation belongs.
# * expr is the regular expression.
# * nth indicates which match should be returned.  If nth is larger than the
#   number of matches in a trial, nothing is returned for that trial.
# * group indicates which group we're interested in.  If group==1, pointers to
#   the beginning of the first group are returned.  (Throw an error message if
#   a group is requested that doesn't exist in the expression.)  If
#   is.null(group), ignore groups and return pointers to the beginning of the
#   global match.
find.fixation <- function(syms, trial, expr, nth=1, subpattern=0) {
  
  if (nth!=1)
    stop("use gregepxr")

  s <- sapply(split(syms, trial),
              function(s) do.call(paste, c(as.list(s), sep="")))

  hits <- unlist(pcre(expr, s, subpattern))
  offsets <- c(0, cumsum(nchar(s)))[1:length(hits)]

  offsets <- offsets[hits!=-1]
  hits <- hits[hits!=-1]

  hits + offsets

}

# # Fixations on word F:
# find.fix(d$wn, d$id, "F")
# d[find.fix(d$wn, d$id, "F"),]
# 
# # Fixations on word F followed by a fixation on word E:
# find.fix(d$wn, d$id, "FE")
# 
# # Fixations on word F preceded by a fixation on word G:
# # (We want a pointer for E not G.)
# find.fix(d$wn, d$id, "(G)E")
# 
# # Beginngin of a second pass through the sentence:
# find.fix(d$wn, d$id, "([A-G]+)A[A-G]+")

#
# Extract sub-scanpaths:
#
# TODO: nth!=1 cases
# TODO: groups

# * syms is the sequence of word identifiers in the order in which they were
#   fixated.
# * trial indicates to which trial each fixation belongs.
# * expr is the regular expression.
# * nth indicates which match should be returned.  If nth is larger than the
#   number of matches in a trial, nothing is returned for that trial.
# * group indicates which group we're interested in.  If group==1, the scanpath
#   corresponding to the first group is returned.  (Throw an error message if
#   a group is requested that doesn't exist in the expression.)  If
#   is.null(group), ignore groups and return the scanpath corresponding to the
#   global match.
match.scanpath <- function(syms, trial, expr, nth=1, subpattern=0) {

  if (nth!=1)
    stop("use gregepxr")

  s <- sapply(split(syms, trial),
              function(s) do.call(paste, c(as.list(s), sep="")))

  hitsg <- pcre(expr, s, subpattern)
  hits <- sapply(hitsg, function(x) x[[1]])
  mlen <- sapply(hitsg, function(x) attr(x, "match.length")[[1]])
  offsets <- c(0, cumsum(nchar(s)))[1:length(hits)]

  offsets <- offsets[hits!=-1]
  mlen <- mlen[hits!=-1]
  hits <- hits[hits!=-1]

  hite <- hits + mlen + offsets - 1
  hits <- hits + offsets

  # Probably not very efficient:
  f <- function(i) { hits[i]:hite[i] }
  unlist(lapply(1:length(hits), f))

}

# p <- function(x) plot.scanpaths(dur~wn|id, d[x,])
# 
# # Extract sub-scanpaths where first E and then F is fixated:
# p(extract.fix(d$wn, d$id, "EF"))
# 
# # More examples:
# p(extract.fix(d$wn, d$id, "EF*"))
# p(extract.fix(d$wn, d$id, "EF+"))
# 
# # Straight left-to-right reading:
# p(extract.fix(d$wn, d$id, "A+B+C+D+E+F+G+"))
# 
# # Regression starting on F:
# p(extract.fix(d$wn, d$id, "F[A-E]+[FG]"))
