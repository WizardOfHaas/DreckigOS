newuser:	;Makes new user SI - name DI - passwd AX - priv level (0-root) char
	pusha
	mov bx,void
	mov si,userchar
	call gethashfile
	mov si,void
	call getfilesize
	add ax,void + 2
	mov [.end],ax
	.test
	mov si,[.end]
	cmp byte[si -1],0
	je .ok
	add byte[.end],1
	jmp .test
	.ok
	popa

	call useraddstub
	push ax
	mov si,di
	call gethash
	call tostring
	mov si,ax
	call useraddstub
	pop ax
	mov si,[.end]
	mov [si],ax
	mov byte[si + 1],0

	mov bx,void
	mov si,userchar
	call puthashfile
ret
	.end db 0,0

useraddstub:
	pusha
	mov di,[newuser.end]
	call copystring
	mov ax,si
	call length
	add di,ax
	mov byte[di],' '
	add di,1
	mov [newuser.end],di
	popa
ret

killuser:		;DI - user to kill
	call getuserdata
	cmp cx,0
	je .done

	pusha			;Kludge starts here
	mov si,userchar
	mov bx,void
	call gethashfile
	popa			;End kludge

	push di
	mov ax,si
	call length
	add ax,1
	add si,ax
	pop di
	mov ax,512
	call getregs
	call memcpy

	mov bx,void
	mov si,userchar
	call puthashfile
.done
ret

getuserdata:
	mov ax,[root]
	pusha
	mov ax,'0'
	mov [root],ax
	mov si,userchar
	mov bx,void
	call gethashfile
	popa
	mov [root],ax
	call parseuserdata
ret

parseuserdata:		;DI - User Name out SI - hash AX - #
	mov si,void + 2
.loop
	pusha
	mov ax,si
	call length
	add ax,1
	mov [.tmp],ax
	popa

	push si
	push di
	call parse
	mov si,ax
	call compare
	jc .done
	cmp ax,0
	je .done
	pop di
	pop si
	add si,[.tmp]
	jmp .loop
.done
	pop di
	pop si
	mov di,ax
	mov si,bx
	mov bx,cx
	mov ax,[bx]
ret
	.tmp db 0,0

hidepasswd:
	pusha
	mov ax,buffer
	call length
	pusha
	call getcurs
	sub dh,1
	mov dl,9
	call movecurs
	popa
	xor bx,bx
.loop
	mov si,.mask
	call print
	cmp ax,bx
	je .done
	add bx,1
	jmp .loop
.done
	call printret
	popa
ret
	.mask db '*',0

login:
	mov bx,void
	mov si,userchar
	call gethashfile
	mov byte[locked],1
	mov si,.usr
	mov di,buffer
	call getinput
	mov di,buffer
	call parseuserdata
	push ax
	push si

	mov si,.pass
	mov di,buffer
	call getinput
	call hidepasswd
	mov si,buffer
	call gethash
	call tostring
	mov di,ax
	pop si
	call compare
	pop ax
	jc .done
	call err
	jmp login
.done
	mov [user],ax
	mov [root],ax
	mov si,void
	mov dx,void + 512
	call memclear
	call inittags
	mov di,.run
	call runlangfile
	mov byte[locked],0
ret
	.usr db 'UserName>',0
	.pass db 'Password>',0
	.run db 'run',0

usercmd:
	mov si,.prmpt
	mov di,buffer
	call getinput
	
	mov di,buffer
	mov si,.add
	call compare
	jc .addcmd

	mov si,.init
	call compare
	jc .initcmd

	mov si,list
	call compare
	jc .listcmd

	mov si,.kill
	call compare
	jc .killcmd
	jmp .done
.addcmd
	mov si,login.usr
	mov di,buffer
	call getinput
	
	mov si,login.pass
	mov di,void + 4096
	call getinput

	mov si,.grp
	mov di,void + 2048
	call getinput
	mov ax,[void + 2048]

	mov si,buffer
	mov di,void + 4096
	call newuser
	jmp .done
.initcmd
	mov si,userchar
	call killhashfile
	mov ax,'0'
	mov si,.root
	mov di,.root
	call newuser
	jmp .done
.listcmd
	mov si,userchar
	mov bx,void
	mov di,void + 2
	call printfilell
	jmp .done
.killcmd
	mov si,login.usr
	mov di,buffer
	call getinput
	mov di,buffer
	call killuser
.done
ret
	.prmpt db 'USER>',0
	.grp db 'Group>',0
	.add db 'add',0
	.init db 'init',0
	.root db 'root',0
	.kill db 'kill',0

changeroot:
	mov si,.prmpt
	mov di,buffer
	call getinput

	mov di,buffer
	call getuserdata
	call unmountcmd
	mov [root],ax
ret
	.prmpt db 'New root>',0

sudocmd:
	push si
	mov di,usercmd.root
	call getuserdata
	push si
	mov si,login.pass
	mov di,void
	call getinput
	call hidepasswd
	mov si,void
	call gethash
	call tostring
	pop si
	mov di,ax
	call compare
	pop di
	jc .run
	jmp .done
.run
	mov ax,[user]
	mov bx,[root]
	push ax
	push bx
	mov ax,'0'
	mov bx,ax
	mov [user],ax
	mov [root],bx
	call commands
	pop bx
	pop ax
	mov [user],ax
	mov [root],bx
	call unmountcmd
.done
ret