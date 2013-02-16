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
	mov byte[.any],1
.loop
	cmp word[bx],00
	jne .task
	add bx,2
	cmp bx,taskque + 32
	jge .done
	jmp .loop
.task
	mov byte[.any],0
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
	.any db 0,0

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

killcmd:
	mov si,.pid
	mov di,buffer
	call getinput
	mov si,buffer
	call toint
	call kill
ret
	.pid db 'PID>',0

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
	pusha
	call findclearque
	mov word[bx],ax
	mov ax,bx
	sub ax,taskque
	mov [.pid],ax
	mov [saveregs.base],ax
	popa
	call saveregs
	mov ax,[.pid]
ret
	.pid db 0,0

initstatestore:
	call malocbig
	mov [statestore],ax
	call malocbig
ret

saveregs:
	pusha
	mov ax,[.base]
	mov bx,16
	mul bx
	add ax,[statestore]
	mov [.base],ax
	popa
	pusha
	push di
	mov di,[.base]
	mov [di],ax
	mov [di + 2],bx
	mov [di + 4],cx
	mov [di + 6],dx
	mov [di + 8],si
	mov si,di
	pop di
	mov [si + 10],di
	popa
ret
	.base db 0,0

pullregs:
	pusha
	mov ax,[.base]
	mov bx,16
	mul bx
	add ax,[statestore]
	mov [.base],ax
	popa
	mov di,[.base]
	mov ax,[di]
	mov bx,[di + 2]
	mov cx,[di + 4]
	mov dx,[di + 6]
	mov si,[di + 8]
	mov di,[di + 10]
ret
	.base db 0,0

numtasks:
	xor ax,ax
	push bx
	xor bx,bx
.loop
	cmp bx,32
	jge .done
	add bx,2
	cmp word[taskque + bx],1
	jle .task
	jmp .loop
.task
	add ax,1
	jmp .loop
.done
	call getregs
	pop bx
ret

yield:
	pusha
	mov byte[.fullp],0
	mov bx,[currpid]
	add bx,2
.loop
	cmp word[bx],00
	jne .run
	add bx,2
	cmp bx,taskque + 32
	jge .full
	jmp .loop
.full
	cmp byte[.fullp],1
	je .done
	mov bx,taskque
	mov byte[.fullp],1
	jmp .loop
.run
	mov byte[.fullp],0
	mov word[currpid],bx
	mov word[pullregs.base],bx
	sub word[pullregs.base],taskque
	push bx
	call pullregs
	pop bx
	call word[bx]
.done
	popa
ret
	.fullp db 0,0

coopcall:
	call schedule
	push ax
	call yield
	pop ax
	call kill
ret

cleartime:
	pusha
	mov ah,01h
	xor cx,cx
	xor dx,dx
	int 1Ah
	popa
ret

getsystime:
	xor ax,ax
	int 1Ah
ret

wintest:
	call savecurs

	mov dh,0
	mov dl,70
	call movecurs
	call tasklist

	call loadcurs
	call yield
ret
	.msg db 'test!',0

currpid db 0,0
taskque times 32 db 0
times 2 db 0