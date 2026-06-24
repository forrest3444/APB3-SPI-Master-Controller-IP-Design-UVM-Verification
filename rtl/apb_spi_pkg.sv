package apb_spi_pkg;

    localparam logic [11:0] REG_CTRL_ADDR       = 12'h000;
    localparam logic [11:0] REG_STATUS_ADDR     = 12'h004;
    localparam logic [11:0] REG_CLKDIV_ADDR     = 12'h008;
    localparam logic [11:0] REG_TXDATA_ADDR     = 12'h00c;
    localparam logic [11:0] REG_RXDATA_ADDR     = 12'h010;
    localparam logic [11:0] REG_IRQ_EN_ADDR     = 12'h014;
    localparam logic [11:0] REG_IRQ_RAW_ADDR    = 12'h018;
    localparam logic [11:0] REG_IRQ_STATUS_ADDR = 12'h01c;
    localparam logic [11:0] REG_IRQ_CLEAR_ADDR  = 12'h020;
    localparam logic [11:0] REG_TXFIFO_LVL_ADDR = 12'h024;
    localparam logic [11:0] REG_RXFIFO_LVL_ADDR = 12'h028;
    localparam logic [11:0] REG_VERSION_ADDR    = 12'h02c;

    localparam int unsigned CTRL_ENABLE_BIT     = 0;
    localparam int unsigned CTRL_START_BIT      = 1;
    localparam int unsigned CTRL_CPHA_BIT       = 2;
    localparam int unsigned CTRL_CPOL_BIT       = 3;
    localparam int unsigned CTRL_CONT_BIT       = 4;
    localparam int unsigned CTRL_RX_EN_BIT      = 5;
    localparam int unsigned CTRL_TX_EN_BIT      = 6;
    localparam int unsigned CTRL_SOFT_RESET_BIT = 7;

    localparam int unsigned STATUS_BUSY_BIT                 = 0;
    localparam int unsigned STATUS_TX_EMPTY_BIT             = 1;
    localparam int unsigned STATUS_TX_FULL_BIT              = 2;
    localparam int unsigned STATUS_RX_EMPTY_BIT             = 3;
    localparam int unsigned STATUS_RX_FULL_BIT              = 4;
    localparam int unsigned STATUS_CS_ACTIVE_BIT            = 5;
    localparam int unsigned STATUS_DONE_PENDING_BIT         = 6;
    localparam int unsigned STATUS_TX_UNDERFLOW_PENDING_BIT = 7;
    localparam int unsigned STATUS_RX_OVERFLOW_PENDING_BIT  = 8;

    localparam int unsigned IRQ_DONE_BIT         = 0;
    localparam int unsigned IRQ_TX_EMPTY_BIT     = 1;
    localparam int unsigned IRQ_RX_NOT_EMPTY_BIT = 2;
    localparam int unsigned IRQ_TX_UNDERFLOW_BIT = 3;
    localparam int unsigned IRQ_RX_OVERFLOW_BIT  = 4;

    localparam logic [31:0] CTRL_RESET_VALUE    = 32'h0000_0060;
    localparam logic [7:0]  CLKDIV_RESET_VALUE  = 8'h01;
    localparam logic [15:0] VERSION_MAJOR       = 16'h0001;
    localparam logic [15:0] VERSION_MINOR       = 16'h0000;
    localparam logic [31:0] VERSION_RESET_VALUE = {VERSION_MAJOR, VERSION_MINOR};

    typedef enum logic [1:0] {
        SPI_ST_IDLE       = 2'b00,
        SPI_ST_LOAD       = 2'b01,
        SPI_ST_SHIFT      = 2'b10,
        SPI_ST_FRAME_DONE = 2'b11
    } spi_state_e;

endpackage
