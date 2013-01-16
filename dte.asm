textedit:
	.start
	mov si,.name
	mov di,.filename
	call getinput

	mov si,.filename
	call isfileempty
	jc .starttype
	
	mov si,filesend
	mov dx,filesend + 1024
	call memclear

	mov ax,1
	call maloc
	add ax,1
	mov [.filestart],ax

.loop
	mov di,buffer
	call input
	
	mov di,buffer
	mov si,quit
	call compare
	jc .done
	
	mov ax,buffer
	call length
	call maloc
	mov [.filend],ax
	push ax
	mov si,buffer
	call load2mem
	pop bx
	mov byte[bx],0
	jmp .loop
.starttype
.type
	mov si,void
.typeloop
	call print
	call printret
	mov ax,si
	call length
	add si,ax	
	add si,1
	cmp byte[si],0
	jne .typeloop
.edit
	call printret
	mov si,.line
	mov di,buffer
	call getinput
	cmp byte[buffer],'q'
	je .end
	cmp byte[buffer],'t'
	je .type
	cmp byte[buffer],'w'
	je .editdone
	mov si,buffer
	call toint
	mov si,void
	call getindex
	push si
	call print
	mov si,.outchar
	mov di,buffer
	call getinput
	pop di
	mov si,buffer
	call fixsize
	call copystring
	jmp .edit
.editdone
	mov bx,void
	mov si,.filename
	call puthashfile
	jmp .end
.done
	mov ax,1
	call maloc
	mov byte[bx],0
	mov ax,bx
	add ax,512
	call zeroram
	mov bx,[.filestart]
	mov si,.filename
	call puthashfile
.end
	call printret
ret
	.filestart db 0,0
	.filend db 0,0
	.lines db 0
	.filename times 16 db 0
	.name db 'NAME>',0
	.line db 'LINE>',0
	.list db 'list',0
	.outchar db '>',0

printfile:
	mov bx,void + 4096
	mov di,void + 4096
	call printfilell
ret

printfilell:
	push di
	call gethashfile	
	pop si
.typeloop
	call print
	call printret
	mov ax,si
	call length
	add si,ax
	add si,1
	cmp byte[si],0
	jne .typeloop
.done
ret

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

fixsize:
	pusha
	mov [.src],si
	mov [.dest],di
	push di
	mov ax,si
	call length
	pop di
	push ax
	mov ax,di
	call length
	pop bx
	cmp ax,bx
	jl .grow
	jg .shrink
	jmp .done
.shrink
	mov di,[.dest]
	add di,bx
	mov si,[.dest]
	add si,ax
	mov ax,512
	call memcpy
	jmp .done
.grow
	mov si,[.dest]
	add si,ax
	mov di,[.dest]
	add di,bx
	mov ax,512
	call memcpy
.done
	popa
ret
	.src dw 0
	.dest dw 0