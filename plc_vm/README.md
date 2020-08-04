# Programmable Logic Controller (PLC)

The PLC VM is an Ubuntu 16.04 server running a modified OpenPLC soft PLC.

### Instructions

Follow the build instructions at https://github.com/thiagoralves/OpenPLC_v2 with the PLC on a NAT adapter.

Choose to build a Linux Soft PLC with Modbus IO layer.

Change the network adapter to the host-only network 192.168.95.0/24. Set the static IP address to 192.168.95.2 by using `sudo nano /etc/network/interfaces` and making the file look like
```
auto lo
iface lo inet loopback

allow-hotplug enp0s3
iface enp0s3 inet static
address 192.168.95.2
netmask 255.255.255.0
```

Upload the included mbconfig.cfg file through the OpenPLC web interface
