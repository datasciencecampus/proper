input_path = '/Users/michaelhodge/Documents/access-to-services/a2s-applied-projects/output/emu/output_area_run/private_transport/private_transport_k3'
fix_path = '/Users/michaelhodge/Downloads/k3_pri/csv/pointToPointNearest-2019_07_18_15_16_53.csv'

input <- read.csv(paste0(input_path,'.csv'), stringsAsFactors = F)
fix <- read.csv(fix_path, stringsAsFactors = F)

a <- match(fix$origin, input$origin)
a <- a[!is.na(a)]

num <- 1

for (i in a){
  input[i,] <- fix[num,]
  num <- num + 1
}

a <- match(fix$destination, input$destination)
a <- a[!is.na(a)]
a <- a[!duplicated(a)]
a <- a[2:length(a)]

for (i in a){
  input[i,] <- fix[num,]
  num <- num + 1
}

write.csv(input,paste0(input_path,'_new.csv'))