##' Checks the validity of locations for isochrones
##'
##' Calculates the journey time and details between multiple origins and/or destinations. 
##' A comma separated value file of journey details is saved in the output folder.
##'
##' @param output.dir The directory for the output files
##' @param otpcon The OTP router URL, see ?otpcon for details
##' @param locationPoints The variable containing origin(s), see ?importLocationData for details
##' @param modes The mode of the journey, defaults to 'WALK'
##' @param cutoff Specify the isochrone cutoff distance, defaults to 20 mins
##' @param infoPrint Specifies whether you want some information printed to the console or not, default is TRUE
##' @author Michael Hodge
##' @examples
##' @donotrun{
##'   locationValidatorIsochrone(
##'     output.dir = 'C:\Users\User\Documents',
##'     otpcon,
##'     locationPoints
##'   )
##' }
##' @export
locationValidatorIsochrone <- function(output.dir,
                                       otpcon = otpcon,
                                       locationPoints = originPoints,
                                       modes = 'WALK',
                                       cutoff = 20,
                                       infoPrint = T) {
  
  #########################
  #### SETUP VARIABLES ####
  #########################
  
  num.total <- nrow(locationPoints)
  
  file_name <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  file_name <- gsub("[^A-Za-z0-9]", "_", file_name)
  
  unlink(paste0(output.dir, "/locationChecker-", file_name) , recursive = T) 
  dir.create(paste0(output.dir, "/locationChecker-", file_name)) 
  dir.create(paste0(output.dir, "/locationChecker-", file_name, "/csv")) 
  
  if (infoPrint == T) {
    cat("Now running the propeR locationValidatorIsochrone tool.\n", sep="")
  }
  
  ###########################
  #### CALL OTP FUNCTION ####
  ###########################
  
  num.run <- 0
  
  startDateAndTime = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  start_time <- format(as.POSIXct(startDateAndTime), "%I:%M %p") 
  start_date <- as.Date(startDateAndTime)
  time.taken <- vector()
  calls.list <- c(0)
  if (infoPrint == T) {
    cat("Creating ", num.total, " checks, please wait...\n")
  }
  
  pb <- progress::progress_bar$new(
    format = "  running, changes made :what [:bar] :percent eta: :eta",
    total = num.total, clear = FALSE, width= 60)
  
  calls = {}
  
  locationPoints$mod <- 0
  
  check <- function(otpcon, from_origin, start_date, start_time, modes, cutoff){
    isochrone <- propeR::otpIsochrone(
      otpcon,
      batch = T,
      from = from_origin$lat_lon,
      to = from_origin$lat_lon,
      modes = modes,
      cutoff = cutoff,
      date = start_date,
      time = start_time
    )
    return(isochrone)
  }
  
  i <- 1
  
  repeat  {
    from_origin <- locationPoints[i,]
    
    isochrone <- check(otpcon, from_origin, start_date, start_time, modes, cutoff)
    
    if (isochrone$status == "ERROR"){
      
      if (locationPoints$mod[i] > 0){
        locationPoints$lat[i] <- locationPoints$lat[i] + ((runif(1, 0.01, 0.05) * sample(c(-1,1),size=1)) * locationPoints$mod[i])
        locationPoints$lon[i] <- locationPoints$lon[i] + ((runif(1, 0.01, 0.05) * sample(c(-1,1),size=1)) * locationPoints$mod[i])
        locationPoints$lat_lon[i] <- paste0(locationPoints$lat[i], ",", locationPoints$lon[i])
      } else {
        locationPoints$lat[i] <- locationPoints$lat[i]
        locationPoints$lon[i] <- locationPoints$lon[i]
        locationPoints$lat_lon[i] <- paste0(locationPoints$lat[i], ",", locationPoints$lon[i])
      }
      
      from_origin <- locationPoints[i,]
      
      df <- propeR::nominatimNodeSearch(from_origin$lat, from_origin$lon)
      sp::coordinates(from_origin) <- c("lon","lat")
      sp::coordinates(df) <- c("lon","lat")
      
      g = FNN::get.knnx(sp::coordinates(df), sp::coordinates(from_origin), k = 1)
      pair = g$nn.index
      
      locationPoints$lat[i] <- df[pair[1,1],]$lat
      locationPoints$lon[i] <- df[pair[1,1],]$lon
      locationPoints$lat_lon[i] <- paste0(locationPoints$lat[i], ",", locationPoints$lon[i])
      
      locationPoints$mod[i] <- locationPoints$mod[i] + 1
      
      if (!(i %in% calls)){
        calls <- cbind(i,calls)
      }
      
    } else {
      i <- i + 1
      pb$tick(tokens = list(what = length(calls)))
    }
    
    if (i == nrow(locationPoints)){
      break
    }
  }
  
  if (infoPrint == T) {
    cat("\nValidation complete, now saving outputs to ", output.dir, ", please wait.\n", sep="")
    # cat("Journey details:\n", sep = "")
    # cat("Trips possible: ", nrow(point_to_point_table_overview[!is.na(point_to_point_table_overview$duration_mins),]),"/",num.total,"\n", sep = "")
  }
  
  write.csv(
    locationPoints,
    file = paste0(output.dir, "/locationChecker-", file_name, "/csv/locationChecker-", file_name, ".csv"),
    row.names = F)
  if (infoPrint == T) {
    cat("Outputs saved. Thanks for using propeR.\n")
  }
  
  output_df <- locationPoints
  
}
