****************************************************************************
*                                                                          *
* ONLINE - Lists all disk volumes connected to the computer                *
* Copyright (C) 2017,2018  William L. Chatfield <bill_chatfield@yahoo.com> *
*                                                                          *
* This program is free software; you can redistribute it and/or modify     *
* it under the terms of the GNU General Public License as published by     *
* the Free Software Foundation; either version 2 of the License, or        *
* (at your option) any later version.                                      **                                                                          *
* This program is distributed in the hope that it will be useful,          *
* but WITHOUT ANY WARRANTY; without even the implied warranty of           *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
* GNU General Public License for more details.                             *
*                                                                          *
* You should have received a copy of the GNU General Public License along  *
* with this program; if not, write to the Free Software Foundation, Inc.,  *
* 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              *
*                                                                          *
****************************************************************************

               ORG   $2000
               DSK   ONLINE
               TYP   $FF        ;SYSTEM TYPE

********************************
*                              *
* CONSTANTS                    *
*                              *
********************************

DEBUG          EQU   0
ONLCMD         EQU   $C5        ;ID FOR ON_LINE MLI SYSTEM CALL
RDKEY          EQU   $FD0C      ;READS 1 CHAR
CROUT          EQU   $FD8E      ;SUB TO OUTPUT CARRIAGE RETURN
COUT           EQU   $FDED      ;SUB TO OUTPUT A CHARACTER
PRBYTE         EQU   $FDDA      ;SUB TO PRINT ERROR MESSAGE
MLI            EQU   $BF00      ;ADDRESS OF MLI ENTRY POINT
BELL           EQU   $FF3A      ;SUBROUTINE TO BEEP
MAXREC         EQU   16         ;MAX RECS RETURNED BY ON_LINE
BUFPTR         EQU   6          ;WILL USE ZERO PAGE 6 & 7
MSGADR         EQU   8
RECLEN         EQU   $10        ;THAT'S 16 IN DECIMAL

********************************
*                              *
* MACROS                       *
*                              *
********************************

               DO    0          ;TURN OFF ASSEMBLY FOR MACROS

********************************
*                              *
* PUTS                         *
*                              *
********************************

PUTS           MAC
               TYA              ;PRESERVE Y
               PHA
               LDY   #0         ;PREPARE LOOP INDEX
]NEXTCHR       LDA   ]1,Y       ;LOAD A CHARACTER
               CMP   #0         ;CHECK FOR END OF STRING
               BEQ   FINISH
               JSR   COUT
               INY
               JMP   ]NEXTCHR
FINISH         PLA              ;RESTORE Y
               TAY
               EOM

********************************
*                              *
* PAUSE                        *
*                              *
********************************

PAUSE          MAC
               PUTS  DPAUSE
               JSR   RDKEY
               JSR   CROUT
               EOM

ADD2ADDR       MAC
               LDA   ]1
               CLC
               ADC   ]2
               STA   ]1
               BCC   DONE
               INC   ]1+1
DONE           EOM

               FIN              ;END OF MACROS

********************************
*                              *
* MAIN                         *
*                              *
********************************

MAIN
               PUTS  LICENSE
               JSR   CROUT

               JSR   MLI        ;CALL MACHINE LANGUAGE INTERFACE
               DB    ONLCMD     ;SPECIFY THE ON_LINE SYSTEM CALL
               DA    ONLARGS    ;SPECIFY ADDRESS OF ARGUMENTS
               BEQ   CONTINUE   ;ON_LINE RETURNS 0 ON SUCCESS
               JMP   ERROR
*
* COPY THE ADDRESS OF THE OUTPUT BUFFER INTO BUFPTR
*
CONTINUE       LDA   #<BUFFER   ;PUT LOW BYTE INTO ACCUMULATOR
               STA   BUFPTR     ;ASSIGN LOW BYTE TO BUFPTR
               LDA   #>BUFFER   ;PUT HIGH BYTE INTO ACCUMULATOR
               STA   BUFPTR+1   ;ASSIGN HIGH BYTE TO BUFPTR
*
* LOOP TO PROCESS 16 RECORDS
*
RECLOOP        LDA   RECNUM
               CMP   #MAXREC
               BNE   :CHKLAST
               JMP   ENDPROG
:CHKLAST       LDY   #0
               LDA   (BUFPTR),Y
               CMP   #0         ;LAST REC IF FIRST BYTE IS 0
               BNE   FINDDRV
               JMP   ENDPROG

* FIND DRIVE NUMBER. IT IS SPECIFIED BY THE HIGH BIT OF
* THE FIRST BYTE IN THE RECORD. A ZERO SPECIFIES DRIVE 1.
* A ONE SPECIFIES DRIVE 2.

FINDDRV        LDY   #0         ;SETUP FOR LDA INDIRECT INDEXED
               LDA   (BUFPTR),Y ;LOAD FIRST BYTE INTO ACCUM
               AND   #%10000000 ;FOCUS ON THE HIGH BIT
               CLC              ;DON'T LET THE CARRY BIT WRAP
               LSR              ;SHIFT BITS TO THE RIGHT
               LSR              ;AGAIN
               LSR              ;AGAIN
               LSR              ;...
               LSR
               LSR
               LSR              ;BIT ZERO NOW SPECIFIES DRIVE
               ADC   #1         ;CONVERT BIT TO DRIVE NUMBER
               STA   DRIVENUM   ;STORE THE RESULT
*
* FIND SLOT NUMBER
*
               LDY   #0         ;SETUP FOR NEXT OP
               LDA   (BUFPTR),Y ;LOAD FIRST BYTE INTO ACCUM
               AND   #%01110000 ;FOCUS ON BITS 4,5, AND 6
               LSR              ;SHIFT BITS TO THE RIGHT
               LSR              ;DO IT AGAIN
               LSR              ;DO IT AGAIN
               LSR              ;DO IT AGAIN
               STA   SLOTNUM    ;BITS 0,1,2 NOW SPECIFY SLOT NUM
*
* FIND VOLUME NAME LENGTH
*
               LDY   #0         ;SETUP FOR NEXT OP
               LDA   (BUFPTR),Y ;LOAD FIRST BYTE OF REC INTO A
               AND   #%00001111 ;FOCUS ON LOWER 4 BITS
               STA   NAMELEN    ;STORE THE RESULT

               DO    DEBUG
               PUTS  DNAMELEN
               LDA   NAMELEN
               JSR   PRBYTE
               JSR   CROUT
               FIN
*
* PRINT SLOT AND DRIVE
*
PRTSLOT
               LDA   #"S"       ;AN 'S' WITH HIGH BIT SET
               JSR   COUT       ;WRITE 'S'
               LDA   SLOTNUM    ;PUT SLOT NUM IN ACCUMULATOR
               CLC              ;CLEAR CARRY FLAG FOR ADDITION
               ADC   #$B0       ;CONVERT TO ASCII & SET HI BIT
               JSR   COUT       ;PRINT SLOTNUM
               LDA   #$AC       ;COMMA WITH HIGH BIT SET
               JSR   COUT       ;WRITE COMMA
               LDA   #"D"       ;A 'D' WITH HIGH BIT SET
               JSR   COUT       ;WRITE 'D'
               LDA   DRIVENUM   ;PUT DRIVE NUM IN ACCUMULATOR
               CLC              ;CLEAR CARRY FLAG FOR ADDITION
               ADC   #$B0       ;CONVERT TO ASCII & SET HI BIT
               JSR   COUT       ;WRITE DRIVENUM CHARACTER
               LDA   #" "       ;SPACE WITH HIGH BIT SET
               JSR   COUT       ;WRITE SPACE CHARACTER
*
* CHECK FOR EMPTY VOLUME NAME
*
               LDY   #0
               CPY   NAMELEN    ;CHECK FOR EMPTY NAME
               BNE   WRITEVOL   ;CONTINUE IF IT IS NOT EMPTY
               INY              ;MOVE INDEX TO LOC OF ERROR CODE
               LDA   (BUFPTR),Y ;LOAD THE ERROR CODE
               JSR   WRITEERR
               JSR   CROUT
               JMP   INCREC
*
* PRINT THE VOLUME NAME
*
WRITEVOL       LDA   #"/"       ;SLASH WITH HIGH BIT SET
               JSR   COUT       ;WRITE SLASH CHARACTER
               LDY   #1         ;SET INDEX TO FIRST CHAR OF NAME
:NEXTCHR       LDA   (BUFPTR),Y ;LOAD CHAR INTO ACCUMULATOR
               ORA   #%10000000 ;TURN ON THE HIGH BIT FOR PRINT
               JSR   COUT       ;WRITE A CHARACTER OF VOL NAME
               CPY   NAMELEN    ;CHECK IF LAST CHARACTER
               BEQ   :DONEVOL   ;EXIT LOOP IF DONE
               INY              ;INCREMENT Y REGISTER
               JMP   :NEXTCHR   ;LOOP TO NEXT CHARACTER
:DONEVOL       JSR   CROUT      ;WRITE A CARRIAGE RETURN
*
* BOTTOM OF RECLOOP
*
INCREC         INC   RECNUM     ;INCREMENT CURRENT RECORD NUM
*
* ADD 16 TO THE ADDRESS IN BUFPTR
*
               LDA   BUFPTR     ;LOAD THE LOW BYTE OF BUFPTR
               CLC              ;CLEAR CARRY BIT IN PREP FOR ADD
               ADC   #RECLEN    ;ADD RECLEN TO LOW BYTE
               STA   BUFPTR     ;STORE CALCULATED LOW BYTE
               BCC   :NOCARRY   ;IF CARRY NOT SET THEN NEXT REC
               INC   BUFPTR+1   ;INC HIGH BYTE IF CARRY WAS SET
:NOCARRY
               DO    DEBUG
               PAUSE
               FIN

               JMP   RECLOOP    ;LOOP TO NEXT RECORD
ENDPROG
               RTS              ;RETURN TO WHATEVER CALLED PROG
*
* ERROR HANDLER
*
ERROR
               JSR   WRITEERR
               JSR   BELL       ;BEEP
               JSR   CROUT      ;WRITE CARRIAGE RETURN
               RTS              ;RETURN TO WHATEVER CALL PROGRAM

********************************
*                              *
* SUB WRITEERR                 *
* ERROR CODE MUST BE IN ACCUM  *
*                              *
********************************

WRITEERR
               STA   ERRCODE
               LDX   #0
               LDY   #0

:NEXTERR
               DO    DEBUG
               PUTS  DERRCODE
               LDA   ERRCODE
               JSR   PRBYTE
               JSR   CROUT
               FIN

               LDA   ERRCODE
               CMP   ERRCODES,X
               BEQ   :FOUND
               INX
               INY
               INY
               CPX   ERRCOUNT
               BMI   :NEXTERR

* UNKNOWN ERROR CODE
               LDA   #"("
               JSR   COUT
               PUTS  UNKECODE
               LDA   ERRCODE
               JSR   PRBYTE
               LDA   #")"
               JSR   COUT
               JMP   :ENDSUB

:FOUND         LDA   ERRMSGS,Y  ;LOAD A WITH LOW BYTE OF MSG
               STA   MSGADR     ;STORE LOW BYTE INTO LOCAL
               INY              ;ADVANCE TO HIGH BYTE
               LDA   ERRMSGS,Y  ;LOAD A WITH HIGH BYTE OF MSG
               STA   MSGADR+1   ;STORE HIGH BYTE INTO LOCAL

               DO    DEBUG
               PUTS  DMSGADR
               LDA   MSGADR
               JSR   PRBYTE
               JSR   CROUT
               FIN

               LDA   #"("
               JSR   COUT
               PUTS  (MSGADR)   ;WRITE THE ERROR MESSAGE
               LDA   #")"
               JSR   COUT

:ENDSUB        RTS

********************************
*                              *
* VARIABLES                    *
*                              *
********************************

BUFFER         DS    256        ;SPACE FOR 16 DISK VOL RECORDS
ONLARGS        DB    2          ;PARAMETER COUNT
               DB    0          ;UNIT NUMBER, 0=ALL
               DA    BUFFER     ;ADDRESS OF OUTPUT BUFFER
DRIVENUM       DB    0          ;BYTE TO STORE DRIVENUM
SLOTNUM        DB    0          ;BYTE TO STORE SLOTNUM
NAMELEN        DB    0          ;LENGTH OF A VOLUME NAME
RECNUM         DB    0          ;CURRENT RECORD NUMBER
ERRCODE        DB    0
DNAMELEN       ASC   "NAMELEN=",00
DERRCODE       ASC   "ERRCODE=",00
DMSGADR        ASC   "MSGADR=",00
DPAUSE         ASC   "PRESS ANY KEY TO CONTINUE",00
UNKECODE       ASC   "UNKNOWN ERROR CODE: ",00
*
* ERROR MESSAGES
*
ERRCOUNT       DB    8
ERR27          ASC   "I/O ERROR",00
ERR28          ASC   "DEVICE NOT CONNECTED",00
ERR2E          ASC   "DISK SWITCHED: FILE STILL OPEN ON OTHER DISK",00
ERR45          ASC   "VOLUME DIRECTORY NOT FOUND",00
ERR52          ASC   "NOT A PRODOS DISK",00
ERR55          ASC   "VOLUME CONTROL BLOCK FULL",00
ERR56          ASC   "BAD BUFFER ADDRESS",00
ERR57          ASC   "DUPLICATE VOLUME",00
*
* ERROR CODE TO MESSAGE TRANSLATION TABLE
*
ERRCODES       DB    $27
               DB    $28
               DB    $2E
               DB    $45
               DB    $52
               DB    $55
               DB    $56
               DB    $57
ERRMSGS        DA    ERR27
               DA    ERR28
               DA    ERR2E
               DA    ERR45
               DA    ERR52
               DA    ERR55
               DA    ERR56
               DA    ERR57
*
* LICENSE
*
LICENSE  ASC "Github.com/gungwald/online v1.0.1 GPL2",00
LICENSE0 ASC "ONLINE v1.0.1",00
LICENSE1 ASC "Copyright (c) 2017,2018 Bill Chatfield",00
LICENSE2 ASC "Distributed under the GPLv2",00
LICENSE3 ASC "https://github.com/gungwald/online",00
