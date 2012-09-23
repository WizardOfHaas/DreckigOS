fileman:
.loop
	mov si,.prmpt
	call print
	mov di,buffer
	call input
	
	mov di,buffer
	mov si,quit
	call compare
	jc .done

	mov si,.list
	call compare
	jc .listcmd
	
	mov si,.type
	call compare
	jc .typecmd

	mov si,.kill
	call compare
	jc .killcmd

	mov si,.find
	call compare
	jc .findcmd

	mov si,.tag
	call compare
	jc .tagcmd

	mov si,.readtag
	call compare
	jc .readtagcmd

	mov si,.killtag
	call compare
	jc .killtagcmd

	jmp .loop
.listcmd
	call filelist
	jmp .loop
.typecmd
	call getfilename
	mov di,buffer
	call findfile
	cmp ax,0
	je .err
	call printfile
	call printret
	jmp .loop
.killcmd
	call getfilename
	mov di,buffer
	call killfile
	jmp .done
.findcmd
	call getfilename
	mov di,buffer
	call findfile
	cmp ax,0
	je .err

	cmp byte[bx + 10],'V'
	je .doV

	push bx
	push ax
	mov ax,bx
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print
	pop ax
	push ax
	call tostring
	mov si,ax
	call print
	call printret
	
	pop ax
	pop bx
	sub bx,ax
	mov ax,bx
	call tostring
	mov si,ax
	call print
	mov si,.bytes
	call print
	call printret
	jmp .loop
.doV
	
	jmp .loop
.tagcmd
	call getfilename
	mov si,buffer
	mov di,langcommand.cmdbuff
	call copystring
	call getfilename
	mov si,langcommand.cmdbuff
	mov di,buffer
	call newtag
	jmp .loop
.readtagcmd
	call getfilename
	mov di,buffer
	call readtag
	call print
	call printret
	jmp .loop
.killtagcmd
	call getfilename
	mov di,buffer
	call killtag
	jmp .loop
.err
	call err
	jmp .loop
.done
ret
	.prmpt db 'FILE>',0
	.list db 'list',0
	.type db 'type',0
	.kill db 'kill',0
	.find db 'find',0
	.tag db 'tag',0
	.readtag db 'readtag',0
	.killtag db 'killtag',0
	.space db '-',0
	.bytes db ' bytes',0

getfilename:
	mov si,.name
	call print
	mov di,buffer
	call input
ret
	.name db 'NAME>',0

guifileman:
	mov byte[guiprint.x],1
	mov cx,5
	mov dx,5
	mov si,100
	mov di,195
	call drawwin
	mov dl,1
	mov dh,1
	call movecurs
	call filelist
	mov [.numfiles],ax
.loop	
	call filesel
	cmp ax,'QQ'
	jne .loop
	call background
ret
	.numfiles db 0,0

filesel:
	mov si,.selected
	mov di,guifileman.numfiles
	call dokeys
	jc .print
	cmp ax,'QQ'
	je .done
	
	pusha
	mov cx,90
	mov dx,8
	mov si,97
	mov di,190
	mov al,00
	call fillbox
	popa
	
	mov ax,[.selected]
	mov bx,8
	mul bx
	mov cx,90
	mov dx,ax
	add dx,8
	mov si,95
	mov di,ax
	add di,16
	mov ax,02
	call fillbox
	jmp .done
.print
	mov cx,115
	mov dx,5
	mov si,250
	mov di,195
	call drawwin

	mov ax,[.selected]
	call getfileindex
	mov di,si
	mov dl,15
	mov dh,1
	call movecurs
	mov dx,[guiprint.x]
	mov byte[guiprint.x],15
	pusha
	call print?file
	popa
	mov [guiprint.x],dx
.done
ret
	.selected db 0,0