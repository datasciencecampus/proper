---
layout: docs
docid: "installation"
title: "Installation"
permalink: /docs/installation.html
subsections:
  - title: Install
    id: install
  - title: Build
    id: build
  - title: Docker install
    id: docker
---

<a id="install"> </a>

### R installation

The easiest method is to install direct from this GitHub repository using:

```R
# R
library(devtools)
install_github("datasciencecampus/access-to-services/propeR")
```

Failing this, you can pull this repository and install locally using:

```R
# R
install("propeR/dir/here")
```

<a id="build"> </a>

#### R building

If neither method above works. Or you wish to make changes to the package. Then you will need to build the package. Building propeR requires devtools and roxygen2:

```R
# R
install.packages("devtools")
install.packages("roxygen2")
```

Then:

```R
# R
build("propeR/dir/here")
install("propeR/dir/here")
```

Once you have installed propeR using RStudio you can now [start using it in RStudio.](#using-rstudio)

<a id="docker"> </a>

### Docker installation

For convenience we have created a [Docker](https://www.docker.com/) image for
the [propeR R package](https://github.com/datasciencecampus/access-to-services/tree/develop/propeR).

The propeR R package can be built from the parent directory as follows:

```bash
# Bash
cd to/propeR/dir/
docker build . --tag=dsc_proper
```

Or you can build from the [online docker image](https://hub.docker.com/u/datasciencecampus), using:

```bash
# Bash
docker run datasciencecampus/dsc_proper:1.0
```