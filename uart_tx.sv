module uart_tx #(parameter CLKS_PER_BIT = 434)( // default 115200 baud with 50MHz clock 
    input logic clk,
    input logic tx_start,
    input logic [7:0] data,
    output logic txd,
    output logic tx_done
);

    localparam IDLE_STATE = 2'b00;
    localparam START_STATE = 2'b01;
    localparam DATA_STATE = 2'b10;
    localparam STOP_STATE = 2'b11;

    logic[1:0] state = 2'b0;
    logic[15:0] counter = 16'b0;
    logic[2:0] bit_index = 3'b0;
    logic[7:0] sbuf_reg = 8'b0;

always_ff @( posedge clk ) 
    begin
        case (state)
            IDLE_STATE:
                begin
                    counter <= 16'b0;
                    txd <= 1;
                    tx_done <= 0;

                    if (tx_start == 1) 
                        begin
                            state <= START_STATE;
                        end
                    else 
                        state <= IDLE_STATE;
                end
            START_STATE:
                begin
                    txd <= 0;
                    //UART baud rate
                    if (counter < CLKS_PER_BIT - 1)
                        begin
                            counter <= counter + 16'b1;
                            state <= START_STATE;
                        end
                    else
                        begin
                            counter <= 16'b0;
                            sbuf_reg <= data; // Latch input
                            state <= DATA_STATE;
                        end
                end 
            DATA_STATE:
                begin
                    txd <= sbuf_reg[0];
                    if (counter < CLKS_PER_BIT - 1)
                        begin
                            counter <= counter + 16'b1;
                            state <= DATA_STATE;
                        end
                    else 
                        begin
                            counter <= 16'b0;
                            if (bit_index < 7)
                                begin
                                    sbuf_reg <= {1'b0, sbuf_reg[7:1]};
                                    bit_index <= bit_index + 3'b1;
                                    state <= DATA_STATE;
                                end
                            else 
                                begin
                                    bit_index <= 3'b0;
                                    state <= STOP_STATE;
                                end
                        end
                end
            STOP_STATE:
                begin
                    txd <= 1;
                    //UART baud rate
                    if (counter < CLKS_PER_BIT - 1)
                        begin
                            counter <= counter + 16'b1;
                            state <= STOP_STATE;
                        end
                    else
                        begin
                            counter <= 0;
                            tx_done <= 1;
                            state <= IDLE_STATE;
                        end
                end 
        endcase 
    end

endmodule 