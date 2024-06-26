`timescale 1ns/10ps
`ifndef SDRAM_SHIFT
// 5ns works with both 32 and 128 MB modules
// valid values for 48 MHz
// 0 260 520 729 1041 1250 1475 1736 1996 2256 2500 2734 2994 3255 3515 3750 3993
// 4253 4513 4774 5000 5208 5520 5729 5989 6250 6510 6770 6979 7291 7500 7725 7986
// 8246 8506 8750 8984 9244 9505 9765 10000 10243 10329

// valid values for 96 MHz
// 0 -520 -1041 -1475 -1996 -2517 -2994 -3515 -3993 -4253 -4513 -4774 -5034
// -5208 (-180 deg)

	`ifndef JTFRAME_SDRAM96
		// 48 MHz clock
		`define SDRAM_SHIFT "90"
		// `define SDRAM_SHIFT "5520 ps"
	`else
		// 96 MHz clock
		`define SDRAM_SHIFT "-180"
		//`define SDRAM_SHIFT "-5034"
	`endif
`endif


//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// outclk_0__47.99107______0.000______50.0______363.063____307.569
// outclk_1__47.99107_____90.000______50.0______363.063____307.569
// outclk_2__23.99554______0.000______50.0______419.216____307.569
// outclk_3___5.99888______0.000______50.0______546.786____307.569
// outclk_4__95.98214______0.000______50.0______305.930____307.569
// outclk_5__95.98214____-173.571______50.0______305.930____307.569
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary__________50.000____________0.010


module pll_0002 

(// Clock in ports
input         refclk,
// Clock out ports
 output        outclk_0,
 output        outclk_1,
 output        outclk_2,
 output        outclk_3,
 output        outclk_4,
 output        outclk_5,
 // Status and control signals
 input         rst,
 output        locked
);
 // Input buffering
 //------------------------------------
wire refclk_pll_0002;
 IBUF clkin1_ibufg
  (.O (refclk_pll_0002),
   .I (refclk));

 // Clocking PRIMITIVE
 //------------------------------------

 // Instantiation of the MMCM PRIMITIVE
 //    * Unused inputs are tied off
 //    * Unused outputs are labeled unused

 wire        outclk_0_pll_0002;
 wire        outclk_1_pll_0002;
 wire        outclk_2_pll_0002;
 wire        outclk_3_pll_0002;
 wire        outclk_4_pll_0002;
 wire        outclk_5_pll_0002;
 wire        clk_out7_pll_0002;

 wire [15:0] do_unused;
 wire        drdy_unused;
 wire        psdone_unused;
 wire        locked_int;
 wire        clkfbout_pll_0002;
 wire        clkfbout_buf_pll_0002;
 wire        clkfboutb_unused;
   wire clkout0b_unused;
  wire clkout1b_unused;
  wire clkout2b_unused;
  wire clkout3b_unused;
 wire        clkout6_unused;
 wire        clkfbstopped_unused;
 wire        clkinstopped_unused;
 wire        reset_high;

 MMCME2_ADV
 #(.BANDWIDTH            ("OPTIMIZED"),
   .CLKOUT4_CASCADE      ("FALSE"),
   .COMPENSATION         ("ZHOLD"),
   .STARTUP_WAIT         ("FALSE"),
   .DIVCLK_DIVIDE        (2),
   .CLKFBOUT_MULT_F      (26.875),
   .CLKFBOUT_PHASE       (0.000),
   .CLKFBOUT_USE_FINE_PS ("FALSE"),
   .CLKOUT0_DIVIDE_F     (14.000),
   .CLKOUT0_PHASE        (0.000),
   .CLKOUT0_DUTY_CYCLE   (0.500),
   .CLKOUT0_USE_FINE_PS  ("FALSE"),
   .CLKOUT1_DIVIDE       (14),
   .CLKOUT1_PHASE        (90.000),
   .CLKOUT1_DUTY_CYCLE   (0.500),
   .CLKOUT1_USE_FINE_PS  ("FALSE"),
   .CLKOUT2_DIVIDE       (28),
   .CLKOUT2_PHASE        (0.000),
   .CLKOUT2_DUTY_CYCLE   (0.500),
   .CLKOUT2_USE_FINE_PS  ("FALSE"),
   .CLKOUT3_DIVIDE       (112),
   .CLKOUT3_PHASE        (0.000),
   .CLKOUT3_DUTY_CYCLE   (0.500),
   .CLKOUT3_USE_FINE_PS  ("FALSE"),
   .CLKOUT4_DIVIDE       (7),
   .CLKOUT4_PHASE        (0.000),
   .CLKOUT4_DUTY_CYCLE   (0.500),
   .CLKOUT4_USE_FINE_PS  ("FALSE"),
   .CLKOUT5_DIVIDE       (7),
   .CLKOUT5_PHASE        (-173.571),
   .CLKOUT5_DUTY_CYCLE   (0.500),
   .CLKOUT5_USE_FINE_PS  ("FALSE"),
   .CLKIN1_PERIOD        (20.000))
 mmcm_adv_inst
   // Output clocks
  (
   .CLKFBOUT            (clkfbout_pll_0002),
   .CLKFBOUTB           (clkfboutb_unused),
   .CLKOUT0             (outclk_0_pll_0002),
   .CLKOUT0B            (clkout0b_unused),
   .CLKOUT1             (outclk_1_pll_0002),
   .CLKOUT1B            (clkout1b_unused),
   .CLKOUT2             (outclk_2_pll_0002),
   .CLKOUT2B            (clkout2b_unused),
   .CLKOUT3             (outclk_3_pll_0002),
   .CLKOUT3B            (clkout3b_unused),
   .CLKOUT4             (outclk_4_pll_0002),
   .CLKOUT5             (outclk_5_pll_0002),
   .CLKOUT6             (clkout6_unused),
    // Input clock control
   .CLKFBIN             (clkfbout_buf_pll_0002),
   .CLKIN1              (refclk_pll_0002),
   .CLKIN2              (1'b0),
    // Tied to always select the primary input clock
   .CLKINSEL            (1'b1),
   // Ports for dynamic reconfiguration
   .DADDR               (7'h0),
   .DCLK                (1'b0),
   .DEN                 (1'b0),
   .DI                  (16'h0),
   .DO                  (do_unused),
   .DRDY                (drdy_unused),
   .DWE                 (1'b0),
   // Ports for dynamic phase shift
   .PSCLK               (1'b0),
   .PSEN                (1'b0),
   .PSINCDEC            (1'b0),
   .PSDONE              (psdone_unused),
   // Other control and status signals
   .LOCKED              (locked_int),
   .CLKINSTOPPED        (clkinstopped_unused),
   .CLKFBSTOPPED        (clkfbstopped_unused),
   .PWRDWN              (1'b0),
   .RST                 (reset_high));
 assign reset_high = rst; 

 assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
// Output buffering
 //-----------------------------------

 BUFG clkf_buf
  (.O (clkfbout_buf_pll_0002),
   .I (clkfbout_pll_0002));


 BUFG clkout1_buf
  (.O   (outclk_0),
   .I   (outclk_0_pll_0002));


 BUFG clkout2_buf
  (.O   (outclk_1),
   .I   (outclk_1_pll_0002));

 BUFG clkout3_buf
  (.O   (outclk_2),
   .I   (outclk_2_pll_0002));

 BUFG clkout4_buf
  (.O   (outclk_3),
   .I   (outclk_3_pll_0002));

 BUFG clkout5_buf
  (.O   (outclk_4),
   .I   (outclk_4_pll_0002));

 BUFG clkout6_buf
  (.O   (outclk_5),
   .I   (outclk_5_pll_0002));


endmodule
