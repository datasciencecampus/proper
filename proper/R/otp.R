# note: this is mainly based on code from Marcus Young:
# https://github.com/marcusyoung/opentripplanner/blob/master/Rscripts/otp-api-fn.R
# (pull request submitted)

##' Get OTP connection URL
##'
##' Connects to the OpenTripPlanner (OTP) server URL
##'
##' @param hostname defaults to 'localhost'
##' @param router defaults to 'default'
##' @param port defaults to 8080
##' @param ssl defaults to FALSE
##' @return The OTP server URL as https://hostname:port/otp/routers/router or http://hostname:port/otp/routers/router
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   otpcon <- otpConnect(
##'     hostname = "localhost",
##'     router = "default",
##'     port = "8080",
##'     ssl = "false"
##'   )
##' }
##' @export
otpConnect <-
  function(hostname = 'localhost',
           router = 'default',
           p = TRUE,
           port = '8080',
           ssl = FALSE)  {
    return (paste0(
      ifelse(ssl, "https://", "http://"),
      hostname,
      ifelse(p, paste0(":",port,'/'),'/'),
      "otp/routers/",
      router
    ))
  }

##' Returns trip distance from OTP
##'
##' Returns trip distance. The parameters are: from, to and transport mode(s).
##' @param otpcon OTP router URL
##' @param from 'lat, lon' decimal degrees
##' @param to 'lat, lon' decimal degrees
##' @param modes defaults to 'TRANSIT, WALK'
##' @return A list comprising status and distance (in meters)
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   result <- otpTripDistance(
##'     otpcon,
##'     from = "51.5128,-3.2347",
##'     to = "51.4779, -3.1830",
##'     modes = "WALK, TRANSIT"
##'     )
##' }
##' @export
otpTripDistance <- function(otpcon,
                            from,
                            to,
                            modes = 'WALK,TRANSIT') {
  # convert modes string to uppercase - expected by OTP
  modes <- toupper(modes)
  
  # setup router URL with /plan
  routerUrl <- paste0(otpcon, '/plan')
  
  # set parameters for query
  params <- list(fromPlace = from,
                 toPlace = to,
                 mode = modes)
  
  # Use GET from the httr package to make API call and place in req - returns json by default
  req <- httr::GET(routerUrl, query = params)
  
  # convert response content into text
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  
  # parse text to json
  asjson <- jsonlite::fromJSON(text)
  
  # Check for errors - if no error object, continue to process content
  if (is.null(asjson$error$id)) {
    # set error.id to OK
    error.id <- "OK"
    if (modes == "CAR") {
      # for car the distance is only recorded in the legs objects. Only one leg should be returned if mode is car and we pick that -  probably need error check for this
      response <-
        list(
          "errorId" = error.id,
          "distance" = asjson$plan$itineraries$legs[[1]]$distance
        )
      return (response)
      # for walk or cycle
    } else {
      response <-
        list("errorId" = error.id,
             "distance" = asjson$plan$itineraries$walkDistance)
      return (response)
    }
  } else {
    # there is an error - return the error code and message
    response <-
      list("errorId" = asjson$error$id,
           "errorMessage" = asjson$error$msg)
    return (response)
  }
}

# Function to make an OTP API lookup and return trip time in simple or detailed form.
# The parameters from, to, modes, date and time must be specified in the function call other
# parameters have defaults set and are optional in the call.

##' Returns trip time from OTP
##'
##' Returns trip time in simple or detailed form. The parameters from, to, modes,
##' date and time must be specified in the function call, other parameters have
##' defaults set and are optional in the call.
##'
##' @param otpcon OTP router URL
##' @param from 'lat, lon' decimal degrees
##' @param to 'lat, lon' decimal degrees
##' @param modes defaults to 'TRANSIT, WALK'
##' @param detail defaults to TRUE
##' @param date 'YYYY-MM-DD' format
##' @param time 12 hour format
##' @param maxWalkDistance in meters, defaults to 800
##' @param walkReluctance defaults to 2 (range 0 - 20)
##' @param arriveBy defaults to FALSE
##' @param transferPenalty defaults to 0
##' @param minTransferTime in minutes, defaults to 1
##' @param walkSpeed in m/s, defaults to 1.4
##' @param bikeSpeed in m/s, defaults to 4.3
##' @param maxTransfers defaults to 10
##' @param wheelchair defaults to FALSE
##' @param preWaitTime in minutes, defaults to 60
##' @return A list comprising status and duration (in minutes) of detail is FALSE, or list comprising status, and itineraries, trip details
##' and polylines dataframes
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   result <- otpTripTime(
##'     otpcon,
##'     from = "51.5128,-3.2347",
##'     to = "51.4779, -3.1830",
##'     modes = "WALK, TRANSIT",
##'     date = "2018-10-01",
##'     time = "08:00am"
##'   )
##' }
##' @export
otpTripTime <- function(otpcon,
                        from_name,
                        from_lat_lon,
                        to_name,
                        to_lat_lon,
                        modes = 'WALK,TRANSIT',
                        detail = TRUE,
                        date,
                        time,
                        maxWalkDistance = 800,
                        walkReluctance = 2,
                        arriveBy = 'false',
                        # todo: this should be a boolean
                        transferPenalty = 0,
                        minTransferTime = 1,
                        walkSpeed = 1.4,
                        bikeSpeed = 4.3,
                        maxTransfers = 10,
                        wheelchair = FALSE,
                        preWaitTime = 60) {
  # convert modes string to uppercase - expected by OTP
  modes <- toupper(modes)
  
  routerUrl <- paste0(otpcon, '/plan')
  
  params <- list(
    fromPlace = from_lat_lon,
    toPlace = to_lat_lon,
    mode = modes,
    date = date,
    time = time,
    maxWalkDistance = maxWalkDistance,
    walkReluctance = walkReluctance,
    arriveBy = arriveBy,
    transferPenalty = transferPenalty,
    minTransferTime = (minTransferTime * 60),
    walkSpeed = walkSpeed,
    bikeSpeed = bikeSpeed,
    maxTransfers = maxTransfers,
    wheelchair = wheelchair
  )
  
  # Use GET from the httr package to make API call and place in req - returns json by default. Not using numItineraries due to odd OTP behaviour - if request only 1 itinerary don't necessarily get the top/best itinerary, sometimes a suboptimal itinerary is returned. OTP will return default number of itineraries depending on mode. This function returns the first of those itineraries.
  req <- httr::GET(routerUrl, query = params)
  
  # convert response content into text
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  
  # parse text to json
  asjson <- jsonlite::fromJSON(text)
  
  # Check for errors - if no error object, continue to process content
  if (is.null(asjson$error$id)) {
    # set error.id to OK
    error.id <- "OK"
    # get first itinerary
    df <- asjson$plan$itineraries[1, ]
    
    #Check if start of journey is within reasonable wait time
    required_start_time <-
      as.POSIXct(paste0(date, " ", format(strptime(time, "%I:%M %p"), format =
                                            "%H:%M:%S")), format = "%Y-%m-%d %H:%M:%S")
    journey_start_time <- df$startTime
    journey_start_time <-
      as.POSIXct(journey_start_time / 1000, origin = "1970-01-01")
    pre_waiting_time <- as.numeric(difftime(journey_start_time, required_start_time, units =
                                              "mins"))
    
    if (pre_waiting_time < as.integer(preWaitTime)) {
      # check if need to return detailed response
      if (detail == TRUE) {
        # need to convert times from epoch format
        df$start <-
          strftime(as.POSIXct(df$startTime / 1000, origin = "1970-01-01"),
                   format = "%H:%M:%S")
        df$end <-
          strftime(as.POSIXct(df$endTime / 1000, origin = "1970-01-01"),
                   format = "%H:%M:%S")
        
        ret.df <-
          subset(
            df,
            select = c(
              'start',
              'end',
              'walkDistance',
              'duration',
              'walkTime',
              'transitTime',
              'waitingTime',
              'transfers'
            )
          )
        
        ret.df$distance_km <- round(sum(df$legs[[1]]$distance) / 1000, digits = 2)
        
        # round walking distance
        ret.df[, 3] <- round(ret.df[, 3] / 1000, digits = 2)
        
        # convert seconds into minutes where applicable
        ret.df[, 4:7] <- round(ret.df[, 4:7] / 60, digits = 2)
        
        # add in name of origin and destination
        ret.df$origin <- from_name
        ret.df$destination <- to_name
        
        ret.df$pre_waiting_time_mins <- round(pre_waiting_time, digits = 2)
        
        ret.df <- ret.df[, c(10, 11, 1, 2, 9, 4, 3, 5, 6, 7, 12, 8)]
        
        colnames(ret.df) <- c(
          "origin",
          "destination",
          "start_time",
          "end_time",
          "distance_km",
          "duration_mins",
          "walk_distance_km",
          "walk_time_mins",
          "transit_time_mins",
          "waiting_time_mins",
          "pre_waiting_time_mins",
          "transfers")
    
        # rename walkTime column as appropriate - this a mistake in OTP
        if (modes == "CAR") {
          names(ret.df)[names(ret.df) == 'walk_time_mins'] <- 'drive_time_mins'
        } else if (modes == "BICYCLE") {
          names(ret.df)[names(ret.df) == 'walk_time_mins'] <- 'cycle_time_mins'
        }
        
        # If legs are null then use the input data to build the dataframe
        if (is.null(df$legs)) {
          df2 <- data.frame(matrix(ncol = 13, nrow = 1))
          df2_col_names <- c(
            "origin",
            "destination",
            "start_time",
            "end_time",
            "distance_km",
            "from_lat",
            "from_lon",
            "to_lat",
            "to_lon",
            "mode",
            "agency_name",
            "route_name",
            "duration_mins"
          )
          
          colnames(df2) <- df2_col_names
          
          df2$origin <- from_name
          df2$destination <- to_name
          df2$start_time <- df$start
          df2$end_time <- df$end
          df2$distance <- round(distm(
            c(
              as.numeric(df2$from_lon),
              as.numeric(df2$from_lat)
            ),
            c(as.numeric(df2$to_lon),
              as.numeric(df2$to_lat)),
            fun = distHaversine
          ) / 1000, digits = 2)
          df2$from_lat <- gsub(",.*$", "", from)
          df2$from_lon <- sub('.*,\\s*', '', from)
          df2$to_lat <- gsub(",.*$", "", to)
          df2$to_lon <- sub('.*,\\s*', '', to)
          df2$mode <- mode
          df2$agencyName <- mode
          df2$routeShortName <- mode
          df2$duration <- df$duration

        } else {
          df2 <- df$legs[[1]]
          
          df2$startTime <-
            strftime(as.POSIXct(df2$startTime / 1000, origin = "1970-01-01"),
                     format = "%H:%M:%S")
          df2$endTime <-
            strftime(as.POSIXct(df2$endTime / 1000, origin = "1970-01-01"),
                     format = "%H:%M:%S")
          df2$distance <- round(df2$distance, digits = 2)
          df2$duration <- round(df2$duration / 60, digits = 2)
        }
        
        #Constructs dataframe of lats and longs from origin to destination
        output_table_nrow <- nrow(df2)
        output_table_col_names <- c(
          "from",
          "to",
          "start_time",
          "end_time",
          "distance_km",
          "from_lat",
          "from_lon",
          "to_lat",
          "to_lon",
          "mode",
          "agency_name",
          "route_name",
          "duration_mins"
        )
        
        output_table <-
          data.frame(matrix(ncol = 13, nrow = output_table_nrow))
        colnames(output_table) <- output_table_col_names
        
        for (i in 1:output_table_nrow) {
          
          if (i == 1){
            output_table$from[i] <- paste0(from_name, " (origin)")
          } else {
            output_table$from[i] <- df2$from$name[i]
          }
          
          if (i == output_table_nrow){
            output_table$to[i] <- paste0(to_name, " (destination)")
          } else {
            output_table$to[i] <- df2$from$name[i+1]
          }
          
          output_table$start_time[i] <- df2$startTime[i]
          output_table$end_time[i] <- df2$endTime[i]
          output_table$distance_km[i] <- df2$distance[i] / 1000
          output_table$from_lat[i] <- df2$from$lat[i]
          output_table$from_lon[i] <- df2$from$lon[i]
          output_table$to_lat[i] <- df2$to$lat[i]
          output_table$to_lon[i] <- df2$to$lon[i]
          output_table$mode[i] <- df2$mode[i]
          if (df2$mode[i] == 'CAR' ||
              df2$mode[i] == 'WALK' ||
              df2$mode[i] == 'BICYCLE' || df2$mode[i] == 'BICYCLE,WALK') {
            output_table$agency_name[i] <- df2$mode[i]
            output_table$route_name[i] <- df2$mode[i]
          } else {
            output_table$agency_name[i] <- df2$agencyName[i]
            output_table$route_name[i] <- df2$routeShortName[i]
          }
          output_table$duration_mins[i] <- df2$duration[i]
        }
        
        output_table$from <-
          sub('[.]',
              '_',
              make.names(output_table$from, unique = TRUE)) # Makes sure there are no duplicates in names
        
        output_table$to <-
          sub('[.]',
              '_',
              make.names(output_table$to, unique = TRUE)) # Makes sure there are no duplicates in names
        
        for (i in 1:length(asjson[["plan"]][["itineraries"]][["legs"]][[1]][["legGeometry"]][["points"]])) {
          if (i == 1) {
            detailed_points <-
              gepaf::decodePolyline(asjson[["plan"]][["itineraries"]][["legs"]][[1]][["legGeometry"]][["points"]][[i]])
            for (n in 1:nrow(detailed_points)) {
              if (n < nrow(detailed_points)) {
                detailed_points[n, "to_lat"] <- detailed_points[n + 1, "lat"]
                detailed_points[n, "to_lon"] <-
                  detailed_points[n + 1, "lon"]
              }
              detailed_points[n, "mode"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["mode"]][[i]]
              detailed_points[n, "route"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["route"]][[i]]
              detailed_points[n, "distance"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["distance"]][[i]]
              detailed_points[n, "duration"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["duration"]][[i]]
              if (detailed_points[n, "mode"] == 'CAR' ||
                  detailed_points[n, "mode"] == 'WALK' ||
                  detailed_points[n, "mode"] == 'BICYCLE') {
                detailed_points[n, "agencyName"] <- detailed_points[n, "mode"]
              } else {
                detailed_points[n, "agencyName"] <-
                  asjson[["plan"]][["itineraries"]][["legs"]][[1]][["agencyName"]][[i]]
              }
            }
            
          } else {
            detailed_points_tmp <-
              gepaf::decodePolyline(asjson[["plan"]][["itineraries"]][["legs"]][[1]][["legGeometry"]][["points"]][[i]])
            for (n in 1:nrow(detailed_points_tmp)) {
              if (n < nrow(detailed_points_tmp)) {
                detailed_points_tmp[n, "to_lat"] <- detailed_points_tmp[n + 1, "lat"]
                detailed_points_tmp[n, "to_lon"] <-
                  detailed_points_tmp[n + 1, "lon"]
              }
              detailed_points_tmp[n, "mode"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["mode"]][[i]]
              detailed_points_tmp[n, "route"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["route"]][[i]]
              detailed_points_tmp[n, "distance"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["distance"]][[i]]
              detailed_points_tmp[n, "duration"] <-
                asjson[["plan"]][["itineraries"]][["legs"]][[1]][["duration"]][[i]]
              if (detailed_points_tmp[n, "mode"] == 'CAR' ||
                  detailed_points_tmp[n, "mode"] == 'WALK' ||
                  detailed_points_tmp[n, "mode"] == 'BICYCLE') {
                detailed_points_tmp[n, "agencyName"] <-
                  detailed_points_tmp[n, "mode"]
              } else {
                detailed_points_tmp[n, "agencyName"] <-
                  asjson[["plan"]][["itineraries"]][["legs"]][[1]][["agencyName"]][[i]]
              }
            }
            detailed_points <-
              rbind(detailed_points, detailed_points_tmp)
          }
        }
        
        detailed_points <- as.data.frame(detailed_points)
        detailed_points <-
          detailed_points[!is.na(detailed_points$to_lat), ]
        detailed_points["name"] <-
          paste0("point", seq(1, nrow(detailed_points)))
        row.names(detailed_points) <- detailed_points$name
        colnames(detailed_points) <-
          c(
            "from_lat",
            "from_lon",
            "to_lat",
            "to_lon",
            "mode",
            "route",
            "distance",
            "duration",
            "agencyName",
            "name"
          )
        
        #Constructs a SpatialLinesDataFrame to be handled by the addPolylines function (without it colors don't work properly)
        poly_lines <-
          apply(detailed_points, 1, function(x) {
            points <- data.frame(
              lng = as.numeric(c(x["from_lon"],
                                 x["to_lon"])),
              lat = as.numeric(c(x["from_lat"],
                                 x["to_lat"])),
              stringsAsFactors = F
            )
            sp::coordinates(points) <- c("lng", "lat")
            sp::Lines(sp::Line(points), ID = x["name"])
          })
        
        row.names(output_table) <- output_table$name
        
        poly_lines <-
          sp::SpatialLinesDataFrame(sp::SpatialLines(poly_lines), detailed_points)
        sp::proj4string(poly_lines) <- sp::CRS("+init=epsg:4326")
        
        # Output the response
        response <-
          list(
            "errorId" = error.id,
            "itineraries" = ret.df,
            "trip_details" = df2,
            "output_table" = output_table,
            "poly_lines" = poly_lines,
            "detailed_points" = detailed_points
          )
        return (response)
      } else {
        # detail not needed - just return travel time in minutes
        response <-
          list("errorId" = error.id,
               "duration" = df$duration / 60)
        return (response)
      }
    } else {
      # there is no reasonable journey in a reasonable time
      response <-
        list("errorId" = 200,
             "errorMessage" = 'Outside preWaitTime')
      return (response)
    }
  } else {
    # there is an error - return the error code and message
    response <-
      list("errorId" = asjson$error$id,
           "errorMessage" = asjson$error$msg)
    return (response)
  }
}

##' Returns trip details for choropleth analysis
##'
##' A light version of the OtpTripTime function designed to work for the choropleth
##' analysis
##'
##' @param otpcon OTP router URL
##' @param from 'lat, lon' decimal degrees
##' @param to 'lat, lon' decimal degrees
##' @param modes defaults to 'TRANSIT, WALK'
##' @param detail defaults to TRUE
##' @param date 'YYYY-MM-DD' format
##' @param time 12 hour format
##' @param maxWalkDistance in meters, defaults to 800
##' @param walkReluctance defaults to 2 (range 0 - 20)
##' @param arriveBy defaults to FALSE
##' @param transferPenalty defaults to 0
##' @param minTransferTime in minutes, defaults to 1
##' @param walkSpeed in m/s, defaults to 1.4
##' @param bikeSpeed in m/s, defaults to 4.3
##' @param maxTransfers defaults to 10
##' @param wheelchair defaults to FALSE
##' @return A list comprising status and journey itineraries (duration, walk time, transit time, waiting time and transfers)
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   result <- otpChoropleth(
##'     otpcon,
##'     from = "51.5128,-3.2347",
##'     to = "51.4779, -3.1830",
##'     modes = "WALK, TRANSIT",
##'     date = "2018-10-01",
##'     time = "08:00am"
##'   )
##' }
##' @export
otpChoropleth <- function(otpcon,
                          from,
                          to,
                          modes,
                          detail = TRUE,
                          date,
                          time,
                          maxWalkDistance = 800,
                          walkReluctance = 2,
                          arriveBy = FALSE,
                          transferPenalty = 0,
                          minTransferTime = 1,
                          walkSpeed = 1.4,
                          bikeSpeed = 4.3,
                          maxTransfers = 10,
                          wheelchair = FALSE) {
  # convert modes string to uppercase - expected by OTP
  modes <- toupper(modes)
  
  routerUrl <- paste0(otpcon, '/plan')
  
  params = list(
    fromPlace = from,
    toPlace = to,
    mode = modes,
    date = date,
    time = time,
    maxWalkDistance = maxWalkDistance,
    walkReluctance = walkReluctance,
    arriveBy = arriveBy,
    transferPenalty = transferPenalty,
    minTransferTime = (minTransferTime * 60),
    walkSpeed = walkSpeed,
    bikeSpeed = bikeSpeed,
    maxTransfers = maxTransfers,
    wheelchair = wheelchair
  )
  
  # Use GET from the httr package to make API call and place in req - returns json by default. Not using numItineraries due to odd OTP behaviour - if request only 1 itinerary don't necessarily get the top/best itinerary, sometimes a suboptimal itinerary is returned. OTP will return default number of itineraries depending on mode. This function returns the first of those itineraries.
  req <- httr::GET(routerUrl, query = params)
  
  # convert response content into text
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  
  # parse text to json
  asjson <- jsonlite::fromJSON(text)
  
  # Check for errors - if no error object, continue to process content
  if (is.null(asjson$error$id)) {
    # set error.id to OK
    error.id <- "OK"
    # get first itinerary
    df <- asjson$plan$itineraries[1, ]
    # check if need to return detailed response
    if (detail == TRUE) {
      # need to convert times from epoch format
      df$start <-
        strftime(as.POSIXct(df$startTime / 1000, origin = "1970-01-01"),
                 format = "%H:%M:%S")
      df$end <-
        strftime(as.POSIXct(df$endTime / 1000, origin = "1970-01-01"),
                 format = "%H:%M:%S")
      
      # subset the dataframe ready to return
      ret.df <-
        subset(
          df,
          select = c(
            'start',
            'end',
            'duration',
            'walkTime',
            'transitTime',
            'waitingTime',
            'transfers'
          )
        )
      
      # convert seconds into minutes where applicable
      ret.df[, 3:6] <- round(ret.df[, 3:6] / 60, digits = 2)
      # rename walkTime column as appropriate - this a mistake in OTP
      if (modes == "CAR") {
        names(ret.df)[names(ret.df) == 'walkTime'] <- 'driveTime'
      } else if (modes == "BICYCLE") {
        names(ret.df)[names(ret.df) == 'walkTime'] <- 'cycleTime'
      }
      
      # Output the response
      
      response <-
        list("errorId" = error.id, "itineraries" = ret.df)
      return (response)
    } else {
      # detail not needed - just return travel time in minutes
      response <-
        list("errorId" = error.id,
             "duration" = df$duration / 60)
      return (response)
    }
  } else {
    # there is an error - return the error code and message
    response <-
      list("errorId" = asjson$error$id,
           "errorMessage" = asjson$error$msg)
    return (response)
  }
}

##' Return isochrone from OTP
##'
##' Returns an isochrone from OTP for a specified maximum duration and cutoff intervals based on the origin(s) location(s)
##'
##' @param otpcon OTP router URL
##' @param from 'lat, lon' decimal degrees
##' @param modes defaults to 'TRANSIT, WALK'
##' @param cutoff list in minutes, defaults to c(30,60,90)
##' @param batch defaults to TRUE
##' @param date 'YYYY-MM-DD' format
##' @param time 12 hour format
##' @param maxWalkDistance in meters, defaults to 800
##' @param walkReluctance defaults to 2 (range 0 - 20)
##' @param walkSpeed in m/s, defaults to 1.4
##' @param bikeSpeed in m/s, defaults to 4.3
##' @param minTransferTime in minutes, defaults to 1
##' @param maxTransfers defaults to 10
##' @param wheelchair defaults to FALSE
##' @param arriveBy defaults to FALSE
##' @return A list comprising status and isochrones as a text object
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   result <- otpChoropleth(
##'     otpcon,
##'     from = "51.5128,-3.2347",
##'     modes = "WALK, TRANSIT",
##'     date = "2018-10-01",
##'     time = "08:00am"
##'   )
##' }
##' @export
otpIsochrone <- function(otpcon,
                         from,
                         to,
                         modes,
                         cutoff = c(30, 60, 90),
                         batch = TRUE,
                         date,
                         time,
                         maxWalkDistance = 800,
                         walkReluctance = 2,
                         walkSpeed = 1.4,
                         bikeSpeed = 4.3,
                         minTransferTime = 1,
                         maxTransfers = 10,
                         wheelchair = FALSE,
                         arriveBy = FALSE) {
  # convert modes string to uppercase - expected by OTP
  modes <- toupper(modes)
  
  routerUrl <- paste0(otpcon, "/isochrone")
  
  # todo: should just pass these from ... args
  params <- list(
    fromPlace = from,
    toPlace = to,
    mode = modes,
    batch = batch,
    date = date,
    time = time,
    maxWalkDistance = maxWalkDistance,
    walkReluctance = walkReluctance,
    walkSpeed = walkSpeed,
    bikeSpeed = bikeSpeed,
    minTransferTime = (minTransferTime * 60),
    maxTransfers = maxTransfers,
    wheelchair = wheelchair,
    arriveBy = arriveBy
  )
  
  # api accepts multiple cutoffSec args:
  # http://docs.opentripplanner.org/en/latest/Intermediate-Tutorial/#calculating-travel-time-isochrones
  params <-
    append(params, as.list(setNames(cutoff * 60, rep(
      "cutoffSec", length(cutoff)
    ))))
  
  # Use GET from the httr package to make API call and place in req - returns json by default
  req <- httr::GET(routerUrl, query = params)
  
  # convert response content into text
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  
  # Check that geojson is returned
  if (grepl("\"type\":\"FeatureCollection\"", text)) {
    status <- "OK"
  } else {
    status <- "ERROR"
  }
  
  return (list(status = status, response = text))
}

##' Returns is journey is possible from OTP
##'
##' Returns if journey is possible.
##'
##' @param otpcon OTP router URL
##' @param from 'lat, lon' decimal degrees
##' @param to 'lat, lon' decimal degrees
##' @param modes defaults to 'TRANSIT, WALK'
##' @param date 'YYYY-MM-DD' format
##' @param time 12 hour format
##' @param maxWalkDistance in meters, defaults to 800
##' @param walkReluctance defaults to 2 (range 0 - 20)
##' @param arriveBy defaults to FALSE
##' @param transferPenalty defaults to 0
##' @param minTransferTime in minutes, defaults to 1
##' @param walkSpeed in m/s, defaults to 1.4
##' @param bikeSpeed in m/s, defaults to 4.3
##' @param maxTransfers defaults to 10
##' @param wheelchair defaults to FALSE
##' @param preWaitTime in minutes, defaults to 60
##' @return A list comprising status and duration (in minutes) of detail is FALSE, or list comprising status, and itineraries, trip details
##' and polylines dataframes
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   result <- otpJourneyChecker(
##'     otpcon,
##'     from = "51.5128,-3.2347",
##'     to = "51.4779, -3.1830",
##'     modes = "WALK, TRANSIT",
##'     date = "2018-10-01",
##'     time = "08:00am"
##'   )
##' }
##' @export
otpJourneyChecker <- function(otpcon,
                        from_name,
                        from_lat_lon,
                        to_name,
                        to_lat_lon,
                        modes = 'WALK',
                        date,
                        time,
                        maxWalkDistance = 800,
                        walkReluctance = 2,
                        arriveBy = 'false',
                        # todo: this should be a boolean
                        transferPenalty = 0,
                        minTransferTime = 1,
                        walkSpeed = 1.4,
                        bikeSpeed = 4.3,
                        maxTransfers = 10,
                        wheelchair = FALSE) {
  # convert modes string to uppercase - expected by OTP
  modes <- toupper(modes)
  
  routerUrl <- paste0(otpcon, '/plan')
  
  params <- list(
    fromPlace = from_lat_lon,
    toPlace = to_lat_lon,
    mode = modes,
    date = date,
    time = time,
    maxWalkDistance = maxWalkDistance,
    walkReluctance = walkReluctance,
    arriveBy = arriveBy,
    transferPenalty = transferPenalty,
    minTransferTime = (minTransferTime * 60),
    walkSpeed = walkSpeed,
    bikeSpeed = bikeSpeed,
    maxTransfers = maxTransfers,
    wheelchair = wheelchair
  )
  
  # Use GET from the httr package to make API call and place in req - returns json by default. Not using numItineraries due to odd OTP behaviour - if request only 1 itinerary don't necessarily get the top/best itinerary, sometimes a suboptimal itinerary is returned. OTP will return default number of itineraries depending on mode. This function returns the first of those itineraries.
  req <- httr::GET(routerUrl, query = params)
  
  # convert response content into text
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  
  # parse text to json
  asjson <- jsonlite::fromJSON(text)
  
  # Check for errors - if no error object, continue to process content
  if (is.null(asjson$error$id)) {
      response <- 1
      return (response)
    } else {
      response <- 0
      return (response)
  }
}
