##' Generates an animated map of intersecting polygons for multiple origins between a start and end
##' time and date.
##'
##' Calculates a series of polygons for the intersection between multiple origins and finds the intersection, between a start and end time and date.
##' Saves intersecting map as an animated .gif image.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param startDateAndTime The start time and date, in 'YYYY-MM-DD HH:MM:SS' format
##' @param endDateAndTime The end time and date, in 'YYYY-MM-DD HH:MM:SS' format
##' @param timeIncrease The time increase in minutes, default 60
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
##' @param mapMarkerColours the color palette of the markers, defaults to 'Greys'
##' @param mapPolygonColours the color palette of the poygon, defaults to 'Blue'
##' @param mapZoom The zoom level of the map as an integer (e.g. 12), defaults to bounding box approach
##' @param mapPolygonLineWeight Specifies the weight of the polygon, defaults to 5 px
##' @param mapPolygonLineOpacity Specifies the opacity of the polygon line, defaults to 1 (solid)
##' @param mapPolygonFillOpacity Specifies the opacity of the polygon fill, defaults to 0.6
##' @param mapMarkerOpacity Specifies the opacity of the marker, defaults to 1 (solid)
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 0.5
##' @return Saves an animated map as a gif to output directory
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
isochroneMultiIntersectTime <- function(output.dir,
                                        otpcon,
                                        originPoints,
                                        destinationPoints,
                                        # otpIsochrone args
                                        startDateAndTime = "2018-08-18 12:00:00",
                                        endDateAndTime = "2018-08-18 15:00:00",
                                        timeIncrease = 60,
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
                                        isochroneCutOffs = 60,
                                        # leaflet map args
                                        mapMarkerColours = "Greys",
                                        mapPolygonColours = "#6BAED6",
                                        mapZoom = "bb",
                                        mapPolygonLineWeight = 5,
                                        mapPolygonLineOpacity = 1,
                                        mapPolygonFillOpacity = 0.6,
                                        mapMarkerOpacity = 1,
                                        mapLegendOpacity = 0.5) {
  
  message("Now running the propeR isochroneMultiIntersectTime tool.\n")
  
  library(leaflet)
  pal_time_date = leaflet::colorFactor(c("#FFFFFF"), domain = NULL) # Creating colour palette
  palIsochrone = leaflet::colorFactor(mapMarkerColours, NULL, n = length(originPoints)) # Creating colour palette
  unlink(paste0(output.dir, "/tmp_folder"), recursive = T) # Deletes tmp_folder if exists
  dir.create(paste0(output.dir, "/tmp_folder")) # Creates tmp_folder
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  date_time_legend <- format(as.POSIXct(startDateAndTime), "%d %B %Y %H:%M") # Creates a legend value for date in day, month, year and time in 24 clock format
  
  time_series <- seq(as.POSIXct(startDateAndTime), as.POSIXct(endDateAndTime), by = timeIncrease * 60) # Creates a time series between start and end dates and times based on the increment in time
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.start <- 1
  num.end <- nrow(originPoints) * length(time_series)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  message("Creating ", num.total, " isochrones, please wait...\n")
  
  for (n in num.start:length(time_series)) {
    
    for (i in num.start:nrow(originPoints)) {

      num.run <- num.run + 1
      date_time_legend <- format(time_series[n], "%B %d %Y %H:%M") # Creates a legend value for date in day, month, year and time in 24 clock format
      time <- format(time_series[n], "%I:%M %p")
      date <- format(time_series[n], "%m/%d/%Y")
      from_origin <- originPoints[i, ]
      to_destination <- destinationPoints[i,]
      start.time <- Sys.time()
      
      isochrone <- propeR::otpIsochrone(
        otpcon,
        batch = T,
        from = from_origin$lat_lon,
        to = to_destination$lat_lon,
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
        cutoff = isochroneCutOffs 
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
          round((mean(time.taken) * num.total) - sum(time.taken),
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
          " seconds.\n"
        )
      }
    }
    
    for (i in 1:length(isochrone_multi$status)) {
      
      if (i == 1) {
        isochrone_polygons <- rgdal::readOGR(isochrone_multi$response[i], "OGRGeoJSON", verbose = F) # Reads first response and greates SpatialPolygonsDataFrame
        poly_df <- as.data.frame(isochrone_polygons) # Converts data element of SpatialPolygonsDataFrame to a dataframe
        isochrone_polygons <- rgeos::gSimplify(isochrone_polygons, tol = 0.001) # Cleans polygons by simplyfing them
        s_poly <- sp::SpatialPolygonsDataFrame(isochrone_polygons, poly_df) # Merges back to SpatialPolygonsDataFrame
        s_poly_intersect <- s_poly
        s_poly_all <- s_poly
      } else {
        # Cleans and appends all other SpatialPolygonsDataFrames together
        isochrone_polygons_tmp <- rgdal::readOGR(isochrone_multi$response[i], "OGRGeoJSON", verbose = F)
        poly_df_tmp <- as.data.frame(isochrone_polygons_tmp) # Converts data element of SpatialPolygonsDataFrame to a dataframe
        isochrone_polygons_tmp <- rgeos::gSimplify(isochrone_polygons_tmp, tol = 0.001) # Cleans polygons by simplyfing them
        s_poly_tmp <- sp::SpatialPolygonsDataFrame(isochrone_polygons_tmp, poly_df_tmp) # Merges back to SpatialPolygonsDataFrame
        s_poly_all <- rbind(s_poly_all, s_poly_tmp)
        s_poly_intersect <-rgeos::gIntersection(s_poly_intersect, s_poly_tmp)
        
        if (is(s_poly_intersect, "SpatialCollections")) { s_poly_intersect <- s_poly_intersect@polyobj }
      }
    
    if (i == 1) {
      lon.min <- min(min(originPoints$lon),min(destinationPoints$lon),s_poly_intersect@bbox[1])
      lat.min <- min(min(originPoints$lat),min(destinationPoints$lat),s_poly_intersect@bbox[2])
      lon.max <- max(max(originPoints$lon),max(destinationPoints$lon),s_poly_intersect@bbox[3])
      lat.max <- max(max(originPoints$lat),max(destinationPoints$lat),s_poly_intersect@bbox[4])
    }
    }
    
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
        lon.min,
        lat.min,
        lon.max,
        lat.max)
    }
    
    m <- addPolygons(
        m,
        data = s_poly_intersect,
        # Adds polygons from journey
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
        popup = ~ mode)
    m <- addLegend(
        m,
        pal = palIsochrone,
        values = paste(originPoints$name),
        opacity = mapLegendOpacity)
    m <- addLegend(
      m,
      pal = pal_time_date,
      values = date_time_legend,
      position = "bottomleft",
      title = "Date and Time")
    
    mapview::mapshot(m, file = paste0(output.dir, "/tmp_folder/", i, "_", n, ".png")) 
  }
  
  ######################
  #### SAVE RESULTS ####
  ######################
  
  message("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n")
  stamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S") 
  
  library(dplyr)
  list.files(
    path = paste0(output.dir, "/tmp_folder"),
    pattern = "*.png",
    full.names = T
  ) %>%  # Creates gif of results
    purrr::map(magick::image_read) %>%  
    magick::image_join() %>% 
    magick::image_animate(fps = 5) %>%  
    magick::image_write(paste0(output.dir, "/isochroneMultiIntersectTime-map-", stamp, ".gif")) 
  
  m <-
    magick::image_read(paste0(output.dir, "/isochroneMultiIntersectTime-map-", stamp, ".gif")) %>%
    magick::image_scale("600")
  
  invisible(print(m)) 
  
  unlink(paste0(output.dir, "/tmp_folder"), recursive = T) 
  
  message("Thanks for using propeR.")
}
