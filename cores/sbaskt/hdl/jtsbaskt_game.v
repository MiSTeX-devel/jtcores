/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 11-11-2021 */

module jtsbaskt_game(
    `include "jtframe_game_ports.inc" // see $JTFRAME/hdl/inc/jtframe_game_ports.inc
);

localparam [21:0] SCR_START = `SCR_START,
                  PCM_START = `PCM_START;

wire [ 7:0] dipsw_a, dipsw_b;
wire        V16;

wire [ 3:0] pal_sel;
wire        obj_frame;
wire        cpu_cen, cpu4_cen;
wire        cpu_rnw, cpu_irqn, cpu_nmin;
wire        vscr_cs, vram_cs, objram_cs, flip;
wire [ 7:0] vscr_dout, vram_dout, obj_dout, cpu_dout,
            debug_snd;
wire        vsync60;
wire        snd_cen, psg_cen;

wire        m2s_irq, m2s_data;

assign { dipsw_b, dipsw_a } = dipsw[15:0];
assign dip_flip = flip;
assign debug_view = debug_snd;

wire [ 7:0] nc, pre_data;

always @(*) begin
    post_data = prog_data;
    if( ioctl_addr[21:0] >= SCR_START && ioctl_addr[21:0]<PCM_START ) begin
        post_data = { prog_data[3:0], prog_data[7:4] };
    end
end

jtkicker_clocks u_clocks(
    .status     ( status    ),
    // 24 MHz domain
    .clk24      ( clk24     ),
    .cpu4_cen   ( cpu4_cen  ),
    .snd_cen    ( snd_cen   ),
    .psg_cen    ( psg_cen   ),
    .ti1_cen    (           ),
    .ti2_cen    (           )
);

`ifndef NOMAIN
jtsbaskt_main u_main(
    .rst            ( rst24         ),
    .clk            ( clk24         ),        // 24 MHz
    .cpu4_cen       ( cpu4_cen      ),
    .cpu_cen        ( cpu_cen       ),
    // ROM
    .rom_addr       ( main_addr     ),
    .rom_cs         ( main_cs       ),
    .rom_data       ( main_data     ),
    .rom_ok         ( main_ok       ),
    // cabinet I/O
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .service        ( service       ),
    // GFX
    .cpu_dout       ( cpu_dout      ),
    .cpu_rnw        ( cpu_rnw       ),

    .vscr_cs        ( vscr_cs       ),
    .vram_cs        ( vram_cs       ),
    .vram_dout      ( vram_dout     ),
    .vscr_dout      ( vscr_dout     ),

    .objram_cs      ( objram_cs     ),
    .obj_dout       ( obj_dout      ),
    .obj_frame      ( obj_frame     ),
    // Sound control
    .snd_data_cs    ( m2s_data      ),
    .snd_on_cs      ( m2s_irq       ),
    // GFX configuration
    .pal_sel        ( pal_sel       ),
    .flip           ( flip          ),
    // interrupt triggers
    .LVBL           ( LVBL          ),
    .V16            ( V16           ),
    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       )
);
`else
    assign main_cs = 0;
    assign objram_cs = 0;
    assign snd     = 0;
    assign sample  = 0;
    assign game_led= 0;
    assign pal_sel = 0;
    assign flip    = 0;
    assign pcm_addr= 0;
`endif

`ifndef NOSOUND
jtsbaskt_snd u_sound(
    .rst        ( rst       ),
    .clk        ( clk24     ),
    .snd_cen    ( snd_cen   ),    // 3.5MHz
    .psg_cen    ( psg_cen   ),    // 1.7MHz
    // ROM
    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),
    // From main CPU
    .main_dout  ( cpu_dout  ),
    .m2s_data   ( m2s_data  ),
    .m2s_irq    ( m2s_irq   ),
    // Sound
    .pcm_addr   ( pcm_addr  ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    .snd        ( snd       ),
    .sample     ( sample    ),
    .peak       ( game_led  ),
    .debug_view ( debug_snd )
);
`else
    assign snd_cs=0;
    assign snd_addr=0;
    assign pcm_addr=0;
    assign snd=0;
    assign sample=0;
`endif

/* verilator tracing_off */
jtsbaskt_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),

    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  ),

    // configuration
    .pal_sel    ( pal_sel   ),
    .flip       ( flip      ),

    // CPU interface
    .cpu_addr   ( main_addr[10:0]  ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_rnw    ( cpu_rnw   ),
    // Scroll
    .vram_cs    ( vram_cs   ),
    .vscr_cs    ( vscr_cs   ),
    .vram_dout  ( vram_dout ),
    .vscr_dout  ( vscr_dout ),
    // Objects
    .objram_cs  ( objram_cs ),
    .obj_dout   ( obj_dout  ),
    .obj_frame  ( obj_frame ),

    // PROMs
    .prog_data  ( prog_data ),
    .prog_addr  ( prog_addr[10:0] ),
    .prom_en    ( prom_we   ),

    // Scroll
    .scr_addr   ( scr_addr  ),
    .scr_data   ( scr_data  ),
    .scr_ok     ( scr_ok    ),
    // Objects
    .obj_addr   ( obj_addr  ),
    .obj_data   ( obj_data  ),
    .obj_cs     ( obj_cs    ),
    .obj_ok     ( obj_ok    ),

    .V16        ( V16       ),
    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .gfx_en     ( gfx_en    ),
    .debug_bus  ( debug_bus )
);

endmodule