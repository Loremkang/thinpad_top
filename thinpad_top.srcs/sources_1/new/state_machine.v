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

	output txd,
	input rxd,

	    //CPLD���ڿ������ź�
    output uart_rdn,         //�������źţ�����Ч
    output uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre        //���ݷ�����ϱ�־
	);

reg [3:0] state = 0;//״̬����״̬
reg [31:0] data_received;// �Ӵ��ڽ��յ������ݵĻ�����
reg [31:0] data_ram; // �Ӵ洢���������ݵĻ�����
reg [19:0] address_buffer;// �洢�ĵ�ַ
reg received_done = 0; // �Ƿ�32λ�����Ѿ��������
reg send_begin = 0;// �Ƿ�ʼ��������

reg oe_r = 1, we_r = 1;

assign oe = oe_r;
assign we = we_r;//�ڴ��дʹ��

reg rdn_r = 1, wrn_r = 1;
assign uart_rdn = rdn_r;
assign uart_wrn = wrn_r;//���ڶ�дʹ��

reg [31:0] data_w; //д���ݻ���
reg [31:0] data_r; //�����ݻ���

wire [7:0] ext_uart_rx; // ���յ��Ĳ�������
reg  [7:0] ext_uart_buffer, ext_uart_tx; // ���յ������ݵĻ������������͵����ݻ�����
wire ext_uart_ready, ext_uart_busy; // �Ƿ��Ѿ����յ�һ֡���������ݣ��Ƿ����ڷ�����æ
reg ext_uart_start, ext_uart_avai; // �Ƿ�ʼ���ͻ������е��źţ��Ƿ������Ѿ�����

assign  data = (we_r == 0 || wrn_r == 0)? data_w: 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz; // д��ʱ���ó�data_w,�����óɸ���̬

always @(oe_r, rdn_r)
if(oe_r == 0 || rdn_r == 0)
data_r = data;// �����ݻ���



always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		state <= 0;
	end
	else if (clk) begin
		case(state)
			4'b0000:begin //״̬1����ʼ�Ӵ����н�������
			 if (uart_dataready) begin
			// data <= data_received;
			// leds <= data_received[15:0];
			rdn_r <= 0;//��ʼ����������
			wrn_r <= 1;
			state <= 4'b0110;	
			end
			else begin
			    // leds <= data_received[15:0];
				state <= 0;
			end
			end
			4'b0110:begin//״̬2����ʾ�Ӵ����еõ�������
			data_w <= data_r[7:0];
			leds[7:0] <= data_r[7:0];
			rdn_r <= 1;//����ʹ����Ϊ1
			state <= 4'b0001;
			end
			4'b0001: begin //3�����ղ���ʾ�Ӳ��뿪�صõ������ݵ�ַ
			address <= push_buttons[19:0];
			leds <= push_buttons[15:0];
			state <= 4'b0010;
			end
			4'b0010: begin//4����ʼд����
			rdn_r <= 1;
			wrn_r <= 1;
			we_r <= 0;//д����
			oe_r <= 1;
			state <= 4'b0011;
			end
			4'b0011: begin//5�����ղ���ʾ�Ӳ��뿪�ػ�õĵ�ַ
			we_r <= 1;
			oe_r <= 1;
			address <= push_buttons;
			state <= 4'b0100;
			end
			4'b0100: begin//6����ʼ��
			rdn_r <= 1;
			wrn_r <= 1;
			oe_r <= 0; // ������
			we_r <= 1;
			state <= 4'b0101;
			end
			4'b0101: begin//7����ʾ����������
			data_w <= data_r;//�����������ݷŵ�������
			leds <= data_r[15:0];//��ʾ���ڴ��ж���������
			// leds <= data_r[15:0];
			oe_r <= 1;
			we_r <= 1;
			state <= 4'b0111;
			end
			4'b0111:begin //8�������������ݷ���ȥ
			wrn_r <= 0; //��ʼ���ʹ���
			rdn_r <= 1;
		    state <= 4'b1000;
			end
			4'b1000:begin
			wrn_r <= 1;
			rdn_r <= 1;
			state <= 4'b0000;
			end
			default: state <= 0;
		endcase
	end
end


    
// ��������״̬��
/*reg [3:0]rec_state = 0;
always @(posedge clk_50M) begin
	received_done <= 0;//Ĭ����0
	 // ������յ�һ֡���ݣ��������η��ڻ�������
	 //leds[3:0] <= rec_state;
	 rdn_r <= 0;
	 leds[4] <= uart_dataready;
		case (rec_state)
			4'b0000: if (uart_dataready) begin rdn_r <= 0; wrn_r <= 1; rec_state <= 4'b0001; end
			4'b0001: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[31:24] <= data_r[7:0]; rec_state <= 4'b0010; end
			4'b0010: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[23:16] <= data_r[7:0]; rec_state <= 4'b0011; end
			4'b0011: if (uart_dataready)begin rdn_r <= 0; wrn_r <= 1; data_received[15:8] <= data_r[7:0]; rec_state <= 4'b0100; end
			4'b0100: begin data_received[7:0] <= data_r[7:0]; received_done <= 1; rec_state <= 4'b0000; end
			default: rec_state <= 0;
		endcase

end*/

/*always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end*/

/*reg tra_state = 0;
always @(posedge clk_50M) begin
		case(tra_state)
			4'b0000: if (send_begin && !uart_tbre) begin // �����æ�����п�ʼ�����ź�
				data_w[7:0] <= data_ram[31:24];
				rdn_r <= 1; wrn_r <= 0; 
				send_begin <= 0;//����ʼ�����ź���Ϊ��
				tra_state <= 1;
			end
			else begin
				tra_state <= 0;
			end
			4'b0001: if (!uart_tbre && uart_tsre) begin
				data_w[7:0] <= data_ram[23:16];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 2;
			end
			4'b0010:
			if (!uart_tbre && uart_tsre) begin
				data_w[7:0] <= data_ram[15:8];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 3;
			end
			4'b0011:
			if (!uart_tbre && uart_tsre)begin
				data_w[7:0] <= data_ram[7:0];
				rdn_r <= 1; wrn_r <= 0; 
				tra_state <= 0;
			end
			default: tra_state <= 0;

		endcase
	end*/
endmodule