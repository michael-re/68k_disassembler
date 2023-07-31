*-------------------------------------------------------------------------------
* Title      : 68K disassembler
* Written by : Michael
* Date       : 06/30/2023
* Description: A disassembler for the 68K assembly language.
*-------------------------------------------------------------------------------
CR              EQU         $0000000D
LF              EQU         $0000000A
HT              EQU         $00000009
MIN_ADDR        EQU         $00000000
MAX_ADDR        EQU         $00FFFFFF
STACK           EQU         $0000A000
BUFFER_SIZE     EQU         $00000064
CODE_SECTION    EQU         $00001000
TEXT_SECTION    EQU         $00006000

SHIFT_12        EQU         12
SHIFT_8         EQU         8
SHIFT_6         EQU         6
SHIFT_3         EQU         3
SHIFT_1         EQU         1

* error value
ERROR           EQU        -1

* <ea> values
DN_EA           EQU         1
AN_EA           EQU         2
ANI_EA          EQU         3
ANIPI_EA        EQU         4
ANIPD_EA        EQU         5
ABSW_EA         EQU         6
ABSL_EA         EQU         7
IMM_EA          EQU         8

* size values
BYTE_VALUE      EQU         1
WORD_VALUE      EQU         2
LONG_VALUE      EQU         3

* directions
DN_TO_EA        EQU         $0100
DIR_LEFT        EQU         $0100

START:          ORG         CODE_SECTION
                LEA         welcome_msg, A1     * load welcome message
                JSR         PRINT_STRING_LN     * print welcome message

PROGRAM_BEGIN:  LEA         STACK, SP           * reset stack pointer
                JSR         CLEAR_REGISTERS     * set all register values to 0

                * print rules for input
                LEA         rule_msg, A1        * load rules
                JSR         PRINT_STRING_LN     * print rules

                * get starting address from user
                LEA         start_msg, A1       * load prompt asking for the starting address
                JSR         GET_HEX_INPUT       * read in user input
                MOVE.L      D0, start_addr      * save user input to start_addr

                * get ending address from user
                LEA         end_msg, A1         * load prompt asking for the ending address
                JSR         GET_HEX_INPUT       * read in user input
                MOVE.L      D0, end_addr        * save user input to end_addr

                * disassemble instructions
                JSR         DISASSEMBLE

PROGRAM_END:    JSR         PRINT_NEWLINE       * print empty line
                JSR         PRINT_NEWLINE       * print empty line
                LEA         goodbye_msg, A1     * load goodbye message
                JSR         PRINT_STRING_LN     * display goodbye message
                SIMHALT                         * halt simulator


*-------------------------------------------------------------------------------
* Subroutine:
*       DISASSEMBLE
*
* Description:
*       Disassembles all instructions from start_addr to end_addr by repeatedly
*       calling DISASSEMBLE_PAGE. After disassembling a page, this subroutine
*       asks the user to press enter to disassemble another page or any other
*       key to quit.
*
*       When all instructions have been disassembled, it will ask the user
*       if they want to restart the program or terminate.
*-------------------------------------------------------------------------------
DISASSEMBLE:
                MOVEM.L     A0-A6/D0-D7, -(SP)  * save registers
                JSR         CLEAR_REGISTERS     * clear registers
                JSR         CLEAR_SCREEN        * clear screen

DIS_LOOP:       JSR         DISASSEMBLE_PAGE    * disassemble a page of instructions from memory

                * check if all instructions have been decoded
                MOVE.L      start_addr, D0      * load start_addr into D0
                MOVE.L      end_addr, D1        * load end_addr into D1
                CMP.L       D1, D0              * compare start_addr and end_addr
                BGE         DIS_END             * exit loop if start_addr >= end_addr

                * more instructions left to decode, ask user if they want to continue
                LEA         continue_msg, A1    * load continue message
                JSR         PRINT_STRING        * print continue message
                JSR         READ_CHAR           * read character from keyboard

                CMP.B       #CR, D1             * check if user entered "enter"
                BEQ         DIS_LOOP            * if so, disassemble next page

                * done disassembling instructions in memory
DIS_END:        LEA         finish_msg, A1      * load finish message
                JSR         PRINT_NEWLINE       * print empty line
                JSR         PRINT_STRING_LN     * print finish message
                JSR         RESTART_PROMPT      * ask if user wants to restart or terminate program
                MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DISASSEMBLE_PAGE
*
* Description:
*       Disassembles a single page of instructions and prints them to the
*       console in the following format:
*           memory location            op-code            operand
*
*       This subroutine calls DECODE_INSTRUCTION in a loop until it has printed
*       25 instructions or until no more instructions are available to decode.
*-------------------------------------------------------------------------------
DISASSEMBLE_PAGE:
                MOVEM.L     A0-A6/D0-D7, -(SP)  * save registers
                JSR         CLEAR_REGISTERS     * clear registers
                JSR         CLEAR_SCREEN        * clear screen
                MOVEQ       #25, D2             * set loop counter to 25

DISP_LOOP:      MOVE.L      start_addr, D0      * load start_addr into D0
                MOVE.L      end_addr, D1        * load end_addr into D1
                CMP.L       D1, D0              * compare start_addr and end_addr
                BGE         DISP_END            * exit loop if start_addr >= end_addr

                JSR         DECODE_INSTRUCTION  * call DECODE_INSTRUCTION
                DBF         D2, DISP_LOOP       * decrement counter and loop if not zero

DISP_END:       MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_INSTRUCTION
*
* Description:
*       Decodes the instruction located at the address specified by start_addr,
*       increments start_addr to the next instruction in memory, and outputs the
*       decoded instruction to the screen.
*-------------------------------------------------------------------------------
DECODE_INSTRUCTION:
                MOVEM.L     A0-A6/D0-D7, -(SP)  * save registers
                JSR         CLEAR_REGISTERS     * clear registers

                * print current address - memory location
                MOVE.L      start_addr, D0      * load start_addr into D0
                JSR         LONG_TO_HEX_STRING  * convert address to hex string
                LEA         long_string_buf, A1 * load converted hex string
                JSR         PRINT_STRING        * print hex string
                JSR         RESET_BUFFER_AND_OFFSET

                * decode instruction
                JSR         LOAD_CURRENT_WORD   * load word data of current instruction to decode
                LEA         OPCODE_TABLE, A1    * load address of opcode jump table
                MOVE.B      #SHIFT_12, D1       * shift 12 bits to the right
                LSR.W       D1, D0              * isolate the first 4 bits to decode opcode name
                MULU        #6, D0              * form offset
                JSR         0(A1,D0)            * jump indirect with index

                * print to screen and go to next instruction
                LEA         output_buffer, A1   * load output buffer with decoded instruction
                JSR         PRINT_STRING_LN     * print buffer
                JSR         NEXT_INSTRUCTION    * go to the next instruction

                MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to the caller

OPCODE_TABLE:
                JMP         CODE_0000
                JMP         CODE_0001
                JMP         CODE_0010
                JMP         CODE_0011
                JMP         CODE_0100
                JMP         CODE_0101
                JMP         CODE_0110
                JMP         CODE_0111
                JMP         CODE_1000
                JMP         CODE_1001
                JMP         CODE_1010
                JMP         CODE_1011
                JMP         CODE_1100
                JMP         CODE_1101
                JMP         CODE_1110
                JMP         CODE_1111
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0000
*
* Description:
*       This disassembler does not decode any opcodes that begins with 0000.
*-------------------------------------------------------------------------------
CODE_0000:
                JSR         INVALID_OPCODE      * fill buffer with "DATA $WXYZ"
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0001
*
* Description:
*       Decodes the following opcodes:
*           - MOVE.B
*-------------------------------------------------------------------------------
CODE_0001:
                LEA         string_moveb, A1    * load opcode name
DECODE_MOVE_EA: JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JSR         PAD_BUFFER          * pad buffer before decoding operands

                * decode source <ea> for move instructions
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         DECODE_EA           * get source <ea>
                JSR         WRITE_COMMA         * write ', ' to buffer
                CMP         #ERROR, D0          * check for invalid source <ea>
                BEQ         _0001_INVALID

                * decode destination <ea>
                JSR         LOAD_CURRENT_WORD   * reload current instruction
                JSR         LOAD_DST_EA         * load destination mode and reg
                JSR         DECODE_EA           * get destination <ea>

                * check destination <ea>, MOVE supports all but An and #imm
                CMP         #ERROR, D0          * check for invalid <ea>
                BEQ         _0001_INVALID

                CMP         #AN_EA, D0          * check for An
                BEQ         _0001_INVALID

                CMP         #IMM_EA, D0         * check for #imm
                BEQ         _0001_INVALID

                BRA         _0001_RETURN        * done decoding MOVE

_0001_INVALID:  JSR         INVALID_OPCODE      * fill buffer with "DATA $WXYZ"
_0001_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0010
*
* Description:
*       Decodes the following opcodes:
*           - MOVE.L
*           - MOVEA.L
*-------------------------------------------------------------------------------
CODE_0010:
                * to determine if MOVE or MOVEA, we need to first check the destination <ea>
                MOVE.L      #LONG_VALUE, D3     * set size of opcode to long
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         LOAD_DST_EA         * load destination mode and reg
                JSR         DECODE_EA           * get destination <ea>

                * reset output buffer and instruction offset because decoding
                * destination <ea> will have potential modified them
                JSR         RESET_BUFFER_AND_OFFSET

                CMP         #ERROR, D0          * check for invalid <ea>
                BEQ         _0010_INVALID

                CMP         #AN_EA, D0          * if An, it's MOVEA.L
                BEQ         MATCHED_MOVEAL

                * <ea> != An --> decode MOVE.L
                LEA         string_movel, A1    * load opcode name
                JMP         DECODE_MOVE_EA      * decode source and destination operands

MATCHED_MOVEAL: LEA         string_moveal, A1   * load opcode name

DECODE_MOVEA_EA:
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JSR         PAD_BUFFER          * pad buffer before decoding operands

                * decode source <ea> - MOVEA supports all <ea> for source
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         DECODE_EA           * get source <ea>
                JSR         WRITE_COMMA         * write ', ' to buffer
                CMP         #ERROR, D0          * check for invalid source <ea>
                BEQ         _0010_INVALID

                * decode destination <ea> - MOVEA only supports An for destination
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         LOAD_DST_EA         * load destination mode and reg
                JSR         DECODE_EA           * get destination <ea>
                CMP         #AN_EA, D0          * check if An <ea>
                BEQ         _0010_RETURN        * done decoding MOVEA

_0010_INVALID:  JSR         INVALID_OPCODE      * fill buffer with "DATA $WXYZ"
_0010_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0011
*
* Description:
*       Decodes the following opcodes:
*           - MOVE.W
*           - MOVEA.W
*-------------------------------------------------------------------------------
CODE_0011:
                * to determine if MOVE or MOVEA, we need to first check destination <ea>
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         LOAD_DST_EA         * load destination mode and reg
                JSR         DECODE_EA           * decode destination <ea>

                * reset output buffer and instruction offset because decoding
                * destination <ea> will have potential modified them
                JSR         RESET_BUFFER_AND_OFFSET

                CMP         #ERROR, D0          * check for invalid
                BEQ         _0011_INVALID       * no reason to decoding anymore

                CMP         #AN_EA, D0          * check if <ea> is An
                BEQ         MATCHED_MOVEAW      * <ea> = An --> MOVEA.W

                * <ea> != An -->  decode MOVE.W
                LEA         string_movew, A1    * load opcode name into A1
                JMP         DECODE_MOVE_EA      * decode source and destination operands

MATCHED_MOVEAW: LEA         string_moveaw, A1   * load opcode name
                JMP         DECODE_MOVEA_EA     * decode source and destination operands

_0011_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_0011_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0100
*
* Description:
*       Decodes the following opcodes:
*           - LEA.L
*           - NOT
*           - NOP
*           - RTS
*           - JSR
*-------------------------------------------------------------------------------
CODE_0100:
                * check if instruction is NOP
                JSR         LOAD_CURRENT_WORD   * load current instruction
                CMP         #$4E71, D0          * compare against NOP
                BEQ         MATCHED_NOP         * decode NOP

                * check if instruction RTS
                CMP         #$4E75, D0          * compare against RTS
                BEQ         MATCHED_RTS         * decode RTS

                * check if instruction is JSR
                MOVE.B      #SHIFT_6, D1        * shift 6 bits to the right
                LSR.W       D1, D0              * isolate bits 15 - 6
                CMP         #$13A, D0           * compare against JSR
                BEQ         MATCHED_JSR         * decode JSR

                * check if instruction is LEA.L
                ANDI.L      #$7, D0             * isolate the last 3 bits
                CMP         #$7, D0             * check if its LEA.L
                BEQ         MATCHED_LEA         * decode LEA

                * check if instruction is NOT
                JSR         LOAD_CURRENT_WORD   * load current instruction
                MOVE.B      #SHIFT_8, D1        * shift 8 bits to the right
                LSR.W       D1, D0              * isolate bits 15 - 8
                CMP         #$46, D0            * check against NOT
                BEQ         MATCHED_NOT         * decode NOT

                * couldn't decode word to valid instruction
_0100_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
                BRA         _0100_RETURN        * return to caller

MATCHED_NOP:    * decode NOP
                LEA         string_nop, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                BRA         _0100_RETURN        * done decoding NOP

MATCHED_RTS:    * decode RTS
                LEA         string_rts, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                BRA         _0100_RETURN        * done decoding RTS

MATCHED_NOT:    * decode NOT
                LEA         string_not, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_SIZE_78      * decode opcode size

                CMP         #ERROR, D0          * check if valid size was decoded
                BEQ         _0100_INVALID       * something went wrong

                JSR         PAD_BUFFER          * pad buffer to align start of operands
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * get addressing mode

                * NOT supports all <ea> except An and #imm
                CMP.L       #ERROR, D0          * invalid addressing mode
                BEQ         _0100_INVALID

                CMP.L       #AN_EA, D0          * does not support An
                BEQ         _0100_INVALID

                CMP.L       #IMM_EA, D0         * does not support #imm
                BEQ         _0100_INVALID

                BRA _0100_RETURN                * done decoding NOT

MATCHED_JSR:    * decode JSR
                LEA         string_jsr, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * get addressing mode

                * JSR supports the following <ea> - (An), (xxx).W, (xxx).L
                CMP.L       #ANI_EA, D0         * check if decoded (An)
                BEQ         _0100_RETURN

                CMP.L       #ABSW_EA, D0        * check if decoded (xxx).W
                BEQ         _0100_RETURN

                CMP.L       #ABSL_EA, D0        * check if decoded (xxx).L
                BEQ         _0100_RETURN

                BRA         _0100_INVALID       * invalid addressing returned

MATCHED_LEA:    * decode LEA
                LEA         string_lea, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * get source <ea>

                * LEA supports the following source <ea> - (An), (xxx).W, (xxx).L
                CMP.L       #ANI_EA, D0         * check if decoded (An)
                BEQ         LEA_DST

                CMP.L       #ABSW_EA, D0        * check if decoded (xxx).W
                BEQ         LEA_DST

                CMP.L       #ABSL_EA, D0        * check if decoded (xxx).L
                BEQ         LEA_DST

                BRA         _0100_INVALID       * invalid LEA

LEA_DST:        JSR         WRITE_COMMA         * write ', ' to buffer
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         LOAD_DST_EA         * load destination mode and reg
                ANDI.L      #$000F, D0          * set destination mode to An
                JSR         DECODE_EA           * get addressing mode for destination
                BRA         _0100_RETURN        * done decoding LEA

_0100_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0101
*
* Description:
*       Decodes the following opcodes:
*           - ADDQ
*-------------------------------------------------------------------------------
CODE_0101:
                LEA         string_addq, A1     * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer

                * decode instruction size
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         DECODE_SIZE_78      * decode opcode size
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                CMP.L       #ERROR, D0          * check if decoded size is invalid
                BEQ         _0101_INVALID

                * decode immediate value: 1 - 8
                JSR         LOAD_CURRENT_WORD   * reload instruction
                LSR.L       #SHIFT_8, D0        * shift bits 9-12 to the front
                ANDI.L      #$000F, D0          * isolate the first 4 bits
                MOVE.L      D0, D1              * make copy of the first 4 bits
                ANDI.L      #1, D1              * isolate the least significant bit
                BNE         _0101_INVALID       * validate that this is ADDQ

                LSR.L       #SHIFT_1, D0        * remove least significant bit
                JSR         WRITE_QUICK_3       * decode 3 bit immediate data
                JSR         WRITE_COMMA         * write ', ' to buffer

                * decode destination <ea>
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * decode destination <ea>

                * check for error
                CMP.L       #ERROR, D0          * check if destination <ea> is invalid
                BEQ         _0101_INVALID

                CMP.L       #IMM_EA, D0         * can't have immediate data as destination <ea>
                BEQ         _0101_INVALID

                BRA         _0101_RETURN        * done decoding ADDQ

_0101_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_0101_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0110
*
* Description:
*       Decodes the following opcodes:
*           - BGT
*           - BLE
*           - BEQ
*           - BRA
*-------------------------------------------------------------------------------
CODE_0110:
                JSR         LOAD_CURRENT_WORD   * load current instruction
                LSR.L       #SHIFT_8, D0        * move condition bits to the first 4 bits
                ANDI.L      #$000F, D0          * isolate condition bits

                * determine if BGT, BLE, or BEQ, or BRA
                CMP         #$0000, D0          * BRA
                BEQ         MATCHED_BRA

                CMP         #$000E, D0          * BGT
                BEQ         MATCHED_BGT

                CMP         #$000F, D0          * BLE
                BEQ         MATCHED_BLE

                CMP         #$0007, D0          * BEQ
                BEQ         MATCHED_BEQ

                BRA         _0110_INVALID

MATCHED_BRA:    * decode BRA
                LEA         string_bra, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         DECODE_DISPLACEMENT * decode displacement

MATCHED_BGT:    * decode BGT
                LEA         string_bgt, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         DECODE_DISPLACEMENT * decode displacement

MATCHED_BLE:    * decode BLE
                LEA         string_ble, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         DECODE_DISPLACEMENT * decode displacement

MATCHED_BEQ:    * decode BEQ
                LEA         string_beq, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         DECODE_DISPLACEMENT * decode displacement

_0110_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_0110_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0111
*
* Description:
*       Decodes the following opcodes:
*           - MOVEQ.L
*-------------------------------------------------------------------------------
CODE_0111:
                LEA         string_moveq, A1    * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                * write immediate data to buffer
                JSR         LOAD_CURRENT_WORD   * load current instruction
                ANDI.L      #$00FF, D0          * isolate immediate data bits
                MOVE.B      #'#', (A0)+         * write '#' to buffer
                MOVE.B      #'$', (A0)+         * write '$' to buffer
                JSR         WORD_TO_HEX_STRING  * convert immediate data to string
                LEA         word_string_buf, A1 * load converted immediate data string
                JSR         WRITE_TO_BUFFER     * write immediate data string to buffer
                JSR         WRITE_COMMA         * write ', ' to buffer

                * decode destination register
                JSR         LOAD_CURRENT_WORD   * reload instruction
                LSR.L       #SHIFT_8, D0        * shift bits 9-12 to the front
                ANDI.L      #$000F, D0          * isolate the first 4 bits
                MOVE.L      D0, D1              * make copy of the first 4 bits
                ANDI.L      #1, D1              * isolate the least significant bit
                BNE         _0101_INVALID       * validate that this is MOVEQ

                LSR         #SHIFT_1, D0        * remove least significant bit
                MOVE.B      #'D', (A0)+         * write 'D' to buffer
                JSR         WRITE_REGISTER_NUM  * write register number to buffer
                BRA         _0111_RETURN        * done decoding MOVEQ

_0111_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_0111_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1000
*
* Description:
*       Decodes the following opcodes:
*           - OR
*-------------------------------------------------------------------------------
CODE_1000:
                LEA         string_or, A1       * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer

                * decode operands
OR_OPERANDS:    JSR         DECODE_DN_EA_DN_OPERANDS
                CMP         #ERROR, D0          * check if destination is invalid
                BEQ         _1000_INVALID

                CMP.L       #ERROR, D1          * check if source is invalid
                BEQ         _1000_INVALID

                * validate decoded <ea> fields
                CMP.L       #DN_TO_EA, D2       * check if decoded Dn, <ea>
                BEQ         DNEA_DN_AN_IMM_CHECK

                * decoded <ea>, Dn: if the location specified is a source
                * operand, only data addressing modes can be used: Dn, (An),
                * (An)+, -(An), (xxx).W, (xxx).L, #<data> --> everything but An
                CMP.L       #AN_EA, D1          * check if source is An
                BEQ         _1000_INVALID

                CMP.L       #DN_EA, D0          * check if destination is not Dn
                BNE         _1000_INVALID
                BRA         _1000_RETURN

                * decoded Dn, <ea>: if the location specified is a destination
                * operand, only memory alterable addressing modes can be used:
                * (An), (An)+, -(An), (xxx).W, (xxx).L
                *
                * DOES NOT SUPPORT: Dn, An, #<data>
DNEA_DN_AN_IMM_CHECK:
                CMP.L       #DN_EA, D1          * check if source is not Dn
                BNE         _1000_INVALID

                CMP.L       #DN_EA, D0          * check if destination is Dn
                BEQ         _1000_INVALID

                CMP.L       #AN_EA, D0          * check if destination is An
                BEQ         _1000_INVALID

                CMP.L       #IMM_EA, D0         * check if destination is #<data>
                BEQ         _1000_INVALID

                BRA         _1000_RETURN

_1000_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_1000_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1001
*
* Description:
*       Decodes the following opcodes:
*           - SUB
*-------------------------------------------------------------------------------
CODE_1001:
                LEA         string_sub, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer

                * decode operands
SUB_PATTERN:    JSR         DECODE_DN_EA_DN_OPERANDS
                CMP         #ERROR, D0          * check if destination is invalid
                BEQ         _1001_INVALID

                CMP.L       #ERROR, D1          * check if source is invalid
                BEQ         _1001_INVALID

                * validate decoded <ea> fields
                CMP.L       #DN_TO_EA, D2       * check if decoded Dn, <ea>
                BEQ         DNEA_DN_AN_IMM_CHECK

                * decode <ea>, Dn: if the location specified is a source
                * operand, all addressing modes can be used.
                CMP.L       #DN_EA, D0          * check if destination is not Dn
                BNE         _1000_INVALID

                * An only supports word and long size instruction
                CMP.L       #AN_EA, D0          * An only supports word and long size instruction
                BEQ         VALIDATE_ANB        * validate opcode size
                BRA         _1000_RETURN

VALIDATE_ANB:   CMP         #BYTE_VALUE, D3     * make sure opcode is not byte-sized
                BNE         _1001_RETURN

_1001_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_1001_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1010
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1010.
*-------------------------------------------------------------------------------
CODE_1010:
                JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1011
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1011.
*-------------------------------------------------------------------------------
CODE_1011:
                JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1100
*
* Description:
*       Decodes the following opcodes:
*           - AND
*-------------------------------------------------------------------------------
CODE_1100:
                LEA         string_and, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         OR_OPERANDS         * AND has the same pattern as OR
                JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1101
*
* Description:
*       Decodes the following opcodes:
*           - ADD
*           - ADDA
*-------------------------------------------------------------------------------
CODE_1101:
                JSR         LOAD_CURRENT_WORD   * load current instruction
                ANDI.L      #$00C0, D0          * isolate bit 7 and 8
                CMP         #$00C0, D0          * check if ADDA opcode
                BEQ         MATCHED_ADDA

                * decode ADD - it has the same pattern as SUB
                LEA         string_add, A1      * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                JMP         SUB_PATTERN         * decode source and destination operands

MATCHED_ADDA:   * decode ADDA
                LEA         string_adda, A1     * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_SIZE_9       * decode opcode size
                MOVE.L      D0, D3              * save size to D3

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         PAD_BUFFER          * pad buffer to align start of operands
                JSR         DECODE_EA           * decode source <ea>
                CMP         #ERROR, D0          * check <ea> for error
                BEQ         _1101_INVALID

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         WRITE_COMMA         * write ', ' to buffer

                JSR         LOAD_DST_EA         * load destination mode and reg
                ANDI.L      #$000F, D0          * set mode to An
                JSR         DECODE_EA           * decode destination <ea>
                BRA         _1101_RETURN

_1101_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_1101_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1110
*
* Description:
*       Decodes the following opcodes:
*           - LSL
*           - LSR
*           - ASL
*           - ASR
*           - ROL
*           - ROR
*-------------------------------------------------------------------------------
CODE_1110:
                * check for memory shift/rotate
                JSR         LOAD_CURRENT_WORD   * load current instruction
                ANDI.L      #$00C0, D0          * isolate bits 7 and 8
                CMP.L       #$00C0, D0          * check if memory shift/rotate
                BEQ         MEMORY_SR

                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #$0018, D0          * isolate bits 4 and 5

                CMP.L       #$0000, D0          * check if arithmetic shift
                BEQ         MATCHED_ASD

                CMP.L       #$0008, D0          * check if logical shift
                BEQ         MATCHED_LSD

                CMP.L       #$0018, D0          * check if rotate
                BEQ         MATCHED_ROD

                BRA         _1110_INVALID

MEMORY_SR:      MOVE.L      #ERROR, D4          * set flag for <ea> mode only
                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #$0E00, D0          * isolate bits 10-12

                CMP.L       #$0000, D0          * check if arithmetic shift
                BEQ         MATCHED_ASD

                CMP.L       #$0200, D0          * check if logical shift
                BEQ         MATCHED_LSD

                CMP.L       #$0600, D0          * check if rotate
                BEQ         MATCHED_ROD

                BRA         _1110_INVALID

MATCHED_LSD:    LEA         string_ls, A1       * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                BRA         LAR_DIRECTION       * get logical shift direction

MATCHED_ASD:    LEA         string_as, A1       * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                BRA         LAR_DIRECTION       * get arithmetic shift direction

MATCHED_ROD:    LEA         string_ro, A1       * load opcode name
                JSR         WRITE_TO_BUFFER     * write opcode name to buffer
                BRA         LAR_DIRECTION       * get rotate direction

LAR_DIRECTION:  * shift/rotation direction
                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #DIR_LEFT, D0       * isolate direction bit
                CMP.L       #DIR_LEFT, D0       * check direction bit
                BEQ         WRITE_LEFT          * left shift/rotate
                BRA         WRITE_RIGHT         * right shift/rotate

WRITE_LEFT:     MOVE.B      #'L', (A0)+         * write 'L' to buffer
                BRA         SR_NEXT             * decode shift/rotate size

WRITE_RIGHT:    MOVE.B      #'R', (A0)+         * write 'R' to buffer
                BRA         SR_NEXT             * decode shift/rotate size

SR_NEXT:        * check if <ea> mode only - size set to word
                CMP.L       #ERROR, D4          * check if <ea> mode only flag is set
                BEQ         EA_SR_MEMORY

                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_SIZE_78      * decode opcode size
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                * move i/r bit to D1
                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #$0020, D0          * isolate bit 5
                MOVE.L      D0, D1              * save i/r bit to D1

                * isolate count/register bits for source
                JSR         LOAD_CURRENT_WORD   * reload instruction
                LSR.W       #SHIFT_6, D0        * shift right by 6
                LSR.W       #SHIFT_3, D0        * shift right by 3
                ANDI.L      #$0007, D0          * isolate first 3 bits

                * check if i/r bit is shift/rotation is count or register
                CMP.L       #$0000, D1
                BEQ         SR_COUNT            * i/r = 0, shift/rotate by count
                BRA         SR_REG              * i/r = 1, shift/rotate by register

SR_COUNT:       * decode immediate value: 1 - 8
                JSR         WRITE_QUICK_3       * write quick immediate data to buffer
                BRA         SR_DST_REG          * decode destination register

SR_REG:         * decode source register
                MOVE.B      #'D', (A0)+         * write 'D' to buffer
                JSR         WRITE_REGISTER_NUM  * write register number to buffer
                BRA         SR_DST_REG          * decode destination register

SR_DST_REG:     JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         WRITE_COMMA         * write comma to buffer
                ANDI.L      #$0007, D0          * isolate the first 3 bits
                MOVE.B      #'D', (A0)+         * write 'D' to buffer
                JSR         WRITE_REGISTER_NUM  * write register number to buffer
                BRA         _1110_RETURN        * done decoding ASd, LSd, and ROd opcodes

EA_SR_MEMORY:   * opcode only takes a single operand
                MOVE.L      #$40, D0            * set opcode size to word for single operand
                JSR         DECODE_SIZE_78      * decode opcode size
                JSR         PAD_BUFFER          * pad buffer to align start of operands
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * decode single operand <ea>

                * <ea> must be (An), (An)+, -(An), (xxx).W, (xxx).L
                CMP.L       #ERROR, D0          * check if error
                BEQ         _1110_INVALID

                CMP.L       #DN_EA, D0          * check if Dn
                BEQ         _1110_INVALID

                CMP.L       #AN_EA, D0          * check if An
                BEQ         _1110_INVALID

                CMP.L       #IMM_EA, D0         * check if #<data>
                BEQ         _1110_INVALID

                BRA         _1110_RETURN        * done decoding ASd, LSd, and ROd opcodes with single operand

_1110_INVALID:  JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
_1110_RETURN:   RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1111
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1111.
*-------------------------------------------------------------------------------
CODE_1111:
                JSR         INVALID_OPCODE      * filler buffer with "DATA $WXYZ"
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_DN_EA_DN_OPERANDS
*
* Description:
*       Decodes the operands for instructions that have operands in the form of
*       (<ea>, Dn) or (Dn, <ea>).
*
* Return value:
*       D0 - destination <ea> value
*       D1 - source <ea> value
*       D2 - direction bit
*       D3 - instruction size (BYTE_VALUE, WORD_VALUE, LONG_VALUE)
*-------------------------------------------------------------------------------
DECODE_DN_EA_DN_OPERANDS:
                JSR         LOAD_CURRENT_WORD   * load current instruction
                JSR         DECODE_SIZE_78      * decode opcode size
                MOVE.L      D0, D3              * save size in D3
                CMP         #ERROR, D0          * check if decoded valid opcode size
                BEQ         DDEDO_INVALID

                * get direction (<ea> --> Dn || Dn --> <ea>)
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         PAD_BUFFER          * pad buffer to align start of operands
                ANDI.W      #DN_TO_EA, D0       * isolate direction bit
                MOVE.L      D0, D2              * save direction bit
                CMP         #DN_TO_EA, D0       * check if Dn, <ea>
                BEQ         OPERAND_DN_EA       * decode Dn, <ea>

                * decode <ea>, Dn
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         DECODE_EA           * decode source operand
                MOVE.L      D0, D1              * save source <ea> to D1
                CMP.L       #ERROR, D0          * check if it's invalid
                BEQ         DDEDO_INVALID

                * decode destination
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         WRITE_COMMA         * write ', ' to buffer
                JSR         LOAD_DST_EA         * get destination <ea>
                ANDI.L      #$07, D0            * set to Dn mode
                JSR         DECODE_EA           * decode destination <ea>

                CMP.L       #ERROR, D0          * check if it's invalid
                BEQ         DDEDO_INVALID
                BRA         DDEDO_RETURN

OPERAND_DN_EA:
                * decode Dn, <ea>
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         LOAD_DST_EA         * Dn is source, load it
                ANDI.L      #$07, D0            * set to Dn mode
                JSR         DECODE_EA           * decode it
                MOVE.L      D0, D1              * save source <ea> to D1

                CMP.L       #DN_EA, D0          * check if it's invalid, must be Dn
                BNE         DDEDO_INVALID

                * decode destination
                JSR         LOAD_CURRENT_WORD   * reload instruction
                JSR         WRITE_COMMA         * write ', '
                JSR         DECODE_EA           * decode destination

                CMP.L       #ERROR, D0          * check if it's invalid
                BEQ         DDEDO_INVALID
                BRA         DDEDO_RETURN

DDEDO_INVALID:  MOVE.L      #ERROR, D0
                MOVE.L      #ERROR, D1
DDEDO_RETURN:   RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_DISPLACEMENT
*
* Description:
*       Decodes the displacement value of the current branching instruction at
*       start_addr in writes it to the buffer in A0. On exit, A0 will point to
*       the last byte written to the buffer.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*-------------------------------------------------------------------------------
DECODE_DISPLACEMENT:
                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #$00FF, D0          * isolate displacement bits
                CMP         #$0000, D0          * check if displacement is 8 or 16 bits
                BEQ         DIS_16_BIT          * 16-bit displacement
                BRA         DIS_8_BIT           * 8-bit displacement

DIS_16_BIT:     LEA         string_word, A1     * load instruction size, word
                JSR         WRITE_TO_BUFFER     * write instruction size to buffer
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                ADD.L       #2, inst_offset     * update instruction offset by the number of bytes in a word
                MOVE.L      start_addr, D0      * PC
                ADD.L       #2, D0              * PC + 2

                MOVE.L      #0, D1              * clear D1 to hold displacement
                MOVE.L      D0, A1              * move address of instruction into A1
                MOVE.W      (A1), D1            * load displacement word

                * apply displacement to PC to get location of label
                CMP.L       #$8000, D1          * check if displacement is negative
                BGE         NEG_16
                BRA         POS_16

NEG_16:         NEG.W       D1                  * negative displacement - negate it
                SUB.L       D1, D0              * branch location = (PC + 2) - displacement
                BRA         WRITE_DIS           * write displacement to buffer

POS_16:         ADD         D1, D0              * branch location = (PC + 2) + displacement
                BRA         WRITE_DIS           * write displacement to buffer

DIS_8_BIT:      LEA         string_byte, A1     * load instruction size, byte
                JSR         WRITE_TO_BUFFER     * write instruction size to buffer
                JSR         PAD_BUFFER          * pad buffer to align start of operands

                JSR         LOAD_CURRENT_WORD   * reload instruction
                ANDI.L      #$00FF, D0          * isolate displacement bits
                MOVE.L      D0, D1              * save displacement in D1

                MOVE.L      start_addr, D0      * PC
                ADD.L       #2, D0              * PC + 2

                * apply displacement to PC to get location of label
                CMP.L       #$0080, D1          * check if displacement is negative
                BGE         NEG_8
                BRA         POS_8

NEG_8:          NEG.B       D1                  * negative displacement - negate it
                SUB.L       D1, D0              * branch location = (PC + 2) - displacement
                BRA         WRITE_DIS           * write displacement to buffer

POS_8:          ADD         D1, D0              * branch location = (PC + 2) + displacement
                BRA         WRITE_DIS           * write displacement to buffer

WRITE_DIS:      JSR         LONG_TO_HEX_STRING  * convert branch label to hex string
                LEA         long_string_buf, A1 * load converted string label value
                MOVE.B      #'$', (A0)+         * write '$' to buffer
                JSR         WRITE_TO_BUFFER     * write branch location to buffer
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       INVALID_OPCODE
*
* Description:
*       Writes "DATA   $WXYZ" to the output buffer, where $WXYZ is the
*       hexadecimal number that couldn't be decoded.
*-------------------------------------------------------------------------------
INVALID_OPCODE:
                MOVEM.L     A0-A1, -(SP)        * save registers
                JSR         CLEAR_OUTPUT_BUFFER * clear output buffer
                LEA         output_buffer, A0   * load address of output buffer
                LEA         string_data, A1     * load address of 'DATA' string

                MOVE.B      #HT, (A0)+          * append tab character
                JSR         WRITE_TO_BUFFER     * write DATA to buffer
                JSR         PAD_BUFFER          * add padding to buffer
                MOVE.B      #'$', (A0)+         * append '$'

                * load the value at start_addr into D0 and print it
                JSR         LOAD_CURRENT_WORD   * load invalid word
                JSR         WORD_TO_HEX_STRING  * convert word value to hex string
                LEA         word_string_buf, A1 * load address of converted hex string
                JSR         WRITE_TO_BUFFER     * write word to buffer

                MOVEM.L     (SP)+, A0-A1        * restore registers
                RTS                             * return to the caller



*-------------------------------------------------------------------------------
* Subroutine:
*       LOAD_CURRENT_WORD
*
* Description:
*       Loads D0 with the word value held at the address start_addr holds.
*
* Return Value:
*       D0 - Word value (first 16 bits) of the data held at the address of
*       start_addr.
*-------------------------------------------------------------------------------
LOAD_CURRENT_WORD:
                MOVEM.L     A0, -(SP)           * save registers
                MOVE.L      #0, D0              * clear D0
                MOVE.L      start_addr, A0      * load address of start_addr into A0
                MOVE.W      (A0), D0            * load in word data at start_addr
                MOVEM.L     (SP)+, A0           * restore registers
                RTS                             * return to the caller



*-------------------------------------------------------------------------------
* Subroutine:
*       NEXT_INSTRUCTION
*
* Description:
*       increments start_addr by the number of bytes in inst_offset to move
*       start_addr to the next instruction in memory.
*
*       After incrementing start_addr, inst_offset is reset to the number of
*       bytes in a word (2).
*-------------------------------------------------------------------------------
NEXT_INSTRUCTION:
                MOVEM.L     A0-A6/D0-D7, -(SP)  * save registers
                MOVE.L      start_addr, D0      * load current instruction
                MOVE.L      inst_offset, D1     * load instruction offset
                ADD.L       D1, D0              * go to next instruction
                MOVE.L      D0, start_addr      * write value to variable
                MOVE.L      #2, inst_offset     * reset instruction offset
                MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       RESET_BUFFER_AND_OFFSET
*
* Description:
*       Resets everything related to the current opcode by clearing the output
*       buffer and instruction offset.
*-------------------------------------------------------------------------------
RESET_BUFFER_AND_OFFSET:
                JSR         CLEAR_OUTPUT_BUFFER * clear output buffer
                LEA         output_buffer, A0   * load into A0
                MOVE.B      #HT, (A0)+          * append tab to align opcode name
                MOVE.L      #2, inst_offset     * reset instruction offset
                RTS                             * return to caller



********************************************************************************
* <ea> subroutines
********************************************************************************

*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_EA
*
* Description:
*       Decodes the addressing mode of the current instruction and writes it
*       to the buffer in A0. On exit, A0 will point to the last byte written
*       to the buffer.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*       D0 - The first 6 bits of the <ea> to decode. It should be formatted as
*            follows: <Mode> <Xn> --> 0000 0000 00xx xxxx
*       D3 - The size of the current instruction. Set to #LONG_VALUE if
*            instruction can take #<data> and supports long size.
*
* Return Value:
*       D0 - The effective addressing mode of the current instruction.
*            The following numbers correspond to the following addressing modes:
*               ERROR:    error  - invalid addressing mode
*               DN_EA:    Dn     - data register direct
*               AN_EA:    An     - address register direct
*               ANI_EA:   (An)   - address register indirect
*               ANIPI_EA: (An)+  - address register indirect with post incrementing
*               ANIPD_EA: -(An)  - address register indirect with pre decrementing
*               ABSW_EA: (xxx).W - absolute word address
*               ABSL_EA: (xxx).L - absolute long address
*               IMM_EA:  #imm    - immediate data
*-------------------------------------------------------------------------------
DECODE_EA:
                MOVEM.L     A1-A6/D1-D7, -(SP)  * save registers
                ANDI.L      #$3F, D0            * isolate lower 6 bits
                MOVE.L      D0, D1              * make copy of <ea>
                LEA         EA_TABLE, A1        * load address of ea jump table
                MOVE.B      #SHIFT_3, D2        * shift 3 bits to the right
                LSR.W       D2, D1              * isolate the 3 mode bits
                MULU        #6, D1              * form offset
                JSR         0(A1,D1)            * jump indirect with index
                MOVEM.L     (SP)+, A1-A6/D1-D7  * restore registers
                RTS                             * return to caller

EA_TABLE:
                JMP         EA_MODE_000         * Dn    - data register direct
                JMP         EA_MODE_001         * An    - address register direct
                JMP         EA_MODE_010         * (An)  - address register indirect
                JMP         EA_MODE_011         * (An)+ - address register indirect with post incrementing
                JMP         EA_MODE_100         * -(An) - address register indirect with pre decrementing
                JMP         EA_MODE_101         * --- unsupported ---
                JMP         EA_MODE_110         * --- unsupported ---
                JMP         EA_MODE_111         * absolute word/long addressing and immediate data
                RTS                             * return to caller

EA_MODE_000:                                    * Dn
                MOVE.B      #'D', (A0)+         * append 'D' for data register
                JSR         WRITE_REGISTER_NUM
                MOVE.L      #DN_EA, D0          * add return value
                RTS                             * return to caller

EA_MODE_001:                                    * An
                MOVE.B      #'A', (A0)+         * append 'A' for address register
                JSR         WRITE_REGISTER_NUM
                MOVE.L      #AN_EA, D0          * add return value
                RTS                             * return to caller

EA_MODE_010:                                    * (An)
                MOVE.B      #'(', (A0)+         * append '('
                MOVE.B      #'A', (A0)+         * append 'A' for address register
                JSR         WRITE_REGISTER_NUM
                MOVE.B      #')', (A0)+         * append ')'
                MOVE.L      #ANI_EA, D0         * add return value
                RTS                             * return to caller

EA_MODE_011:                                    * (An)+
                MOVE.B      #'(', (A0)+         * append '('
                MOVE.B      #'A', (A0)+         * append 'A' for address register
                JSR         WRITE_REGISTER_NUM
                MOVE.B      #')', (A0)+         * append ')'
                MOVE.B      #'+', (A0)+         * append '+'
                MOVE.L      #ANIPI_EA, D0       * add return value
                RTS                             * return to caller

EA_MODE_100:                                    * -(An)
                MOVE.B      #'-', (A0)+         * append '-'
                MOVE.B      #'(', (A0)+         * append '('
                MOVE.B      #'A', (A0)+         * append 'A' for address register
                JSR         WRITE_REGISTER_NUM
                MOVE.B      #')', (A0)+         * append ')'
                MOVE.L      #ANIPD_EA, D0       * add return value
                RTS                             * return to caller

EA_MODE_101:                                    * --- unsupported ---
                MOVE.L      #ERROR, D0          * invalid addressing mode
                RTS                             * return to caller

EA_MODE_110:                                    * --- unsupported ---
                MOVE.L      #ERROR, D0          * invalid addressing mode
                RTS                             * return to caller

EA_MODE_111:                                    * (xxx).W, (xxx).L, #imm
                CMP.L       #$38, D0            * check if absolute word addressing
                BEQ         EA_ABS_WORD

                CMP.L       #$39, D0            * check if absolute long addressing
                BEQ         EA_ABS_LONG

                CMP.L       #$3C, D0            * check if immediate data
                BEQ         EA_IMM_DATA

                BRA         _111_ERROR          *   something went wrong

EA_ABS_WORD:                                    * (xxx).W
                MOVE.B      #'$', (A0)+         * append '$'
                JSR         WRITE_OFFSET_WORD   * get word from memory
                MOVE.L      #ABSW_EA, D0        * add return value
                BRA         _111_RETURN         * done decoding absolute word

EA_ABS_LONG:                                    * (xxx).L
                MOVE.B      #'$', (A0)+         * append '$'
                JSR         WRITE_OFFSET_WORD   * get the first word from memory
                JSR         WRITE_OFFSET_WORD   * get the second word to fully decode long word
                MOVE.L      #ABSL_EA, D0        * add return value
                BRA         _111_RETURN         * done decoding absolute long

EA_IMM_DATA:                                    * #imm
                MOVE.B      #'#', (A0)+         * append '#'
                MOVE.B      #'$', (A0)+         * append '$'
                JSR         WRITE_OFFSET_WORD   * get word from memory

                CMP         #LONG_VALUE, D3
                BEQ         ADD_NEXT_WORD
                BRA         EA_IMM_DATA_N

ADD_NEXT_WORD:  JSR         WRITE_OFFSET_WORD   * get next word from memory
EA_IMM_DATA_N:  MOVE.L      #IMM_EA, D0         * add return value
                BRA         _111_RETURN         * done decoding immediate data

_111_ERROR:     MOVE.L      #ERROR, D0          * invalid addressing mode
_111_RETURN:    RTS                             * return to caller




*-------------------------------------------------------------------------------
* Subroutine:
*       WRITE_OFFSET_WORD
*
* Description:
*       Writes the word value obtained by applying inst_offset to start_addr in
*       memory to the buffer in A0.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*-------------------------------------------------------------------------------
WRITE_OFFSET_WORD:
                MOVEM.L     A1/D0-D1, -(SP)     * save registers
                MOVE.L      start_addr, D0      * load current instruction
                MOVE.L      inst_offset, D1     * load instruction offset
                ADD.L       D1, D0              * go to next instruction

                MOVE.L      D0, A1              * load in address of instruction
                MOVE.L      #0, D0              * reset D0
                MOVE.W      (A1), D0            * copy word from memory

                JSR         WORD_TO_HEX_STRING  * convert word to hex
                LEA         word_string_buf, A1 * get converted word
                JSR         WRITE_TO_BUFFER     * write word to buffer
                ADD.L       #2, inst_offset     * update instruction offset by the number of bytes in word
                MOVEM.L     (SP)+, A1/D0-D1     * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       WRITE_REGISTER_NUM
*
* Description:
*       Writes the register number represented by the last 3 bits in D0 to the
*       buffer in A0.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*       D0 - Register number to write.
*-------------------------------------------------------------------------------
WRITE_REGISTER_NUM:
                MOVEM.L     D0, -(SP)           * save registers
                ANDI.L      #$07, D0            * isolate 3 register bits
                ADD.B       #'0', D0            * convert to ASCII
                MOVE.B      D0, (A0)+           * write register number to buffer
                MOVEM.L     (SP)+, D0           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_SIZE_78
*
* Description:
*       Decodes the size of the instruction in D0 and writes it to the buffer in
*       A0. On exit, A0 will point to the last byte written to the buffer.
*
*       Keep in mind, this only works for opcodes where bit 7 and 8 hold the
*       the size of the instruction. THIS DOES NOT WORK FOR instruction where
*       the size is determined by a single bit or other bit fields in the
*       instruction.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*       D0 - Instruction to decode the size of.
*
* Return Value:
*       D0 - The decoded size of the current instruction, where each of the
*            following numbers correspond to the following sizes:
*               ERROR:      error - invalid instruction size mode
*               BYTE_VALUE: byte  - .B
*               WORD_VALUE: word  - .W
*               LONG_VALUE: long  - .L
*-------------------------------------------------------------------------------
DECODE_SIZE_78:
                MOVEM.L     A1, -(SP)           * save registers
                ANDI.L      #$C0, D0            * isolate bits 7 and 8

                CMP.L       #$0, D0             * check if byte
                BEQ         DS_BYTE

                CMP.L       #$40, D0            * check if word
                BEQ         DS_WORD

                CMP.L       #$80, D0            * check if long
                BEQ         DS_LONG

                BRA         DS_INVALID          * something went wrong

DS_BYTE:        LEA         string_byte, A1     * load byte size string
                JSR         WRITE_TO_BUFFER     * write byte size to buffer
                MOVE.L      #BYTE_VALUE, D0     * load return value
                BRA         DS_RETURN           * return to caller

DS_WORD:        LEA         string_word, A1     * load word size string
                JSR         WRITE_TO_BUFFER     * write word size to buffer
                MOVE.L      #WORD_VALUE, D0     * load return value
                BRA         DS_RETURN           * return to caller

DS_LONG:        LEA         string_long, A1     * load long size string
                JSR         WRITE_TO_BUFFER     * write long size to buffer
                MOVE.L      #LONG_VALUE, D0     * load return value
                BRA         DS_RETURN           * return to caller

DS_INVALID:     MOVE.L      #ERROR, D0          * add return value
DS_RETURN:      MOVEM.L     (SP)+, A1           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_SIZE_9
*
* Description:
*       Decodes the size of the instruction in D0 and writes it to the buffer in
*       A0. On exit, A0 will point to the last byte written to the buffer.
*
*       Keep in mind, this only works for opcodes where bit 9 holds the
*       the size of the instruction.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*       D0 - Instruction to decode the size of.
*
* Return Value:
*       D0 - The decoded size of the current instruction, where each of the
*            following numbers correspond to the following sizes:
*               WORD_VALUE: word  - .W
*               LONG_VALUE: long  - .L
*-------------------------------------------------------------------------------
DECODE_SIZE_9:
                MOVEM.L     A1, -(SP)           * save registers
                ANDI.L      #$100, D0           * isolate bit 9
                CMP.L       #$000, D0           * check if word
                BEQ         DS_WORD             * return word
                BRA         DS_LONG             * return long
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       WRITE_QUICK_3
*
* Description:
*       Decodes the the 3 bit immediate data in D0 and writes it to the buffer
*       in A0. On exit, A0 will point to the last byte written to the buffer.
*
*       The first 3 bits in D0 represent the quick immediate data to decode. The
*       values 1 – 7 represent counts of 1, and zero specifies a count of eight.
*
* Parameters:
*       A0 - Pointer to buffer to write too.
*       D0 - Quick immediate data to decode.
*-------------------------------------------------------------------------------
WRITE_QUICK_3:
                MOVEM.L     A1, -(SP)           * save registers
                CMP.L       #$0000, D0          * check if quick value is zero
                BEQ         QUICK_SET_8         * quick value = 0,  immediate data is 8
                BRA         QUICK_WRITE         * write quick value to buffer

QUICK_SET_8:    MOVE.L      #$0008, D0          * set quick value to 8
QUICK_WRITE:    MOVE.B      #'#', (A0)+         * write '#'' to buffer
                MOVE.B      #'$', (A0)+         * write '$' to buffer
                JSR         WORD_TO_HEX_STRING  * convert quick data to hex
                LEA         word_string_buf, A1 * load converted into A1
                JSR         WRITE_TO_BUFFER     * write value to buffer
                MOVEM.L     (SP)+, A1           * restore registers
                RTS                             * return to caller






*-------------------------------------------------------------------------------
* Subroutine:
*       LOAD_DST_EA
*
* Description:
*       Swaps destination <ea> with source <ea> for the instruction in D0. The
*       destination <ea>, bits 7 - 13, will be swapped with the source <ea>,
*       bits 1 - 6. After swapping the <ea>, the destination Mode and Xn bits
*       will be in the  the following format: <Mode> <Xn>
*
* Parameters:
*       D0 - Instruction to load destination <ea> of.
*
* Return Value:
*       D0 - The destination <ea> of the instruction where the first three bits
*            represent the <Xn> and the next three the <Mode>.
*-------------------------------------------------------------------------------
LOAD_DST_EA:
                MOVEM.L     D1, -(SP)           * save registers

                * move dst to were src is
                MOVE.B      #SHIFT_6, D1        * shift 6 bits to the right
                LSR.W       D1, D0              * isolate bits 15 - 6
                ANDI.L      #$3F, D0            * isolate lower 6 bits

                * swap mode with reg in destination
                MOVE.L      D0, D1              * copy the contents of D0 to D1
                ANDI.L      #$07, D0            * isolate first 3 bits in D0
                LSL.W       #$03, D0            * shift D0 3 bits to the left
                ANDI.L      #$38, D1            * isolate the next 3 bits in D1
                LSR.W       #$03, D1            * shift D1 3 bits to the right
                OR.L        D1, D0              * combine the modified D0 and D1 to swap bits 0-2 with 3-5

                MOVEM.L     (SP)+, D1           * restore registers
                RTS                             * return to caller




********************************************************************************
* Conversion subroutines
********************************************************************************

*-------------------------------------------------------------------------------
* Subroutine:
*       STRING_TO_NUMBER
*
* Description:
*       Convert a null-terminated string in A1 that represents a hex number into
*       an integer value.
*
* Parameters:
*       A1 - pointer to the null-terminated string containing the hex string to
*            convert.
*
* Return Value:
*       D0 - The integer value the hex string represents. On failure, -1 is
*            returned.
*       D1 - Returns 0 on success, -1 (FFFFFFFF) on error.
*-------------------------------------------------------------------------------
STRING_TO_NUMBER:
                MOVEM.L     A1/D2, -(SP)        * save registers
                MOVE.L      #0, D0              * holds return value
                MOVE.L      #0, D1              * holds current string being converted
                MOVE.L      #8, D2              * loop counter

STN_CONVERT:    CMP.L       #0, D2
                BEQ         STN_LOOP_END

                LSL.L       #4, D0              * multiply running total by 16 (using shift to prevent sign extension)
                MOVE.L      #0, D1              * clear the value of D1
                MOVE.B      (A1)+, D1           * load the ASCII value being converted

                CMP.B       #'0', D1            * check if it's less than '0'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'9', D1            * check if it's less than '9'
                BLS         ASCII_NUMBER        * it's a hex digit, convert it

                CMP.B       #'A', D1            * check if it's less than 'A'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'F', D1            * check if it's less than 'F'
                BLS         ASCII_C_LETTER      * it's a hex digit, convert it

                CMP.B       #'a', D1            * check if it's less than 'a'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'f', D1            * check if it's less than 'f'
                BLS         ASCII_L_LETTER      * it's a hex digit, convert it

STN_ERROR:      MOVE.L      #-1, D0             * set D0 to 0xFFFFFFFF
                MOVE.L      #-1, D1             * set error flag
                BRA         STN_RETURN

ASCII_NUMBER:   SUB         #'0', D1            * convert the ASCII digit to a number
                BRA         STN_CONTINUE

ASCII_L_LETTER: SUB         #'a', D1            * convert the ASCII lowercase letter to a number
                ADD         #10, D1
                BRA         STN_CONTINUE

ASCII_C_LETTER: SUB         #'A', D1            * convert the ASCII capital letter to a number
                ADD         #10, D1
                BRA         STN_CONTINUE

STN_CONTINUE:   ADD         D1, D0              * add current value to total
                DBF         D2, STN_CONVERT     * decrement the counter and loop if not zero

STN_LOOP_END:   MOVE.L      #0, D1              * disable the error flag
STN_RETURN:     MOVEM.L     (SP)+, A1/D2        * restore registers
                RTS                             * return to the caller




*-------------------------------------------------------------------------------
* Subroutine:
*       LONG_TO_HEX_STRING
*
* Description:
*       Converts the longword value in D0 into a hexadecimal string
*       representation and stores it in the long_string_buf as a
*       null-terminated string.
*
* Parameters:
*       D0 - Longword value to be converted to a hexadecimal string.
*
* Return Value:
*       long_string_buf - Null-terminated string of the integer value in D0
*                        as a hexadecimal string.
*-------------------------------------------------------------------------------
LONG_TO_HEX_STRING:
                MOVEM.L     A1/D0-D2, -(SP)     * save registers
                MOVE.L      #8, D1              * holds loop counter
                MOVE.B      D0, D2              * holds current digit to convert
                LEA         long_string_buf, A1 * load address of the hex buffer (stores return value)
                ADDA.L      D1, A1              * adjust A1 by the loop counter to fill in reverse order

LTS_CONVERT:    ANDI.L      #$0000000F, D2      * mask out the lower 4 bits of D2 to get the last digit
                ADD.B       #'0', D2            * convert the digit to an ASCII hex character
                CMP.B       #'9', D2            * check if the digit is greater than '9'
                BLS         LTS_STORE           * branch if it's a digit from 0 to 9
                ADD.B       #7, D2              * adjust the ASCII value for letters A to F
LTS_STORE:      MOVE.B      D2, -(A1)           * write hex character to buffer

                LSR.L       #4, D0              * shift right to get the next digit
                MOVE.L      D0, D2              * copy the value into D2
                DBF         D1, LTS_CONVERT     * decrement loop counter and loop if not zero

                MOVEM.L     (SP)+, A1/D0-D2     * restore registers
                RTS                             * return to the caller




*-------------------------------------------------------------------------------
* Subroutine:
*       WORD_TO_HEX_STRING
*
* Description:
*       Converts the word value in D0 into a hexadecimal string representation
*       and stores it in the word_string_buf as a null-terminated string.
*
* Parameters:
*       D0 - Word value to be converted to a hexadecimal string.
*
* Return Value:
*       word_string_buf - Null-terminated string of the integer value in D0
*                        as a hexadecimal string.
*-------------------------------------------------------------------------------
WORD_TO_HEX_STRING:
                MOVEM.L     A1/D0-D2, -(SP)     * save registers
                MOVE.L      #4, D1              * holds loop counter
                MOVE.B      D0, D2              * holds current digit to convert
                LEA         word_string_buf, A1 * load address of the hex buffer (stores return value)
                ADDA.L      D1, A1              * adjust A1 by the loop counter to fill in reverse order

WTS_CONVERT:    ANDI.W      #$000F, D2          * mask out the lower 4 bits of D2 to get the last digit
                ADD.B       #'0', D2            * convert the digit to an ASCII hex character
                CMP.B       #'9', D2            * check if the digit is greater than '9'
                BLS         WTS_STORE           * branch if it's a digit from 0 to 9
                ADD.B       #7, D2              * adjust the ASCII value for letters A to F
WTS_STORE:      MOVE.B      D2, -(A1)           * write hex character to buffer

                LSR.W       #4, D0              * shift right to get the next digit
                MOVE.W      D0, D2              * copy the value into D2
                DBF         D1, WTS_CONVERT     * decrement loop counter and loop if not zero

                MOVE.B      #0, (A1)            * null-terminate hex buffer

                MOVEM.L     (SP)+, A1/D0-D2     * restore registers
                RTS                             * return to the caller





********************************************************************************
* I/O subroutines
********************************************************************************

*-------------------------------------------------------------------------------
* Subroutine:
*       GET_HEX_INPUT
*
* Description:
*       Obtains a hexadecimal input from the user and returns the integer it
*       represents in D0. This subroutine checks the input to ensure it's valid.
*
* Parameters:
*       A1 - Pointer to null-terminated string containing prompt asking for
*            the user input.
*
* Return Value:
*       D0 - The integer value the hex string represents.
*-------------------------------------------------------------------------------
GET_HEX_INPUT:
                MOVEM.L     A1/D1, -(SP)        * save registers
                JSR         PRINT_STRING        * print prompt for user input
                JSR         READ_STRING         * read user input

                LEA         error_msg_h, A1
                CMP.W       #8, D1              * check if input is the right length
                BNE         INVALID_INPUT       * input is either too long or too short

                LEA         input_buffer, A1    * load the starting address of the input
                JSR         STRING_TO_NUMBER    * convert string input to an integer

                LEA         error_msg_h, A1
                CMP         #ERROR, D1          * check if conversion was successful
                BEQ         INVALID_INPUT       * input was not a valid hex string

                LEA         error_msg_l, A1
                CMP.L       #MIN_ADDR, D0       * check starting address range
                BLT.L       INVALID_INPUT       * starting address is out of range

                LEA         error_msg_g, A1
                MOVE.L      #MAX_ADDR, D1       * load the max value for the ending address (too big to fit as immediate data)
                CMP.L       D1, D0              * check ending address range
                BGT         INVALID_INPUT       * ending address is out of range

                MOVE.L      D0, D1              * copy the converted number into D1
                AND.L       #1, D1              * check if the least significant bit is 0 (is it even)

                LEA         error_msg_e, A1
                BNE         INVALID_INPUT       * address is not even

                MOVEM.L     (SP)+, A1/D1        * restore registers
                RTS                             * return to the caller



*-------------------------------------------------------------------------------
* Subroutine:
*       INVALID_INPUT
*
* Description:
*       Prints the error message that resulted in the invalid input stored in A1
*       and calls RESTART_PROMPT to check if the user wants to restart the
*       program or quit.
*
* Parameters:
*       A1 - The error that resulted in the invalid input.
*-------------------------------------------------------------------------------
INVALID_INPUT:
                JSR         PRINT_STRING_LN     * print error message
                LEA         error_msg, A1       * load invalid input message
                JSR         PRINT_STRING        * print invalid input
                BRA         RESTART_PROMPT      * ask user if they want to restart



*-------------------------------------------------------------------------------
* Subroutine:
*       RESTART_PROMPT
*
* Description:
*       Asks the user if they want to restart the program or quit. If the user
*       enters "R" or "r", it branches to PROGRAM_BEGIN to restart the program. If they
*       enter "Q" or "q", it branches to PROGRAM_END to terminate the program.
*
*-------------------------------------------------------------------------------
RESTART_PROMPT:
                LEA         restart_msg, A1     * load restart message
                JSR         PRINT_STRING        * print message to console
                JSR         READ_CHAR           * get input from user
                JSR         CLEAR_SCREEN        * clear the screen

                * check user input
                CMP.B       #'R', D1            * compare user input in D1
                BEQ         PROGRAM_BEGIN       * entered 'R' - restart

                CMP.B       #'r', D1            * compare user input in D1
                BEQ         PROGRAM_BEGIN       * entered 'r' - restart

                CMP.B       #'Q', D1            * compare user input in D1
                BEQ         PROGRAM_END         * entered 'Q' - terminate

                CMP.B       #'q', D1            * compare user input in D1
                BEQ         PROGRAM_END         * entered 'q' - terminate

                * invalid input, try again
                LEA         error_msg, A1
                JSR         PRINT_STRING
                BRA         RESTART_PROMPT



*-------------------------------------------------------------------------------
* Subroutine:
*       READ_STRING
*
* Description:
*       Reads up to 80 characters from the keyboard and stores the result in
*       input_buffer as a null-terminated string. The length of the string is
*       returned in D1.W (max 80).
*
* Return Value:
*       D1.W - Length of string read from the user.
*       A1   - Pointer to the null-terminated string (input_buffer) read from the user.
*-------------------------------------------------------------------------------
READ_STRING:
                MOVEM.L     D0, -(SP)           * save registers
                JSR         CLEAR_INPUT_BUFFER  * fill input buffer with zeros
                MOVE.L      #$0, D1             * prepare D1 to store string length
                LEA         input_buffer, A1    * load input_buffer into A1
                MOVE.B      #2, D0              * prepare system call to read string
                TRAP        #15                 * make system call
                MOVEM.L     (SP)+, D0           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       READ_CHAR
*
* Description:
*       Reads a single character from the keyboard and stores it in D1.
*
* Return Value:
*       D1.B - Character read from the keyboard.
*-------------------------------------------------------------------------------
READ_CHAR:
                MOVEM.L     D0, -(SP)           * save registers
                MOVE.B      #5, D0              * prepare system call to read a character
                TRAP        #15                 * make system call
                MOVEM.L     (SP)+, D0           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       PRINT_STRING
*
* Description:
*       Prints a null-terminated string to the console.
*
* Parameters:
*       A1 - Pointer to the null-terminated string to print. If the string is not
*            null-terminated, the program will crash.
*-------------------------------------------------------------------------------
PRINT_STRING:
                MOVEM.L     D0, -(SP)           * save registers
                MOVE.B      #14, D0             * prepare system call to print string
                TRAP        #15                 * make system call
                MOVEM.L     (SP)+, D0           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       PRINT_NEWLINE
*
* Description:
*       Prints an empty line to the console.
*-------------------------------------------------------------------------------
PRINT_NEWLINE:
                MOVEM.L     A1, -(SP)           * save registers
                LEA         empty_line, A1      * load the address of empty line
                JSR         PRINT_STRING        * print empty line
                MOVEM.L     (SP)+, A1           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       PRINT_STRING_LN
*
* Description:
*       Prints a null-terminated string to the console followed by an empty line.
*
* Parameters:
*       A1 - Pointer to the null-terminated string to print.
*-------------------------------------------------------------------------------
PRINT_STRING_LN:
                JSR         PRINT_STRING        * print the string in A1
                JSR         PRINT_NEWLINE       * print empty line
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       CLEAR_SCREEN
*
* Description:
*       Clears the console screen.
*-------------------------------------------------------------------------------
CLEAR_SCREEN:
                MOVEM.L     D0-D1, -(SP)        * save registers
                MOVE.W      #$FF00, D1          * reposition cursor
                MOVE.B      #11, D0             * prepare system call to clear screen
                TRAP        #15                 * make system call
                MOVEM.L     (SP)+, D0-D1        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       WRITE_COMMA
*
* Description:
*       Write a comma followed by an empty space to the buffer in A0.
*
* Parameters:
*       A0 - Pointer to buffer where ', ' will be written.
*-------------------------------------------------------------------------------
WRITE_COMMA:
            MOVE.B          #',', (A0)+         * append comma
            MOVE.B          #' ', (A0)+         * append white space
            RTS                                 * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       PAD_BUFFER
*
* Description:
*       Pads the output_buffer with whitespace to ensure it has a length of 10
*       characters.
*-------------------------------------------------------------------------------
PAD_BUFFER:
                MOVEM.L     D0, -(SP)           * save registers
                LEA         output_buffer, A0   * load in output buffer
                MOVE.L      #10, D0             * loop counter

PAD_LOOP:       CMP.B       #0, (A0)            * check for empty value
                BEQ         PAD_ADD             * add padding
                BRA         PAD_SKIP            * skip padding

PAD_ADD:        MOVE.B      #' ', (A0)          * pad buffer with white space
PAD_SKIP        ADD         #1, A0              * increment to the next byte
                DBF         D0, PAD_LOOP        * repeat
                MOVEM.L     (SP)+, D0           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       CLEAR_INPUT_BUFFER
*
* Description:
*       Clears the input_buffer by filling it with zeros.
*-------------------------------------------------------------------------------
CLEAR_INPUT_BUFFER:
                MOVEM.L     A0/D0, -(SP)        * save registers
                LEA         input_buffer, A0    * load address of input_buffer into A0
                MOVE.L      #BUFFER_SIZE, D0    * set D0 to the number of bytes to clear
CIB_CLEAR:      CLR.B       (A0)+               * clear the byte and increment A0
                DBF         D0, CIB_CLEAR       * decrement D0 and loop until it becomes zero
                MOVEM.L     (SP)+, A0/D0        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       CLEAR_OUTPUT_BUFFER
*
* Description:
*       Clears the output_buffer by filling it with zeros.
*-------------------------------------------------------------------------------
CLEAR_OUTPUT_BUFFER:
                MOVEM.L     A0/D0, -(SP)        * save registers
                LEA         output_buffer, A0   * load address of output_buffer into A0
                MOVE.L      #BUFFER_SIZE, D0    * set D0 to the number of bytes to clear
COB_CLEAR:      CLR.B       (A0)+               * clear the byte and increment A0
                DBF         D0, COB_CLEAR       * decrement D0 and loop until it becomes zero
                MOVEM.L     (SP)+, A0/D0        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       WRITE_TO_BUFFER
*
* Description:
*       Writes the null-terminated string in A1 to the buffer in A0.
*
* Parameters:
*       A0 - Buffer to write to.
*       A1 - Null-terminated string to write.
*-------------------------------------------------------------------------------
WRITE_TO_BUFFER:
                MOVEM.L     A1/D0, -(SP)        * save registers

WTB_LOOP:       MOVE.B      (A1)+, D0           * load character from string
                BEQ         WTB_END             * if end of string, exit loop
                MOVE.B      D0, (A0)+           * write character to buffer
                BRA         WTB_LOOP            * repeat until end of string

WTB_END:        MOVEM.L     (SP)+, A1/D0        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       CLEAR_REGISTERS
*
* Description:
*       Clears register D0-D7 and A0-A6 by filling them with zeros. The stack
*       pointer (A7) is left untouched.
*-------------------------------------------------------------------------------
CLEAR_REGISTERS:
                MOVE.L      #0, D0              * clear data registers
                MOVE.L      #0, D1
                MOVE.L      #0, D2
                MOVE.L      #0, D3
                MOVE.L      #0, D4
                MOVE.L      #0, D5
                MOVE.L      #0, D6
                MOVE.L      #0, D7
                MOVE.L      #0, A0              * clear address registers
                MOVE.L      #0, A1
                MOVE.L      #0, A2
                MOVE.L      #0, A3
                MOVE.L      #0, A4
                MOVE.L      #0, A5
                MOVE.L      #0, A6
                RTS                             * return to caller




*-------------------------------------------------------------------------------
* text section
*-------------------------------------------------------------------------------
                ORG         TEXT_SECTION

* -------------- variables -----------------------------------------------------
start_addr      DC.L        $0          * address of instruction to disassemble
end_addr        DC.L        $0          * address of the last instruction to disassemble
inst_offset     DC.L        $2          * offset to the next instruction
input_buffer    DS.B        BUFFER_SIZE * buffer to store string user input (256 chars)
output_buffer   DS.B        BUFFER_SIZE * buffer to store string to display (256 chars)

long_string_buf DC.B       '        ', 0
word_string_buf DC.B       '    ', 0

* -------------- info messages -------------------------------------------------
rule_msg        DC.B        'When entering the memory address to load in a program,', CR, LF
                DC.B        'the following restrictions apply:',                      CR, LF, CR, LF, HT
                DC.B        '1. Address must be in hexadecimal format.',              CR, LF, HT
                DC.B        '2. Address must be an EVEN number.',                     CR, LF, HT
                DC.B        '3. Starting address must less than ending address.',     CR, LF, HT
                DC.B        '4. Address must be in longword form:   xxxxxxxx',        CR, LF, HT
                DC.B        '5. Starting address must greater than: 00000000',        CR, LF, HT
                DC.B        '6. Ending address must be less than:   00FFFFFF.',       CR, LF, 0

welcome_msg     DC.B        'Welcome to the 68K disassembler!',          CR, LF,              0
goodbye_msg     DC.B        'Thank you for using the 68K disassembler!', CR, LF, CR, LF,      0
restart_msg     DC.B        'Do you want to restart or quit? Enter "R" to restart, or "Q" to quit.', CR, LF, HT
                DC.B        'Enter (R/Q): ', 0
continue_msg    DC.B        'Press enter to disassemble another page or anything else to quit: ', 0
finish_msg      DC.B        'Finished disassembling instructions!', 0

* -------------- error messages ------------------------------------------------
error_msg       DC.B        'Error: received invalid input.',                      CR, LF, 0
error_msg_h     DC.B        'Error: input not valid hex string in longword form.', CR, LF, 0
error_msg_l     DC.B        'Error: input less than min allowable value.',         CR, LF, 0
error_msg_g     DC.B        'Error: input greater than max allowable value.',      CR, LF, 0
error_msg_e     DC.B        'Error: address is not even.',                         CR, LF, 0

start_msg       DC.B        'Enter starting memory address : $', 0
end_msg         DC.B        'Enter ending memory address   : $', 0

empty_line      DC.B        ' ', CR, LF, 0

* -------------- op codes and other values -------------------------------------
string_data     DC.B        'DATA',    0
string_nop      DC.B        'NOP',     0
string_rts      DC.B        'RTS',     0
string_jsr      DC.B        'JSR',     0

string_moveq    DC.B        'MOVEQ.L', 0
string_moveb    DC.B        'MOVE.B',  0
string_movew    DC.B        'MOVE.W',  0
string_movel    DC.B        'MOVE.L',  0

string_moveaw   DC.B        'MOVEA.W', 0
string_moveal   DC.B        'MOVEA.L', 0
string_lea      DC.B        'LEA.L',   0

string_bcc      DC.B        'BCC',     0
string_bgt      DC.B        'BGT',     0
string_ble      DC.B        'BLE',     0
string_beq      DC.B        'BEQ',     0
string_bra      DC.B        'BRA',     0

string_not      DC.B        'NOT',     0
string_or       DC.B        'OR',      0
string_and      DC.B        'AND',     0

string_add      DC.B        'ADD',     0
string_adda     DC.B        'ADDA',    0
string_addq     DC.B        'ADDQ',    0
string_sub      DC.B        'SUB',     0

string_ls       DC.B        'LS',      0
string_as       DC.B        'AS',      0
string_ro       DC.B        'RO',      0

string_byte     DC.B        '.B',      0
string_word     DC.B        '.W',      0
string_long     DC.B        '.L',      0
string_sep      DC.B        ', '       0

                END    START            * last line of source
