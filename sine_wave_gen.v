`timescale 1ns / 1ps

module sine_wave_gen (
    input wire clk,             // 100 MHz clock from Basys 3
    input wire rst,             // Reset signal
    input wire [7:0] switch,    // Frequency control via switches
    output reg [15:0] sine_out  // 16-bit sine output
);
    
    reg [15:0] phase_acc = 0;
    wire [7:0] addr;  // Change to wire
    
    // Phase Increment (adjust frequency based on switches)
    wire [15:0] phase_inc = {switch, 8'b0};  // Shifted to control precision

    // 8-bit Sine LUT (precomputed values from sin() function)
    reg [15:0] sine_LUT [0:255];
    
    initial begin
        // Initialize sine LUT directly in the file
        sine_LUT[0] = 16'h0000; sine_LUT[1] = 16'h0324; sine_LUT[2] = 16'h0647; sine_LUT[3] = 16'h096A;
        sine_LUT[4] = 16'h0C8B; sine_LUT[5] = 16'h0FAB; sine_LUT[6] = 16'h12C7; sine_LUT[7] = 16'h15E1;
        sine_LUT[8] = 16'h18F8; sine_LUT[9] = 16'h1C0B; sine_LUT[10] = 16'h1F19; sine_LUT[11] = 16'h2223;
        sine_LUT[12] = 16'h2527; sine_LUT[13] = 16'h2826; sine_LUT[14] = 16'h2B1E; sine_LUT[15] = 16'h2E10;
        sine_LUT[16] = 16'h30FB; sine_LUT[17] = 16'h33DE; sine_LUT[18] = 16'h36B9; sine_LUT[19] = 16'h398C;
        sine_LUT[20] = 16'h3C56; sine_LUT[21] = 16'h3F16; sine_LUT[22] = 16'h41CD; sine_LUT[23] = 16'h447A;
        sine_LUT[24] = 16'h471C; sine_LUT[25] = 16'h49B3; sine_LUT[26] = 16'h4C3F; sine_LUT[27] = 16'h4EBF;
        sine_LUT[28] = 16'h5133; sine_LUT[29] = 16'h539A; sine_LUT[30] = 16'h55F4; sine_LUT[31] = 16'h5842;
        sine_LUT[32] = 16'h5A81; sine_LUT[33] = 16'h5CB3; sine_LUT[34] = 16'h5ED6; sine_LUT[35] = 16'h60EB;
        sine_LUT[36] = 16'h62F1; sine_LUT[37] = 16'h64E7; sine_LUT[38] = 16'h66CE; sine_LUT[39] = 16'h68A5;
        sine_LUT[40] = 16'h6A6C; sine_LUT[41] = 16'h6C23; sine_LUT[42] = 16'h6DC9; sine_LUT[43] = 16'h6F5E;
        sine_LUT[44] = 16'h70E1; sine_LUT[45] = 16'h7254; sine_LUT[46] = 16'h73B5; sine_LUT[47] = 16'h7503;
        sine_LUT[48] = 16'h7640; sine_LUT[49] = 16'h776B; sine_LUT[50] = 16'h7883; sine_LUT[51] = 16'h7989;
        sine_LUT[52] = 16'h7A7C; sine_LUT[53] = 16'h7B5C; sine_LUT[54] = 16'h7C29; sine_LUT[55] = 16'h7CE2;
        sine_LUT[56] = 16'h7D89; sine_LUT[57] = 16'h7E1C; sine_LUT[58] = 16'h7E9C; sine_LUT[59] = 16'h7F08;
        sine_LUT[60] = 16'h7F61; sine_LUT[61] = 16'h7FA6; sine_LUT[62] = 16'h7FD7; sine_LUT[63] = 16'h7FF5;
        sine_LUT[64] = 16'h7FFF; sine_LUT[65] = 16'h7FF5; sine_LUT[66] = 16'h7FD7; sine_LUT[67] = 16'h7FA6;
        sine_LUT[68] = 16'h7F61; sine_LUT[69] = 16'h7F08; sine_LUT[70] = 16'h7E9C; sine_LUT[71] = 16'h7E1C;
        sine_LUT[72] = 16'h7D89; sine_LUT[73] = 16'h7CE2; sine_LUT[74] = 16'h7C29; sine_LUT[75] = 16'h7B5C;
        sine_LUT[76] = 16'h7A7C; sine_LUT[77] = 16'h7989; sine_LUT[78] = 16'h7883; sine_LUT[79] = 16'h776B;
        sine_LUT[80] = 16'h7640; sine_LUT[81] = 16'h7503; sine_LUT[82] = 16'h73B5; sine_LUT[83] = 16'h7254;
        sine_LUT[84] = 16'h70E1; sine_LUT[85] = 16'h6F5E; sine_LUT[86] = 16'h6DC9; sine_LUT[87] = 16'h6C23;
        sine_LUT[88] = 16'h6A6C; sine_LUT[89] = 16'h68A5; sine_LUT[90] = 16'h66CE; sine_LUT[91] = 16'h64E7;
        sine_LUT[92] = 16'h62F1; sine_LUT[93] = 16'h60EB; sine_LUT[94] = 16'h5ED6; sine_LUT[95] = 16'h5CB3;
        sine_LUT[96] = 16'h5A81; sine_LUT[97] = 16'h5842; sine_LUT[98] = 16'h55F4; sine_LUT[99] = 16'h539A;
        sine_LUT[100] = 16'h5133; sine_LUT[101] = 16'h4EBF; sine_LUT[102] = 16'h4C3F; sine_LUT[103] = 16'h49B3;
        sine_LUT[104] = 16'h471C; sine_LUT[105] = 16'h447A; sine_LUT[106] = 16'h41CD; sine_LUT[107] = 16'h3F16;
        sine_LUT[108] = 16'h3C56; sine_LUT[109] = 16'h398C; sine_LUT[110] = 16'h36B9; sine_LUT[111] = 16'h33DE;
        sine_LUT[112] = 16'h30FB; sine_LUT[113] = 16'h2E10; sine_LUT[114] = 16'h2B1E; sine_LUT[115] = 16'h2826;
        sine_LUT[116] = 16'h2527; sine_LUT[117] = 16'h2223; sine_LUT[118] = 16'h1F19; sine_LUT[119] = 16'h1C0B;
        sine_LUT[120] = 16'h18F8; sine_LUT[121] = 16'h15E1; sine_LUT[122] = 16'h12C7; sine_LUT[123] = 16'h0FAB;
        sine_LUT[124] = 16'h0C8B; sine_LUT[125] = 16'h096A; sine_LUT[126] = 16'h0647; sine_LUT[127] = 16'h0324;
        sine_LUT[128] = 16'h0000; sine_LUT[129] = 16'hFCDC; sine_LUT[130] = 16'hF9B9; sine_LUT[131] = 16'hF696;
        sine_LUT[132] = 16'hF375; sine_LUT[133] = 16'hF055; sine_LUT[134] = 16'hED39; sine_LUT[135] = 16'hEA1F;
        sine_LUT[136] = 16'hE708; sine_LUT[137] = 16'hE3F5; sine_LUT[138] = 16'hE0E7; sine_LUT[139] = 16'hDDDD;
        sine_LUT[140] = 16'hDAD9; sine_LUT[141] = 16'hD7DA; sine_LUT[142] = 16'hD4E2; sine_LUT[143] = 16'hD1F0;
        sine_LUT[144] = 16'hCF05; sine_LUT[145] = 16'hCC22; sine_LUT[146] = 16'hC947; sine_LUT[147] = 16'hC674;
        sine_LUT[148] = 16'hC3AA; sine_LUT[149] = 16'hC0EA; sine_LUT[150] = 16'hBE33; sine_LUT[151] = 16'hBB86;
        sine_LUT[152] = 16'hB8E4; sine_LUT[153] = 16'hB64D; sine_LUT[154] = 16'hB3C1; sine_LUT[155] = 16'hB141;
        sine_LUT[156] = 16'hAECD; sine_LUT[157] = 16'hAC66; sine_LUT[158] = 16'hAA0C; sine_LUT[159] = 16'hA7BE;
        sine_LUT[160] = 16'hA57F; sine_LUT[161] = 16'hA34D; sine_LUT[162] = 16'hA12A; sine_LUT[163] = 16'h9F15;
        sine_LUT[164] = 16'h9D0F; sine_LUT[165] = 16'h9B19; sine_LUT[166] = 16'h9932; sine_LUT[167] = 16'h975B;
        sine_LUT[168] = 16'h9594; sine_LUT[169] = 16'h93DD; sine_LUT[170] = 16'h9237; sine_LUT[171] = 16'h90A2;
        sine_LUT[172] = 16'h8F1F; sine_LUT[173] = 16'h8DAC; sine_LUT[174] = 16'h8C4B; sine_LUT[175] = 16'h8AFD;
        sine_LUT[176] = 16'h89C0; sine_LUT[177] = 16'h8895; sine_LUT[178] = 16'h877D; sine_LUT[179] = 16'h8677;
        sine_LUT[180] = 16'h8584; sine_LUT[181] = 16'h84A4; sine_LUT[182] = 16'h83D7; sine_LUT[183] = 16'h831E;
        sine_LUT[184] = 16'h8277; sine_LUT[185] = 16'h81E4; sine_LUT[186] = 16'h8164; sine_LUT[187] = 16'h80F8;
        sine_LUT[188] = 16'h809F; sine_LUT[189] = 16'h805A; sine_LUT[190] = 16'h8029; sine_LUT[191] = 16'h800B;
        sine_LUT[192] = 16'h8001; sine_LUT[193] = 16'h800B; sine_LUT[194] = 16'h8029; sine_LUT[195] = 16'h805A;
        sine_LUT[196] = 16'h809F; sine_LUT[197] = 16'h80F8; sine_LUT[198] = 16'h8164; sine_LUT[199] = 16'h81E4;
        sine_LUT[200] = 16'h8277; sine_LUT[201] = 16'h831E; sine_LUT[202] = 16'h83D7; sine_LUT[203] = 16'h84A4;
        sine_LUT[204] = 16'h8584; sine_LUT[205] = 16'h8677; sine_LUT[206] = 16'h877D; sine_LUT[207] = 16'h8895;
        sine_LUT[208] = 16'h89C0; sine_LUT[209] = 16'h8AFD; sine_LUT[210] = 16'h8C4B; sine_LUT[211] = 16'h8DAC;
        sine_LUT[212] = 16'h8F1F; sine_LUT[213] = 16'h90A2; sine_LUT[214] = 16'h9237; sine_LUT[215] = 16'h93DD;
        sine_LUT[216] = 16'h9594; sine_LUT[217] = 16'h975B; sine_LUT[218] = 16'h9932; sine_LUT[219] = 16'h9B19;
        sine_LUT[220] = 16'h9D0F; sine_LUT[221] = 16'h9F15; sine_LUT[222] = 16'hA12A; sine_LUT[223] = 16'hA34D;
        sine_LUT[224] = 16'hA57F; sine_LUT[225] = 16'hA7BE; sine_LUT[226] = 16'hAA0C; sine_LUT[227] = 16'hAC66;
        sine_LUT[228] = 16'hAECD; sine_LUT[229] = 16'hB141; sine_LUT[230] = 16'hB3C1; sine_LUT[231] = 16'hB64D;
        sine_LUT[232] = 16'hB8E4; sine_LUT[233] = 16'hBB86; sine_LUT[234] = 16'hBE33; sine_LUT[235] = 16'hC0EA;
        sine_LUT[236] = 16'hC3AA; sine_LUT[237] = 16'hC674; sine_LUT[238] = 16'hC947; sine_LUT[239] = 16'hCC22;
        sine_LUT[240] = 16'hCF05; sine_LUT[241] = 16'hD1F0; sine_LUT[242] = 16'hD4E2; sine_LUT[243] = 16'hD7DA;
        sine_LUT[244] = 16'hDAD9; sine_LUT[245] = 16'hDDDD; sine_LUT[246] = 16'hE0E7; sine_LUT[247] = 16'hE3F5;
        sine_LUT[248] = 16'hE708; sine_LUT[249] = 16'hEA1F; sine_LUT[250] = 16'hED39; sine_LUT[251] = 16'hF055;
        sine_LUT[252] = 16'hF375; sine_LUT[253] = 16'hF696; sine_LUT[254] = 16'hF9B9; sine_LUT[255] = 16'hFCDC;
    end

    always @(posedge clk) begin
        if (rst)
            phase_acc <= 0;
        else
            phase_acc <= phase_acc + phase_inc; // Increment phase
    end

    assign addr = phase_acc[15:8]; // Use upper 8 bits as address

    always @(posedge clk) begin
        sine_out <= sine_LUT[addr];
    end

endmodule