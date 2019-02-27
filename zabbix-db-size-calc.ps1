#Zabbix DB Size calculator
#https://www.zabbix.com/documentation/2.4/manual/installation/requirements#database_size
function Get-zabbixDBsize {
	param ($items, $history, $refreshRate=60, $trendsYears=3, $valuesPerSec)
	
	if (!$psboundparameters.count) {
		write-host "Example: get-zabbixDBsize -items 11284 -history 30 -trendsYears 3 -valuesPerSec 250" -f yellow
		write-host "Note1: The following values obtained from Zabbix Dashboard: Status of Zabbix: items, valuesPerSec" -f green
		write-host "Note2: The following values obtained from Templates: history and trends years" -f green
		return
	}
	
	#Zabbix configuration 	Fixed size. Normally 10MB or less.
	
	#For example, if we have 3000 items for monitoring with refresh rate of 60 seconds, the number of values per second is calculated as 3000/60 = 50.
	#It means that 50 new values are added to Zabbix database every second.
	if (!$valuesPerSec) {$valuesPerSec=$items/$refreshRate}
	#housekeeper settings for history:
	#If we would like to keep 30 days of history and we receive 50 values per second, total number of values will be around (30*24*3600)* 50 = 129.600.000, or about 130M of values.
	#days*(items/refresh rate)*24*3600*bytes
	#items	: number of items
	#days 	: number of days to keep history
	#refresh rate : average refresh rate of items
	#bytes 	: number of bytes required to keep single value, depends on database engine, normally 50 bytes.
	$totalValues=($history*24*3600)*$valuesPerSec
	#Depending on the database engine used, type of received values (floats, integers, strings, log files, etc), the disk space for keeping a single value may vary from 40 bytes to hundreds of bytes.
	#Normally it is around 50 bytes per value. In our case, it means that 130M of values will require 130M * 50 bytes = 6.5GB of disk space.
	$historyDiskSpaceGB=$totalValues*50/1000000000
	$historyDiskSpaceMB=$totalValues*50/1000000
	#Housekeeper setting for trends:
	#Zabbix keeps a 1-hour max/min/avg/count set of values for each item in the table trends. The data is used for trending and long period graphs. The one hour period can not be customised. 
	#Zabbix database, depending on database type, requires about 128 bytes per each total. Suppose we would like to keep trend data for 5 years. Values for 3000 items will require 3000*24*365* 128 = 3.4GB per year, or 16.8GB for 5 years.
	#days*(items/3600)*24*3600*bytes
	#items : number of items
	#days : number of days to keep history
	#bytes : number of bytes required to keep single trend, depends on database engine, normally 128 bytes.
	$trendsDiskSpaceGB=$items*24*365*$trendsYears*128/1000000000
	$trendsDiskSpaceMB=$items*24*365*$trendsYears*128/1000000
	#Housekeeper settings for events
	#Each Zabbix event requires approximately 130 bytes of disk space. It is hard to estimate the number of events generated by Zabbix daily. In the worst case scenario, we may assume that Zabbix generates one event per second. 
	#It means that if we want to keep 3 years of events, this would require 3*365*24*3600* 130 = 12.3GB
	#days*events*24*3600*bytes
	#events : number of event per second. One (1) event per second in worst case scenario.
	#days : number of days to keep history
	#bytes : number of bytes required to keep single trend, depends on database engine, normally 130 bytes
	$eventsDiskSpaceGB=3*365*24*3600*130/1000000000
	$eventsDiskSpaceMB=3*365*24*3600*130/1000000
	
	$totalDBSizeGB=$historyDiskSpaceGB+$trendsDiskSpaceGB+$eventsDiskSpaceGB+0.01
	$totalDBSizeMB=$historyDiskSpaceMB+$trendsDiskSpaceMB+$eventsDiskSpaceMB+10
	
	write-host "Zabbix projected DBSize in GB = $("{0:N2}" -f $totalDBSizeGB)" -f cyan
	write-host "Zabbix projected DBSize in MB = $("{0:N2}" -f $totalDBSizeMB)" -f cyan
} 
