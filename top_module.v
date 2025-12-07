`timescale 1ns / 1ps

module top_module (
    input wire clk,              
    input wire rst,               // Reset
    input wire [7:0] switch,      // Frequency control switches
    output wire tx                // UART TX line
);

    wire [15:0] sine_wave;
    wire [15:0] filtered_wave;

    // Generate Sine Wave
    sine_wave_gen sine_gen (
        .clk(clk),
        .rst(rst),
        .switch(switch),
        .sine_out(sine_wave)
    );

    // Apply FIR Filter
    fir_filter fir (
        .clk(clk),
        .rst(rst),
        .data_in(sine_wave),
        .data_out(filtered_wave)
    );

    // UART Transmission (Sending both raw and filtered data)
    uart_tx uart (
        .clk(clk),
        .rst(rst),
        .data(filtered_wave), // Sending only filtered wave for now
        .tx(tx)
    );

endmodule
