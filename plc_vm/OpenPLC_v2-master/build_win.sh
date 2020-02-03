#!/bin/bash
echo Building OpenPLC environment:

echo [MATIEC COMPILER]
cp ./matiec_src/bin_win32/iec2c.exe ./
cp ./matiec_src/bin_win32/*.dll ./

echo [LADDER]
./iec2c.exe ./st_files/blank_program.st
mv -f POUS.c POUS.h LOCATED_VARIABLES.h VARIABLES.csv Config0.c Config0.h Res0.c ./core/

echo [ST OPTIMIZER]
cd st_optimizer_src
g++ st_optimizer.cpp -o st_optimizer
cd ..
cp ./st_optimizer_src/st_optimizer.exe ./

echo [GLUE GENERATOR]
cd glue_generator_src
g++ glue_generator.cpp -o glue_generator
cd ..
cp ./glue_generator_src/glue_generator.exe ./core/glue_generator.exe

clear
echo Disabling DNP3 support \(opendnp3 is not compatible with Cygwin\)...
mv ./core/dnp3.cpp ./core/dnp3.disabled 2> /dev/null
mv ./core/dnp3_dummy.disabled ./core/dnp3_dummy.cpp 2> /dev/null
cp -f ./core/core_builders/dnp3_disabled/*.* ./core/core_builders/

cd core
rm -f ./hardware_layer.cpp
rm -f ../build_core.sh

echo The OpenPLC needs a driver to be able to control physical or virtual hardware.
echo Please select the driver you would like to use:
OPTIONS="Blank Modbus Fischertechnik RaspberryPi UniPi PiXtend PiXtend_2S Arduino ESP8266 Arduino+RaspberryPi Simulink "
select opt in $OPTIONS; do
	if [ "$opt" = "Blank" ]; then
		cp ./hardware_layers/blank.cpp ./hardware_layer.cpp
		cp ./core_builders/build_normal.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "Modbus" ]; then
		cp ./hardware_layers/modbus_master.cpp ./hardware_layer.cpp
		cp ./core_builders/build_modbus_win.sh ../build_core.sh
		echo [LIBMODBUS]
		cd ..
		cd libmodbus_src
		./autogen.sh
		./configure
		make install
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "Fischertechnik" ]; then
		cp ./hardware_layers/fischertechnik.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "RaspberryPi" ]; then
		cp ./hardware_layers/raspberrypi.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "UniPi" ]; then
		cp ./hardware_layers/unipi.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "PiXtend" ]; then
		cp ./hardware_layers/pixtend.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
    elif [ "$opt" = "PiXtend_2S" ]; then
		cp ./hardware_layers/pixtend2s.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		exit
	elif [ "$opt" = "Arduino" ]; then
		cp ./hardware_layers/arduino.cpp ./hardware_layer.cpp
		cp ./core_builders/build_normal.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "ESP8266" ]; then
		cp ./hardware_layers/esp8266.cpp ./hardware_layer.cpp
		cp ./core_builders/build_normal.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "Arduino+RaspberryPi" ]; then
		cp ./hardware_layers/arduino.cpp ./hardware_layer.cpp
		cp ./core_builders/build_rpi.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	elif [ "$opt" = "Simulink" ]; then
		cp ./hardware_layers/simulink.cpp ./hardware_layer.cpp
		cp ./core_builders/build_normal.sh ../build_core.sh
		echo [OPENPLC]
		cd ..
		./build_core.sh
		echo 'export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"' >> ~/.bashrc
		exit
	else
		#clear
		echo bad option
	fi
done
