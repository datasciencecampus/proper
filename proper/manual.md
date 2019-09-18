# propeR manual

<p align="center"><img align="center" src="meta/logo/propeR_logo_v1.png" width="200px"></p>

## Contents

* [Introduction](#introduction)
* [GTFS feed](#gtfs-feed)
  	* [Creating a GTFS feed](#creating-a-gtfs-feed)
  	* [TransXChange to GTFS](#transxchange-to-gtfs)
  		* [TransXChange2GTFS by danbillingsley](transxchange2gtfs-by-danbillingsley)
  		* [transxchange2gtfs by planar network](transxchange2gtfs-by-planar-network)
  	* [CIF to GTFS](#cif-to-gtfs)
  	* [Cleaning the GTFS data](#cleaning-the-gtfs-data)
  	* [Sample GTFS data](#˜sample-gtfs-data)  

* [Creating and running an OpenTripPlanner server](#creating-and-running-an-opentripplanner-server)
	* [Java method](#java-method)
  * [Docker method](#docker-method)

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

4. [FAQ](#faq)    

## Introduction

This R package (propeR) was created to analyse multimodal transport for a number of research projects at the [Data Science Campus, Office for National Statistics](https://datasciencecampus.ons.gov.uk/).

## GTFS feed

propeR can be used without a General Transit Feed Specification (GTFS)](https://en.wikipedia.org/wiki/General_Transit_Feed_Specification) dataset. However, a GTFS feed is required to analyse public transport. Without it you can analyse car, bicycle, and foot transport using OpenStreetMap (OSM) data.

Understanding the complete UK transit network relies on the knowledge and software that can parse various other transit feeds such as bus data, provided in [TransXChange](https://www.gov.uk/government/collections/transxchange) format, and train data, provided in [CIF](https://www.raildeliverygroup.com/our-services/rail-data/timetable-data.html) format.

The initial tasks was to convert these formats to GTFS. The team indentified two viable converters: (i) C# based [TransXChange2GTFS](https://github.com/danbillingsley/TransXChange2GTFS) to convert TransXChange data; and (ii) sql based [dtd2mysql](https://github.com/open-track/dtd2mysql) to convert CIF data. The [TransXChange2GTFS](https://github.com/danbillingsley/TransXChange2GTFS) code was modified by the Campus and pushed back (successfully) to the original repository. The team behind [dtd2mysql](https://github.com/open-track/dtd2mysql), [planar network](https://planar.network/), have since created their own [TransXChange to GTFS converter](https://github.com/planarnetwork/transxchange2gtfs), which does not require a C# compiler.

Below is a more detailed set-by-step guide on how these converters are used.

### Creating a GTFS feed

A [GTFS](https://en.wikipedia.org/wiki/General_Transit_Feed_Specification) folder typically comprises the following files:

| Filename  | Description | Required? |
|---------------|-------------------------- |:---------:|
| agency.txt  | Contains information about the service operator | Yes |
| stops.txt | Contains details of each stop in the timetables provided  | Yes |
| routes.txt  | Contains information about the route  | Yes |
| trips.txt | Contains information about each trip on a route and service | Yes |
| stop_times.txt  | Contains the start and end times for stops on a journey | Yes |
| calendar.txt  | The start and end dates of journeys | Yes |
| calendar_dates.txt  | Shows exceptions for journeys for holidays etc  | Optional  |
| fare_attributes.txt | Contains information about journey fares  | Optional  |
| fare_rules.txt  | Assigns fares to certain journeys | Optional  |
| transfers.txt | Transfer type and time between stops  | Optional  |

Transport network models such as [OpenTripPlanner (OTP)](http://www.opentripplanner.org/) require a ZIP folder of these files.

#### TransXChange to GTFS

UK bus data in [TransXChange](https://www.gov.uk/government/collections/transxchange) format can be downloaded from [here](ftp://ftp.tnds.basemap.co.uk/) following the creation of an account at the Traveline website, [here](https://www.travelinedata.org.uk/traveline-open-data/traveline-national-dataset/). The data is catergorised by region. For our work, we downloaded the Wales (W) data. The data will be contained within a series of [XML](https://en.wikipedia.org/wiki/XML) files for each bus journey. For example, here is a snippet of the `CardiffBus28-CityCentre-CityCentre6_TXC_2018803-1215_CBAO028A.xml`:

```
<?xml version="1.0" encoding="utf-8"?>
<TransXChange xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsi:schemaLocation="http://www.transxchange.org.uk/ http://www.transxchange.org.uk/schema/2.1/TransXChange_general.xsd" CreationDateTime="2018-08-03T12:15:26" ModificationDateTime="2018-08-03T12:15:26" Modification="revise" RevisionNumber="1" FileName="CardiffBus28-CityCentre-CityCentre6_TXC_2018803-1215_CBAO028A.xml" SchemaVersion="2.1" RegistrationDocument="false" xmlns="http://www.transxchange.org.uk/">
  <ServicedOrganisations>
    <ServicedOrganisation>
      <OrganisationCode>CDS</OrganisationCode>
      <Name>Cardiff</Name>
      <WorkingDays>
```

##### TransXChange2GTFS by danbillingsley

Initially, we used [TransXChange2GTFS](https://github.com/danbillingsley/TransXChange2GTFS) to convert the TransXChange files into GTFS format. TransXChange is a C# tool. Our method to convert the data was:

1. Place the XML files in the 'dir/input' folder.
2. Run the Program.cs file (i.e., `dotnet run Program.cs`).
3. The GTFS txt files will be created in the 'dir/output' folder.
4. Compress the txt files to a ZIP folder with an appropriate name (e.g., 'bus_GTFS.zip').

##### transxchange2gtfs by planar network

The team, [planar network](https://planar.network/), who we initially used to convert the UK train data to GTFS, have created a TypeScript TransXChange to GTFS converter, [transxchange2gtfs](https://github.com/planarnetwork/transxchange2gtfs). Their GitHub page provides good detailed instructions to installing and converting the files. The method we used was:

1. Install the converter as per the GitHub instructions.
3. Run `transxchange2gtfs path/to/GTFS/file.zip gtfs-output.zip` in terminal/command line.

#### CIF to GTFS

As mentioned above, UK train data in CIF format can be downloaded from [here](http://data.atoc.org/data-download) following the creation of an account. The timetable data will download as a zipped folder named 'ttis\*\*\*.zip'.

Inside the zipped folder will be the following files: ttfis\*\*\*.alf, ttfis\*\*\*.dat, ttfis\*\*\*.flf, ttfis\*\*\*.mca, ttfis\*\*\*.msn, ttfis\*\*\*.set, ttfis\*\*\*.tsi, and ttfis\*\*\*.ztr. Most of these files are difficult to read, hence the need for GTFS.

We used the sql tool [dtd2mysql](https://github.com/open-track/dtd2mysql) created by [planar network](https://planar.network/) to convert the files into a SQL database, then into the GTFS format. The [dtd2mysql github](https://github.com/open-track/dtd2mysql) page gives a guide on how to convert the data. This method used here was:

1. Create a sql database with an appropriate name (e.g., 'train_database'). Note, this is easiest done under the root username with no password.
2. Run the following in a new terminal/command line window within an appropriate directory:
```
DATABASE_USERNAME=root DATABASE_NAME=train_database dtd2mysql --timetable /path/to/ttisxxx.ZIP
```
3. Run the following to download the GTFS files into the root directory:
```
DATABASE_USERNAME=root DATABASE_NAME=train_database dtd2mysql --gtfs-zip train_GTFS.zip
```
4. As [OpenTripPlanner (OTP)](http://www.opentripplanner.org/) requires GTFS files to not be stored in subfolders in the GTFS zip file, extract the downloaded 'train_GTFS.zip' and navigate to the subfolder level where the txt files are kept, then zip these files to a folder with an appropriate name (e.g., 'train_GTFS.zip').

**Note**: _if you are receiving a 'group_by' error, you will need to temporarily or permenantly disable `'ONLY_FULL_GROUP_BY'` in mysql._

### Cleaning the GTFS Data

The converted GTFS ZIP files may not work directly with [OpenTripPlanner (OTP)](http://www.opentripplanner.org/). Often this is caused by stops within the stop.txt file that are not handled by other parts of the GTFS feed, but there are other issues too, such as latitude and longitudes of stops being assigned to 0. In propeR we have created a function called `cleanGTFS()` to clean and preprocess the GTFS files. To run:

```
#R
library(propeR)
cleanGTFS(gtfs.dir, gtfs.filename)
```

Where `gtfs.dir` is the directory where the GTFS ZIP folder is located, and `gtfs.filename` is the filename of the GTFS feed. This will create a new, cleaned GTFS ZIP folder in the same location as the old ZIP folder, but with the suffix '\_new'. Run this function for each GTFS feed.

### Sample GTFS data

The Data Science Campus has created some cleaned GTFS data from March 2019 (using the steps above) for:

* buses in Cardiff, Wales, UK. [Download, 1.7MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/cardiff_bus/Cardiff-gtfs.zip) 
* buses in Wales, UK. [Download, 22.3MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/wales_bus/W_GTFS.zip) 
* buses in Scotland, UK. [Download, 34.6MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/scotland_bus/S_GTFS.zip) 
* buses in East Anglia, England, UK. [Download, 3.5MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/EA_GTFS.zip) 
* buses in East Midlands, England, UK. [Download, 28.0MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/EM_GTFS.zip) 
* buses in Greater London, England, UK. [Download, 99.8MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/L_GTFS.zip) 
* buses in the North East, England, UK. [Download, 43,4MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/NE_GTFS.zip) 
* buses in the North West, England, UK. [Download, 34.1MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/NW_GTFS.zip) 
* buses in the South East, England, UK. [Download, 55.3MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/SE_GTFS.zip) 
* buses in the South West, England, UK. [Download, 26.7MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/SW_GTFS.zip) 
* buses in the West Midlands, England, UK. [Download, 25.5MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/WM_GTFS.zip) 
* buses in Yorkshire, England, UK. [Download, 29.2MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/england_bus/Y_GTFS.zip) 
* national coaches in the UK. [Download, 1.2MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/ncsd/NCSD_GTFS.zip) 
* trains in the UK. [Download, 21.4MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/uk_train/train_GTFS.zip) 

The Data Science Campus has also created a bespoke OpenStreetMap (osm) file for Cardiff, Wales, UK for March 2019:

* Cardiff OSM file. [Download, 101.1MB](https://a2s-gtfs.s3.eu-west-2.amazonaws.com/Mar19/cardiff_osm/cardiff.osm) 

**Note**: _these GTFS do not contain the most recent timetables, it is only designed as a practice set of GTFS data for use with the propeR tool. Some (but not most) services have end dates of 2018-08-15, 2018-09-02, 2018-10-31. Therefore, analysing journeys after these dates will not include these services. Most services have an end date capped at 2020-01-01._

## Creating and running an OpenTripPlanner server

### Java method

[OpenTripPlanner (OTP)](http://www.opentripplanner.org/) is an open source multi-modal trip planner, which runs on Linux, Mac, Windows, or potentially any platform with a Java virtual machine. More details, including basic tutorials can be found [here](http://docs.opentripplanner.org/en/latest/). Guidance on how to setup the OpenTripPlanner locally can be found [here](https://github.com/opentripplanner/OpenTripPlanner/wiki). Here is the method that worked for us:

1. Check you have the latest java SE runtime installed on your computer, preferrably the 64-bit version on a 64-bit computer. The reason for this is that the graph building process in step 7 uses a lot of memory. The 32-bit version of java might not allow a sufficient heap size to be allocated to graph and server building. For the GTFS sample data [here](add link), a 32-bit machine may suffice.
2. Create an 'otp' folder in a preferred root directory.
3. Download the latest single stand-alone runnable .jar file of OpenTripPlanner [here](https://repo1.maven.org/maven2/org/opentripplanner/otp/). Choose the '-shaded.jar' file. Place this in the 'otp' folder.
4. Create a 'graphs' folder in the 'otp' folder.
5. Create a 'default' folder in the 'graphs' folder.
6. Put the GTFS ZIP folder(s) in the 'default' folder along with the latest OpenStreetMap .osm data for your area, found [here](https://download.geofabrik.de/europe/great-britain/wales.html). If you're using the sample GTFS data, an .osm file for Cardiff can be found [here](https://github.com/datasciencecampus/access-to-services/tree/master/propeR/data/osm).
7. Build the graph by using the following command line/terminal command whilst in the 'otp' folder:

    ```
    java -Xmx4G -jar otp-1.3.0-shaded.jar --build graphs/default
    ```
  changing the shaded.jar file name and end folder name to be the appropriate names for your build. '-Xmx4G' specifies a maximum heap size of 4G memory, graph building may not work with less memory than this.
8. Once the graph has been build you should have a 'Graphs.obj' file in the 'graphs/default' folder. Now initiate the server using the following command from the 'otp' folder:

    ```
    java -Xmx4G -jar otp-1.3.0-shaded.jar --graphs graphs --router default --server
    ```
Again, checking the shaded.jar file and folder names are correct.
9. If successful, the front-end of OTP should be accessible from your browser using [http://localhost:8080/](http://localhost:8080/).

### Docker method

Again for convenience we have created several docker images to run an OTP server. First fire up OTP server (parse `-d` flag to daemonise).

```
docker run -p 8080:8080 datasciencecampus/<docker_image>
```

where `<docker_image>` is:

* `dsc_otp` (graph for Cardiff, Wales, UK from March 2019)
* `dsc_otp_wales_mar19` (graph for Wales, UK from March 2019)
* `dsc_otp_scotland_mar19` (graph for Scotland, UK from March 2019)
* `dsc_otp_england_mar19` (graph for England, UK from March 2019)

A stand-alone OTP server can also be built and deployed in the [otp/](otp/) directory by editing the `Dockerfile` and `build.sh` files.

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

Q: Do I need an OpenStreetMap (.osm) file to run propeR?

>A: Yes, whilst you can build the graph without an .osm file. You will need it to analyse the graph.

Q: Do I need a GTFS file to run propeR?

>A: Only if you want to analyse public transport. Without a GTFS file you can still analyse private transport or walking by setting `modes` to `CAR`, `BICYCLE` or `WALK` in each of the functions.

Q: How accurate is the cost calculation in the point to point functions?

>A: The tool currently cannot ingest fare information. Therefore `costEstimate` can be used in the point to point functions. This provides an *estimate* based on the values given in the parameters `busTicketPrice`, `busTicketPriceMax`, `trainTicketPriceKm` and `trainTicketPriceMin`.

Q: How to I stop propeR printing to the R console:

>A: All functions have a parameter called `infoPrint`. This by default is set to `T`, please set to `F` if you want to prevent console printing.

Q: I found a bug!

>A: Please use the GitHub issues form to provide us with the information ([here](https://github.com/datasciencecampus/access-to-services/issues))

### Common errors

Q: Why am I receiving the following error when running propeR?

```
Error in curl::curl_fetch_memory(url, handle = handle) :
  Failed to connect to localhost port 8080: Connection refused
Called from: curl::curl_fetch_memory(url, handle = handle)
```

> A: The OTP server has not been initiated. Please see [step 2.](#creating-the-opentripplanner-server) of this guide.

Q: Why am I receiving the following error when running propeR?

```
Error in paste0(otpcon, "/plan") : object 'otpcon' not found
```

> A: The OTP connection has not been established. Please see [step 3.2.1.](#otpconnect) of this guide.
