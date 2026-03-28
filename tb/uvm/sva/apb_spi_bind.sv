`ifdef ASSERT_ON
bind apb_spi_master_top apb_protocol_sva u_apb_protocol_sva (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR)
);

bind apb_spi_master_top spi_protocol_sva u_spi_protocol_sva (
    .PCLK             (PCLK),
    .PRESETn          (PRESETn),
    .spi_sclk         (spi_sclk),
    .spi_cs_n         (spi_cs_n),
    .cfg_cpol         (cfg_cpol),
    .status_busy      (status_busy),
    .status_cs_active (status_cs_active)
);
`endif
