newfile:			;Write file using bFS	IN - si, file name, ax, file length	
	pusha
	mov cx,ax
	mov di,si
.space
	call maloc
.size
	mov [.start],bx
	mov [.end],ax
	mov si,ax
	mov byte[si - 1],0
	mov si,bx
	add si,1
	mov [si],cx
.name
	xchg si,di
	add di,1
	call copystring
.pad
	mov ax,si
	call length
	add di,ax
	mov bx,[.end]
	sub bx,2
.loop
	cmp di,bx
	jge .done
	add di,1
	mov byte [di],0
	jmp .loop
.done
	popa
ret
	.start db 0,0
	.end db 0,0

killfile:
	call findfile
	cmp ax,0
	je .err

	mov si,bx
	mov di,ax
	mov byte[di],0
	mov byte[si - 1],0
	mov ax,bx
	add ax,512
	call movemem
	jmp .done
.err
	mov ax,'nf'
.done
ret

filelist:
	mov si,void + 20
	mov dx,si
	add dx,1024
.loop
	cmp byte [si],'*'
	je .found
	add si,1
	cmp si,dx
	je .done
	jmp .loop
.found
	add si,2
	cmp byte [si],'*'
	je .tag
	cmp byte [si],'0'
	je .done
	cmp byte[si],0
	je .loop
	call print
	call printcol
	jmp .loop
.tag
	sub si,1
	cmp byte [si],'&'
	jne .loop
	add si,2
	call print
	call print~
	jmp .loop
.done
	call printret
ret

printcol:
	pusha
	mov si,.col
	call print
	popa
ret
	.col db '   ',0

print~:
	pusha
	mov si,.~
	call print
	call printcol
	popa
ret
	.~ db '~',0

findfile:
	push si
	push di					;Find file and give location
	mov si,di
	mov bx,void
	call gethashfile
	cmp ax,'er'
	jne .done
.err
	mov ax,0
.done	
	mov ax,void
	mov bx,void + 512
	pop di
	pop si
ret

copyfile:			;Copy file IN, di,name source, si,name destination
	pusha
	push di
	mov di,.dname
	call copystring
	pop si
	mov di,.sname
	call copystring

	mov di,.sname
	call findfile
	mov si,.dname
	mov bx,void
	call puthashfile
.done
	popa
ret
	.sname times 32 db 0
	.dname times 32 db 0

cleartmp:				;Destroy all files called tmp
.loop
	mov di,.tmp
	call killfile
	cmp ax,'nf'
	je .done
	jmp .loop
.done
	call cleanramdisk
ret
	.tmp db 'tmp',0

rename:					;Rename a file IN-di, file, si, name
	push si
	call findfile
	cmp ax,0
	je .err
	pop si

	add ax,2
	mov di,ax
	call copystring
	jmp .done
.err
	mov ax,'nf'
.done
ret

pullfile:
	push di
	call findfile
	push ax
	push bx
	
	mov ax,1
	call maloc
	mov di,ax
	sub di,1

	pop bx
	pop ax
	mov si,ax
	mov ax,bx
	call movemem
	pop di

	mov si,.tmp
	call rename	

	mov di,.tmp
	call findfile
	push ax
	push bx
	mov si,ax
	mov dx,bx
	call markfull
	pop bx
	pop ax

	mov si,bx
	mov di,ax
	add si,1
	add ax,1024
	call movemem
ret
	.tmp db 'mtmp',0

newtag:				;Make a tag, SI, name, DI, value
	push di
	push si
	mov ax,1
	call maloc
	add bx,1
	mov si,bx
	mov cx,'&*'
	mov [si],cx
	pop si
	add bx,2
	mov di,bx
	call copystring
	mov ax,1
	call maloc
	mov si,bx
	mov byte[si],0
	pop di
	xchg si,di
	call copystring
ret

findtag:			;Find a tag, DI, name
	mov si,void + 18
	mov dx,si
	add dx,1024
.loop
	cmp byte[si],'*'
	je .tagp
	add si,1
	cmp si,dx
	jge .nope
	jmp .loop
.tagp
	add si,1
	cmp byte[si],'&'
	jne .loop
	add si,1
	cmp byte[si],'*'
	add si,1
	jmp .istag
.istag
	pusha
	call compare
	jc .found
	popa
	jmp .loop
.nope
	mov ax,0
	jmp .done
.found
	popa
.done
ret

readtag:			;Read tag data, DI, name, out SI, value
	call findtag
	mov ax,si
	call length
	add si,ax
	add si,1		
ret

killtag:			;Kill tag, DI, name
	push di
	call findtag
	pop di
	sub si,3
	push si
	
	call readtag
	mov ax,si
	call length
	add si,ax
	mov dx,si

	pusha
	mov di,si
	call markfull
	popa
	pop si

	mov ax,dx
	add ax,1024
	mov di,si
	mov si,dx
	call movemem
ret

cleanramdisk:
	pusha
	mov si,void + 20
.loop
	cmp byte[si],'*'
	je .42
	add si,1
	cmp si,void + 1024
	jge .done
	jmp .loop
.42
	cmp byte[si + 1],'*'
	jne .ok
	mov byte[si],0
	jmp .loop
.ok
	add si,1
	jmp .loop
.done
	popa	
ret

resetfloppy:
	pusha
	mov ax, 0
	mov dl, 0
	stc
	int 13h
	popa	
ret

l2hts:
	push bx
	push ax
	mov bx, ax			
	mov dx, 0			
	div word [.SecsPerTrack]	
	add dl, 01h			
	mov cl, dl			
	mov ax, bx
	mov dx, 0			
	div word [.SecsPerTrack]	
	mov dx, 0
	div word [.Sides]
	mov dh, dl			
	mov ch, al			
	pop ax
	pop bx
	mov dl, byte 0	
ret
	.Sides dw 2
	.SecsPerTrack dw 18

getdirsec:
	xor cx,cx
.loop
	cmp cx,3
	jge .done
	clc
	pusha
	call trydirsec
	popa
	jc .fail
	jmp .done
.fail
	add cx,1
	jmp .loop
.done
ret

trydirsec:
	mov ax,19
	call l2hts
	mov bx,void + 1024
	mov ah,2
	mov al,2
	stc
	int 13h
ret

populatebfs:
	pusha
	xor cx,cx
	mov si,void + 1024
.loop
	add cx,1
	cmp cx,1024
	jge .done
	
	cmp byte[si],229
	je .dead
	cmp byte[si],'A'
	jl .dead
	cmp byte[si],'z'
	jg .dead
	
	pusha
	call isempty
	cmp al,'T'
	je .nf
	popa

	mov ax,15
	pusha
	call fixfilenames
	cmp dx,'nf'
	je .nf
	call newfile
	mov di,si
	call findfile
	mov [.last],bx
	add si,11
	mov ax,si
	add ax,21
	mov di,bx
	sub di,1
	call movemem
	sub bx,14
	mov byte[bx],35
	mov byte[bx + 33],'*'
	mov byte[bx + 34],0
	mov byte[bx + 9],'V'
	popa
	add si,32
	jmp .loop
.nf
	popa
.dead
	add si,32
	jmp .loop
.done
	popa
ret
	.last db 0,0

fixfilenames:
	mov dx,ax
	mov di,si
	xor cx,cx
.loop
	add cx,1
	cmp cx,8
	jge .dot
	cmp byte[si],' '
	je .dot
	cmp byte[si],'A'
	jl .dead
	cmp byte[si],'Z'
	jg .dead
	add si,1
	jmp .loop
.dead
	mov dx,'nf'
	jmp .done
.dot
	mov byte[si],0
	add si,1
.done
	mov si,di
	mov ax,dx
ret

loadfat:
	pusha
	mov ax,1
	call l2hts
	mov bx,void + 2048
	mov ah,2
	mov al,9
	int 13h
	popa
ret

vfs2disk:
	pusha
	pusha
	call isvfs
	cmp ax,'VF'
	jne .lie
	popa
	push bx
	call resetfloppy
	call findfile
	cmp ax,0
	je .err
	sub bx,6
	mov ax,word[bx]
	add ax,31
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
	popa
	jmp .retry
.lie
	popa
.err
	call err
	mov ax,'er'
.done
	popa
ret

isempty:
	add si,13
	xor cx,cx
.loop
	inc cx
	cmp cx,18
	jge .empty
	cmp byte[si],0
	jg .done
	inc si
	jmp .loop
.empty
	mov al,'T'
.done
ret

isvfs:
	call findfile
	add ax,10
	mov si,ax
	cmp byte[si],'V'
	je .is
	cmp byte[si],'D'
	je .loaded
	jmp .done
.loaded
	mov ax,'LV'
	jmp .done
.is
	mov ax,'VF'
.done
ret

disk2bfs:
	push di
	pusha
	call isvfs
	cmp ax,'VF'
	jne .lie
	popa
	push di
	mov bx,void + 1024
	call vfs2disk
	pop di
	mov si,di
	mov ax,11
	pusha
	call killfile
	popa

	call newfile
	call findfile
	pusha
	mov di,ax
	add di,12
	mov si,void + 1024
	call copystring
	popa

	mov si,ax
	mov di,bx
	mov byte[si + 10],'D'
	mov ax,1
	call maloc
	sub ax,si
	mov byte[si + 1],al
	pop di
	call fixfile
	jmp .done
.lie
	popa
.done
ret

loadrootdir:
	call getdirsec
	call populatebfs
	mov si,[populatebfs.last]
	add si,32
	mov dx,void + 1024
	call memclear
ret

printvf:
	mov bx,void + 1024
	call vfs2disk
	mov si,void + 1024
	call printandfix
	call printret
ret

fixfile:
	pusha
	call findfile
	cmp ax,0
	je .done
	mov byte[bx - 1],0
	add ax,12
	mov si,ax
.loop
	cmp byte[si],9
	je .tab
	cmp byte[si],10
	je .cr
	cmp byte[si],13
	je .cr
	cmp byte[si],'*'
	je .done
	add si,1
	jmp .loop
.tab
	mov byte[si],' '
	jmp .loop
.cr
	mov byte[si],0
	jmp .loop
.done
	popa
ret

printandfix:
	pusha
	mov ah,0Eh
	mov bl,2
.repeat
        lodsb
        cmp al,0
        je .done
	cmp al,9
	je .dotab
	cmp al,10
	je .doret
	.fixok
        int 10h
        jmp .repeat
.dotab
	pusha
	mov si,.tab
	call print
	popa
	jmp .repeat
.doret
	call printret
	jmp .repeat
.done
	popa
ret
	.tab db '     ',0

getvfsdata:
	call resetfloppy
	call findfile
	cmp ax,0
	je bsod
	sub bx,6
	mov ax,word[bx]
	add ax,31
	call l2hts
ret

fixvfs:
.loopup
	cmp byte[di],'*'
	je .done
	add di,1
	cmp di,void + 1024
	jge .fixloop
	jmp .loopup
.fixloop
	mov byte[si],'0'
	inc si
	cmp si,di
	jge .done
	jmp .fixloop
.done
ret

killvfs:
	pusha
	mov si,void + 20
.loop
	cmp byte[si],'*'
	je .file
	add si,1
	cmp si,void + 1024
	jge .done
	jmp .loop
.file
	cmp byte[si + 10],'V'
	je .vfile
	add si,1
	jmp .loop
.vfile
	pusha
	cmp byte[.start],0
	je .set
	.setok
	mov di,si
	xor ax,ax
	mov al,byte[si + 1]
	add di,ax
	mov [.end],di
	xchg si,di
	mov ax,si
	add ax,1024
	call movemem
	popa
	jmp .loop
.set
	mov [.start],si
	jmp .setok
.fix
	mov si,[.start]
	mov di,[.end]
	call fixvfs
	jmp .fixok
.done
	cmp word[.setok],void + 20 + 11
	jg .fix
	.fixok
	popa
ret
	.start db 0,0
	.end db 0,0

resetvfs:
	call killvfs
	call loadrootdir
ret

saveramdisk:
	mov si,.disk
	mov bx,void
	call puthashfile
ret
	.disk db 'disk',0

loadramdisk:
	mov si,.disk
	mov bx,void
	call gethashfile
ret
	.disk db 'disk',0