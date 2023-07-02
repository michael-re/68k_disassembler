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


START:          ORG         CODE_SEC
                LEA         welcome_msg, A1     * load welcome message
                JSR         PRINT_STRING_LN     * print welcome message

MAIN:
                LEA         STACK, SP           * reset stack pointer
                JSR         CLEAR_REGISTERS     * set all register values to 0

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

                JSR         NUMBER_TO_HEX_STRING
                LEA         hex_string_buf, A1
                JSR         PRINT_NEWLINE
                JSR         PRINT_STRING_LN
                SIMHALT

PROGRAM_END:
                JSR         PRINT_NEWLINE       * print empty line
                JSR         PRINT_NEWLINE       * print empty line
                LEA         goodbye_msg, A1     * load goodbye message
                JSR         PRINT_STRING_LN     * display goodbye message
                SIMHALT                         * halt simulator




********************************************************************************
* Conversion subroutines
********************************************************************************

*-------------------------------------------------------------------------------
* Subroutine:
*       READ_STRING
*
* Description:
*       Convert null-terminated string in A1 that represents a hex number into
*       a integer value.
*
* Parameters:
*       A1 - pointer to null-terminated string containing hex string to convert.
*
* Return Value:
*       D0 - The integer value hex string represents. On failure, -1 is
*            returned.
*       D1 - Returns 0 on success, -1 (FFFFFFFF) on error
*-------------------------------------------------------------------------------
STRING_TO_NUMBER:
                MOVEM.L     A1/D2, -(SP)        * save registers
                MOVE.L      #0, D0              * hold return value
                MOVE.L      #0, D1              * hold current string being converted
                MOVE.L      #8, D2              * loop counter

STN_CONVERT:    CMP.L       #0, D2
                BEQ         STN_LOOP_END

                LSL.L       #4, D0              * multiply running total by 16 (using shift to prevent sign extension)
                MOVE.L      #0, D1              * clear value of D1
                MOVE.B      (A1)+, D1           * load ascii value being converted

                CMP.B       #'0', D1            * check if its less than '0'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'9', D1            * check it its less than '9'
                BLS         ASCII_NUMBER        * it's a hex digit, convert it

                CMP.B       #'A', D1            * check if its less than 'A'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'F', D1            * check if its less than 'F'
                BLS         ASCII_C_LETTER      * it's a hex digit, convert it

                CMP.B       #'a', D1            * check if its less than 'a'
                BLT         STN_ERROR           * branch to invalid input

                CMP.B       #'f', D1            * Check if its less than 'f'
                BLS         ASCII_L_LETTER      * it's a hex digit, convert it

STN_ERROR:      MOVE.L      #-1, D0             * set D0 to 0xFFFFFFFF
                MOVE.L      #-1, D1             * set error flag
                BRA         STN_RETURN

ASCII_NUMBER:   SUB         #'0', D1            * Convert ascii digit to number
                BRA         STN_CONTINUE

ASCII_L_LETTER: SUB         #'a', D1            * Convert ascii lower case letter to number
                ADD         #10, D1
                BRA         STN_CONTINUE

ASCII_C_LETTER: SUB         #'A', D1            * Convert ascii capital case letter to number
                ADD         #10, D1
                BRA         STN_CONTINUE

STN_CONTINUE:   ADD         D1, D0              * add current digit to total
                SUB         #1, D2              * decrement counter
                BRA         STN_CONVERT

STN_LOOP_END:   MOVE.L      #0, D1              * disable error flag
STN_RETURN:     MOVEM.L     (SP)+, A1/D2        * restore registers
                RTS                             * return to caller




*-------------------------------------------------------------------------------
* Subroutine:
*       NUMBER_TO_HEX_STRING
*
* Description:
*       Converts a longword value in D0 into a hexadecimal string representation
*       and stores it in the hex_string_buf as a null-terminated string.
*
* Parameters:
*       D0 - Longword value to be converted to a hexadecimal string.
*
* Return Value:
*       hex_string_buf - Null-terminated string of the integer value in D0
*                        as a hexadecimal string.
*-------------------------------------------------------------------------------
NUMBER_TO_HEX_STRING:
                MOVEM.L     A1/D0-D2, -(SP)     * save registers
                MOVE.L      #8, D1              * loop counter
                MOVE.B      D0, D2              * the current digit to convert
                LEA         hex_string_buf, A1  * load address of hex buffer
                ADDA.L      D1, A1              * adjust A1 by the loop counter to fill in reverse order

NTS_CONVERT:    ANDI.L      #$0000000F, D2      * mask out lower 4 bits of D2 to git digit
                ADD.B       #'0', D2            * convert the digit to ascii hex character
                CMP.B       #'9', D2            * check if digit is greater than '9'
                BLS         NTS_STORE           * branch if it's a digit from 0 to 9
                ADD.B       #7, D2              * adjust the ascii value for letters A to F
NTS_STORE:      MOVE.B      D2, -(A1)           * store the hex character in the buffer

                LSR.L       #4, D0              * shift right to get the next digit
                MOVE.L      D0, D2              * copy value to D2
                DBF         D1, NTS_CONVERT     * decrement loop counter and loop if not zero

                MOVE.B      #0, (A1)            * null-terminate hex buffer

                MOVEM.L     (SP)+, A1/D0-D2     * restore registers
                RTS                             * return to caller





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
* Parameters
*       A1 - Pointer to null-terminated string containing prompt asking for
*            the user input.
*
* Return Value:
*       D0 - The integer value hex string represents.
*-------------------------------------------------------------------------------
GET_HEX_INPUT:
                MOVEM.L     A1/D1, -(SP)        * save registers
                JSR         PRINT_STRING        * print prompt for user input
                JSR         READ_STRING         * read user input

                LEA         error_msg_h, A1
                CMP.W       #8, D1              * check if input is the right length
                BNE         INVALID_INPUT       * input either too long or too short

                LEA         input_buffer, A1    * load in starting address of input
                JSR         STRING_TO_NUMBER    * convert string input to integer

                LEA         error_msg_h, A1
                CMP         #0, D1              * check if conversion was successful
                BNE         INVALID_INPUT       * input was not a hex string

                LEA         error_msg_l, A1
                CMP.L       #MIN_ADDR, D0       * check starting address range
                BLT.L       INVALID_INPUT       * starting address out of range

                LEA         error_msg_g, A1
                MOVE.L      #MAX_ADDR, D1       * load in max value for ending address (too big to fit as immediate data)
                CMP.L       D1, D0              * check ending address range
                BGT         INVALID_INPUT       * ending address out of range

                MOVE.L      D0, D1              * copy converted number into D1
                AND.L       #1, D1              * check if least significant bit is 0

                LEA         error_msg_e, A1
                BNE         INVALID_INPUT       * address is not even

                MOVEM.L     (SP)+, A1/D1        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       INVALID_INPUT
*
* Description:
*       Prints the error message that result in the invalid input stored in A1
*       and calls RESTART_PROMPT to check if the user wants to restart the
*       program or quit.
*
* Parameters:
*       A1 - The error that result in the invalid input.
*-------------------------------------------------------------------------------
INVALID_INPUT:
                JSR         PRINT_STRING_LN
                LEA         error_msg, A1
                JSR         PRINT_STRING
                BRA         RESTART_PROMPT



*-------------------------------------------------------------------------------
* Subroutine:
*       RESTART_PROMPT
*
* Description:
*       Asks the user if they want to retart the program or quit. If the user
*       enters "R" or "r", this branches to main to restart the program. If they
*       enter "Q" or "q", it branches to PROGRAM_END to terminate the program.
*
*-------------------------------------------------------------------------------
RESTART_PROMPT:
                LEA         restart_msg, A1
                JSR         PRINT_STRING
                JSR         READ_CHAR
                JSR         CLEAR_SCREEN        * clear the screen

                CMP.B       #'R', D1            * compare user input in D1
                BEQ         MAIN                * entered 'R' - restart

                CMP.B       #'r', D1            * compare user input in D1
                BEQ         MAIN                * entered 'r' - restart

                CMP.B       #'Q', D1            * compare user input in D1
                BEQ         PROGRAM_END         * entered 'Q' - terminate

                CMP.B       #'q', D1            * compare user input in D1
                BEQ         PROGRAM_END         * entered 'q' - terminate

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
*       D1.W - length of string read from user
*       A1   - pointer to (input_buffer) null-terminated string read from user.
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
*       Reads a single character from the keyboard and store it D1.
*
* Return Value:
*       D1.B - Character read from keyboard.
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
*       A1 - Pointer to null-terminated string to print. If the string is not
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
*       PRINT_STRING
*
* Description:
*       Prints empty line to console.
*-------------------------------------------------------------------------------
PRINT_NEWLINE:
                MOVEM.L     A1, -(SP)           * save registers
                LEA         empty_line, A1      * load address of empty line
                JSR         PRINT_STRING        * print the empty line
                MOVEM.L     (SP)+, A1           * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       PRINT_STRING_LN
*
* Description:
*       Prints a null-terminated string to the console followed by an empty
*       line.
*
* Parameters:
*       A1 - Pointer to null-terminated string to print.
*-------------------------------------------------------------------------------
PRINT_STRING_LN:
                JSR         PRINT_STRING        * print string in A1
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
*       Clears input_buffer by filling it with zeros.
*-------------------------------------------------------------------------------
CLEAR_INPUT_BUFFER:
                MOVEM.L     A0/D0, -(SP)        * save registers
                LEA         input_buffer, A0    * load address of input_buffer into A0
                MOVE.L      #BUFFER_SIZE, D0    * set D0 to the number of bytes to clear
                CLR.B       (A0)+               * clear the byte and increment A0
                DBF         D0, *-4             * decrement D0 and loop until it becomes zero
                MOVEM.L     (SP)+, A0/D0        * restore registers
                RTS                             * return to caller



*-------------------------------------------------------------------------------
* Subroutine:
*       CLEAR_OUTPUT_BUFFER
*
* Description:
*       Clears output_buffer by filling it with zeros.
*-------------------------------------------------------------------------------
CLEAR_OUTPUT_BUFFER:
                MOVEM.L     A0/D0, -(SP)        * save registers
                LEA         output_buffer, A0   * load address of output_buffer into A0
                MOVE.L      #BUFFER_SIZE, D0    * set D0 to the number of bytes to clear
                CLR.B       (A0)+               * clear the byte and increment A0
                DBF         D0, *-4             * decrement D0 and loop until it becomes zero
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
                MOVE.L      #0, D0                  * clear data registers
                MOVE.L      #0, D1
                MOVE.L      #0, D2
                MOVE.L      #0, D3
                MOVE.L      #0, D4
                MOVE.L      #0, D5
                MOVE.L      #0, D6
                MOVE.L      #0, D7
                MOVE.L      #0, A0                  * clear address registers
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

* create global variables to store values
start_addr      DC.L        $0          * address of the first instruction to disassemble
end_addr        DC.L        $0          * address of the last instruction to disassemble
curr_addr       DS.L        $0          * address of current instruction being disassembled
input_buffer    DS.B        BUFFER_SIZE * buffer to store string user input (256 chars)
output_buffer   DS.B        BUFFER_SIZE * buffer to store string to display (256 chars)
hex_string_buf  DC.B        '        ', 0

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
continue_msg    DC.B        'Press enter to continue or anything else to quit: ', 0

* error messages
error_msg       DC.B        'Error: received invalid input.',                      CR, LF, 0
error_msg_h     DC.B        'Error: input not valid hex string in longword form.', CR, LF, 0
error_msg_l     DC.B        'Error: input less than min allowable value.',         CR, LF, 0
error_msg_g     DC.B        'Error: input greater than max allowable value.',      CR, LF, 0
error_msg_e     DC.B        'Error: address is not even.',                         CR, LF, 0

start_msg       DC.B        'Enter starting memory address : $', 0
end_msg         DC.B        'Enter ending memory address   : $', 0

empty_line      DC.B        ' ', CR, LF, 0

                END    START            * last line of source
