##' Calculates the journey between for a single origin and destination between a
##' start and end time and date.
##'
##' Calculates the journey time and details between a single origin and destination between a start
##' and end time and date. A comma separated value file of journey details is saved in the output folder.
##' An animated map of the journey can also be saved as a .gif image.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param originPointsRow The row of originPoints to be used, defaults to 1
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param destinationPointsRow The row of destinationPoints to be used, defaults to 1
##' @param startDateAndTime The start time and date, in 'YYYY-MM-DD HH:MM:SS' format, default is currrent date and time
##' @param endDateAndTime The end time and date, in 'YYYY-MM-DD HH:MM:SS' format, default is an hour after the currrent date and time
##' @param timeIncrease The time increase in minutes, default 30
##' @param modes The mode of the journey, defaults to 'TRANSIT, WALK'
##' @param maxWalkDistance The maximum walking distance, in meters, defaults to 1000 m
##' @param walkReluctance The reluctance of walking-based routes, defaults to 2 (range 0 (lowest) - 20 (highest))
##' @param walkSpeed The walking soeed, in meters per second, defaults to 1.4 m/s
##' @param bikeSpeed The cycling speed, in meters per second, defaults to 4.3 m/s
##' @param minTransferTime The maximum transfer time, in minutes, defaults to 0 mins (no time specified)
##' @param maxTransfers The maximum number of transfers, defaults to 10
##' @param wheelchair If TRUE, uses on wheeelchair friendly stops, defaults to FALSE
##' @param arriveBy Selects whether journey starts at startDateandTime (FALSE) or finishes (TRUE), defaults to FALSE
##' @param preWaitTime The maximum waiting time before a journey cannot be found, in minutes, defaults to 15 mins
##' @param estimateCost Specify whether to estimate costs of journey or not (default is False)
##' @param busTicketPrice Specifiy the cost of a bus journey (default is 3 GPB)
##' @param busTicketPriceMax Specifiy the maximum cost of a bus journey (default is 12 GPB)
##' @param trainTicketPriceKm Specifiy the cost of a train journey per km (default is 0.12 GPB per km)
##' @param trainTicketPriceMin Specifiy the minimum cost of a train journey (default is 3 GBP)
##' @param infoPrint Specifies whether you want some information printed to the console or not, default is TRUE
##' @param mapOutput Specifies whether you want to output a map, defaults to FALSE
##' @param gifOutput Specifies whether you want to output an animated gif map, defaults to FALSE
##' @param geojsonOutput Specifies whether you want to output the polylines as a geojson, defaults to FALSE
##' @param mapPolylineColours A list defining the colours to assign to each mode of transport.
##' @param mapZoom The zoom level of the map as an integer (e.g. 12), defaults to bounding box approach
##' @param mapPolylineWeight Specifies the weight of the polyline, defaults to 5 px
##' @param mapPolylineOpacity Specifies the opacity of the polyline, defaults to 1 (solid)
##' @param mapMarkerStrokeColor Specifies the outline color of the marker, defaults to black
##' @param mapMarkerStrokeWeight Specifies the stroke weight of the marker, defaults to 1 (solid)
##' @param mapMarkerOpacity Specifies the opacity of the marker, defaults to 1 (solid)
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 1 (solid)
##' @param mapDarkMode Specifies if you want to use the dark leaflet map colour (default is FALSE)
##' @return Saves journey details as comma separated value file to output directory. An animated map in .gif format may also be saved.
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   pointToPointTime(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     destinationPoints,
##'     startDateAndTime = "2018-08-18 12:00:00",
##'     endDateAndTime = "2018-08-18 13:00:00",
##'     timeIncrease = 60
##'   )
##' }
##' @export
pointToPointTime <- function(output.dir,
                             otpcon = otpcon,
                             originPoints = originPoints,
                             originPointsRow = 1,
                             destinationPoints = destinationPoints,
                             destinationPointsRow = 1,
                             # otpTime args
                             startDateAndTime = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                             endDateAndTime = format(Sys.time() + 1 * 60 * 60, "%Y-%m-%d %H:%M:%S"),
                             timeIncrease = 30,
                             modes = "WALK, TRANSIT",
                             maxWalkDistance = 1000,
                             walkReluctance = 2,
                             walkSpeed = 1.5,
                             bikeSpeed = 5,
                             minTransferTime = 1,
                             maxTransfers = 5,
                             wheelchair = F,
                             arriveBy = F,
                             preWaitTime = 15,
                             estimateCost = F,
                             busTicketPrice = 3,
                             busTicketPriceMax = 12,
                             trainTicketPriceKm = 0.12,
                             trainTicketPriceMin = 3,
                             infoPrint = T,
                             # leaflet map args
                             mapOutput = F,
                             gifOutput = F,
                             geojsonOutput = F,
                             mapPolylineColours = list(
                               TRANSIT = "#000000",
                               WALK = "#A14296",
                               BUS = "#48C1B1",
                               RAIL = "#4D7BC5",
                               CAR = "#8D4084",
                               BICYCLE = "#4AA6C3"
                             ),
                             mapZoom = "bb",
                             mapPolylineWeight = 5,
                             mapPolylineOpacity = 1,
                             mapMarkerStrokeColor = 'black',
                             mapMarkerStrokeWeight = 1,
                             mapMarkerOpacity = 1,
                             mapLegendOpacity = 1,
                             mapDarkMode = F) {
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  origin_points_row_num <- originPointsRow
  from_origin <- originPoints[origin_points_row_num, ]
  if (origin_points_row_num > nrow(originPoints)) {
    stop('Row is not in origin file, process aborted.\n')
  }
  
  destination_points_row_num <- destinationPointsRow
  to_destination <- destinationPoints[destination_points_row_num, ]
  if (destination_points_row_num > nrow(destinationPoints)) {
    stop('Row is not in destination file, process aborted.\n')
  }
  
  start_date <- as.Date(startDateAndTime)
  time_series = seq(as.POSIXct(startDateAndTime), as.POSIXct(endDateAndTime), by = (timeIncrease) * 60) 
  
  file_name <- paste0(from_origin$name,"_",to_destination$name)
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)
  
  unlink(paste0(output.dir, "/pointToPointTime-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/pointToPointTime-", file_name)) 
  dir.create(paste0(output.dir, "/pointToPointTime-", file_name, "/csv")) 
  
  if (gifOutput == T || mapOutput == T) {
    pal_transport <- leaflet::colorFactor(
      palette = unlist(mapPolylineColours, use.names = F),
      # Creating colour palette
      levels = as.factor(names(mapPolylineColours)),
      reverse = F)
    pal_time_date = leaflet::colorFactor(c("#FFFFFF"), domain = NULL)
    if (mapDarkMode == T){
      mapMarkerStrokeColor = 'white'
    }
  }
  
  if (mapOutput == T){
    dir.create(paste0(output.dir, "/pointToPointTime-", file_name, "/map"))
  }
  
  if (gifOutput == T){
    dir.create(paste0(output.dir, "/pointToPointTime-", file_name, "/gif"))
  }
  
  if (geojsonOutput == T){
    dir.create(paste0(output.dir, "/pointToPointTime-", file_name, "/geojson"))
  }
  
  if (infoPrint == T){
    cat("Now running the propeR pointToPointTime tool.\n", sep="")
    cat("Parameters chosen:\n", sep="")
    cat("From: ", from_origin$name, " (", from_origin$lat_lon, ")\n", sep="")
    cat("To: ", to_destination$name, " (", to_destination$lat_lon, ")\n", sep="")
    cat("Date and Time: ", startDateAndTime, " (start) to ", endDateAndTime, " (end)\n", sep="")
    cat("Intervals (mins): ", timeIncrease, "\n", sep="")
    cat("Outputs: CSV [TRUE] Map [", mapOutput, "] GeoJSON [", geojsonOutput, "] GIF [", gifOutput, "]\n\n", sep="")
  }
    
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.start <- 1
  num.end <- length(time_series)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  if (infoPrint == T){
    cat("Creating ", num.total, " point to point connections, please wait...\n", sep="")
  }
  
  make_blank_df <- function(from_origin, to_destination, time_twenty_four) {
    df <- data.frame(
      "origin" = from_origin$name,
      "destination" = to_destination$name,
      "start_time" = time_twenty_four,
      "end_time" = NA,
      "distance_km" = NA,
      "duration_mins" = NA,
      "walk_distance_km" = NA,
      "walk_time_mins" = NA,
      "transit_time_mins" = NA,
      "waiting_time_mins" = NA,
      "pre_waiting_time" = NA,
      "transfers" = NA,
      "cost" = NA,
      "no_of_buses" = NA,
      "no_of_trains" = NA,
      "journey_details" = NA)
    df
  }
  
  if (infoPrint == T){
    pb <- progress::progress_bar$new(
      format = "  Travel time calculation complete for time :what [:bar] :percent eta: :eta",
      total = num.total, clear = FALSE, width= 100)
  }
  
  for (i in num.start:num.end) {
    
    num.run <- num.run + 1
    time <- format(time_series[num.run], "%I:%M %p")
    time_twenty_four <- strftime(as.POSIXct(time_series[i], origin = "1970-01-01"), format = "%H:%M:%S")
    file_name_loop <- paste0(from_origin$name,"_",to_destination$name,"_",gsub("[[:punct:][:blank:]]+", "_", time_series[num.run]))
    date <- as.Date(time_series[num.run])
    
    if (mapOutput == T) { date_time_legend <- format(time_series[num.run], "%d %B %Y %H:%M") }
    
    point_to_point <- propeR::otpTripTime(
      otpcon,
      detail = T,
      from_name = from_origin$name,
      from_lat_lon = from_origin$lat_lon,
      to_name = to_destination$name,
      to_lat_lon = to_destination$lat_lon,
      modes = modes,
      date = date,
      time = time,
      maxWalkDistance = maxWalkDistance,
      walkReluctance = walkReluctance,
      walkSpeed = walkSpeed,
      bikeSpeed = bikeSpeed,
      minTransferTime = minTransferTime,
      maxTransfers = maxTransfers,
      wheelchair = wheelchair,
      arriveBy = arriveBy,
      preWaitTime = preWaitTime
    ) 
    
    point_to_point_table <- point_to_point$output_table
    
    #########################
    #### OPTIONAL EXTRAS ####
    #########################
    
    if (mapOutput == T || geojsonOutput == T || gifOutput == T) {
      if (!is.null(point_to_point_table) && exists("point_to_point_table")) {
        poly_lines <- point_to_point$poly_lines
        poly_lines <- sp::spTransform(poly_lines, sp::CRS("+init=epsg:4326"))
      }
    }
    
    if (mapOutput == T || gifOutput == T) {
      
      if (!is.null(point_to_point_table) && exists("point_to_point_table")) {

        if (num.run == 1) {
          lon.min <- min(min(from_origin$lon),min(to_destination$lon),poly_lines@bbox[1])
          lat.min <- min(min(from_origin$lat),min(to_destination$lat),poly_lines@bbox[2])
          lon.max <- max(max(from_origin$lon),max(to_destination$lon),poly_lines@bbox[3])
          lat.max <- max(max(from_origin$lat),max(to_destination$lat),poly_lines@bbox[4])
        }
        
        m <- leaflet()
        if (mapDarkMode == T) {
          m <- addProviderTiles(m, providers$CartoDB.DarkMatter)
        } else {
          m <- addProviderTiles(m, providers$CartoDB.Positron)
        }        
        m <- addScaleBar(m)
        
        if (is.numeric(mapZoom)){
          m <- setView(
            m,
            lat = (from_origin$lat + to_destination$lat) / 2,
            lng = (from_origin$lon + to_destination$lon) / 2,
            zoom = mapZoom)
        } else {
          m <- fitBounds(
            m,
            lon.min,
            lat.min,
            lon.max,
            lat.max)
        }
        
        m <- addAwesomeMarkers(
            m,
            data = from_origin,
            lat = ~ lat,
            lng = ~ lon,
            popup = ~ name,
            icon = makeAwesomeIcon(
              icon = "hourglass-start",
              markerColor = "red",
              iconColor = "white",
              library = "fa"))
        m <- addPolylines(
            m,
            data = poly_lines,
            color = ~ pal_transport(poly_lines$mode),
            weight = mapPolylineWeight,
            opacity = mapPolylineOpacity)
        m <- addCircleMarkers(
            m,
            data = point_to_point_table,
            lat = ~ from_lat,
            lng = ~ from_lon,
            fillColor = ~ pal_transport(point_to_point_table$mode),
            stroke = T,
            color = mapMarkerStrokeColor,
            weight = mapMarkerStrokeWeight,
            fillOpacity = mapMarkerOpacity,
            popup = ~ mode)
        m <- addLegend(
            m,
            pal = pal_transport,
            values = point_to_point_table$mode,
            opacity = mapLegendOpacity,
            title = "Transport Mode")
        m <- addLegend(
          m,
          pal = pal_time_date,
          values = date_time_legend,
          position = "bottomleft",
          title = "Date and Time")
        m <- addAwesomeMarkers(
            m,
            data = to_destination,
            lat = ~ lat,
            lng = ~ lon,
            popup = ~ name,
            icon = makeAwesomeIcon(
              icon = "hourglass-end",
              markerColor = "blue",
              iconColor = "white",
              library = "fa"))
        
      } else {
        
        if (num.run == 1) {
          lon.min <- min(min(from_origin$lon),min(to_destination$lon))
          lat.min <- min(min(from_origin$lat),min(to_destination$lat))
          lon.max <- max(max(from_origin$lon),max(to_destination$lon))
          lat.max <- max(max(from_origin$lat),max(to_destination$lat))
        }
        
        m <- leaflet()
        if (mapDarkMode == T) {
          m <- addProviderTiles(m, providers$CartoDB.DarkMatter)
        } else {
          m <- addProviderTiles(m, providers$CartoDB.Positron)
        }            
        m <- addScaleBar(m)
        
        if (is.numeric(mapZoom)){
          m <- setView(
            m,
            lat = (from_origin$lat + to_destination$lat) / 2,
            lng = (from_origin$lon + to_destination$lon) / 2,
            zoom = mapZoom)
        } else {
          m <- fitBounds(
            m,
            lon.min,
            lat.min,
            lon.max,
            lat.max)
        }
        
        m <- addAwesomeMarkers(
            m,
            data = from_origin,
            lat = ~ lat,
            lng = ~ lon,
            popup = ~ name,
            icon = makeAwesomeIcon(
              icon = "hourglass-start",
              markerColor = "red",
              iconColor = "white",
              library = "fa"))
        m <- addAwesomeMarkers(
            m,
            data = to_destination,
            lat = ~ lat,
            lng = ~ lon,
            popup = ~ name,
            icon = makeAwesomeIcon(
              icon = "hourglass-end",
              markerColor = "blue",
              iconColor = "white",
              library = "fa"))
        m <- addLegend(
            m,
            pal = pal_transport,
            values = NA,
            opacity = mapLegendOpacity,
            title = "Transport Mode")
        m <- addLegend(
          m,
          pal = pal_time_date,
          values = date_time_legend,
          position = "bottomleft",
          title = "Date and Time")
      }
      mapview::mapshot(m, file = paste0(output.dir, "/pointToPointTime-", file_name, "/map/pointToPointTime-", file_name_loop, ".png"))
    }
    
    if (geojsonOutput == T) {
      if (exists("poly_lines")) {
        rgdal::writeOGR(
          poly_lines,
          dsn = paste0(output.dir,
                       "/pointToPointTime-",
                       file_name,
                       "/geojson/",
                       "pointToPointTime-",
                       file_name_loop,
                       ".geoJSON"),
          layer = "poly_lines",
          driver = "GeoJSON")
        remove(poly_lines)
      }
    }
    
    if (num.run == 1) {
      
      if (!is.null(point_to_point$errorId)){
        
        if (point_to_point$errorId == "OK") {
          
          if (estimateCost == T){
            
            cost <- 0
            busCost <- 0
            trainCost <- 0
            
            for (n in 1:nrow(point_to_point$output_table)){
              if (point_to_point$output_table[n,]$mode == 'BUS'){
                busCost <- busCost + busTicketPrice
              } else if (point_to_point$output_table[n,]$mode == 'RAIL'){
                trainCost_tmp <- trainTicketPriceKm * (point_to_point$output_table[n,]$distance)
                if (trainCost_tmp < trainTicketPriceMin){
                  trainCost_tmp <- trainTicketPriceMin
                }
                trainCost <- trainCost + trainCost_tmp
              }
            }
            
            if (busCost > busTicketPriceMax){
              busCost <- busTicketPriceMax
            }
            cost <- busCost + trainCost  
            
          } else {
            cost <- NA
          }
          
          point_to_point_table_overview <- point_to_point$itineraries
          point_to_point_table_overview["cost"] <- round(cost, digits = 2)
          point_to_point_table_overview["no_of_buses"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'BUS',])
          point_to_point_table_overview["no_of_trains"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'RAIL',])
          point_to_point_table_overview["journey_details"] <- jsonlite::toJSON(point_to_point$output_table)
          
        } else {
          point_to_point_table_overview <- make_blank_df(from_origin, to_destination, time_twenty_four)
        }
        
      } else {
        point_to_point_table_overview <- make_blank_df(from_origin, to_destination, time_twenty_four)
      }
      
    } else {
      
      if (!is.null(point_to_point$errorId)){
        
        if (point_to_point$errorId == "OK") {
          
          if (estimateCost == T){
            
            cost <- 0
            busCost <- 0
            trainCost <- 0
            
            for (n in 1:nrow(point_to_point$output_table)){
              if (point_to_point$output_table[n,]$mode == 'BUS'){
                busCost <- busCost + busTicketPrice
              } else if (point_to_point$output_table[n,]$mode == 'RAIL'){
                trainCost_tmp <- trainTicketPriceKm * (point_to_point$output_table[n,]$distance / 1000)
                if (trainCost_tmp < trainTicketPriceMin){
                  trainCost_tmp <- trainTicketPriceMin
                }
                trainCost <- trainCost + trainCost_tmp
              }
            }
            
            if (busCost > busTicketPriceMax){
              busCost <- busTicketPriceMax
            }
            cost <- busCost + trainCost  
            
          } else {
            cost <- NA
          }
          
          point_to_point_table_overview_tmp <- point_to_point$itineraries
          point_to_point_table_overview_tmp["cost"] <- round(cost, digits = 2)
          point_to_point_table_overview_tmp["no_of_buses"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'BUS',])
          point_to_point_table_overview_tmp["no_of_trains"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'RAIL',])
          point_to_point_table_overview_tmp["journey_details"] <- jsonlite::toJSON(point_to_point$output_table)
        } else {
          point_to_point_table_overview_tmp <- make_blank_df(from_origin, to_destination, time_twenty_four)
        }
        
        point_to_point_table_overview <- rbind(point_to_point_table_overview, point_to_point_table_overview_tmp)
      } else {
        point_to_point_table_overview_tmp <- make_blank_df(from_origin, to_destination, time_twenty_four)
        
        point_to_point_table_overview <- rbind(point_to_point_table_overview, point_to_point_table_overview_tmp)
      }
    }
    if (infoPrint == T){
      pb$tick(tokens = list(what = time))
    }
    
  }
  
  ######################
  #### SAVE RESULTS ####
  ######################
  
  if (infoPrint == T){
    cat("\nAnalysis complete, now saving outputs to ", output.dir, ", please wait.\n", sep="")
    cat("Journey details:\n", sep = "")
    cat("Trips possible: ", nrow(point_to_point_table_overview[!is.na(point_to_point_table_overview$duration_mins),]),"/",num.total,"\n", sep = "")
    cat("Mean Duration (mins): ", round(mean(point_to_point_table_overview$duration_mins, na.rm=TRUE),2), " [+/-", round(sd(point_to_point_table_overview$duration_mins, na.rm=TRUE),2), "] ", " (Walk time: ", round(mean(point_to_point_table_overview$walk_time_mins, na.rm=TRUE),2), " [+/-", round(sd(point_to_point_table_overview$walk_time_mins, na.rm=TRUE),2), "] ", ", Transit time: ", round(mean(point_to_point_table_overview$transit_time_mins, na.rm=TRUE),2), " [+/-", round(sd(point_to_point_table_overview$transit_time_mins, na.rm=TRUE),2), "] ", ", Waiting time: ", round(mean(point_to_point_table_overview$waiting_time_mins, na.rm=TRUE),2), " [+/-", round(sd(point_to_point_table_overview$waiting_time_mins, na.rm=TRUE),2), "])\n", sep = "")
    cat("Mean Distance (km): ", round(mean(point_to_point_table_overview$distance_km, na.rm=TRUE),2), " [+/-", round(sd(point_to_point_table_overview$distance_km, na.rm=TRUE),2), "]\n", sep = "")
    cat("Median Transfers: ", median(point_to_point_table_overview$transfers, na.rm=TRUE), " (Buses: ", median(point_to_point_table_overview$no_of_buses, na.rm=TRUE), ", Trains: ", median(point_to_point_table_overview$no_of_trains, na.rm=TRUE), ")\n\n", sep = "")
  }

  for (i in 1:nrow(point_to_point_table_overview)) {
    
    point_to_point_table_overview[i,"time"] = format(time_series[i], "%H:%M:%S")
    
    if (i == 1) {
      point_to_point_table_overview[i,"date"] = format(time_series[i], "%m/%d/%Y")
    } else {
      
      if (format(time_series[i], "%I:%M %p") >= format(time_series[i-1], "%I:%M %p")) {
        point_to_point_table_overview$date[i] = point_to_point_table_overview[i - 1,"date"]
      } else {
        point_to_point_table_overview$date[i] = format(as.Date(strptime(point_to_point_table_overview[i - 1,"date"], "%m/%d/%Y")) + 1, "%m/%d/%Y")
      }
    }
  }
  
  if (modes == "CAR") {
    colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "drive_time_mins"
  } else if (modes == "BICYCLE") {
    colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "cycle_time_mins"
  }
  
  write.csv(
    point_to_point_table_overview,
    file = paste0(output.dir, "/pointToPointTime-", file_name, "/csv/pointToPointTime-", file_name, ".csv"),
    row.names = F) 
  
  if (gifOutput == T) {
    library(dplyr)
    list.files(
      path = paste0(output.dir, "/pointToPointTime-", file_name, "/map"),
      pattern = "*.png",
      full.names = T
    ) %>% 
      purrr::map(magick::image_read) %>%
      magick::image_join() %>%
      magick::image_animate(fps = 5) %>% 
      magick::image_write(paste0(output.dir, "/pointToPointTime-", file_name, "/gif/", "/pointToPointTime-gif-", file_name, ".gif"))
    
    m <-
      magick::image_read(paste0(output.dir, "/pointToPointTime-", file_name, "/gif/", "/pointToPointTime-gif-", file_name, ".gif")) %>%
      magick::image_scale("800") 
  
    invisible(print(m)) 
  }

  if (infoPrint == T){
    cat("Outputs were saved to ", output.dir, "/pointToPointTime-", file_name,"/.\nThanks for using propeR.", sep="")
  }
  
  output <- point_to_point_table_overview
}
