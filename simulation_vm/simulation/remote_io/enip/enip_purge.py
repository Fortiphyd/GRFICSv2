#USAGE: sudo python enip_purge.py out@0x93/1/10=DINT[2] in@0x93/1/11=DINT -a 192.168.95.12
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

class Attribute_valve( device.Attribute ):
    def __init__(self, name, type, default = 0, error = 0x00, mask = 0):
        super(Attribute_valve, self).__init__(name, type, default, error, mask)
        # connect to simulation
        HOST = '127.0.0.1'
        PORT = 55555
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((HOST, PORT))

    def __getitem__( self, key ):
        self.sock.send('{"request":"read"}\n')
        data = json.loads(self.sock.recv(1500))
        valve_pos = int(data["state"]["purge_valve_pos"]/100.0*65535)
        flow = int(data["outputs"]["purge_flow"]/500.0*65535)
        return [valve_pos, flow]

    def __setitem__( self, key, value ):
        self.sock.send('{"request":"write","data":{"inputs":{"purge_valve_sp":'+repr(value[0] / 65535.0 * 100.0)+'}}}\n')

sys.exit( main( attribute_class=Attribute_valve ))
