class i2c_monitor extends ncsu_component#(.T(i2c_transaction_base));

  i2c_configuration  configuration;
  virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)bus;

  T i2c_monitored_trans;
  ncsu_component #(T) i2c_agent;

// Here when monitor is constructed, it is given a name handle of parent-> the corresponding agent it belongs to
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) i2c_agent);
    this.i2c_agent = i2c_agent;
  endfunction
  
  virtual task run ();
      forever begin
        i2c_monitored_trans = new("i2c_monitored_trans");
        if ( enable_transaction_viewing) begin
           i2c_monitored_trans.start_time = $time;
        end 

        // Monitor of agent calls monitor of interface and it's used in forever begin because monitor has to keep monitoring the data
        bus.monitor(i2c_monitored_trans.address,
                    i2c_monitored_trans.op,
                    i2c_monitored_trans.data
                    );
    /*    ncsu_info("i2c_monitor::run()", $sformatf("%s  i2c_ADDRESS:0x%h i2c_DATA :0x%p OPERATION:0x%x",get_full_name(),
                 		i2c_monitored_trans.address,
						i2c_monitored_trans.data,
						i2c_monitored_trans.op) ,NCSU_NONE); */

      //calls nb_put of agent to send transaction to scoreboard.
         i2c_agent.nb_put(i2c_monitored_trans);  

        if ( enable_transaction_viewing) begin
           i2c_monitored_trans.end_time = $time;
           i2c_monitored_trans.add_to_wave(transaction_viewing_stream);
        end
    end
  endtask

endclass
