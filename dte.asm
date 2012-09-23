textedit:
	.start
	mov si,.name
	call print
	mov di,buffer
	call input

	mov si,buffer
	mov di,.list
	call compare
	jc .listfiles

	mov si,buffer
	mov di,.filename
	call copystring

	mov di,.filename
	call findfile
	cmp ax,0
	jne .type

	mov si,.filename
	mov ax,11
	call newfile
	mov di,.filename
	call findfile
	mov [.filestart],ax
.loop
	add byte [.lines],1
	mov di,buffer
	call input
	
	mov di,buffer
	mov si,quit
	call compare
	jc .done
	
	mov ax,buffer
	call length
	call maloc
	push ax
	mov si,buffer
	call load2mem
	pop bx
	add byte [.lines],1
	jmp .loop
.type
	mov di,.filename
	call tagprintfile
.edit
	mov si,.line
	call print
	mov di,buffer
	call input

	mov si,buffer
	call toint
	mov di,.filename
	call getindex
	push di
	mov si,di
	call print

	mov si,langcommand.outchar
	call print
	mov di,buffer
	call input
	pop di
	push di

	mov ax,di
	call length
	push ax
	mov ax,buffer
	call length
	pop bx
	cmp ax,bx
	jg .editgrow
	jl .editshrink
	.editok
	pop di
	mov si,buffer
	call copystring
	jmp .done
.editshrink
	pop di
	push di
	mov si,di
	add si,bx
	add di,ax
	mov ax,si
	add ax,1024
	call movemem
	jmp .editok
.editgrow
	pop di
	push di
	mov si,di
	add si,bx
	add di,ax
	mov ax,1024
	call memcpy
	jmp .editok
.listfiles
	call filelist
	jmp .start
.done
	mov ax,1
	call maloc

	mov si,[.filestart]
	sub bl,[.filestart]
	add si,1
	mov [si],bl
	mov si,[.filestart]
	add si,10
	mov al,'d'
	mov [si],al
.end
	call printret
ret
	.filestart db 0
	.filend db 0
	.lines db 0
	.filename times 16 db 0
	.name db 'NAME>',0
	.line db 'LINE>',0
	.list db 'list',0

printfile:
	add ax,12
	mov [.filend],bx
	mov si,ax
.typeloop
	call print
	mov ax,si
	call length
	add si,ax
	cmp si,[.filend]
	jge .done
	add si,1
	call printret
	cmp byte[si],'*'
	je .done
	jmp .typeloop
.done
ret
	.filend db 0,0

tagprintfile:
	mov [.nextfile],di

	call findfile
	cmp ax,0
	je .done
	call printfile
	mov di,[.nextfile]
.loop
	call findtag
	cmp ax,0
	je .done
	mov di,[.nextfile]
	
	call readtag
	mov di,si
	mov [.nextfile],di
	call findfile
	cmp ax,0
	je .done
	call printfile
	mov di,[.nextfile]
	jmp .loop
.done
	call printret
ret
	.nextfile db 0,0