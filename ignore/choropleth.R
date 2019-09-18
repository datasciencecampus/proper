##' Generates a series of choropleth maps using multiple origins to a single destination.
##'
##' Calculates a series of choropleth maps using multiple origins to a single destination.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param originPolygons The variable containing origin(s) polygon(s), see ?importGeojsonData for details
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param destinationPointsRow The row of destinationPoints to be used, defaults to 1
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
##' @param durationCutoff For categorical maps, specify the duration time cutoff in minutes, defaults to 60 minutes
##' @param waitingCutoff For categorical maps, specify the waiting time cutoff in minutes, defaults to 10 minutes
##' @param transferCutoff For categorical maps, specify the number of transfers cutoff, defaults to 1
##' @param mapPolygonColours the color palette of the poylgon, defaults to 'Blue'
##' @param mapPolygonCatColours the color palette of the polygon for catergorical maps, defaults to c("#820e0e", "#407746")
##' @param mapZoom The zoom level of the map as an integer (e.g. 12), defaults to bounding box approach
##' @param mapPolygonLineWeight Specifies the weight of the polygon, defaults to 1 px
##' @param mapPolygonLineOpacity Specifies the opacity of the polygon line, defaults to 1 (solid)
##' @param mapPolygonFillOpacity Specifies the opacity of the polygon fill, defaults to 0.6
##' @param mapMarkerOpacity Specifies the opacity of the marker, defaults to 1 (solid)
##' @param mapLegendOpacity Specifies the opacity of the legend, defaults to 0.5
##' @return Returns a series of maps (duration, wait time, transfers) to the output directory
##' @author Michael Hodge
##' @examples
##'   choropleth(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     originPolygons,
##'     destinationPoints,
##'     startdDateAndTime = "2018-08-18 12:00:00"
##'   )
##' @export
choropleth <- function(output.dir,
                       otpcon,
                       originPoints,
                       originPolygons,
                       destinationPoints,
                       destinationPointsRow = 1,
                       # otpChoropleth args
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
                       # func specific args (originally in config.R)
                       durationCutoff = 60,
                       waitingCutoff = 10,
                       transferCutoff = 1,
                       # leaflet map args
                       mapPolygonColours = "Blues",
                       mapPolygonCatColours = c("#820e0e", "#407746"),
                       mapZoom = "bb",
                       mapPolygonLineWeight = 1,
                       mapPolygonLineOpacity = 1,
                       mapPolygonFillOpacity = 0.6,
                       mapMarkerOpacity = 1,
                       mapLegendOpacity = 0.5) {
  
  message("Now running the propeR choropleth tool.\n")
  
  library(leaflet)
  pal_choropleth = leaflet::colorNumeric(mapPolygonColours, domain = NULL, na.color = "#ffffff") # Creating colour palette
  pal_choropleth_transfers = leaflet::colorFactor(mapPolygonColours, domain = NULL, na.color = "#ffffff") # Creating colour palette
  pal_choropleth_cat = leaflet::colorFactor(mapPolygonCatColours, na.color = "#ffffff", domain = NULL) # Creating colour palette
  unlink(paste0(output.dir, "/tmp_folder"), recursive = T) # Deletes tmp_folder if exists
  dir.create(paste0(output.dir, "/tmp_folder")) # Creates tmp_folder
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  destination_points_row_num <- destinationPointsRow
  to_destination <- destinationPoints[destination_points_row_num, ] # Takes the specified row from the data
  if (destination_points_row_num > nrow(destinationPoints)) {
    message('Row is not in destination file, process aborted.\n')
    unlink(paste0(output.dir, "/tmp_folder"), recursive = TRUE) # Deletes tmp_folder if exists
    break
  }
  
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p") # Sets start time
  start_date <- as.Date(startDateAndTime) # Sets start date
  date_time_legend <- format(as.POSIXct(startDateAndTime), "%d %B %Y %H:%M") # Creates a legend value for date in day, month, year and time in 24 clock format
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.start <- 1
  num.end <- nrow(originPoints)
  num.run <- 0
  num.total <- num.end
  time.taken <- vector()
  
  message("Creating ", num.total, " point to point connections, please wait...")
  
  for (i in num.start:num.end) {

    num.run <- num.run + 1
    start.time <- Sys.time()
    
    from_origin <- originPoints[num.run, ]
    
    choropleth <- propeR::otpChoropleth(
      otpcon,
      detail = T,
      from = from_origin$lat_lon,
      to = to_destination$lat_lon,
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
      arriveBy = arriveBy
    )
    
    if (num.run == 1) {
      choropleth_result <- choropleth$itineraries
    } else {
      choropleth_result = rbind(choropleth_result, choropleth$itineraries)
    }
    
    if (choropleth$errorId == "OK") {
      originPoints[num.run, "status"] <- choropleth$errorId
      originPoints[num.run, "duration"] <- choropleth$itineraries$duration
      originPoints[num.run, "waitingtime"] <- choropleth$itineraries$waitingTime
      originPoints[num.run, "transfers"] <- choropleth$itineraries$transfers
      
      if (originPoints[num.run, "duration"] > (durationCutoff)) {
        originPoints[num.run, "duration_cat"] <- sprintf('Over %s minutes', durationCutoff)
      } else {
        originPoints[num.run, "duration_cat"] <- sprintf('Under %s minutes', durationCutoff)
      }
      
      if (originPoints[num.run, "waitingtime"] > (waitingCutoff)) {
        originPoints[num.run, "waitingtime_cat"] <- sprintf('Over %s minutes', waitingCutoff)
      } else {
        originPoints[num.run, "waitingtime_cat"] <- sprintf('Under %s minutes', waitingCutoff)
      }
      
      if (originPoints[num.run, "transfers"] >= (transferCutoff)) {
        originPoints[num.run, "transfers_cat"] <- sprintf('Over %s transfer(s)', transferCutoff)
      } else {
        originPoints[num.run, "transfers_cat"] <- sprintf('Under %s transfer(s)', transferCutoff)
      }
      
    } else {
      originPoints[num.run, "status"] <- choropleth$errorId
    }
    
    end.time <- Sys.time()
    time.taken[num.run] <- round(end.time - start.time, digits = 2)
    
    if (num.run < num.total) {
      message(
        num.run,
        " out of ",
        num.total,
        " connections complete. Time taken ",
        round(sum(time.taken), digit = 2),
        " seconds. Estimated time left is approx. ",
        round((mean(time.taken) * num.total) - sum(time.taken), digits = 2),
        " seconds."
      )
    } else {
      message(
        num.run,
        " out of ",
        num.total,
        " connections complete. Time taken ",
        sum(time.taken),
        " seconds.\n"
      )
    }
    
  }
  
  colnames(originPolygons@data)[3] = "name"
  choropleth_map <- sp::merge(originPolygons, originPoints[, c(
      'name',
      'duration',
      'waitingtime',
      'transfers',
      'duration_cat',
      'waitingtime_cat',
      'transfers_cat'
    )], by = c("name"))
  
  choropleth_table <- originPoints[, c(
      'name',
      'duration',
      'waitingtime',
      'transfers',
      'duration_cat',
      'waitingtime_cat',
      'transfers_cat'
    )]
  
  popup_duration <- paste0(
      "<strong>Name: </strong>",
      choropleth_map$name,
      "<br><strong>Duration: </strong>",
      choropleth_map$duration,
      " mins")
  
  popup_waitingtime <- paste0(
      "<strong>Name: </strong>",
      choropleth_map$name,
      "<br><strong>Waiting: </strong>",
      choropleth_map$waitingtime,
      " mins")
  
  popup_transfers <- paste0(
      "<strong>Name: </strong>",
      choropleth_map$name,
      "<br><strong>Transfers: </strong>",
      choropleth_map$transfers)
  
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
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  m <- addPolygons(
      m,
      data = choropleth_map,
      fillColor = ~ pal_choropleth(choropleth_map$duration),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_duration)
  m <- addLegend(
    m,
    pal = pal_choropleth,
    # Adds legend
    values = choropleth_map$duration,
    opacity = mapLegendOpacity,
    bins = 5,
    na.label = "NA",
    title = "Duration (minutes)")
  m <- addAwesomeMarkers(
      m,
      data = to_destination,
      # Adds marker for destination
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  m_cat <- leaflet()
  m_cat <- addScaleBar(m_cat)
  m_cat <- addProviderTiles(m_cat, providers$OpenStreetMap.BlackAndWhite)

  if (is.numeric(mapZoom)){
    m_cat <- setView(
      m_cat,
      lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
      lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
      zoom = mapZoom
    )
  } else {
    m_cat <- fitBounds(
      m_cat,
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  m_cat <- addPolygons(
      m_cat,
      data = choropleth_map,
      fillColor = ~ pal_choropleth_cat(choropleth_map$duration_cat),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_duration)
  m_cat <- addLegend(
    m_cat,
    pal = pal_choropleth_cat,
    values = choropleth_map$duration_cat,
    opacity = mapLegendOpacity,
    title = "Duration (minutes)")
  m_cat <- addAwesomeMarkers(
      m_cat,
      data = to_destination,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  n <- leaflet()
  n <- addScaleBar(n)
  n <- addProviderTiles(n, providers$OpenStreetMap.BlackAndWhite)

  if (is.numeric(mapZoom)){
    n <- setView(
      n,
      lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
      lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
      zoom = mapZoom
    )
  } else {
    n <- fitBounds(
      n,
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  n <- addPolygons(
      n,
      data = choropleth_map,
      fillColor = ~ pal_choropleth(choropleth_map$waitingtime),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_waitingtime)
  n <- addLegend(
    n,
    pal = pal_choropleth,
    values = choropleth_map$waitingtime,
    opacity = mapLegendOpacity,
    bins = 5,
    na.label = "NA",
    title = "Wait Time (minutes)")
  n <- addAwesomeMarkers(
      n,
      data = to_destination,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  n_cat <- leaflet()
  n_cat <- addScaleBar(n_cat)
  n_cat <- addProviderTiles(n_cat, providers$OpenStreetMap.BlackAndWhite)

  if (is.numeric(mapZoom)){
    n_cat <- setView(
      n_cat,
      lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
      lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
      zoom = mapZoom
    )
  } else {
    n_cat <- fitBounds(
      n_cat,
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  n_cat <- addPolygons(
      n_cat,
      data = choropleth_map,
      fillColor = ~ pal_choropleth_cat(choropleth_map$waitingtime_cat),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_waitingtime)
  n_cat <- addLegend(
    n_cat,
    pal = pal_choropleth_cat,
    values = choropleth_map$waitingtime_cat,
    opacity = mapLegendOpacity,
    title = "Wait Time (minutes)")
  n_cat <- addAwesomeMarkers(
      n_cat,
      data = to_destination,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  o <- leaflet()
  o <- addScaleBar(o)
  o <- addProviderTiles(o, providers$OpenStreetMap.BlackAndWhite)

  if (is.numeric(mapZoom)){
    o <- setView(
      o,
      lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
      lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
      zoom = mapZoom
    )
  } else {
    o <- fitBounds(
      o,
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  o <- addPolygons(
      o,
      data = choropleth_map,
      fillColor = ~ pal_choropleth_transfers(choropleth_map$transfers),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_transfers)
  o <- addLegend(
    o,
    pal = pal_choropleth_transfers,
    values = choropleth_map$transfers,
    opacity = mapLegendOpacity,
    na.label = "NA",
    title = "Transfers")
  o <- addAwesomeMarkers(
      o,
      data = to_destination,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  o_cat <- leaflet()
  o_cat <- addScaleBar(o_cat)
  o_cat <- addProviderTiles(o_cat, providers$OpenStreetMap.BlackAndWhite)

  if (is.numeric(mapZoom)){
    o_cat <- setView(
      o_cat,
      lat = (mean(originPoints$lat) + mean(destinationPoints$lat)) / 2,
      lng = (mean(originPoints$lon) + mean(destinationPoints$lon)) / 2,
      zoom = mapZoom
    )
  } else {
    o_cat <- fitBounds(
      o_cat,
      min(min(originPoints$lon),min(destinationPoints$lon),choropleth_map@bbox[1]),
      min(min(originPoints$lat),min(destinationPoints$lat),choropleth_map@bbox[2]),
      max(max(originPoints$lon),max(destinationPoints$lon),choropleth_map@bbox[3]),
      max(max(originPoints$lat),max(destinationPoints$lat),choropleth_map@bbox[4]))
  }
  
  o_cat <- addPolygons(
      o_cat,
      data = choropleth_map,
      fillColor = ~ pal_choropleth_cat(choropleth_map$transfers_cat),
      fillOpacity = mapPolygonFillOpacity,
      opacity = mapPolygonLineOpacity,
      color = "#BDBDC3",
      weight = mapPolygonLineWeight,
      popup = popup_transfers)
  o_cat <- addLegend(
    o_cat,
    pal = pal_choropleth_cat,
    values = choropleth_map$transfers_cat,
    opacity = mapLegendOpacity,
    title = "Transfers")
  o_cat <- addAwesomeMarkers(
      o_cat,
      data = to_destination,
      lat = ~ lat,
      lng = ~ lon,
      popup = ~ name,
      icon = makeAwesomeIcon(
        icon = 'hourglass-end',
        markerColor = 'red',
        iconColor = 'white',
        library = "fa")
    )
  
  ######################
  #### SAVE RESULTS ####
  ######################
  
  message("Analysis complete, now saving outputs to ", output.dir, ", please wait.\n")
  
  stamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  
  mapview::mapshot(m, file = paste0(output.dir, "/choropleth_duration-", stamp, ".png"))
  htmlwidgets::saveWidget(m, file = paste0(output.dir, "/choropleth_duration-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_duration-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(m)) # plots map to Viewer
  
  mapview::mapshot(m_cat, file = paste0(output.dir, "/choropleth_duration_cat-", stamp, ".png"))
  htmlwidgets::saveWidget(m_cat, file = paste0(output.dir, "/choropleth_duration_cat-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_duration_cat-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(m_cat)) # plots map to Viewer
  
  mapview::mapshot(n, file = paste0(output.dir, "/choropleth_waitingtime-", stamp, ".png"))
  htmlwidgets::saveWidget(n, file = paste0(output.dir, "/choropleth_waitingtime-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_waitingtime-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(n)) # plots map to Viewer
  
  mapview::mapshot(n_cat, file = paste0(output.dir, "/choropleth_waitingtime_cat-", stamp, ".png"))
  htmlwidgets::saveWidget(n_cat, file = paste0(output.dir, "/choropleth_waitingtime_cat-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_waitingtime_cat-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(n_cat)) # plots map to Viewer
  
  mapview::mapshot(o, file = paste0(output.dir, "/choropleth_transfers-", stamp, ".png"))
  htmlwidgets::saveWidget(o, file = paste0(output.dir, "/choropleth_transfers-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_transfers-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(o)) # plots map to Viewer
  
  mapview::mapshot(o_cat, file = paste0(output.dir, "/choropleth_transfers_cat-", stamp, ".png"))
  htmlwidgets::saveWidget(o_cat, file = paste0(output.dir, "/choropleth_transfers_cat-", stamp, ".html")) # Saves as an interactive HTML webpage
  unlink(paste0(output.dir, "/choropleth_transfers_cat-", stamp, "_files"), recursive = T) # Deletes temporary folder that mapshot creates
  invisible(print(o_cat)) # plots map to Viewer
  
  write.csv(
    choropleth_table,
    file = paste0(output.dir, "/choropleth-", stamp, ".csv"),
    row.names = F
  ) # Saves trip details as a CSV
  
  unlink(paste0(output.dir, "/tmp_folder"), recursive = TRUE) # Deletes tmp_folder if exists
  
  message("Thanks for using propeR.")
}
