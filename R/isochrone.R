##' Generates an isochrone map from a single origin
##'
##' Generates an isochrone polygon from a single origin and checks whether destinations
##' fall within isochrone, and if so, at what cutoff time amount. 
##' A comma separated value file of journey times for each destination is saved in the output folder.
##' A map of the journey can also be saved as a .png image and .html file.
##' The polygon can also be saved as a .GeoJSON file.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param originPointsRow The row of originPoints to be used, defaults to 1
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
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
##' @param isochroneCutOffMax Provide the maximum cutoff time for the isochrone, defaults 90
##' @param isochroneCutOffMin Provide the minimum cutoff time for the isochrone, defaults 10
##' @param isochroneCutOffStep Provide the cutoff time step for the isochrone, 0 denotes no step is required (returns isochroneCutOffMax only), defaults 10
##' @param infoPrint Specifies whether you want some information printed to the console or not, default is TRUE
##' @param mapOutput Specifies whether you want to output a map, defaults to FALSE
##' @param geojsonOutput Specifies whether you want to output a GeoJSON file, defaults to FALSE
##' @param mapZoom The zoom level of the map as an integer (e.g. 12), defaults to bounding box approach
##' @param mapPolygonLineWeight Specifies the weight of the polygon, defaults to 0 px
##' @param mapPolygonLineColor Specifies the color of the polygon, defaults to 'white'
##' @param mapPolygonLineOpacity Specifies the opacity of the polygon line, defaults to 1 (solid)
##' @param mapPolygonFillOpacity Specifies the opacity of the polygon fill, defaults to 1
##' @param originMarker Specifies if you want to output the origin markers to the map (default is True)
##' @param originMarkerColor Specifies the colour of the origin marker if it is within a isochrone (default is 'red')
##' @param destinationMarkerSize Specifies the destination marker(s) size (default is 3)
##' @param destinationMarkerOutOpacity Specifies the opacity of destination marker(s)if it is not within a isochrone (default is 1, solid)
##' @param destinationMarkerInOpacity Specifies the opacity of destination marker(s)if it is within a isochrone (default is 1, solid)
##' @param destinationMarkerStroke Specifies whether a destination marker(s) stroke is used (default is T)
##' @param destinationMarkerStrokeColor Specifies the stroke color for the destination marker(s) (default is 'black')
##' @param destinationMarkerStrokeWeight Specifies the marker stroke weight for the destination marker(s) (default is 1)
##' @param destinationMarkerInColor Specifies the colour of destination marker(s)if it is within a isochrone (default is 'white')
##' @param destinationMarkerOutColor Specifies the colour of destination marker(s) if it is not within a isochrone (default is 'grey')
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 1
##' @param mapDarkMode Specifies if you want to use the dark leaflet map colour (default is FALSE)
##' @return Saves journey details as comma separated value file to output directory. A map in .png and .html formats, and/or a polygon as a .GeoJSON format, may also be saved
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   isochrone(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints = originPoints,
##'     destinationPoints = destinationPoints,
##'     startDateAndTime = "2018-08-18 12:00:00"
##'   )
##' }
##' @export
isochrone <- function(output.dir,
                      otpcon,
                      originPoints,
                      originPointsRow = 1,
                      destinationPoints,
                      destinationPointsRow = 1,
                      # otpIsochrone args
                      startDateAndTime = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                      modes = "WALK, TRANSIT",
                      maxWalkDistance = 1000,
                      walkReluctance = 2,
                      walkSpeed = 1.5,
                      bikeSpeed = 5,
                      minTransferTime = 1,
                      maxTransfers = 5,
                      wheelchair = F,
                      arriveBy = F,
                      # function specific args.
                      isochroneCutOffMax = 90,
                      isochroneCutOffMin = 10,
                      isochroneCutOffStep = 10,
                      infoPrint = T,
                      # leaflet map args
                      mapOutput = F,
                      geojsonOutput = F,
                      mapZoom = "bb",
                      mapPolygonLineWeight = 0,
                      mapPolygonLineColor = 'white',
                      mapPolygonLineOpacity = 1,
                      mapPolygonFillOpacity = 1,
                      originMarker = T,
                      originMarkerColor = 'red',
                      destinationMarkerSize = 3,
                      destinationMarkerOutOpacity = 1,
                      destinationMarkerInOpacity = 1,
                      destinationMarkerStroke = T,
                      destinationMarkerStrokeColor = 'black',
                      destinationMarkerStrokeWeight = 1,
                      destinationMarkerInColor = 'white',
                      destinationMarkerOutColor = 'grey',
                      mapLegendOpacity = 1,
                      mapDarkMode = F) {
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  origin_points_row_num <- originPointsRow 
  from_origin <- originPoints[origin_points_row_num,]
  if (origin_points_row_num > nrow(originPoints)) {
    stop('Row is not in origin file, process aborted.\n')
  }
  
  if (isochroneCutOffMin < 5) {
    stop('Minimum cutoff time needs to be above 5 minutes.\n')
  }
  
  destination_points_row_num <- destinationPointsRow 
  
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p") 
  start_date <- as.Date(startDateAndTime) 
  date_time_legend <- format(as.POSIXct(startDateAndTime), "%d %B %Y %H:%M") 
  
  file_name <- paste0(from_origin$name, "_", startDateAndTime)
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)
  
  unlink(paste0(output.dir, "/isochrone-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/isochrone-", file_name)) 
  dir.create(paste0(output.dir, "/isochrone-", file_name, "/csv")) 
  
  if (isochroneCutOffStep == 0){
    isochroneCutOffs <- isochroneCutOffMax
  } else {
    isochroneCutOffs <- seq(isochroneCutOffMin, isochroneCutOffMax, isochroneCutOffStep)
  }
  
  mapPolygonColours <- c("#4365BC", "#5776C4", "#6C87CC", "#8098D4", "#95A9DB", "#AABAE3", "#BFCBEA", "#D4DCF1", "#E9EEF8")

  if (mapOutput == T) {
    library(leaflet)
    pal_time_date = leaflet::colorFactor(c("#FFFFFF"), domain = NULL) 
    palIsochrone = leaflet::colorFactor(mapPolygonColours, NULL, n = length(isochroneCutOffs))
  }
  
  if (mapOutput == T){
    dir.create(paste0(output.dir, "/isochrone-", file_name, "/map"))
  }
  
  if (geojsonOutput == T){
    dir.create(paste0(output.dir, "/isochrone-", file_name, "/geojson"))
  }
  
  warning_list <- c()
  
  if (infoPrint == T) {
    cat("Now running the propeR isochrone tool.\n")
    cat("Parameters chosen:\n")
    cat("From: ", from_origin$name, " (", from_origin$lat_lon, ")\n", sep = "")
    cat("Date and Time: ", startDateAndTime, "\n", sep = "")
    cat("Min Duration (mins): ", isochroneCutOffMin, "\n", sep = "")
    cat("Max Duration (mins): ", isochroneCutOffMax, "\n", sep = "")
    cat("Isochrone Step (mins): ", isochroneCutOffStep, "\n", sep = "")
    cat("Outputs: CSV [TRUE] Map [", mapOutput, "] GeoJSON [", geojsonOutput, "]\n\n", sep = "")
  }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  isochrone <- propeR::otpIsochrone(
    otpcon,
    batch = T,
    from = from_origin$lat_lon,
    to = from_origin$lat_lon,
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
    cutoff = isochroneCutOffs
  )
  
  
  isochrone_polygons <- rgdal::readOGR(isochrone$response, "OGRGeoJSON", verbose = F) 
  destination_points_spdf <- destinationPoints 
  sp::coordinates(destination_points_spdf) <- ~ lon + lat 
  sp::proj4string(destination_points_spdf) <- sp::proj4string(isochrone_polygons) 
  isochrone_polygons_split <- sp::split(isochrone_polygons, isochrone_polygons@data$time) 
  
  time_df <- data.frame(matrix(,
                               ncol = length(isochroneCutOffs),
                               nrow = nrow(destination_points_spdf))) 
  
  if (length(isochrone_polygons) != length(isochroneCutOffs)){
    warning_list <- c(warning_list, paste0("A polygon for cutoff level(s) ", setdiff(isochroneCutOffs, (isochrone_polygons@data$time)/60), " minutes could not be produced."))
  }
  
  for (i in 1:length(isochrone_polygons)) {
    time_df_tmp <- sp::over(destination_points_spdf, isochrone_polygons_split[[i]])
    time_df[, i] <- time_df_tmp[, 2]
  }
  
  for (i in 1:nrow(destination_points_spdf)) {
    
    if (is.na(time_df[i, length(isochroneCutOffs)])) {
      time_df[i, length(isochroneCutOffs) + 1] = NA
    } else {
      time_df[i, length(isochroneCutOffs) + 1] = min(time_df[i, 1:length(isochroneCutOffs)], na.rm = T)
    }
  }
  
  names(time_df)[ncol(time_df)] <- "travel_time"
  destinationPoints$travel_time <- time_df$travel_time / 60
  
  destination_points_non_na <- subset(destinationPoints,!(is.na(destinationPoints["travel_time"])))
  
  #########################
  #### OPTIONAL EXTRAS ####
  #########################
  
  if (mapOutput == T) {
    library(leaflet)
    m <- leaflet()
    m <- addScaleBar(m)
    
    if (mapDarkMode != T) {
      m <- addProviderTiles(m, providers$CartoDB.Positron)
    } else {
      m <- addProviderTiles(m, providers$CartoDB.DarkMatter)
    }
    
    if (is.numeric(mapZoom)){
      m <- setView(
        m,
        lat = (from_origin$lat + mean(destinationPoints$lat)) / 2,
        lng = (from_origin$lon + mean(destinationPoints$lon)) / 2,
        zoom = mapZoom
      )
    } else {
      m <- fitBounds(
        m,
        min(min(from_origin$lon),min(destinationPoints$lon),isochrone_polygons@bbox[1]),
        min(min(from_origin$lat),min(destinationPoints$lat),isochrone_polygons@bbox[2]),
        max(max(from_origin$lon),max(destinationPoints$lon),isochrone_polygons@bbox[3]),
        max(max(from_origin$lat),max(destinationPoints$lat),isochrone_polygons@bbox[4]))
    }
    
    m <- addPolygons(
      m,
      data = isochrone_polygons,
      stroke = T,
      color = mapPolygonLineColor,
      opacity = mapPolygonLineOpacity,
      weight = mapPolygonLineWeight,
      smoothFactor = 0.3,
      fillOpacity = mapPolygonFillOpacity,
      fillColor = palIsochrone(isochrone_polygons@data$time)
    )
    m <- addCircleMarkers(
      m,
      data = destinationPoints,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      fillColor = destinationMarkerOutColor,
      stroke = destinationMarkerStroke,
      color = destinationMarkerStrokeColor,
      opacity = destinationMarkerOutOpacity,
      weight = destinationMarkerStrokeWeight,
      fillOpacity = destinationMarkerOutOpacity,
      radius = destinationMarkerSize
    )
    m <- addCircleMarkers(
      m,
      data = destination_points_non_na,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      fillColor = destinationMarkerInColor,
      stroke = destinationMarkerStroke,
      color = destinationMarkerStrokeColor,
      opacity = destinationMarkerInOpacity,
      weight = destinationMarkerStrokeWeight,
      fillOpacity = destinationMarkerInOpacity,
      radius = destinationMarkerSize
    )
    m <- addLegend(
      m,
      pal = palIsochrone,
      values = isochroneCutOffs,
      opacity = mapLegendOpacity,
      title = "Duration (mins)"
    )
    m <- addLegend(
      m,
      pal = pal_time_date,
      opacity = mapLegendOpacity,
      values = date_time_legend,
      position = "bottomleft",
      title = "Date and Time"
    )
    if (originMarker == T){
      m <-
        addAwesomeMarkers(
          m,
          data = from_origin,
          lat = ~ lat,
          lng = ~ lon,
          popup = ~ name,
          icon = makeAwesomeIcon(
            icon = "hourglass-start",
            markerColor = originMarkerColor,
            iconColor = "white",
            library = "fa"))
    }
  }
  
  ######################
  #### SAVE RESULTS ####
  ######################
  
  if (infoPrint == T) {
    cat("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n", sep = "")
    cat("Journey details:\n", sep = "")
    cat("Destinations possible: ", nrow(destinationPoints[!is.na(destinationPoints$travel_time),]),"/",nrow(destinationPoints),"\n", sep = "")
    cat("Mean Duration (mins): ", round(mean(destinationPoints$travel_time, na.rm=TRUE),2), " [+/-", round(sd(destinationPoints$travel_time, na.rm=TRUE),2), "]\n\n", sep = "")
  }
  
  write.csv(
    destinationPoints,
    file = paste0(output.dir, "/isochrone-", file_name, "/csv/isochrone-", file_name, ".csv"),
    row.names = F)
  
  if (length(warning_list) > 0){
    write.csv(
      warning_list,
      file = paste0(output.dir, "/isochrone-", file_name, "/csv/warning-list.csv"),
      row.names = F)
  }
  
  if (mapOutput == T) {
    invisible(print(m))
    mapview::mapshot(m, file = paste0(output.dir, "/isochrone-", file_name, "/map/isochrone-map-", file_name, ".png")) 
    htmlwidgets::saveWidget(
      m,
      file = paste0(output.dir, "/isochrone-", file_name, "/map/isochrone-map-", file_name, ".html"),
      selfcontained = T) 
    unlink(paste0(output.dir, "/isochrone-", file_name, "/map/isochrone-map-", file_name, "_files"), recursive = T)
  }
  
  if (geojsonOutput == T) {
    rgdal::writeOGR(
      isochrone_polygons,
      dsn = paste0(output.dir,
                   "/isochrone-", 
                   file_name,
                   "/geojson/isochrone-",
                   file_name,
                   ".geoJSON"),
      layer = "poly_lines",
      driver = "GeoJSON")
  }
  
  if (infoPrint == T){
    cat("Outputs were saved to ", output.dir, "/isochrone-", file_name,"/.\nThanks for using propeR.", sep="")
  }
}
