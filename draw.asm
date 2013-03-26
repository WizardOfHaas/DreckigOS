guipage dw 0
initgui:
	call initfont

	call malocbig
	mov [guipage],ax
ret

startgui:	
	xor ax,ax
	mov al,13h
	int 10h

	mov ax,1123h
	mov bl,02h
	int 10h

	mov al,5
	mov ah,25
	mov bl,200
	mov bh,50
	mov si,.msg
	call newwin

	mov al,50
	mov ah,75
	mov bl,100
	mov bh,100
	mov si,.msg2
	call newwin

	call displayallwins
	call waitkey
	mov ax,1
	call clearwin
	call waitkey
ret
	.msg db 'Welcome to WINDv3!',10,'A GUI for Dreckig OS!',0
	.msg2 db 'Test!',0

fontpage dw 0
initfont:
	pusha
	call malocbig
	mov [fontpage],ax
	call malocbig
	call malocbig
	call malocbig
	mov si,[fontpage]
	push ds
	push es
	mov ax,1130h
	mov bh,3
	int 10h
	push es
	pop ds
	pop es
	mov si,bp
	mov cx,256*16/4
	rep movsd
	pop ds
	popa
ret

initfontold:
	mov ax,1130h
	mov bh,6
	int 10h
	mov [fontpage],bp
ret

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
	push ax
	call getwindata
	mov bx,ax
	movzx cx,byte[bx]
	movzx dx,byte[bx + 1]
	movzx si,byte[bx + 2]
	movzx di,byte[bx + 3]
	call drawwin
	mov si,[bx + 4]
	pop ax
	call printwin
	popa
ret

clearwin:
	pusha
	call getwindata
	mov bx,ax
	movzx cx,byte[bx]
	movzx dx,byte[bx + 1]
	movzx si,byte[bx + 2]
	movzx di,byte[bx + 3]
	mov ax,00
	call fillbox
	popa
ret

displayallwins:
	pusha
	mov si,[guipage]
	xor ax,ax
.loop
	cmp byte[si],'0'
	je .done
	call displaywin
	add si,6
	add ax,1
	jmp .loop
.done
	popa
ret

printwin:		;SI,string, AX,win id
	pusha
	call getwindata
	mov di,ax
	movzx cx,byte[di]
	movzx dx,byte[di + 1]
	movzx bx,byte[di + 2]
	sub bx,10
	add cx,2
	add dx,2
	mov [.x],cx
	mov [.y],dx
	mov [.r],bx
.loop
	cmp byte[si],0
	je .done
	cmp byte[si],10
	je .nl
	cmp cx,[.r]
	jge .wrap
	call putchar
	add cx,8
	add si,1
	jmp .loop
.nl
	add si,1
	mov cx,[.x]
	add dx,8
	jmp .loop
.wrap
	mov cx,[.x]
	add cx,1
	add dx,8
	jmp .loop
.done
	popa
ret
	.x db 0,0
	.y db 0,0
	.r db 0,0

putchar:
	pusha
	mov di,si
	movzx si,byte[di]
	call drawglyph
	popa
ret

drawglyph:		;cx,x, dx,y, si,char
	pusha
	mov byte[.row],0
	xor bx,bx
	push dx
	mov ax,8
	mul si
	mov di,ax
	add di,[fontpage]
	sub di,916
	pop dx
	mov al,byte[di]
.mainloop
	shl al,1
	jc .draw
	.drawok
	add bx,1
	add cx,1
	cmp bx,9
	jge .next
	jmp .mainloop
.next
	add dx,1
	sub cx,9
	add di,1
	mov al,byte[di]
	xor bx,bx
	add byte[.row],1
	cmp byte[.row],8
	jge .done
	jmp .mainloop
.draw
	push ax
	mov al,02
	call plot
	pop ax
	jmp .drawok
.done
	popa
ret
	.row db 0

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

drawbtn:
	pusha
	
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
	pusha
	mov al,15
	call fillbox
	mov al,00
	add cx,1
	add dx,1
	sub si,1
	sub di,1
	call fillbox
	popa
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