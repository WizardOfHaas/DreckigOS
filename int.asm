loadints:
	mov di,int32h
	mov bx,32h
	call loadint
ret

loadint:
	cli
	shl bx,2
	xor ax,ax
	mov gs,ax
	mov [gs:bx],word di
	mov [gs:bx + 2],ds
	sti
ret

int32h:
	call yield
iret