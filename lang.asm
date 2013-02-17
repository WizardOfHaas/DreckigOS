langcommand:
.commands
	pusha
	mov di,.cmdbuff
	call deparse
	popa

	mov si,ax
	mov di,.endchar
	call compare
	jc .done

	mov si,bx
	mov di,.outchar
	call compare
	jc .out

	mov si,ax
	mov di,.varchar
	call compare
	jc .tovar

	mov di,.bakchar
	call compare
	jc .tobak

	mov si,bx
	mov di,.inchar
	call compare
	jc .prompt

	mov si,ax
	mov di,.ifchar
	call compare
	jc .if

	mov di,.addchar
	call compare
	jc .add

	mov di,.subchar
	call compare
	jc .sub
	
	mov di,.mulchar
	call compare
	jc .mul

	mov di,.syschar
	call compare
	jc .syscmd

	mov di,.gochar
	call compare
	jc .go
	
	mov di,.eqlchar
	call compare
	jc .varin

	mov di,.filechar
	call compare
	jc .file

	mov di,.filepchar
	call compare
	jc .filep

	mov di,.tagchar
	call compare
	jc .tagcmd

	mov di,color
	call compare
	jc .colorcmd

	mov di,bf
	call compare
	jc .bfcmd

	mov di,.sudochar
	call compare
	jc .sudocmd

	mov di,.cmdbuff
	call getlastchar
	cmp byte[di],'>'
	je .bigout

	mov ax,'er'
	jmp .done	
.end
	jmp .done
.out
	mov si,ax
	mov di,.varchar
	call compare
	jc .varout

	mov si,ax
	mov di,.bakchar
	call compare
	jc .bakout

	mov si,ax
	call print
	call printret
	jmp .done
.bigout
	mov si,.cmdbuff
	call cutend
	call print
	call printret
	jmp .done
.bakout
	mov si,.bak
	call print
	call printret
	jmp .done
.varout
	mov si,.var
	call print
	call printret
	jmp .done
.varin
	mov si,.cmdbuff + 2
	mov di,.var
	call copystring	
	jmp .done
.prompt
	mov si,ax
	call print
	mov di,.var
	call input
	jmp .done
.filep
	pusha
	mov si,bx
	mov di,.varchar
	call compare
	jc .filepvar
	popa
	mov si,bx
	call isfileempty
	jc .ift
	jmp .done
.filepvar
	popa
	mov si,.var
	call isfileempty
	jc .ift
	jmp .done
.if
	mov si,bx
	mov di,.bakchar
	call compare
	jc .ifbak

	mov di,.var
	mov si,bx
	call compare
	jc .ift
	jmp .done
.ifbak
	mov si,.var
	mov di,.bak
	call compare
	jc .ift
	jmp .done
.ift
	mov ax,cx
	mov bx,dx
	jmp .commands
	jmp .done
.add
	mov si,bx
	mov di,.bakchar
	call compare
	jc .addbak

	cmp cx,0	
	jg .add2ints

	mov si,.var
	call toint
	push ax
	
	mov si,bx
	call toint
	mov bx,ax
	pop ax

	add ax, bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.addbak
	mov bx,.var
	mov cx,.bak
.add2ints
	call parse2ints

	add ax,bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.sub
	mov si,bx
	mov di,.bakchar
	call compare
	jc .subbak

	cmp cx,0	
	jg .sub2ints

	mov si,.var
	call toint
	push ax
	
	mov si,bx
	call toint
	mov bx,ax
	pop ax

	sub ax, bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.subbak
	mov bx,.var
	mov cx,.bak
.sub2ints
	call parse2ints

	sub ax,bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.mul
	mov si,bx
	mov di,.bakchar
	call compare
	jc .mulbak

	cmp cx,0	
	jg .mul2ints

	mov si,.var
	call toint
	push ax
	
	mov si,bx
	call toint
	mov bx,ax
	pop ax

	mul bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.mulbak
	mov bx,.var
	mov cx,.bak
.mul2ints
	call parse2ints

	mul bx
	call tostring
	mov si,ax
	mov di,.var
	call copystring
	jmp .done
.syscmd
	pusha
	mov si,bx
	mov di,.varchar
	call compare
	jc .sysvar
	popa

	mov di,bx
	call getthread
	.sysok
	cmp ax,'fl'
	je .syserr
	call coopcall
	jmp .done
.sysvar
	popa
	mov di,.var
	call commands
	jmp .sysok
.syserr
	jmp .done
.go
	pusha
	mov di,.varchar
	mov si,bx
	call compare
	jc .govar
	popa

	mov di,bx
	call runlangfile
	jmp .done
.govar
	popa
	mov si,.var
	mov di,buffer
	call copystring
	mov si,buffer
	call parse
	call langcommand
	jmp .done
.tovar
	mov si,.bak
	mov di,.var
	call copystring
	jmp .done
.tobak
	mov si,.var
	mov di,.bak
	call copystring
	jmp .done
.tagcmd
	pusha
	mov si,.varchar
	mov di,bx
	call compare
	jc .tagvar
	
	mov di,cx
	call compare
	jc .tagsetvar
	popa

	.tagvarok
	mov si,cx
	cmp byte[si], '>'	
	je .tagout

	cmp byte[si],'='
	je .tagtovar

	cmp byte[si],0
	je .tagerr

	pusha
	mov di,bx
	call findtag
	cmp ax,0
	jne .tagp
	popa

	pusha
	mov si,.varchar
	mov di,cx
	call compare
	jc .tagvarout
	popa

	.tagpok
	mov si,bx
	mov di,cx
	call newtag
	jmp .done
.tagsetvar
	popa
	pusha
	mov si,bx
	call findtag
	cmp ax,0
	jne .tagsetvarp
	popa
	.tagsetvarpok
	mov si,bx
	mov di,.var
	call newtag
	jmp .done
.tagsetvarp
	mov di,bx
	call killtag
	popa
	jmp .tagsetvarpok
.tagvarout
	popa
	mov cx,.var
	jmp .tagpok
.tagvar
	popa
	mov bx,.var
	jmp .tagvarok
.tagp
	mov di,bx
	call killtag
	popa
	jmp .tagpok
.tagout
	mov di,bx
	call readtag
	call print
	call printret
	jmp .done
.tagtovar
	mov di,bx
	call readtag
	mov di,.var
	call copystring
	jmp .done
.tagerr
	popa
	jmp .done
.file
	mov si,cx
	mov di,.outchar
	call compare
	jc .fileout

	mov di,.addchar
	call compare
	jc .filein

	mov di,.inchar
	call compare
	jc .filereset

	mov di,.eqlchar
	call compare
	jc .fileset
	jmp .done
.filereset
	push bx
	mov bx,void + 4096
	mov ax,void + 4096 + 512
	call zeroram
	mov si,.var
	mov di,void + 4096
	call copystring
	pop si
	mov bx,void + 4096
	call puthashfile
	jmp .done
.fileset
	pusha
	mov si,bx
	mov bx,void + 4096
	call gethashfile
	popa
	cmp dx,0
	jne .filesetarray

	mov si,void + 4096
	mov di,.var
	call copystring
	jmp .done
.filesetarray
	mov si,dx
	call toint
	mov si,void + 4096
	call getindex
	mov di,.var
	call copystring
	jmp .done
.fileout
	mov si,bx
	call printhashfile
	jmp .done
.filein
	cmp dx,0
	jg .fileinindex

	mov di,bx
	push di
	call findfile
	cmp ax,0
	je .err
	pop di	

	push di
	;Copy String to File
	mov ax,1
	call maloc
	sub ax,1
	mov di,ax
	mov byte[di],0
	add di,1
	mov si,.var
	call copystring

	pop di
	call findfile
	push ax

	;Calc new length
	mov ax,.var
	call length
	mov bx,ax
	add bx,1
	pop ax
	add ax,1
	mov si,ax
	add [si],bx
	mov di,si
	add di,[si]
	mov byte[di],'*'
	jmp .done
.fileinindex
	mov di,bx
	push di
	mov si,dx
	call toint
	pop di	

	call getindex

	push di
	mov ax,dx
	call length
	pop di
	push di
	push ax
	mov ax,.var
	call length
	pop bx
	pop di
	cmp ax,bx
	jg .fileingrow
	jl .fileinshrink
	
	.fileinok
	mov si,.var
	call copystring
	jmp .done
.fileinshrink
	push di
	mov si,di
	add si,bx
	sub si,2
	add di,ax
	mov ax,si
	add ax,1024
	call movemem
	pop di
	jmp .fileinok
.fileingrow
	push di
	mov si,di
	add si,bx
	sub si,2
	add di,ax
	mov ax,1024
	call memcpy
	pop di
	jmp .fileinok
.colorcmd
	mov si,bx
	call toint
	mov byte[colors],al
	call clear
	jmp .done
.bfcmd
	mov si,bx
	call runbffile
	jmp .done
.sudocmd
	mov si,bx
	call sudocmd
	jmp .done
.err
	call err
	mov ax,'er'
	jmp .done
.done
ret
	.outchar db '>',0
	.inchar db '<',0
	.eqlchar db '=',0
	.varchar db 'var',0
	.bakchar db 'bak',0
	.ifchar db 'if',0
	.addchar db '+',0
	.subchar db '-',0
	.mulchar db '*',0
	.syschar db '#',0
	.endchar db 'end',0
	.gochar db 'run',0
	.freechar db 'free',0
	.filechar db 'file',0
	.filepchar db 'file?',0
	.tagchar db 'tag',0
	.loopchar db 'loop',0
	.newchar db 'new',0
	.sudochar db 'asr',0
	.loadchar db 'load',0
	.savechar db 'save',0
	.cmdbuff times 64 db 0
	.var times 64 db 0
	.bak times 64 db 0

parse2ints:
	mov si,bx
	call toint
	push ax

	mov si,cx
	call toint
	mov bx,ax
	pop ax
ret

runlangfile:
	mov bx,void
	mov si,di
	call gethashfile
	mov si,void
.loop	
	push si
	mov ax,si
	call length
	add ax,1
	pop si
	push ax
	push si
	call parse
	call langcommand
	pop si
	pop ax
	add si,ax
	cmp byte[si],0
	je .done
	jmp .loop
.done
ret

incandpad:
	call length
	add di,ax
	mov byte[di],' '
	inc di
ret

deparse:			;IN - di, where to put
	pusha
	cmp ax,0
	je .done
	mov si,ax
	call copystring
	call incandpad

	cmp bx,0
	je .done
	mov si,bx
	call copystring	
	mov ax,bx
	call incandpad

	cmp cx,0
	je .done
	mov si,cx
	call copystring
	mov ax,cx
	call incandpad	

	cmp dx,0
	je .done
	mov si,dx
	call copystring
	mov ax,dx
	call incandpad
.done
	mov byte[di - 1],0
	popa
ret

getlastchar:			;IN - di, string OUT - di, char
.loop
	cmp byte[di],0
	je .done
	inc di
	jmp .loop
.done
	sub di,1
ret

cutend:
	pusha
	call getlastchar
	mov byte[di],0
	popa
ret

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

newtag:				;Make a tag, SI, name, DI, value
	push di
	push si
	mov ax,1
	mov si,[tagmem]
	call malocsmall
	add bx,1
	mov si,bx
	mov cx,'&*'
	mov [si],cx
	pop si
	add bx,2
	mov di,bx
	call copystring
	mov ax,1
	mov si,[tagmem]
	call malocsmall
	mov si,bx
	mov byte[si],0
	pop di
	xchg si,di
	call copystring
ret

findtag:			;Find a tag, DI, name
	mov si,[tagmem]
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

tagpage dw 0
tagmem dw 0

inittags:
	pusha
	call malocbig
	mov [tagmem],ax
	mov [tagpage],bx
	popa
ret