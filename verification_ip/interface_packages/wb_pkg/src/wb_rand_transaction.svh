class wb_rand_transaction extends wb_transaction_base;
   `ncsu_register_object(wb_rand_transaction)
   
   randc bit [WB_DATA_WIDTH-1:0] rand_data; //data

   function new(string name=""); 
      super.new(name);
   endfunction

   function void post_randomize();
      data = rand_data;
   endfunction

endclass