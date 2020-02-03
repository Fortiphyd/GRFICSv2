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
// Thiago Alves, Jul 2016
//-----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <string.h>
#include <pthread.h>

#include "ladder.h"

#define ESP_PORT	7567

#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#define bitWrite(value, bit, bitvalue) (bitvalue ? bitSet(value, bit) : bitClear(value, bit))

struct OPLC_input
{
	uint8_t device_id;
	uint8_t digital;
	uint16_t analog;
};

struct OPLC_output
{
	uint8_t device_id;
	uint8_t digital;
	uint16_t analog;
};

//-----------------------------------------------------------------------------
// Create the socket and bind it. Returns the file descriptor for the socket
// created.
//-----------------------------------------------------------------------------
int createSocket_esp(int port)
{
	int socket_fd;
	struct sockaddr_in server_addr;

	//Create TCP Socket
	socket_fd = socket(AF_INET,SOCK_STREAM,0);
	if (socket_fd<0)
	{
		perror("ESP8266: error creating stream socket");
		exit(1);
	}

	//Initialize Server Struct
	bzero((char *) &server_addr, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
	server_addr.sin_addr.s_addr = INADDR_ANY;
	server_addr.sin_port = htons(port);

	//Bind socket
	if (bind(socket_fd,(struct sockaddr *)&server_addr,sizeof(server_addr)) < 0)
	{
		perror("ESP8266: error binding socket");
		exit(1);
	}

	listen(socket_fd,5);
	printf("ESP8266: Listening on port %d\n", port);

	return socket_fd;
}

//-----------------------------------------------------------------------------
// Blocking call. Wait here for the client to connect. Returns the file
// descriptor to communicate with the client.
//-----------------------------------------------------------------------------
int waitForClient_esp(int socket_fd)
{
	int client_fd;
	struct sockaddr_in client_addr;
	socklen_t client_len;

	printf("ESP8266: waiting for new client...\n");

	client_len = sizeof(client_addr);
	client_fd = accept(socket_fd, (struct sockaddr *)&client_addr, &client_len); //blocking call

	return client_fd;
}

//-----------------------------------------------------------------------------
// Blocking call. Holds here until something is received from the client.
// Once the message is received, it is stored on the buffer and the function
// returns the number of bytes received.
//-----------------------------------------------------------------------------
int listenToClient_esp(int client_fd, unsigned char *buffer)
{
	bzero(buffer, 1024);
	int n = read(client_fd, buffer, 1024);
	return n;
}

//-----------------------------------------------------------------------------
// Process client's request
//-----------------------------------------------------------------------------
void processMessage_esp(unsigned char *buffer, int bufferSize, int client_fd)
{
	if (bufferSize >= sizeof(struct OPLC_input))
	{
		struct OPLC_input input_data;
		struct OPLC_output output_data;
		
		memcpy(&input_data, buffer, sizeof(struct OPLC_input));
		
		if (input_data.device_id < 100)
		{
			pthread_mutex_lock(&bufferLock); //lock mutex
			
			//Digital Inputs
			for (int i = 0; i < 8; i++)
			{
				if (bool_input[input_data.device_id][i] != NULL)
				{
					*bool_input[input_data.device_id][i] = bitRead(input_data.digital, i);
				}
			}
			
			//Analog Input
			if (int_input[input_data.device_id] != NULL)
			{
				*int_input[input_data.device_id] = input_data.analog;
			}
			
			//Digital Outputs
			for (int i = 0; i < 8; i++)
			{
				if (bool_output[input_data.device_id][i] != NULL)
				{
					bitWrite(output_data.digital, i, *bool_output[input_data.device_id][i]);
				}
			}
			
			//Analog Output
			if (int_output[input_data.device_id] != NULL)
			{
				output_data.analog = *int_output[input_data.device_id];
			}
			pthread_mutex_unlock(&bufferLock); //unlock mutex
			
			//Sending packet back to client
			output_data.device_id = input_data.device_id;
			memcpy(buffer, &output_data, sizeof(struct OPLC_output));
			write(client_fd, buffer, sizeof(struct OPLC_output));
		}
	}
}

//-----------------------------------------------------------------------------
// Thread to handle requests for each connected client
//-----------------------------------------------------------------------------
void *handleConnections_esp(void *arguments)
{
	int client_fd = *(int *)arguments;
	printf("ESP8266: Thread created for client ID: %d\n", client_fd);

	while(1)
	{
		unsigned char buffer[1024];
		int messageSize;

		messageSize = listenToClient_esp(client_fd, buffer);
		if (messageSize <= 0 || messageSize > 1024)
		{
			break;
		}

		processMessage_esp(buffer, messageSize, client_fd);
	}
}

//-----------------------------------------------------------------------------
// Function to start the server. It receives the port number as argument and
// creates an infinite loop to listen and parse the messages sent by the
// clients
//-----------------------------------------------------------------------------
void *startServer_esp(void *arg)
{
	int socket_fd, client_fd;

	socket_fd = createSocket_esp(ESP_PORT);

	while(1)
	{
		client_fd = waitForClient_esp(socket_fd); //block until a client connects
		if (client_fd < 0)
		{
			printf("ESP8266: Error accepting client!\n");
		}

		else
		{
			int arguments[1];
			pthread_t thread;

			printf("ESP8266: Client accepted! Creating thread for the new client ID: %d...\n", client_fd);
			arguments[0] = client_fd;
			pthread_create(&thread, NULL, handleConnections_esp, arguments);
		}
	}
}


//-----------------------------------------------------------------------------
// This function is called by the main OpenPLC routine when it is initializing.
// Hardware initialization procedures should be here.
//-----------------------------------------------------------------------------
void initializeHardware()
{
	pthread_t thread;
	pthread_create(&thread, NULL, startServer_esp, NULL);
}

//-----------------------------------------------------------------------------
// This function is called by the OpenPLC in a loop. Here the internal buffers
// must be updated to reflect the actual Input state. The mutex bufferLock
// must be used to protect access to the buffers on a threaded environment.
//-----------------------------------------------------------------------------
void updateBuffersIn()
{
	//The thread created in initializeHardware is already updating
	//OpenPLC's buffers. So this function should do nothing.
}

//-----------------------------------------------------------------------------
// This function is called by the OpenPLC in a loop. Here the internal buffers
// must be updated to reflect the actual Output state. The mutex bufferLock
// must be used to protect access to the buffers on a threaded environment.
//-----------------------------------------------------------------------------
void updateBuffersOut()
{
	//The thread created in initializeHardware is already updating
	//OpenPLC's buffers. So this function should do nothing.
}