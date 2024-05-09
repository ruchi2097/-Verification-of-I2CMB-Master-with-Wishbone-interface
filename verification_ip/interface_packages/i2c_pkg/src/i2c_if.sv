
   parameter int WB_ADDR_WIDTH = 2;
   parameter int WB_DATA_WIDTH = 8;
   parameter int NUM_I2C_BUSSES = 1;
   parameter int I2C_ADDR_WIDTH = 7;
   parameter int I2C_DATA_WIDTH = 8;

import operation::*;

interface i2c_if #(
    int I2C_ADDR_WIDTH = 7,
    int I2C_DATA_WIDTH = 8
) (
    inout tri scl,
    input triand sda_i,
    output bit sda_o
);

  i2c_cntrl_t control;
  bit drive_bus;
  bit drive_data;

  assign sda_o = drive_bus ? drive_data : sda_i;
  bit repeated_start = 0;
  task stop_condition();
    //$display("Entered stop condition \n");
    forever
      @(posedge sda_i)
        if (scl) begin
          control   = STOP;
          drive_bus = 0;
          break;
        end
    //$display("Completed stop condition \n");
  endtask

  task start_condition();
    //$display("Entered start condition \n");
    forever
      @(negedge sda_i) begin
        if (scl) begin
          //$display("start condition passed \n");
          control = START;
          break;
        end
      end
    //$display("Completed start condition \n");
  endtask


  task get_address(output bit [I2C_ADDR_WIDTH-1:0] addr);
    for (int ad = I2C_ADDR_WIDTH - 1; ad >= 0; ad--) begin
      @(posedge scl) addr[ad] = sda_i;
    end
  endtask

  task write_data_fn(output bit [I2C_DATA_WIDTH-1:0] data[]);

    bit [I2C_DATA_WIDTH-1:0] write_data_temp;
    //$display("entered write data function");
    data = new[data.size() + 1] (data);
    for (int i = 0; i < I2C_DATA_WIDTH; i++) begin
      @(posedge scl) drive_bus = 0;
      write_data_temp[I2C_DATA_WIDTH-1-i] = sda_i;
    end

    data[data.size()-1] = write_data_temp;
    //$display("-------Data written on i2c= %d ------\n",write_data_temp);
  endtask

  task get_write_read_bit(output bit r_w);
    @(posedge scl) r_w = sda_i;
  endtask



  task send_ack();
    @(posedge scl) drive_bus = 1;
    drive_data = 1'b0;
  endtask


  task get_ack(output bit ack);
    @(posedge scl) drive_bus = 0;
    ack = sda_i;
  endtask

  task wait_for_i2c_transfer(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data[]);

    bit [I2C_ADDR_WIDTH-1:0] addr;
    bit r_w;
    bit ack;
    //capture the start condition	
    control = IDLE;

    if (control != START && !repeated_start) begin
      start_condition();
      //$display("i2c slave start detected");
    end else if (repeated_start) begin
      write_data.delete();
    end

    repeated_start = 0;
    //capture the address and find mode
    get_address(addr);

    // capture read/write bit
    get_write_read_bit(r_w);

    // send acknowledge
    send_ack();
    if (r_w == WRITE) begin
      op = WRITE;
      fork
        forever begin
          stop_condition();
          if (control == STOP) begin
            control = STOP;
            //$display("----WAIT I2C TASK STOP----");
            write_data.delete();
            break;
          end
        end

        forever begin
          start_condition();
          if (control == START) begin
            repeated_start = 1;
            break;
          end
        end

        forever begin
          write_data_fn(write_data);
          send_ack();
          control = ACTION;
        end
      join_any

      disable fork;

    end else begin
      op = READ;  // set read mode;
      control = ACTION;
    end

  endtask


  task read_data_fn(input bit [I2C_DATA_WIDTH-1:0] data);
    foreach (data[j]) begin
      @(posedge scl) drive_bus = 1;
      drive_data = data[j];
    end
    //$display("-------read_data-------=%d",data);
  endtask


  task provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data[],
                         output bit transfer_complete);
    bit ack;
    control = START;
    repeated_start = 0;
    //$display("Read data provide size is %0d", read_data.size());

    for (int i = 0; i < read_data.size(); i++) begin

      read_data_fn(read_data[i]);
      get_ack(ack);

      if (ack == 1'b0) begin
        transfer_complete = 0;
        continue;
      end else if (ack == 1'b1) begin
        fork
          forever begin
            stop_condition();
            if (control == STOP) begin
              transfer_complete = 1;
              //$display("I2C slave read stop detected \n");
              break;
            end
          end

          forever begin
            start_condition();
            if (control == START) begin
              transfer_complete = 1;
              repeated_start = 1;
              //$display("I2C slave repeated start detected \n");
              break;
            end
          end
        join_any
        disable fork;
      end
      if (transfer_complete) break;

    end
  endtask


  task monitor(output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op,
               output bit [I2C_DATA_WIDTH-1:0] data[]);
    //bit reading if it is read or write	
    bit [I2C_DATA_WIDTH-1:0] write_data;
    bit monitor_rw;
    data.delete();
    control = IDLE;

    if (control != START && !repeated_start) begin
      start_condition();
      //$display("i2c slave start detected");
    end

    get_address(addr);
    get_write_read_bit(monitor_rw);
    send_ack();
    if (monitor_rw == READ) begin
      @(negedge scl) op = READ;
    end else if (monitor_rw == WRITE) begin
      @(negedge scl) op = WRITE;

    end

    fork
      forever begin
        stop_condition();
        if (control == STOP) begin
          control = STOP;
          //$display("----WAIT I2C TASK STOP----");
          break;
        end
      end

      forever begin
        start_condition();
        if (control == START) begin
          repeated_start = 1;
          break;
        end
      end


      forever begin
        forever begin
          for (int i = I2C_DATA_WIDTH - 1; i >= 0; i--) begin
            @(negedge scl) write_data[i] = sda_o;
          end
          data = new[data.size() + 1] (data);
          data[data.size()-1] = write_data;
          @(negedge scl);
        end
      end
    join_any
    disable fork;
  endtask

endinterface
