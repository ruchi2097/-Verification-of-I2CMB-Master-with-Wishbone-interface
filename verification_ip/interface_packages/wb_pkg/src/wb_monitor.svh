class wb_monitor extends ncsu_component#(.T(wb_transaction_base));

  wb_configuration  configuration;
	virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;

  T wb_monitored_trans;
  ncsu_component #(T) wb_agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) wb_agent);
    this.wb_agent = wb_agent;
  endfunction

	
	task wb_interrupt_check();
    bus.wait_for_interrupt();
	endtask

  
  virtual task run ();
    bus.wait_for_reset();
      forever begin
        wb_monitored_trans = new("wb_monitored_trans");
        if ( enable_transaction_viewing) begin
           wb_monitored_trans.start_time = $time;
        end
        bus.master_monitor(wb_monitored_trans.address,
                    wb_monitored_trans.data,wb_monitored_trans.we);
      /*  ncsu_info("wb_monitor::run()" ,$sformatf("%s WB_ADDRESS 0x%h WB_DATA %0d WB_WE 0x%x ",
                 get_full_name(),
                 wb_monitored_trans.address, 
                 wb_monitored_trans.data, 
				          wb_monitored_trans.we) , NCSU_NONE); */
             
      // calls nb_put for agent that sends transaction for all subscribers - in this case coverage and predictor.
        wb_agent.nb_put(wb_monitored_trans);

        if ( enable_transaction_viewing) begin
           wb_monitored_trans.end_time = $time;
           wb_monitored_trans.add_to_wave(transaction_viewing_stream);
        end 
    end 
  endtask

endclass
