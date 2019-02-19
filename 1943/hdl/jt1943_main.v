/*  This file is part of JT_GNG.
    JT_GNG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT_GNG program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT_GNG.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 18-2-2019 */

// 1943: Main CPU

module jt1943_main(
    input              clk, 
    input              cen6,   // 6MHz
    input              cen3    /* synthesis direct_enable = 1 */,   // 3MHz
    input              rst,
    input              [7:0] char_dout,
    output             [7:0] cpu_dout,
    output  reg        char_cs,
    input              char_wait_n,
    input              scr_wait_n,
    output  reg        flip,
    input   [8:0]      V,
    input              LHBL,
    // Sound
    output  reg        sres_b, // sound reset
    output  reg        snd_int,
    output  reg        snd_latch_cs,
    output  reg        snd_latch1_cs,
    // scroll
    input   [7:0]      scr_dout,
    output  reg        scr_cs,
    output  reg [1:0]  scrpos_cs,
    output  reg [2:0]  scr_br,
    // cheat!
    input              cheat_invincible,
    // Object
    output  reg        obj_cs,
    // cabinet I/O
    input   [6:0]      joystick1,
    input   [6:0]      joystick2,
    input   [1:0]      start_button,
    input   [1:0]      coin_input,
    // BUS sharing
    output  [12:0]     cpu_AB,
    output             rd_n,
    output             wr_n,
    // ROM access
    output  reg [16:0] rom_addr,
    input       [ 7:0] rom_data,
    // DIP switches
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,
    output reg         coin_cnt,
    // PROM F1
    input    [7:0]     prog_addr,
    input              prom_k6_we,
    input    [3:0]     prog_din
);

wire [15:0] A;
wire [ 7:0] ram_dout;
reg t80_rst_n;
reg main_cs, in_cs, ram_cs, bank_cs, flip_cs, brt_cs;
reg SECWR;

wire mreq_n;

always @(*) begin
    main_cs       = 1'b0;
    ram_cs        = 1'b0;
    snd_latch_cs = 1'b0;
    snd_latch1_cs = 1'b0;
    scrpos_cs     = 2'b0;
    flip_cs       = 1'b0;
    bank_cs       = 1'b0;
    in_cs         = 1'b0;
    char_cs       = 1'b0;
    scr_cs        = 1'b0;
    brt_cs        = 1'b0;
    obj_cs        = 1'b0;    
    casez(A[15:13])
        3'b0??: main_cs = 1'b1;
        3'b10?: main_cs = 1'b1; // bank
        3'b110: // cscd
            case(A[12:11])
                2'b00: // Part 11B
                    in_cs = 1'b1;
                2'b01:
                    casez(A[2:0])
                        3'b000: snd_latch_cs = 1'b1;
                        3'b100: bank_cs       = 1'b1;
                        3'b110: OKOUT         = 1'b1;
                        3'b111: SECWR         = 1'b1;
                        //3'b010: scrpos_cs     = 2'b01;
                        //3'b011: scrpos_cs     = 2'b10;
                        //3'b100: flip_cs       = 1'b1;
                        //3'b101: brt_cs        = 1'b1;
                        default:;
                    endcase
                2'b10: // DOCS
                //    char_cs = 1'b1; // DOCS
                2'b11: // D8CS
                    if( !A[3] && !wr_n) case(A[2:0])
                        3'd0: scr1posh_cs <= 2'b01; // LSB
                        3'd1: scr1posh_cs <= 2'b10; // MSB
                        3'd2: scr1posv_cs <= 1'b1;
                        3'd3: scr1posh_cs <= 2'b01; // LSB
                        3'd4: scr1posh_cs <= 2'b10; // MSB
                        3'd6: gfxen_cs    <= 1'b1;
                    endcase
                    scr_cs  = 1'b1; // SCRCE
            endcase
        3'b111: ram_cs = A[12]==1'b0; // csef
    endcase
end

// special registers
reg [2:0] bank;
always @(posedge clk)
    if( rst ) begin
        bank      <= 2'd0;
        scr_br    <= 3'b0;
        flip     <= 1'b0;
        sres_b   <= 1'b1;
        coin_cnt <= 1'b0;
    end
    else if(cen3) begin
        if( bank_cs  ) begin
            CHON   <= cpu_dout[7];
            flip   <= cpu_dout[6];
            coin_cnt <= cpu_dout[5] | cpu_dout[1:0];
            bank   <= cpu_dout[4:2];
            `ifdef SIMULATION
            $display("Bank changed to %d", cpu_dout[4:2]);
            `endif
        end
    end

always @(negedge clk)
    t80_rst_n <= ~rst;

reg [7:0] cabinet_input;
reg [7:0] security_code;

always @(*)
    case( A[2:0] )
        3'd0: cabinet_input = { coin_input, // COINS
                     4'hf, // undocumented. The game start screen has background when set to 0!
                     start_button }; // START
        3'd1: cabinet_input = { 1'b1, joystick1 };
        3'd2: cabinet_input = { 1'b1, joystick2 };
        3'd3: cabinet_input = dipsw_a;
        3'd4: cabinet_input = dipsw_b;
        3'd7: cabinet_input = security_code;
        default: cabinet_input = 8'hff;
    endcase


// RAM, 16kB
wire cpu_ram_we = ram_cs && !wr_n;
assign cpu_AB = A[12:0];

jtgng_ram #(.aw(13)) RAM(
    .clk        ( clk       ),
    .cen        ( cen3      ),
    .addr       ( A[12:0]   ),
    .data       ( cpu_dout  ),
    .we         ( cpu_ram_we),
    .q          ( ram_dout  )
);

// Data bus input
reg [7:0] cpu_din;
wire [3:0] int_ctrl;
wire iorq_n, m1_n;
wire irq_ack = !iorq_n && !m1_n;
wire [7:0] irq_vector = {3'b110, int_ctrl[1:0], 3'b111 }; // Schematic K10

always @(*)
    case( {ram_cs, char_cs, scr_cs, main_cs, in_cs} )
        5'b10_000: cpu_din =  //(cheat_invincible && A==16'he0a5) ? 8'h2 : 
                            ram_dout;
        5'b01_000: cpu_din = char_dout;
        5'b00_100: cpu_din = scr_dout;
        5'b00_010: cpu_din = rom_data;
        5'b00_001: cpu_din = cabinet_input;
        default:   cpu_din = rom_data;
    endcase

// ROM ADDRESS
always @(*) begin
    rom_addr[13:0] = A[13:0];
    //rom_addr[16:14] = { 1'b0, A[15:14] } + (!A[15] ? 3'd0 : {1'b0, bank});
    rom_addr[16:14] = !A[15] ? { 2'b0, A[14] } : ( 3'b010 + {1'b0, bank});
end

///////////////////////////////////////////////////////////////////
// interrupt generation. Schematics page 5/9, parts 12J and 14K
reg int_n, int_latch_qb, int_rqb, int_rqb_last;

always @(posedge clk) begin
    if( V[8] && !V[4] )
        case( V[7:5] )
            3'd7: int_latch_qb <= 1'b0;
            3'd0: int_latch_qb <= 1'b1;
        endcase
    int_rqb_last <= int_rqb;
    int_rqb <= int_latch_qb && (V[8] && !V[4] && V[7:5]==3'd3 );
    if( iorq_n || m1_n )
        int_n <= 1'b1;
    else
        int_n <= !( int_rqb && !int_rqb_last );
end
wire wait_n = scr_wait_n & char_wait_n;


///////////////////////////////////////////////////////////////////
// CPU Security (copy protection)
reg [7:0] security;

always @(posedge clk) begin
    if( SECWR && !wr_n )
        security <= cpu_dout;
    case( security )    
        8'h24: security_code <= 8'h1d;
        8'h60: security_code <= 8'hf7;
        8'h01: security_code <= 8'hac;
        8'h55: security_code <= 8'h50;
        8'h56: security_code <= 8'he2;
        8'h2a: security_code <= 8'h58;
        8'ha8: security_code <= 8'h13;
        8'h22: security_code <= 8'h3e;
        8'h3b: security_code <= 8'h5a;
        8'h1e: security_code <= 8'h1b;
        8'he9: security_code <= 8'h41;
        8'h7d: security_code <= 8'hd5;
        8'h43: security_code <= 8'h54;
        8'h37: security_code <= 8'h6f;
        8'h4c: security_code <= 8'h59;
        8'h5f: security_code <= 8'h56;
        8'h3f: security_code <= 8'h2f;
        8'h3e: security_code <= 8'h3d;
        8'hfb: security_code <= 8'h36;
        8'h1d: security_code <= 8'h3b;
        8'h27: security_code <= 8'hae;
        8'h26: security_code <= 8'h39;
        8'h58: security_code <= 8'h3c;
        8'h32: security_code <= 8'h51;
        8'h1a: security_code <= 8'ha8;
        8'hbc: security_code <= 8'h33;
        8'h30: security_code <= 8'h4a;
        8'h64: security_code <= 8'h12;
        8'h11: security_code <= 8'h40;
        8'h33: security_code <= 8'h35;
        8'h09: security_code <= 8'h17;
        8'h25: security_code <= 8'h04;
        default: security_code <= 8'h0;
    endcase
end

///////////////////////////////////////////////////////////////////


`ifdef SIMULATION
`define Z80_ALT_CPU
`endif

//`ifdef NCVERILOG
//`undef Z80_ALT_CPU
//`endif

`ifdef VERILATOR_LINT 
`define Z80_ALT_CPU
`endif

`ifndef Z80_ALT_CPU
// This CPU is used for synthesis
wire [211:0] z80_regs;
`ifdef SIMULATION
wire reg_IFF2; 
wire reg_IFF1; 
wire [1:0]  reg_IM;    // 4
wire [15:0] reg_IY; 
wire [15:0] reg_HL_; 
wire [15:0] reg_DE_; 
wire [15:0] reg_BC_; 
wire [15:0] reg_IX; 
wire [15:0] reg_HL; 
wire [15:0] reg_DE; 
wire [15:0] reg_BC; 
wire [15:0] reg_PC; 
wire [15:0] reg_SP; // 164 
wire [7:0]  reg_R; 
wire [7:0]  reg_I; 
wire [7:0]  reg_F_; 
wire [7:0]  reg_A_; 
wire [7:0]  reg_F; 
wire [7:0]  reg_A;
assign { 
    reg_IFF2, reg_IFF1, reg_IM, reg_IY, reg_HL_, reg_DE_, reg_BC_, 
    reg_IX, reg_HL, reg_DE, reg_BC, reg_PC, reg_SP, reg_R, reg_I, 
    reg_F_, reg_A_, reg_F, reg_A } = z80_regs; 
`endif
T80s u_cpu(
    .RESET_n    ( t80_rst_n   ),
    .CLK        ( clk         ),
    .CEN        ( cen3        ),
    .WAIT_n     ( wait_n      ),
    .INT_n      ( int_n       ),
    .RD_n       ( rd_n        ),
    .WR_n       ( wr_n        ),
    .A          ( A           ),
    .DI         ( cpu_din     ),
    .DO         ( cpu_dout    ),
    .IORQ_n     ( iorq_n      ),
    .M1_n       ( m1_n        ),
    .MREQ_n     ( mreq_n      ),
    .NMI_n      ( 1'b1        ),
    .BUSRQ_n    ( 1'b1        ),
    .out0       ( 1'b0        )
);
`else
// This CPU is used for simulation
tv80s #(.Mode(0)) u_cpu (
    .reset_n( t80_rst_n  ),
    .clk    ( clk        ), // 3 MHz, clock gated
    .cen    ( cen3       ),
    .wait_n ( wait_n     ),
    .int_n  ( int_n      ),
    .nmi_n  ( 1'b1       ),
    .busrq_n( 1'b1       ),
    .rd_n   ( rd_n       ),
    .wr_n   ( wr_n       ),
    .A      ( A          ),
    .di     ( cpu_din    ),
    .dout   ( cpu_dout   ),
    .iorq_n ( iorq_n     ),
    .m1_n   ( m1_n       ),
    .mreq_n ( mreq_n     ),
    // unused
    .busak_n(),
    .halt_n (),
    .rfsh_n ()
);
`endif
endmodule // jtgng_main