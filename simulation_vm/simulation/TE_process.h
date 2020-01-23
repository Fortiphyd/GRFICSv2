#ifndef TE_PROCESS_H
#define TE_PROCESS_H


#include <math.h>
#include <lapacke.h>
#include <time.h>
#include <sys/time.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <jsoncpp/json/json.h>



//TODO add sensor noise?

class TE {
        struct timeval last_update, current; 
        double time_scale;
        //parameters
        double sampling_delay;          //sampling delay in gas composition measurement [h]
        double ya1;                     //mol fraction A in feed 1
        double yb1;                     //mol fraction B in feed 1
        double yc1;
        double product_valve_max;       // max allowed posiition for product valve[%]
        double level_gain;              //gain for level controller
        double product_valve_nom;       //nominal steady state for product valve [%]
        double kpar;                      //pre-exponential k0 of eq 5
        double ncpar;                      //power on Pc in eq 5


        //state variables
        double molar_A;             //NA        kmol
        double molar_B;             //NB        kmol
        double molar_C;             //NC        kmol
        double molar_D;             //ND        kmol
        double f1_valve_pos;        //X1        percentage
        double f2_valve_pos;        //X2        percentage
        double purge_valve_pos;     //X3        percentage
        double product_valve_pos;   //X4        percentage
        
        //state var derivatives
        double dxdt_molar_A;             //NA        kmol
        double dxdt_molar_B;             //NB        kmol
        double dxdt_molar_C;             //NC        kmol
        double dxdt_molar_D;             //ND        kmol       
        
        //outputs
        double f1_flow;             //F1        kmol h-1
        double f2_flow;             //F2        kmol h-1
        double purge_flow;          //F3        kmol h-1
        double product_flow;        //F4        kmol h-1
        double pressure;            //P         kmol h-1
        double liquid_level;        //VL        percentage
        double A_in_purge;          //yA3       kmol h-1
        double B_in_purge;          //yB3       kmol h-1
        double C_in_purge;          //yC3       kmol h-1
        double ymeas[4];            //used for delayed sampling
        double ylast[4];            //used for delayed sampling
        double cost;                //C         kmol h-1
    public:
        void steady_state();
        TE();
        void update(Json::Value inputs);
        void print_outputs();
        Json::Value get_state_json() ;
        
};



#endif
