class wb_configuration extends ncsu_configuration;
	bit irq_enable_check = 1;
  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string};
  endfunction

endclass
