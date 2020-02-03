//-----------------------------------------------------------------------------
// Copyright 2015 Thiago Alves
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
// This is the file for the network routines of the OpenPLC. It has procedures
// to create a socket, bind it and start network communication.
// Thiago Alves, Dec 2015
//-----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <string.h>
#include <pthread.h>

#include "ladder.h"

#define MAX_INPUT 16
#define MAX_OUTPUT 16
#define MAX_MODBUS 100

//-----------------------------------------------------------------------------
// Create the socket and bind it. Returns the file descriptor for the socket
// created.
//-----------------------------------------------------------------------------
int createSocket(int port)
{
	int socket_fd;
	struct sockaddr_in server_addr;

	//Create TCP Socket
	socket_fd = socket(AF_INET,SOCK_STREAM,0);
	if (socket_fd<0)
	{
		perror("Server: error creating stream socket");
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
		perror("Server: error binding socket");
		exit(1);
	}
        // we accept max 5 pending connections
	listen(socket_fd,5);
	printf("Server: Listening on port %d\n", port);

	return socket_fd;
}

//-----------------------------------------------------------------------------
// Blocking call. Wait here for the client to connect. Returns the file
// descriptor to communicate with the client.
//-----------------------------------------------------------------------------
int waitForClient(int socket_fd)
{
	int client_fd;
	struct sockaddr_in client_addr;
	socklen_t client_len;

	printf("Server: waiting for new client...\n");

	client_len = sizeof(client_addr);
	client_fd = accept(socket_fd, (struct sockaddr *)&client_addr, &client_len); //blocking call

	return client_fd;
}

//-----------------------------------------------------------------------------
// Blocking call. Holds here until something is received from the client.
// Once the message is received, it is stored on the buffer and the function
// returns the number of bytes received.
//-----------------------------------------------------------------------------
int listenToClient(int client_fd, unsigned char *buffer)
{
	// MODIFIED changed 1024 buffer size to 260
	bzero(buffer, 260);
	int n = read(client_fd, buffer, 260);
	return n;
}

//-----------------------------------------------------------------------------
// Process client's request
//-----------------------------------------------------------------------------
void processMessage(unsigned char *buffer, int bufferSize, int client_fd)
{
	int messageSize = processModbusMessage(buffer, bufferSize);
	write(client_fd, buffer, messageSize);
}

//-----------------------------------------------------------------------------
// Thread to handle requests for each connected client
//-----------------------------------------------------------------------------
void *handleConnections(void *arguments)
{
	int client_fd = *(int *)arguments;
	//unsigned char buffer[1024]; MODIFIED changed to smaller buffer to make overflow easier
	unsigned char buffer[260];
	int messageSize;

	printf("Server: Thread created for client ID: %d\n", client_fd);

	while(1)
	{
		//unsigned char buffer[1024];
		//int messageSize;

		messageSize = listenToClient(client_fd, buffer);
		if (messageSize <= 0 || messageSize > 260)
		{
			// something has  gone wrong or the client has closed connection
			if (messageSize == 0)
			{
				printf("Server: client ID: %d has closed the connection\n", client_fd);
			}
			else
			{
				printf("Server: Something is wrong with the  client ID: %d message Size : %i\n", client_fd, messageSize);
			}
			break;
		}

		processMessage(buffer, messageSize, client_fd);
	}
	//printf("Debug: Closing client socket and calling pthread_exit in server.cpp\n");
	close(client_fd);
	pthread_exit(NULL);
}

//-----------------------------------------------------------------------------
// Function to start the server. It receives the port number as argument and
// creates an infinite loop to listen and parse the messages sent by the
// clients
//-----------------------------------------------------------------------------
void startServer(int port)
{
	int socket_fd, client_fd;

	socket_fd = createSocket(port);
	mapUnusedIO();

	while(1)
	{
		client_fd = waitForClient(socket_fd); //block until a client connects
		if (client_fd < 0)
		{
			printf("Server: Error accepting client!\n");
		}

		else
		{
			int arguments[1];
			pthread_t thread;
                        int ret = -1;

			printf("Server: Client accepted! Creating thread for the new client ID: %d...\n", client_fd);
			arguments[0] = client_fd;
			ret = pthread_create(&thread, NULL, handleConnections, arguments);
			if (ret==0) 
			{
				pthread_detach(thread);
			}
		}
	}
}
