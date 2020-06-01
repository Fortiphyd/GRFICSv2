#!/bin/bash

sim_path=/home/user/GRFICSv2/simulation_vm/simulation/remote_io/modbus
sudo pkill python
sudo python $sim_path/feed1.py &
sudo python $sim_path/feed2.py &
sudo python $sim_path/purge.py &
sudo python $sim_path/product.py &
sudo python $sim_path/tank.py &
sudo python $sim_path/analyzer.py &
