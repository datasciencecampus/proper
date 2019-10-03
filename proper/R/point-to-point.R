##' Calculates the journey for a single origin and destination.
##'
##' Calculates the journey time and details between a single origin and destination. 
##' A comma separated value file of journey details is saved in the specified output folder.
##' A map of the journey can also be saved as a .png image and .html file.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param originPointsRow The row of originPoints to be used, defaults to 1
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param destinationPointsRow The row of destinationPoints to be used, defaults to 1
##' @param startDateAndTime The start time and date, in 'YYYY-MM-DD HH:MM:SS' format, default is currrent date and time
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
##' @return Saves journey details as comma separated value file to output directory. A map in .png and .html formats may also be saved)
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   pointToPoint(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     destinationPoints,
##'     startDateAndTime = "2018-08-18 12:00:00"
##'   )
##' }
##' @export
pointToPoint <- function(output.dir,
                         otpcon,
                         originPoints,
                         originPointsRow = 1,
                         destinationPoints,
                         destinationPointsRow = 1,
                         # otpTime args
                         startDateAndTime = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                         modes = "WALK, TRANSIT",
                         maxWalkDistance = 1000,
                         walkReluctance = 2,
                         walkSpeed = 1.4,
                         bikeSpeed = 4.3,
                         minTransferTime = 1,
                         maxTransfers = 10,
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
                         geojsonOutput = F,
                         mapPolylineColours = list(
                           TRANSIT = "#000000",
                           WALK = "#A14296",
                           BUS = "#48C1B1",
                           RAIL = "#4D7BC5",
                           CAR = "#E825D6",
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
  from_origin <- originPoints[origin_points_row_num,]
  if (origin_points_row_num > nrow(originPoints)) {
    stop("Row is not in origin file, process aborted.\n")
  }
  
  destination_points_row_num <- destinationPointsRow
  to_destination <- destinationPoints[destination_points_row_num,]
  if (destination_points_row_num > nrow(destinationPoints)) {
    stop("Row is not in destination file, process aborted.\n")
  }
  
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p")
  start_date <- as.Date(startDateAndTime)
  date_time_legend <- format(as.POSIXct(startDateAndTime), "%d %B %Y %H:%M")
  
  file_name <- paste0(from_origin$name,"_",to_destination$name, "_", startDateAndTime)
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)

  unlink(paste0(output.dir, "/pointToPoint-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/pointToPoint-", file_name)) 
  dir.create(paste0(output.dir, "/pointToPoint-", file_name, "/csv")) 
  
  if (mapOutput == T) {
    dir.create(paste0(output.dir, "/pointToPoint-", file_name, "/map")) 
    library(leaflet)
    pal_transport <-
      leaflet::colorFactor(
        palette = unlist(mapPolylineColours, use.names = F),
        levels = as.factor(names(mapPolylineColours)),
        reverse = F
      )
    pal_time_date = leaflet::colorFactor(c("#FFFFFF"), domain = NULL)
    if (mapDarkMode == T){
      mapMarkerStrokeColor = 'white'
    }
  }
  
  if (geojsonOutput == T){
    dir.create(paste0(output.dir, "/pointToPoint-", file_name, "/geojson"))
  }
  
  if (infoPrint == T){
    cat("Now running the propeR pointToPoint tool.\n")
    cat("Parameters chosen:\n", sep="")
    cat("From: ", from_origin$name, " (", from_origin$lat_lon, ")\n", sep="")
    cat("To: ", to_destination$name, " (", to_destination$lat_lon, ")\n", sep="")
    cat("Date and Time: ", startDateAndTime, "\n", sep="")
    cat("Outputs: CSV [TRUE] Map [", mapOutput, "] GeoJSON [", geojsonOutput, "]\n\n", sep="")
  }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  point_to_point <- propeR::otpTripTime(
    otpcon,
    detail = T,
    from_name = from_origin$name,
    from_lat_lon = from_origin$lat_lon,
    to_name = to_destination$name,
    to_lat_lon =   to_destination$lat_lon,
    modes = modes,
    date = start_date,
    time = start_time,
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
  
  if (!is.null(point_to_point$errorId)){
    
    if (point_to_point$errorId == 'OK') {
      
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
      
      point_to_point_table_overview <- point_to_point$itineraries[1,]
      point_to_point_table_overview["cost"] <- round(cost, digits = 2)
      point_to_point_table_overview["no_of_buses"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'BUS',])
      point_to_point_table_overview["no_of_trains"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'RAIL',])
      point_to_point_table_overview["journey_details"] <- jsonlite::toJSON(point_to_point$output_table)
      
      point_to_point_table <- point_to_point$output_table

    } else {
      unlink(paste0(output.dir, "/pointToPoint-", file_name) , recursive = T) 
      stop("No journey found with given parameters!\n")
    }
    
    #########################
    #### OPTIONAL EXTRAS ####
    #########################
    
    if (mapOutput == T || geojsonOutput == T) {
      poly_lines <- point_to_point$poly_lines
      poly_lines <- sp::spTransform(poly_lines, sp::CRS("+init=epsg:4326"))
    }
    
    if (mapOutput == T) {
      if (infoPrint == T){
        cat("Generating map, please wait.\n")
      }
        
      popup_poly_lines <- paste0(
          "<strong>Mode: </strong>",
          poly_lines$mode,
          "<br><strong>Route: </strong>",
          poly_lines$route,
          "<br><strong>Operator: </strong>",
          poly_lines$agencyName,
          "<br><strong>Duration: </strong>",
          round(poly_lines$duration / 60, digits = 2),
          " mins",
          "<br><strong>Distance: </strong>",
          round(poly_lines$distance / 1000, digits = 2),
          " km")
      
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
          min(min(from_origin$lon),min(to_destination$lon),poly_lines@bbox[1]),
          min(min(from_origin$lat),min(to_destination$lat),poly_lines@bbox[2]),
          max(max(from_origin$lon),max(to_destination$lon),poly_lines@bbox[3]),
          max(max(from_origin$lat),max(to_destination$lat),poly_lines@bbox[4]))
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
          popup = popup_poly_lines,
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
          popup = ~ from)
      m <- addLegend(
          m,
          pal = pal_transport,
          values = point_to_point_table$mode,
          opacity = mapLegendOpacity,
          title = "Transport Mode")
      m <- addLegend(
        m,
        pal = pal_time_date,
        opacity = mapLegendOpacity,
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
    }
    
    ######################
    #### SAVE RESULTS ####
    ######################
    
    if (infoPrint == T){
      cat("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n", sep = "")
      cat("Journey details:\n", sep = "")
      cat("Duration (mins): ", point_to_point_table_overview$duration_mins, " (Walk time: ", point_to_point_table_overview$walk_time_mins, ", Transit time: ", point_to_point_table_overview$transit_time_mins, ", Waiting time: ", point_to_point_table_overview$waiting_time_mins, ")\n", sep = "")
      cat("Distance (km): ", point_to_point_table_overview$distance_km, "\n", sep = "")
      cat("Transfers: ", point_to_point_table_overview$transfers, " (Buses: ", point_to_point_table_overview$no_of_buses, ", Trains: ", point_to_point_table_overview$no_of_trains, ")\n\n", sep = "")
    }
    
    if (modes == "CAR") {
      colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "drive_time_mins"
    } else if (modes == "BICYCLE") {
      colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "cycle_time_mins"
    }
    
    write.csv(
      point_to_point_table_overview,
      file = paste0(output.dir, "/pointToPoint-", file_name, "/csv/pointToPoint-", file_name, ".csv"),
      row.names = F)
    
    write.csv(
      point_to_point_table,
      file = paste0(output.dir, "/pointToPoint-", file_name, "/csv/pointToPoint-journey-legs-", file_name, ".csv"),
      row.names = F)
    
    if (mapOutput == T) {
      invisible(print(m))
      mapview::mapshot(m, file = paste0(output.dir, "/pointToPoint-", file_name, "/map/pointToPoint-map-", file_name, ".png")) 
      htmlwidgets::saveWidget(
        m,
        file = paste0(output.dir, "/pointToPoint-", file_name, "/map/pointToPoint-map-", file_name, ".html"),
        selfcontained = T) 
      unlink(paste0(output.dir, "/pointToPoint-", file_name, "/map/pointToPoint-map-", file_name, "_files"), recursive = T)
    }
    
    if (geojsonOutput == T) {
      rgdal::writeOGR(
        poly_lines,
        dsn = paste0(output.dir,
                     "/pointToPoint-", 
                     file_name,
                     "/geojson/pointToPoint-",
                     file_name,
                     ".geoJSON"),
        layer = "poly_lines",
        driver = "GeoJSON")
    }
    
  } else {
    unlink(paste0(output.dir, "/pointToPoint-", file_name) , recursive = T) 
    stop("No journey found with given parameters!\n")
  }
  
  if (infoPrint == T){
    cat("Outputs were saved to ", output.dir, "/pointToPoint-", file_name,"/.\nThanks for using propeR.", sep="")
  }
  
  output <- point_to_point_table_overview
}
