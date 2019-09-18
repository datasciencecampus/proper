PKGNAME := $(shell sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION)
PKGVERS := $(shell sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION)
PKGSRC  := $(shell basename `pwd`)

all: check clean

deps:
	R --silent -e 'install.packages(c("devtools", "rgdal", "dplyr", "progress", "knitr", "rmarkdown", "cleangeo", "leaflet", "magick", "mapview", "rgdal", "rgeos", "htmlwidgets", "gepaf", "geosphere", "FNN"), repos="https://cran.rstudio.com/")'
	R --silent -e 'install.packages("webshot"); webshot::install_phantomjs()'

man-docs:
	R --silent -e 'devtools::document()'

html-docs:
	R --silent -e 'rmarkdown::render("vignettes/guide.Rmd", "html_document", output_dir="/tmp")'

pdf-docs:
	R --silent -e 'rmarkdown::render("vignettes/guide.Rmd", "pdf_document", output_dir="/tmp")'

build: man-docs
	cd ..;\
	R CMD build $(PKGSRC)

check: deps build
	cd ..;\
	R CMD check $(PKGNAME)_$(PKGVERS).tar.gz

install: deps build
	cd ..;\
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

clean:
	$(RM) -rf inst/doc
	cd ..;\
	$(RM) -r $(PKGNAME).Rcheck/
  
test:
	R --silent -e 'if(!require("testthat")) install.packages("testthat"); devtools::test()'
