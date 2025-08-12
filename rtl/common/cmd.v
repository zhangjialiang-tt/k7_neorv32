module cmd (
    //global input interface
    input  wire [1       - 1 : 0] i_Sys_clk,
    input  wire [1       - 1 : 0] i_Rst_n,
    input  wire [1       - 1 : 0] i_External_sync,
    input  wire [1       - 1 : 0] i_Cmd_1,
    input  wire [1       - 1 : 0] i_Cmd_2,
    output reg   [12      - 1 : 0] o_Cmd_scaler
);  //cmd
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    reg [1   - 1 : 0] cmd_1_d1;
    reg [1   - 1 : 0] cmd_1_d2;
    reg [1   - 1 : 0] external_sync_d1;
    reg [1   - 1 : 0] external_sync_d2;
    wire [1   - 1 : 0] external_sync_neg;
    reg [1   - 1 : 0] cmd_2_d1;
    reg [1   - 1 : 0] cmd_2_d2;

    wire [1   - 1 : 0] cmd_up;
    wire [1   - 1 : 0] cmd_down;
    reg [12   - 1 : 0] cmd_scaler;
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n)    begin
            cmd_1_d1 <= 'd0;
            cmd_1_d2 <= 'd0;
            cmd_2_d1 <= 'd0;
            cmd_2_d2 <= 'd0;
        end else begin
            cmd_1_d1 <= i_Cmd_1;
            cmd_1_d2 <= cmd_1_d1;
            cmd_2_d1 <= i_Cmd_2;
            cmd_2_d2 <= cmd_2_d1;
        end
    end
    assign cmd_up = ~cmd_1_d2 && cmd_1_d1;
    assign cmd_down = ~cmd_2_d2 && cmd_2_d1;
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) begin
            cmd_scaler <= 'd110;
        end else if(cmd_up)begin
            if(cmd_scaler<110)          cmd_scaler <= 'd110;
            else if(cmd_scaler>400)     cmd_scaler <= 'd400;
            else                        cmd_scaler <= cmd_scaler + 'd10;
        end else if(cmd_down)begin
            if(cmd_scaler<110)          cmd_scaler <= 'd110;
            else if(cmd_scaler>400)     cmd_scaler <= 'd400;
            else                        cmd_scaler <= cmd_scaler - 'd10;
        end
    end

    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n)    begin
            external_sync_d1 <= 'd0;
            external_sync_d2 <= 'd0;
        end else begin
            external_sync_d1 <= i_External_sync;
            external_sync_d2 <= external_sync_d1;
        end
    end
    assign external_sync_neg = ~external_sync_d2 && external_sync_d1;

    //**********************************************************************************************
    // module1
    //**********************************************************************************************

    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n)                o_Cmd_scaler <= 'd110;
        else if(external_sync_neg)  o_Cmd_scaler <= cmd_scaler;
    end
    // assign o_Cmd_scaler = cmd_scaler;
endmodule
