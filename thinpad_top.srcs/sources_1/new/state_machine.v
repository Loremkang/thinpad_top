`default_nettype wire
module state_machine(
	input clk_50M,
	input clk,
	input rst,

	output reg[15:0] leds,
	inout [31:0] data,
	output reg[19:0] address,
	input [31:0] push_buttons,

	output reg oe, 
	output reg we,

	input rxd,
	output txd
	);

reg [3:0] state = 0;//״̬����״̬
reg [31:0] data_received;// ���ܵ�����������
reg [19:0] address_buffer;// �洢�ĵ�ַ
reg received_done = 0; // �Ƿ�32λ�����Ѿ��������
reg send_begin = 0;// �Ƿ�ʼ��������

reg oe_r = 1;
reg we_r = 1;// Ĭ�ϲ�ʹ��

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
			we <= 0;//д����
			state <= 4'b0011;
			end
			4'b0011: begin
			we <= 1;
			address <= push_buttons;
			state <= 4'b0100;
			end
			4'b0100: begin
			oe <= 0;
			state <= 4'b0101;
			end
			4'b0101: begin
			data_received <= data;//�����������ݷŵ�������
			leds <= data[15:0];
			oe <= 1;
			state <= 0;
			end
			default: state <= 0;
		endcase
	end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_ready),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );
    
// ��������״̬��
reg [3:0]rec_state = 0;
always @(posedge clk_50M) begin
	received_done <= 0;//Ĭ����0
	if(ext_uart_ready)begin // ������յ�һ֡���ݣ��������η��ڻ�������
		case (rec_state)
			4'b0000: begin data_received[31:24] <= ext_uart_rx; rec_state <= 4'b0001; end
			4'b0001: begin data_received[23:16] <= ext_uart_rx; rec_state <= 4'b0010; end
			4'b0010: begin data_received[15:8] <= ext_uart_rx; rec_state <= 4'b0011; end
			4'b0100: begin data_received[7:0] <= ext_uart_rx; received_done <= 1; rec_state <= 4'b0000; end
			default: rec_state <= 0;
		endcase
	end
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
			4'b0000: if (send_begin && !ext_uart_busy) begin // �����æ���ҿ�ʼ����
				ext_uart_tx <= data[31:24];
				ext_uart_start <= 1;
				send_begin <= 0;//����ʼ�����ź���Ϊ��
				tra_state <= 1;
			end
			else begin
				tra_state <= 0;
			end
			4'b0001: if (ext_uart_busy) begin
				tra_state <= 1;
			end
			else begin
				ext_uart_tx <= data[23:16];
				ext_uart_start <= 1;
				tra_state <= 2;
			end
			4'b0010:
			if (ext_uart_busy) begin
				tra_state <= 4'b0010;
			end
			else begin
				ext_uart_tx <= data[15:8];
				ext_uart_start <= 1;
				tra_state <= 3;
			end
			4'b0011:
			if (ext_uart_busy) begin
				tra_state <= 4'b0011;
			end
			else begin
				ext_uart_tx <= data[7:0];
				ext_uart_start <= 1;
				tra_state <= 0;
			end
			default: tra_state <= 0;

		endcase
	end


async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );
endmodule