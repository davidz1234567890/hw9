CONTROL_REG .EQU $0012
STATUS_REG .EQU $0014
DATA_REG .EQU $0020

        .ORG $2000
ARRAY   .DW $0
        .DW $0
        .DW $0
        .DW $0
        .DW $0
        .DW $0
        .DW $0
        .DW $0

        .ORG $1000
START   LI R6, $0 ; array_offset <- 0
        LI R7, $0 ; num_attempts <- 0 to start
INIT    LI R3, $0001 ; loads enable bit = 1
        SW R0, R3, CONTROL_REG ; stores enabled bit in CONTROL_REG
        LI R4, $0002 ; loads read bit = 1
        OR R3, R3, R4 ; makes the bit mask 0000 0000 0000 0011
        SW R0, R3, CONTROL_REG ; stores enabled and read bit in CONTROL_REG
WAIT    LW R5, R0, STATUS_REG
        SLTI R0, R5, $0 ; checks if data ready == 1
        BRN DONE_RD
CONT    BRA WAIT
DONE_RD LI R3, $000D ; loads ack = 11, read = 0, enable = 1
        SW R0, R3, CONTROL_REG ; stores this in CONTROL_REG

INIT1   LI R1, $0 ; initializes count to 0
        LW R2, R0, DATA_REG ; loads data_reg
        LI R3, $0 ; initializes i to 0
LOOP    SLL R4, R2, R3 ; performs data_reg << i
        SLTI R0, R4, $0
        BRN INCR ; checks if MSB after shifting is 1
LOOP1   ADDI R3, R3, $1
        SLTI R0, R3, $0010 
        BRN LOOP ; continues loop if i < 16
        BRA EVAL
INCR    ADDI R1, R1, $1 ; if MSB after shifting is 1, increments count by 1
        BRA LOOP1
EVAL    LI R5, $1 ; loads bit mask of 0x1 into R5
        AND R5, R1, R5 ; stores count & 0x1 into R6
        LI R3, $00 ; clears data ready
        SW R0, R3, STATUS_REG ; stores this in CONTROL_REG
        SLTI R0, R5, $0
        BRZ EVEN
ODD     LI R3, $0005 ; loads ack = 01, read = 0, enable = 1
        SW R0, R3, CONTROL_REG ; stores this in CONTROL_REG
        BRA AFTER
EVEN    LI R3, $0001 ; loads ack = 00, read = 0, enable = 1
        SW R0, R3, CONTROL_REG ; stores this in CONTROL_REG
        BRA STORE
AFTER   ADDI R7, R7, $1 ; num_attempts <- num_attempts + 1
        SLTI R0, R7, $3 
        BRN INIT
        LI R3, $0005 ; loads ack = 01, read = 0, enable = 1
        SW R0, R3, CONTROL_REG ; stores this in CONTROL_REG
        LI R2, $FF ; 3 attempts all failed
        BRA STORE
STORE   SW R6, R2, ARRAY ; R2 either contains data_reg contents or $FF
                         ; and that is stored in the array
        ADDI R6, R6, $2 ; add 2 words to the array offset each time
        LI R7, $0 ; resets num_attempts <- 0
        SLTI R0, R6, $0010 ; checks if offset < 16, 
                           ; which is the same as checking index < 8
        BRN INIT
        BRA END
END     STOP