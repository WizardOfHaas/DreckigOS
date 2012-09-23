gotask:	
	.start
	mov si,.name
	call print
	mov di,.file
	call input

	mov di,.file
	mov si,textedit.list
	call compare
	jc .listfiles

	mov di,.file
	call findfile
	cmp ax,0
	je .err
.runcmd
	mov [.filend],bx
	add ax,12
	mov di,ax
.runloop
	pusha
	call getthread
	cmp ax,'fl'
	je .done
	call schedule
	popa
	mov ax,di
	push di
	call length
	pop di
	add di,ax
	add di,1
	cmp di,[.filend]
	jge .runit
	jmp .runloop
.listfiles
	call filelist
	jmp .start
.runit
	mov ax,.done
	call schedule
	.runitloop
	call yield
	cmp byte[yield.fullp],1
	je .done
	jmp .runitloop
.err
	call err
.done
	call killque
	mov ax,shell
	call schedule
ret
	.file times 8 db 0
	.filend db 0,0
	.name db 'NAME>',0

HCF:
	mov dx,0
	call getpit
	push ax
.loop
	cmp dx,bx
	je .end
	mov ax,dx
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print
	add dx,1
jmp .loop
.end	
	call printret
	mov si,.ticks
	call print
	call getpit
	mov bx,ax
	pop ax
	sub ax,bx
	call tostring
	mov si,ax
	call print
	call printret
ret
	.space db ' ',0
	.ticks db 'Ticks ',0

getpit:				;Get time from PIT
	pushfd
	cli			;OUT - ax, time in ticks
	mov al,00000000b
	out 43h,al
	in al,40h	
	mov ah,al
	in al,40h
	rol ax,8
	sti
	popfd
ret

tasklist:
	pusha
	mov bx,taskque
.loop
	cmp word[bx],00
	jne .task
	add bx,2
	cmp bx,taskque + 32
	jge .done
	jmp .loop
.task
	push bx
	mov ax,bx
	sub ax,taskque
	call tostring
	mov si,ax
	call print
	call printcol
	pop bx
	push bx
	mov ax,[bx]
	call tostring
	mov si,ax
	call print
	call printret
	pop bx
	add bx,2
	jmp .loop
.done
	popa
ret

findclearque:
	mov bx,taskque
.loop
	cmp bx,taskque + 32
	jge .done
	cmp word[bx],00
	je .done
	add bx,2
	jmp .loop
.done
ret

kill:			;IN - ax, pid
	pusha
	mov bx,taskque
	add bx,ax
	mov word[bx],00
	popa
ret

killque:		;Deschedule all tasks
	pusha
	mov si,taskque
.loop
	cmp si,taskque + 32
	jge .done
	mov byte[si],0
	add si,1
	jmp .loop
.done
	popa
ret

schedule:			;IN - ax, ip of proccess, OUT - ax, pid
	call findclearque
	mov word[bx],ax
	mov ax,bx
	sub ax,taskque
ret

yield:
	pusha
	mov bx,word[currpid]
	add bx,2
.loop
	cmp word[bx],00
	jne .run
	add bx,2
	cmp bx,taskque + 32
	jge .full
	jmp .loop
.full
	mov bx,taskque
	mov byte[.fullp],1
	jmp .loop
.run
	mov byte[.fullp],0
	mov word[currpid],bx
	call word[bx]
.done
	popa
ret
	.fullp db 0,0

coopcall:
	call schedule
	mov word[.pid],ax
	call yield
	mov ax,word[.pid]
	call kill
ret
	.pid db 0,0,0

currpid db 0,0
taskque times 32 db 0