class i2cmb_generator extends ncsu_component #(
    .T(ncsu_transaction)
);

  typedef enum bit [1:0] {
    CSR  = 0,
    DPR  = 1,
    CMDR = 2,
    FSMR = 3
  } register_type;

  wb_transaction_base wb_trans;
  i2c_transaction_base i2c_trans;
  wb_rand_transaction wb_rand_trans;
  wb_agent wb_ag;
  int success;

  i2c_agent i2c_ag;
  i2c_op_t op;
  bit [7:0] i2c_read_data[];
  bit [7:0] wb_read_data;

  bit [WB_DATA_WIDTH-1:0] original_data[4];
  bit [WB_DATA_WIDTH-1:0] post_transaction_data[4];

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  function void set_i2c_agent(i2c_agent i2c_ag);
    this.i2c_ag = i2c_ag;
  endfunction

  function set_wb_agent(wb_agent wb_ag);
    this.wb_ag = wb_ag;
  endfunction

  task i2c_read(bit [7:0] data[]);
    $cast(i2c_trans, ncsu_object_factory::create("i2c_transaction_base"));
    i2c_trans.data = data;
    i2c_ag.bl_put(i2c_trans);
  endtask

  task i2c_write();
    $cast(i2c_trans, ncsu_object_factory::create("i2c_transaction_base"));
    i2c_ag.bl_put(i2c_trans);
  endtask

  task wb_run(bit [1:0] addr, bit [7:0] data, bit we);
    $cast(wb_trans, ncsu_object_factory::create("wb_transaction_base"));
    wb_trans.address = addr;
    if (we == 1'b0) wb_trans.data = data;
    wb_trans.we = we;
    wb_ag.bl_put(wb_trans);
  endtask

  task wb_read(bit [1:0] addr, bit [7:0] data, bit we);
    $cast(wb_trans, ncsu_object_factory::create("wb_transaction_base"));
    wb_trans.address = addr;
    if (we == 1'b0) wb_trans.data = data;
    wb_trans.we = we;
    wb_ag.bl_put(wb_trans);
    $display("Address = %0d data=%0b", wb_trans.address, wb_trans.data);
  endtask

  // ****************************************************************************
  task write_operation();
    // Start command
    wb_run(CMDR, 8'bxxxxx100, 0);
    wait_for_interrupt();
    // Slave address with write operation
    wb_run(DPR, 8'h44, 0);  ///
    wb_run(CMDR, 8'bxxxxx001, 0);
    wait_for_interrupt();
  endtask

  // ****************************************************************************
  task read_operation();
    // Start command
    wb_run(CMDR, 8'bxxxxx100, 0);
    wait_for_interrupt();

    // Slave address with read operation
    wb_run(DPR, 8'h45, 0);
    wb_run(CMDR, 8'bxxxxx001, 0);
    wait_for_interrupt();
  endtask

  // ****************************************************************************
  // Wait for interrupt
  task wait_for_interrupt();
    logic [7:0] temp_data;
    wb_ag.wait_for_interrupt();
    wb_run(CMDR, temp_data, 1);
  endtask

  // ****************************************************************************
  task run();
    $display("\n======================== Base Test (Directed) =======================");
    fork
      begin : wb_flow

        // Define the flow of the simulation
        bit [I2C_DATA_WIDTH-1:0] read_data;

        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h0, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();

        $display(
            "======================== Write 32 incrementing values to I2C =======================");
        write_operation();
        // Write 32 incrementing values
        for (int i = 0; i < 32; i++) begin
          wb_run(DPR, i, 0);
          wb_run(CMDR, 8'bxxxxx001, 0);
          wait_for_interrupt();
        end

        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();

        $display(
            "\n======================== Read 32 incrementing reads from I2C =======================");
        read_operation();
        // Read 64 incrementing values
        for (int i = 0; i < 32; i++) begin
          if (i < 64) wb_run(CMDR, 8'bxxxxx010, 0);  //ack read
          else wb_run(CMDR, 8'bxxxxx011, 0);  //nack read
          wait_for_interrupt();
          wb_run(DPR, wb_read_data, 1);
        end

        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();
        // Alternate writes and reads 
        // Alternate read 63-0/write 64-127 
        $display(
            "========== Starting 64 alternate incrementing write and decrementing reads =========");
        for (int i = 0; i < 64; i++) begin
          write_operation();
          // Write data
          wb_run(DPR, i + 64, 0);
          wb_run(CMDR, 8'bxxxxx001, 0);
          wait_for_interrupt();
          // Stop command
          wb_run(CMDR, 8'bxxxxx101, 0);
          wait_for_interrupt();

          read_operation();

          // Read with nack
          wb_run(CMDR, 8'bxxxxx011, 0);
          wait_for_interrupt();
          wb_run(DPR, wb_read_data, 1);
          // Stop command
          wb_run(CMDR, 8'bxxxxx101, 0);
          wait_for_interrupt();
        end
      end : wb_flow

      //i2c flow

      begin : i2c_flow
        int iter_j = 0;
        // Assignment 1 wb_bus written 0 to 32 bits to i2c
        i2c_write();

        // Assignment 2 provide read data for wb i.e write 100 to 132
        begin : i2c_flow
          i2c_read_data = new[32];
          for (int i = 0; i < 32; i++) begin
            i2c_read_data[i] = i + 100;
          end
          i2c_read(i2c_read_data);
        end : i2c_flow

        repeat (128) begin
          i2c_write();
          i2c_read_data = new[1];
          i2c_read_data[0] = 63 - iter_j;
          i2c_read(i2c_read_data);
          if (iter_j == 63) break;
          iter_j++;
        end
      end : i2c_flow
    join

  endtask : run

  // ****************************************************************************

  task invalid();
    $display(
        "======================== Register Aliasing/Checking the Validity of Registers =======================");
    wb_run(CSR, 8'b11xxxxxx, 0);  //Enable the core
    // Read original data 
    wb_run(CSR, 8'bxxxxxxxx, 1);
    original_data[0] = wb_trans.data;
    wb_run(DPR, 8'bxxxxxxxx, 1);
    original_data[1] = wb_trans.data;
    wb_run(CMDR, 8'bxxxxxxxx, 1);
    original_data[2] = wb_trans.data;
    wb_run(FSMR, 8'bxxxxxxxx, 1);
    original_data[3] = wb_trans.data;

    //Write to DPR register
    wb_run(DPR, 8'h100000000, 0);

    // Read the register values again
    wb_run(CSR, 8'bxxxxxxxx, 1);
    post_transaction_data[0] = wb_trans.data;
    wb_run(DPR, 8'bxxxxxxxx, 1);
    post_transaction_data[1] = wb_trans.data;
    wb_run(CMDR, 8'bxxxxxxxx, 1);
    post_transaction_data[2] = wb_trans.data;
    wb_run(FSMR, 8'bxxxxxxxx, 1);
    post_transaction_data[3] = wb_trans.data;

    if(post_transaction_data[0] == 8'b11000000 &&
         post_transaction_data[1] == 8'b00000000 &&
         post_transaction_data[2] == 8'b10000000 &&
         post_transaction_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("END TEST");
  endtask

  // ****************************************************************************

  task read_only();
    $display(
        "======================== Checking the validity of Read Only Registers =======================");
    wb_run(CSR, 8'b11xxxxxx, 0);  //Enable the core

    // Read original data 

    wb_run(CSR, 8'bxxxxxxxx, 1);
    original_data[0] = wb_trans.data;
    wb_run(DPR, 8'bxxxxxxxx, 1);
    original_data[1] = wb_trans.data;
    wb_run(CMDR, 8'bxxxxxxxx, 1);
    original_data[2] = wb_trans.data;
    wb_run(FSMR, 8'bxxxxxxxx, 1);
    original_data[3] = wb_trans.data;

    //Write to FSMR register which is read only
    wb_run(FSMR, 8'h10100000, 0);

    // Read the register values again
    wb_run(CSR, 8'bxxxxxxxx, 1);
    post_transaction_data[0] = wb_trans.data;
    wb_run(DPR, 8'bxxxxxxxx, 1);
    post_transaction_data[1] = wb_trans.data;
    wb_run(CMDR, 8'bxxxxxxxx, 1);
    post_transaction_data[2] = wb_trans.data;
    wb_run(FSMR, 8'bxxxxxxxx, 1);
    post_transaction_data[3] = wb_trans.data;

    if(post_transaction_data[0] == 8'b11000000 &&
         post_transaction_data[1] == 8'b00000000 &&
         post_transaction_data[2] == 8'b10000000 &&
         post_transaction_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("END TEST");
  endtask

  // ****************************************************************************
  task default_values();
    $display(
        "======================== Checking the default value of all registers =======================");
    wb_run(CSR, 8'bxxxxxxxx, 1);
    original_data[0] = wb_trans.data;
    wb_run(DPR, 8'bxxxxxxxx, 1);
    original_data[1] = wb_trans.data;
    wb_run(CMDR, 8'bxxxxxxxx, 1);
    original_data[2] = wb_trans.data;
    wb_run(FSMR, 8'bxxxxxxxx, 1);
    original_data[3] = wb_trans.data;

    if(original_data[0] == 8'b00000000 &&
         original_data[1] == 8'b00000000 &&
         original_data[2] == 8'b10000000 &&
         original_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("END TEST");
  endtask
  // ****************************************************************************
  task random_read();
    $display("======================== Random Read Test =======================");
    fork
      begin : i2c_flow
        i2c_read_data = new[64];
        for (int i = 0; i < 64; i++) begin
          i2c_read_data[i] = $urandom_range(0, 127);
        end
        i2c_read(i2c_read_data);
      end : i2c_flow

      begin : wb_flow
        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h05, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();


        read_operation();
        // Read 64 incrementing values
        for (int i = 0; i < 64; i++) begin
          if (i < 64) wb_run(CMDR, 8'bxxxxx010, 0);  //ack read
          else wb_run(CMDR, 8'bxxxxx011, 0);  //nack read
          wait_for_interrupt();
          wb_run(DPR, wb_read_data, 1);
        end

        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();
      end : wb_flow
    join
  endtask

  // ****************************************************************************
  task random_write();
    $display("======================== Random Write Test =======================");
    fork
      begin : i2c_flow
        i2c_write();
      end : i2c_flow

      begin : wb_flow
        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h05, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();

        write_operation();
        // Write 64 random alues
        for (int i = 0; i < 64; i++) begin
          wb_rand_trans = new;
          wb_rand_trans.address = DPR;
          success = wb_rand_trans.randomize();
          wb_ag.bl_put(wb_rand_trans);

          wb_run(CMDR, 8'bxxxxx001, 0);
          wait_for_interrupt();
        end
        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();

      end : wb_flow

    join
  endtask

  // ****************************************************************************

  task random_alternate();
    $display(
        "======================== Random Alternate Write and Read Test =======================");
    fork
      begin : wb_flow
        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h05, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();

        for (int i = 0; i < 64; i++) begin
          write_operation();
          // Write data
          wb_rand_trans = new;
          wb_rand_trans.address = DPR;
          success = wb_rand_trans.randomize();
          wb_ag.bl_put(wb_rand_trans);
          wb_run(CMDR, 8'bxxxxx001, 0);
          wait_for_interrupt();
          // Stop command
          wb_run(CMDR, 8'bxxxxx101, 0);
          wait_for_interrupt();

          read_operation();

          // Read with nack
          wb_run(CMDR, 8'bxxxxx011, 0);
          wait_for_interrupt();
          wb_run(DPR, wb_read_data, 1);
          // Stop command
          wb_run(CMDR, 8'bxxxxx101, 0);
          wait_for_interrupt();
        end

      end : wb_flow

      //i2c flow

      begin : i2c_flow
        int iter_j = 0;
        repeat (128) begin
          i2c_write();
          i2c_read_data = new[1];
          i2c_read_data[0] = $urandom_range(0, 64);
          i2c_read(i2c_read_data);
          if (iter_j == 63) break;
          iter_j++;
        end
      end : i2c_flow
    join
  endtask

  // ****************************************************************************
  task fsm_transition();
    $display("======================== FSM Transition Test =======================");

    fork
      begin
        $display("--------Fsm state testing of repeated start condition-------- \n");
        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h05, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();

        // Repeated start command
        wb_run(CMDR, 8'bxxxxx100, 0);
        wb_run(CMDR, 8'bxxxxx100, 0);

        wait_for_interrupt();

        // Slave address with write operation
        wb_run(DPR, 8'h44, 0);  ///
        wb_run(CMDR, 8'bxxxxx001, 0);
        wait_for_interrupt();

        // Write 32 incrementing values
        for (int i = 0; i < 32; i++) begin
          wb_run(DPR, i, 0);
          wb_run(CMDR, 8'bxxxxx001, 0);
          wait_for_interrupt();
        end

        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();
      end

      begin
        // Write 32 values to i2c slave and test repeated start
        i2c_write();
      end
    join


    fork
      begin
        //Enable core and interrupt
        wb_run(CSR, 8'b11xxxxxx, 0);
        // I2C Bus ID #5
        wb_run(DPR, 8'h05, 0);
        // Set Bus command
        wb_run(CMDR, 8'bxxxxx110, 0);
        wait_for_interrupt();

        $display("--------FSM state testing to read with ack instead of nack---------\n");
        read_operation();
        // Read 32 incrementing values
        for (int i = 0; i < 32; i++) begin
          wb_run(CMDR, 8'bxxxxx010, 0);
          wait_for_interrupt();
          wb_run(DPR, wb_read_data, 1);
        end
        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();
      end

      begin
        i2c_read_data = new[32];
        for (int i = 0; i < 32; i++) begin
          i2c_read_data[i] = i + 100;
        end
        i2c_read(i2c_read_data);
      end
    join

    fork
      $display("-------Fsm state testing - Checking start ---> address ---> stop------------ \n");

      //Enable core and interrupt
      begin
        wb_run(CMDR, 8'bxxxxx100, 0);
        wait_for_interrupt();
        // Slave address with write operation
        wb_run(DPR, 8'h44, 0);
        wb_run(CMDR, 8'bxxxxx001, 0);
        wait_for_interrupt();

        // Stop command
        wb_run(CMDR, 8'bxxxxx101, 0);
        wait_for_interrupt();
      end

      begin
        i2c_write();
      end
    join
  endtask

endclass


