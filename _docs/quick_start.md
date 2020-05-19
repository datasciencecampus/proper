---
layout: docs
docid: "quick_start"
title: "Quick Start"
permalink: /docs/quick_start.html
subsections:
  - title: Software prerequisites
    id: software-prerequisites
  - title: Data prerequisites
    id: data-prerequisites
  - title: Using RStudio
    id: using-rstudio
  - title: Using Docker
    id: using-docker
  - title: propeR functions
    id: proper-functions
  - title: FAQ
    id: faq
  - title: Acknowledgements
    id: acknowledgements
  - title: Licence
    id: licence
---

<a id="software-prerequisites"> </a>

## Software Prerequisites

* R and your GUI of choice, such as RStudio, OR
* Docker

<a id="data-prerequisites"> </a>

### Data prerequisites

All location data (origin and destination) must be in comma separated (CSV) format and contain the following columns:
* A unique ID column
* A latitude column, where data is in decimal degrees (or a postcode column)
* A longitude column, where data is in decimal degrees (or a postcode column)

The CSV file must contain headers, the header names can be specified in `importLocationData()`.

<a id="using-rstudio"> </a>

### Using RStudio

As with any R package, it can be loaded in an R session using:

```R
#R
library(propeR)
```

<a id="using-docker"> </a>

### Using Docker

Alternatively. If you have installed propeR using Docker you can use Docker to run propeR. Put source and destination `.csv` data in a directory, e.g., `/tmp/data/`. Example data files `origin.csv` and `destination.csv` can be found in `propeR/inst/extdata/`, then:

```bash
#Bash
docker run -v /tmp/data:/mnt datasciencecampus/dsc_proper:1.0 'otp.host="XXX.XXX.X.X", fun="pointToPoint", src_file="/mnt/origin.csv", dst_file="/mnt/destination.csv", output.dir="/mnt", startDateAndTime="2019-08-02 12:00:00"'
```

where `otp.host` is your inet address, which can be found using:

```bash
#Bash
/sbin/ifconfig |grep inet |awk '{print $2}'
```

Output data will be in `tmp/data/`.

<a id="proper-functions"> </a>

### propeR functions

  propeR has the following functions:

  | Function | Description |
  |-----------------------|-----------------------------------------|
  | `importLocationData` | Used to generate a dataframe from a CSV file containing origin or destination information. |
  | `postcodeToDecimalDegrees` | Used in `importLocationData()` to convert postcodes to decimal degrees latitude and longitude via API calls (*needs internet access*). |
  | `cleanGTFS` | Used to clean GTFS ZIP folder before OTP graph building. |
  | `isochrone` | Generates a polygon [(isochrone)](https://en.wikipedia.org/wiki/Isochrone_map) around a single origin to calculate journey times to multiple destinations, can output a PNG map, HTML map, and .GeoJSON polygon file. |
  | `isochroneTime` | Same as `isochrone()`, but between a start and end time/date. Output can be an animated GIF image. |
  | `isochroneMulti`  | Same as `isochrone()`, but for multiple origins. A polygon is created for each origin. |
  | `locationValidator` | Used to check the validity of location points by trying to create a small isochrone around the location. FIxes the nearest routable point if there is an error. |
  | `otpConnect` | A core function used to connect to OTP either locally or remotely (i.e. the URL of the generated and hosted OTP graph). |
  | `otpIsochrone` | A core function used to produce an API call to OTP to be used with the propeR isochrone functions. |
  | `otpTripDistance` | A core function used to produce an API call to OTP to find trip distance. |
  | `otpTripTime` | A core function used to produce an API call to OTP to find trip time. |
  | `pointToPoint` | Calculates the journey details between a single origin and destination, can output a PNG map and HTML map. |
  | `pointToPointLoop` | Calculates the journey details between multiple origins and destinations. |
  | `pointToPointNearest` | Calculates the journey details between the nearest (k = 1) destination to each origin using a KNN approach. Can also calculate the second (k = 2), third (k = 3) naearest, and so forth. |
  | `pointToPointTime` | Same as `pointToPoint()`, but between a start and end time/date. Output can be an animated GIF image. |

  Use **`?`** in R to view the function help files for more information, e.g., **`?isochrone`**. Below we will run through each function using the RStudio method, but the help files will help you understand all the parameters that can be changed in each function.


<a id="faq"> </a>

## FAQ

Q: How accurate is the cost calculation in the point to point functions?

>A: The tool currently cannot ingest fare information. Therefore `costEstimate` can be used in the point to point functions. This provides an *estimate* based on the values given in the parameters `busTicketPrice`, `busTicketPriceMax`, `trainTicketPriceKm` and `trainTicketPriceMin`.

Q: How to I stop propeR printing to the R console:

>A: All functions have a parameter called `infoPrint`. This by default is set to `T`, please set to `F` if you want to prevent console printing.

Q: I found a bug!

>A: Please use the GitHub issues form to provide us with the information ([here](https://github.com/datasciencecampus/proper/issues))

### Common errors

Q: Why am I receiving the following error when running propeR?

```
Error in curl::curl_fetch_memory(url, handle = handle) :
  Failed to connect to localhost port 8080: Connection refused
Called from: curl::curl_fetch_memory(url, handle = handle)
```

> A: The OTP server has not been initiated. Please see [graphtie](https://github.com/datasciencecampus/graphite) of this guide.

Q: Why am I receiving the following error when running propeR?

```
Error in paste0(otpcon, "/plan") : object 'otpcon' not found
```

> A: The OTP connection has not been established. Please see [graphtie](https://github.com/datasciencecampus/graphite) of this guide.

<a id="acknowledgements"> </a>

## Acknowledgments

* [TransXChange2GTFS](https://github.com/danbillingsley/TransXChange2GTFS)
* [transxchange2gtfs](https://github.com/planarnetwork/transxchange2gtfs)
* [dtd2mysql](https://github.com/open-track/dtd2mysql)
* [OpenTripPlanner](http://www.opentripplanner.org/)
* functions `otpConnect()`, `otpTripTime()`, `otpTripDistance()`, `otpIsochrone()` are modified from Marcus Young's repo [here](https://github.com/marcusyoung/opentripplanner/blob/master/Rscripts/otp-api-fn.R)

<a id="licence"> </a>

## Licence

The Open Government Licence (OGL) Version 3

Copyright (c) 2018 Office of National Statistics

This source code is licensed under the Open Government Licence v3.0. To view this licence, visit [www.nationalarchives.gov.uk/doc/open-government-licence/version/3](www.nationalarchives.gov.uk/doc/open-government-licence/version/3) or write to the Information Policy Team, The National Archives, Kew, Richmond, Surrey, TW9 4DU.