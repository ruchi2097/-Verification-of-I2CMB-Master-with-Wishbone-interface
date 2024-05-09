class wb_transaction_base extends ncsu_transaction;
  `ncsu_register_object(wb_transaction_base)  // To register wb_transaction with the object factory
   bit [WB_ADDR_WIDTH-1:0] address; //register address
   bit we = 0; //operation
   bit [WB_DATA_WIDTH-1:0] data; //data

   function new(string name = "");
      super.new(name);
   endfunction

   virtual function string convert2string();
   if(address == 1)
      return {super.convert2string(), $sformatf("WB_ADDRESS:%0x WRITE_ENABLE:%0d DATA:%0d",
              address, we, data)};
   endfunction

   function bit compare(wb_transaction_base rhs);
      return ((this.address == rhs.address) && (this.we == rhs.we) && (this.data == rhs.data));
   endfunction

 /*  virtual function void add_to_wave(int transaction_viewing_stream_h);
     super.add_to_wave(transaction_viewing_stream_h);
      $add_attribute(transaction_view_h, address, "address");
      $add_attribute(transaction_view_h, we, "write_enable");
      $add_attribute(transaction_view_h, data, "data");
      $end_transaction(transaction_view_h, end_time);
      $free_transaction(transaction_view_h); 
   endfunction
*/

endclass
