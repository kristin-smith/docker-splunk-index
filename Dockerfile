# Use an official Splunk runtime as the parent image
FROM splunk/splunk:7.0.0

#Set working directory when you drop in
WORKDIR /opt/splunk/etc/apps

# Install telnet and netstat (issues running it on 7.0.0)
#RUN sudo apt-get update && sudo apt-get install -y telnet net-tools 

#Set Timezone to Denver
RUN cd /etc && sudo rm localtime && sudo ln -s /usr/share/zoneinfo/US/Mountain localtime
RUN bash -c "export TZ=America/Denver; echo \$TZ" 
RUN sudo dpkg-reconfigure -f noninteractive tzdata

#Open web port
EXPOSE 8000/tcp
EXPOSE 9997/tcp
EXPOSE 8189/tcp

#Set Splunk variables
ENV SPLUNK_START_ARGS "--accept-license --answer-yes"  
ENV SPLUNK_PASSWORD="change+me"




