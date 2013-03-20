guipage dw 0
initgui:
	call malocbig
	mov [guipage],ax

	xor ax,ax
	mov al,13h
	int 10h

	mov ax,1123h
	mov bl,02h
	int 10h

	mov al,5
	mov ah,5
	mov bl,205
	mov bh,195
	mov si,.msg
	call newwin
	call displaywin
	call waitkey
ret
	.msg db 'This is a test!',0

newwin:			;AL,x1, AH,y1, BL,x2, BH,y2, SI,window contents
	pusha
	call malocbig
	mov [.mem],ax
	mov di,[.mem]
	call copystring
	mov si,[guipage]
	mov ax,1
	call malocsmall
	sub ax,1
	mov [.entry],ax
	popa
	mov si,[.entry]
	mov byte[si],al
	mov byte[si + 1],ah
	mov byte[si + 2],bl
	mov byte[si + 3],bh
	mov di,[.mem]
	mov word[si + 4],di
	mov ax,si
	sub ax,[guipage]
	mov bx,6
	div bx
ret			;AX,win ID, SI,win page
	.mem dw 0
	.entry dw 0

getwindata:			;AX,win ID
	mov bx,6
	mul bx
	add ax,[guipage]
ret			;AX,pointer to window data entry

displaywin:		;AX,win ID
	pusha
	call getwindata
	mov bx,ax
	movzx cx,byte[bx]
	movzx dx,byte[bx + 1]
	movzx si,byte[bx + 2]
	movzx di,byte[bx + 3]
	call drawwin
	mov si,[bx + 4]
	call printwin
	popa
ret

printwin:
	call print
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