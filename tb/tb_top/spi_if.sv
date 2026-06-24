interface spi_if;

    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    modport dut (
        output spi_sclk,
        output spi_mosi,
        input  spi_miso,
        output spi_cs_n
    );

endinterface
