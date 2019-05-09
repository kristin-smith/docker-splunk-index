@echo OFF
SETLOCAL EnableDelayedExpansion

REM Prompt the user for the name of the custom application being tested. Assumes the custom application is in the folder that this file is being run from. This folder holds the /bin and /local directories that make it function
set /p "app=Enter the folder name of the custom application you're testing:"
REM validate the custom application exists in the given directory
if not exist %~dp0\!app!\ ( 
	echo "Couldn't locate the application. Please verify your directory name and try again"
	goto:EOF
)
REM change Windows paths to Unix style path formatting before mounting volumes
set dirpath=%~dp0
set dirpath=%dirpath:\=/%
set dirpath=%dirpath:C:=/c%

REM Make sure the splunk network is up. Otherwise, create it
docker network ls|find /c "splunk" >splunknet.txt
set /p splunknet= <splunknet.txt
if %splunknet% LSS 1 (
	docker network create splunk | Echo "splunk network up and running"
)
del splunknet.txt

REM To build the base container
docker image ls|find  /c "splunk-index" >splunkimages.txt
set /p splunkim= <splunkimages.txt
if %splunkim% LSS 1 (
	docker build -t splunk-index --pull . 
) 
Echo "splunk-indexer image is ready"
del splunkimages.txt

REM Check that there are no other splunk-index containers running (port will be allocated already, may get data out of sync)
docker container ls|find /c "splunk-index" >splunkcon.txt
set /p splunkup= <splunkcon.txt
echo "Splunk up is" + %splunkup%
del splunkcon.txt

REM If there are no other instances running, create a new container. Create a volume in /opt/splunk/etc/apps for the application being tested
if %splunkup% EQU 0 (
		Echo "Starting splunk-indexer"
		docker run -dt -p 8000:8000 -p 9997:9997 -p 8189:8089 -v %dirpath%!app!/:/opt/splunk/etc/apps/!app! --net splunk splunk-index
		Echo "splunk-indexer container is ready"
		REM Now that the container is up, find the container ID and open the ports
		docker container ls | findstr splunk-index >splunkid.txt
		for /f %%G IN (splunkid.txt) do set "conid=%%G" & docker exec !conid! /opt/splunk/bin/splunk enable listen 9997 & docker exec !conid! /opt/splunk/bin/splunk enable listen 8189
		del splunkid.txt
	) else (Echo "splunk-indexer already exists, please investigate" 
			PAUSE)
			

