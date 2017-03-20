// SUBROUTINES:

// I2C Low Level

/* Pull the SDA line low */
low_SDA:				// SDA -> GND

	in  GPR, DDRB		// read DDR 
	ori  GPR, (1<<SDA)  // add SDA set bit
	out DDRB, GPR		// set sda output

	in  GPR, PORTB		// read portb 
	andi GPR, ~(1<<SDA) // mask SDA bit
	out PORTB, GPR		// set output low

	ret
	
/* Allow the SDA line to tristate (ext Pull-Up) */
high_SDA:				// SDA -> tristate

	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<SDA) // mask SDA bit
	out DDRB, GPR		// set sda input

	ret
	
/* Pull the SCL line low */
low_SCL:				// SCL -> GND

	in  GPR, DDRB		// read DDR 
	ori  GPR, (1<<SCL)  // add SCL set bit
	out DDRB, GPR		// set scl output

	in  GPR, PORTB		// read portb 
	andi GPR, ~(1<<SCL) // mask SCL bit
	out PORTB, GPR		// set output low

	ret
	
/* Allow the SDA line to tristate (ext Pull-Up) */
high_SCL:				// SCL -> tristate

	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<SCL) // mask SCL bit
	out DDRB, GPR		// set scl input

	ret

/* read the current level of SDA into the RBitr reg masking to SDA only */
read_SDA:
	
	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<SDA) // mask SDA bit
	out DDRB, GPR		// set sda input

	in  RBitr, PINB		// read pinB into RBitr
	andi RBitr, (1<<SDA)// mask to SDA

	ret
	
/* read the current level of SCL into the RBitr reg masking to SCL only */
read_SCL:
	
	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<SCL) // mask SCL bit
	out DDRB, GPR		// set scl input

	in  RBitr, PINB		// read pinB into RBitr
	andi RBitr, (1<<SCL)// mask to SDA

	ret

/* read the current level of PB1 into the RBitr reg masking to PB1 only */
read_PB1:
	
	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<PB1) // mask SCL bit
	out DDRB, GPR		// set scl input

	in  RBitr, PINB		// read pinB into RBitr
	andi RBitr, (1<<PB1)// mask to SDA

	ret

	/* Pull the SDA line low */
low_PB1:				// SDA -> GND

	in  GPR, DDRB		// read DDR 
	ori  GPR, (1<<PB1)  // add SDA set bit
	out DDRB, GPR		// set sda output

	in  GPR, PORTB		// read portb 
	andi GPR, ~(1<<PB1) // mask SDA bit
	out PORTB, GPR		// set output low

	ret
	
/* Allow the SDA line to tristate (ext Pull-Up) */
high_PB1:				// SDA -> tristate

	in  GPR, DDRB		// read DDR 
	andi GPR, ~(1<<PB1) // mask SDA bit
	out DDRB, GPR		// set sda input

	ret


// I2C High Level

/* Perform a start condition or restart condition, performs both */
start_condition:

	rcall high_SDA		// SDA high <- allows for restart to use same call
	rcall high_SCL		// SCL high 
	
	nop					// take a real quick break (no op)
	
	rcall low_SDA		// SDA low BEFORE
	nop					// break
	rcall low_SCL		// SCL low NEXT
	nop					// break
	
	ret

/* perform a stop condition */
stop_condition:

	rcall low_SDA		// just make sure
	nop					// break
	rcall high_SCL		// SCL high BEFORE
	nop					// break
	rcall high_SDA		// SDA high NEXT

	ret

/* write the MSB of the WOT to the SDA pin and pulse the clock */
write_bit:	

	sbrc WOT, 7			// skip the next line if WOT[7] = 0
		rcall high_SDA
	sbrs WOT, 7			// skip the next line if WOT[7] = 1
		rcall low_SDA
			
	rcall high_SCL		// pulse clock
	nop
	rcall low_SCL

	ret
	
/* read the current level of SDA and insert it into RBitr[0]
   seperated from RBytr so that this can be used for ack/nack */
read_bit:

	nop
	rcall high_SCL		// clock up to lock data
	nop

	rcall read_SDA		// read SDA into RBitr

	clr GPR			
	sbrc RBitr, SDA		// skip the next line if SDA bit in RBitr is cleared
	ldi  GPR, 0x1		
	mov RBitr, GPR		// set the LSB of RBitr to be the value of SDA

	nop
	rcall low_SCL		// clock down to accept new data

	ret

/* write the contents of WOT the I2C line */
write_byte:

	ldi LOP, 8		// init loop reg

	w_b_s:
	dec LOP			// loop--

	rcall write_bit // write the MSB to the bus
	lsl WOT			// left shift to the next bit to send

	cpi LOP, 0		// check if its 0 yet
	brne w_b_s		// if not go back to w_b_s

	rcall high_SDA	// release control of SDA
	ret

/* read a byte of data from the bus via read_bit, and store the result in RBytr */
read_byte:

	ldi LOP, 8		// init loop reg

	clr GPRB		// clean GPRB for use (GPR is used in read_bit)

	r_b_s:
	dec LOP			// loop--

	rcall read_bit	// read a bit into RBitr
	lsl GPRB		// shift the GP to the left to free the next spot
	or GPRB, RBitr	// move the read bit into said spot

	cpi LOP, 0		// check if its 0 yet
	brne r_b_s		// if not go back to r_b_s

	mov RBytr, GPRB // move the new read byte into its designated reg
	ret

// end I2C 