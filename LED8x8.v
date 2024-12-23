module LED8x8(output reg[7:0]DATA_R,DATA_G,DATA_B,
              output reg[3:0]COMM,output [6:0] seg,input [5:0] D,
				  input CLK,output reg [3:0] life,output reg beep);
	parameter logic[7:0] W_Char[7:0]=
	  '{8'b10111111,
	    8'b10111111,
		 8'b10111000,
		 8'b11111010,
		 8'b11111010,
		 8'b10111000,
		 8'b10111111,
		 8'b10111111};
	parameter logic[7:0] L_Char[7:0]=
	  '{8'b01111110,
	    8'b10111101,
		 8'b11011011,
		 8'b11100111,
		 8'b11100111,
		 8'b11011011,
		 8'b10111101,
		 8'b01111110};
	bit [3:0] score ;
	bit[2:0] cnt;
	reg [3:0] plat_1= 3'b000, plat_2=3'b001, plat_3=3'b010, ball_x=3'b001;
   reg [3:0] kplat_1 = 3'b000, kplat_2 = 3'b001, kplat_3 = 3'b010;
   reg [3:0] plat_pos = 3'b010;
   reg [3:0] last_status_d1 = 1'b0, last_status_d0 = 1'b0;
   reg start = 1'b0;
	reg stage_1 = 1;
	reg stage_2 = 0;
	reg up = 1;
	reg [1:0] remain_life = 3;
	reg [7:0] ball_y = 8'b00000010;
	reg [15:0] block = 16'b0100001001011010;
	reg [10:0] time_pass = 11'b0;
	reg [2:0] ball_status;
	reg [3:0] last_status_d4 = 1'b0;
   divfreq F0(CLK,CLK_div);
	initial begin
	 cnt=0;
	 score=4'b0;
	 DATA_R=8'b11111111;
	 DATA_G=8'b11111111;
	 DATA_B=8'b11111111;
	 COMM=4'b1000;
   end
	always@(posedge CLK_div)
	  begin 
	    time_pass <= time_pass + 1'b1; 
	    if(cnt>=7)
		   cnt=0;
		 else
		   cnt=cnt+1;
		 COMM={1'b1,cnt};
		 if(stage_2 == 0 && score == 7)
		  DATA_G=W_Char[cnt];
		 else if(remain_life!=0 || ball_y!=8'b00000000)
		  begin
	      if(cnt==plat_3 || cnt==plat_2 ||cnt==plat_1) DATA_R<=8'b11111110;	
	      else DATA_R = 8'b11111111;
	 
	      if (cnt==ball_x) DATA_G<=~ball_y;
	      else DATA_G = 8'b11111111;
	 
	 
	      if(block[cnt]==1 && block[cnt+8]==1) DATA_B <= 8'b00111111;
	      else if(block[cnt]==1 && block[cnt+8]==0) DATA_B <= 8'b01111111;
	      else if(block[cnt]==0 && block[cnt+8]==0) DATA_B <= 8'b11111111;
	      else if(block[cnt]==0 && block[cnt+8]==1) DATA_B <= 8'b10111111;
	     end
		 else
		   DATA_R=L_Char[cnt];
		 
		 //update status
	 plat_1 <= kplat_1 + plat_pos;
	 plat_2 <= kplat_2 + plat_pos;
	 plat_3 <= kplat_3 + plat_pos;
	 if(start==0)
	 begin
	 ball_x <= plat_2;
	 beep <= 0;
	 end
	 //restart重新開始
	 if(D[2]==1'b1)
	 begin
		plat_pos <= 3'b010;
		ball_y <= 8'b00000010;
		start <= 0;
		block <= 16'b0100001001011010;
		up <= 1;
		remain_life <= 3;
		beep <= 0;
		score <= 4'b0;
		stage_1 = 1;
	 end	
	 
	 //Life血量
	 if(remain_life==2'b11) life = 4'b1110;
	 else if(remain_life==2'b10) life = 4'b1100;
	 else if(remain_life==2'b01) life = 4'b1000;
	 else life = 4'b0000;
	 
	 
	 if(D[5]==0)
	 begin
//復活
	 if(D[4]==1 && last_status_d4==0 && remain_life!=0)
	 begin
		start <= 0;
		ball_x <= plat_2;
		ball_y <= 8'b00000010;
		remain_life <= remain_life - 1;
	 end

	 //平台左右移動
	 //plat right
 	 else if(D[1]==0 && last_status_d1==1 && plat_pos<5) plat_pos <= plat_pos + 1'b1;
	 //plat left
	 else if(D[0]==0 && last_status_d0==1 && plat_pos>0) plat_pos <= plat_pos - 1'b1;
	 //start game
	 else if(D[3]==1) start<=1;
	 
	 last_status_d1 <= D[1];	 
	 last_status_d0 <= D[0];
	 last_status_d4 <= D[4];
	  

	 //ball status
	if(start==1 && time_pass==11'b11111111111)
	begin
		beep <= 0;
		//ball raising
		if(up==1)
		begin
			if(ball_x == plat_1 && ball_y == 8'b00000010) ball_status=2'b0;
			else if(ball_x == plat_2 && ball_y == 8'b00000010) ball_status=2'b01;
			else if(ball_x == plat_3 && ball_y == 8'b00000010) ball_status=2'b10;
				
			if(ball_x==3'b000 && ball_x==plat_1 && ball_y==8'b00000010)
			begin
				ball_x <= ball_x+1;
				ball_y <= ball_y*2;
			end	
			else if(ball_x==3'b111 && ball_x==plat_3 && ball_y==8'b00000010)
			begin
				ball_x <= ball_x-1;
				ball_y <= ball_y*2;
			end
			else if(ball_status==0)
			begin
				if(ball_x == 3'b001 ) ball_status = 2'b10;
				ball_x <= ball_x-1;
				ball_y <= ball_y*2;
			end
			
			else if(ball_status==1)
			begin
				ball_y <= ball_y*2;
			end
			
			else if(ball_status==2)
			begin
				if(ball_x==3'b110 ) ball_status = 2'b0;
				ball_x <= ball_x+1;
				ball_y <= ball_y*2;
			end
			
			
		end
		
		//ball falling
		else 
		begin
		
			if(ball_status==0)
			begin
				if(ball_x==3'b001) ball_status = 2'b10;
				ball_x <= ball_x-1;
				ball_y <= ball_y/2;
			end
			
			else if(ball_status==1)
				ball_y <= ball_y/2;
				
			else if(ball_status==2)
			begin
				if(ball_x==3'b110) ball_status = 2'b0;
				ball_x <= ball_x+1;
				ball_y <= ball_y/2;
			end
			
		end
		time_pass <= 11'b0;
	end
	end
	
	 //hit detect(碰到磚塊或最高點)
	 if(ball_y==8'b01000000 && block[ball_x+8]==1)
	 begin
			block[ball_x+8]<=0;
			up <= 0;
			beep <= 1;
			if(stage_2==1)score<=score-1'b1;
			else score <= score + 1'b1;
	 end
	 else if(ball_y==8'b10000000 && block[ball_x]==1)
	 begin
		block[ball_x]<=0;
		up <= 0;
		beep <= 1;
		if(stage_2==1)score<=score-1'b1;
		else score <= score + 1'b1;
	 end
	 else if(ball_y==8'b00000010 && (plat_1==ball_x || plat_2==ball_x || plat_3 == ball_x))
	 begin
	 up <= 1;
	 if(start==1) beep <= 1;
	 end
	 else if(ball_y==8'b10000000)
	 begin
	 up<=0;
	 beep <= 1;
	 end;
	 
	 if(block == 16'b0 && stage_1 == 1)
	 begin
	   stage_2 = 1;
	   stage_1 = 0;
		ball_y <= 8'b00000010;
		start <= 0;
		block <= 16'b0101101000011000;
		up <= 1;
		beep <= 0;
	 end
	 else if(block == 16'b0 && stage_2 == 1)
	 begin
	   stage_2 = 0;
	   ball_y <= 8'b00000010;
		start <= 0;
		block <= 16'b0000000011111110;
		up <= 1;
		beep <= 0;
	 end

end 
	seg_behavior F1(seg,score);
endmodule 

module divfreq(input CLK,output reg CLK_div);
reg[24:0]Count;
always@(posedge CLK)
  begin
    if(Count>25000)
	   begin
		 Count<=25'b0;
		 CLK_div=~CLK_div;
		end
	 else
	   Count<=Count+1'b1;
	end
endmodule

module seg_behavior(
  output reg [6:0] seg,
  input [3:0] ABCD
);

  always @(*)
  begin
    case (ABCD)
      4'b0000: seg = 7'b0000001;
      4'b0001: seg = 7'b1001111;
      4'b0010: seg = 7'b0010010;
      4'b0011: seg = 7'b0000110;
      4'b0100: seg = 7'b1001100;
      4'b0101: seg = 7'b0100100;
      4'b0110: seg = 7'b0100000;
      4'b0111: seg = 7'b0001111;
      4'b1000: seg = 7'b0000000;
      4'b1001: seg = 7'b0000100;
      default: seg = 7'b1111111;
    endcase
  end
endmodule 



	