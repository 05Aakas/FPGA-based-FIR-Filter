//module fir_filter #(
//    parameter N = 16,  // Data width
//    parameter TAPS = 31 // Number of coefficients
//) (
//    input clk,
//    input rst,
//    input signed [N-1:0] data_in,
//    output reg signed [N-1:0] data_out
//);

//    reg signed [N-1:0] shift_reg [0:TAPS-1]; 
//    reg signed [N-1:0] coeffs [0:TAPS-1];

//    // Example FIR Coefficients (Replace with actual values)
//    initial begin
//        coeffs[0] = 16'h0020; coeffs[1] = 16'h0035; coeffs[2] = 16'h005A;
//        coeffs[3] = 16'h008C; coeffs[4] = 16'h00D0; coeffs[5] = 16'h012A;
//        coeffs[6] = 16'h019F; coeffs[7] = 16'h022D; coeffs[8] = 16'h02D2;
//        coeffs[9] = 16'h0387; coeffs[10] = 16'h0445; coeffs[11] = 16'h0503;
//        coeffs[12] = 16'h05B1; coeffs[13] = 16'h0640; coeffs[14] = 16'h06AC;
//        coeffs[15] = 16'h06EC; coeffs[16] = 16'h06AC; coeffs[17] = 16'h0640;
//        coeffs[18] = 16'h05B1; coeffs[19] = 16'h0503; coeffs[20] = 16'h0445;
//        coeffs[21] = 16'h0387; coeffs[22] = 16'h02D2; coeffs[23] = 16'h022D;
//        coeffs[24] = 16'h019F; coeffs[25] = 16'h012A; coeffs[26] = 16'h00D0;
//        coeffs[27] = 16'h008C; coeffs[28] = 16'h005A; coeffs[29] = 16'h0035;
//        coeffs[30] = 16'h0020;
//    end

//    integer i;
//    reg signed [N+15:0] acc; // Accumulator with extra bits for precision

//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            data_out <= 0;
//            for (i = 0; i < TAPS; i = i + 1) 
//                shift_reg[i] <= 0;
//        end else begin
//            // Shift the data
//            for (i = TAPS-1; i > 0; i = i - 1) 
//                shift_reg[i] <= shift_reg[i-1];
//            shift_reg[0] <= data_in;

//            // Compute MAC (Multiply and Accumulate)
//            acc = 0;
//            for (i = 0; i < TAPS; i = i + 1) 
//                acc = acc + shift_reg[i] * coeffs[i];

//            // Assign output (truncate/scale if needed)
//            data_out <= acc >>> 15; // Scaling down to 16 bits
//        end
//    end
//endmodule



module fir_filter #(
    parameter N = 16,  // Data width
    parameter TAPS = 31 // Number of coefficients
) (
    input clk,
    input rst,
    input signed [N-1:0] data_in,
    output reg signed [N-1:0] data_out
);

    // Shift register for input data
    reg signed [N-1:0] shift_reg [0:TAPS-1];
    
    // FIR coefficients (same as original)
    reg signed [N-1:0] coeffs [0:TAPS-1];
    initial begin
        coeffs[0] = 16'h0020; coeffs[1] = 16'h0035; coeffs[2] = 16'h005A;
        coeffs[3] = 16'h008C; coeffs[4] = 16'h00D0; coeffs[5] = 16'h012A;
        coeffs[6] = 16'h019F; coeffs[7] = 16'h022D; coeffs[8] = 16'h02D2;
        coeffs[9] = 16'h0387; coeffs[10] = 16'h0445; coeffs[11] = 16'h0503;
        coeffs[12] = 16'h05B1; coeffs[13] = 16'h0640; coeffs[14] = 16'h06AC;
        coeffs[15] = 16'h06EC; coeffs[16] = 16'h06AC; coeffs[17] = 16'h0640;
        coeffs[18] = 16'h05B1; coeffs[19] = 16'h0503; coeffs[20] = 16'h0445;
        coeffs[21] = 16'h0387; coeffs[22] = 16'h02D2; coeffs[23] = 16'h022D;
        coeffs[24] = 16'h019F; coeffs[25] = 16'h012A; coeffs[26] = 16'h00D0;
        coeffs[27] = 16'h008C; coeffs[28] = 16'h005A; coeffs[29] = 16'h0035;
        coeffs[30] = 16'h0020;
    end

    // Pipeline stage 1: Group of 3 multiplications each (10 groups)
    reg signed [N+15:0] stage1 [0:9];
    reg signed [N+15:0] stage1_remainder;
    
    // Pipeline stage 2: Intermediate sums
    reg signed [N+15:0] stage2 [0:3];
    
    // Pipeline stage 3: Final sum
    reg signed [N+15:0] stage3;
    
    // Pipeline stage 4: Output register
    reg signed [N+15:0] stage4;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers
            for (i = 0; i < TAPS; i = i + 1) 
                shift_reg[i] <= 0;
                
            for (i = 0; i < 10; i = i + 1)
                stage1[i] <= 0;
            stage1_remainder <= 0;
            
            for (i = 0; i < 4; i = i + 1)
                stage2[i] <= 0;
                
            stage3 <= 0;
            stage4 <= 0;
            data_out <= 0;
        end else begin
            // Shift register update
            for (i = TAPS-1; i > 0; i = i - 1) 
                shift_reg[i] <= shift_reg[i-1];
            shift_reg[0] <= data_in;

            // --- Pipeline Stage 1: Multiply and accumulate in groups of 3 ---
            for (i = 0; i < 10; i = i + 1) begin
                stage1[i] <= (shift_reg[i*3]   * coeffs[i*3]) +
                             (shift_reg[i*3+1] * coeffs[i*3+1]) +
                             (shift_reg[i*3+2] * coeffs[i*3+2]);
            end
            // Handle the remaining tap (tap 30)
            stage1_remainder <= shift_reg[30] * coeffs[30];

            // --- Pipeline Stage 2: First level of summation ---
            stage2[0] <= stage1[0] + stage1[1] + stage1[2];    // Sum of first 9 products
            stage2[1] <= stage1[3] + stage1[4] + stage1[5];    // Sum of next 9 products
            stage2[2] <= stage1[6] + stage1[7] + stage1[8];    // Sum of next 9 products
            stage2[3] <= stage1[9] + stage1_remainder;         // Sum of last 3 products + remainder

            // --- Pipeline Stage 3: Second level of summation ---
            stage3 <= stage2[0] + stage2[1] + stage2[2] + stage2[3];

            // --- Pipeline Stage 4: Scaling and output ---
            stage4 <= stage3;
            data_out <= stage4 >>> 15; // Right shift by 15 for scaling
        end
    end
endmodule