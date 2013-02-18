ddbstest:
	mov di,.file
	mov si,.name
	mov bx,.spec
	call newtable

	mov bx,void
	mov si,.file
	call gethashfile
	mov bx,void
	call showdb
ret
	.spec db 2,'GID',0,4,'Passwd',0,10,'Name',0,0,0
	.name db 'tb0',0
	.file db 'db0',0

dbms:
.loop
	mov si,.prmpt
	mov di,buffer
	call getinput

	mov di,buffer
	mov si,quit
	call compare
	jc .done

	mov si,.usechar
	call compare
	jc .use

	mov si,.descchar
	call compare
	jc .desc
	jmp .loop
.use
	mov si,.fname
	mov di,buffer
	call getinput
	call malocbig
	mov [.dbmem],ax
	mov bx,ax
	mov si,buffer
	call gethashfile
	mov si,[.dbmem]
	call showdb
	jmp .loop
.desc
	mov si,.tname
	mov di,buffer
	call getinput

	mov si,[.dbmem]
	mov di,buffer
	call desctb
	jmp .loop
.done
	mov ax,[.dbmem]
	call addr2page
	call freebig
ret
	.usechar db 'use',0
	.descchar db 'desc',0
	.prmpt db 'ddbs>',0
	.fname db 'file>',0
	.tname db 'table>',0
	.dbmem dw 0

newtable:			;DI - DB name, SI - Table Name, BX - Table specs
	push di
	pusha
	call malocbig
	call getregs
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
	push ax
	mov si,bx
	add ax,bx
	mov di,[.end]
	call movemem
	pop ax
	add di,ax
	mov word[di],'**'
	pop si
	mov bx,[.mem]
	call puthashfile
	mov ax,[.mem]
	call addr2page
	call freebig
ret
	.mem dw 0
	.end dw 0

showdb:			;SI - DB location
	add si,1
.printloop
	call print
	call printret
.loop
	cmp word[si],'**'
	je .next
	cmp word[si],00
	je .done
	add si,1
	jmp .loop
.next
	add si,3
	jmp .printloop
.done
ret

desctb:			;SI - DB, DI - table name
	call findtablespec
	mov ax,si
	call length
	add si,ax
	add si,1
.printloop
	pusha
	movzx ax,byte[si]
	call tostring
	mov si,ax
	call print
	call printdot
	popa
	add si,1
	call print
	call printcol
	mov ax,si
	call length
	add si,ax
	add si,1
	cmp word[si],'**'
	je .done
	jmp .printloop
.done
	call printret
ret

findtablespec:		;SI - DB location, DI - Table name
	add si,1
.cmploop
	call compare
	jc .done
.loop
	cmp word[si],'**'
	je .next
	cmp word[si],00
	je .err
.next
	add si,3
	jmp .cmploop
.err
	mov si,0
.done
ret



inserttable:
	
ret