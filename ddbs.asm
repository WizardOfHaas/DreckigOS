ddbscmd:
ret

newtable:			;DI - DB name, SI - Table Name, BX - Table specs
	pusha
	call malocbig
	mov [.mem],ax
	mov bx,ax
	mov si,di
	call gethashfile
	mov bx,[.mem]
	call getfilesize
	add ax,1
	mov [.end],ax
	mov bx,[.mem]
	add [.end],bx
	popa

	push bx
	mov di,[.end]
	call copystring
	mov ax,si
	call length
	add ax,1
	add [.end],ax
	pop bx

	push bx
	call getfilesize
	add ax,1
	pop bx
	sub ax,bx
	mov si,bx
	mov di,[.end]
	call memcpy
ret
	.mem dw 0
	.end dw 0