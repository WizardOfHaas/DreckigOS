ddbstest:
	mov di,.file
	mov si,.name
	mov bx,.spec
	call newtable
ret
	.spec db 2,'GID',0,4,'Passwd',0,10,'Name',0,0,0
	.name db 'tb0',0
	.file db 'db0',0

newtable:			;DI - DB name, SI - Table Name, BX - Table specs
	pusha
	call malocbig
	mov [.mem],ax
	mov bx,ax
	mov si,di
	call gethashfile
	mov bx,[.mem]
	call getfilesize
	add ax,1
	mov [.end],ax
	mov bx,[.mem]
	add [.end],bx
	popa

	push bx
	mov di,[.end]
	call copystring
	mov ax,si
	call length
	add ax,1
	add [.end],ax
	pop bx

	push bx
	call getfilesize
	add ax,1
	pop bx
	mov si,bx
	add ax,bx
	push ax
	mov di,[.end]
	call getregs
	call movemem
	pop si
	mov word[si],'**'
ret
	.mem dw 0
	.end dw 0