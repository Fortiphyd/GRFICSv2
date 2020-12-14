# GRFICSv2
Version 2 of the Graphical Realism Framework for Industrial Control Simulation (GRFICS)

### Overview

This version of GRFICS is organized as 4 VirtualBox VMs (a 3D simulation, a soft PLC, a HMI, and a pfsense firewall) communicating with each other on a host-only virtual networks. For a more detailed explanation of the entire framework and some background information on ICS networks, please refer to the workshop paper located at https://www.usenix.org/conference/ase18/presentation/formby

A video series walking through VM setup and example attacks is available on the Fortiphyd YouTube channel at 
https://www.youtube.com/playlist?list=PL2RSrzaDx0R670yPlYPqM51guk3bQjFG5

A commercial version of GRFICS with more scenarios, advanced features, and streamlined usability is being offered by Fortiphyd Logic. Find out more at https://www.fortiphyd.com/training

### Simulation

The simulation VM runs a realistic simulation of a chemical process reaction that is controlled and monitored by simulated remote IO devices through a simple JSON API. These remote IO devices are then monitored and controlled by the PLC VM using the Modbus protocol. This VM is located in the ICS network subnet (192.168.95.0/24) with the IP addresses 192.168.95.10-192.168.95.15
![simulation](figures/simulation.png)

### Programmable Logic Controller

The PLC VM is a modified version of OpenPLC (https://github.com/thiagoralves/OpenPLC_v2) that uses an older version of the libmodbus library with known buffer overflow vulnerabilities. This VM is located in the ICS network subnet (192.168.95.0/24) at 192.168.95.2

### Human Machine Interface

The HMI VM primarily contains an operator HMI created using the free ScadaBR software. This HMI is used to monitor the process measurements being collected by the PLC and send commands to the PLC. This VM is located in the DMZ network subnet (192.168.90.0/24) at 192.168.90.5
![hmi](figures/hmi.png)


### PfSense Firewall/Router

The firewall VM provides routing and firewall features between the DMZ and ICS network. The WAN interface is on the DMZ subnet (192.168.90.0/24) at 192.168.90.100 and the LAN interface is on the ICS subnet (192.168.95.0/24) at 192.168.95.1

### Engineering Workstation

The workstation VM is an Ubuntu 16.04 machine with software used for programming the OpenPLC. The workstation is located in the ICS network (192.168.95.0/24) at 192.168.95.5.

#### Installing from scratch

1. Download and install the latest version of [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

2. [Create a host-only interface](https://www.virtualbox.org/manual/ch06.html#network_hostonly) in VirtualBox.

3. Download an image for both the desktop and server versions of 64-bit [Ubuntu 16.04](http://releases.ubuntu.com/16.04/).

4. See instructions for each VM in corresponding directories.

#### Pre-built VMs

1. Download VMs:

   - [Simulation VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/dformby_fortiphyd_com/EaBeAxbF6xtEumdsJ7npVz0BeECJnseAMsfAbaLwV3sKOg?e=JRvkcS) - MD5=02af6c2502ecaab6c6d138deb560b27d
   - [HMI VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/dformby_fortiphyd_com/Eacy2_AyKsNHsebSady0fGMB95li29AVnQxjHiu89XXpEQ?e=WZxsx0) - MD5=20ef1ff9e36f80ea3e257806bec09274
   - [pfsense VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/dformby_fortiphyd_com/ETe9GfHNkOZKh2YuL7oMd1UBs8zhnqmGnqoODuTy2q8alg?e=GqTHB6) - MD5=521745220cd2f6e268eb188934d6b0ad
   - [PLC VM](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/dformby_fortiphyd_com/ER0pG_X5IRNCg477jf2ppo8BdN0t13t9vrNBH92_oOWOHA?e=hNeJ88) - MD5=0fbb1254fb166466496f2a48780ae774
   - [Workstation](https://netorgft4230013-my.sharepoint.com/:u:/g/personal/dformby_fortiphyd_com/EcZuc0Xu7WRBjhIhwWH2MjkBeZ4W1S-k6m4m7Nuk_RHpdQ?e=kHhX7y) - MD5=68c21a9057d68c637c358b05f1f816e8

2. [Add 2 host-only adapters](https://www.virtualbox.org/manual/ch06.html#network_hostonly) in VirtualBox:
    - VirtualBox Host-Only Ethernet Adapter #2: 192.168.95.111 and 255.255.255.0 netmask
    - VirtualBox Host-Only Ethernet Adapter #3: 192.168.90.111 and 255.255.255.0 netmask

  Your VirtualBox settings should look something like the below screenshot.

  ![netset3](figures/vb_networking.png)


3. Import each VM into VirtualBox using File->Import Appliance

4. VM credentials
    - Simulation (Chemical Plant): simulation | Fortiphyd
    - HMI (ScadaBR): scadabr | scadabr    web console: admin | admin
    - Pfsense: admin | pfsense
    - PLC: user | password

5. If you downloaded a VM, the simulation scripts should start on boot. If not, log into the simulation VM and open 2 terminals. In one, cd into the "simulation" directory and run `./simulation`. In the second terminal, cd into the "simulation/remote_io/modbus" directory and run `sudo bash run_all.sh`.

6. If you downloaded a VM, the PLC should start on boot. If not, log into plc VM, cd into the OpenPLC_v2 directory, and run "sudo nodejs server.js"

7. Point your internet browser to the ip address of the simulation VM (default 192.168.95.10) to view the visualization.
