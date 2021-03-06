

library(lubridate)

water=read.csv('./data/base/WaterDepth2013To2019.csv', stringsAsFactor=F)

#Load station name conversion function.
source('./data/base/AccessToWildtrax.R')
colnames(water)=c('VegDate', 'Plot', 'Distance', 'Depth', 'StationKey')
colnames(water)[5]='Station'
water$WTStation=AccessToWildtrax(water$Station)
#Collapse stations ending in 2, 3, etc. as Erin did.
x=water$WTStation[substr(water$WTStation,nchar(water$WTStation),nchar(water$WTStation)) %in% c("2", '3', '4', '5')]
y=substr(x, 1, nchar(x)-1)
water$WTStation[substr(water$WTStation,nchar(water$WTStation),nchar(water$WTStation)) %in% c("2", '3', '4', '5')]=y
rm(list=c('x', 'y'))

water$VegDate=as.Date(water$VegDate)

water=water[order(water$VegDate),]
water=water[order(water$Station),]
water=water[,c('WTStation','Station','VegDate', 'Plot', 'Distance', 'Depth')]
water$year=year(water$VegDate)



sort(unique(water$Depth))

#There are a lot of unusual values in the Depth column.
#Some other ones are clearly measured in meters, while others are in cm.


table(water$Distance, water$year)
table(water$Plot, water$Distance)

#One unusual thing is distances of 1, 2, and 3. Apparently the explanation
#for that is that the measures were taken 3 times at each point.
#So when you have C and distance=2, it's actually the second
#measure at C. With N and distance=1, it's the first measure at 10 m N.
#Cardinal directions were apparently all at 10m in that case.
#I'm just going to take the first measurement. Averaging the 3 would
#be another option, but I don't think thats best because an averaged
#value has different properties than a single measurement.

water$Distance[water$Distance==1 & water$Plot=='C']=0
water$Distance[water$Distance==1 & water$Plot %in% c('N', 'E', 'S', 'W')]=10
water$Distance[water$Distance %in% c(2,3)]=NA

#I'm going to sort that out later. For now I'll just remove weird values.

water$Distance[water$Distance==99]=NA
water$Distance[water$Plot %in% c("",'NE', 'NW','SE', 'SSW', 'SW')]=NA
water$Distance[water$Plot %in% c('E', 'N', 'S', 'W') & water$Distance==0]=NA
water$Distance[water$Plot == 'C' & water$Distance!=0]=NA
#2019-12-06: changed from restricting to 101cm to restricting to <49cm because
#I discovered that many data shetts have >50 as a value, which was
#converted to 51. Not useful for change analysis.
water$Distance[water$Depth>49 | water$Depth<0]=NA

water=water[!is.na(water$Distance),]
water=water[!is.na(water$Depth),]
#Looks much better, and overall doesn't change the total number of
#water measurements by a whole lot.
table(water$Distance, water$year)
table(water$Plot, water$Distance)


#Restrict water data to our trend stations. Have to account for
#Some stations in access having 2, 3, etc. tacked onto the end.

SurveyData=read.csv('./data/processed/yera_occupy_2013-18_new.csv', header=T, stringsAsFactors=F)
SurveyStations=sort(unique(SurveyData$ss))


water=water[water$WTStation %in% SurveyStations,]
#Check that all SurveyStations have water data. Not all do, but
#after checking, this seems to be "true" missing data, rather than the names
#not aligning between two datasets.
sum(SurveyStations %in% water$WTStation)==length(SurveyStations)

SurveyStations[which(!SurveyStations %in% water$WTStation)]

#New name for each station-direction-distance depth measurement.

water$SDD=paste0(water$Station, "-",water$Plot,'-', water$Distance)
length(unique(water$SDD)) #almost 10000 unique station-direction-distance stations.
table(table(water$SDD)) #More than half have >1 year of data, so that's good.


#Fill out a table with SDD, all years of water depth.

Y=paste0('x',sort(unique(water$year)))

YDF=as.data.frame(matrix(NA,ncol=length(Y), nrow=1))
colnames(YDF)=Y
S=sort(unique(water$SDD))

for(i in 1:length(S)) {
  Point=S[i]
  Subset=water[water$SDD==Point,]
  Station=Subset$Station[1]
  WTStation=Subset$WTStation[1]
  df=data.frame(SDD=Point,WTStation, Station)
  df=cbind(df,YDF)
  df$NYears=nrow(Subset)
  for(j in 1:nrow(Subset)) {
    year=Subset$year[j]
    D=Subset$Depth[j]
    colname=paste0('x',year)
    df[,colname]=D
  }
  if(i==1) {OUT=df} else {OUT=rbind(OUT,df)}
}

rm(list=ls()[!ls()%in%c('OUT','water','SurveyData')])

write.csv(water, './data/processed/LongWaterMeasurements.csv', row.names=F)
write.csv(OUT, './data/processed/WaterMeasurementsByPoint.csv', row.names=F)



