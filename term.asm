swapterm:
	cmp byte[doterm],0
	je .0
	mov byte[doterm],0
	jmp .done
.0
	mov byte[doterm],1
.done
ret

serialprint:
	pusha
.repeat:
	lodsb
	cmp al, 0
	je .done
	call sendserial
	jmp .repeat
.done:
	popa
ret

serialinput:
.loop
	call getserial
	mov byte[di],al
	add di,1
	cmp al,0
	je .done
	jmp .loop
.done
ret

sendserial:
	pusha
	mov ah,01h
	mov dx,00h
	int 14h
	popa
ret

getserial:
	push dx
	mov ah,02h
	mov dx,00h
	int 14h
	pop dx
ret

porton:			;AX=1 for 1200 baud
	pusha
	mov dx, 0
	cmp ax, 1
	je .slow_mode
	mov ah, 0
	mov al, 11100011b
	jmp .finish
.slow_mode:
	mov ah, 0
	mov al, 10000011b
.finish:
	int 14h
	popa
ret