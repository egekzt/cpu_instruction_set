`timescale 1ns/1ps


//[Common 17-345] A valid license was not found for feature 'Synthesis' and/or device 'xc7vx485t'. Please run the Vivado License Manager for assistance in determining
//which features and devices are licensed for your system.
//Resolution: Check the status of your licenses in the Vivado License Manager. For debug help search Xilinx Support for "Licensing FAQ". 
//Hocam yukaridaki hata sebebiyle synthesis alamiyorum

`define BELLEK_ADRES    32'h8000_0000
`define VERI_BIT        32
`define ADRES_BIT       32
`define YAZMAC_SAYISI   32

module islemci (
    input                       clk,
    input                       rst,
    output  [`ADRES_BIT-1:0]    bellek_adres,
    input   [`VERI_BIT-1:0]     bellek_oku_veri,
    output  [`VERI_BIT-1:0]     bellek_yaz_veri,
    output                      bellek_yaz
);

localparam GETIR        = 2'd0;
localparam COZYAZMACOKU = 2'd1;
localparam YURUTGERIYAZ = 2'd2;

localparam LUI = 3'd0;
localparam AUIPC = 3'd1;
localparam JAL = 3'd2;
localparam JALR = 3'd3;
localparam BEQ = 3'd4;
localparam LW = 3'd5;
localparam SW = 3'd6;
localparam ADDI = 3'd7;
localparam ADD = 3'd8;
localparam SUB = 3'd9;
localparam OR = 3'd10;
localparam AND = 3'd11;
localparam XOR = 3'd12;

reg [1:0] simdiki_asama_r;
reg [1:0] simdiki_asama_ns;
reg ilerle_cmb;
reg immediate[31:0];
reg op[2:0];
reg rs2[4:0];
reg rs1[4:0];
reg rd[4:0];
wire [`VERI_BIT-1:0] yazmac_obegi [0:`YAZMAC_SAYISI-1];
reg [`ADRES_BIT-1:0] ps_r;

always @ * begin
    ilerle_cmb = 0;
    simdiki_asama_ns = simdiki_asama_r;
end

always @(posedge clk) begin
    
    if (rst) begin
        ps_r <= `BELLEK_ADRES;
        simdiki_asama_r <= GETIR;
    end
    else begin
        if (ilerle_cmb) begin
            simdiki_asama_r <= simdiki_asama_ns;
            
        end
        if(simdiki_asama_r == GETIR) begin
            reg buyruk[31:0] = yazmac_obegi[ps_r];
            ilerle_cmb <= 1;
            simdiki_asama_ns <= COZYAZMACOKU;
            bellek_yaz=0;
            
        end
        if(simdiki_asama_r == COZYAZMACOKU) begin
            ilerle_cmb <= 1;
            simdiki_asama_ns <= YURUTGERIYAZ;
            if(buyruk[6] == 1) begin 
                if(buyruk[3] == 1) begin //JAL
                    reg[31:0] extended_data = $signed({buyruk[20], buyruk[10:1], buyruk[11], buyruk[19:12],0});
                    rd <= buyruk[11:7];
                    immediate <= extended_data;
                    op <= 3'd2;
                    
                end
                else begin
                    if(buyruk[2] == 1)begin //JALR
                        reg [31:0] extended_data = $signed(buyruk[31:20]);
                        rd <= buyruk[11:7];
                        rs1 <= buyruk[19:15];
                        immediate <= extended_data;
                        op <= 3'd3;
                    end
                    else begin
                        if(buyruk[1] == 1)begin //BEQ
                            reg[31:0] extended_data = $signed({buyruk[31],buyruk[7],buyruk[30:25],buyruk[11:8]});
                            rs2 <= buyruk[24:20];
                            rs1 <= buyruk[19:15];
                            immediate <= extended_data;
                            op<= 3'd4;
                            
                        end
                    end
                end
            end
            else begin 
                if(buyruk[2] == 1) begin
                    if(buyruk[5] == 0) begin //AUIPC
                        rd <=buyruk[11:7];
                        immediate = { buyruk[31:12],12'd0 };
                        op <= 3'd1;
                    end
                    else begin //LUI
                        rd <=buyruk[11:7];
                        immediate = { buyruk[31:12],12'd0 };
                        op <= 3'd0;
                    end
                end
                else begin
                    if(buyruk[5] == 0) begin
                        if(buyruk[4] == 0)begin //LW
                            reg[31:0] extended_data = $signed(buyruk[31:20]);
                            rd <=buyruk[11:7];
                            rs1 <= buyruk[19:15];
                            immediate <= extended_data;
                            op <= 3'd5;
                        end
                        else begin //ADDI
                            rd <=buyruk[11:7];
                            rs1 <= buyruk[19:15];
                            op <= 3'd7;
                        end
                    end
                    else begin
                        if(buyruk[4] == 0)begin//SW
                            reg[31:0] extended_data = $signed({buyruk[31:25],buyruk[11:7]});
                            rs1 <= buyruk[19:15];
                            rs2 <= buyruk[24:20];
                            immediate <= extended_data;
                            op <= 3'd6;
                        end
                        else begin
                            if(buyruk[15:12] == 000) begin //ADD VE SUB
                                if(buyruk[30] == 1)begin//SUB
                                    rd <= buyruk[11:7];
                                    rs2 <= buyruk[24:20];
                                    rs1 <= buyruk[19:15];
                                    op <= 3'd9;
                                end
                                else begin//ADD
                                    rd <=buyruk[11:7];
                                    rs2 <= buyruk[24:20];
                                    rs1 <= buyruk[19:15];
                                    op <= 3'd8;
                                end
                            end 
                            else if(buyruk[15:12] == 110) begin //OR
                                rd <=buyruk[11:7];
                                rs2 <= buyruk[24:20];
                                rs1 <= buyruk[19:15];
                                op <= 3'd10;
                            end
                            else if(buyruk[15:12] == 111)begin//AND
                                rd <=buyruk[11:7];
                                rs2 <= buyruk[24:20];
                                rs1 <= buyruk[19:15];
                                op <= 3'd11;
                            end
                            else if(buyruk[15:12] == 100)begin//XOR
                                rd <=buyruk[11:7];
                                rs2 <= buyruk[24:20];
                                rs1 <= buyruk[19:15];
                                op <= 3'd12;
                            end
                        end
                    end    
                end
            end 
        end
        if(simdiki_asama_r == YURUTGERIYAZ) begin
            
            if(op == 3'd0)begin
                yazmac_obegi[rd] = immediate;
                ps_r = ps_r + 4;
                ilerle_cmb<= 1;
                simdiki_asama_ns <=GETIR;
                
            end
            if(op == 3'd1)begin
                yazmac_obegi[rd] = immediate;
                ps_r = ps_r + immediate;  
                ilerle_cmb <=1;
                simdiki_asama_ns <=GETIR;
                
            end
            if(op == 3'd2)begin
                yazmac_obegi[rd] = ps_r + 4;
                ps_r = ps_r + immediate;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
                
                
            end
            if(op == 3'd3)begin
                yazmac_obegi[rd] = ps_r + 4;
                ps_r = rs1 + immediate;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if(op == 3'd4)begin
                if(rd1 == rd2)begin
                    ps_r = ps_r + immediate;
                end
                else begin
                    ps_r = ps_r + 4;
                end
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if (op == 3'd5) begin 
                if (ilerle_cmb == 1) begin
                    reg [31:0] extended;
                    reg [31:0] mem_address;
                    extended = $signed({20'b0, buyruk[31:20]});
                    mem_address = yazmac_obegi[rs1] + extended;
            
                    
                    bellek_adres = mem_address;
                    ilerle_cmb <= 0;
                end
                else begin
                    
                    yazmac_obegi[rd] = bellek_oku_veri;
                    ilerle_cmb <= 1;
                    simdiki_asama_ns <= GETIR;
                end
            end
            
            if (op == 3'd6) begin 
                if (ilerle_cmb == 1) begin
                    reg [31:0] extended;
                    reg [31:0] mem_address;
                    extended = $signed({20'b0, buyruk[31:25], buyruk[11:7]});
                    mem_address = yazmac_obegi[rs1] + extended;
            
                    
                    bellek_adres = mem_address;
                    bellek_yaz_veri = yazmac_obegi[rs2];
                    bellek_yaz = 1'b1; 
                    ilerle_cmb <= 0;
                end
                else begin
                    
                    ilerle_cmb <= 1;
                    simdiki_asama_ns <= GETIR;
                end
            end

            if(op == 3'd7)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1] + immediate;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
                
            end
            if(op == 3'd8)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1]+yazmac_obegi[rs2];
                ps_r = ps_r + 4;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if(op == 3'd9)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1]-yazmac_obegi[rs2];
                ps_r = ps_r + 4;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if(op == 3'd10)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1] | yazmac_obegi[rs2];
                ps_r = ps_r + 4;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if(op == 3'd11)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1] & yazmac_obegi[rs2];
                ps_r = ps_r + 4;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end
            if(op == 3'd12)begin
                yazmac_obegi[rd] = yazmac_obegi[rs1]^yazmac_obegi[rs2];
                ps_r = ps_r + 4;
                ilerle_cmb<=1;
                simdiki_asama_ns<=GETIR;
            end            
            
        end
        
    end
end

assign bellek_adres = ps_r;
assign bellek_yaz_veri = 32'h0;
assign bellek_yaz = 1'b0;

endmodule