memclear:			;Clear RAM
	mov ax,0		;IN - dx, stop point, si, start point
	add dx,1
.loop
	cmp si,dx
	je .done
	mov ax,'0'
	mov [si],ax
	add si,1
	jmp .loop
jmp .loop
.done
ret

markfull:	
	push ax
	push bx 		;Mark RAM location as full
	mov ax,0		;IN - dx, stop point, si, start point
.loop
	cmp si,dx
	je .done
	mov ax,'*'
	mov [si],ax
	add si,1
	jmp .loop
jmp .loop
.done	
	pop ax
	pop bx
ret

printstack:
	mov bx,0
	mov si,sp
.loop
	mov ah,0Eh
	lodsb	
	cmp bx,64
	je .done
	int 10h	
	add bx,1
	jmp .loop
.done
	mov si,return
	call print
	mov ax,sp
	call tostring
	mov si,ax
	call print
	.end
	call printret
ret

maloc:			;Allocate RAM
	push si
	push di
	mov dx,ax	;IN - ax, size
	push dx		;OUT - ax, bottom, bx, top
	mov si,void + 20
.find
	cmp byte[si],'0'
	je .test
	add si,1
	add dx,1
	cmp dx,void + 10000h
	je .full
	jmp .find
.test
	add si,1
	cmp byte[si],'0'
	je .aloc
	jmp .find
.aloc
	sub si,1
	pop dx
	mov ax,si
	mov bx,ax
	add bx,dx
	mov dx,bx
	mov si,ax
	call markfull
	jmp .done
.full
	mov si,.err
	call print
	jmp .done
.done
	pop di
	pop si
ret
	.err db 'Memory full',13,10,0

load2mem:	
	mov ax,si		;Load STRING into memory		
	mov di,bx		;IN - ax, top, bx, bottom, si, source		
.loop
	mov al,[si]
	mov [di],al
	add di,1
	add si,1
	cmp al,0
	jne .loop
.done		
ret

movemem:		;IN - si, bottom, ax, top, di, new
	pusha
	mov bx,0
.loop
	cmp di,void
	jl .done
	cmp si,ax
	jge .done
	mov bl,[si]
	mov [di],bl
	add di,1
	add si,1
	jmp .loop
.done
	popa
ret

memcpy:				;IN - si, source, di, destination, ax, length
	pusha
	add di,void + 2048
	mov bx,si
	add bx,ax
	mov ax,bx
	call movemem
	popa
	pusha
	mov si,di
	add si,void + 2048
	mov bx,si
	add bx,ax
	mov ax,bx
	call movemem
.done
	popa
ret