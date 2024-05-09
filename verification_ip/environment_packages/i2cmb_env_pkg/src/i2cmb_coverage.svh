class i2cmb_coverage extends ncsu_component#(.T(wb_transaction_base));

    i2cmb_env_configuration     configuration;

    //Use to check which register is selected for wb
    bit [1:0] reg_addr;

    //Use to check the command of CMDR register if address= 2'b10 that is cmdr register is selected
    bit [2:0] data_cmdr;

    //Use to check the data of DPR register when address is 2'b01
    bit [7:0] data_dpr;
  
    covergroup i2cmb_coverage_cg;
    ADDR: coverpoint reg_addr;
    CMDR : coverpoint data_cmdr;
    DPR : coverpoint data_dpr;
    endgroup
  
    function void set_configuration(i2cmb_env_configuration cfg);
      configuration = cfg;
    endfunction
  
    function new(string name = "", ncsu_component_base  parent = null);
    super.new(name,parent);
      i2cmb_coverage_cg = new;
    endfunction
  
    virtual function void nb_put(T trans);
      reg_addr = trans.address;
      if(trans.address == 2'b10) begin
          data_cmdr = trans.data[2:0];
       end
      if(trans.address == 2'b01) begin 
          data_dpr = trans.data;
       end   
         i2cmb_coverage_cg.sample();
    endfunction
  
  endclass
  