gethash:
	xor ax,ax
	mov cx,2
.loop
	cmp byte[si],0
	je .done
	movzx bx,byte[si]
	sub bx,64	
	add ax,bx
	mul cx
	add si,1
	jmp .loop
.done
	mov bx,2880
	div bx
	mov ax,dx
ret

userhash:
	mov si,.prmpt
	mov di,buffer
	call getinput
	
	mov si,buffer
	mov di,.put
	call compare
	jc .putcmd

	mov di,.get
	call compare
	jc .getcmd

	mov di,.kill
	call compare
	jc .killcmd

	mov di,.test
	call compare
	jc .testcmd
	jmp .done
.putcmd
	mov si,.name
	mov di,buffer
	call getinput
	mov si,.outchar
	mov di,void + 100
	call getinput

	mov si,buffer
	mov bx,void + 100
	call putfiletimed
	jmp .done
.getcmd
	mov si,.name
	mov di,buffer
	call getinput
	
	mov si,buffer
	mov bx,void
	call getfiletimed
	mov si,void
	call print
	call printret
	jmp .done
.killcmd
	mov si,.name
	mov di,buffer
	call getinput
	mov si,buffer
	call killhashfile	
	jmp .done
.testcmd
	call testdrive
.done
ret
	.prmpt db 'hashfs>',0
	.name db 'name>',0
	.outchar db '>',0
	.get db 'get',0
	.put db 'put',0
	.kill db 'kill',0
	.test db 'test',0

testdrive:
	mov si,.test
	mov bx,void
	call getfiletimed
	mov si,.test
	mov bx,void
	call putfiletimed
ret
	.test db 'test',0

getfiletimed:
	call cleartime
	call gethashfile
	call getsystime
	mov ax,dx
	call tostring
	mov si,ax
	call print
	call printret
ret

putfiletimed:
	call cleartime
	call puthashfile
	call getsystime
	mov ax,dx
	call tostring
	mov si,ax
	call print
	call printret
ret

gethashfile:
	call resetfloppy
	push bx
	mov bx,[user]
	cmp bx,'0'
	jne .unpriv
	.ok
	call gethash
	call l2hts

	pop bx
	mov ah,2
	mov al,1
	xor di,di
	.retry
	inc di
	cmp di,3
	jge .err
	pusha
	stc
	int 13h
	jc .fail
	popa
	jmp .done
.fail
	jmp .retry
.unpriv
	push si
	mov si,user
	mov di,buffer
	call copystring
	pop si
	mov di,buffer
	call stringappend
	mov si,buffer
	jmp .ok
.err
	call err
	mov ax,bx
	add ax,512
	call zeroram
	mov ax,'er'
	jmp .end
.done
	pusha
	cmp byte[crypton],0
	je .clear
	mov si,bx
	call decrypt
	call getfilesize
	mov ax,bx
	add ax,512
	call zeroram
	.clear
	popa
.end
ret

puthashfile:
	pusha
	cmp byte[crypton],0
	je .clear
	push bx
	mov si,bx
	call encrypt
	pop bx
	call fillfile
	.clear
	popa
	pusha
	push bx
	mov bx,[user]
	cmp bx,'0'
	jne .unpriv
	.ok
	call gethash
	call l2hts

	pop bx
	mov ah,3
	mov al,1
	xor di,di
	.retry
	inc di
	cmp di,3
	jge .err
	pusha
	stc
	int 13h
	jc .fail
	popa
	jmp .done
.fail
	jmp .retry
.unpriv
	push si
	mov si,user
	mov di,buffer
	call copystring
	pop si
	mov di,buffer
	call stringappend
	mov si,buffer
	jmp .ok
.err
	call err
	mov ax,'er'
.done
	popa
ret

isfileempty:
	pusha
	mov bx,void + 4096
	call gethashfile
	mov si,void + 4096
.loop
	cmp byte[si],0
	jne .stuff
	cmp si,void + 4096 + 512
	jge .empty
	add si,1
	jmp .loop
.empty
	clc
	jmp .done
.stuff
	stc
.done
	popa
ret

getfilesize:
	xor ax,ax
.loop
	cmp word[bx],0
	je .done
	cmp ax,512
	jge .done		
	add ax,1
	add bx,1
	jmp .loop
.done
ret

makefileempty:
	pusha
	mov si,void + 4096
.loop
	mov byte[si],0
	cmp si,void + 4096 + 512
	jg .done
	add si,1
	jmp .loop
.done
	popa	
ret

killhashfile:
	call makefileempty
	mov bx,void + 4096
	call puthashfile
ret

getindex:
.loop
	cmp ax,0
	je .done
	cmp byte[si],0
	je .test
	add si,1
	jmp .loop
.test
	add si,1
	sub ax,1
	jmp .loop
.done
ret

crashlog:
	mov [void + 4096 + 10],di
	mov di,void + 4096
	mov [di],ax
	mov [di + 2],bx
	mov [di + 4],cx
	mov [di + 6],dx
	mov [di + 8],si
	mov [di + 12],ss
	mov [di + 14],cs
	mov [di + 16],ds
	mov [di + 18],es
	mov [di + 20],fs
	mov [di + 22],gs
	mov [di + 24],sp
	mov [di + 26],bp

	mov bx,void + 4096
	mov si,crash
	call puthashfile

	mov bx,void
	mov si,.void
	call puthashfile
ret
	.void db 'void',0

printhashfile:
	mov bx,void + 4096
	call gethashfile
	mov si,void + 4096
.typeloop
	call print
	call printret
	mov ax,si
	call length
	add si,ax	
	add si,1
	cmp byte[si],0
	jne .typeloop
ret