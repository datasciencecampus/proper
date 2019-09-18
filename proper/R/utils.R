##' A simple postcode to latitude and longitude converter.
##'
##' Generates a latitude and longitude (in decimal degrees) based on the postcode.
##'
##' @param postcode UK postcode
##' @return The latitude and longitude in decimal degrees.
##' @author Michael Hodge
##' @examples
##' @donotrun{
##' postcodeToDecimalDegrees('NP10 8XG')
##' }
##' @export
postcodeToDecimalDegrees <- function(postcode) {
  r <-
    jsonlite::fromJSON(paste0("http://api.getthedata.com/postcode/", postcode))
}

##' A backup postcode to latitude and longitude converter.
##'
##' Generates a latitude and longitude (in decimal degrees) based on the postcode.
##'
##' @param postcode UK postcode
##' @return The latitude and longitude in decimal degrees.
##' @author Michael Hodge
##' @examples
##' @donotrun{
##' postcodeToDecimalDegrees_backup('NP10 8XG')
##' }
##' @export
postcodeToDecimalDegrees_backup <- function(postcode) {
  r <-
    httr::GET(paste0("http://api.postcodes.io/postcodes/", postcode))
  httr::content(r)
}

##' Postcode autocomplete
##'
##' Generates a postcode from a partial postcode
##'
##' @param postcode UK postcode
##' @return The latitude and longitude in decimal degrees.
##' @author Michael Hodge
##' @examples
##' @donotrun{
##' postcodeToDecimalDegrees_backup('NP10 8XG')
##' }
##' @export
postcodeComplete <- function(postcode) {
  r <-
    httr::GET(paste0("http://api.postcodes.io/postcodes/", postcode,'/autocomplete'))
  httr::content(r)
}

##' Finds list of nodes near a lat and lon
##'
##' Finds list of nodes near a lat and lon
##'
##' @param lat latitude
##' @param lon longitude
##' @return dataframe of lats and lons of nearest nodes
##' @author Michael Hodge
##' @examples
##' @donotrun{
##' nominatimNodeSearch(lat, lon)
##' }
##' @export
nominatimNodeSearch <- function(lat, lon) {
  r <- jsonlite::fromJSON(paste0("https://nominatim.openstreetmap.org/search?q=", lat, "%2C", lon, "&format=json"))
  r <- r$polygonpoints
  r  <-  as.data.frame(list('lat' = as.numeric(r[[1]][,2]), 'lon' = as.numeric(r[[1]][,1])), stringsAsFactors = FALSE)
  r
}

##' Finds lthe nearest object to a lat and lon
##'
##' Finds lthe nearest object to a lat and lon
##'
##' @param lat latitude
##' @param lon longitude
##' @param object the object you want to search for (e.g. pub)
##' @return dataframe of lats and lons of nearest nodes
##' @author Michael Hodge
##' @examples
##' @donotrun{
##' nominatimNodeSearch(lat, lon)
##' }
##' @export
nominatimObjectSearch <- function(lat, lon, object) {
  r <- jsonlite::fromJSON(paste0("https://nominatim.openstreetmap.org/search?q=", object,"+near+", lat, "%2C", lon, "&format=json"))
  r
}
