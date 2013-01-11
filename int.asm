loadints:
	xor bx,bx
	mov di,except
.loop
	call loadint
	add bx,1
	cmp bx,8
	jl .loop

	mov di,int32h
	mov bx,32h
	call loadint
ret

loadint:
	cli
	shl bx,2
	xor ax,ax
	mov gs,ax
	mov [gs:bx],di
	mov [gs:bx + 2],ds
	sti
ret

remap:
	cli
	mov al,0x11
	out 0x20,al
	out 0xA0,al

	mov al,0x20
	out 0x21,al
	mov al,0x28
	out 0xA1,al

	mov al,0x04
	out 0x21,al
	mov al,0x02
	out 0xA1,al

	mov al,0x01
	out 0x21,al
	out 0xA1,al

	mov al,0xFE
	out 0x21,al
	mov al,0xFF
	out 0xA1,al
	sti
ret

int32h:
	call yield
iret

except:
	pusha
	mov si,.err
	call print
	popa
	pop ax
	add ax,2
	push ax
iret
	.err db 'Exception!',13,10,0