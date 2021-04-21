FROM ubuntu:xenial

#Update repos and install packages
RUN apt-get update
RUN apt-get install -y libjsoncpp-dev liblapacke-dev python-pymodbus build-essential apache2 php libapache2-mod-php
RUN apt-get install -y sudo

#Build the app
COPY . /opt/simulation
WORKDIR /opt/simulation/simulation
RUN make
RUN rm /var/www/html/index.html
RUN ln -s /opt/simulation/web_visualization/* /var/www/html

#Start the server
CMD service apache2 start; ./remote_io/modbus/run_all.sh && ./simulation
