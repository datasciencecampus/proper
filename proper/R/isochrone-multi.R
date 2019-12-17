##' Generates an isochrone map for multiple origins.
##'
##' Generates an isochrone map from multiple origins and checks whether destinations
##' fall within isochrones, and if so, at what cutoff time amount.
##' A comma separated value file of journey times for each origin and destination is saved in the output folder.
##' A map of the journey can also be saved as a .png image and .html file.
##' The polygons can also be saved as a .GeoJSON file.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param journeyReturn Specifies whether the journey should be calculated as a return or not (default is FALSE)
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
##' @param destinationMarkerOpacity Specifies the opacity of destination marker(s)if it is within a isochrone (default is 1, solid)
##' @param destinationMarkerStroke Specifies whether a destination marker(s) stroke is used (default is T)
##' @param destinationMarkerStrokeColor Specifies the stroke color for the destination marker(s) (default is 'black')
##' @param destinationMarkerStrokeWeight Specifies the marker stroke weight for the destination marker(s) (default is 1)
##' @param destinationMarkerColor Specifies the colour of destination marker(s) if it is not within a isochrone (default is 'white')
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 1
##' @param mapDarkMode Specifies if you want to use the dark leaflet map colour (default is FALSE)
##' @param failSafeSave Specify the failsafe save number for large datasets, default is 100
##' @return Saves journey details as CSV to output directory (optional: a map in PNG and HTML formats, the polygons as a GeoJSON)
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   isochroneMulti(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     destinationPoints,
##'     startDateAndTime = "2018-08-18 12:00:00"
##'   )
##' }
##' @export
isochroneMulti <- function(output.dir,
                           otpcon,
                           originPoints,
                           destinationPoints,
                           journeyReturn = F,
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
                           # output args
                           mapOutput = F,
                           geojsonOutput = F,
                           failSafeSave = 100,
                           # leaflet map args
                           mapZoom = "bb",
                           mapPolygonLineWeight = 0,
                           mapPolygonLineColor = 'white',
                           mapPolygonLineOpacity = 1,
                           mapPolygonFillOpacity = 1,
                           originMarker = T,
                           originMarkerColor = 'red',
                           destinationMarkerSize = 3,
                           destinationMarkerOpacity = 1,
                           destinationMarkerStroke = T,
                           destinationMarkerStrokeColor = 'black',
                           destinationMarkerStrokeWeight = 1,
                           destinationMarkerColor = 'white',
                           mapLegendOpacity = 1,
                           mapDarkMode = F) {
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  if (isochroneCutOffMin < 5) {
    stop('Minimum cutoff time needs to be above 5 minutes.\n')
  }
  
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p")
  start_date <- as.Date(startDateAndTime) 
  date_time_legend <- format(as.POSIXct(startDateAndTime), "%d %B %Y %H:%M") 
  rownames(destinationPoints) <- NULL
  destination_points_spdf <- destinationPoints 
  sp::coordinates(destination_points_spdf) <- ~ lon + lat 
  
  file_name <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)
  
  unlink(paste0(output.dir, "/isochroneMulti-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/isochroneMulti-", file_name)) 
  dir.create(paste0(output.dir, "/isochroneMulti-", file_name, "/csv")) 
  
  if (isochroneCutOffStep == 0){
    isochroneCutOffs <- isochroneCutOffMax
  } else {
    isochroneCutOffs <- seq(isochroneCutOffMin, isochroneCutOffMax, isochroneCutOffStep)
  }
  
  mapPolygonColours <- c("#4365BC", "#5776C4", "#6C87CC", "#8098D4", "#95A9DB", "#AABAE3", "#BFCBEA", "#D4DCF1", "#E9EEF8")
  
  if (mapOutput == T) {
    library(leaflet)
    palIsochrone = leaflet::colorFactor(mapPolygonColours, NULL, n = length(isochroneCutOffs))
    unlink(paste0(output.dir, "/tmp_folder"), recursive = T) 
  }
  
  if (mapOutput == T){
    dir.create(paste0(output.dir, "/isochroneMulti-", file_name, "/map"))
  }
  
  if (geojsonOutput == T){
    dir.create(paste0(output.dir, "/isochroneMulti-", file_name, "/geojson"))
  }
  
  warning_list <- c()
  
  if (infoPrint == T) {
    cat("Now running the propeR isochrone tool.\n")
    cat("Parameters chosen:\n")
    cat("Date and Time: ", startDateAndTime, "\n", sep = "")
    cat("Min Duration (mins): ", isochroneCutOffMin, "\n", sep = "")
    cat("Max Duration (mins): ", isochroneCutOffMax, "\n", sep = "")
    cat("Isochrone Step (mins): ", isochroneCutOffStep, "\n", sep = "")
    cat("Outputs: CSV [TRUE] Map [", mapOutput, "] GeoJSON [", geojsonOutput, "]\n\n", sep = "")
  }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.start <- 1
  num.end <- nrow(originPoints)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  originPoints_removed <- c()
  originPoints_removed_list <- c()
  if (infoPrint == T) {
    message("Creating ", num.total, " isochrones, please wait...")
  }
  
  if (infoPrint == T) {
    pb <- progress::progress_bar$new(
      format = "  Isochrone calculation complete for call :what [:bar] :percent eta: :eta",
      total = num.total, clear = FALSE, width= 100)
  }
  
  for (i in num.start:num.end) {
    num.run <- num.run + 1
    from_origin <- originPoints[num.run, ]
    
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
    
    options(warn = -1)
    
    if (num.run == num.start) {
    
      t <- try(isochrone_polygons <- rgdal::readOGR(isochrone$response, "OGRGeoJSON", verbose = F), silent = T)
      
      if ("try-error" %in% class(t)) {
        originPoints_removed_list <- c(originPoints_removed_list, num.run)
        warning_list <- c(warning_list, paste0("Isochrone failed for ",originPoints$name[num.run],". Removed ",originPoints$name[num.run]," from analysis as no polygon could be generated from it."))
        next
        
      } else {
        isochrone_polygons <- rgdal::readOGR(isochrone$response, "OGRGeoJSON", verbose = F)
        isochrone_polygons@data$name <- from_origin$name # adds name to json
        sp::proj4string(destination_points_spdf) <- sp::proj4string(isochrone_polygons) 
        time_df_tmp <- data.frame(matrix(,
            ncol = nrow(destinationPoints),
            nrow = 1)) 
        isochrone_polygons_split <- sp::split(isochrone_polygons, isochrone_polygons@data$time) 
        
        if (length(isochrone_polygons) != length(isochroneCutOffs)){
          warning_list <- c(warning_list,paste0("A polygon for cutoff level(s) ", setdiff(isochroneCutOffs, (isochrone_polygons@data$time)/60), " minutes could not be produced for ", originPoints$name[num.run], ")."))
        }
        
        for (n in 1:length(isochrone_polygons)) {
        
            time_df_tmp2 <- sp::over(destination_points_spdf, isochrone_polygons_split[[n]]) # Finds the polygon the destination point falls within
            time_df_tmp2$index <- as.numeric(row.names(time_df_tmp2))
            time_df_tmp2 <- time_df_tmp2[order(time_df_tmp2$index),]
            time_df_tmp[n, ] <- time_df_tmp2[, 2]
            remove(time_df_tmp2)
          
        }
        
        options(warn = -1)
        
        for (n in 1:ncol(time_df_tmp)) {
          time_df_tmp[length(isochroneCutOffs) + 1, n] <- min(time_df_tmp[1:length(isochroneCutOffs), n], na.rm = T)
        }
        
        options(warn = 0)
        
        rownames(time_df_tmp)[length(isochroneCutOffs) + 1] <- originPoints$name[num.run]
        time_df <- time_df_tmp[length(isochroneCutOffs) + 1, ]
      }
    } else {
      t <- try(isochrone_polygons_tmp <- rgdal::readOGR(isochrone$response, "OGRGeoJSON", verbose = F), silent = T)
      
      if ("try-error" %in% class(t)) {
        originPoints_removed_list <- c(originPoints_removed_list, num.run)
        warning_list <- c(warning_list, paste0("Isochrone failed for ",originPoints$name[num.run],". Removed ",originPoints$name[num.run]," from analysis as no polygon could be generated from it."))
        next
        
      } else {
        isochrone_polygons_tmp <- rgdal::readOGR(isochrone$response, "OGRGeoJSON", verbose = F)
        isochrone_polygons_tmp@data$name <- from_origin$name # adds name to json
        
        if (exists("isochrone_polygons")) {
          isochrone_polygons <- rbind(isochrone_polygons, isochrone_polygons_tmp)
        } else {
          isochrone_polygons <- isochrone_polygons_tmp
        }
        
        sp::proj4string(destination_points_spdf) <- sp::proj4string(isochrone_polygons_tmp) # Take projection
        time_df_tmp <- data.frame(matrix(,
            ncol = nrow(destinationPoints),
            nrow = 1)) 
        isochrone_polygons_split <- sp::split(isochrone_polygons_tmp, isochrone_polygons_tmp@data$time) 
        
        if (length(isochrone_polygons_tmp) != length(isochroneCutOffs)){
          warning_list <- c(warning_list,paste0("A polygon for cutoff level(s) ", setdiff(isochroneCutOffs, (isochrone_polygons@data$time)/60), " minutes could not be produced for ", originPoints$name[num.run], ")."))
        } 
        
        for (n in 1:length(isochrone_polygons_tmp)) {

            time_df_tmp2 <- sp::over(destination_points_spdf, isochrone_polygons_split[[n]]) # Finds the polygon the destination point falls within
            time_df_tmp2$index <- as.numeric(row.names(time_df_tmp2))
            time_df_tmp2 <- time_df_tmp2[order(time_df_tmp2$index),]
            time_df_tmp[n, ] <- time_df_tmp2[, 2]
          
        }
        
        for (n in 1:ncol(time_df_tmp)) {
          time_df_tmp[length(isochroneCutOffs) + 1, n] <- min(time_df_tmp[1:length(isochroneCutOffs), n], na.rm = T)
        }
        
        rownames(time_df_tmp)[length(isochroneCutOffs) + 1] <- originPoints$name[num.run]
        
        if (exists("time_df")) {
          time_df <- rbind(time_df, time_df_tmp[length(isochroneCutOffs) + 1, ])
        } else {
          time_df <- time_df_tmp[length(isochroneCutOffs) + 1, ]
        }
      }
    }
    
    tmp_seq <- isochrone_polygons@plotOrder
    
    for (n in 1:(length(tmp_seq))) {
      if (n == 1) {
        tmp_seq[n] = as.integer(length(tmp_seq))
      } else if (n < length(isochroneCutOffs) + 1 && n > 1) {
        num <- n - 1
        tmp_seq[n] = as.integer(tmp_seq[num] - nrow(originPoints))
      } else {
        num <- n - length(isochroneCutOffs)
        tmp_seq[n] = as.integer(tmp_seq[num] - 1)
      }
    }
    
    isochrone_polygons@plotOrder <- tmp_seq
    
    if (infoPrint == T) {
      pb$tick(tokens = list(what = num.run))
    }
    
    if ((num.run/failSafeSave) %% 1 == 0) { # fail safe for large files
      is.na(time_df) <- sapply(time_df, is.infinite)
      
      write.csv(
        time_df,
        file = paste0(output.dir, "/isochroneMulti-", file_name, "/csv/isochroneMulti-isochrone_multi_inc-", file_name, ".csv"),
        row.names = T) 
      
      if (length(warning_list > 0)) {
        write.csv(
          warning_list,
          file = paste0(output.dir, "/isochroneMulti-", file_name, "/csv/warning-list", file_name, ".csv"),
          row.names = T) 
      }
      
      if (geojsonOutput == T) {
        rgdal::writeOGR(
          isochrone_polygons,
          dsn = paste0(output.dir,
                       "/isochroneMulti-",
                       file_name,
                       "/geojson/",
                       "isochroneMulti-",
                       file_name,
                       ".geoJSON"),
          layer = "isochrone_polygons",
          driver = "GeoJSON",
          overwrite_layer = TRUE)
      }
      
    }
  }
  
  options(warn = 0)
  
  if (length(originPoints_removed > 0)) {
    originPoints <- originPoints[-c(originPoints_removed_list),]
  }
  
  for (n in 1:nrow(destinationPoints)) {
    colnames(time_df)[n] <- destinationPoints$name[n]
  }
  
  time_df <- time_df / 60
  
  #########################
  #### OPTIONAL EXTRAS ####
  #########################
  
  if (mapOutput == T) {
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
        lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
        lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
        zoom = mapZoom
      )
    } else {
      m <- fitBounds(
        m,
        min(min(originPoints$lon),min(destinationPoints$lon),isochrone_polygons@bbox[1]),
        min(min(originPoints$lat),min(destinationPoints$lat),isochrone_polygons@bbox[2]),
        max(max(originPoints$lon),max(destinationPoints$lon),isochrone_polygons@bbox[3]),
        max(max(originPoints$lat),max(destinationPoints$lat),isochrone_polygons@bbox[4]))
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
        fillColor = palIsochrone(isochrone_polygons@data$time))
    m <- addCircleMarkers(
        m,
        data = destinationPoints,
        lat = ~ lat,
        lng = ~ lon,
        fillColor = destinationMarkerColor,
        stroke = destinationMarkerStroke,
        color = destinationMarkerStrokeColor,
        opacity = destinationMarkerOpacity,
        weight = destinationMarkerStrokeWeight,
        fillOpacity = destinationMarkerOpacity,
        radius = destinationMarkerSize)
    m <- addLegend(
      m,
      pal = palIsochrone,
      values = isochroneCutOffs,
      opacity = mapLegendOpacity,
      title = "Duration (mins)")
    if (originMarker == T){
      m <-
        addAwesomeMarkers(
          m,
          data = originPoints,
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
  
  is.na(time_df) <- sapply(time_df, is.infinite)

  if (infoPrint == T) {
    cat("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n", sep = "")
    cat("Journey details:\n", sep = "")
    cat("Isochrones generated: ", num.total-length(originPoints_removed_list),"/",num.total,"\n", sep = "")
    cat("Destinations possible: ", ncol(time_df) - sum(colSums(is.na(time_df)) == nrow(time_df)),"/",ncol(time_df),"\n\n", sep = "")
  }
  
  write.csv(
    time_df,
    file = paste0(output.dir, "/isochroneMulti-", file_name, "/csv/isochroneMulti-isochrone_multi_inc-", file_name, ".csv"),
    row.names = T) 
  
  if (length(warning_list > 0)) {
    write.csv(
      warning_list,
      file = paste0(output.dir, "/isochroneMulti-", file_name, "/csv/warning-list", file_name, ".csv"),
      row.names = T) 
  }
  
  if (geojsonOutput == T) {
    rgdal::writeOGR(
      isochrone_polygons,
      dsn = paste0(output.dir,
                   "/isochroneMulti-",
                   file_name,
                   "/geojson/",
                   "isochroneMulti-",
                   file_name,
                   ".geoJSON"),
      layer = "isochrone_polygons",
      driver = "GeoJSON",
      overwrite_layer = TRUE)
  }
  
  if (mapOutput == T) {
    invisible(print(m)) 
    mapview::mapshot(m, file = paste0(output.dir, "/isochroneMulti-", file_name, "/map/isochroneMulti-", file_name, ".png"))
    htmlwidgets::saveWidget(m, file = paste0(output.dir, "/isochroneMulti-", file_name, "/map/isochroneMulti-", file_name, ".html")) 
    unlink(paste0(output.dir, "/isochroneMulti-", file_name, "/map/isochroneMulti-", file_name, "_files"), recursive = T) 
  }
  
  if (infoPrint == T){
    cat("Outputs were saved to ", output.dir, "/isochroneMulti-", file_name,"/.\nThanks for using propeR.", sep="")
  }
  
  filename <- paste0("/isochroneMulti-", file_name)
}
