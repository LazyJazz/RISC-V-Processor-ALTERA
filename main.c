void print(int v) {
	int * x = (int *) 0x4000;
	*x = v;
}

int read_keypad() { return *((int*)0x00010000); }
int read_switch() { return *((int*)0x00010004); }
int read_button() { return *((int*)0x00010008); }
unsigned long long read_clock() { return *((unsigned long long *)0x00010010); }

char ascii_to_chc(char ascii)
{
	switch (ascii)
	{
		case 'O' : case '0' : return 0b11111100;
		case '1' : return 0b01100000;
		case '2' : return 0b11011010;
		case '3' : return 0b11110010;
		case '4' : return 0b01100110;
		case '5' : return 0b10110110;
		case '6' : return 0b10111110;
		case '7' : return 0b11100000;
		case '8' : return 0b11111110;
		case '9' : return 0b11110110;
		case 'A' : case 'a' : return 0b11101110;
		case 'B' : case 'b' : return 0b00111110;
		case 'C' : case 'c' : return 0b10011100;
		case 'D' : case 'd' : return 0b01111010;
		case 'E' : case 'e' : return 0b10011110;
		case 'F' : case 'f' : return 0b10001110;
		case 'P' : case 'p' : return 0b11001110;
		case 'H' : return 0b01101110;
		case 'h' : return 0b00101110;
		case 'L' : return 0b00011100;
		case 'l' : return 0b00001100;
		case 'o' : return 0b00111010;
		case 'R' : case 'r' : return 0b00001010;
		case 'U' : return 0b01111100;
		case 'u' : return 0b00111000;
		case 'J' : return 0b01110000;
	}
	return 0;
}

void Sleep_Cycle(unsigned long long clock)
{
	unsigned long long start_clk = read_clock();
	while (read_clock() < start_clk + clock);
}

void Sleep(unsigned long long millisec)
{
	Sleep_Cycle(millisec * 5000);
}

void print_chars(const char *a)
{
	print(((int)ascii_to_chc(a[0]) << 24) | ((int)ascii_to_chc(a[1]) << 16) | ((int)ascii_to_chc(a[2]) << 8) | (int)ascii_to_chc(a[3]));
}

#define BUTTON_DOWN 0
#define BUTTON_UP 1
#define KEYPAD_DOWN 2
#define KEYPAD_UP 3
#define KEY_A 0x0
#define KEY_B 0xC
#define KEY_C 0x8
#define KEY_D 0x4
#define KEY_0 0x6
#define KEY_1 0x3
#define KEY_2 0x2
#define KEY_3 0x1
#define KEY_4 0xf
#define KEY_5 0xe
#define KEY_6 0xd
#define KEY_7 0xb
#define KEY_8 0xa
#define KEY_9 0x9
#define KEY_STAR 0x7
#define KEY_POUND 0x5

int money = 0;
int state = 0;
/*
0: Show Coin
1: Print Price
-1: Error
2: BYE
*/
unsigned long long log_clk;
int sel = -1;
int err_code;

int price_list[10] = {0, 15, 25, 20, 10, 50, 30, 20, 40, 40};
char print_buffer[4];

void ReportError(int code)
{
	err_code = code;
	state = -1;
	log_clk = read_clock();
}

void AddCoin(int coin)
{
	if (money + coin > 999) ReportError(0);
	else money += coin, state = 0;
}

void Quit()
{
	state = 4;
	log_clk = read_clock();
}

void SelItem(int item)
{
	state = 1;
	sel = item;
}

void Confirm()
{
	if (state != 1) return;
	if (money >= price_list[sel])
	{
		money -= price_list[sel];
		state = 3;
		log_clk = read_clock();
	}
	else
		ReportError(1);
}

void Cancel()
{
	state = 0;
}

void MsgProc(unsigned int Msg, unsigned int param)
{
	switch (Msg)
	{
		case KEYPAD_DOWN:
			switch (param)
			{
				case KEY_1: SelItem(1); break;
				case KEY_2: SelItem(2); break;
				case KEY_3: SelItem(3); break;
				case KEY_4: SelItem(4); break;
				case KEY_5: SelItem(5); break;
				case KEY_6: SelItem(6); break;
				case KEY_7: SelItem(7); break;
				case KEY_8: SelItem(8); break;
				case KEY_9: SelItem(9); break;
				case KEY_STAR: Cancel(); break;
				case KEY_POUND: Confirm(); break;
			}
			break;
		case BUTTON_DOWN:
			switch (param)
			{
				case 0: AddCoin(5); break;
				case 1: AddCoin(10); break;
				case 2: AddCoin(50); break;
				case 3: Quit(); break;
			}
			break;
	}
}

unsigned int button_hold[4];
unsigned int button_held[4];
unsigned int keypad_hold[16];
unsigned int keypad_held[16];

void PollEvent()
{
	int keypad_state = read_keypad();
	int button_state = read_button()^0b1100;
	for (int i = 0; i < 4; i++)
	{
		if (button_state & (1 << i))
		{
			if (button_hold[i] < 4) button_hold[i]++;
		}
		else
			button_hold[i] = 0;
		if (button_hold[i] == 4)
		{
			if (!button_held[i]) MsgProc(BUTTON_DOWN, i);
			button_held[i] = 1;
		}
		else
		{
			if (button_held[i]) MsgProc(BUTTON_UP, i);
			button_held[i] = 0;
		}
	}
	for (int i = 0; i < 16; i++)
	{
		if (keypad_state & (1 << i))
		{
			if (keypad_hold[i] < 4) keypad_hold[i]++;
		}
		else
			keypad_hold[i] = 0;
		if (keypad_hold[i] == 4)
		{
			if (!keypad_held[i]) MsgProc(KEYPAD_DOWN, i);
			keypad_held[i] = 1;
		}
		else
		{
			if (keypad_held[i]) MsgProc(KEYPAD_UP, i);
			keypad_held[i] = 0;
		}
	}
}

void UpdateState()
{
	if (log_clk + 5000000ull <= read_clock() && ((state == -1) || (state == 2) || (state == 3))) state = 0;
	if (log_clk + 1665000ull <= read_clock() && (state == 4))
	{
		if (!money) state = 2;
		else
		{
			if (money >= 50) money -= 50;
			else if (money >= 10) money -= 10;
			else if (money >= 5) money -= 5;
		}
		log_clk = read_clock();
	}
}

void Update()
{
	PollEvent();
	UpdateState();
}

void Render()
{
	int price;
	switch(state)
	{
		case -1 :
			print_buffer[0] = ascii_to_chc('E');
			print_buffer[1] = ascii_to_chc('r');
			print_buffer[2] = ascii_to_chc('r');
			print_buffer[2] |= 0b00000001;
			print_buffer[3] = ascii_to_chc('0' + err_code);
			break;
		case 0 :
		case 4 :
			print_buffer[0] = ascii_to_chc('C');
			if (money > 99)
				print_buffer[1] = ascii_to_chc('0' + (money / 100) % 10);
			else
				print_buffer[1] = 0;
			print_buffer[2] = ascii_to_chc('0' + (money / 10) % 10);
			print_buffer[2] |= 0b00000001;
			print_buffer[3] = ascii_to_chc('0' + money % 10);
			break;
		case 1 :
			price = price_list[sel];
			print_buffer[0] = ascii_to_chc('P');
			if (price > 99)
				print_buffer[1] = ascii_to_chc('0' + (price / 100) % 10);
			else
				print_buffer[1] = 0;
			print_buffer[2] = ascii_to_chc('0' + (price / 10) % 10);
			print_buffer[2] |= 0b00000001;
			print_buffer[3] = ascii_to_chc('0' + price % 10);
			break;
		case 2 : print_buffer[0] = ascii_to_chc('5'),print_buffer[1] = ascii_to_chc('E'),print_buffer[2] = (ascii_to_chc('E') | 1),print_buffer[3] = ascii_to_chc('U'); break;
		case 3 :
			price = price_list[sel];
			print_buffer[0] = ascii_to_chc('5');
			print_buffer[1] = ascii_to_chc('o');
			print_buffer[2] = ascii_to_chc('l');
			print_buffer[3] = ascii_to_chc('d');
			print_buffer[3] |= 0b00000001;
			break;
	}
	int printv = ((int)print_buffer[0] << 24) | ((int)print_buffer[1] << 16) | ((int)print_buffer[2] << 8) | ((int)print_buffer[3]);
	print(printv);
}

void print_str(const char * str)
{
	int len = 0;
	while (str[len]) len++;
	for (int i = 0; !i || i + 3 < len; i++)
	{
		char pchars[4] = {};
		pchars[0] = str[i];
		if (i + 1 < len) pchars[1] = str[i + 1];
		if (i + 2 < len) pchars[2] = str[i + 2];
		if (i + 3 < len) pchars[3] = str[i + 3];
		print_chars(pchars);
		Sleep(200);
	}
}

int main()
{
	//print_str("0123456789ABCDEF");
	while (1)
	{
		Update();
		Render();
	}//*/
	return 0;
}