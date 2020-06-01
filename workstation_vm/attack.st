FUNCTION_BLOCK scale_to_real
  VAR_INPUT
    raw_input_value : UINT;
  END_VAR
  VAR_OUTPUT
    scaled_real : REAL;
  END_VAR
  VAR_INPUT
    real_max : REAL;
    real_min : REAL;
  END_VAR
  VAR
    raw_max : UINT := 65535;
    raw_min : UINT := 0;
    rate : REAL;
    offset : REAL;
  END_VAR

  rate := (real_max - real_min) / UINT_TO_REAL(raw_max - raw_min);
  offset := real_min - UINT_TO_REAL(raw_min)*rate;
  scaled_real := UINT_TO_REAL(raw_input_value)*rate + offset;
END_FUNCTION_BLOCK

FUNCTION_BLOCK scale_to_uint
  VAR_INPUT
    real_in : REAL;
  END_VAR
  VAR_OUTPUT
    uint_out : UINT;
  END_VAR
  VAR
    DIV1_OUT : REAL;
    MUL4_OUT : REAL;
    REAL_TO_UINT6_OUT : UINT;
  END_VAR

  DIV1_OUT := DIV(real_in, 100.0);
  MUL4_OUT := MUL(DIV1_OUT, 65535.0);
  REAL_TO_UINT6_OUT := REAL_TO_UINT(MUL4_OUT);
  uint_out := REAL_TO_UINT6_OUT;
END_FUNCTION_BLOCK

FUNCTION_BLOCK composition_control
  VAR
    PID0 : PID;
    a_in_purge_real : REAL := 47.00;
  END_VAR
  VAR_INPUT
    a_in_purge : UINT := 32000;
  END_VAR
  VAR
    a_setpoint_real : REAL := 47.00;
  END_VAR
  VAR_INPUT
    a_setpoint : UINT := 32000;
    curr_pos : UINT := 16000;
  END_VAR
  VAR
    valve_pos_real : REAL := 25.0;
    pos_update_real : REAL := 0.0;
    valve_pos_nominal : REAL := 25.0;
  END_VAR
  VAR_OUTPUT
    new_pos : UINT := 16000;
  END_VAR
  VAR
    composition_k : REAL := 2.0;
    composition_ti : REAL := 99.0;
    cycle_time : TIME := T#200ms;
    scale_to_real3 : scale_to_real;
    scale_to_real2 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    comp_max : REAL := 100.0;
    comp_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    pos_min : REAL := 0.0;
    scale_to_real0 : scale_to_real;
    SUB42_OUT : REAL;
    LIMIT44_OUT : REAL;
  END_VAR

  scale_to_real3(raw_input_value := a_in_purge, real_max := comp_max, real_min := comp_min);
  a_in_purge_real := scale_to_real3.scaled_real;
  scale_to_real2(raw_input_value := a_setpoint, real_max := comp_max, real_min := comp_min);
  a_setpoint_real := scale_to_real2.scaled_real;
  PID0(AUTO := TRUE, PV := a_in_purge_real, SP := a_setpoint_real, X0 := valve_pos_nominal, KP := composition_k, TR := composition_ti, CYCLE := cycle_time);
  pos_update_real := PID0.XOUT;
  scale_to_real0(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  valve_pos_real := scale_to_real0.scaled_real;
  SUB42_OUT := SUB(valve_pos_real, pos_update_real);
  LIMIT44_OUT := LIMIT(pos_min, SUB42_OUT, pos_max);
  scale_to_uint0(real_in := LIMIT44_OUT);
  new_pos := scale_to_uint0.uint_out;
END_FUNCTION_BLOCK

FUNCTION_BLOCK pressure_control
  VAR
    pressure_real : REAL := 2700.0;
  END_VAR
  VAR_INPUT
    pressure : UINT := 58981;
  END_VAR
  VAR
    pressure_sp_real : REAL := 2700.0;
  END_VAR
  VAR_INPUT
    pressure_sp : UINT := 58981;
    curr_pos : UINT := 30000;
  END_VAR
  VAR
    valve_pos_real : REAL := 39.25;
    pos_update_real : REAL := 0.0;
    valve_pos_nominal : REAL := 39.25;
  END_VAR
  VAR_OUTPUT
    valve_pos : UINT := 25886;
  END_VAR
  VAR
    pressure_k : REAL := -2.0;
    pressure_ti : REAL := 999.0;
    cycle_time : TIME := T#200ms;
    PID0 : PID;
    scale_to_real5 : scale_to_real;
    scale_to_real4 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    pressure_max : REAL := 3000.0;
    pressure_min : REAL := 0.0;
    pos_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    scale_to_real0 : scale_to_real;
    SUB53_OUT : REAL;
    LIMIT55_OUT : REAL;
  END_VAR

  scale_to_real5(raw_input_value := pressure, real_max := pressure_max, real_min := pressure_min);
  pressure_real := scale_to_real5.scaled_real;
  scale_to_real4(raw_input_value := pressure_sp, real_max := pressure_max, real_min := pressure_min);
  pressure_sp_real := scale_to_real4.scaled_real;
  PID0(AUTO := TRUE, PV := pressure_real, SP := pressure_sp_real, X0 := valve_pos_nominal, KP := pressure_k, TR := pressure_ti, CYCLE := cycle_time);
  pos_update_real := PID0.XOUT;
  scale_to_real0(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  valve_pos_real := scale_to_real0.scaled_real;
  SUB53_OUT := SUB(valve_pos_real, pos_update_real);
  LIMIT55_OUT := LIMIT(pos_min, SUB53_OUT, pos_max);
  scale_to_uint0(real_in := LIMIT55_OUT);
  valve_pos := scale_to_uint0.uint_out;
END_FUNCTION_BLOCK

FUNCTION_BLOCK flow_control
  VAR
    flow_k : REAL := 2.0;
    flow_ti : REAL := 999.0;
    flow_td : REAL := 0.0;
  END_VAR
  VAR_INPUT
    product_flow : UINT := 6554;
  END_VAR
  VAR
    product_flow_real : REAL := 100.0;
    cycle_time : TIME := T#200ms;
    pos_update_real : REAL := 0.0;
    curr_pos_real : REAL := 60.9;
  END_VAR
  VAR_OUTPUT
    new_pos : UINT := 35000;
  END_VAR
  VAR_INPUT
    curr_pos : UINT := 35000;
  END_VAR
  VAR
    flow_set_real : REAL := 100.0;
  END_VAR
  VAR_INPUT
    flow_set_in : UINT := 6554;
  END_VAR
  VAR
    scale_to_real0 : scale_to_real;
    scale_to_real1 : scale_to_real;
    flow_max : REAL := 500.0;
    flow_min : REAL := 0.0;
    pos_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    scale_to_real2 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    PID0 : PID;
    SUB58_OUT : REAL;
    LIMIT40_OUT : REAL;
  END_VAR

  scale_to_real0(raw_input_value := product_flow, real_max := flow_max, real_min := flow_min);
  product_flow_real := scale_to_real0.scaled_real;
  scale_to_real1(raw_input_value := flow_set_in, real_max := flow_max, real_min := flow_min);
  flow_set_real := scale_to_real1.scaled_real;
  PID0(AUTO := TRUE, PV := product_flow_real, SP := flow_set_real, KP := flow_k, TR := flow_ti, TD := flow_td, CYCLE := cycle_time);
  pos_update_real := PID0.XOUT;
  scale_to_real2(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  curr_pos_real := scale_to_real2.scaled_real;
  SUB58_OUT := SUB(curr_pos_real, pos_update_real);
  LIMIT40_OUT := LIMIT(pos_min, SUB58_OUT, pos_max);
  scale_to_uint0(real_in := LIMIT40_OUT);
  new_pos := scale_to_uint0.uint_out;
END_FUNCTION_BLOCK

FUNCTION_BLOCK level_control
  VAR_INPUT
    liquid_level : UINT;
    level_sp : UINT := 30000;
    curr_pos : UINT;
  END_VAR
  VAR_OUTPUT
    new_pos : UINT;
  END_VAR
  VAR
    PID0 : PID;
    cycle_time : TIME := T#200ms;
    level_k : REAL := 2.0;
    level_ti : REAL := 99999.0;
    scale_to_real0 : scale_to_real;
    level_max : REAL := 100.0;
    level_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    pos_min : REAL := 0.0;
    level_real : REAL := 44.18;
    pos_real : REAL := 47.0;
    pos_update_real : REAL := 0.0;
    sp_real : REAL := 44.18;
    scale_to_real1 : scale_to_real;
    scale_to_real2 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    ADD30_OUT : REAL;
    LIMIT25_OUT : REAL;
  END_VAR

  scale_to_real0(raw_input_value := liquid_level, real_max := level_max, real_min := level_min);
  level_real := scale_to_real0.scaled_real;
  scale_to_real1(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  pos_real := scale_to_real1.scaled_real;
  scale_to_real2(raw_input_value := level_sp, real_max := level_max, real_min := level_min);
  sp_real := scale_to_real2.scaled_real;
  PID0(AUTO := TRUE, PV := level_real, SP := sp_real, KP := level_k, TR := level_ti, CYCLE := cycle_time);
  pos_update_real := PID0.XOUT;
  ADD30_OUT := ADD(pos_real, pos_update_real);
  LIMIT25_OUT := LIMIT(pos_min, ADD30_OUT, pos_max);
  scale_to_uint0(real_in := LIMIT25_OUT);
  new_pos := scale_to_uint0.uint_out;
END_FUNCTION_BLOCK

FUNCTION_BLOCK scale_to_signed
  VAR_INPUT
    input_uint : UINT;
  END_VAR
  VAR_OUTPUT
    output_int : INT;
  END_VAR
  VAR
    DIV3_OUT : UINT;
    ABS8_OUT : UINT;
    UINT_TO_INT9_OUT : INT;
  END_VAR

  DIV3_OUT := DIV(input_uint, 2);
  ABS8_OUT := ABS(DIV3_OUT);
  UINT_TO_INT9_OUT := UINT_TO_INT(ABS8_OUT);
  output_int := UINT_TO_INT9_OUT;
END_FUNCTION_BLOCK

PROGRAM main
  VAR
    flow_set AT %MW0 : UINT := 0;
    a_setpoint AT %MW1 : UINT := 65535;
    pressure_sp AT %MW2 : UINT := 65535;
    override_sp AT %MW3 : UINT := 65535;
    level_sp AT %MW4 : UINT := 65535;
  END_VAR
  VAR
    scale_to_signed0 : scale_to_signed;
  END_VAR
  VAR
    f1_valve_pos AT %IW0 : UINT := 30000;
    f1_flow AT %IW1 : UINT := 30000;
    f2_valve_pos AT %IW2 : UINT := 30000;
    f2_flow AT %IW3 : UINT := 30000;
    purge_valve_pos AT %IW4 : UINT := 30000;
    purge_flow AT %IW5 : UINT := 30000;
    product_valve_pos AT %IW6 : UINT := 30000;
    product_flow AT %IW7 : UINT := 10000;
    pressure AT %IW8 : UINT := 60000;
    level AT %IW9 : UINT := 30000;
    a_in_purge AT %IW10 : UINT := 30000;
    b_in_purge AT %IW11 : UINT := 10000;
    c_in_purge AT %IW12 : UINT := 10000;
    f1_valve_sp AT %QW0 : UINT := 65535;
    f2_valve_sp AT %QW1 : UINT := 65535;
    purge_valve_sp AT %QW2 : UINT := 0;
    product_valve_sp AT %QW3 : UINT := 0;
  END_VAR
  VAR
    product_valve_safe : UINT := 0;
    purge_valve_safe : UINT := 65535;
    f1_valve_safe : UINT := 0;
    f2_valve_safe : UINT := 0;
  END_VAR
  VAR
    hmi_pressure AT %MW20 : INT;
    hmi_level AT %MW21 : INT;
    hmi_f1_valve_pos AT %MW22 : INT;
    hmi_f1_flow AT %MW23 : INT;
    hmi_f2_valve_pos AT %MW24 : INT;
    hmi_f2_flow AT %MW25 : INT;
    hmi_purge_valve_pos AT %MW26 : INT;
    hmi_purge_flow AT %MW27 : INT;
    hmi_product_valve_pos AT %MW28 : INT;
    hmi_product_flow AT %MW29 : INT;
    scan_count AT %MW30 : UINT := 0;
  END_VAR
  VAR
    scale_to_signed1 : scale_to_signed;
    scale_to_signed2 : scale_to_signed;
    scale_to_signed3 : scale_to_signed;
    scale_to_signed4 : scale_to_signed;
    scale_to_signed5 : scale_to_signed;
    scale_to_signed6 : scale_to_signed;
    scale_to_signed7 : scale_to_signed;
    scale_to_signed8 : scale_to_signed;
    scale_to_signed9 : scale_to_signed;
  END_VAR
  VAR_EXTERNAL
    run_bit : BOOL;
  END_VAR
  VAR
    ADD87_OUT : UINT;
    GE91_OUT : BOOL;
    MOVE92_ENO : BOOL;
    MOVE92_OUT : UINT;
  END_VAR

  scale_to_signed0(input_uint := 30000);
  hmi_pressure := scale_to_signed0.output_int;
  scale_to_signed1(input_uint := 16000);
  hmi_level := scale_to_signed1.output_int;
  scale_to_signed2(input_uint := 10000);
  hmi_f1_valve_pos := scale_to_signed2.output_int;
  scale_to_signed3(input_uint := 10000);
  hmi_f2_valve_pos := scale_to_signed3.output_int;
  scale_to_signed4(input_uint := 3000);
  hmi_purge_valve_pos := scale_to_signed4.output_int;
  scale_to_signed5(input_uint := 15000);
  hmi_product_valve_pos := scale_to_signed5.output_int;
  scale_to_signed6(input_uint := 10000);
  hmi_f1_flow := scale_to_signed6.output_int;
  scale_to_signed7(input_uint := 10000);
  hmi_f2_flow := scale_to_signed7.output_int;
  scale_to_signed8(input_uint := 3000);
  hmi_purge_flow := scale_to_signed8.output_int;
  scale_to_signed9(input_uint := 15000);
  hmi_product_flow := scale_to_signed9.output_int;
  ADD87_OUT := ADD(scan_count, 1);
  scan_count := ADD87_OUT;
  GE91_OUT := GE(scan_count, 32000);
  MOVE92_OUT := MOVE(EN := GE91_OUT, IN := 0, ENO => MOVE92_ENO);
  scan_count := MOVE92_OUT;
END_PROGRAM

FUNCTION_BLOCK pressure_override
  VAR
    pressure_real : REAL := 2700.0;
  END_VAR
  VAR_INPUT
    pressure : UINT := 58981;
    curr_sp : UINT := 58981;
  END_VAR
  VAR
    curr_sp_real : REAL := 2700.0;
    product_sp_real : REAL := 100.0;
    sp_update : REAL := 0.0;
    product_sp_nominl : REAL := 100.0;
  END_VAR
  VAR_OUTPUT
    product_sp : UINT := 13107;
  END_VAR
  VAR
    override_sp_real : REAL := 2900.0;
  END_VAR
  VAR_INPUT
    override_sp : UINT := 63350;
  END_VAR
  VAR
    override_k : REAL := 2.0;
    override_ti : REAL := 99999.0;
    cycle_time : TIME := T#200ms;
    PID0 : PID;
    scale_to_real7 : scale_to_real;
    pressure_max : REAL := 3000.0;
    pressure_min : REAL := 0.0;
    flow_max : REAL := 500.0;
    flow_min : REAL := 0.0;
    scale_to_real0 : scale_to_real;
    MAX84_OUT : REAL;
    SUB85_OUT : REAL;
    LIMIT67_OUT : REAL;
    DIV73_OUT : REAL;
    MUL75_OUT : REAL;
    REAL_TO_UINT79_OUT : UINT;
  END_VAR

  scale_to_real7(raw_input_value := pressure, real_max := pressure_max, real_min := pressure_min);
  pressure_real := scale_to_real7.scaled_real;
  PID0(AUTO := TRUE, PV := pressure_real, SP := override_sp_real, KP := override_k, TR := override_ti, CYCLE := cycle_time);
  MAX84_OUT := MAX(PID0.XOUT, 0.0);
  sp_update := MAX84_OUT;
  scale_to_real0(raw_input_value := curr_sp, real_max := flow_max, real_min := flow_min);
  curr_sp_real := scale_to_real0.scaled_real;
  SUB85_OUT := SUB(curr_sp_real, sp_update);
  LIMIT67_OUT := LIMIT(50.0, SUB85_OUT, 150.0);
  product_sp_real := LIMIT67_OUT;
  DIV73_OUT := DIV(product_sp_real, 500.0);
  MUL75_OUT := MUL(DIV73_OUT, 65535.0);
  REAL_TO_UINT79_OUT := REAL_TO_UINT(MUL75_OUT);
  product_sp := REAL_TO_UINT79_OUT;
END_FUNCTION_BLOCK


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      run_bit AT %QX0.0 : BOOL := 1;
    END_VAR
    TASK MainTask(INTERVAL := T#200ms,PRIORITY := 0);
    PROGRAM instance0 WITH MainTask : main;
  END_RESOURCE
END_CONFIGURATION
