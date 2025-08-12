
//Dual port RAM
module ramDualPort #(
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 8
)(
	input wire [(DATA_WIDTH-1):0] dataA, dataB,
	input wire [(ADDRESS_WIDTH-1):0] addrA, addrB,
	input wire weA, weB, clk,
	output wire [(DATA_WIDTH-1):0] qA, qB
);

	wire [(DATA_WIDTH-1):0] qA_temp;
	lpm_dual_clk_port_ram #(
		.DATA_WIDTH( DATA_WIDTH ),
		// .ADDR_DEPTH( DATA_WIDTH ),
		.ADDR_WIDTH( ADDRESS_WIDTH )
	) inst_dual_port_ram_scaler(
        .clock_a       ( clk			),
        .enable_a      ( 1'b1        	),
        .address_a     ( addrA 			),
        .wren_a        ( weA			),
        .data_a        ( dataA			),
        .rden_a        ( ~weA			),
        .q_a           ( qA_temp 		),
        
		
		.clock_b       ( clk			),
        .enable_b      ( 1'b1       	),
        .address_b     ( addrB			),
        .wren_b        ( 1'b0			),
        .data_b        ( {DATA_WIDTH{1'd0}}			),//DATA_WIDTH
        .rden_b        ( 1'b1			),
        .q_b           ( qB				)
    );
assign qA = weA ? dataA : qA_temp;

	// Declare the RAM variable
	// reg [DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];

	// always @ (posedge clk)
	// begin
	// //Port A
	// 	if (weA) 
	// 	begin
	// 		ram[addrA] <= dataA;
	// 		qA <= dataA;
	// 	end
	// 	else 
	// 	begin
	// 		qA <= ram[addrA];
	// 	end 

	// //Port B
	// 	if (weB) 
	// 	begin
	// 		ram[addrB] <= dataB;
	// 		qB <= dataB;
	// 	end
	// 	else 
	// 	begin
	// 		qB <= ram[addrB];
	// 	end 
	// end 

	//Port B
	// always @ (posedge clk)
	// begin
	// end

endmodule //ramDualPort
