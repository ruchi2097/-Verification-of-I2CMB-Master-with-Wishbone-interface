package ncsu_pkg;

  `include "ncsu_macros.svh"

  `include "src/ncsu_pkg_version.svh"
  `include "src/ncsu_typedefs.svh"
  `include "src/ncsu_void.svh"
  `include "src/ncsu_object.svh"
  `include "src/ncsu_config_db.svh"
  `include "src/ncsu_configuration.svh"
  `include "src/ncsu_transaction.svh"
  `include "src/ncsu_component_base.svh"
  `include "src/ncsu_component.svh"
  `include "src/ncsu_object_wrapper.svh"
  `include "src/ncsu_object_factory.svh"
  `include "src/ncsu_object_registry.svh"

  parameter int WB_ADDR_WIDTH = 2;
  parameter int WB_DATA_WIDTH = 8;
  parameter int I2C_ADDR_WIDTH = 7;
  parameter int I2C_DATA_WIDTH = 8;
  parameter int NUM_I2C_BUSSES = 1;

endpackage
