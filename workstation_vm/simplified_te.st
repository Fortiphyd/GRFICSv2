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
    composition_k : REAL := 1.0;
    composition_ti : REAL := 99.0;
    cycle_time : TIME := T#50ms;
    scale_to_real3 : scale_to_real;
    scale_to_real2 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    comp_max : REAL := 100.0;
    comp_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    pos_min : REAL := 0.0;
    scale_to_real0 : scale_to_real;
    SUB45_OUT : REAL;
    MUL46_OUT : REAL;
    ADD42_OUT : REAL;
    LIMIT44_OUT : REAL;
  END_VAR

  scale_to_real3(raw_input_value := a_in_purge, real_max := comp_max, real_min := comp_min);
  a_in_purge_real := scale_to_real3.scaled_real;
  scale_to_real2(raw_input_value := a_setpoint, real_max := comp_max, real_min := comp_min);
  a_setpoint_real := scale_to_real2.scaled_real;
  SUB45_OUT := SUB(a_setpoint_real, a_in_purge_real);
  MUL46_OUT := MUL(SUB45_OUT, composition_k);
  pos_update_real := MUL46_OUT;
  scale_to_real0(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  valve_pos_real := scale_to_real0.scaled_real;
  ADD42_OUT := ADD(valve_pos_real, pos_update_real);
  LIMIT44_OUT := LIMIT(pos_min, ADD42_OUT, pos_max);
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
    pressure_k : REAL := 20.0;
    pressure_ti : REAL := 999.0;
    cycle_time : TIME := T#50ms;
    scale_to_real5 : scale_to_real;
    scale_to_real4 : scale_to_real;
    scale_to_uint0 : scale_to_uint;
    pressure_max : REAL := 3200.00;
    pressure_min : REAL := 0.0;
    pos_min : REAL := 0.0;
    pos_max : REAL := 100.0;
    scale_to_real0 : scale_to_real;
    SUB57_OUT : REAL;
    MUL60_OUT : REAL;
    SUB53_OUT : REAL;
    LIMIT55_OUT : REAL;
  END_VAR

  scale_to_real5(raw_input_value := pressure, real_max := pressure_max, real_min := pressure_min);
  pressure_real := scale_to_real5.scaled_real;
  scale_to_real4(raw_input_value := pressure_sp, real_max := pressure_max, real_min := pressure_min);
  pressure_sp_real := scale_to_real4.scaled_real;
  SUB57_OUT := SUB(pressure_sp_real, pressure_real);
  MUL60_OUT := MUL(SUB57_OUT, pressure_k);
  pos_update_real := MUL60_OUT;
  scale_to_real0(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  valve_pos_real := scale_to_real0.scaled_real;
  SUB53_OUT := SUB(valve_pos_real, pos_update_real);
  LIMIT55_OUT := LIMIT(pos_min, SUB53_OUT, pos_max);
  scale_to_uint0(real_in := LIMIT55_OUT);
  valve_pos := scale_to_uint0.uint_out;
END_FUNCTION_BLOCK

FUNCTION_BLOCK flow_control
  VAR
    flow_k : REAL := 1.0;
    flow_ti : REAL := 999.0;
    flow_td : REAL := 0.0;
  END_VAR
  VAR_INPUT
    product_flow : UINT := 6554;
  END_VAR
  VAR
    product_flow_real : REAL := 100.0;
    cycle_time : TIME := T#50ms;
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
    SUB59_OUT : REAL;
    MUL60_OUT : REAL;
    ADD58_OUT : REAL;
    LIMIT40_OUT : REAL;
  END_VAR

  scale_to_real0(raw_input_value := product_flow, real_max := flow_max, real_min := flow_min);
  product_flow_real := scale_to_real0.scaled_real;
  scale_to_real1(raw_input_value := flow_set_in, real_max := flow_max, real_min := flow_min);
  flow_set_real := scale_to_real1.scaled_real;
  SUB59_OUT := SUB(flow_set_real, product_flow_real);
  MUL60_OUT := MUL(SUB59_OUT, flow_k);
  pos_update_real := MUL60_OUT;
  scale_to_real2(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  curr_pos_real := scale_to_real2.scaled_real;
  ADD58_OUT := ADD(curr_pos_real, pos_update_real);
  LIMIT40_OUT := LIMIT(pos_min, ADD58_OUT, pos_max);
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
    cycle_time : TIME := T#50ms;
    level_k : REAL := 10.0;
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
    SUB32_OUT : REAL;
    MUL33_OUT : REAL;
    SUB30_OUT : REAL;
    LIMIT25_OUT : REAL;
  END_VAR

  scale_to_real0(raw_input_value := liquid_level, real_max := level_max, real_min := level_min);
  level_real := scale_to_real0.scaled_real;
  scale_to_real1(raw_input_value := curr_pos, real_max := pos_max, real_min := pos_min);
  pos_real := scale_to_real1.scaled_real;
  scale_to_real2(raw_input_value := level_sp, real_max := level_max, real_min := level_min);
  sp_real := scale_to_real2.scaled_real;
  SUB32_OUT := SUB(sp_real, level_real);
  MUL33_OUT := MUL(SUB32_OUT, level_k);
  pos_update_real := MUL33_OUT;
  SUB30_OUT := SUB(pos_real, pos_update_real);
  LIMIT25_OUT := LIMIT(pos_min, SUB30_OUT, pos_max);
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
    override_k : REAL := 1.0;
    override_ti : REAL := 99999.0;
    cycle_time : TIME := T#50ms;
    scale_to_real7 : scale_to_real;
    pressure_max : REAL := 3000.0;
    pressure_min : REAL := 0.0;
    flow_max : REAL := 500.0;
    flow_min : REAL := 0.0;
    scale_to_real0 : scale_to_real;
    SUB86_OUT : REAL;
    MUL87_OUT : REAL;
    MAX84_OUT : REAL;
    ADD85_OUT : REAL;
    LIMIT67_OUT : REAL;
    DIV73_OUT : REAL;
    MUL75_OUT : REAL;
    REAL_TO_UINT79_OUT : UINT;
  END_VAR

  scale_to_real7(raw_input_value := pressure, real_max := pressure_max, real_min := pressure_min);
  pressure_real := scale_to_real7.scaled_real;
  SUB86_OUT := SUB(override_sp_real, pressure_real);
  MUL87_OUT := MUL(SUB86_OUT, override_k);
  MAX84_OUT := MAX(MUL87_OUT, 0.0);
  sp_update := MAX84_OUT;
  scale_to_real0(raw_input_value := curr_sp, real_max := flow_max, real_min := flow_min);
  curr_sp_real := scale_to_real0.scaled_real;
  ADD85_OUT := ADD(curr_sp_real, sp_update);
  LIMIT67_OUT := LIMIT(50.0, ADD85_OUT, 150.0);
  product_sp_real := LIMIT67_OUT;
  DIV73_OUT := DIV(product_sp_real, 500.0);
  MUL75_OUT := MUL(DIV73_OUT, 65535.0);
  REAL_TO_UINT79_OUT := REAL_TO_UINT(MUL75_OUT);
  product_sp := REAL_TO_UINT79_OUT;
END_FUNCTION_BLOCK

PROGRAM main
  VAR
    flow_control0 : flow_control;
  END_VAR
  VAR
    flow_set AT %MW0 : UINT := 13107;
    a_setpoint AT %MW1 : UINT := 30801;
    pressure_sp AT %MW2 : UINT := 55295;
    override_sp AT %MW3 : UINT := 31675;
    level_sp AT %MW4 : UINT := 28835;
  END_VAR
  VAR
    composition_control0 : composition_control;
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
    f1_valve_sp AT %QW0 : UINT := 30000;
    f2_valve_sp AT %QW1 : UINT := 30000;
    purge_valve_sp AT %QW2 : UINT := 30000;
    product_valve_sp AT %QW3 : UINT := 30000;
  END_VAR
  VAR
    product_valve_safe : UINT := 0;
    purge_valve_safe : UINT := 65535;
    f1_valve_safe : UINT := 0;
    f2_valve_safe : UINT := 0;
    pressure_control0 : pressure_control;
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
    pressure_override0 : pressure_override;
    level_control0 : level_control;
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

  flow_control0(product_flow := product_flow, curr_pos := f1_valve_pos, flow_set_in := flow_set);
  f1_valve_sp := flow_control0.new_pos;
  pressure_control0(pressure := pressure, pressure_sp := pressure_sp, curr_pos := purge_valve_pos);
  purge_valve_sp := pressure_control0.valve_pos;
  composition_control0(a_in_purge := a_in_purge, a_setpoint := a_setpoint, curr_pos := f2_valve_pos);
  f2_valve_sp := composition_control0.new_pos;
  pressure_override0(pressure := pressure, curr_sp := flow_set, override_sp := override_sp);
  flow_set := pressure_override0.product_sp;
  level_control0(liquid_level := level, level_sp := level_sp, curr_pos := product_valve_pos);
  product_valve_sp := level_control0.new_pos;
  scale_to_signed0(input_uint := pressure);
  hmi_pressure := scale_to_signed0.output_int;
  scale_to_signed1(input_uint := level);
  hmi_level := scale_to_signed1.output_int;
  scale_to_signed2(input_uint := f1_valve_pos);
  hmi_f1_valve_pos := scale_to_signed2.output_int;
  scale_to_signed3(input_uint := f2_valve_pos);
  hmi_f2_valve_pos := scale_to_signed3.output_int;
  scale_to_signed4(input_uint := purge_valve_pos);
  hmi_purge_valve_pos := scale_to_signed4.output_int;
  scale_to_signed5(input_uint := product_valve_pos);
  hmi_product_valve_pos := scale_to_signed5.output_int;
  scale_to_signed6(input_uint := f1_flow);
  hmi_f1_flow := scale_to_signed6.output_int;
  scale_to_signed7(input_uint := f2_flow);
  hmi_f2_flow := scale_to_signed7.output_int;
  scale_to_signed8(input_uint := purge_flow);
  hmi_purge_flow := scale_to_signed8.output_int;
  scale_to_signed9(input_uint := product_flow);
  hmi_product_flow := scale_to_signed9.output_int;
  ADD87_OUT := ADD(scan_count, 1);
  scan_count := ADD87_OUT;
  GE91_OUT := GE(scan_count, 32000);
  MOVE92_OUT := MOVE(EN := GE91_OUT, IN := 0, ENO => MOVE92_ENO);
  scan_count := MOVE92_OUT;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      run_bit AT %QX0.0 : BOOL := 1;
    END_VAR
    TASK MainTask(INTERVAL := T#50ms,PRIORITY := 0);
    PROGRAM instance0 WITH MainTask : main;
  END_RESOURCE
END_CONFIGURATION
