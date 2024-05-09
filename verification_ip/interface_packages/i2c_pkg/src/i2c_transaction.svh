class i2c_transaction_base extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction_base) //Used for registering object in factory for dynamic creation of objects

// Used all data members of i2c inteface to make a transaction
	i2c_op_t op;
	bit[I2C_ADDR_WIDTH-1:0] address;
	bit[I2C_DATA_WIDTH-1:0] data[];
	bit[I2C_DATA_WIDTH-1:0] write_data[];

  function new(string name=""); 
    super.new(name);
  endfunction

//Display function for transaction
  virtual function string convert2string();
		return {super.convert2string(),$sformatf("I2C_ADDRESS:0x%h I2C_DATA :0x%p OPERATION:0x%x",address, data, op)};
	endfunction	


//Comapres two transaction, the transaction passed in argument with current transaction.
  function bit compare(i2c_transaction_base rhs);
    return ((this.address == rhs.address ) && 
            (this.data == rhs.data) &&
			(this.write_data == rhs.write_data) &&
            (this.op == rhs.op) );
  endfunction

 /* virtual function void add_to_wave(int transaction_viewing_stream_h);
     super.add_to_wave(transaction_viewing_stream_h);
     $add_attribute(transaction_view_h,op,"op");
     $add_attribute(transaction_view_h,address,"address");
     $add_attribute(transaction_view_h,data,"data");
     $add_attribute(transaction_view_h,write_data,"write_data");
     $end_transaction(transaction_view_h,end_time);
     $free_transaction(transaction_view_h); 
  endfunction
  */

endclass
