;
; tiny10test.asm
;
; Created: 22/11/2016 21:30:59
; Author : lukej
;

//--------------------------------------------- defines 

.equ SDA = PB2 // define pins
.equ SCL = PB0

// LIS register addresses
.equ LIS_W = 0B00110000 // lis addr + write
.equ LIS_R = 0B00110001 // lis addr + read

.equ CTRL_REG1 = 0x20
.equ CTRL_REG2 = 0x21
.equ CTRL_REG3 = 0x22
.equ CTRL_REG4 = 0x23
.equ CTRL_REG5 = 0x24
.equ CTRL_REG6 = 0x25

.equ INT1_CFG  = 0x30
.equ INT1_SRC  = 0x31
.equ INT1_THS  = 0x32
.equ INT1_DURATION = 0x33

// EEPROM address registers
.equ EEP_W = 0B10100000 // eeprom addr + write
.equ EEP_R = 0B10100001 // eeprom addr + read

// PCF address registers
.equ PCF_W = 0B10100010 // pcf + write
.equ PCF_R = 0B10100011 // pcf + read

.equ CTRL_STAT_1 = 0x00
.equ CTRL_STAT_2 = 0x01
.equ VL_seconds	= 0x02
.equ Minutes	= 0x03
.equ Hours		= 0x04
.equ Days		= 0x05
.equ Weekdays	= 0x06
.equ Century_months	= 0x07
.equ Years		= 0x08
.equ CLKOUT_control	= 0x0D
.equ Timer_control	= 0x0E
.equ Timer		= 0x0F

// internal 
.def GPR = r16 // General purpose Reg (local) (assume nothing)
.def GPRB = r23 // General purpose Reg B (local) (assume nothing)
.def LOP = r17 // Register for loops

.def RBitr = r18 // bit read reg
.def RBytr = r19 // byte read reg

.def WOT = r20 // write flow reg
.def SAD = r21 // Sub address storage
.def DAT = r22 // data storage

.def DEL = r24 // delay reg
.def DELH = r25 // delay higher reg

// 26,27 used for pointing to sram

.def WPS = r28 // watchdog prescaler

.def EEH = r31  // we will be using the Z reg for addressing the EEprom
.def EEL = r30  // Low bit too

.def EEC = r29	// current address holder

//--------------------------------------------

rjmp skip				// making room for the interupt vector tables

.org PCI0addr			// INT0addr is the address of EXT_INT0
rjmp PCI0_vect			// so run the handler
.org WDTaddr			// WDTaddr is the address of the WDT timeout
rjmp WDT_vect			// so run the handler

skip:

// CODE TO RUN: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

// Setup the LIS3DH --

// enable all axes, normal mode 100Hz rate
ldi SAD, CTRL_REG1
ldi DAT, 0xA7
rcall LIS_CMD

// disable the HP filter
//ldi SAD, CTRL_REG2
//ldi DAT, 0x00
//rcall LIS_CMD

// Int driven to INT1 pin
ldi SAD, CTRL_REG3
ldi DAT, 0x40
rcall LIS_CMD

// Full Scale = 16G
ldi SAD, CTRL_REG4
ldi DAT, 0x30
rcall LIS_CMD

// Interupt latched 
// commenting out will remove latching effect
//ldi SAD, CTRL_REG5
//ldi DAT, 0x08
//rcall LIS_CMD

// threshold absolute 
ldi SAD, INT1_THS
ldi DAT, 0x7F
rcall LIS_CMD

// Set minimum duration to x <- this is effectively sensitivity
ldi SAD, INT1_DURATION
ldi DAT, 0x09
rcall LIS_CMD

// interrupt generation on all axis
ldi SAD, INT1_CFG
ldi DAT, 0x0A
rcall LIS_CMD

// ---------------


ldi EEH, 0x00		// set location 0
ldi EEL, 0x00		// set location 0

ldi EEC, 0x00

inc EEC		// increment location


// ---------------

// set up all interupts
cli

// enable wdt to blink slowly   
ldi WPS, 0B0110		// highest timeout 
clr GPR
out WDTCSR, GPR			// clean up
rcall load_prescaler

// enable pin change int on SCL for button, PB1 for LIS

clr GPR
ldi GPR, 0B0011
out PCMSK, GPR
ldi GPR, 0B0001
out PCICR, GPR


// ----------------------
#include "deadData.asm"

sei
start:				// main loop

ldi GPR, 0B0101		// Sleep code
out SMCR, GPR		// set sleep mode to power down + enable
sleep

rjmp start

// ----------------------

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




// Interrupt vectors

// LIS threshhold exceeded interupt OR button pressed interupt
PCI0_vect:

	cli
	
	rcall read_SCL	// read the pin to check if it was the button

	sbrs RBitr, SCL	// if it was run button
	rcall button_event // button

	rcall read_PB1 // read to see if it was the accelerometer

	sbrs RBitr, PB1 // if it was run accel
	rcall accel_event

	ldi DEL, 255				// TAKE 5
	rcall delay

	sei

	reti // esc

// Periodic watchdog interupt
WDT_vect:

	cli

	rcall low_SDA // pulse led 

	in GPR, WDTCSR		// clear the watchdog
	ori GPR, (1<<WDIE)
	ori GPR, (1<<WDE)
	out WDTCSR, GPR

	ldi DEL, 255 // delay		
	rcall delay

	ldi DEL, 255 // delay			 
	rcall delay

	rcall high_SDA // pulse led
	
	sei

	reti


// include i2c external library
#include "i2clib.asm"
// include uart external library
#include "uartlib.asm"


// User routines

/* just something to delay by twice the number in DEL */
delay:
	d_s:
	dec DEL
	nop
	nop
	cpi DEL, 0
	brne d_s

	ret

delayL:
	dLH_s:
	dec DELH
	dL_s:
	dec DEL
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	cpi DEL, 0
	brne dL_s
	cpi DELH, 0
	brne dLH_s

	ret

/* Read command for LIS3DH 
   reads sub-address SAD into RBytr */
LIS_READ:

	rcall start_condition	// start con

	ldi WOT, LIS_W			// lis addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 10				// TAKE 5
	rcall delay

	mov WOT, SAD			// value of SAD (sub address in lis reg file) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	rcall start_condition	// repeated start con

	ldi WOT, LIS_R			// lis addr + read slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 5				// TAKE 5
	rcall delay
 
	rcall read_byte			// read a byte into RBytr for use 
	rcall read_bit			// Master Not Acknowledge 

	rcall stop_condition	// stop con

	ret

/* Write command for LIS3DH 
   writes DAT into sub-address SAD */
LIS_CMD:	 

	rcall start_condition	// start con

	ldi WOT, LIS_W			// lis addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	mov WOT, SAD			// value of SAD (sub address in lis reg file) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	mov WOT, DAT			// value of DAT into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	rcall stop_condition	// stop con

	ldi DEL, 20
	rcall delay

	ret


/* Read byte from eeprom
   Address located in Z
   Result stored on RBytr*/
EEP_READ_BYTE:

	rcall start_condition	// start con

	ldi WOT, EEP_W			// EEP addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 10				// TAKE 5
	rcall delay

	mov WOT, EEH			// value of EEH (memory high byte) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	mov WOT, EEL			// value of EEL (memory low byte) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	rcall start_condition	// repeated start con

	ldi WOT, EEP_R			// EEP addr + read slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 5				// TAKE 5
	rcall delay
 
	rcall read_byte			// read a byte into RBytr for use 
	rcall read_bit			// Master Not Acknowledge 

	rcall stop_condition	// stop con

	ret

/* Write byte to eeprom
   Address located in Z
   Data locate in DAT	*/
EEP_WRITE_BYTE:

	rcall start_condition	// start con

	ldi WOT, EEP_W			// EEP addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 10				// TAKE 5
	rcall delay

	mov WOT, EEH			// value of EEH (memory high byte) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	mov WOT, EEL			// value of EEL (memory low byte) into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	mov WOT, DAT			// value of DAT into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	rcall stop_condition	// stop con

	ret

PCF_READ_TIME:

	ldi r27, 0x00			// set sram pointer to ramstart
	ldi r26, 0x40
	
	rcall start_condition	// start con

	ldi WOT, PCF_W			// PCF addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 10				// TAKE 5
	rcall delay

	ldi WOT, VL_seconds		// set address pointer to VL_seconds
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	rcall start_condition	// start con

	ldi WOT, PCF_R			// PCF addr + write slave identifier into WOT
	rcall write_byte		// Write the above to the bus
	rcall read_bit			// slave Acknowledge (no error checking yet)

	ldi DEL, 5				// TAKE 5
	rcall delay


	ldi LOP, 7				// set the loop to 7 variables
 
	pcf_l_b:

	rcall read_byte			// read a byte into RBytr for use 
	rcall read_bit			// Master Not Acknowledge 

	ST X+, RBytr			// store each successive in sram
	DEC LOP					// lop--;

	cpi LOP, 0				// if its 0 move on
	brne pcf_l_b

	rcall stop_condition	// stop con

	ret



load_prescaler: // reduces prescaler by 1 each time the sub is run by "blink faster" 

	wdr

	clr GPR
	out WDTCSR, GPR			// clean up the wtachdog registers

	in GPR, WDTCSR			// load the clean one

	mov GPRB, WPS			// do the requisite maths an=d bit setting
	andi GPRB, 0B0111
	or GPR, GPRB

	mov GPRB, WPS
	lsl GPRB
	lsl GPRB
	andi GPRB, 0B00100000
	or GPR, GPRB

	out WDTCSR, GPR

	in GPR, WDTCSR
	ori GPR, (1<<WDIE)
	andi GPR, ~(1<<WDE)
	out WDTCSR, GPR			// loads watchdog register

	ret

blink_faster:	// decrements the prescaler and reloads the watchdog

	dec WPS
	sbrc WPS,7
	ldi WPS, 0x09

	mov DAT, WPS
	rcall load_prescaler

	ret

accel_event:	// runs whenever the accelerometer is knocked, saves data to memory
	
	rcall blink_faster		// up the prescaler 

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x48
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x65
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x6c
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x6c
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x6f
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x21
	rcall EEP_WRITE_BYTE

	ldi DEL, 255
	rcall delay

	mov EEL, EEC
	inc EEC
	ldi DAT, 0x40
	rcall EEP_WRITE_BYTE

	ret

button_event:	// runs whenever the button is pressed, dumps data over uart

	ldi DEL, 255			// set wait 

	wait:					// wait until the button is released
	rcall read_SCL
	cpi RBitr, (1<<SCL)
	brne wait

	rcall delay				// wait a bunch

	ldi WPS, 0x09
	mov DAT, WPS
	rcall load_prescaler	// clear the prescaler

	ldi LOP, 0x00			// clear loop var and memory locations
	ldi EEH, 0x00		
	ldi EEL, 0x00


	// loop through every memory address and send contents over uart
	BYL_s:
	inc LOP
	inc EEL

	rcall EEP_READ_BYTE

	mov DAT, RBytr
	rcall uart_byte

	cpi RBytr, 0x40
	breq end 

	cpi LOP, 255
	brne BYL_s
	end:

	ret

	


	