//Function of driver is to stimulate the dut.

class i2c_driver extends ncsu_component#(.T(i2c_transaction_base));

// Here when agent is constructed, it is given a name handle of parent-> the corresponding agent it belongs to
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)bus;
  i2c_configuration configuration;
  i2c_transaction_base trans;

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction


// this will call the i2c methods to send stimulus to the dut.
  virtual task bl_put(T trans);
  bit transfer_complete =0;
  	bus.wait_for_i2c_transfer(trans.op,trans.write_data);

	if(trans.op==READ)
		bus.provide_read_data(trans.data,transfer_complete);
  endtask

endclass
