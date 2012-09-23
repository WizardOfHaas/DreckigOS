drawguishell:
	call background
	mov cx,290
	mov dx,0
	mov si,320
	mov di,199
	mov al,15
	call fillbox
	mov di,loadicon.icon
	mov dx,0
	mov si,shellwin
	call loadicon
	mov di,loadicon.quit
	mov dx,1
	mov si,quitguishell
	call loadicon
	mov di,loadicon.file
	mov dx,2
	mov si,guifileman
	call loadicon
ret

loadicon:
	pusha
	mov bx,dx
	mov ax,2
	mul bx
	mov bx,ax
	mov [iconcmds + bx],si
	popa
	mov bx,void + 1024
	call vfs2disk
	mov ax,dx
	mov bx,22
	mul bx
	mov dx,ax
	mov cx,298
	mov si,void + 1024
	call drawicon
	add byte[numicons],1
ret
	.icon db 'ICON',0
	.quit db 'QUIT',0
	.file db 'FILE',0

drawicon:			;IN - cx,dx, x,y, si, icon
	xor bx,bx
	xor di,di
.loop
	add bx,1
	cmp bx,22
	jge .next
	mov al,byte[si]
	call plot
	add si,1
	add cx,1
	jmp .loop
.next
	add si,1
	sub cx,21
	xor bx,bx
	add di,1
	cmp di,22
	jge .done
	add dx,1
	jmp .loop
.done
ret

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