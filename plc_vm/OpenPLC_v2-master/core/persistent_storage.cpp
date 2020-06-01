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
// This file is responsible for the persistent storage on the OpenPLC
// Thiago Alves, Mar 2016
//-----------------------------------------------------------------------------

#include <stdio.h>
#include <time.h>
#include <pthread.h>

#include "ladder.h"

//-----------------------------------------------------------------------------
// Main function for the thread. Should create a buffer for the persistent
// data, compare it with the actual data and write back to the persistent
// file if the data has changed
//-----------------------------------------------------------------------------
void *persistentStorage(void *args)
{
	IEC_INT persistentBuffer[BUFFER_SIZE];

	pthread_mutex_lock(&bufferLock); //lock mutex
	for (int i = 0; i < BUFFER_SIZE; i++)
	{
		if (int_output[i] != NULL) persistentBuffer[i] = *int_output[i];
	}
	pthread_mutex_unlock(&bufferLock); //unlock mutex

	while (1)
	{
		//printf("checking data...\n");
		bool bufferOutdated = false;

		pthread_mutex_lock(&bufferLock); //lock mutex
		for (int i = 0; i < BUFFER_SIZE; i++)
		{
			if (int_output[i] != NULL)
			{
				if (persistentBuffer[i] != *int_output[i])
				{
					persistentBuffer[i] = *int_output[i];
					bufferOutdated = true;
				}
			}
		}
		pthread_mutex_unlock(&bufferLock); //unlock mutex

		if (bufferOutdated)
		{
			//printf("writing data to disk...\n");
			FILE *fd = fopen("persistent.file", "w"); //if file already exists, it will be overwritten
			if (fd == NULL)
			{
				printf("Error creating persistent memory file!\n");
				return 0;
			}

			if (fwrite(persistentBuffer, sizeof(IEC_INT), BUFFER_SIZE, fd) < BUFFER_SIZE)
			{
				printf("Error writing to persistent memory file!\n");
				return 0;
			}
			fclose(fd);
		}

		sleep_thread(1000);
	}
}

int readPersistentStorage()
{
	FILE *fd = fopen("persistent.file", "r");
	if (fd == NULL)
	{
		printf("Error openning persistent memory file, or file doesn't exists!\n");
		return 0;
	}

	IEC_INT persistentBuffer[BUFFER_SIZE];

	if (fread(persistentBuffer, sizeof(IEC_INT), BUFFER_SIZE, fd) < BUFFER_SIZE)
	{
		printf("Error while trying to read the persistent memory file!\n");
		return 0;
	}
	fclose(fd);

	pthread_mutex_lock(&bufferLock); //lock mutex
	for (int i = 0; i < BUFFER_SIZE; i++)
	{
		if (int_output[i] != NULL) *int_output[i] = persistentBuffer[i];
	}
	pthread_mutex_unlock(&bufferLock); //unlock mutex
}
