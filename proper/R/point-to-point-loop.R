##' Calculates the journey for a number of origins and/or destinations.
##'
##' Calculates the journey time and details between multiple origins and/or destinations. 
##' A comma separated value file of journey details is saved in the output folder.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param originPoints The variable containing origin(s), see ?importLocationData for details
##' @param originPointsRow The row of originPoints to be used, defaults to 1
##' @param destinationPoints The variable containing destination(s) see ?importLocationData for details
##' @param destinationPointsRow The row of destinationPoints to be used, defaults to 1
##' @param journeyLoop Specifies the type of loop, only origins (1), only destinations (2), both (0, default), or fixed (3)
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
##' @param preWaitTime The maximum waiting time before a journey cannot be found, in minutes, defaults to 15 mins
##' @param estimateCost Specify whether to estimate costs of journey or not (default is False)
##' @param busTicketPrice Specifiy the cost of a bus journey (default is 3 GPB)
##' @param busTicketPriceMax Specifiy the maximum cost of a bus journey (default is 12 GPB)
##' @param trainTicketPriceKm Specifiy the cost of a train journey per km (default is 0.12 GPB per km)
##' @param trainTicketPriceMin Specifiy the minimum cost of a train journey (default is 3 GBP)
##' @param infoPrint Specifies whether you want some information printed to the console or not, default is TRUE
##' @param geojsonOutput Specifies whether you want to output the polylines as a geojson, defaults to FALSE
##' @param failSafeSave Specify the failsafe save number for large datasets, default is 100
##' @return Saves journey details as comma separated value file to output directory
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   pointToPointLoop(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     originPoints,
##'     destinationPoints,
##'     journeyLoop = 0,
##'     journeyReturn = TRUE,
##'     startDateAndTime = "2018-08-18 12:00:00"
##'   )
##' }
##' @export
pointToPointLoop <- function(output.dir,
                             otpcon,
                             originPoints,
                             originPointsRow = 1,
                             destinationPoints,
                             destinationPointsRow = 1,
                             journeyLoop = 0,
                             journeyReturn = F,
                             # otpTime args
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
                             preWaitTime = 15,
                             distThreshold = F,
                             distMax = 20,
                             estimateCost = F,
                             busTicketPrice = 3,
                             busTicketPriceMax = 12,
                             trainTicketPriceKm = 0.12,
                             trainTicketPriceMin = 3,
                             infoPrint = T,
                             geojsonOutput = F,
                             failSafeSave = 100) {
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  if (journeyReturn == T) { multiplier <- 2 } else { multiplier <- 1 }
  
  if (journeyLoop == 0) {
    originPointsEnd <- nrow(originPoints)
    destinationPointsEnd <- nrow(destinationPoints)
  } else if (journeyLoop == 1) {
    originPointsEnd <- nrow(originPoints)
    destinationPointsEnd <- 1
    destination_points_row_num <-destinationPointsRow
    
    if (destination_points_row_num > nrow(destinationPoints)) {
      stop('Row is not in destination file')
    }
    
  } else if (journeyLoop == 2) {
    originPointsEnd <- 1
    destinationPointsEnd <- nrow(destinationPoints)
    origin_points_row_num <- originPointsRow
    
    if (origin_points_row_num > nrow(originPoints)) {
      stop('Row is not in origin file')
    }
    
  } else if (journeyLoop == 3) {
    originPointsEnd <- nrow(originPoints)
    destinationPointsEnd <- 1
  } else {
    stop('Parameter type for journeyLoop unknown')
  }
  
  num.total <- (originPointsEnd * destinationPointsEnd) * multiplier
  
  file_name <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)
  
  unlink(paste0(output.dir, "/pointToPointLoop-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/pointToPointLoop-", file_name)) 
  dir.create(paste0(output.dir, "/pointToPointLoop-", file_name, "/csv")) 
  
  if (geojsonOutput == T){
    dir.create(paste0(output.dir, "/pointToPointLoop-", file_name, "/geojson"))
  }
  
  if (infoPrint == T) {
    cat("Now running the propeR pointToPointLoop tool.\n", sep="")
    cat("Parameters chosen:\n", sep="")
    if (journeyLoop == 0) {
      cat("Loop Type: Origin and destination (", num.total, " calls)\n", sep="")
    } else if (journeyLoop == 1) {
      cat("Loop Type: Origin only (", num.total, " calls)\n", sep="")
    } else if (journeyLoop == 2) {
      cat("Loop Type: Destination only (", num.total, " calls)\n", sep="")
    } else if (journeyLoop == 3) {
      cat("Loop Type: Origin and Destination are fixed (", num.total, " calls)\n", sep="")
    }
    cat("Return Journey: ", journeyReturn, "\n", sep="")
    cat("Date and Time: ", startDateAndTime, "\n", sep="")
    cat("Outputs: CSV [TRUE] GeoJSON [", geojsonOutput, "]\n\n", sep="")
  }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.run <- 0
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p") 
  start_date <- as.Date(startDateAndTime)
  time.taken <- vector()
  calls.list <- c(0)
  if (infoPrint == T) {
    cat("Creating ", num.total, " point to point connections, please wait...\n")
  }
  
  make_blank_df <- function(from, to, modes) {
    
    if (modes == "CAR") {
      df <- data.frame(
        "origin" = from$name,
        "destination" = to$name,
        "start_time" = NA,
        "end_time" = NA,
        "distance_km" = NA,
        "duration_mins" = NA,
        "walk_distance_km" = NA,
        "drive_time_mins" = NA,
        "transit_time_mins" = NA,
        "waiting_time_mins" = NA,
        "pre_waiting_time_mins" = NA,
        "transfers" = NA,
        "cost" = NA,
        "no_of_buses" = NA,
        "no_of_trains" = NA,
        "journey_details" = NA)
    } else if (modes == "BICYCLE") {
      df <- data.frame(
        "origin" = from$name,
        "destination" = to$name,
        "start_time" = NA,
        "end_time" = NA,
        "distance_km" = NA,
        "duration_mins" = NA,
        "walk_distance_km" = NA,
        "cycle_time_mins" = NA,
        "transit_time_mins" = NA,
        "waiting_time_mins" = NA,
        "pre_waiting_time_mins" = NA,
        "transfers" = NA,
        "cost" = NA,
        "no_of_buses" = NA,
        "no_of_trains" = NA,
        "journey_details" = NA)
    } else {
      df <- data.frame(
        "origin" = from$name,
        "destination" = to$name,
        "start_time" = NA,
        "end_time" = NA,
        "distance_km" = NA,
        "duration_mins" = NA,
        "walk_distance_km" = NA,
        "walk_time_mins" = NA,
        "transit_time_mins" = NA,
        "waiting_time_mins" = NA,
        "pre_waiting_time_mins" = NA,
        "transfers" = NA,
        "cost" = NA,
        "no_of_buses" = NA,
        "no_of_trains" = NA,
        "journey_details" = NA)
    }
    df
  }
  
  if (infoPrint == T) {
    pb <- progress::progress_bar$new(
      format = "  Travel time calculation complete for call :what [:bar] :percent eta: :eta",
      total = num.total, clear = FALSE, width= 100)
  }
  
  for (j in 1:multiplier) {
    
    for (k in 1:destinationPointsEnd) {
      
      for (i in 1:originPointsEnd) {
        
        num.run <- num.run + 1
        
        if (journeyLoop == 0) {
          from_origin <- originPoints[i,]
          to_destination <- destinationPoints[k,]
        } else if (journeyLoop == 1) {
          from_origin <- originPoints[i,]
          to_destination <- destinationPoints[destinationPointsRow, ]
        } else if (journeyLoop == 2) {
          from_origin <- originPoints[originPointsRow,]
          to_destination <- destinationPoints[k, ]
        } else if (journeyLoop == 3) {
          from_origin <- originPoints[i,]
          to_destination <- destinationPoints[i, ]
        }
        
        if (j == 1) {
          from <- from_origin
          to <- to_destination
        } else {
          to <- from_origin
          from <- to_destination
        }
        
        point_to_point <- propeR::otpTripTime(
          otpcon,
          detail = T,
          from_name = from$name,
          from_lat_lon = from$lat_lon,
          to_name = to$name,
          to_lat_lon = to$lat_lon,
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
              
              #########################
              #### OPTIONAL EXTRAS ####
              #########################
              
              if (geojsonOutput == T) {
                poly_lines <- point_to_point$poly_lines
                poly_lines <- sp::spTransform(poly_lines, sp::CRS("+init=epsg:4326"))
              }
              
              if (geojsonOutput == T) {
                rgdal::writeOGR(
                  poly_lines,
                  dsn = paste0(output.dir,
                               "/pointToPointLoop-", 
                               file_name,
                               "/geojson/pointToPointLoop-",
                               from$name,
                               "-",
                               to$name,
                               ".geoJSON"),
                  layer = "poly_lines",
                  driver = "GeoJSON")
              }
              
            } else {
              point_to_point_table_overview <- make_blank_df(from, to, modes)
            }
            
          } else {
            point_to_point_table_overview <- make_blank_df(from, to, modes)
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
              
              point_to_point_table_overview_tmp <- point_to_point$itineraries
              point_to_point_table_overview_tmp["cost"] <- round(cost, digits = 2)
              point_to_point_table_overview_tmp["no_of_buses"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'BUS',])
              point_to_point_table_overview_tmp["no_of_trains"] <- nrow(point_to_point$output_table[point_to_point$output_table$mode == 'RAIL',])
              point_to_point_table_overview_tmp["journey_details"] <- jsonlite::toJSON(point_to_point$output_table)
              
              #########################
              #### OPTIONAL EXTRAS ####
              #########################
              
              if (geojsonOutput == T) {
                poly_lines <- point_to_point$poly_lines
                poly_lines <- sp::spTransform(poly_lines, sp::CRS("+init=epsg:4326"))
              }
              
              if (geojsonOutput == T) {
                rgdal::writeOGR(
                  poly_lines,
                  dsn = paste0(output.dir,
                               "/pointToPointLoop-", 
                               file_name,
                               "/geojson/pointToPointLoop-",
                               from$name,
                               "-",
                               to$name,
                               ".geoJSON"),
                  layer = "poly_lines",
                  driver = "GeoJSON")
              }
              
            } else {
              point_to_point_table_overview_tmp <- make_blank_df(from, to, modes)
            }
            
            point_to_point_table_overview <- rbind(point_to_point_table_overview, point_to_point_table_overview_tmp)
          } else {
            point_to_point_table_overview_tmp <- make_blank_df(from, to, modes)
            
            point_to_point_table_overview <- rbind(point_to_point_table_overview, point_to_point_table_overview_tmp)
          }
        }
        
        if (infoPrint == T) {
          pb$tick(tokens = list(what = num.run))
        }
        
        if ((num.run/failSafeSave) %% 1 == 0) { # fail safe for large files
          
          point_to_point_table_overview_out <- point_to_point_table_overview
          
          if (modes == "CAR") {
            colnames(point_to_point_table_overview_out)[which(names(point_to_point_table_overview_out) == "walk_time_mins")] <- "drive_time_mins"
          } else if (modes == "BICYCLE") {
            colnames(point_to_point_table_overview_out)[which(names(point_to_point_table_overview_out) == "walk_time_mins")] <- "cycle_time_mins"
          }
          
          write.csv(
            point_to_point_table_overview_out,
            file = paste0(output.dir, "/pointToPointLoop-", file_name, "/csv/pointToPointLoop-", file_name, ".csv"),
            row.names = F) 
          
          
        }
      }
    }
  }
  
  if (infoPrint == T) {
    cat("\nAnalysis complete, now saving outputs to ", output.dir, ", please wait.\n", sep="")
    cat("Journey details:\n", sep = "")
    cat("Trips possible: ", nrow(point_to_point_table_overview[!is.na(point_to_point_table_overview$duration_mins),]),"/",num.total,"\n\n", sep = "")
  }
  
  if (modes == "CAR") {
    colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "drive_time_mins"
  } else if (modes == "BICYCLE") {
    colnames(point_to_point_table_overview)[which(names(point_to_point_table_overview) == "walk_time_mins")] <- "cycle_time_mins"
  }
  
  write.csv(
    point_to_point_table_overview,
    file = paste0(output.dir, "/pointToPointLoop-", file_name, "/csv/pointToPointLoop-", file_name, ".csv"),
    row.names = F) 
  
  if (infoPrint == T){
    cat("Outputs were saved to ", output.dir, "/pointToPointLoop-", file_name,"/.\nThanks for using propeR.", sep="")
  }
  
  output <- point_to_point_table_overview
}
