ddbstest:
	mov bx,void
	mov si,.file
	call gethashfile
	mov si,void
	mov di,.name
	mov ax,.val0
	mov bx,.val1
	mov cx,.val2
	call inserttable
ret
	.name db 'tb0',0
	.file db 'db0',0
	.val0 db '01'
	.val1 db '0123'
	.val2 db 'a value!'

dbms:
	call ddbstest
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

	mov si,.inschar
	call compare
	jc .ins
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
.ins
	call instablecmd
	jmp .loop
.done
	mov ax,[.dbmem]
	call addr2page
	call freebig
ret
	.usechar db 'use',0
	.descchar db 'desc',0
	.inschar db 'ins',0
	.prmpt db 'ddbs>',0
	.fname db 'file>',0
	.tname db 'table>',0
	.dbmem dw 0

maketable:			;DI - db, SI - tb name, BX - tb spec
	pusha
	mov [.mem],di
	mov bx,di
	call getfilesize
	add ax,1
	mov[.end],ax
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
ret
	.end dw 0
	.mem dw 0

newtable:			;DI - DB name, SI - Table Name, BX - Table specs
	push di
	pusha
	call malocbig
	call getregs
	mov [.mem],ax
	mov bx,ax
	mov si,di
	call gethashfile
	popa

	mov di,[.mem]
	call maketable	

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

instablecmd:
	mov si,dbms.tname
	mov di,buffer
	call getinput

	call malocbig
	mov [.mem],ax
	mov byte[.prmpt + 3],'0'
	mov si,.prmpt
	mov di,[.mem]
	call getinput
	add byte[.prmpt + 3],1
	mov si,.prmpt
	mov di,[.mem]
	add di,128
	call getinput
	add byte[.prmpt + 3],1
	mov di,[.mem]
	add di,256
	call getinput

	mov si,dbms.dbmem
	mov di,buffer
	mov ax,[.mem]
	mov bx,[.mem]
	add bx,128
	mov cx,[.mem]
	add cx,256
	call inserttable
ret
	.mem dw 0
	.prmpt db 'val0>',0

inserttable:		;SI - DB location, DI - table name, AX - val0, BX - val1...
	push di
	pusha
	call malocbig
	mov [.mem],ax
	mov bx,ax
	mov si,di
	call gethashfile
	mov bx,[.mem]
	mov [.end],bx
	call getfilesize
	mov [.end],ax
	popa
	call findtablespec
	push ax
	mov ax,si
	call length
	add si,ax
	add si,1
	mov [.spec],si
	pop ax
	call insstub
	mov ax,bx
	call insstub
	mov ax,cx
	call insstub
	mov ax,dx
	call insstub
.done
	pop si
	mov bx,[.mem]
	call puthashfile
	mov ax,[.mem]
	call addr2page
	call freebig
ret
	.mem dw 0
	.end dw 0
	.spec dw 0

insstub:
	cmp ax,0
	je .done
	pusha
	mov di,ax
	mov si,[inserttable.spec]
	movzx ax,byte[si]
	mov si,[di]
	mov di,[inserttable.end]
	call memcpy
	add [inserttable.end],ax
	mov ax,[inserttable.spec]
	call length
	add ax,1
	add [inserttable.spec],ax
	popa
.done
ret