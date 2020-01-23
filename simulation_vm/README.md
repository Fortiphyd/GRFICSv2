### Installation

#### Simulation
1. Install jsoncpp: `sudo apt-get install libjsoncpp-dev`
2. Go to the simulation folder: `cd ~/GRFICSv2/simulation_vm/simulation`
3. Compile: `sudo make`

#### Web Visualization
1. Install php and apache2: `sudo apt install apache2 php libapache2-mod-php`
2. Create a symlink to the apache folder `sudo ln -s ~/GRFICSv2/simulation_vm/web_visualization/* /var/www/html`
