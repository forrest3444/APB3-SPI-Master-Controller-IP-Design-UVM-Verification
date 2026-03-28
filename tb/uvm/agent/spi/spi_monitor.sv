class spi_monitor extends uvm_component;
    `uvm_component_utils(spi_monitor)

    spi_agent_cfg                  cfg;
    uvm_analysis_port #(spi_frame) ap;
    int unsigned                   frame_count;
    int unsigned                   window_count;

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "spi_agent_cfg not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        spi_frame tr;
        bit [7:0] tx_shift;
        bit [7:0] rx_shift;
        int       bit_count;
        bit       prev_sclk;
        bit       curr_sclk;
        bit       leading_edge;
        bit       trailing_edge;
        bit       sample_edge;

        forever begin
            @(negedge cfg.vif.spi_cs_n);
            window_count++;
            bit_count = 0;
            tx_shift  = '0;
            rx_shift  = '0;
            prev_sclk = cfg.vif.spi_sclk;

            while (cfg.vif.spi_cs_n === 1'b0) begin
                @(cfg.vif.spi_sclk or cfg.vif.spi_cs_n);
                if (cfg.vif.spi_cs_n !== 1'b0) begin
                    break;
                end

                curr_sclk     = cfg.vif.spi_sclk;
                leading_edge  = (prev_sclk == cfg.default_cpol) && (curr_sclk != cfg.default_cpol);
                trailing_edge = (prev_sclk != cfg.default_cpol) && (curr_sclk == cfg.default_cpol);
                sample_edge   = cfg.default_cpha ? trailing_edge : leading_edge;

                if (sample_edge) begin
                    tx_shift = {tx_shift[6:0], cfg.vif.spi_mosi};
                    rx_shift = {rx_shift[6:0], cfg.vif.spi_miso};
                    bit_count++;

                    if (bit_count == 8) begin
                        tr = spi_frame::type_id::create("tr");
                        tr.cpol         = cfg.default_cpol;
                        tr.cpha         = cfg.default_cpha;
                        tr.cont         = (cfg.vif.spi_cs_n === 1'b0);
                        tr.tx_en        = 1'b1;
                        tr.rx_en        = 1'b1;
                        tr.tx_byte      = tx_shift;
                        tr.rx_byte      = rx_shift;
                        tr.frame_idx    = frame_count;
                        tr.cs_window_id = window_count;
                        ap.write(tr);
                        frame_count++;
                        bit_count = 0;
                        tx_shift  = '0;
                        rx_shift  = '0;
                    end
                end

                prev_sclk = curr_sclk;
            end
        end
    endtask
endclass
