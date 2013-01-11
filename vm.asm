nodemaster:
	xor bx,bx
.schedloop
	cmp word[.romlist + bx],0
	je .runloop
	mov dx,bx
	mov si,word[.romlist + bx]
	mov di,word[.cpulist + bx]
	mov ax,runcpu
	call schedule
	call getregs
	add bx,2
	cmp word[.romlist + bx],0
	je .runloop
	cmp word[.cpulist + bx],0
	je .runloop
	add byte[.numvm],2
	jmp .schedloop
.runloop
	call tasklist
.run
	cmp byte[startvm.comp],2
	je .done
	call yield
	jmp .run
.done
ret
	.cpulist times 8 db 0
	.romlist times 8 db 0
	.int db 0,0
	.numvm db 0,0

alocvm:
	pusha
	mov si,bx
	push si
	mov ax,16
	mov si,di
	call malocsmall
	pop si
	call zeroram
	mov word[nodemaster.cpulist + si],bx
	popa	
ret

alocallvm:
	call malocbig
	mov di,ax
	xor bx,bx
.loop
	cmp bx,6
	jge .done
	call alocvm
	add bx,2
	jmp .loop
.done
ret

runrom:
	push di
	call killque
	call killvfs
	call loadrootdir
	pop di
	mov bx,void + 2048
	call vfs2disk
	cmp ax,'er'
	je .err
	mov ax,16
	call maloc
	call zeroram
	mov si,void + 2048
	mov di,bx
	mov dx,0
	call runcpu
	call free
	mov bx,void + 2048
	mov ax,void + 2048 + 512
	call free
	call printret
	jmp .done
.err
	mov ax,'fl'
.done
	call killque
	mov ax,shell
	call schedule
ret

cmdlinevm:
	mov di,bx
	mov bx,void + 2048
	mov [nodemaster.romlist],bx
	call vfs2disk
	cmp cx,0
	je .done
	mov bx,void + 2560
	mov [nodemaster.romlist + 2],bx
	mov di,cx
	call vfs2disk
	cmp dx,0
	je .done
	mov bx,void + 3072
	mov [nodemaster.romlist + 4],bx
	mov di,dx
	call vfs2disk
.done
	call killque
	mov byte[doterm],1
	call startvm.run
ret

startvm:	
	call killque
	
	mov si,.msg
	call print
	mov byte[doterm],1

	call loadroms
.run
	call alocallvm
	call nodemaster

;	mov si,void + 20
;	mov dx,void + 1024
;	call memclear

	mov byte[startvm.comp],0
	mov byte[doterm],0

	call printret

	call killque
	mov ax,shell
	call schedule
ret
	.msg db 'VMHUD outputing over serial line...',13,10
	.comp db 0,0

loadroms:
	pusha
	call getdirsec
	call populatebfs
	mov byte[.rom + 3],'A'
	mov bx,void + 2048
	mov di,.rom
	xor si,si
.loop
	call getregs
	call vfs2disk
	cmp ax,'er'
	je .done
	mov word[nodemaster.romlist + si],bx
	add si,2
	cmp byte[.rom + 3],'C'
	jge .done
	add byte[.rom + 3],1
	add bx,512
	jmp .loop
.done
	call killvfs
	call printret
	popa
ret
	.rom db 'ROMA',0

runcpu:
	pusha
.loop
	cmp byte[di + 11],'D'
	je .die
	cmp byte[di + 9],'S'
	je .done
	cmp byte[di + 9],'W'
	je .wait
	cmp byte[.int],0
	jne .doint
	call runop
	call yield
	jmp .loop
.wait
	call yield
	cmp byte[di + 9],'W'
	je .wait
	jmp .loop
.doint
	mov al,byte[.int]
	mov byte[.int],0
	call doint
	jmp .loop
.die
	mov byte[di + 11],0
	mov byte[di + 9],'S'
	mov ax,dx
	call getregs
	call kill
.done
	add byte[startvm.comp],1
	popa
ret
	.int db 0,0

vmhud:
	pusha
	mov ax,[doterm]
	mov [.tmp],ax
	mov byte[doterm],1
	mov ax,dx
	call tostring
	mov si,ax
	call print
	call printcol
	movzx ax,byte[di + 3]
	call tostring
	mov si,ax
	call print
	call printdash
	movzx ax,byte[di + 5]
	call tostring
	mov si,ax
	call print
	call printdash
	movzx ax,byte[di + 7]
	call tostring
	mov si,ax
	call print
	call printcol
	movzx ax,byte[di]
	call tostring
	mov si,ax
	call print
	call printcol
	movzx ax,byte[di + 11]
	call tostring
	mov si,ax
	call print
	movzx ax,byte[di + 9]
	call tostring
	mov si,ax
	call print
	call printret
	mov ax,[.tmp]
	mov [doterm],ax
	popa
ret
	.tmp db 0,0

printdash:
	pusha
	mov si,.dash
	call print
	popa
ret
	.dash db '-',0

runop:
	pusha
	cmp byte[di + 11],'D'
	je .done
	mov cx,si
	mov si,[di]
	add si,cx
	cmp byte[di + 9],'w'
	je .waitloop
	add byte[di],1

	cmp byte[si],0
	je .stop
	cmp byte[si],1
	je .set
	cmp byte[si],2
	je .and
	cmp byte[si],3
	je .or
	cmp byte[si],4
	je .getmem
	cmp byte[si],41
	je .getmemreg
	cmp byte[si],5
	je .setmem
	cmp byte[si],51
	je .setmemreg
	cmp byte[si],6
	je .nop
	cmp byte[si],7
	je .jmp
	cmp byte[si],8
	je .cmp
	cmp byte[si],81
	je .cmpregs
	cmp byte[si],9
	je .mov
	cmp byte[si],10
	je .jne
	cmp byte[si],11
	je .je
	cmp byte[si],12
	je .jg
	cmp byte[si],13
	je .jl
	cmp byte[si],14
	je .call
	cmp byte[si],15
	je .ret
	cmp byte[si],16
	je .wait
	cmp byte[si],17
	je .run
	cmp byte[si],20
	je .add
	cmp byte[si],21
	je .inc
	cmp byte[si],22
	je .addreg
	cmp byte[si],23
	je .sub
	cmp byte[si],24
	je .dec
	cmp byte[si],25
	je .subreg
	cmp byte[si],30
	je .int
	cmp byte[si],35
	je .putscreen
	cmp byte[si],36
	je .putregscreen
	cmp byte[si],38
	je .incP
	cmp byte[si],39
	je .decP
	cmp byte[si],40
	je .getkeybd
.stop
	mov byte[di + 9],'S'
	jmp .done
.incP
	add byte[di],1
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	mov bx,[di]
	add byte[ram + bx],1
	jmp .done
.decP
	add byte[di],1
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	mov bx,[di]
	sub byte[ram + bx],1
	jmp .done
.mov
	mov cx,di
	add byte[di],2
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	movzx bx,byte[si + 2]
	call calcreg
	mov bx,ax
	add bx,cx
	xor ax,ax
	mov al,byte[bx]
	mov byte[di],al
	jmp .done
.set
	add byte[di],2
	movzx bx,[si + 1]
	call calcreg
	add di,ax
	mov bl,byte[si + 2]
	mov byte[di],bl
	jmp .done
.and
	mov al,byte[di + 3]
	mov bl,byte[di + 5]
	and al,bl
	mov byte[di + 7],al
	jmp .done
.or
	mov al,byte[di + 3]
	mov bl,byte[di + 5]
	or al,bl
	mov byte[di + 7],al
	jmp .done
.getmem
	add byte[di],2
	movzx bx,byte[si + 1]
	call calcreg
	movzx bx,[si + 2]
	add bx,ram
	mov cl,byte[bx]
	add di,ax
	mov byte[di],cl
	jmp .done
.getmemreg
	add byte[di],2
	call calc2regs
	mov si,di
	add di,ax
	add si,bx
	movzx bx,byte[si]
	mov al,byte[ram + bx]
	mov byte[di],al
	jmp .done
.setmem
	add byte[di],2
	movzx bx,byte[si + 1]
	call calcreg
	movzx bx,[si + 2]
	add bx,ram
	add di,ax
	mov cl,byte[di]
	mov byte[bx],cl
	jmp .done
.setmemreg
	add byte[di],2
	call calc2regs
	mov si,di
	add di,ax
	add si,bx
	mov al,byte[di]
	movzx bx,byte[si]
	mov byte[ram + bx],al
	jmp .done
.jmp
	mov al,byte[si + 1]
	mov byte[di],al
	jmp .done
.jne
	cmp byte[di + 11],1
	jne .jmp
	add byte[di],1
	jmp .done
.je
	cmp byte[di + 11],1
	je .jmp
	add byte[di],1
	jmp .done
.jg
	cmp byte[di + 11],2
	je .jmp
	add byte[di],1
	jmp .done
.jl
	cmp byte[di + 11],3
	je .jmp
	add byte[di],1
	jmp .done
.call
	movzx bx,byte[di + 13]
	mov al,byte[di]
	add al,2
	add bx,ram
	mov byte[bx],bl
	sub byte[di + 13],1
	jmp .jmp
.ret
	movzx bx,byte[di + 13]
	add bx,ram
	mov al,byte[bx]
	mov byte[di],al
	add byte[di + 13],1
	jmp .done
.wait
	mov byte[di + 9],'w'
	mov bl,byte[si + 1]
	mov al,byte[si + 2]
	mov byte[.w1],bl
	mov byte[.w2],al
.waitloop
	call err
	movzx bx,byte[.w1]
	movzx ax,byte[.w2]
	movzx cx,byte[ram + bx]
	cmp byte[di + 11],'D'
	je .waitdone
	cmp cx,ax
	je .waitdone
	call yield
	jmp .waitloop
.waitdone
	add byte[di],2
	mov byte[di + 9],0
	jmp .done
.w1 db 0,0
.w2 db 0,0
.run
	movzx bx,byte[si + 1]
	cmp bx,255
	je .runreg
	mov si,ram
	add si,bx
	mov al,byte[di]
	.regok
	movzx bx,byte[di]
	sub si,bx
	call runop
	call vmhud
	mov byte[di],al
	add byte[di],1
	jmp .done
.runreg
	push dx
	push di
	movzx bx,byte[si + 2]
	call calcreg
	add di,ax
	movzx si,byte[di]
	add si,ram
	pop di
	pop dx
	mov al,byte[di]
	add al,1
	jmp .regok
.cmpregs
	add byte[di],2
	call calc2regs
	mov ah,bl
	je .docmp
.cmp
	add byte[di],2
	movzx bx,byte[si + 1]
	call calcreg
	add ax,di
	mov bx,ax
	mov al,byte[bx]
	mov ah,byte[si + 2]
.docmp
	cmp al,ah
	je .cmpe
	jg .cmpg
	jl .cmpl
	mov byte[di + 11],0
	jmp .done
.cmpe
	mov byte[di + 11],1
	jmp .done
.cmpg
	mov byte[di + 11],2
	jmp .done
.cmpl
	mov byte[di + 11],3
	jmp .done
.add
	mov al,byte[di + 3]
	mov ah,byte[di + 5]
	add al,ah
	mov byte[di + 7],al
	jmp .done
.addreg
	movzx bx,byte[si + 1]
	call calcreg
	push di
	mov bl,byte[si + 2]
	add di,ax
	add byte[di],bl
	pop di
	add byte[di],2
	jmp .done
.sub
	mov al,byte[di + 3]
	mov ah,byte[di + 5]
	sub al,ah
	mov byte[di + 7],al
	jmp .done
.subreg
	movzx bx,byte[si + 1]
	call calcreg
	push di
	mov bl,byte[si + 2]
	add di,ax
	sub byte[di],bl
	pop di
	add byte[di],2
	jmp .done
.inc
	add byte[di],1
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	add byte[di],1
	jmp .done
.dec
	add byte[di],1
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	sub byte[di],1
	jmp .done
.int
	add byte[di],1
	mov al,byte[si + 1]
	mov ah,byte[di + 15]
	mov byte[runcpu.int],al
	mov [doint.caller],di
	jmp .done
.putscreen
	add byte[di],1
	mov al,byte[si + 1]
	mov byte[.buf],al
	.print
	mov si,.buf
	mov ah,byte[doterm]
	mov byte[doterm],0
	call print
	mov byte[doterm],ah
	jmp .done
.putregscreen
	add byte[di],1
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	mov al,byte[di]
	mov byte[.buf],al
	jmp .print
.getkeybd
	add byte[di],1
	call waitkey
	push ax
	movzx bx,byte[si + 1]
	call calcreg
	add di,ax
	pop ax
	mov byte[di],al
	jmp .done
.nop
.done
	popa
ret
	.buf db 0,0,0

calc2regs:
	movzx bx,byte[si + 1]
	call calcreg
	push ax
	movzx bx,byte[si + 2]
	call calcreg
	mov bx,ax
	pop ax
ret

calcreg:
	mov ax,2
	mul bx
	add ax,3
ret

clearW:
	pusha
	xor bx,bx
.loop
	cmp word[nodemaster.cpulist + bx],0
	je .done
	mov si,word[nodemaster.cpulist + bx]
	add bx,2
	cmp byte[si + 9],'W'
	jne .loop
	mov byte[si + 9],0
	jmp .loop
.done
	popa
ret

doint:
	pusha
	mov dx,[.caller]
	cmp al,1
	je .getcpulist
	cmp al,2
	je .wait
	cmp al,3
	je .endlich
	cmp al,4
	je .tott
	jmp .done
.getcpulist
	mov di,dx
	mov al,byte[nodemaster.numvm]
	mov byte[di + 3],al
	jmp .done
.wait
	mov di,dx
	mov byte[di + 9],'W'
	jmp .done
.endlich
	call clearW
	jmp .done
.tott
	call killallvms
	mov ax,shell
	call schedule
	call tasklist
.done	
	popa
ret
	.caller db 0,0

killallvms:
	mov si,nodemaster.cpulist
	xor bx,bx
.loop
	mov di,word[nodemaster.cpulist + bx]
	cmp di,0
	je .wait
	mov byte[di + 11],'D'
	add bx,2
	jmp .loop
.wait
	call findclearque
	sub bx,taskque
	call printret
	call getregs
	cmp bx,0
	je .done
	call yield
	jmp .wait
.done
ret

ram:
times 256 db 0