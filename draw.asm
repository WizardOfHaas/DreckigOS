;0xA0000
plot:
	pusha
	push ax
	mov ax,320
	mul dx
	add ax,cx
	mov bx,ax
	pop ax
	push es
	mov cx,0xA000
	mov es,cx
	mov byte[es:bx],al
	pop es
	popa
ret

drawhline:		;IN - cx,dx, start, si,di, stop, al, color
	pusha
.loop
	call plot
	add cx,1
	cmp cx,si
	jge .done
	jmp .loop
.done
	popa
ret

drawvline:
	pusha
.loop
	call plot
	add dx,1
	cmp dx,di
	jge .done
	jmp .loop
.done
	popa
ret

drawwin:
	mov al,15
	call fillbox
	mov al,00
	add cx,1
	add dx,1
	sub si,1
	sub di,1
	call fillbox
	
ret

fillbox:
	pusha
.loop
	call drawhline
	cmp dx,di
	jge .done
	add dx,1
	jmp .loop
	
.done
	popa
ret

background:
	call blankscreen
	xor cx,cx
	xor dx,dx
	mov ax,07h
.loop
	call plot
	add cx,2
	cmp cx,290
	jge .next
	jmp .loop
.next
	add dx,1
	cmp dx,200
	jge .done
	sub cx,289
	jmp .loop
.done
ret

blankscreen:
	pusha
	mov cx,0
	mov dx,0
	mov si,290
	mov di,200
	mov al,00
	call fillbox
	popa
ret