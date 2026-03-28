class spi_driver extends uvm_driver #(spi_frame);
    `uvm_component_utils(spi_driver)

    spi_agent_cfg cfg;

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "spi_agent_cfg not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        spi_frame req;

        cfg.vif.spi_miso = 1'b0;
        forever begin
            seq_item_port.get_next_item(req);
            drive_frame(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_frame(spi_frame req);
        bit [7:0] shift_reg;
        int       sample_count;
        int       drive_count;
        bit       prev_sclk;
        bit       curr_sclk;
        bit       leading_edge;
        bit       trailing_edge;

        shift_reg = req.rx_byte;
        wait (cfg.vif.spi_cs_n === 1'b0);

        if (!req.cpha) begin
            cfg.vif.spi_miso = shift_reg[7];
            shift_reg        = {shift_reg[6:0], 1'b0};
            drive_count      = 1;
        end else begin
            cfg.vif.spi_miso = 1'b0;
            drive_count      = 0;
        end

        sample_count = 0;
        prev_sclk    = cfg.vif.spi_sclk;

        while ((cfg.vif.spi_cs_n === 1'b0) && (sample_count < 8)) begin
            @(cfg.vif.spi_sclk or cfg.vif.spi_cs_n);
            if (cfg.vif.spi_cs_n !== 1'b0) begin
                break;
            end

            curr_sclk     = cfg.vif.spi_sclk;
            leading_edge  = (prev_sclk == req.cpol) && (curr_sclk != req.cpol);
            trailing_edge = (prev_sclk != req.cpol) && (curr_sclk == req.cpol);

            if (!req.cpha) begin
                if (leading_edge) begin
                    sample_count++;
                end

                if (trailing_edge && (drive_count < 8)) begin
                    cfg.vif.spi_miso = shift_reg[7];
                    shift_reg        = {shift_reg[6:0], 1'b0};
                    drive_count++;
                end
            end else begin
                if (leading_edge && (drive_count < 8)) begin
                    cfg.vif.spi_miso = shift_reg[7];
                    shift_reg        = {shift_reg[6:0], 1'b0};
                    drive_count++;
                end

                if (trailing_edge) begin
                    sample_count++;
                end
            end

            prev_sclk = curr_sclk;
        end

        wait (cfg.vif.spi_cs_n === 1'b1);
        cfg.vif.spi_miso = 1'b0;
    endtask
endclass
