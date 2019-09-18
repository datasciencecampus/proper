##' Generates a GeoJSON of intersecting polygons for multiple origins
##'
##' Calculates a series of polygons between multiple origins and finds the intersection.
##' Saves polygon as a .GeoJSON file. A map of the intersecting polygon can also be saved as a .png image and .html file.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param startDateAndTime The start time and date, in 'YYYY-MM-DD HH:MM:SS' format
##' @param modes The mode of the journey, defaults to 'TRANSIT, WALK'
##' @param maxWalkDistance The maximum walking distance, in meters, defaults to 1000 m
##' @param walkReluctance The reluctance of walking-based routes, defaults to 2 (range 0 (lowest) - 20 (highest))
##' @param walkSpeed The walking soeed, in meters per second, defaults to 1.4 m/s
##' @param bikeSpeed The cycling speed, in meters per second, defaults to 4.3 m/s
##' @param minTransferTime The maximum transfer time, in minutes, defaults to 0 mins (no time specified)
##' @param maxTransfers The maximum number of transfers, defaults to 10
##' @param wheelchair If TRUE, uses on wheeelchair friendly stops, defaults to FALSE
##' @param arriveBy Selects whether journey starts at startDateandTime (FALSE) or finishes (TRUE), defaults to FALSE
##' @param isochroneCutOffs Provide a list of cutoffs in minutes, defaults to c(30, 60, 90)
##' @param mapOutput Specifies whether you want to output a map, defaults to FALSE
##' @param geojsonOutput Specifies whether you want to output a GeoJSON file, defaults to TRUE
##' @param mapMarkerColours the color palette of the markers, defaults to 'Greys'
##' @param mapPolygonColours the color palette of the poygon, defaults to 'Blue'
##' @param mapZoom The zoom level of the map as an integer (e.g. 12), defaults to bounding box approach
##' @param mapPolygonLineWeight Specifies the weight of the polygon, defaults to 5 px
##' @param mapPolygonLineOpacity Specifies the opacity of the polygon line, defaults to 1 (solid)
##' @param mapPolygonFillOpacity Specifies the opacity of the polygon fill, defaults to 0.6
##' @param mapMarkerOpacity Specifies the opacity of the marker, defaults to 1 (solid)
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 0.5
##' @return Saves intersecting polygon as a .GeoJSON to output directory. A map in .png and .html formats, and/or a polygon as a .GeoJSON format, may also be saved
##' @author Michael Hodge
##' @examples
##'   isochroneMultiIntersect(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     destinationPoints,
##'     startDateAndTime = "2018-08-18 12:00:00"
##'   )
##' @export
isochroneMultiIntersect <- function(output.dir,
                                    otpcon,
                                    originPoints,
                                    destinationPoints,
                                    # otp args
                                    startDateAndTime = "2018-08-18 12:00:00",
                                    modes = "WALK, TRANSIT",
                                    maxWalkDistance = 1000,
                                    walkReluctance = 2,
                                    walkSpeed = 1.5,
                                    bikeSpeed = 5,
                                    minTransferTime = 1,
                                    maxTransfers = 5,
                                    wheelchair = F,
                                    arriveBy = F,
                                    # function specific args
                                    isochroneCutOffs = 60,
                                    # leaflet map args
                                    mapOutput = F,
                                    geojsonOutput = T,
                                    mapMarkerColours = "Greys",
                                    mapPolygonColours = "#6BAED6",
                                    mapZoom = "bb",
                                    mapPolygonLineWeight = 5,
                                    mapPolygonLineOpacity = 1,
                                    mapPolygonFillOpacity = 0.6,
                                    mapMarkerOpacity = 1,
                                    mapLegendOpacity = 0.5) {
  
  message("Now running the propeR isochroneMultiIntersect tool.\n")
  
  if (mapOutput == T) {
    library(leaflet)
    palIsochrone = leaflet::colorFactor(mapMarkerColours, NULL, n = length(originPoints)) 
    unlink(paste0(output.dir, "/tmp_folder"), recursive = T) 
  }
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  if (is.null(originPoints$mode)) { originPoints$mode <- modes }
  
  if (is.null(originPoints$max_duration)) { originPoints$max_duration <- isochroneCutOffs }
  
  if (is.null(originPoints$time)) { originPoints$time <- format(as.POSIXct(startDateAndTime), "%I:%M %p") }
  
  if (is.null(originPoints$date)) { originPoints$date <- as.Date(startDateAndTime) }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.start <- 1
  num.end <- nrow(originPoints)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  
  message("Creating ", num.total, " isochrones, please wait...")

  for (i in num.start:num.end) {
    
    start.time <- Sys.time()
    num.run <- num.run + 1
    
    #Changes transport modes to OTP transport modes
    from_origin <- originPoints[num.run,]
    to_destination <- destinationPoints[num.run,]
    if (from_origin$mode == "Public Transport") { mode <- "TRANSIT,WALK"
    } else if (from_origin$mode == "Driving") { mode <- "CAR"
    } else if (from_origin$mode == "Train") { mode <- "RAIL,WALK"
    } else if (from_origin$mode == "Bus") { mode <- "BUS,WALK"
    } else if (from_origin$mode == "Walking") { mode <- "WALK"
    } else if (from_origin$mode == "Cycling") { mode <- "BICYCLE"
    } else { mode <- modes }
    
    isochrone <- propeR::otpIsochrone(
      otpcon,
      batch = T,
      from = from_origin$lat_lon,
      to = to_destination$lat_lon,
      modes = from_origin$mode,
      date = from_origin$date,
      time = from_origin$time,
      maxWalkDistance = maxWalkDistance,
      walkReluctance = walkReluctance,
      walkSpeed = walkSpeed,
      bikeSpeed = bikeSpeed,
      minTransferTime = minTransferTime,
      maxTransfers = maxTransfers,
      wheelchair = wheelchair,
      arriveBy = arriveBy,
      cutoff = from_origin$max_duration
    )
    
    if (num.run == 1) {
      isochrone_multi <- isochrone
    } else {
      isochrone_multi$status <- c(isochrone_multi$status, isochrone$status)
      isochrone_multi$response <- c(isochrone_multi$response, isochrone$response)
    }
    
    end.time <- Sys.time()
    time.taken[num.run] <- round(end.time - start.time, digits = 2)
    
    if (num.run < num.total) {
      message(
        num.run,
        " out of ",
        num.total,
        " isochrones complete. Time taken ",
        round(sum(time.taken), digit = 2),
        " seconds. Estimated time left is approx. ",
        round((
          mean(time.taken) * num.total
        ) - sum(time.taken),
        digits = 2),
        " seconds."
      )
    } else {
      message(
        num.run,
        " out of ",
        num.total,
        " isochrones complete. Time taken ",
        sum(time.taken),
        " seconds."
      )
    }
  }
  
  num.start <- 1
  num.end <- length(isochrone_multi$status)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  
  message("Finding the intersect between ", num.total, " isochrones, please wait...")
  
  for (n in num.start:num.end) {
    
    start.time <- Sys.time()
    num.run <- num.run + 1
    
    if (num.run == 1) {
      isochrone_polygons <- rgdal::readOGR(isochrone_multi$response[num.run], "OGRGeoJSON", verbose = F)
      poly_df <- as.data.frame(isochrone_polygons)
      isochrone_polygons <- rgeos::gSimplify(isochrone_polygons, tol = 0.001)
      s_poly <- sp::SpatialPolygonsDataFrame(isochrone_polygons, poly_df)
      s_poly_intersect <- s_poly
      s_poly_all <- s_poly
    } else {
      # Cleans and appends all other SpatialPolygonsDataFrames together
      isochrone_polygons_tmp <- rgdal::readOGR(isochrone_multi$response[num.run], "OGRGeoJSON", verbose = F)
      poly_df_tmp <- as.data.frame(isochrone_polygons_tmp) # Converts data element of SpatialPolygonsDataFrame to a dataframe
      isochrone_polygons_tmp <- rgeos::gSimplify(isochrone_polygons_tmp, tol = 0.001) # Cleans polygons by simplyfing them
      s_poly_tmp <- sp::SpatialPolygonsDataFrame(isochrone_polygons_tmp, poly_df_tmp) # Merges back to SpatialPolygonsDataFrame
      s_poly_all <- rbind(s_poly_all, s_poly_tmp)
      s_poly_intersect <- rgeos::gIntersection(s_poly_intersect, s_poly_tmp)
      
      if (is(s_poly_intersect, "SpatialCollections")) { s_poly_intersect <- s_poly_intersect@polyobj }
    }
    
    end.time <- Sys.time()
    time.taken[num.run] <- round(end.time - start.time, digits = 2)
    
    if (num.run < num.total) {
      message(
        num.run,
        " out of ",
        num.total,
        " intersections complete. Time taken ",
        round(sum(time.taken), digit = 2),
        " seconds. Estimated time left is approx. ",
        round((
          mean(time.taken) * num.total
        ) - sum(time.taken),
        digits = 2),
        " seconds."
      )
    } else {
      message(
        num.run,
        " out of ",
        num.total,
        " intersections complete. Time taken ",
        sum(time.taken),
        " seconds."
      )
    }
  }
  
  #########################
  #### OPTIONAL EXTRAS ####
  #########################
  
  if (mapOutput == T) {
    popup_originPoints <-
      # generates a popup for the poly_lines_lines feature
      paste0(
        "<strong>Name: </strong>",
        originPoints$name,
        "<br><strong>Mode: </strong>",
        originPoints$mode,
        "<br><strong>Duration: </strong>",
        round(originPoints$max_duration, digits = 2),
        " mins",
        "<br><strong>Date: </strong>",
        originPoints$date,
        "<br><strong>Time: </strong>",
        originPoints$time)
    
    m <- leaflet()
    m <- addScaleBar(m)
    m <- addProviderTiles(m, providers$OpenStreetMap.BlackAndWhite)

    if (is.numeric(mapZoom)){
      m <- setView(
        m,
        lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
        lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
        zoom = mapZoom
      )
    } else {
      m <- fitBounds(
        m,
        min(min(originPoints$lon),min(destinationPoints$lon),s_poly_intersect@bbox[1]),
        min(min(originPoints$lat),min(destinationPoints$lat),s_poly_intersect@bbox[2]),
        max(max(originPoints$lon),max(destinationPoints$lon),s_poly_intersect@bbox[3]),
        max(max(originPoints$lat),max(destinationPoints$lat),s_poly_intersect@bbox[4]))
    }
    
    m <- addPolygons(
        m,
        data = s_poly_intersect,
        stroke = T,
        weight = mapPolygonLineWeight,
        color = mapPolygonColours,
        opacity = mapPolygonLineOpacity,
        smoothFactor = 0.3,
        fillOpacity = mapPolygonFillOpacity,
        fillColor = mapPolygonColours)
    m <- addCircleMarkers(
        m,
        data = originPoints,
        lat = ~ lat,
        lng = ~ lon,
        radius = 8,
        fillColor = palIsochrone(originPoints$name),
        stroke = T,
        color = "black",
        weight = 1,
        opacity = mapMarkerOpacity,
        fillOpacity = 0.8,
        popup = popup_originPoints)
    m <- addLegend(
      m,
      pal = palIsochrone,
      values = paste(
        originPoints$name,
        " by ",
        originPoints$mode,
        " in ",
        originPoints$max_duration,
        " mins",
        sep = ""
      ),
      opacity = mapLegendOpacity)
  }
  
  ######################
  #### SAVE RESULTS ####
  ######################
  
  message("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n")
  stamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  
  s_poly_intersect <- as(s_poly_intersect, "SpatialPolygonsDataFrame")
  
  if (geojsonOutput == T) {
    rgdal::writeOGR(
      s_poly_intersect,
      dsn = paste0(
        output.dir,
        "/isochroneMultiIntersect-",
        stamp,
        ".geoJSON"),
      layer = "s_poly_intersect",
      driver = "GeoJSON")
  }
  
  if (mapOutput == T) {
    invisible(print(m)) # plots map to Viewer
    mapview::mapshot(m, file = paste0(output.dir, "/isochroneMultiIntersect-map-", stamp, ".png"))
    htmlwidgets::saveWidget(m, file = paste0(output.dir, "/isochroneMultiIntersect-map-", stamp, ".html")) # Saves as an interactive HTML webpage
    unlink(paste0(output.dir, "/isochroneMultiIntersect-map-", stamp, "_files"), recursive = T) # Deletes tmp_folder
  }
  
  message("Thanks for using propeR.")
}
