class wb_coverage extends ncsu_component#(.T(wb_transaction_base));

    wb_configuration configuration;
    bit  we;
    bit [WB_ADDR_WIDTH-1:0]  wb_addr;
    bit [WB_DATA_WIDTH-1] wb_data;

    covergroup  wb_transaction_cg;
    option.per_instance = 1;
    option.name = get_full_name();

    WB_ADDRESS :coverpoint wb_addr;
    WB_DATA: coverpoint wb_data;
    WB_WE: coverpoint we;
    WB_addr_x_we : cross wb_addr,we;
    endgroup

//This covergroup checks the validity of registers present in register block
// csr = 0 dpr = 1 cmdr = 2 fsmr = 3 . Only 4 combinations can be accepted in bin
    covergroup register_cg;
    option.per_instance = 1;
    option.name = get_full_name();

    WB_REGISTER: coverpoint wb_addr
                {
                   bins valid_reg[4]={0,1,2,3};
                }

    endgroup

function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_transaction_cg = new;
    register_cg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
  //  $display("wb_coverage::nb_put() %s called",get_full_name());
    wb_addr = trans.address;
    wb_data = trans.data;
    we = trans.we;
    wb_transaction_cg.sample();
    register_cg.sample();
  endfunction

endclass