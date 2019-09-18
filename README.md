# propeR

**prope** [latin] _verb_
**Definitions:**
1. near, nearby;
2. almost;
3. close by

<p align="center"><img align="center" src="meta/logo/propeR_logo_v1.png" width="200px"></p>

An R tool for analysing multimodal transport. Requests calls to a [OpenTripPlanner](http://www.opentripplanner.org/) server. For public transport, a GTFS feed is required.

The [propeR manual](https://github.com/datasciencecampus/access-to-services/blob/develop/propeR/manual.md) contains information about how to: create a GTFS feed, setup an OpenTripPlanner (OTP) server, installing and using propeR. There are two options for both install propeR (Rstudio and Docker) and running the OTP server (Java or Docker).

## Software Prerequisites

* GTFS building (optional)
  * A C# compiler such as Visual Studio Code, AND
  * MySQL
* OTP server (required)
  * Java SE Runtime Environment 8 (preferrably 64-bit) [[download here]](https://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html), OR
  * Docker
* propeR (required)
  * R and your GUI of choice, such as RStudio, OR
  * Docker

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
