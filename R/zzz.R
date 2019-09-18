.onAttach <- function(libname, pkgname) {
  packageStartupMessage("propeR")
}

.onLoad <- function(libname, pkgname) {
  options(digits.secs=3)
  options(scipen=999)
}
