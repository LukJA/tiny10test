/* playing around with software uart on the SDA pin 
   Use DAT
   Finely tuned to 19200 baud 
   8 data 1 stop
   lsb first */
// Uart output a byte
uart_byte:

	mov WOT, DAT			// value of DAT into WOT
	ldi LOP, 8				// init loop reg

	rcall low_PB1			// start condition is initially low

	ldi DEL, 4				// tuning delay
	rcall delay
	nop						// tuning delay
	nop

	u_a_s:
	dec LOP					// loop-- plays the data out over the bus one bit at a time

	sbrc WOT, 0				// skip the next line if WOT[0] = 0
		rcall high_PB1
	sbrs WOT, 0				// skip the next line if WOT[0] = 1
		rcall low_PB1
	lsr WOT					// left shift to the next bit to send
		
	ldi DEL, 3				// tuning delay
	rcall delay

	nop						// tuning delay
	nop
	nop

	cpi LOP, 0				// check if its 0 yet
	brne u_a_s				// if not go back to u_a_s

	nop						// tuning delay
	nop
	nop
	nop

	rcall high_PB1			// release control of SDA
	ret

// uart input a byte

uart_recieve:
	
	nop 

	ret