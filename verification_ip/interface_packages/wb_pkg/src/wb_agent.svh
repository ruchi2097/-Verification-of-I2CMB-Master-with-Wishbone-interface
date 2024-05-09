class wb_agent extends ncsu_component#(.T(wb_transaction_base));

  wb_configuration configuration;
  wb_driver        driver;
  wb_monitor       monitor;
  wb_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH))::get(get_full_name(), this.bus))) begin;
      $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction

  function void set_configuration(wb_configuration cfg);
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
    coverage = new("wb_coverage",this);
    coverage.set_configuration(configuration);
    coverage.build();
    connect_subscriber(coverage);
  endfunction

  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  virtual task bl_put(T trans);
    driver.bl_put(trans);
    assert_IRQ_is_set:  
    assert(configuration.irq_enable_check)
    else $display("ERROR");
  endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  task wait_for_interrupt();
    monitor.wb_interrupt_check();
  endtask : wait_for_interrupt

  virtual task run();
     fork monitor.run(); join_none
  endtask

endclass


