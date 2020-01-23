#!/usr/bin/env python
"""
MODIFIED Pymodbus Asynchronous Server Example
--------------------------------------------------------------------------

The asynchronous server is a high performance implementation using the
twisted library as its backend.  This allows it to scale to many thousands
of nodes which can be helpful for testing monitoring software.
"""



# --------------------------------------------------------------------------- # 
# import the various server implementations
# --------------------------------------------------------------------------- # 
from pymodbus.server.async import StartTcpServer
from pymodbus.server.async import StartUdpServer
from pymodbus.server.async import StartSerialServer

from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.transaction import ModbusRtuFramer, ModbusAsciiFramer

# --------------------------------------------------------------------------- # 
# configure the service logging
# --------------------------------------------------------------------------- # 
import logging
logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.DEBUG)


def run_async_server():
    store_feed1 = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [17]*100),
        co=ModbusSequentialDataBlock(0, [17]*100),
        hr=ModbusSequentialDataBlock(0, [17]*100),
        ir=ModbusSequentialDataBlock(0, [17]*100))
    context_feed1 = ModbusServerContext(slaves=store_feed1, single=True)
    
    # ----------------------------------------------------------------------- # 
    # initialize the server information
    # ----------------------------------------------------------------------- # 
    # If you don't set this or any fields, they are defaulted to empty strings.
    # ----------------------------------------------------------------------- # 
    identity_feed1 = ModbusDeviceIdentification()
    identity_feed1.VendorName = 'Pymodbus'
    identity_feed1.ProductCode = 'PM'
    identity_feed1.VendorUrl = 'http://github.com/bashwork/pymodbus/'
    identity_feed1.ProductName = 'Pymodbus Server'
    identity_feed1.ModelName = 'Pymodbus Server'
    identity_feed1.MajorMinorRevision = '1.0'
    
     
      
    # ----------------------------------------------------------------------- # 
    # run the server you want
    # ----------------------------------------------------------------------- # 
    
    StartTcpServer(context_feed1, identity=identity_feed1, address=("192.168.95.10", 502))


if __name__ == "__main__":
    run_async_server()