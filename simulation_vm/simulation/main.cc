#include <string>
#include <string.h>
#include <iostream>
#include <sstream>
#include <stdlib.h>
#include <sys/types.h> 
#include <arpa/inet.h>    //close 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <netinet/in.h> 
#include <sys/time.h> //FD_SET, FD_ISSET, FD_ZERO macros 
#include <errno.h> 
#include <pthread.h>
#include <jsoncpp/json/json.h>
#include "TE_process.h"
#define PORT 55555
#define TRUE 1


// compile with g++ example.cc TE_process.cc -ljsoncpp -llapacke -lpthread -o simulation
TE *my_te;
Json::Value inputs;
Json::Value outputs;
pthread_mutex_t simulation_lock;           // single lock used for any access to TE process, inputs, or outputs to ensure atomic operation
unsigned int process_rate = 100000;      // max of 1000000

void* simulation(void *ptr) {
    while (1) {
       
        /************** UPDATE PROCESS SIMULATION ***************/
        pthread_mutex_lock(&simulation_lock);
        my_te->update(inputs);
        outputs = my_te->get_state_json();
        my_te->print_outputs();
        pthread_mutex_unlock(&simulation_lock);       
        
        usleep(process_rate);
        
    }


}

int main(void) {
    Json::Reader reader;
    Json::FastWriter writer;
    Json::Value command;
    pthread_t process_thread;
    

    int opt = TRUE;  
    int master_socket , addrlen , new_socket , client_socket[30] , 
          max_clients = 30 , activity, i , valread , sd;  
    int max_sd;  
    struct sockaddr_in address;  
        
    char buffer[1025];  //data buffer of 1K 
        
    //set of socket descriptors 
    fd_set readfds;  
        

    
    //initialize TE process
    my_te = new TE();
    my_te->update(inputs);

    //initialise all client_socket[] to 0 so not checked 
    for (i = 0; i < max_clients; i++)  
    {  
        client_socket[i] = 0;  
    }  
        
    //create a master socket 
    if( (master_socket = socket(AF_INET , SOCK_STREAM , 0)) == 0)  
    {  
        perror("socket failed");  
        exit(EXIT_FAILURE);  
    }  
    
    //set master socket to allow multiple connections , 
    //this is just a good habit, it will work without this 
    if( setsockopt(master_socket, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, 
          sizeof(opt)) < 0 )  
    {  
        perror("setsockopt");  
        exit(EXIT_FAILURE);  
    }  
    
    //type of socket created 
    address.sin_family = AF_INET;  
    address.sin_addr.s_addr = INADDR_ANY;  
    address.sin_port = htons( PORT );  
        
    //bind the socket to localhost port 8888 
    if (bind(master_socket, (struct sockaddr *)&address, sizeof(address))<0)  
    {  
        perror("bind failed");  
        exit(EXIT_FAILURE);  
    }  
    printf("Listener on port %d \n", PORT);  
        
    //try to specify maximum of 3 pending connections for the master socket 
    if (listen(master_socket, 3) < 0)  
    {  
        perror("listen");  
        exit(EXIT_FAILURE);  
    }  
        
    //accept the incoming connection 
    addrlen = sizeof(address);  
    puts("Waiting for connections ...");  
        
    while(TRUE)  
    {  
        my_te->update(inputs);
        //clear the socket set 
        FD_ZERO(&readfds);  
    
        //add master socket to set 
        FD_SET(master_socket, &readfds);  
        max_sd = master_socket;  
            
        //add child sockets to set 
        for ( i = 0 ; i < max_clients ; i++)  
        {  
            //socket descriptor 
            sd = client_socket[i];  
                
            //if valid socket descriptor then add to read list 
            if(sd > 0)  
                FD_SET( sd , &readfds);  
                
            //highest file descriptor number, need it for the select function 
            if(sd > max_sd)  
                max_sd = sd;  
        }  
    
        //wait for an activity on one of the sockets , timeout is NULL , 
        //so wait indefinitely 
        activity = select( max_sd + 1 , &readfds , NULL , NULL , NULL);  
      
        if ((activity < 0) && (errno!=EINTR))  
        {  
            printf("select error");  
        }  
            
        //If something happened on the master socket , 
        //then its an incoming connection 
        if (FD_ISSET(master_socket, &readfds))  
        {  
            if ((new_socket = accept(master_socket, 
                    (struct sockaddr *)&address, (socklen_t*)&addrlen))<0)  
            {  
                perror("accept");  
                exit(EXIT_FAILURE);  
            }  
            
            //inform user of socket number - used in send and receive commands 
            printf("New connection , socket fd is %d , ip is : %s , port : %d \n" , new_socket , inet_ntoa(address.sin_addr) , ntohs
                  (address.sin_port));  
          
                
            //add new socket to array of sockets 
            for (i = 0; i < max_clients; i++)  
            {  
                //if position is empty 
                if( client_socket[i] == 0 )  
                {  
                    client_socket[i] = new_socket;  
                    printf("Adding to list of sockets as %d\n" , i);  
                        
                    break;  
                }  
            }  
        }  
            
        //else its some IO operation on some other socket
        for (i = 0; i < max_clients; i++)  
        {  
            sd = client_socket[i];  
                
            if (FD_ISSET( sd , &readfds))  
            {  
                //Check if it was for closing , and also read the 
                //incoming message 
                if ((valread = read( sd , buffer, 1024)) == 0)  
                {  
                    //Somebody disconnected , get his details and print 
                    getpeername(sd , (struct sockaddr*)&address , \
                        (socklen_t*)&addrlen);  
                    printf("Host disconnected , ip %s , port %d \n" , inet_ntoa(address.sin_addr) , ntohs(address.sin_port));  
                        
                    //Close the socket and mark as 0 in list for reuse 
                    close( sd );  
                    client_socket[i] = 0;  
                }   
                    
                    // PROCESS INPUTS OR OUTPUTS
                else
                {  
                    bool reader_stat = reader.parse(buffer,command);
                    if (reader_stat) {
                        if (command.isMember("request")) {
                            if (command["request"] == "read") {
                                outputs = my_te->get_state_json();
                                std::string response = writer.write(outputs);
                                send(sd,response.c_str(),response.length(),0);
                            } else if (command["request"] == "write") {
                                if (command.isMember("data")) {
                                    inputs = command["data"];
                                    my_te->update(inputs);
                                    outputs = my_te->get_state_json();
                                    std::string response = writer.write(outputs);
                                    send(sd, response.c_str(), response.length(),0);
                                }
                            } else {
                                //invalid json message
                               
                            }
                        }
                    } else {
                        //invalid json format
                    }
                }  
            }  
        }  
    }

    return 0;
}
