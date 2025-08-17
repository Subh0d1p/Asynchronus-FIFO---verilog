`timescale 1ps/1ps

module fifotestbench;
    reg wreq, wclk, wrst_n, rreq, rclk, rrst_n;
    reg [7:0] wdata;
    wire [7:0] rdata;
    wire wfull, rempty;
    
    async_fifo f1 (
        .wreq(wreq),
        .wclk(wclk),
        .wrst_n(wrst_n),
        .rreq(rreq),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .wdata(wdata),
        .rdata(rdata),
        .wfull(wfull),
        .rempty(rempty)
    );

    initial wclk = 1'b0;
    always #10 wclk = ~wclk;

    initial rclk = 1'b0;
    always #50 rclk = ~rclk;

    initial begin
        initialize();
        reset();
        write_sequence();
        #200 $finish;
    end

    task initialize;
        begin
            wreq = 0;
            rreq = 0;
            wdata = 0;
            wrst_n = 1;
            rrst_n = 1;
        end
    endtask

    task reset;
        begin
            #5 wrst_n = 0;
            rrst_n = 0;
            #15 wrst_n = 1;
            rrst_n = 1;
        end
    endtask

    task write_sequence;
        begin
            wreq = 1;
            rreq = 1;
            wdata = 8'd4;
            #10 wdata = 8'd15;
            #10 wdata = 8'd19;
            #10 wdata = 8'd107;
            #10 wdata = 8'd5;
            #10 wdata = 8'd8;
            #10 wdata = 8'd50;
            #10 wdata = 8'd500;
            #10 wdata = 8'd67;
            #10 wdata = 8'd500;
            #10 wdata = 8'd600;
            #10 wdata = 8'd700;
            #10 wdata = 8'd800;
            #10 wdata = 8'd900;
            #10 wdata = 8'd1000;
        end
    endtask

    initial begin
        $monitor("Time=%0t: wdata=%d rdata=%d wfull=%b rempty=%b", 
                 $time, wdata, rdata, wfull, rempty);
    end
endmodule
