class i2cmb_test extends ncsu_component #(
    .T(ncsu_transaction)
);

  i2cmb_env_configuration cfg;
  i2cmb_environment       env;
  i2cmb_generator         gen;
  string                  test_name;

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    if (!$value$plusargs("GEN_TRANS_TYPE=%s", test_name)) begin
      $display("+GEN_TRANS_TYPE plusarg invalid");
      $fatal;
    end

    cfg = new("cfg");
    env = new("env", this);
    env.set_configuration(cfg);
    env.build();
    gen = new("gen", this);
    gen.set_wb_agent(env.get_wb_agent());
    gen.set_i2c_agent(env.get_i2c_agent());
  endfunction

  virtual task run();
    env.run();
    if (test_name === "i2cmb_base") gen.run();
    else if (test_name == "i2cmb_invalid") gen.invalid();
    else if (test_name == "i2cmb_read_only") gen.read_only();
    else if (test_name == "i2cmb_default") gen.default_values();
    else if (test_name == "i2cmb_random_read") gen.random_read();
    else if (test_name == "i2cmb_random_write") gen.random_write();
    else if (test_name == "i2cmb_random_alternate") gen.random_alternate();
    else if (test_name == "i2cmb_transition") gen.fsm_transition();
    else gen.run();
  endtask

endclass : i2cmb_test
