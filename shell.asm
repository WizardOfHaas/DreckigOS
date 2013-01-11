shell:
	mov si,prompt
        call print

        mov di,buffer
        call input

	cmp byte[buffer],0
	je .err

	mov di,buffer
	call commands
	cmp ax,'fl'
	jne .done

	mov si,buffer
	call parse
	call langcommand
	cmp ax,'er'
	jne .done	

	cmp byte[buffer],95
	jge .err

	mov si,buffer
	call runbf
	jmp .done
.err
	jmp .done
.done
	mov si,buffer
	call addtohist
ret

savecurs:
	pusha
	call getcurs
	mov byte[.x],dl
	mov byte[.y],dh
	popa
ret
	.x db 0,0
	.y db 0,0

loadcurs:
	pusha
	mov dl,byte[savecurs.x]
	mov dh,byte[savecurs.y]
	call movecurs
	popa
ret

getcurs:
	mov ah,03h
	mov bx,0
	int 10h
ret

movecurs:
	pusha
	mov ah,02h
	mov bx,0
	int 10h
	popa
ret

parse:
	push si

	mov ax, si			

	mov bx, 0
	mov cx, 0
	mov dx, 0

	push ax			

.loop1:
	lodsb				
	cmp al, 0			
	je .finish
	cmp al, ' '			
	jne .loop1
	dec si
	mov byte [si], 0		

	inc si				
	mov bx, si

.loop2:					
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	
	pop ax
	pop si
ret

compout:		;In - SI,DI, strings to compare Out - AX, length of similarity
	xor dx,dx
.loop			
        mov al,[si]
        mov bl,[di]
        cmp al,bl
        jne .done

        cmp al,0
        je .done

        inc si
        inc di
	inc dx
        jmp .loop
.done
	mov ax,dx
ret

closeenough:
	push si
	push di
	call compout
	cmp ax,2
	jge .ok
	jmp .notok
.ok
	stc
	pop di
	pop si
ret
.notok
	clc
	pop di
	pop si
ret

histstart dw 0
histend dw 0
histpage dw 0

inithist:
	pusha
	call malocbig
	mov [histstart],ax
	add ax,1024
	mov [histend],ax
	mov [histpage],bx
	popa
ret

addtohist:
	pusha
	push si
	mov ax,si
	call length
	push ax
	mov si,[histstart]
	call malocsmall
	cmp ax,[histend]
	pop ax
	jge .shift
	.ok
	pop si
	mov di,bx
	call copystring
	jmp .done
.shift
	mov di,[histstart]
	mov si,di
	add si,ax
	sub bx,ax
	mov ax,1024
	call memcpy
	jmp .ok
.done
	popa
ret

showhist:
	mov si,[histstart]
.typeloop
	call print
	call printret
	mov ax,si
	call length
	add si,ax
	add si,1
	cmp byte[si],'0'
	jne .typeloop
.done
ret