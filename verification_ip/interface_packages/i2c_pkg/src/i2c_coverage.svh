class i2c_coverage extends ncsu_component#(.T(i2c_transaction_base));
	
    i2c_configuration configuration;
    i2c_op_t op;
    bit [I2C_ADDR_WIDTH-1:0]  i2c_addr;
    bit [I2C_DATA_WIDTH-1:0] i2c_data;

    covergroup  i2c_transaction_cg;
    option.per_instance = 1;
    option.name = get_full_name();

    I2C_ADDRESS :coverpoint i2c_addr { bins used [1] = {34} ;}  //As we are writing to hexa address 22 -> which in decimal is 34
    I2C_DATA: coverpoint i2c_data  { bins ranges[4] = {[0:127]}; }
    I2C_OP: coverpoint op;
    I2C_addr_x_op : cross I2C_ADDRESS , I2C_OP;
    endgroup

function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
 //   $display("i2c_coverage::nb_put() %s called",get_full_name());
    i2c_addr = trans.address;
    i2c_data = trans.data[0];
    op = trans.op;
    i2c_transaction_cg.sample();
  endfunction





endclass