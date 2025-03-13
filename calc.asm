.MODEL SMALL
.386    ; to enable longer jump offsets
.STACK 100H
.DATA
    msg1 DB 'Enter first number: $'
    msg2 DB 0DH,0AH, 'Enter operator (+, -, *, /, %, ^): $'
    msg3 DB 0DH,0AH, 'Enter second number: $'
    msg4 DB 0DH,0AH, 'Result: $'
    msgErr DB 0DH,0AH, 'Error: Division by zero!$'
    msgInv DB 0DH,0AH, 'Error: Invalid operator!$'
    msgCont DB 0DH,0AH, 'Continue with this result? (Y/N): $'
    msgWelcome DB 'Simple Calculator - Press ESC anytime to exit', 0DH,0AH, '$'
    msgExit DB 0DH,0AH, 'Do you want to exit? (Y/N): $'
    newLine DB 0DH,0AH, '$'     ; New line string
    msgNotDigitErr DB 0DH, 0AH, 'Please enter a valid digit [0-9]!$'
    msgInvalidYN DB 0DH, 0AH, 'Please enter a valid answer: (Y/N)$'

    num1 DW ?      ; First number storage
    num2 DW ?      ; Second number storage
    result DW ?    ; Result storage
    operator DB ?  ; Stores operator
    isNegative DB ? ; Flag for negative number
    resumeReadNum DB ? ; flag for storing whether to continue with reading first number or second number

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; Display welcome message
    MOV DX, OFFSET msgWelcome
    MOV AH, 09H
    INT 21H

CalculationStart:

    ; output a new line
    MOV DX, OFFSET newLine
    MOV AH, 09H
    INT 21H
    
    ; Clear registers
    XOR AX, AX
    XOR BX, BX
    XOR CX, CX
    XOR DX, DX

ReadFirstNumber:
    ; Ask for First Number
    MOV DX, OFFSET msg1
    MOV AH, 09H
    INT 21H
    MOV resumeReadNum, 1   ; resume at reading first number
    CALL ReadNumber
    MOV num1, AX  ; Store first number
    

OperatorInput:
    ; Ask for Operator
    MOV DX, OFFSET msg2
    MOV AH, 09H
    INT 21H
    CALL ReadOperator
    
    ; Check if the operator is valid
    CALL ValidateOperator
    CMP AL, 0
    JE OperatorInput

ReadSecondNumber:
    ; Ask for Second Number
    MOV DX, OFFSET msg3
    MOV AH, 09H
    INT 21H
    MOV resumeReadNum, 2   ; resume reading second number
    CALL ReadNumber
    MOV num2, AX  ; Store second number

    ; Perform Calculation
    CALL Calculate

    ; Print Result
    MOV DX, OFFSET msg4
    MOV AH, 09H
    INT 21H
    CALL PrintNumber

AskContinue:
    ; Ask if user wants to continue with the result
    MOV DX, OFFSET msgCont
    MOV AH, 09H
    INT 21H
    
    MOV AH, 01H
    INT 21H

    CMP AL, 27    ; Check if ESC key (exit)
    JE ReadNumExit 
    
    CMP AL, 'Y'
    JE ContinueWithResult
    CMP AL, 'y'
    JE ContinueWithResult

    CMP AL, 'N'
    JE AskExit
    CMP AL, 'n'
    JE AskExit

    
    MOV DX, OFFSET msgInvalidYN
    MOV AH, 09H
    INT 21H

    JMP AskContinue

AskExit:
    ; Ask if user wants to exit or start a new calculation
    MOV DX, OFFSET msgExit
    MOV AH, 09H
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    CMP AL, 'Y'
    JE MainExit
    CMP AL, 'y'
    JE MainExit
    
    CMP AL, 'N'
    JE CalculationStart
    CMP AL, 'n'
    JE CalculationStart
    
    ; Invalid response, ask again
    MOV DX, OFFSET msgInvalidYN
    MOV AH, 09H
    INT 21H
    
    JMP AskExit

ContinueWithResult:
    ; Use the previous result as the first number
    MOV AX, result
    MOV num1, AX
    JMP OperatorInput

    ; Exit Program section moved to avoid jump range issue
MainExit:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

;--------------------------------------------------
; Read a number from user and convert ASCII to integer
;--------------------------------------------------
ReadNumber PROC
    MOV BX, 0     ; BX will store the final number
    MOV isNegative, 0 ; Reset negative flag
    XOR CX, CX    ; CX will count digits entered

    ; Check for negative sign
    MOV AH, 01H   ; Read character from user
    INT 21H
    
    CMP AL, 27    ; Check if ESC key (exit)
    JE ReadNumExit
    
    ; Handle backspace
    CMP AL, 8     ; Check for backspace
    JE HandleBackspace1
    
    CMP AL, '-'
    JNE NotNegative
    
    MOV isNegative, 1 ; Set negative flag
    JMP ReadLoop
    
NotNegative:
    ; If not negative, process this digit
    CMP AL, 0DH   ; Check if Enter key
    JE EndRead
    
    SUB AL, '0'   ; Convert ASCII to integer
    CMP AL, 0
    JL NotDigit    ; If not a digit, ignore
    CMP AL, 9
    JG NotDigit    ; If not a digit, ignore
    
    MOV AH, 0
    MOV BX, AX    ; Start with first digit
    INC CX        ; Increment digit counter
    JMP ReadLoop

NotDigit:
    ; if the entered character is not a digit, output an error message
    MOV DX, OFFSET msgNotDigitErr
    MOV AH, 09H
    INT 21H

    ; output a new line
    MOV DX, OFFSET newLine
    MOV AH, 09H
    INT 21H

    ; check if current reading is at first or second number
    CMP resumeReadNum, 1
    JE ReadFirstNumber
    
    JMP ReadSecondNumber

HandleBackspace1:
    ; Nothing to delete at the start
    JMP ReadLoop

ReadLoop:
    MOV AH, 01H   ; Read character from user
    INT 21H
    
    CMP AL, 27    ; Check if ESC key (exit)
    JE ReadNumExit 
    
    CMP AL, 8     ; Check for backspace
    JE HandleBackspace
    
    CMP AL, 0DH   ; Check if Enter key is pressed
    JE EndRead

    SUB AL, '0'   ; Convert ASCII to integer
    CMP AL, 0
    JL NotDigit    ; If not a digit, ignore
    CMP AL, 9
    JG NotDigit    ; If not a digit, ignore

    MOV AH, 0
    PUSH AX       ; Save AL on stack
    MOV AX, BX    ; Move BX (current number) into AX
    MOV DX, 10
    MUL DX        ; Multiply AX by 10
    POP DX        ; Restore digit from stack
    ADD AX, DX    ; Add the new digit
    MOV BX, AX    ; Store result in BX
    INC CX        ; Increment digit counter
    JMP ReadLoop

HandleBackspace:
    ; Handle backspace - remove last digit
    CMP CX, 0     ; Check if there are digits to remove
    JE ReadLoop   ; If no digits, just continue

    ; Display visual feedback for backspace
    PUSH BX       ; Save current number
    MOV AH, 02h   ; Function to output character
    MOV DL, 20h   ; Space character to erase
    INT 21h
    MOV DL, 8     ; Backspace again to position cursor
    INT 21h
    POP BX        ; Restore number

    ; Remove last digit mathematically
    MOV AX, BX    ; Move number to AX
    MOV DX, 0     
    MOV BX, 10    ; Prepare to divide by 10
    DIV BX        ; AX = AX / 10, DX = AX % 10
    MOV BX, AX    ; Store back in BX
    DEC CX        ; Decrement digit counter
    JMP ReadLoop

ReadNumExit:      ; Renamed from ExitProgram
    MOV AH, 4CH
    INT 21H

EndRead:
    MOV AX, BX    ; Move final result to AX
    
    ; Apply negative sign if needed
    CMP isNegative, 1
    JNE ReadDone
    NEG AX        ; Convert to negative
    
ReadDone:
    RET

ReadNumber ENDP

;--------------------------------------------------
; Read Operator (+, -, *, /, %, ^)
;--------------------------------------------------
ReadOperator PROC
    ReadOpLoop:
    MOV AH, 01H   ; Read character
    INT 21H
    
    CMP AL, 27    ; Check if ESC key (exit)
    JE OpExit     ; Renamed to avoid duplicate label
    
    CMP AL, 8     ; Check for backspace
    JE HandleOpBackspace
    
    MOV operator, AL
    RET
    
HandleOpBackspace:
    ; Handle backspace - provide visual feedback
    MOV AH, 02h   ; Function to output character
    MOV DL, 20h   ; Space character to erase
    INT 21h
    MOV DL, 8     ; Backspace again to position cursor
    INT 21h
    JMP ReadOpLoop
    
OpExit:
    MOV AH, 4CH
    INT 21H
ReadOperator ENDP

;--------------------------------------------------
; Validate Operator
;--------------------------------------------------
ValidateOperator PROC
    MOV AL, operator
    
    CMP AL, '+'
    JE ValidOp
    CMP AL, '-'
    JE ValidOp
    CMP AL, '*'
    JE ValidOp
    CMP AL, '/'
    JE ValidOp
    CMP AL, '%'   ; Added modulo support
    JE ValidOp
    CMP AL, '^'   ; Added power support
    JE ValidOp
    
    ; Invalid operator
    MOV DX, OFFSET msgInv
    MOV AH, 09H
    INT 21H
    XOR AL, AL    ; AL = 0 indicates invalid
    RET
    
ValidOp:
    MOV AL, 1     ; AL = 1 indicates valid
    RET
ValidateOperator ENDP

;--------------------------------------------------
; Perform Calculation
;--------------------------------------------------
Calculate PROC
    MOV AX, num1  ; Load first number
    MOV BX, num2  ; Load second number

    CMP operator, '+'
    JE DoAdd
    CMP operator, '-'
    JE DoSub
    CMP operator, '*'
    JE DoMul
    CMP operator, '/'
    JE DoDiv
    CMP operator, '%'
    JE DoMod
    CMP operator, '^'
    JE DoPow

DoAdd:
    ADD AX, BX    ; Perform Addition
    JMP StoreResult

DoSub:
    SUB AX, BX    ; Perform Subtraction
    JMP StoreResult

DoMul:
    IMUL BX       ; Perform Multiplication
    JMP StoreResult

DoDiv:
    CMP BX, 0     ; Prevent division by zero
    JE ErrorDiv
    CWD           ; Sign-extend AX into DX:AX
    IDIV BX       ; AX = AX / BX (signed)
    JMP StoreResult

DoMod:
    CMP BX, 0     ; Prevent division by zero
    JE ErrorDiv
    CWD           ; Sign-extend AX into DX:AX
    IDIV BX       ; DX = AX % BX (remainder)
    MOV AX, DX    ; Move remainder to AX
    JMP StoreResult

DoPow:
    ; Simple power implementation for small exponents
    CMP BX, 0
    JL ErrorDiv   ; Can't handle negative exponents
    
    MOV CX, BX    ; Move exponent to CX
    CMP CX, 0     ; If exponent is 0
    JE PowerZero
    
    DEC CX        ; Decrement CX for loop counter
    MOV BX, AX    ; Save base in BX
    
PowerLoop:
    CMP CX, 0     ; Check if done
    JE StoreResult
    IMUL BX       ; Multiply AX by the base
    DEC CX        ; Decrement counter
    JMP PowerLoop
    
PowerZero:
    MOV AX, 1     ; x^0 = 1
    JMP StoreResult

ErrorDiv:
    MOV DX, OFFSET msgErr
    MOV AH, 09H
    INT 21H

    ; output a new line
    MOV DX, OFFSET newLine
    MOV AH, 09H
    INT 21H

    ; check if current reading is at first or second number
    CMP resumeReadNum, 1
    JE ReadFirstNumber

    JMP ReadSecondNumber

StoreResult:
    MOV result, AX
    RET
Calculate ENDP

;--------------------------------------------------
; Print Number (AX to ASCII)
;--------------------------------------------------
PrintNumber PROC
    MOV AX, result
    
    ; Check if negative
    TEST AX, AX
    JNS PositiveNumber
    
    ; Print minus sign for negative numbers
    PUSH AX
    MOV DL, '-'
    MOV AH, 02H
    INT 21H
    POP AX
    NEG AX        ; Make AX positive
    
PositiveNumber:
    MOV CX, 0     ; Initialize digit counter
    MOV BX, 10    ; Divisor for extracting digits

ConvertLoop:
    MOV DX, 0
    DIV BX        ; Divide AX by 10, remainder in DX
    PUSH DX       ; Store remainder (digit)
    INC CX        ; Increase counter
    TEST AX, AX   ; Check if AX is zero
    JNZ ConvertLoop

PrintLoop:
    POP DX        ; Retrieve digit
    ADD DL, '0'   ; Convert to ASCII
    MOV AH, 02H
    INT 21H       ; Print character
    LOOP PrintLoop
    RET
PrintNumber ENDP

END MAIN