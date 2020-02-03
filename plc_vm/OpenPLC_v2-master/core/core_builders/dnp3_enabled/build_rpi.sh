#!/bin/bash
cd core
echo Generating object files...
g++ -std=gnu++11 -I ./lib -c Config0.c -lasiodnp3 -lasiopal -lopendnp3 -lopenpal -Wno-narrowing
g++ -std=gnu++11 -I ./lib -c Res0.c -lasiodnp3 -lasiopal -lopendnp3 -lopenpal -Wno-narrowing

echo Generating glueVars.cpp
./glue_generator
echo Compiling main program
g++ -std=gnu++11 *.cpp *.o -o openplc -I ./lib -lrt -lwiringPi -lpthread -fpermissive -lasiodnp3 -lasiopal -lopendnp3 -lopenpal -Wno-narrowing
cd ..
