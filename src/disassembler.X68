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
BUFFER_SIZE     EQU         $00000100
CODE_SEC        EQU         $00001000
TEXT_SEC        EQU         $00006000

SHIFT_12        EQU         12


START:          ORG         CODE_SEC
                LEA         welcome_msg, A1     * load welcome message
                JSR         PRINT_STRING_LN     * print welcome message

MAIN:
                LEA         STACK, SP           * reset stack pointer
                JSR         CLEAR_REGISTERS     * set all register values to 0

                * print rules for input
                LEA         rule_msg, A1
                JSR         PRINT_STRING_LN

                * get starting address from user
                LEA         start_msg, A1
                JSR         GET_HEX_INPUT
                MOVE.L      D0, start_addr

                * get ending address from user
                LEA         end_msg, A1
                JSR         GET_HEX_INPUT
                MOVE.L      D0, end_addr

                * disassemble instructions
                JSR         DISASSEMBLE

PROGRAM_END:
                JSR         PRINT_NEWLINE       * print empty line
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

                MOVE.L      start_addr, D0      * load start_addr into D0
                MOVE.L      end_addr, D1        * load end_addr into D1

                MOVEQ       #25, D2             * set loop counter to 25

DIS_LOOP:       MOVE.L      start_addr, D0      * reload start_addr into D0
                MOVE.L      end_addr, D1        * reload end_addr into D1
                CMP.L       D1, D0              * compare start_addr and end_addr
                BGE         DIS_END             * exit loop if start_addr >= end_addr

                JSR         DISASSEMBLE_PAGE    * call DECODE_INSTRUCTION

                * check if all instructions have been decoded
                MOVE.L      start_addr, D0      * reload start_addr into D0
                MOVE.L      end_addr, D1        * reload end_addr into D1
                CMP.L       D1, D0              * compare start_addr and end_addr
                BGE         DIS_END             * exit loop if start_addr >= end_addr

                * more instructions left to decode, ask user if they want to continue
                LEA         continue_msg, A1    * load address of continue message into A1
                JSR         PRINT_STRING        * print continue message
                JSR         READ_CHAR           * read character from keyboard

                CMP.B       #CR, D1             * check if user entered "enter"
                BEQ         DIS_LOOP            * disassemble next page

DIS_END:        LEA         finish_msg, A1      * load address of finish message into A1
                JSR         PRINT_NEWLINE       * print empty line
                JSR         PRINT_STRING_LN     * print message with and an empty line
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

                MOVE.L      start_addr, D0      * load start_addr into D0
                MOVE.L      end_addr, D1        * load end_addr into D1

                MOVEQ       #25, D2             * set loop counter to 25

DISP_LOOP:      MOVE.L      start_addr, D0      * reload start_addr into D0
                MOVE.L      end_addr, D1        * reload end_addr into D1
                CMP.L       D1, D0              * compare start_addr and end_addr
                BGE         DISP_END            * exit loop if start_addr >= end_addr

                JSR         DECODE_INSTRUCTION  * call DECODE_INSTRUCTION
                JSR         PRINT_NEWLINE       * print empty line
                DBF         D2, DISP_LOOP       * decrement counter and loop if not zero

DISP_END:       MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       DECODE_INSTRUCTION
*
* Description:
*       Placeholder subroutine that decodes the instruction at start_addr.
*
*       Currently, this subroutine prints the address stored in start_addr
*       and the corresponding word data held at that address in memory.
*-------------------------------------------------------------------------------
DECODE_INSTRUCTION:
                MOVEM.L     A0-A6/D0-D7, -(SP)  * save registers
                JSR         CLEAR_REGISTERS     * clear registers

                * print current address
                MOVE.L      start_addr, D0      * load start_addr into D0
                JSR         LONG_TO_HEX_STRING  * convert address to hex string
                LEA         long_string_buf, A1 * load address of hex string
                JSR         PRINT_STRING        * print hex string

                LEA         JUMP_TABLE_ONE, A0  * load address of first jump table
                JSR         LOAD_CURRENT_WORD   * load word data of current instruction to decode
                MOVE.B      #SHIFT_12, D1       * shift 12 bits to the right
                LSR.W       D1, D0              * isolate the first 4 bits to decode opcode name

                MULU        #6, D0              * form offset
                JSR         0(A0, D0)           * jump indirect with index

                ADD.L       #2, start_addr      * increment start_addr by word size

                MOVEM.L     (SP)+, A0-A6/D0-D7  * restore registers
                RTS                             * return to the caller

JUMP_TABLE_ONE:
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
                JSR         INVALID_OPCODE
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
                JSR         INVALID_OPCODE
                RTS                             * return to caller


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
                JSR         INVALID_OPCODE
                RTS                             * return to caller

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
                JSR         INVALID_OPCODE
                RTS                             * return to caller

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
                JSR         CLEAR_OUTPUT_BUFFER
                LEA         output_buffer, A1
                LEA         output_buffer, A2

                * check if instruction is NOP
                JSR         LOAD_CURRENT_WORD   * load current instruction
                CMP         #$4E71, D0          * compare against NOP
                BEQ         MATCHED_NOP

                CMP         #$4E75, D0          * compare against RTS
                BEQ         MATCHED_RTS

                * couldn't decode word to valid instruction
                JSR         INVALID_OPCODE
                BRA         _0100_RETURN

MATCHED_NOP:
                * load "NOP" into output buffer
                MOVE.B      #HT, (A2)+
                MOVE.B      #'N', (A2)+
                MOVE.B      #'O', (A2)+
                MOVE.B      #'P', (A2)+
                JSR         PRINT_STRING        * print "NOP"
                BRA         _0100_RETURN        * done decoding NOP

MATCHED_RTS:
                * load "RTS" into output buffer
                MOVE.B      #HT, (A2)+
                MOVE.B      #'R', (A2)+
                MOVE.B      #'T', (A2)+
                MOVE.B      #'S', (A2)+
                JSR         PRINT_STRING        * print "RTS"
                BRA         _0100_RETURN        * done decoding RTS

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
                JSR         INVALID_OPCODE
                RTS                             * return to caller


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
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_0111
*
* Description:
*       Decodes the following opcodes:
*           - MOVEQ.L
*-------------------------------------------------------------------------------
CODE_0111:
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1000
*
* Description:
*       Decodes the following opcodes:
*           - OR
*-------------------------------------------------------------------------------
CODE_1000:
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1001
*
* Description:
*       Decodes the following opcodes:
*           - SUB
*-------------------------------------------------------------------------------
CODE_1001:
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1010
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1010.
*-------------------------------------------------------------------------------
CODE_1010:
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1011
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1011.
*-------------------------------------------------------------------------------
CODE_1011:
                JSR         INVALID_OPCODE
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
                JSR         INVALID_OPCODE
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
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1101
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
                JSR         INVALID_OPCODE
                RTS                             * return to caller


*-------------------------------------------------------------------------------
* Subroutine:
*       CODE_1111
*
* Description:
*       This disassembler does not decode any opcodes that begins with 1111.
*-------------------------------------------------------------------------------
CODE_1111:
                JSR         INVALID_OPCODE
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       INVALID_OPCODE
*
* Description:
*       Displays instructions that cannot be decoded, either because they do not
*       disassemble as op codes or because you aren't able to decode, in the
*       follow format:
*           <memory location>       DATA       $WXYZ
*-------------------------------------------------------------------------------
INVALID_OPCODE:
                MOVEM.L     A1-A2, -(SP)        * save registers
                JSR         CLEAR_OUTPUT_BUFFER * clear output buffer
                LEA         output_buffer, A2   * load address of output buffer

                * load "DATA" into output buffer
                MOVE.B      #HT, (A2)+          * append tab character
                MOVE.B      #'D', (A2)+         * append 'D'
                MOVE.B      #'A', (A2)+         * append 'A'
                MOVE.B      #'T', (A2)+         * append 'T'
                MOVE.B      #'A', (A2)+         * append 'A'
                MOVE.B      #HT, (A2)+          * append tab character
                MOVE.B      #'$', (A2)+         * append '$'

                LEA         output_buffer, A1   * load address of output buffer
                JSR         PRINT_STRING        * print "DATA $"

                * load the value at start_addr into D0 and print it
                JSR         LOAD_CURRENT_WORD   * load invalid word
                JSR         WORD_TO_HEX_STRING  * convert word value to hex string
                LEA         word_string_buf, A1 * load address of converted hex string
                JSR         PRINT_STRING        * print hex string

                MOVEM.L     (SP)+, A1-A2        * restore registers
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



********************************************************************************
* Conversion subroutines
********************************************************************************

*-------------------------------------------------------------------------------
* Subroutine:
*       READ_STRING
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

                MOVE.B      #0, (A1)            * null-terminate hex buffer

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
                CMP         #0, D1              * check if conversion was successful
                BNE         INVALID_INPUT       * input was not a valid hex string

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
*       enters "R" or "r", it branches to MAIN to restart the program. If they
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
                BEQ         MAIN                * entered 'R' - restart

                CMP.B       #'r', D1            * compare user input in D1
                BEQ         MAIN                * entered 'r' - restart

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
                ORG         TEXT_SEC

* -------------- variables --------------
start_addr      DC.L        $0          * address of instruction to disassemble
end_addr        DC.L        $0          * address of the last instruction to disassemble
input_buffer    DS.B        BUFFER_SIZE * buffer to store string user input (256 chars)
output_buffer   DS.B        BUFFER_SIZE * buffer to store string to display (256 chars)

long_string_buf DC.B       '         ', 0
word_string_buf DC.B       '     ', 0

* -------------- info messages --------------
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
restart_msg     DC.B        'Do you want to restart or quite? Enter "R" to restart, or "Q" to quit.', CR, LF, HT
                DC.B        'Enter (R/Q): ', 0
continue_msg    DC.B        'Press enter to disassemble another page or anything else to quit: ', 0
finish_msg      DC.B        'Finished disassembling instructions!', 0

* -------------- error messages --------------
error_msg       DC.B        'Error: received invalid input.',                      CR, LF, 0
error_msg_h     DC.B        'Error: input not valid hex string in longword form.', CR, LF, 0
error_msg_l     DC.B        'Error: input less than min allowable value.',         CR, LF, 0
error_msg_g     DC.B        'Error: input greater than max allowable value.',      CR, LF, 0
error_msg_e     DC.B        'Error: address is not even.',                         CR, LF, 0

start_msg       DC.B        'Enter starting memory address : $', 0
end_msg         DC.B        'Enter ending memory address   : $', 0

empty_line      DC.B        ' ', CR, LF, 0

                END    START            * last line of source
