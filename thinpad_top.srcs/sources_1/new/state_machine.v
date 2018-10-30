`default_nettype wire
module state_machine(
	input clk_50M,
	input clk,
	input rst,

	output reg[15:0] leds,
	inout [31:0] data,
	output reg[19:0] address,
	input [31:0] push_buttons,

	output wire oe, 
	output wire we,

	    //CPLD���ڿ������ź�
    output reg uart_rdn,         //�������źţ�����Ч
    output reg uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre        //���ݷ�����ϱ�־
	);

reg [3:0] state = 0;//״̬����״̬
reg [31:0] data_received;// ���ܵ�����������
reg [19:0] address_buffer;// �洢�ĵ�ַ
reg received_done = 0; // �Ƿ�32λ�����Ѿ��������
reg send_begin = 0;// �Ƿ�ʼ��������

reg oe_r = 1, we_r = 1;

assign oe = oe_r;
assign we = we_r;//�ڴ��дʹ��

reg rdn_r = 1, wrn_r = 1;
assign uart_rdn = rdn_r;
assign uart_wrn = wrn_r;//���ڶ�дʹ��

wire [7:0] ext_uart_rx; // ���յ��Ĳ�������
reg  [7:0] ext_uart_buffer, ext_uart_tx; // ���յ������ݵĻ������������͵����ݻ�����
wire ext_uart_ready, ext_uart_busy; // �Ƿ��Ѿ����յ�һ֡���������ݣ��Ƿ����ڷ�����æ
reg ext_uart_start, ext_uart_avai; // �Ƿ�ʼ���ͻ������е��źţ��Ƿ������Ѿ�����

assign data = data_received;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		state <= 0;
	end
	else if (clk) begin
		case(state)
			4'b0000:begin
			 if (received_done) begin
			// data <= data_received;
			leds <= data_received[15:0];
			state <= 4'b0001;	
			end
			else begin
			    leds <= data_received[15:0];
				state <= 0;
			end
			end
			4'b0001: begin
			address <= push_buttons;
			state <= 4'b0010;
			end
			4'b0010: begin
			uart_rdn <= 1;
			uart_wrn <= 1;
			we_r <= 0;//д����
			oe_r <= 1;
			state <= 4'b0011;
			end
			4'b0011: begin
			we_r <= 1;
			oe_r <= 1;
			address <= push_buttons;
			state <= 4'b0100;
			end
			4'b0100: begin
			uart_rdn <= 1;
			uart_wrn <= 1;
			oe_r <= 0; // ������
			we_r <= 1;
			state <= 4'b0101;
			end
			4'b0101: begin
			data_received <= data;//�����������ݷŵ�������
			send_begin <= 1; //��ʼ���ͻ������е�����
			leds <= data[15:0];
			oe_r <= 1;
			we_r <= 1;
			state <= 0;
			end
			default: state <= 0;
		endcase
	end
end


    
// ��������״̬��
reg [3:0]rec_state = 0;
always @(posedge clk_50M) begin
	received_done <= 0;//Ĭ����0
	 // ������յ�һ֡���ݣ��������η��ڻ�������
		case (rec_state)
			4'b0000: if (uart_dataready) begin rdn_r <= 0; wrn_r <= 1; rec_state <= 4'b0001; end
			4'b0001: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[31:24] <= data[7:0]; rec_state <= 4'b0010; end
			4'b0010: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[23:16] <= data[7:0]; rec_state <= 4'b0011; end
			4'b0011: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[15:8] <= data[7:0]; rec_state <= 4'b0100; end
			4'b0100: begin data_received[7:0] <= data[7:0]; received_done <= 1; rec_state <= 4'b0000; end
			default: rec_state <= 0;
		endcase

end

/*always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end*/

reg tra_state = 0;
always @(posedge clk_50M) begin
		case(tra_state)
			4'b0000: if (send_begin && !uart_tbre) begin // �����æ�����п�ʼ�����ź�
				data[7:0] <= data_received[31:24];
				rdn_r <= 1; wrn_r <= 0; 
				send_begin <= 0;//����ʼ�����ź���Ϊ��
				tra_state <= 1;
			end
			else begin
				tra_state <= 0;
			end
			4'b0001: if (!uart_tbre && uart_tsre) begin
				data[7:0] <= data_received[23:16];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 2;
			end
			4'b0010:
			if (!uart_tbre && uart_tsre) begin
				data[7:0] <= data_received[15:8];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 3;
			end
			4'b0011:
			if (!uart_tbre && uart_tsre)begin
				data[7:0] <= data_received[7:0];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 0;
			end
			default: tra_state <= 0;

		endcase
	end
endmodule