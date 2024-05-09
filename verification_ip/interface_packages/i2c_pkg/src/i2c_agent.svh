class i2c_agent extends ncsu_component#(.T(i2c_transaction_base));

  i2c_configuration configuration;
  i2c_driver        driver;
  i2c_monitor       monitor;
  i2c_coverage      coverage;
  ncsu_component #(T) subscribers[$]; //subscribers are predictor and coverage
  virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)bus;


//config db is used to share handle of virtual interface from static (dut) to dynamic(tb) 
  //Here agent get's the handle of virtual interface from config db
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::get(get_full_name(), this.bus))) begin;
      $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    driver = new("driver",this);
    driver.set_configuration(configuration);
    driver.build();
    driver.bus = this.bus;
    monitor = new("monitor",this);
    monitor.set_configuration(configuration);
    monitor.set_agent(this);
    monitor.enable_transaction_viewing = 0;
    monitor.build();
    monitor.bus = this.bus;
    coverage = new("i2c_coverage",this);
    coverage.set_configuration(configuration);
    coverage.build();
    connect_subscriber(coverage);
  endfunction

// For subscribers non blocking put is called.
  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

// Blocking put of driver is called by agent
  virtual task bl_put(T trans);
    driver.bl_put(trans);
  endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

// Agent calls run for monitor to constantly run monitor in the background.
  virtual task run();
     fork monitor.run(); join_none
  endtask

endclass


