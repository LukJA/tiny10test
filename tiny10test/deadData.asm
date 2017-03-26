//load dead values for testing
ldi EEL, 0x01

ldi DAT, 0x31
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x32
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x3A
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x33
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x35
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x20
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x36
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x2f
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x37
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x2f
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x31
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x36
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x20
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x4C
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x36
rcall EEP_WRITE_BYTE

ldi DEL, 255
ldi DELH, 10
rcall delayL

inc EEL
ldi DAT, 0x40
rcall EEP_WRITE_BYTE
ldi EEL, 0x00