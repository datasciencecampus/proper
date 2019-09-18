FROM debian

WORKDIR /stuff/propeR

COPY . /stuff

RUN apt-get update && apt-get install -y \
  make \
  r-base \
  libcurl4-openssl-dev \
  libssl-dev \
  libudunits2-dev \
  libcairo2-dev \
  libmagick++-dev \
  libgdal-dev \
  texlive-latex-base \
  texlive-latex-extra \
  pandoc \
  curl

RUN make install

ENTRYPOINT ["Rscript", "--vanilla", "../facade.R"]
