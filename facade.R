## Rscript --vanilla facade.R 'otp.host="192.168.0.2", otp.port=8080, fun=pointToPoint,src_file="origin.csv", dst_file="destination.csv", output.dir="/tmp/a2s", startDateAndTime="2019-08-02 12:00:00", mapOutput=T' 

suppressMessages(library(propeR))

connect <- (function() {
  otp <- NULL
  function() {
    if(is.null(otp)) {
      otp <<- otpConnect()
    }
    otp
  }
})()

generate <- function(otp.host="localhost", otp.port=8080, otp.router="default", otp.ssl=FALSE, fun, src_file, dst_file, ...) {
  otp <- otpConnect(hostname=otp.host, port=otp.port, router=otp.router, ssl=otp.ssl)
  src.points <- importLocationData(src_file)
  dst.points <- importLocationData(dst_file)
  do.call(fun, list(otpcon=otp, originPoints=src.points, destinationPoints=dst.points, ...))
}

if(!interactive()) {
  args.str <- commandArgs(trailingOnly=T)
  args.lst <- eval(parse(text=paste0("list(", args.str, ")")))
  stopifnot("fun" %in% names(args.lst))
  do.call(generate, args.lst)
}
