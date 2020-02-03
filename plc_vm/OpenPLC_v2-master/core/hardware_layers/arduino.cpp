//-----------------------------------------------------------------------------
// Copyright 2015 Thiago Alves
//
// Based on the LDmicro software by Jonathan Westhues
// This file is part of the OpenPLC Software Stack.
//
// OpenPLC is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenPLC is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenPLC.  If not, see <http://www.gnu.org/licenses/>.
//------
//
// This file is the hardware layer for the OpenPLC. If you change the platform
// where it is running, you may only need to change this file. All the I/O
// related stuff is here. Basically it provides functions to read and write
// to the OpenPLC internal buffers in order to update I/O state.
// Thiago Alves, Dec 2015
//-----------------------------------------------------------------------------

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <string.h>
#include <pthread.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <stdlib.h>

#include "ladder.h"

#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#define bitWrite(value, bit, bitvalue) (bitvalue ? bitSet(value, bit) : bitClear(value, bit))

struct OPLC_input
{
	uint8_t digital[4];
	uint16_t analog[16];
};

struct OPLC_output
{
	uint8_t digital[2];
	uint16_t analog[12];
};

struct OPLC_input input_data;
struct OPLC_output output_data;

int serial_fd;
int isPortFound = 0;

pthread_mutex_t ioLock;

//-----------------------------------------------------------------------------
// Helper function - Makes the running thread sleep for the ammount of time
// in milliseconds
//-----------------------------------------------------------------------------
void sleep_ms(int milliseconds)
{
	struct timespec ts;
	ts.tv_sec = milliseconds / 1000;
	ts.tv_nsec = (milliseconds % 1000) * 1000000;
	nanosleep(&ts, NULL);
}

//-----------------------------------------------------------------------------
// Takes the string name of the serial port (e.g. "/dev/tty.usbserial","COM1")
// and a baud rate (bps) and connects to that port at that speed and 8N1.
// Opens the port in fully raw mode so you can send binary data. Returns valid
// fd, or -1 on error
//-----------------------------------------------------------------------------
int serialport_init(const char* serialport, int baud)
{
    struct termios toptions;
    int fd;

    fd = open(serialport, O_RDWR | O_NONBLOCK );

    if (fd == -1)
    {
        perror("serialport_init: Unable to open port ");
        return -1;
    }

    if (tcgetattr(fd, &toptions) < 0)
    {
        perror("serialport_init: Couldn't get term attributes");
        //return -1;
    }

    speed_t brate = baud; // let you override switch below if needed
    switch(baud) {
    case 4800:   brate=B4800;   break;
    case 9600:   brate=B9600;   break;
#ifdef B14400
    case 14400:  brate=B14400;  break;
#endif
    case 19200:  brate=B19200;  break;
#ifdef B28800
    case 28800:  brate=B28800;  break;
#endif
    case 38400:  brate=B38400;  break;
    case 57600:  brate=B57600;  break;
    case 115200: brate=B115200; break;
    }
    cfsetispeed(&toptions, brate);
    cfsetospeed(&toptions, brate);

    // 8N1
    toptions.c_cflag &= ~PARENB;
    toptions.c_cflag &= ~CSTOPB;
    toptions.c_cflag &= ~CSIZE;
    toptions.c_cflag |= CS8;
    // no flow control
    toptions.c_cflag &= ~CRTSCTS;

    //toptions.c_cflag &= ~HUPCL; // disable hang-up-on-close to avoid reset

    toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
    toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl

    toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
    toptions.c_oflag &= ~OPOST; // make raw

    // see: http://unixwiz.net/techtips/termios-vmin-vtime.html
    toptions.c_cc[VMIN]  = 0;
    toptions.c_cc[VTIME] = 0;
    //toptions.c_cc[VTIME] = 20;

    tcsetattr(fd, TCSANOW, &toptions);
    if( tcsetattr(fd, TCSAFLUSH, &toptions) < 0)
    {
        perror("init_serialport: Couldn't set term attributes");
        return -1;
    }

    return fd;
}

//-----------------------------------------------------------------------------
// Send a packet to the IO board
//-----------------------------------------------------------------------------
void sendPacket()
{
	uint8_t temp[100];
	uint8_t outgoingBuffer[100];
	struct OPLC_output *dataPointer;
	dataPointer = &output_data;

	pthread_mutex_lock(&ioLock);
	memcpy(temp, dataPointer, sizeof(struct OPLC_output));
	pthread_mutex_unlock(&ioLock);

	outgoingBuffer[0] = 'S';
	int j = 1;

	for (int i = 0; i < sizeof(struct OPLC_output); i++)
	{
		if (temp[i] != 'S' && temp[i] != 'E' && temp[i] != '\\')
		{
			outgoingBuffer[j] = temp[i];
			j++;
		}
		else
		{
			outgoingBuffer[j] = '\\';
			j++;
			outgoingBuffer[j] = temp[i];
			j++;
		}
	}
	outgoingBuffer[j] = 'E';
	j++;

	/*
	printf("Packet Sent: ");
	for (int i = 0; i < j; i++)
	{
		printf("0x%02x ", outgoingBuffer[i]);
	}
	printf("\n");
	*/

	write(serial_fd, outgoingBuffer, j);
}

//-----------------------------------------------------------------------------
// Verify the buffer received and remove the byte escapes. Returns TRUE if
// successfull or FALSE in case of error.
//-----------------------------------------------------------------------------
bool parseBuffer(uint8_t *buf, int bufSize)
{
	bool beginReceiving = false;
	bool escapeReceived = false;
	bool packetReceived = false;
	int bufferIndex = 0;

	for (int i = 0; i < bufSize; i++)
	{
		if (!beginReceiving && buf[i] == 'S')
		{
			beginReceiving = true;
		}

		else if (beginReceiving)
		{
			if (!escapeReceived)
			{
				if (buf[i] == '\\')
				{
					escapeReceived = true;
				}
				else if (buf[i] == 'E')
				{
					//End packet
					escapeReceived = false;
					beginReceiving = false;
					packetReceived = true;
					bufferIndex = 0;

				}
				else if (buf[i] == 'S')
				{
					//Missed end of last packet. Drop packet and start a new one
					escapeReceived = false;
					beginReceiving = true;
					packetReceived = false;
					bufferIndex = 0;
				}
				else
				{
					buf[bufferIndex] = buf[i];
					bufferIndex++;
				}
			}

			else if (escapeReceived)
			{
				if (buf[i] == '\\' || buf[i] == 'E' || buf[i] == 'S')
				{
					buf[bufferIndex] = buf[i];
					bufferIndex++;
					escapeReceived = false;
				}
				else
				{
					//Invalid sequence! Drop packet
					escapeReceived = false;
					beginReceiving = false;
					packetReceived = false;
					bufferIndex = 0;
				}
			}
		}
	}

	return packetReceived;
}

//-----------------------------------------------------------------------------
// Receive a packet from the IO board. Returns TRUE in case of success and
// FALSE in case of any error.
//-----------------------------------------------------------------------------
bool receivePacket()
{
	uint8_t receiveBuffer[100];
	int response = read(serial_fd, receiveBuffer, 100);
	if (response == -1 && isPortFound)
	{
		printf("Couldn't read from IO. Error: %s\n", strerror(errno));
		return 0;
	}
	else if (response == 0)
	{
		//avoid printing error messages just if the serial returned 0
		//printf("No response from IO. Error: %s\n", strerror(errno));
		return 0;
	}
	else
	{
		/*
		printf("Read %d bytes\n", response);
		for (int i = 0; i < response; i++)
		{
			printf("0x%02x ", receiveBuffer[i]);
			receiveBuffer[i] = 0;
		}
		printf("\n");
		*/

		if (parseBuffer(receiveBuffer, response))
		{
			struct OPLC_input *dataPointer;
			dataPointer = &input_data;

			pthread_mutex_lock(&ioLock);
			memcpy(dataPointer, receiveBuffer, sizeof(struct OPLC_input));
			pthread_mutex_unlock(&ioLock);

			return 1;
		}
	}

	return 0;
}

//-----------------------------------------------------------------------------
// Thread to send and receive data from the IO board
//-----------------------------------------------------------------------------
void *exchangeData(void *arg)
{
	while(1)
	{
		sendPacket();
		receivePacket();

		sleep_ms(30);
	}
}

//-----------------------------------------------------------------------------
// Verify if there are serial ports on the system
//-----------------------------------------------------------------------------
bool verifySerialPortsAvailable()
{
	DIR *dir = opendir("/dev/serial");
	if (dir)
	{
		return 1;
	}

	return 0;
}

//-----------------------------------------------------------------------------
// getSerialPorts() gives us symbolic links. We must find the absolute path
// for the serial ports.
//-----------------------------------------------------------------------------
void normalizePath(char *portName)
{
	char linkPath[1000];
	char finalPath[1000];
	strcpy(linkPath, "/dev/serial/by-path/");
	strcat(linkPath, portName);

	//Remove the last character from linkPath (it's a space char)
	int i;
	for (i = 0; linkPath[i] != '\0'; i++);
	linkPath[i-1] = '\0';

	ssize_t linkSize = readlink(linkPath, finalPath, 1000);
	if (linkSize < 0)
	{
		printf("Error obtaining path from the symbolic link\n");
		return;
	}
	finalPath[linkSize] = '\0';

	//Since readlink usually gives a relative path
	//we must rebuild the path manually
	int latestBarPosition = 0;
	for (i = 0; finalPath[i] != '\0'; i++)
	{
		if (finalPath[i] == '/')
			latestBarPosition = i;
	}
	latestBarPosition++; //start from the first character after the '/'

	strcpy(portName, "/dev/");
	int j = 5;
	for (i = latestBarPosition; finalPath[i] != '\0'; i++)
	{
		portName[j] = finalPath[i];
		j++;
		portName[j] = '\0';
	}
}

//-----------------------------------------------------------------------------
// getSerialPorts_w32() gives us a partial name. We must get the full path
//-----------------------------------------------------------------------------
void normalizePath_w32(char *portName)
{
	char linkPath[1000];
	char finalPath[1000];
	strcpy(linkPath, "/dev/");
	strcat(linkPath, portName);

	//Remove the last character from linkPath (it's a space char)
	int i;
	for (i = 0; linkPath[i] != '\0'; i++);
	linkPath[i-1] = '\0';
	
	strcpy(portName, linkPath);
}

//-----------------------------------------------------------------------------
// Get the name of each port found
//-----------------------------------------------------------------------------
void getSerialPorts(char **portsList)
{
	FILE *fp;
	char ports[1000];

	fp = popen("/bin/ls /dev/serial/by-path", "r");
	if (fp == NULL)
	{
		printf("Failed to find serial ports\n" );
	}

	int i = 0;
	while (fgets(ports, sizeof(ports)-1, fp) != NULL)
	{
		printf("Port found: %s", ports);
		normalizePath(ports);
		strncpy(portsList[i], ports, 1000);
		i++;
	}

	pclose(fp);
}

//-----------------------------------------------------------------------------
// Get the name of each port found - modified version for W32 with Cygwin
//-----------------------------------------------------------------------------
void getSerialPorts_w32(char **portsList)
{
	FILE *fp;
	char ports[1000];

	fp = popen("/bin/ls /dev", "r");
	if (fp == NULL)
	{
		printf("Failed to find serial ports\n" );
	}

	int i = 0;
	while (fgets(ports, sizeof(ports)-1, fp) != NULL)
	{
		if (!strncmp(ports, "ttyS", 4))
		{
			printf("Port found: %s", ports);
			normalizePath_w32(ports);
			strncpy(portsList[i], ports, 1000);
			i++;
		}
	}

	pclose(fp);
}

//-----------------------------------------------------------------------------
// Test if *portName is the correct serial port
//-----------------------------------------------------------------------------
bool testPort(char *portName)
{
	printf("Trying to open %s\n", portName);
	serial_fd = serialport_init(portName, 115200);
	sleep_ms(2500);
	if (serial_fd < 0) return 0;
	
	for (int i = 0; i < 5; i++) //try at least 5 times
	{
		sendPacket();
		sleep_ms(400);
		for (int j = 0; j < 10; j++)
		{
			if (receivePacket())
			{
				close(serial_fd);
				return 1;
			}
			sleep_ms(10);
		}
		sleep_ms(30);
	}
	
	printf("The port didn't respond properly\n");
	close(serial_fd);
	return 0;
}

//-----------------------------------------------------------------------------
// Call testPort() for each port in **portsList in order to find the correct
// serial port
//-----------------------------------------------------------------------------
int findCorrectPort(char **portsList)
{
    int portsIndex = 0;

    while (portsList[portsIndex][0] != '\0')
    {
    	if (testPort(portsList[portsIndex]))
    		return portsIndex;

		portsIndex++;
    }
	printf("Couldn't find any suitable port\n");
    return -1;
}

//-----------------------------------------------------------------------------
// This function is called by the main OpenPLC routine when it is initializing.
// Hardware initialization procedures should be here.
//-----------------------------------------------------------------------------
void initializeHardware()
{
	char **portsList;
	portsList = new char *[30];
	for(int i = 0; i < 30; i++)
	{
    	portsList[i] = new char[1000];
    	memset(portsList[i],0,sizeof(portsList[i]));
	}

#ifdef __linux__
	if (verifySerialPortsAvailable())
	{
		getSerialPorts(portsList);
		int portId = findCorrectPort(portsList);

		if (portId != -1)
		{
			isPortFound = 1;
			serial_fd = serialport_init(portsList[portId], 115200);
			sleep_ms(2500);
			pthread_t thread;
			pthread_create(&thread, NULL, exchangeData, NULL);
		}
	}
#else
	getSerialPorts_w32(portsList);
	int portId = findCorrectPort(portsList);
	
	if (portId != -1)
	{
		serial_fd = serialport_init(portsList[portId], 115200);
		sleep_ms(2500);
		pthread_t thread;
		pthread_create(&thread, NULL, exchangeData, NULL);
	}
#endif

}

//-----------------------------------------------------------------------------
// This function is called by the OpenPLC in a loop. Here the internal buffers
// must be updated to reflect the actual Input state. The mutex bufferLock
// must be used to protect access to the buffers on a threaded environment.
//-----------------------------------------------------------------------------
void updateBuffersIn()
{
	//Lock mutexes
	pthread_mutex_lock(&bufferLock);
	pthread_mutex_lock(&ioLock);

	//Digital Input
	for (int i = 0; i < (sizeof(input_data.digital)*8); i++)
	{
		if (bool_input[i/8][i%8] != NULL) *bool_input[i/8][i%8] = bitRead(input_data.digital[i/8], i%8);
	}

	//Analog Input
	for (int i = 0; i < (sizeof(input_data.analog)/2); i++)
	{
		if (int_input[i] != NULL) *int_input[i] = input_data.analog[i];
	}

	pthread_mutex_unlock(&ioLock);
	pthread_mutex_unlock(&bufferLock);
}

//-----------------------------------------------------------------------------
// This function is called by the OpenPLC in a loop. Here the internal buffers
// must be updated to reflect the actual Output state. The mutex bufferLock
// must be used to protect access to the buffers on a threaded environment.
//-----------------------------------------------------------------------------
void updateBuffersOut()
{
	//Lock mutexes
	pthread_mutex_lock(&bufferLock);
	pthread_mutex_lock(&ioLock);

	//Digital Output
	for (int i = 0; i < (sizeof(output_data.digital)*8); i++)
	{
		if (bool_output[i/8][i%8] != NULL) bitWrite(output_data.digital[i/8], i%8, *bool_output[i/8][i%8]);
	}

	//Analog Output
	for (int i = 0; i < (sizeof(output_data.analog)/2); i++)
	{
		if (int_output[i] != NULL) output_data.analog[i] = *int_output[i];
	}

	pthread_mutex_unlock(&ioLock);
	pthread_mutex_unlock(&bufferLock);
}