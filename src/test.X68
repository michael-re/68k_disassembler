*-------------------------------------------------------------------------------
* Title      : 68K disassembler test
* Written by : Michael
* Date       : 07/21/2023
* Description: Test file
*-------------------------------------------------------------------------------
WORD        EQU         $FFFFFFFA
LONG        EQU         $0000FFFA

START:      ORG         $00004000

            * first test for group 9 - testing positive displacement
            NOP
            NOP
            JSR     BCC_END               * use JSR to validate branch label value
            BGT     BCC_END
            BLE     BCC_END
            BEQ     BCC_END
            BRA     BCC_END
            JSR     BCC_END               * use JSR to validate branch label value

*--------------------------------- GROUP 1 NOP ---------------------------------
            NOP
            NOP

*--------------------------------- GROUP 2 MOVE --------------------------------
********************************************************************************
* MOVE: ALL PASSED                                                             *
********************************************************************************
            *-------------------------------------------------------------------
            *------------------------------ MOVE.B -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVE.B      D0, D1              * Dn
            MOVE.B      D2, (A0)
            MOVE.B      D3, (A1)+
            MOVE.B      D4, -(A2)
            MOVE.B      D5, WORD
            MOVE.B      D6, LONG

            NOP
            MOVE.B      (A0), D0            * (An)
            MOVE.B      (A1), (A1)
            MOVE.B      (A2), (A1)+
            MOVE.B      (A3), -(A2)
            MOVE.B      (A4), WORD
            MOVE.B      (A5), LONG

            NOP
            MOVE.B      (A0)+, D0           * (An)+
            MOVE.B      (A1)+, (A0)
            MOVE.B      (A2)+, (A1)+
            MOVE.B      (A3)+, -(A2)
            MOVE.B      (A4)+, WORD
            MOVE.B      (A5)+, LONG

            NOP
            MOVE.B      -(A0), D0           * -(An)
            MOVE.B      -(A1), (A0)
            MOVE.B      -(A2), (A1)+
            MOVE.B      -(A3), -(A2)
            MOVE.B      -(A4), WORD
            MOVE.B      -(A5), LONG

            NOP
            MOVE.B      WORD, D0           * (xxx).W
            MOVE.B      WORD, (A0)
            MOVE.B      WORD, (A1)+
            MOVE.B      WORD, -(A2)
            MOVE.B      WORD, $1234
            MOVE.B      WORD, $1234568

            NOP
            MOVE.B      LONG, D0       * (xxx).L
            MOVE.B      LONG, (A0)
            MOVE.B      LONG, (A1)+
            MOVE.B      LONG, -(A2)
            MOVE.B      LONG, $1234
            MOVE.B      LONG, $12345678

            NOP
            MOVE.B      #$00, D0            * #<data>
            MOVE.B      #$00, (A0)
            MOVE.B      #$AA, (A1)+
            MOVE.B      #$AA, -(A2)
            MOVE.B      #$FF, $1234
            MOVE.B      #$11, $12345678

            *-------------------------------------------------------------------
            *------------------------------ MOVE.W -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVE.W      D0, D1              * Dn
            MOVE.W      D2, (A0)
            MOVE.W      D3, (A1)+
            MOVE.W      D4, -(A2)
            MOVE.W      D5, WORD
            MOVE.W      D6, LONG

            NOP
            MOVE.W      (A0), D0            * (An)
            MOVE.W      (A1), (A1)
            MOVE.W      (A2), (A1)+
            MOVE.W      (A3), -(A2)
            MOVE.W      (A4), WORD
            MOVE.W      (A5), LONG

            NOP
            MOVE.W      (A0)+, D0           * (An)+
            MOVE.W      (A1)+, (A0)
            MOVE.W      (A2)+, (A1)+
            MOVE.W      (A3)+, -(A2)
            MOVE.W      (A4)+, WORD
            MOVE.W      (A5)+, LONG

            NOP
            MOVE.W      -(A0), D0           * -(An)
            MOVE.W      -(A1), (A0)
            MOVE.W      -(A2), (A1)+
            MOVE.W      -(A3), -(A2)
            MOVE.W      -(A4), WORD
            MOVE.W      -(A5), LONG

            NOP
            MOVE.W      WORD, D0           * (xxx).W
            MOVE.W      WORD, (A0)
            MOVE.W      WORD, (A1)+
            MOVE.W      WORD, -(A2)
            MOVE.W      WORD, $1234
            MOVE.W      WORD, $1234568

            NOP
            MOVE.W      LONG, D0       * (xxx).L
            MOVE.W      LONG, (A0)
            MOVE.W      LONG, (A1)+
            MOVE.W      LONG, -(A2)
            MOVE.W      LONG, $1234
            MOVE.W      LONG, $12345678

            NOP
            MOVE.W      #$00, D0            * #<data>
            MOVE.W      #$00, (A0)
            MOVE.W      #$AA, (A1)+
            MOVE.W      #$AA, -(A2)
            MOVE.W      #$FF, $1234
            MOVE.W      #$11, $12345678

            *-------------------------------------------------------------------
            *------------------------------ MOVE.L -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVE.L      D0, D1              * Dn
            MOVE.L      D2, (A0)
            MOVE.L      D3, (A1)+
            MOVE.L      D4, -(A2)
            MOVE.L      D5, WORD
            MOVE.L      D6, LONG

            NOP
            MOVE.L      (A0), D0            * (An)
            MOVE.L      (A1), (A1)
            MOVE.L      (A2), (A1)+
            MOVE.L      (A3), -(A2)
            MOVE.L      (A4), WORD
            MOVE.L      (A5), LONG

            NOP
            MOVE.L      (A0)+, D0           * (An)+
            MOVE.L      (A1)+, (A0)
            MOVE.L      (A2)+, (A1)+
            MOVE.L      (A3)+, -(A2)
            MOVE.L      (A4)+, WORD
            MOVE.L      (A5)+, LONG

            NOP
            MOVE.L      -(A0), D0           * -(An)
            MOVE.L      -(A1), (A0)
            MOVE.L      -(A2), (A1)+
            MOVE.L      -(A3), -(A2)
            MOVE.L      -(A4), WORD
            MOVE.L      -(A5), LONG

            NOP
            MOVE.L      WORD, D0           * (xxx).W
            MOVE.L      WORD, (A0)
            MOVE.L      WORD, (A1)+
            MOVE.L      WORD, -(A2)
            MOVE.L      WORD, $1234
            MOVE.L      WORD, $1234568

            NOP
            MOVE.L      LONG, D0       * (xxx).L
            MOVE.L      LONG, (A0)
            MOVE.L      LONG, (A1)+
            MOVE.L      LONG, -(A2)
            MOVE.L      LONG, $1234
            MOVE.L      LONG, $12345678

            NOP
            MOVE.L      #$FF00, D0            * #<data>
            MOVE.L      #$0000, (A0)
            MOVE.L      #$AA00, (A1)+
            MOVE.L      #$AA00, -(A2)
            MOVE.L      #$FF00, $1234
            MOVE.L      #$1100, $12345678


            *-------------------------------------------------------------------
            *------------------------------ MOVEQ.L ----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVEQ.L     #$00, D0
            MOVEQ.L     #$11, D1
            MOVEQ.L     #$AA, D2
            MOVEQ.L     #$BB, D3
            MOVEQ.L     #$FF, D4


            *-------------------------------------------------------------------
            *----------------------------- MOVEA.W -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVEA.W     D0, A0
            MOVEA.W     A1, A1
            MOVEA.W     (A1), A2
            MOVEA.W     (A1)+, A3
            MOVEA.W     -(A1), A4
            MOVEA.W     $0000FFFF, A5
            MOVEA.W     $FFFFFFFF, A6
            MOVEA.W     #$0000FFFF, A7
            MOVEA.W     #$FFFFFFFF, SP


            *-------------------------------------------------------------------
            *----------------------------- MOVEA.L -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            MOVEA.L     D0, A0
            MOVEA.L     A1, A1
            MOVEA.L     (A1), A2
            MOVEA.L     (A1)+, A3
            MOVEA.L     -(A1), A4
            MOVEA.L     $0000FFFF, A5
            MOVEA.L     $FFFFFFFF, A6
            MOVEA.L     #$0000FFFF, A7
            MOVEA.L     #$FFFFFFFF, SP


*--------------------------------- GROUP 3 ADD ---------------------------------
********************************************************************************
* ADD: ALL PASSED                                                              *
********************************************************************************
            *-------------------------------------------------------------------
            *------------------------------- ADD.B -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            ADD.B       D1, D0
            ADD.B       (A0), D1
            ADD.B       (A1)+, D2
            ADD.B       -(A2), D3
            ADD.B       WORD, D4
            ADD.B       LONG, D5

            NOP
            ADD.B       D0, (A0)
            ADD.B       D1, (A1)+
            ADD.B       D2, -(A2)
            ADD.B       D3, WORD
            ADD.B       D4, LONG

            NOP
            ADD.B       (SP), D1
            ADD.B       (SP)+, D1
            ADD.B       -(SP), D1
            ADD.B       $0030, D7
            ADD.B       $FFFF8000, D7


            *-------------------------------------------------------------------
            *------------------------------- ADD.W -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            ADD.W       D1, D0
            ADD.W       A0, D1
            ADD.W       (A1), D2
            ADD.W       (A2)+, D3
            ADD.W       -(A3), D4
            ADD.W       WORD, D5
            ADD.W       LONG, D6

            NOP
            ADD.W       D0, (A0)
            ADD.W       D1, (A1)+
            ADD.W       D2, -(A2)
            ADD.W       D3, WORD
            ADD.W       D4, LONG

            NOP
            ADD.W       A0, D1
            ADD.W       (SP), D1
            ADD.W       (SP)+, D1
            ADD.W       -(SP), D1
            ADD.W       $00008000, D7
            ADD.W       $0030, D7
            ADD.W       $FFFF8000, D7


            *-------------------------------------------------------------------
            *------------------------------- ADD.L -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            ADD.L       D1, D0
            ADD.L       A0, D1
            ADD.L       (A1), D2
            ADD.L       (A2)+, D3
            ADD.L       -(A3), D4
            ADD.L       WORD, D5
            ADD.L       LONG, D6

            NOP
            ADD.L       D0, (A0)
            ADD.L       D1, (A1)+
            ADD.L       D2, -(A2)
            ADD.L       D3, WORD
            ADD.L       D4, LONG

            NOP
            ADD.L       A0, D1
            ADD.L       (SP), D1
            ADD.L       (SP)+, D1
            ADD.L       -(SP), D1
            ADD.L       $00008000, D7
            ADD.L       $0030, D7
            ADD.L       $FFFF8000, D7


            *-------------------------------------------------------------------
            *------------------------------- ADDA ----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            ADDA.W      D0, A0
            ADDA.W      A0, A1
            ADDA.W      (A1), A2
            ADDA.W      -(SP), A3
            ADDA.W      (SP)+, A4
            ADDA.W      WORD, A5
            ADDA.W      LONG, A6
            ADDA.W      #$1234, A7

            NOP
            ADDA.L      D0, A0
            ADDA.L      A0, A1
            ADDA.L      (A1), A2
            ADDA.L      -(SP), A3
            ADDA.L      (SP)+, A4
            ADDA.L      WORD, A5
            ADDA.L      LONG, A6
            ADDA.L      #$1234, A7
            ADDA.L      #LONG, SP


            *-------------------------------------------------------------------
            *------------------------------- ADDQ ----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            ADDQ.B      #1, D0
            * ADDQ.B      #2, A0            * this gives "ERROR: Invalid size code" in EAsy68K
            ADDQ.B      #3, (A1)
            ADDQ.B      #4, (A2)+
            ADDQ.B      #5, -(A3)
            ADDQ.B      #6, WORD
            ADDQ.B      #7, LONG
            ADDQ.B      #8, D7

            NOP
            ADDQ.W      #1, D0
            ADDQ.W      #2, A0
            ADDQ.W      #3, (A1)
            ADDQ.W      #4, (A2)+
            ADDQ.W      #5, -(A3)
            ADDQ.W      #6, WORD
            ADDQ.W      #7, LONG
            ADDQ.W      #8, D7

            NOP
            ADDQ.L      #1, D0
            ADDQ.L      #2, A0
            ADDQ.L      #3, (A1)
            ADDQ.L      #4, (A2)+
            ADDQ.L      #5, -(A3)
            ADDQ.L      #6, WORD
            ADDQ.L      #7, LONG
            ADDQ.L      #8, D7


*--------------------------------- GROUP 4 SUB ---------------------------------
********************************************************************************
* SUB: ALL PASSED                                                              *
********************************************************************************
            *-------------------------------------------------------------------
            *------------------------------- SUB.B -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            SUB.B       D1, D0
            SUB.B       (A0), D1
            SUB.B       (A1)+, D2
            SUB.B       -(A2), D3
            SUB.B       WORD, D4
            SUB.B       LONG, D5

            NOP
            SUB.B       D0, (A0)
            SUB.B       D1, (A1)+
            SUB.B       D2, -(A2)
            SUB.B       D3, WORD
            SUB.B       D4, LONG


            *-------------------------------------------------------------------
            *------------------------------- SUB.W -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            SUB.W       D1, D0
            SUB.W       A0, D1
            SUB.W       (A1), D2
            SUB.W       (A2)+, D3
            SUB.W       -(A3), D4
            SUB.W       WORD, D5
            SUB.W       LONG, D6

            NOP
            SUB.W       D0, (A0)
            SUB.W       D1, (A1)+
            SUB.W       D2, -(A2)
            SUB.W       D3, WORD
            SUB.W       D4, LONG


            *-------------------------------------------------------------------
            *------------------------------- SUB.L -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            SUB.L       D1, D0
            SUB.L       A0, D1
            SUB.L       (A1), D2
            SUB.L       (A2)+, D3
            SUB.L       -(A3), D4
            SUB.L       WORD, D5
            SUB.L       LONG, D6

            NOP
            SUB.L       D0, (A0)
            SUB.L       D1, (A1)+
            SUB.L       D2, -(A2)
            SUB.L       D3, WORD
            SUB.L       D4, LONG


*--------------------------------- GROUP 5 LEA ---------------------------------
********************************************************************************
* LEA: ALL PASSED                                                              *
********************************************************************************
            *-------------------------------------------------------------------
            *------------------------------- LEA.L -----------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            LEA.L       (A0), A0
            LEA.L       WORD, A3
            LEA.L       LONG, A4
            LEA.L       lea_test, A5

lea_test    DC.W        $0
            DC.W        $0
            DC.W        $0
            DC.W        $0

*----------------------------- GROUP 6 AND/OR/NOT ------------------------------
********************************************************************************
*  AND/OR/NOT: ALL PASSED                                                      *
********************************************************************************
            *-------------------------------------------------------------------
            *-------------------------------- AND ------------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            AND.B       D0, D1
            AND.B       (A0), D2
            AND.B       (A1)+, D3
            AND.B       -(A2), D4
            AND.B       WORD, D5
            AND.B       LONG, D6
            AND.B       #12, D7

            NOP
            AND.B       D0, (A0)
            AND.B       D1, (A1)+
            AND.B       D2, -(A2)
            AND.B       D3, WORD
            AND.B       D4, LONG

            NOP
            NOP
            AND.W       D0, D1
            AND.W       (A0), D2
            AND.W       (A1)+, D3
            AND.W       -(A2), D4
            AND.W       WORD, D5
            AND.W       LONG, D6
            AND.W       #12, D7

            NOP
            AND.W       D0, (A0)
            AND.W       D1, (A1)+
            AND.W       D2, -(A2)
            AND.W       D3, WORD
            AND.W       D4, LONG

            NOP
            NOP
            AND.L       D0, D1
            AND.L       (A0), D2
            AND.L       (A1)+, D3
            AND.L       -(A2), D4
            AND.L       WORD, D5
            AND.L       LONG, D6
            AND.L       #12, D7

            NOP
            AND.L       D0, (A0)
            AND.L       D1, (A1)+
            AND.L       D2, -(A2)
            AND.L       D3, WORD
            AND.L       D4, LONG


            *-------------------------------------------------------------------
            *-------------------------------- OR -------------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            OR.B       D0, D1
            OR.B       (A0), D2
            OR.B       (A1)+, D3
            OR.B       -(A2), D4
            OR.B       WORD, D5
            OR.B       LONG, D6
            OR.B       #12, D7

            NOP
            OR.B       D0, (A0)
            OR.B       D1, (A1)+
            OR.B       D2, -(A2)
            OR.B       D3, WORD
            OR.B       D4, LONG

            NOP
            NOP
            OR.W       D0, D1
            OR.W       (A0), D2
            OR.W       (A1)+, D3
            OR.W       -(A2), D4
            OR.W       WORD, D5
            OR.W       LONG, D6
            OR.W       #12, D7

            NOP
            OR.W       D0, (A0)
            OR.W       D1, (A1)+
            OR.W       D2, -(A2)
            OR.W       D3, WORD
            OR.W       D4, LONG

            NOP
            NOP
            OR.L       D0, D1
            OR.L       (A0), D2
            OR.L       (A1)+, D3
            OR.L       -(A2), D4
            OR.L       WORD, D5
            OR.L       LONG, D6
            OR.L       #12, D7

            NOP
            OR.L       D0, (A0)
            OR.L       D1, (A1)+
            OR.L       D2, -(A2)
            OR.L       D3, WORD
            OR.L       D4, LONG


            *-------------------------------------------------------------------
            *-------------------------------- NOT ------------------------------
            *-------------------------------------------------------------------
            NOP
            NOP
            NOT.B       D3
            NOT.B       (A0)
            NOT.B       (A1)+
            NOT.B       -(A2)
            NOT.B       WORD
            NOT.B       LONG

            NOP
            NOP
            NOT.W       D3
            NOT.W       (A0)
            NOT.W       (A1)+
            NOT.W       -(A2)
            NOT.W       WORD
            NOT.W       LONG

            NOP
            NOP
            NOT.L       D3
            NOT.L       (A0)
            NOT.L       (A1)+
            NOT.L       -(A2)
            NOT.L       WORD
            NOT.L       LONG


*------------------------------ GROUP 9 Bcc/BRA --------------------------------
********************************************************************************
*  Bcc/BRA:                                                                    *
********************************************************************************
            *-------------------------------------------------------------------
            *----------------------------- Bcc/BRA -----------------------------
            *-------------------------------------------------------------------
BCC_START:  NOP
            NOP
            JSR     START               * use JSR to validate branch label value
            BGT     START
            BLE     START
            BEQ     START
            BRA     START
            JSR     START               * use JSR to validate branch label value

            NOP
            JSR     BCC_START           * use JSR to validate branch label value
            BGT     BCC_START
            BLE     BCC_START
            BEQ     BCC_START
            BRA     BCC_START
            JSR     BCC_START           * use JSR to validate branch label value

            NOP
            JSR     BCC_END             * use JSR to validate branch label value
            BGT     BCC_END
            BLE     BCC_END
            BEQ     BCC_END
            BRA     BCC_END
            JSR     BCC_END             * use JSR to validate branch label value

            NOP
            JSR     JSR_END             * use JSR to validate branch label value
            BGT     JSR_END
            BLE     JSR_END
            BEQ     JSR_END
            BRA     JSR_END
BCC_END:    JSR     JSR_END             * use JSR to validate branch label value



*------------------------------ GROUP 10 JSR/RTS -------------------------------
********************************************************************************
*  JSR/RTS:                                                                    *
********************************************************************************
            *-------------------------------------------------------------------
            *----------------------------- JSR/RTS -----------------------------
            *-------------------------------------------------------------------
JSR_START:  NOP
            NOP
            JSR     START
            RTS
            JSR     BCC_START
            RTS
            JSR     BCC_END
            RTS
            JSR     JSR_START
            RTS
            JSR     JSR_END

            NOP
            NOP
            JSR     (A0)
            JSR     (A1)
            JSR     (A2)
            JSR     (A3)
            JSR     WORD
            JSR     LONG
JSR_END:    RTS



*------------------------------ GROUP 11 BGT/BLE/BEQ ----------------------------
********************************************************************************
*  BGT/BLE/BEQ:                                                                *
********************************************************************************
            *-------------------------------------------------------------------
            *--------------------------- BGT/BLE/BEQ ---------------------------
            *-------------------------------------------------------------------
            BGT      START
            BGT      BCC_START
            BGT      BCC_END
            BGT      JSR_START
            BGT      JSR_END

            BGE      START
            BGE      BCC_START
            BGE      BCC_END
            BGE      JSR_START
            BGE      JSR_END

            BLE      START
            BLE      BCC_START
            BLE      BCC_END
            BLE      JSR_START
            BLE      JSR_END

            BLT      START
            BLT      BCC_START
            BLT      BCC_END
            BLT      JSR_START
            BLT      JSR_END

            BEQ      START
            BEQ      BCC_START
            BEQ      BCC_END
            BEQ      JSR_START
            BEQ      JSR_END

            BNE      START
            BNE      BCC_START
            BNE      BCC_END
            BNE      JSR_START
            BNE      JSR_END

            BHI      START
            BHI      BCC_START
            BHI      BCC_END
            BHI      JSR_START
            BHI      JSR_END

            BLS      START
            BLS      BCC_START
            BLS      BCC_END
            BLS      JSR_START
            BLS      JSR_END

            JMP      START
            JMP      BCC_START
            JMP      BCC_END
            JMP      JSR_START
            JMP      JSR_END

            END         START
