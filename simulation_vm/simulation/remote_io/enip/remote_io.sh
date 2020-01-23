#!/bin/bash

sudo pkill python
sudo python enip_analyzer.py out@0x93/1/10=UINT[3] -a 192.168.95.15 &
sudo python enip_product.py out@0x93/1/10=UINT[2] in@0x93/1/11=UDINT -a 192.168.95.13 &
sudo python enip_feed1.py out@0x93/1/10=UINT[2] in@0x93/1/11=UDINT -a 192.168.95.10 &
sudo python enip_feed2.py out@0x93/1/10=UINT[2] in@0x93/1/11=UDINT -a 192.168.95.11 &
sudo python enip_purge.py out@0x93/1/10=UINT[2] in@0x93/1/11=UDINT -a 192.168.95.12 &
sudo python enip_tank.py out@0x93/1/10=UINT[2] -a 192.168.95.14 &
