`timescale 1ns / 10ps
import operation::*;

module top();

parameter int WB_ADDR_WIDTH  = 2;
parameter int WB_DATA_WIDTH  = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri    [NUM_I2C_BUSSES-1:0] scl;
triand [NUM_I2C_BUSSES-1:0] sda;
wire [NUM_I2C_BUSSES-1:0] sda_i;
wire [NUM_I2C_BUSSES-1:0] sda_o;

assign sda_o=sda;

bit alt_flag = 0;
typedef enum bit {
  WRITE = 0,
  READ  = 1
} i2c_op_t;

typedef enum bit [1:0] {
  CSR  = 0,
  DPR  = 1,
  CMDR = 2,
  FSMR = 3
} register_type;

// ****************************************************************************
// Clock generator
initial begin : clk_gen
  clk = 0;
  forever
    #5 clk = ~clk;
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
  #113 rst = 0;
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
  bit [WB_ADDR_WIDTH-1:0] wb_addr;
  bit [WB_DATA_WIDTH-1:0] wb_data;
  bit wb_we;

  #113
  forever begin
    wb_bus.master_monitor(wb_addr, wb_data, wb_we);
    $display("WB_monitoring: addr %d data %d we %d", wb_addr, wb_data, wb_we);
  end
end

// ****************************************************************************
// Wait for interrupt
task wait_for_interrupt();
  logic [WB_DATA_WIDTH-1:0] data_irq;
  wait(irq);
  wb_bus.master_read(CMDR, data_irq);
endtask

// ****************************************************************************
task write_operation();

  // Start command
  wb_bus.master_write(CMDR, 8'bxxxxx100);
  wait_for_interrupt();
  // Slave address with write operation
  wb_bus.master_write(DPR, {7'h22,1'b0});
  wb_bus.master_write(CMDR, 8'bxxxxx001);
  wait_for_interrupt();

endtask


// ****************************************************************************
task read_operation();
  // Start command
  wb_bus.master_write(CMDR, 8'bxxxxx100);
  wait_for_interrupt();

  // Slave address with read operation
  wb_bus.master_write(DPR, {7'h22,1'b1});
  wb_bus.master_write(CMDR, 8'bxxxxx001);
  wait_for_interrupt();

endtask
// ****************************************************************************
// Define the flow of the simulation
initial begin : test_flow
  bit [I2C_DATA_WIDTH-1:0] read_data;
  #113
  repeat(3) @(posedge clk);

  //Enable core and interrupt
  wb_bus.master_write(CSR, 8'b11xxxxxx);
  // I2C Bus ID #5
  wb_bus.master_write(DPR, 8'h05);
  // Set Bus command
  wb_bus.master_write(CMDR, 8'bxxxxx110);
  wait_for_interrupt();

// ****************************************************************************
// Write 

//  $display("======================== Write 32 incrementing values to I2C =======================");
  write_operation();	
  // Write 32 incrementing values
  for(int i=0; i<32; i++) begin
    wb_bus.master_write(DPR, i);
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    wait_for_interrupt();
  end

  // Stop command
  wb_bus.master_write(CMDR, 8'bxxxxx101);
  wait_for_interrupt();

// ****************************************************************************
// Read 

 // $display("\n======================== Read 32 incrementing reads from I2C =======================");
	
 read_operation();
  // Read 32 incrementing values
  for(int i=0; i<32; i++) begin
  if (i<31)
    wb_bus.master_write(CMDR, 8'bxxxxx010);   //ack read
  else
    wb_bus.master_write(CMDR, 8'bxxxxx011); //nack read

    wait_for_interrupt();
    wb_bus.master_read(DPR, read_data);
  end

  // Stop command
  wb_bus.master_write(CMDR, 8'bxxxxx101);
  wait_for_interrupt();

// ****************************************************************************
// Alternate writes and reads 
  // Alternate read 63-0/write 64-127 
 // $display("========== Starting 64 alternate incrementing write and decrementing reads =========");
  for(int i=0; i<64; i++) begin
    alt_flag = 1;
 	
    write_operation(); 
    // Write data
    wb_bus.master_write(DPR, i+64);
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    wait_for_interrupt();
  
   read_operation();
	 
    // Read with nack
    wb_bus.master_write(CMDR, 8'bxxxxx011);
    wait_for_interrupt();
    wb_bus.master_read(DPR, read_data);
    alt_flag = 0;
  end
    
    // Stop command
    wb_bus.master_write(CMDR, 8'bxxxxx101);
    wait_for_interrupt();

  $finish;
end

// ****************************************************************************
// I2C operations 
initial begin 
  bit [I2C_DATA_WIDTH-1:0] alt_read_data;
  alt_read_data = 63;
  #113
  fork begin
    forever begin
      bit i2c_op;
      bit [I2C_DATA_WIDTH-1:0] write_data[];
      bit [I2C_DATA_WIDTH-1:0] read_data[];
      bit transfer_complete;

      i2c_bus.wait_for_i2c_transfer(i2c_op, write_data);
      if (i2c_op == READ) begin
        read_data = new[1];
	
	      read_data[0]=alt_flag?alt_read_data:100;

        do begin
          i2c_bus.provide_read_data(read_data, transfer_complete);
          if (!alt_flag)
            read_data[0] += 1;
	  else
            alt_read_data -= 1;
        end while (!transfer_complete);
      end
    end
  end
  join_none
end


// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the I2C Slave Bus Functional Model
i2c_if       #(
  .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
  .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
  )
i2c_bus (
  .scl(scl[0]),
  .sda_i(sda_o[0]),
  .sda_o(sda_i[0])	
  );

// ****************************************************************************
// I2C monitor
initial begin : monitor_i2c_bus
  bit op;
  bit [I2C_ADDR_WIDTH-1:0] addr;
  bit [I2C_DATA_WIDTH-1:0] data[];
  #113
  forever begin
    i2c_bus.monitor(addr, op, data);
    $display("I2C_BUS   %04s transfer with Addr: %h
	    Data: %p\n", i2c_op_t'(op), addr, data);
  end
end 	

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         // out   std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    // out   std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           // out   std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda_i),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         // out   std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          // out   std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

endmodule

