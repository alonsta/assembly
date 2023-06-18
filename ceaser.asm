IDEAL
MODEL small
STACK 100h
DATASEG
word1 db "the",'$'
word2 db "are",'$'
word3 db "to",'$'
word4 db "of",'$'
word5 db "and",'$'
word6 db "a",'$'
word7 db "in",'$'
word8 db "that",'$'
word9 db "have",'$'
word10 db "I",'$'
password db 00d,10,13,'$'
filetomemory db  5000 dup ('$')
filename    db  "C:\TASM\BIN\MSG.txt",0
askforpass db 'please enter your password (1-26)',10,13,'$' 
exampletext db  "the worst time to go to the bathroom is during the lunchtime",0
creatingmsg db "We are creating a file for you with a sample text",0,'$'
charcount dw ?
filehandle  dw  ?
ErrorMsg db 'file error',10,13,'$'
SuccessMsg db 'file success',10,13,'$'
finalfile db "C:\TASM\BIN\FINAL.txt",0
tempword db " ",10,13,'$'
matchcount db " ",'$'
bestpassword db ? 
best db " ",'$'
choiceMsg db 'Welcome to the File Encryption Program!', 10, 13
             db 'Please choose an option:', 10, 13
             db '1. Encrypt file with a password', 10, 13
             db '2. Decrypt file with a password', 10, 13
             db '3. Brute-force encrypted file', 10, 13
             db 'Enter your choice (1, 2, or 3): $'
			 
encrypted db "Your msg file has been encrypted and now is saved in final",0,"$"

decrypted db "Your msg file has been decrypted and now is saved in final",0,"$"

bruteforced db "We brute forced your msg file. the original msg is in final(notice it might be wrong.you can do it manually)",0,"$"

userchoice db ?

invalid db "Enter a valid num between 1 - 3",0,"$"


CODESEG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	mov [password + si],al
	inc si
	mov dl,13
	mov ah,2h
	int 21h
	loop enterpass
	sub [word ptr password],3030h
	pop ax
	pop cx
ret
endp Getpass
;;;;;;;;;;;;;;;;;;;;;;;

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
proc moveenc
    lea si, [filetomemory]
    mov cx, [charcount]
    
encryption_loop:
    mov al, [si]
    cmp al, '$'        
    je end_encryption

    cmp al, 'A'
    jl nonenglish
    cmp al, 'Z'
    jle uppercase
    cmp al, 'a'
    jl nonenglish
    cmp al, 'z'
    jle lowercase
    jmp nonenglish

uppercase:
push cx
xor cx,cx
mov cl,[password]
loopy1:
push cx
cmp al,'Z'
je back1
inc al
jmp sofy1
back1:
sub al,25
sofy1:
pop cx
loop loopy1
pop cx
jmp store_encrypted

lowercase:
push cx
xor cx,cx
mov cl,[password]
loopy3:
push cx
cmp al,'z'
je back3
inc al
jmp sofy3
back3:
sub al,25
sofy3:
pop cx
loop loopy3
pop cx
jmp store_encrypted

nonenglish:
    inc si
    jmp encryption_loop

store_encrypted:
    mov [si], al         
    inc si
    jmp encryption_loop

end_encryption:
    ret
endp moveenc

;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc movedec
    lea si, [filetomemory]
    mov cx, [charcount]
    
decryption_loop:
    mov al, [si]
    cmp al, '$'        
    je end_decryption

    cmp al, 'A'
    jl nonenglish1
    cmp al, 'Z'
    jle uppercase1
    cmp al, 'a'
    jl nonenglish1
    cmp al, 'z'
    jle lowercase1
    jmp nonenglish1

uppercase1:
push cx
xor cx,cx
mov cl,[password]
loopy:
push cx
cmp al,'A'
je back
dec al
jmp sofy
back:
add al,25
sofy:
pop cx
loop loopy
pop cx
jmp store_decrypted

lowercase1:
push cx
xor cx,cx
mov cl,[password]
loopy2:
push cx
cmp al,'a'
je back2
dec al
jmp sofy2
back2:
add al,25
sofy2:
pop cx
loop loopy2
pop cx
jmp store_decrypted

nonenglish1:
    inc si
    jmp decryption_loop

store_decrypted:
    mov [si], al        
    inc si
    jmp decryption_loop

end_decryption:
    ret
endp movedec
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc countwords
	push ax
	push bx
	push cx
	push dx
    lea si,[filetomemory]
    lea di,[word1]
    mov [matchcount],0        

searchLoop:
    mov al, [si]
    cmp al, '$'           
    je endSearch

    mov ah, [di]
    cmp ah, '$' 
    je update

    cmp al, ah
    jne nextCharacter

    inc si
    inc di
    jmp searchLoop

nextCharacter:
    inc si
    mov di, offset word1
    jmp searchLoop

update:
    inc [matchcount]
    mov di, offset word1
    jmp nextCharacter

endSearch:
	add [matchcount],30h
    mov ah, 09h
    mov dx, offset matchcount
    int 21h
	sub [matchcount],30h
	pop dx
	pop cx
	pop bx
	pop ax

ret
endp countwords
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc bruteceaser
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	mov cx,26
	mov [password],0
check:
push cx
	call moveenc
	call printfile
	call countwords
	call movedec
	call printfile
	add [password],30h
	lea dx,[password]
	mov ah,9h
	int 21h
	sub [password],30h
	MOV  CX, 03h
	MOV  DX, 4242H
	MOV  AH, 86H
	INT  15H
	mov dl,13
	mov ah,2h
	int 21h
	mov dl,10
	mov ah,2h
	int 21h
			mov al,[best]
			cmp al,[matchcount]
			jng switch
			jmp sof
	switch:
			mov al,[matchcount]
			mov [best],al
			mov al,[password]
			mov [bestpassword],al
			inc [password]
			pop cx
			loop check
	sof:
			inc [password]
			pop cx
			loop Check
ret
endp bruteceaser
;;;;;;;;;;;;;;;;;;;;;;;;;;;
proc ceasera
    mov ah, 09h
    lea dx, [choiceMsg]
    int 21h

    mov ah, 01h
    int 21h
	mov [userchoice],al
    

    cmp [userchoice], "1"
    je encrypt
    cmp [userchoice], "2"
    je decrypt
    cmp [userchoice], "3"
    je bruteForce

    mov ah, 09h
    lea dx, [invalid]
    int 21h
	mov ah, 00h     
    mov al, 03h     
    int 10h 
    jmp start

encrypt:
	call openfile
	call readfile
	call Getpass
	call moveenc
	call save
	mov dx,offset encrypted
	mov ah,9h
	int 21h
    jmp exit

decrypt:
	call openfile
	call readfile
	call Getpass
	call movedec
	call save
	mov dx,offset encrypted
	mov ah,9h
	int 21h
    jmp exit

bruteForce:
	call openfile
	call readfile
	call bruteceaser
	mov al,[bestpassword]
	mov [password],al
	call movedec
	call printfile
	call save
	mov dx,offset bruteforced
	mov ah,9h
	int 21h
	mov dl,10
	mov ah,2h
	int 21h
	mov dl,13
	mov ah,2h
	int 21h
	lea dx,[password]
	mov ah,9h
	int 21h
    jmp exit
ret
endp ceasera
;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
	mov ax, @data
	mov ds, ax
	call openfile
	call readfile
	lea dx,[filetomemory]
	mov ah,9h
	int 21h
	call countwords
exit:
	mov ax, 4c00h
	int 21h
END start