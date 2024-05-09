//Packages are library used in different files.

package operation;
    typedef enum bit {WRITE = 1'b0, READ = 1'b1} i2c_op_t;
    typedef enum logic[2:0] {IDLE ,START, STOP, ACTION} i2c_cntrl_t;


endpackage 
