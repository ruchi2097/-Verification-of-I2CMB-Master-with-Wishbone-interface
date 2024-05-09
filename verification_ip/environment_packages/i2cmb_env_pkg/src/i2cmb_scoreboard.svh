class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction_base));

T predicted_trans;
T actual_trans;

// parent of scoreboard is i2cmb env
function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

// parent of scoreboard is i2cmb environment
// Called by wb predictor
  virtual function void nb_transport(input T input_trans, output T output_trans);
    predicted_trans = input_trans;
    output_trans = actual_trans;
    $display("%s nb_transport Predicted Output from Predictor %s",get_full_name(),input_trans.convert2string);       
  endfunction


//Called by i2c monitor via agent
  virtual function void nb_put(T trans);
  $display("%s nb_put Actual Output from DUT %s",get_full_name(),trans.convert2string);        
  
  if(this.predicted_trans.compare(trans)) begin 
   $display({get_full_name()," Predicted and Actual Transactions MATCH!"});
  end
  else begin 
   $display({get_full_name()," Predicted and Actual Transactions MISMATCH!"});
  end

  
  endfunction


endclass : i2cmb_scoreboard