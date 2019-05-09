@echo OFF
SETLOCAL EnableDelayedExpansion
REM This works for custom apps that live on the server (as opposed to deployment apps). 
REM Apps being tested here on the development indexer will probably end up becoming deployment apps on the production indexer

REM Prompt user for application to package
set /p "app=Enter the folder name of the custom application you're testing:"

REM Find the container's ID so we can run docker commands against it
docker container ls | findstr splunk-index >splunkid.txt

REM package the application being tested and copy over to the mount point
for /f %%G IN (splunkid.txt) do (
	REM validate the custom application exists in the Splunk instance
	docker exec %%G bash -c "ls /opt/splunk/etc/apps | grep %app%">app-check.txt
	FOR /F "USEBACKQ" %%F IN (`find /C "%app%" ^< "app-check.txt"`) DO (
		SET appcheck=%%F
	)
	del app-check.txt
	if  !appcheck! LSS 1 (
		echo "This app was not found in Splunk. Please validate your application name."
		GOTO:EOF
	) 
	
	REM Package the application
	docker exec -it %%G bash -c "/opt/splunk/bin/splunk package app %app% -timeout 200"
	docker exec  %%G bash -c "cp -r /opt/splunk/etc/system/static/app-packages/%app%.spl /opt/splunk/etc/apps/%app%"
	
	REM copy from the default location into the container's volume so it's accessible on local workstations
	echo "A copy of the package has been placed in /opt/splunk/etc/apps/%app%"
)
