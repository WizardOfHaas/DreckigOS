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

free:
	mov dx,ax
	mov si,bx
	call memclear
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

maloc:
	push si
	mov si,void + 20
	call malocsmall
	pop si
ret

malocsmall:			;Allocate RAM
	push si
	push di
	mov di,si
	add di,1024
	mov dx,ax	;IN - ax, size, si, area
	push dx		;OUT - ax, bottom, bx, top
.find
	cmp byte[si],'0'
	je .test
	add si,1
	add dx,1
	cmp dx,void + 4096
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

malocbig:		;Out - AX,start of 1kb page, BX, page id
	push si
	mov si,void + 5120
	xor bx,bx
.loop
	cmp si,void + 6144
	jg .done
	cmp byte[si + bx],0
	je .found
	add bx,1
	jmp .loop
.found
	mov byte[si + bx],1
	mov ax,1024
	mul bx
	add ax,void + 6144
.done
	pusha
	mov si,ax
	mov dx,ax
	add dx,1024
	call memclear
	popa
	pop si
ret

freebig:		;In - AX,id of page to free
	mov si,void + 5120
	add si,ax
	mov byte[si],0
ret

addr2page:		;IN - AX, addr, OUT - AX, page
	sub ax,void + 6144
	mov bx,1024
	div bx
	call getregs
ret

genmemtable:
	mov bx,void + 5120
	mov ax,void + 6144
	call zeroram
ret

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

copystring:
	pusha
.more:
	mov al, [si]			
	mov [di], al
	inc si
	inc di
	cmp byte al, 0			
	jne .more

.done:
	popa
ret

zeroram:
	pusha
	mov di,bx
.loop
	cmp di,ax
	jge .done
	mov byte[di],0
	add di,1
	jmp .loop
.done	
	popa
ret

memdump:
	mov si,.bott
	call print
	mov di,buffer
	call input
	
	mov si,buffer
	mov di,.void
	call compare
	jc .dumpvoid

	mov si,buffer
	call toint
	mov si,ax
	call getdump
	jmp .done
.dumpvoid
	mov si,void
	call getdump
.done
	call printret
ret
	.bott db 'Bottom>',0
	.void db 'void',0

stringappend:		;DI - string SI - string to append
	pusha
	mov ax,di
	call length
	add di,ax
	call copystring
	popa
ret