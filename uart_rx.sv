module uart_rx #(parameter CLKS_PER_BIT = 434)( // default 115200 baud with 50MHz clock 
    input logic clk,
    input logic rxd,
    output logic [7:0] data,
    output logic rx_done
);

    localparam IDLE_STATE = 2'b00;
    localparam START_STATE = 2'b01;
    localparam DATA_STATE = 2'b10;
    localparam STOP_STATE = 2'b11;

    logic rx_buffer = 1'b1;
    logic rx = 1'b1;

    logic[1:0] state = 2'b0;
    logic[15:0] counter = 16'b0;
    logic[2:0] bit_index = 3'b0;
    logic[7:0] sbuf_reg = 8'b0;

always_ff @(posedge clk) 
    begin
        rx_buffer <= rxd;
        rx <= rx_buffer;
    end


always_ff @( posedge clk ) 
    begin
        case(state)
            IDLE_STATE:
                begin
                    counter <= 16'b0;
                    rx_done <= 1'b0;

                    if (rx == 0)
                        begin
                            state <= START_STATE;
                        end
                    else 
                        state <= IDLE_STATE;
                end
            START_STATE:
                begin
                    if (counter == (CLKS_PER_BIT -1) / 2)
                        begin
                            if (rx == 0) // Check if start bit still low at middle of start bit
                                begin
                                    counter <= 16'b0;
                                    state <= DATA_STATE;
                                end
                            else
                                state <= IDLE_STATE;
                        end
                    else
                        begin
                            counter <= counter + 16'b1;
                            state <= START_STATE;
                        end
                end
            DATA_STATE:
                begin
                    if (counter < CLKS_PER_BIT -1)
                        begin
                            counter <= counter + 16'b1;
                            state <= DATA_STATE;                           
                        end
                    else 
                        begin
                            counter <= 16'b0;
                            sbuf_reg[bit_index] <= rx;
                            if (bit_index < 7) 
                                begin
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
                    if (counter < (CLKS_PER_BIT -1)) 
                        begin
                            counter <= counter + 16'b1;
                            state <= STOP_STATE;

                        end
                    else
                        begin
                            rx_done <= 1'b1;
                            counter <= 16'b0;
                            data <= sbuf_reg;
                            state <= IDLE_STATE;
                        end


                end
            default:
                state <= IDLE_STATE;
                
        endcase
    end

endmodule