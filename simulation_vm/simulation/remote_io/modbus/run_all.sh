#!/bin/bash

sudo pkill python
sudo python feed1.py &
sudo python feed2.py &
sudo python purge.py &
sudo python product.py &
sudo python tank.py &
sudo python analyzer.py &