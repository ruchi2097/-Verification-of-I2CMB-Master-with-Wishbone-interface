class wb_driver extends ncsu_component#(.T(wb_transaction_base));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;
  wb_configuration configuration;
  wb_transaction_base trans;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
	if(trans.we) begin
   bus.master_read(trans.address, trans.data);
   end 
    else begin
    bus.master_write(trans.address, trans.data);
   end
  //   $display("%s %s",get_full_name(),trans.convert2string);        
  endtask

	task wb_interrupt_check();
		bus.wait_for_interrupt();
	endtask

endclass
