# propeR

**prope** [latin] _verb_
**Definitions:**
1. near, nearby;
2. almost;
3. close by

<p align="center"><img align="center" src="proper/meta/logo/propeR_logo_v1.png" width="200px"></p>

## Contents

* [Introduction](#introduction)

* [Software Prerequisites](#software-prerequisites)

* [Installing propeR](#installing-proper)
  * [R installation](#r-installation)
  * [Docker installation](#docker-installation)

* [Running propeR](#running-proper)
  * [Data prerequisites](#data-prerequisites)
  * [Using R](#using-rstudio)
  * [Using Docker](#using-docker)
	* [propeR functions](#proper-functions)
  		* [otpConnect](#otpconnect)
  		* [importLocationData and importGeojsonData](#importlocationdata-and-importgeojsondata)
  		* [pointToPoint](#pointtopoint)
  		* [pointToPointLoop](#pointtopointloop)
  		* [pointToPointNearest](#pointtopointnearest)
  		* [pointToPointTime](#pointtopointtime)
  		* [isochrone](#isochrone)
	  	* [isochroneTime](#isochronetime)
	  	* [isochroneMulti](#isochronemulti)
	  	* [isochroneMultiIntersect](#isochronemultiintersect)
	  	* [isochroneMultiIntersectSensitivity](#isochronemultiintersectsensitivity)
	  	* [isochroneMultiIntersectTime](#isochronemultiintersecttime)
	  	* [choropleth](#choropleth)

* [FAQ](#faq)  

* [Acknowledgments](#acknowledgments)  

* [Contributions and Bug Reports](#contributions-and-bug-reports)  

* [Licence](#licence)  


## Introduction

This R package ([propeR](https://github.com/datasciencecampus/proper)) was created to analyse multimodal transport for a number of research projects at the [Data Science Campus, Office for National Statistics](https://datasciencecampus.ons.gov.uk/). This repository is for the installation and use of propeR only, for all OTP graph related guidance, please see [graphite](https://github.com/datasciencecampus/graphite).

## Software Prerequisites

* R and your GUI of choice, such as RStudio, OR
* Docker

## Installing propeR

### R installation

The easiest method is to install direct from this GitHub repository using:

```
library(devtools)
install_github("datasciencecampus/access-to-services/propeR")
```

Failing this, you can pull this repository and install locally using:

```
install("propeR/dir/here")
```

#### R building

If neither method above works. Or you wish to make changes to the package. Then you will need to build the package. Building propeR requires devtools and roxygen2:

```
# R
install.packages("devtools")
install.packages("roxygen2")
```

Then:

```
build("propeR/dir/here")
install("propeR/dir/here")
```

Once you have installed propeR using RStudio you can now [start using it in RStudio.](#using-rstudio)

### Docker installation

For convenience we have created a [Docker](https://www.docker.com/) image for
the [propeR R package](https://github.com/datasciencecampus/access-to-services/tree/develop/propeR).

The propeR R package can be built from the parent directory as follows:

```
cd to/propeR/dir/
docker build . --tag=dsc_proper
```

Or you can build from the [online docker image](https://hub.docker.com/u/datasciencecampus), using:

```
docker run datasciencecampus/dsc_proper:1.0
```

See [Dockerfile](Dockerfile) for more information and dependencies. Once you have installed propeR using Docker you can now [start using it in Docker.](#using-docker)

## Running propeR

### Data prerequisites

All location data (origin and destination) must be in comma separated (CSV) format and contain the following columns:
* A unique ID column
* A latitude column, where data is in decimal degrees (or a postcode column)
* A longitude column, where data is in decimal degrees (or a postcode column)

The CSV file must contain headers, the header names can be specified in **`importLocationData()`**.

### Using RStudio

The [README](https://github.com/datasciencecampus/propeR/blob/develop/README.md) will provide a guide on how to install propeR. As with any R package, it can be loaded in an R session using:

```
#R
library(propeR)
```

### Using Docker

Alternatively. If you have installed propeR using Docker you can use Docker to run propeR. Put source and destination `.csv` data in a directory, e.g., `/tmp/data/`. Example data files `origin.csv` and `destination.csv` can be found in `propeR/inst/extdata/`, then:

```
docker run -v /tmp/data:/mnt datasciencecampus/dsc_proper:1.0 'otp.host="XXX.XXX.X.X", fun="pointToPoint", src_file="/mnt/origin.csv", dst_file="/mnt/destination.csv", output.dir="/mnt", startDateAndTime="2019-08-02 12:00:00"'
```

where `otp.host` is your inet address, which can be found using:

```
/sbin/ifconfig |grep inet |awk '{print $2}'

```

Output data will be in `tmp/data/`.

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

#### otpConnect

```
#R
otpcon <- otpConnect()
```

This function establishes the connection to the OTP server. You will need to specify these in the parameter fields (i.e. `hostname`, `router`, `port`). See **`?otpConnect`** for more information.

#### importLocationData and importGeojsonData

```
#R
originPoints <- importLocationData('PATH/TO/FILE')
```

This loads csv location data into propeR. Specify the unique ID column header using `idcol=""` (default is 'name'), the latitude column using `latcol=""` (default is 'lat'), the longitude column using `loncol=""` (default is 'lon'), and (if needed) the postcode column using `postcodecol=""` (default is 'postcode').

The propeR package comes with some sample CSV data to be used alongside the OTP graph built using the sample GTFS and .osm files on the [github repo](https://github.com/datasciencecampus/propeR). To load this data, run:

```
#R
originPoints <- importLocationData(system.file("extdata", "origin.csv", package = "propeR"))
destinationPoints <- importLocationData(system.file("extdata", "destination.csv", package = "propeR"))
```

The sample data shows an example of data with a latitude, longitude column (recommended) in the origin CSV file, and one with a postcode column only (works, but not recommended) in the destination CSV file. The **`importLocationData()`** function will call a separate function (`postcodeToDecimalDegrees()`) that converts postcode to latitude and longitude.

**Note:** _the column lat\_lon is generated automatically by `importLocationData()` and does not need to be manually entered._

#### locationValidator

```
#R
pointToPoint(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              locationPoints = originPoints,
              modes = 'WALK')
```

This function checks the validity of the origin and destination points. To do this the function tries to create a small isochrone around the location, and if this cannot be created, it will find the closest routable location and overwrite the latitude and longitude. This will the be saved the specified folder as a new file, which needs to be reloaded into propeR. The function is called using the following:

The above will check the validity of the locations for walking routes, including the use of public transport. To check the validity of the location for driving (e.g., town centres) change `modes` to equal `CAR`.

#### pointToPoint

```
#R
pointToPoint(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              originPointsRow = 2,
              destinationPoints = destinationPoints,
              destinationPointsRow = 2,
              startDateAndTime = '2018-08-18 12:00:00',
              modes = 'WALK, TRANSIT',
              mapOutput = F)
```

The most basic function in propeR is find the journey details for a trip with a single origin and destination.

A csv file with the following headers will be output:

| origin | destination | start\_time | end\_time | distance\_km | duration\_mins | walk_distance\_km | walk\_time_mins | transit_time\_mins | waiting\_time_mins | pre_waiting\_time\_mins | transfers | cost | no\_of\_buses | no\_of\_trains | journey\_details |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

The header walk\_time_mins will become drive\_time_mins or cycle\_time_mins if `modes` is changed to `CAR` or `BICYCLE`, respectively. The column for cost will be 'NA' unless `costEstimate = T` is used. The field waiting\_time_mins provides the total waiting time after the first leg of the journey starts (e.g., the first bus/train journey), the field pre_waiting\_time\_mins provides the time between the given `startDateAndTime` and the first leg of the journey (this cannot exceed the `preWaitTime`).

To output a PNG and interactive HTML leaflet map will as shown below, change the parameter `mapOutput` to `T`. For example:

<p align="center"><img align="center" src="meta/images/pointToPoint.png" width="600px"></p>

A GeoJSON of the polyline can be saved using the parameter `geojsonOutput = T`.

Map colours, zoom and other parameters can be specified by the user. See ?pointToPoint for details.

**Note:** _`preWaitTime` is set by default to 15 minutes, any journey after this will not be deemed suitable. Please change `preWaitTime` value to something more appropriate, if needed._

#### pointToPointLoop

```
#R
pointToPointLoop(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              destinationPoints = destinationPoints,
              journeyLoop = 0,
              startDateAndTime = '2018-08-18 12:00:00',
              modes = 'WALK, TRANSIT')
```

This function works in the similar way to the [`pointToPoint()`](#pointtopoint) function, but instead of a single origin and destination, the function loops through all origins and/or destinations provided.

To loop just through the origins, set `journeyLoop` to `1`, to loop just through the destinations, set `journeyLoop` to `2`, and to loop through both, set `journeyLoop` to `0` (default). If you want to loop through each row of origins and route to the same row in destinations, set `journeyLoop` to `3`. Also, you can calculate return leg journeys by setting `journeyReturn` to `T` (default is `F`).

#### pointToPointNearest

```
#R
pointToPointNearest(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              destinationPoints = destinationPoints,
              journeyReturn = F,
              startDateAndTime = '2018-08-18 12:00:00',
              modes = 'WALK, TRANSIT',
              nearestNum = 1,)
```

This function is useful to analyse the travel details between a destination and origin using a K-nearest neighbour (KNN) approached. It is therefore useful in analysing whether the geographically closest destination (or service) is the fastest and most appropriate for an origin.

By default *k* is set to 1, denoted the geographically closest destination. However, the second, third etc nearest destination can be analysed by changing the parameter `nearestNum`. Like `pointToPointLoop` the parameter `journeyReturn` can be used to specify whether the return journey between origin and destination should be also calculated.

#### pointToPointTime

```
#R
pointToPointTime(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              originPointsRow = 2,
              destinationPoints = destinationPoints,
              destinationPointsRow = 2,
              startDateAndTime = '2018-08-18 12:00:00',
              endDateAndTime = '2018-08-18 13:00:00',
              timeIncrease = 20,
              modes = 'WALK, TRANSIT',
              mapOutput = F)
```

This function works in the similar way to the [`pointToPoint()`](#pointtopoint) function, but instead of a single `startDateAndTime`, an `endDateAndTime` and `timeIncrease` (the incremental increase in time between `startDateAndTime` and `endDateAndTime` journeys should be analysed for) can be stated.

Changing `mapOutput` to `T` will save a map for each journey. To save a GIF of the time-series, set `gifOutput` to `T`. For example:

<p align="center"><img align="center" src="meta/images/pointToPointTime.gif" width="600px"></p>

**Note:** _if left to the default mapZoom tries to set the zoom to the bounding box (`'bb'`) of the origin and destination locations, and the polyline created from the first API call; however, if the first call returns no journey, the map zoom level may not be appropriately set. If this is the case, you may need to manually enter an appropriate mapZoom number (e.g. `mapZoom = 12`)._

#### isochrone

```
#R
isochrone(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              originPointsRow = 2,
              destinationPoints = destinationPoints,
              startDateAndTime  = '2018-08-18 12:00:00',
              modes = 'WALK, TRANSIT',
              isochroneCutOffMax = 90,
              isochroneCutOffMin = 30,
              isochroneCutOffStep = 30,
              mapOutput = F,
              geojsonOutput = F)
```

Instead of a single origin to a single destination, the isochrone function works by taking a single origin and computing the maximum distance from this origin within specified cutoff times. This means that the travel time to multiple destinations can be analysed through a single OTP API call.

A tabular output will show the travel time (in minutes) for each destination by appending the travel time to the destination from the origin to the original destination csv file. This is then saved to the specified `output.dir`.

A map can also be saved by usingn `mapOutput = T`). For example:

<p align="center"><img align="center" src="meta/images/isochrone.png" width="600px"></p>

To save the polygon as a .GeoJSON file into the output folder, change `geojsonOutput` to `T`.

#### isochroneTime

```
#R
isochroneTime(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              originPointsRow = 2,
              destinationPoints = destinationPoints,
              startDateAndTime = '2018-08-18 12:00:00',
              endDateAndTime = '2018-08-18 13:00:00',
              timeIncrease = 20,
              isochroneCutOffMax = 90,
              isochroneCutOffMin = 30,
              isochroneCutOffStep = 30,
              modes = 'WALK, TRANSIT',
              mapOutput = F)
```

This function is to [`isochrone()`](#isochrone) what [`pointToPointTime()`](#pointtopointtime) was to [`pointToPoint()`](#pointtopoint), i.e., a time-series between a start and end time/date at specified time intervals that produces a table and an optional animated GIF image.

Changing `mapOutput` to `T` will save a map for each journey. To save a GIF of the time-series, set `gifOutput` to `T`. For example:

<p align="center"><img align="center" src="meta/images/isochroneTime.gif" width="600px"></p>

**Note:** _if left to the default mapZoom tries to set the zoom to the bounding box (`'bb'`) of the origin and destination locations, and the polygon created from the first API call; however, if the first call returns no journey, the map zoom level may not be appropriately set. If this is the case, you may need to manually enter an appropriate mapZoom number (e.g. `mapZoom = 12`)._

#### 3.2.7. isochroneMulti

```
#R
isochroneMulti(output.dir = 'PATH/TO/DIR',
              otpcon = otpcon,
              originPoints = originPoints,
              destinationPoints = destinationPoints,
              startDateAndTime  = '2018-08-18 12:00:00',
              modes = 'WALK, TRANSIT',
              isochroneCutOffMax = 90,
              isochroneCutOffMin = 30,
              isochroneCutOffStep = 30,
              mapOutput = F,
              geojsonOutput = F)
```

This function works similarly to the [`isochrone()`](#isochrone) function; however, it can handle multiple origins and multiple destinations. This is useful when considering the travel time between multiple locations to multiple possible destinations.

A PNG and interactive HTML map can also be saved in the output directory by changing `mapOutput` to `T`. For example:

<p align="center"><img align="center" src="meta/images/isochroneMulti.png" width="600px"></p>

In addition, the polygons can be saved as a single .GeoJSON file by changing `geojsonOutput` to `T`.

```
#R
library(propeR)
```

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

## Acknowledgments

* [TransXChange2GTFS](https://github.com/danbillingsley/TransXChange2GTFS)
* [transxchange2gtfs](https://github.com/planarnetwork/transxchange2gtfs)
* [dtd2mysql](https://github.com/open-track/dtd2mysql)
* [OpenTripPlanner](http://www.opentripplanner.org/)
* functions `otpConnect()`, `otpTripTime()`, `otpTripDistance()`, `otpIsochrone()` are modified from Marcus Young's repo [here](https://github.com/marcusyoung/opentripplanner/blob/master/Rscripts/otp-api-fn.R)

## Contributions and Bug Reports

We welcome contributions and bug reports. Please do this on this repo and we will endeavour to review pull requests and fix bugs in a prompt manner.

## Licence

The Open Government Licence (OGL) Version 3

Copyright (c) 2018 Office of National Statistics

This source code is licensed under the Open Government Licence v3.0. To view this licence, visit [www.nationalarchives.gov.uk/doc/open-government-licence/version/3](www.nationalarchives.gov.uk/doc/open-government-licence/version/3) or write to the Information Policy Team, The National Archives, Kew, Richmond, Surrey, TW9 4DU.
