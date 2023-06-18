IDEAL
MODEL small
STACK 100h
DATASEG
askforpass db 'please enter your password (2 digits)',10,13,'$'                                   
tempword dw 'ab',0,'$'
pass dw '88',0,'$'
filename    db  "C:\TASM\BIN\MSG.txt",0
filehandle  dw  ? 
ErrorMsg db 'file error',10,13,'$'
SuccessMsg db 'file success',10,13,'$'
filetomemory db  5000 dup ('$')
charcount dw ?
finalfile db "C:\TASM\BIN\FINAL.txt",0
exampletext db  "replace this text to the text you wish to enc/dec",0
creatingmsg db "we are creating a file for you with a sample text",0,'$'
userchoice db ?
invalid db "enter a valid num between 1 - 8",0,"$"
modes db "",0,"$"
brutepass dw 2 dup('$')
bestpass dw 2 dup('$')
best dw ?
englishcounter dw  ?
returnpoint dw ?
CODESEG

;;;;;;;;;;;;;;;;;;;;;;;;;;

proc readfile
    push dx
    push ax
    push si
    push di
    mov ah, 3fh       
    mov bx, [filehandle] 
    lea dx, [filetomemory]  
    mov cx, 5000      
    int 21h           
    jc readerror      
    mov si, offset filetomemory 
    mov di, offset filetomemory 
    xor cx, cx        
readend:
	mov [charcount], ax
	mov dx, offset SuccessMsg
	mov ah, 9h
	int 21h
    pop di
    pop si
    pop ax
    pop dx
    ret
readerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
    pop di
    pop si
    pop ax
    pop dx
    mov [charcount], 0 
    ret
endp readfile

;;;;;;;;;;;;;;;;;;;;;;;;;;

proc openfile
mov ah, 3Dh
mov al,2
lea dx, [filename]
int 21h
jc createfiletest
continue:
mov [filehandle], ax
jc openerror
mov dx, offset SuccessMsg
mov ah, 9h
int 21h
ret
openerror :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
endofopen:
ret
endp openfile
createfiletest:
	lea dx ,[creatingmsg]
	mov ah,9h
	int 21h
	mov ah,3ch	
	mov cx,7
	mov dx, offset filename
	int 21h
	jc openerror
	mov ah, 3Dh
	mov al,2
	lea dx, [filename]
	int 21h
	jc openerror
	mov [filehandle],ax
	mov ah,40h
	mov bx, [filehandle]
	mov cx,49
	mov dx,offset exampletext
	int 21h 
	jc openerror
	jmp exit	

;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc closefile
mov ah, 3eh       
mov bx, [filehandle]
int 21h          
ret 
endp closefile

;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc enc_dec
push ax
mov ax,[pass]
xor [tempword],ax
pop ax
ret 
endp enc_dec

;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc enc_dec_memory
mov cx, [charcount]
xor si,si
memoryloop:   
    lea bx, [filetomemory]
    add bx, si             
    mov dx, [bx]         
    mov [tempword], dx     
    call enc_dec
	mov dx,[tempword]
	mov [bx],dx	
    inc si    
	inc si
loop memoryloop
ret 
endp enc_dec_memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc Getpass
	mov dl, 0ah
	mov ah, 2h
	int 21h
	push dx
	mov dx, offset askforpass
	mov ah,9h
	int 21h
	pop dx
	push cx
	mov cx,2
	xor si,si
	push ax
	xor ax,ax
	enterpass:
	mov ah,1h
	int 21h
	mov [pass + si],ax
	inc si
	mov dl,13
	mov ah,2h
	int 21h
	loop enterpass
	pop ax
	pop cx
ret
endp Getpass

;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc printfile
	mov dl,0ah
	mov ah,2h
	int 21h
	push cx
	mov cx, [charcount]
    mov si, offset filetomemory
    
print_loop:
    mov al, [si]  
    mov dl, al
	mov ah,2h	
    int 21h            

    inc si

    loop print_loop   
	pop cx
	mov dl,0ah
	mov ah,2h
	int 21h
ret
endp printfile

;;;;;;;;;;;;;;;;;;;;;;;;;;;
 proc changepass
		pop [returnpoint]
		pop ax
		mov cx,10
		xor dx,dx
		div cx
		lea bx,[pass]
		add ah,30h
		add al,30h
		mov [bx + 0],al
		mov [bx + 1],ah    
		push [returnpoint]
        ret
    endp changepass
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc save
    push bx
    push cx
    push dx
    push si
    clearlastfile:
	lea dx,[finalfile]
	mov ah,41h
	xor cx,cx
	int 21h
    createagain:
	mov ah, 3Dh
	mov al,2
	lea dx, [finalfile]
	int 21h
    jc createfile  
	mov [filehandle], ax 	
    jmp writefile      
createfile:
	mov ah,3ch	
	mov cx,7
	mov dx, offset finalfile
	int 21h
	jc saveerror
    mov ah, 3dh        
    mov al, 02h        
    mov dx, offset finalfile
    int 21h
    jc saveerror       
    
    mov [filehandle], ax 

writefile:
	mov ah,40h
	mov bx, [filehandle]
	mov cx,[charcount]
	mov dx,offset filetomemory
	int 21h    
    jnc savesuccess          
	
saveerror:
    mov dx, offset ErrorMsg
    mov ah, 9h
    int 21h
	pop si
    pop dx
    pop cx
    pop bx
	ret
savesuccess:
    mov dx, offset SuccessMsg
    mov ah, 9h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    ret
endp save
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc showfinal
mov ah, 3Dh
mov al,2
lea dx, [finalfile]
int 21h
mov [filehandle],ax
mov ah, 3fh       
mov bx, [filehandle] 
lea dx, [filetomemory]  
mov cx, 5000      
int 21h
call enc_dec_memory  
call printfile
ret
endp showfinal
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc brute
xor ax,ax
xor bx,bx
xor cx,cx
xor dx,dx
xor si,si
	mov cx,100
	looping:
	push cx
	push ax
	call changepass
	pop cx
	inc ax
	push cx
	call enc_dec_memory
	pop cx
	push cx
	call countenglish
	pop cx
	push cx
	call enc_dec_memory
	pop cx
	mov ax,[best]
	cmp ax,[englishcounter]
	jna switch
	jmp sof
	switch:
	mov ax,[englishcounter]
	mov [best],ax
	mov ax,[pass]
	mov [bestpass],ax
	sof:
	loop looping
	ret
endp brute
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc countenglish
mov cx,[charcount]
MOV SI, OFFSET filetomemory
mov ax,[word ptr countenglish]
xor [word ptr countenglish],ax
    countenglishl:
        MOV AL, [SI]
        CMP AL, 'A'
        JB notenglish
        CMP AL, 'Z'
        JBE increment
        CMP AL, 'a'
        JB notenglish
        CMP AL, 'z'
        JA notenglish
    increment:
        INC [englishcounter]
    notenglish:
        INC SI
        LOOP countenglishl

ret
endp countenglish
;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
	mov ax, @data
	mov ds, ax
	push 0abh
call changepass


;;;;;;;;;;;;;;;;;;;;;;;;;;;

exit:
	mov ax, 4c00h
	int 21h
END start


