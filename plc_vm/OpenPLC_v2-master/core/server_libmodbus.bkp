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
#include <modbus.h>

#include "ladder.h"

#define MAX_DISCRETE_INPUT 		100
#define MAX_COILS 				100
#define MAX_HOLD_REGS 			1000
#define MAX_INP_REGS			1000

pthread_mutex_t modbusLock; //mutex for the internal buffers

modbus_mapping_t *mb_mapping;
modbus_mapping_t *mb_old_mapping;

//-----------------------------------------------------------------------------
// Must be called periodically. It updates the modbus buffers according to
// the OpenPLC internal buffers
//-----------------------------------------------------------------------------
void updateModbusBuffers()
{
	if (mb_mapping != NULL)
	{
		pthread_mutex_lock(&modbusLock); //lock mutex
		pthread_mutex_lock(&bufferLock);

		for(int i = 0; i < MAX_DISCRETE_INPUT; i++)
		{
			if (bool_input[i/8][i%8] != NULL) mb_mapping->tab_input_bits[i] = *bool_input[i/8][i%8];
		}

		for(int i = 0; i < MAX_COILS; i++)
		{
			if (bool_output[i/8][i%8] != NULL) mb_mapping->tab_bits[i] = *bool_output[i/8][i%8];
		}

		for (int i = 0; i < MAX_INP_REGS; i++)
		{
			if (int_input[0][i] != NULL) mb_mapping->tab_input_registers[i] = *int_input[0][i];
		}

		for (int i = 0; i < MAX_HOLD_REGS; i++)
		{
			if (int_output[0][i] != NULL) mb_mapping->tab_registers[i] = *int_output[0][i];
		}

		pthread_mutex_unlock(&bufferLock);
		pthread_mutex_unlock(&modbusLock); //unlock mutex
	}
}

//-----------------------------------------------------------------------------
// This function sets the internal NULL OpenPLC buffers to point to valid
// positions on the Modbus buffer
//-----------------------------------------------------------------------------
void mapUnusedIO()
{
	if (mb_mapping != NULL)
	{
		pthread_mutex_lock(&modbusLock); //lock mutex
		pthread_mutex_lock(&bufferLock);

		for(int i = 0; i < MAX_DISCRETE_INPUT; i++)
		{
			if (bool_input[i/8][i%8] == NULL) bool_input[i/8][i%8] = &mb_mapping->tab_input_bits[i];
		}

		for(int i = 0; i < MAX_COILS; i++)
		{
			if (bool_output[i/8][i%8] == NULL) bool_output[i/8][i%8] = &mb_mapping->tab_bits[i];
		}

		for (int i = 0; i < MAX_INP_REGS; i++)
		{
			if (int_input[0][i] == NULL) int_input[0][i] = (int16_t *)&mb_mapping->tab_input_registers[i];
		}

		for (int i = 0; i < MAX_HOLD_REGS; i++)
		{
			if (int_output[0][i] == NULL) int_output[0][i] = (int16_t *)&mb_mapping->tab_registers[i];
		}

		pthread_mutex_unlock(&bufferLock);
		pthread_mutex_unlock(&modbusLock); //unlock mutex
	}
}

//-----------------------------------------------------------------------------
// Function to start the server. It receives the port number as argument and
// creates an infinite loop to listen respond to Modbus/TCP requests
//-----------------------------------------------------------------------------
void startServer(int port)
{
	int socket_fd;
	modbus_t *ctx;
    int rc;

    mb_mapping = modbus_mapping_new(MAX_COILS, MAX_INPUT, MAX_HOLD_REGS, MAX_INP_REGS); //arguments: coils, discrete inputs, holding registers, input registers
    if (mb_mapping == NULL)
    {
        printf("Failed to allocate the mapping: %s\n", modbus_strerror(errno));
    }
    mb_old_mapping = modbus_mapping_new(MAX_COILS, 0, MAX_HOLD_REGS, 0); //arguments: coils, discrete inputs, holding registers, input registers
    if (mb_mapping == NULL)
    {
        printf("Failed to allocate the mapping: %s\n", modbus_strerror(errno));
    }

    printf("Waiting for Modbus/TCP connection on Port %i \n", port);
	ctx = modbus_new_tcp(NULL, port);
	socket_fd = modbus_tcp_listen(ctx, 1);
	if (socket_fd == -1)
	{
		printf("Failed to create Modbus server: %s\n", modbus_strerror(errno));
	}
	if (modbus_tcp_accept(ctx, &socket_fd) == -1)
	{
		printf("Failed to create Modbus server: %s\n", modbus_strerror(errno));
	}

	//Map unused variables to the modbus buffer
	mapUnusedIO();

	while(1)
	{
		uint8_t query[MODBUS_TCP_MAX_ADU_LENGTH];

		rc = modbus_receive(ctx, query);

        if (rc > 0)
        {
        	pthread_mutex_lock(&modbusLock); //lock mutex

        	for (int i = 0; i < MAX_COILS; i++)
        	{
        		mb_old_mapping->tab_bits[i] = mb_mapping->tab_bits[i];
        	}
        	for (int i = 0; i < MAX_HOLD_REGS; i++)
        	{
        		mb_old_mapping->tab_registers[i] = mb_mapping->tab_registers[i];
        	}

        	modbus_reply(ctx, query, rc, mb_mapping);

			pthread_mutex_lock(&bufferLock);
        	for (int i = 0; i < MAX_COILS; i++)
        	{
        		if (mb_old_mapping->tab_bits[i] != mb_mapping->tab_bits[i])
        		{
        			if (bool_output[i/8][i%8] != NULL) *bool_output[i/8][i%8] = mb_mapping->tab_bits[i];
        		}
        	}
        	for (int i = 0; i < MAX_HOLD_REGS; i++)
        	{
        		if (mb_old_mapping->tab_registers[i] != mb_mapping->tab_registers[i])
        		{
        			if (int_output[0][i] != NULL) *int_output[0][i] = mb_mapping->tab_registers[i];
        		}
        	}
			pthread_mutex_unlock(&bufferLock);
        	pthread_mutex_unlock(&modbusLock); //unlock mutex
        }

        else if (rc == -1)
        {
            /* Connection closed by the client or server */
            printf("Modbus/TCP connection closed.\n");
	    	modbus_close(ctx);
            if (modbus_tcp_accept(ctx, &socket_fd) == -1)
			{
				printf("Failed to create Modbus server: %s\n", modbus_strerror(errno));
			}
        }
	}
}
