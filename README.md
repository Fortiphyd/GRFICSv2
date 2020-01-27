# GRFICSv2
Version 2 of the Graphical Realism Framework for Industrial Control Simulation (GRFICS)

#### Installing from scratch

1. Download and install the latest version of [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

2. [Create a host-only interface](https://www.virtualbox.org/manual/ch06.html#network_hostonly) in VirtualBox.

3. Download an image for both the desktop and server versions of 64-bit [Ubuntu 16.04](http://releases.ubuntu.com/16.04/).

4. See instructions for each VM in corresponding directories.

#### Pre-built VMs

1. Download VMs:

   - [Simulation VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/sbryce_fortiphyd_com/EckacBkem-pDqmM8g0vJGUUBTBKX6JKvJPMzw4HWjbT0mw?e=FmLbky)
   - [HMI VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/sbryce_fortiphyd_com/EQXZ8QtAXNdGjJggF45J6GYBpu_xhd20WUITNSRIow-3UQ?e=dJ2TGo)

2. [Add a host-only adapter](https://www.virtualbox.org/manual/ch06.html#network_hostonly) in VirtualBox with IP address 192.168.95.1 and 255.255.255.0 netmask.
  Your VirtualBox settings should look something like the below screenshots.

  ![netset3](figures/network_settings3.PNG)

  ![netset1](figures/network_settings1.PNG)

  ![netset2](figures/network_settings2.PNG)

3. Import each VM into VirtualBox using File->Import Appliance

4. Every VM can be logged into with username "user" and password "password"

5. Log into the simulation VM and open 2 terminals. In one, cd into the "simulation" directory and run `./simulation`. In the second terminal, cd into the "simulation/remote_io/modbus" directory and run `sudo bash run_all.sh`.

6. On the host machine, point your internet browser to the ip address of the simulation VM (default 192.168.95.10) to view the visualization.
