#USAGE: sudo python enip_tank.py out@0x93/1/10=DINT[2] -a 192.168.95.14
# 
# Cpppo -- Communication Protocol Python Parser and Originator
# 
# Copyright (c) 2013, Hard Consulting Corporation.
# 
# Cpppo is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.  See the LICENSE file at the top of the source tree.
# 
# Cpppo is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
# 
 
from __future__ import absolute_import
from __future__ import print_function
from __future__ import division

import sys, logging, json, socket

from cpppo.server.enip import device, REAL
from cpppo.server.enip.main import main

class Attribute_tank( device.Attribute ):
    def __init__(self, name, type, default = 0, error = 0x00, mask = 0):
        super(Attribute_tank, self).__init__(name, type, default, error, mask)
        # connect to simulation
        HOST = '127.0.0.1'
        PORT = 55555
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((HOST, PORT))

    def __getitem__( self, key ):
        self.sock.send('{"request":"read"}\n')
        data = json.loads(self.sock.recv(1500))
        pressure = int(data["outputs"]["pressure"]/3200.0*65535)
        if pressure >= 65535:
            pressure = 65535
        level = int(data["outputs"]["liquid_level"]/100.0*65535)
        return [pressure, level]

sys.exit( main( attribute_class=Attribute_tank ))
