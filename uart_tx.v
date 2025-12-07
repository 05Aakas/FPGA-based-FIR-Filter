module uart_tx (
    input wire clk,          // 100 MHz Clock
    input wire rst,          // Reset
    input wire [15:0] data,  // 16-bit Data to transmit
    output reg tx            // UART TX line
);

    // UART Parameters
    parameter CLK_FREQ = 100_000_000;  // 100 MHz
    parameter BAUD_RATE = 115200;
    parameter BAUD_TICK = CLK_FREQ / BAUD_RATE;  // Clock cycles per baud
    parameter MSB_FIRST = 1;  // Send MSB first (set to 0 for LSB first)

    reg [9:0] shift_reg;     // 10-bit Shift Register (1 start, 8 data, 1 stop)
    reg [3:0] bit_index;     // Tracks bit position (0-9)
    reg [15:0] baud_counter; // Baud Rate Counter
    reg [1:0] state;         // State machine: 0=IDLE, 1=BYTE1, 2=BYTE2
    reg [7:0] byte1, byte2;
    always @(*) begin
        byte1 = MSB_FIRST ? data[15:8] : data[7:0];
        byte2 = MSB_FIRST ? data[7:0]  : data[15:8];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1;          // UART Idle is High
            state <= 0;
            bit_index <= 0;
            baud_counter <= 0;
            shift_reg <= 10'h3FF; // Default to idle (all 1's)
        end else begin
            case (state)
                // IDLE: Wait for new data
                0: begin
                    tx <= 1;
                    if (data != 16'h0000) begin  // Start transmission if data is non-zero
                        shift_reg <= {1'b1, byte1, 1'b0}; // Start bit (0) + byte1 + Stop bit (1)
                        state <= 1;              // Move to BYTE1 state
                        bit_index <= 0;
                        baud_counter <= 0;
                    end
                end

                // BYTE1: Transmit first byte
                1: begin
                    if (baud_counter < BAUD_TICK - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else begin
                        baud_counter <= 0;
                        tx <= shift_reg[0];
                        shift_reg <= {1'b1, shift_reg[9:1]}; // Shift right, pad with 1's
                        bit_index <= bit_index + 1;

                        // After 10 bits (start + 8 data + stop), move to BYTE2
                        if (bit_index == 9) begin
                            shift_reg <= {1'b1, byte2, 1'b0}; // Load byte2
                            state <= 2;
                            bit_index <= 0;
                        end
                    end
                end

                // BYTE2: Transmit second byte
                2: begin
                    if (baud_counter < BAUD_TICK - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else begin
                        baud_counter <= 0;
                        tx <= shift_reg[0];
                        shift_reg <= {1'b1, shift_reg[9:1]}; // Shift right, pad with 1's
                        bit_index <= bit_index + 1;

                        // After 10 bits, return to IDLE
                        if (bit_index == 9) begin
                            state <= 0;
                        end
                    end
                end

                default: state <= 0;
            endcase
        end
    end
endmodule