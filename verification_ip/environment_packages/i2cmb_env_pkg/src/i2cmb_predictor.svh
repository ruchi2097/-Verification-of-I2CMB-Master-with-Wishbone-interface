class i2cmb_predictor extends ncsu_component#(.T(wb_transaction_base));
// predictor is used by wb

  i2cmb_scoreboard scoreboard;
  i2c_transaction_base predicted_trans;
  i2cmb_env_configuration configuration;

   bit [I2C_ADDR_WIDTH-1:0] addr;
   bit [I2C_DATA_WIDTH-1:0] write_data[];
   bit [I2C_DATA_WIDTH-1:0] read_data[];
   i2c_op_t op;
   bit [2:0] state;
  typedef enum bit [1:0] {
  CSR  = 0,
  DPR  = 1,
  CMDR = 2,
  FSMR = 3
  } register_type;
  
  typedef enum bit[2:0] {
  S_START,
  S_ADDR,
  S_READ,
  S_WRITE,
  S_STOP
  } trans_state;

  // parent of predictor is i2cmb environment
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(i2cmb_scoreboard scoreboard);
      this.scoreboard = scoreboard;
  endfunction
               
   virtual function void nb_put(wb_transaction_base trans);
  // $display("Predictor's nb put called \n");
   case(state)

   S_START: 
   begin
   if(trans.address == CMDR && trans.data==3'b100) begin
      state = S_ADDR;
      end
   end

   S_ADDR:  // Address we need to send to i2c is collected in this state
   begin
      if(trans.address == DPR)begin
         addr = trans.data>>1;   // When wb writes transaction it left shifts slave address by 1 or 0, so we are right shifting it to get back the address
         op = trans.data[0]? READ:WRITE;    // If the operation is read or right hence stored at 0th bit
         if(op == READ)
            state = S_READ;
         else   
            state = S_WRITE;    
      end
   end

   S_READ:
   begin
      if(trans.address == DPR ) begin
         read_data = new[read_data.size()+1](read_data);
         read_data[read_data.size()-1] = trans.data;
         state = S_READ;    //This will make sure continuous read takes place
      end
      else if(trans.address == CMDR  && trans.data == 3'b101) begin
         predicted_trans = new;
         predicted_trans.address = addr;
         predicted_trans.op = op;
         predicted_trans.data = read_data;
         scoreboard.nb_transport(predicted_trans, null);
         read_data.delete();
         state = S_START;
      end
   end

   S_WRITE:
   begin
    //  if(trans.address==1'b1)
    //  $display("trans.address=%0x trans.data=%0d trans.we = %0d \n",trans.address,trans.data,trans.we);
      if(trans.address==DPR ) begin
         write_data = new[write_data.size()+1](write_data);
         write_data[write_data.size()-1] = trans.data;
         state = S_WRITE;        //This will make sure continuous write takes place
      end  
      if(trans.address==CMDR && trans.data == 3'b101) begin
         predicted_trans = new;
         predicted_trans.address = addr;
         predicted_trans.op = op;
         predicted_trans.data = write_data;
         scoreboard.nb_transport(predicted_trans, null);
         write_data.delete();
         state = S_START;
      end 
   end
   
   default:
   begin
      state = S_START;
   end

   endcase
   endfunction
endclass
