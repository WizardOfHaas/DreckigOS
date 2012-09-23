iconcmds times 18 db 0
numicons db 0,0

shellwin:
	mov byte[.quit],0
	mov cx,5
	mov dx,5
	mov si,250
	mov di,195
	call drawwin	
	
	mov dl,1
	mov dh,1
	call movecurs
.loop
	mov byte[guiprint.x],1
	call shell
	call killque
	cmp byte[.quit],1
	je .goquit
	jmp .loop
.goquit
	call background
.done
ret
	.quit db 0,0

guishell:
	call setupguishell
	call drawguishell
.loop
	call selector
	jmp .loop
ret

guialert:
	pusha
	mov cx,300
	mov dx,180
	mov si,320
	mov di,200
	mov al,12
	call fillbox
	popa
ret

guiclear:
	mov cx,5
	mov dx,5
	mov si,250
	mov di,195
	call drawwin
ret

guiprint:
	mov byte[gui],0
	call getcurs
	mov dl,byte[.x]
	call movecurs
	mov ah,0Eh
	mov bl,2
.repeat
        lodsb
        cmp al,0
        je .done
        int 10h
	pusha
	call getcurs
	cmp dh,23		;[.ymax]
	jge .scroll
	cmp dl,31		;[.xmax]
	jge .wrap
	popa
        jmp .repeat
.scroll
	popa
	call scrollshell
	jmp .repeat
.wrap
	popa
	call wrapshell
	jmp .repeat
.done
	mov byte[gui],1
ret
	.x db 0,0
	.xmax db 0
	.ymax db 0,0

wrapshell:
	call getcurs
	add dh,1
	mov dl,byte[guiprint.x]
	call movecurs
ret

scrollshell:
	mov ah,06h
	mov al,1
	mov bh,0
	mov ch,1
	mov cl,1
	mov dh,23
	mov dl,30
	int 10h
	call getcurs
	sub dh,1
	call movecurs
ret

setupguishell:
	call killque
	xor ax,ax
	mov al,13h
	int 10h

	mov ax,1123h
	mov bl,02h
	int 10h

	mov byte[numicons],0
	mov byte[gui],1
ret

quitguishell:
	call killque
	mov byte[gui],0
	xor ax,ax
	mov al,03h
	int 10h
	mov ax,shell
	call schedule
	call main
ret

selector:
	mov di,numicons
	mov si,selected
	call dokeys
	jc .run
	pusha
	mov cx,290
	mov dx,0
	mov si,298
	mov di,199
	mov al,15
	call fillbox
	popa

	mov ax,[selected]
	mov bx,22
	mul bx
	mov cx,291
	mov dx,ax
	add dx,1
	mov si,297
	mov di,ax
	add di,21
	mov ax,02
	call fillbox
	jmp .done
.run
	mov bx,[selected]
	mov ax,2
	mul bx
	mov bx,ax
	mov ax,[iconcmds + bx]
	call coopcall
.done
ret

dokeys:
	call waitkey
	clc
	cmp al,'q'
	je .esc
	cmp al,13
	je .enter
	cmp ah,48h
	je .up
	cmp ah,50h
	jne .done
	mov dl,byte[di]
	sub dl,1
	cmp byte[si],dl
	jge .done
	add byte[si],1
	jmp .done
.esc
	mov ax,'QQ'
	jmp .done
.enter
	stc
	jmp .done
.up
	cmp byte[si],0
	je .done
	sub byte[si],1
.done
ret

selected db 0,0

shell:
	mov si,prompt
        call print

        mov di,buffer
        call input

	mov di,buffer
	call commands
	cmp ax,'fl'
	jne .done

	.script
	call findfile
	cmp ax,0
	je .langtry
	call gotask.runcmd
	cmp ax,'fl'
	jne .done
.langtry
	mov si,buffer
	call parse
	call langcommand
	cmp ax,'nc'
	jne .done
.err
	call err
.done
ret

savecurs:
	pusha
	mov ah,03h
	mov bx,0
	int 10h
	mov byte[.x],dl
	mov byte[.y],dh
	popa
ret
	.x db 0,0
	.y db 0,0

loadcurs:
	pusha
	mov ah,02h
	mov bx,0
	mov dl,byte[savecurs.x]
	mov dh,byte[savecurs.y]
	int 10h
	popa
ret

getcurs:
	mov ah,03h
	xor bx,bx
	int 10h
ret

movecurs:
	pusha
	mov ah,02h
	mov bx,0
	int 10h
	popa
ret

%INCLUDE "draw.asm"