;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;	
;	copyright Sean Haas 2011-14
ORG 100h
jmp short Init
sc1 db 0
Init:
	cli
	mov ax,0
	mov ss,ax
	mov sp,0FFFFh
	sti

	cmp byte[iscrash],1
	je bsod
	mov byte[iscrash],1

	mov si,splash
	call print

	mov si,loadmem
	call print
	mov si,filesend + 1
	mov dx,filesend + 1024
	call memclear
	call genmemtable
	call printok

	mov si,loadmulti
	call print
	mov word[currpid],taskque
	mov ax,0
	call multi
	call initstatestore
	call printok

	mov si,loadintsmsg
	call print
	call loadints
	call printok

	mov si,loadcache
	call print
	call inithcache
	call printok

	mov si,loadshell
	call print
	mov ax,shell
	call schedule
	mov word[shellpid],ax
	call printok

	call inithist

	mov ax,0
	call porton

	call gencmdhashes

        mov si,loading
        call print

	mov dx,5
        call dotdot
	call printret
	call beep
        call clear

        mov si,header
        call print

	mov si,voidat
	call print
	mov ax,void
	call tostring
	mov si,ax
	call print
	call printret
	
	call initgui

	call login
main:			;Main command loop
	call yield
	call sanitycheck
jmp main


getthread:
	mov si,cmdstrings
.loop
	call compare
	jc .found
	add si,8
	cmp byte[si],'*'
	je .err
	jmp .loop
.found
	mov ax,[si + 6]
	jmp .done
.err
	mov ax,'fl'
.done
ret

getthreadhashed:
	mov si,di
	call gethash
	mov si,[gencmdhashes.mem]
.loop
	mov bx,[si]
	mov cx,[si + 2]
	cmp bx,ax
	je .cmdfound
	add si,4
	cmp word[si],'**'
	je .err
	jmp .loop
.cmdfound
	mov ax,[si + 2]
	jmp .done
.err
	mov ax,'fl'
.done
ret

commands:
	call getthread
	cmp ax,'fl'
	je .err
	mov bx,[user]
	cmp bx,'0'
	jne .exclude
	.ok
	call coopcall
	jmp .done
.exclude
	cmp ax,unsecure
	jge .ok
.err
.done
ret

        loading db 13,10,'Loading',0
	loadmem db 'Setting Up Memory Allocater...',0
	loadmulti db 'Setting Up Multi-Threading...',0
	loadintsmsg db 'Loading IDT...',0
	loadcache db 'Building hash cache...',0
	loadshell db 'Spawning Shell Task...',0
        dot db '.',0
	voidat db 13,10,'Void at ',0
        header db ' ____',13,10,'| 00_|_ DreckigOS',13,10,'| 0| 0 | v0.007 Alpha',13,10,'|__|___| 2011-14 Sean Haas',13,10,0
        prompt db '?>',0
        error db 'Error!',13,10,0
	rebootmsg db 'Rebooting...',0
	stack db 'stack',0
	list db 'list',0
	catch db 'catch',0
	lang db 'lang',0
	langprmpt db 'LANG>',0
        offmsg db 13,10,'Computer Halted...',0
	bsodmsg db 13,10,13,10,'          Look what you`ve done :-(',13,10,'          Bang on the keyboard multiple times to walk away',0
	relist db 'relist',0
	color db 'color',0
	kbs db 'kb available',13,10,0 
	tmp db 'tmp',0
	return db '',13,10,0
        press db 13,10,'Press any key to continue...',13,10,0
	statestore dw 0
	shellpid db 0,0
	pidbuff db 0,0
	starttime db 0,0
	page dw 0
	iscrash db 0
	doterm db 0,0
	locked db 0,0
	colors db 02,0,0,0
        user db '0',0,0
	root db '0',0,0
	buffer times 128 db 0
	sc0 db 0

%INCLUDE "usr.asm"
%INCLUDE "task.asm"
%INCLUDE "memc.asm"	
%INCLUDE "term.asm"
%INCLUDE "hash.asm"
;%INCLUDE "bFS.asm"
%INCLUDE "int.asm"
unsecure:
%INCLUDE "shell.asm"
%INCLUDE "dte.asm"
%INCLUDE "lang.asm"
%INCLUDE "crypt.asm"
%INCLUDE "vm.asm"
%INCLUDE "bf.asm"
%INCLUDE "draw.asm"

print:			;Print string
	pusha
	cmp byte[doterm],1
	je .doterm
	mov ah,0Eh	;IN - si, string to print
	mov bl,2
.repeat
        lodsb
        cmp al,0
        je .done
        int 10h
        jmp .repeat
.doterm
	call serialprint
.done
	popa
ret

printcol:
	pusha
	mov si,.col
	call print
	popa
ret
	.col db '   ',0

getinput:
	call print
	call input
ret

dotdot:
	mov cx,0	;Print dots to the screen with a time delay
.loop			;IN - dx, number of dots
        add cx,1
        mov si,dot
        call print
        mov ax,1
        call pause1
        cmp cx,dx
        je .done
        jmp .loop
.done
        ret

printok:
	pusha
	call getcurs
	mov dl,45
	call movecurs
	mov si,.ok
	call print
	popa
ret
	.ok db 'Ok!',13,10,0

input:			;Take keyboard input
        ;cmp byte[doterm],1
	;je .doterm
	xor cl,cl	;IN - di, string to store input in
.loop
        mov ah,0
        int 0x16

        cmp al,0x0D
        je .done

	cmp al,08h
	je .backspace

	cmp ah,1
	je .esc

	mov bl,2
        mov ah,0x0E
        int 10h

        stosb
        inc cl
        jmp .loop
.backspace
	cmp cl,0
	je .loop
	
	dec di
	mov byte [di],0

	mov ah,0Eh
	mov al,08h
	int 10h

	mov al,' '
	int 10h

	mov al,08h
	int 10h
	jmp .loop
.esc
	cmp byte[locked],1
	je .loop
	call printret
	call killque
	mov ax,shell
	call schedule
	jmp main
	jmp .done
.doterm
	call serialinput
.done
        mov al,0
        stosb

        mov ah,0x0E
        mov al,0x0D
        int 0x10
        mov al,0x0A
        int 0x10
	call sanitycheck
ret

printret:
	pusha
	call getcurs
	cmp dl,75
	jge .side
	mov si,return
	call print
	jmp .done
.side
	mov dl,70
	add dh,1
	call movecurs
.done
	popa
ret

waitkey:		;Wait for key press
	pusha		;OUT - ax, key pressed
	mov ax,0
	mov ah,10h
	int 16h
	mov [.tmp],ax
	popa
	mov ax,[.tmp]
ret
	.tmp dw 0

compare:		;Compare two strings
        pusha		;IN di, si, strings to compare
.loop			;OUT - setc carry flag if strings are equal
        mov al,[si]
        mov bl,[di]
        cmp al,bl
        jne .no

        cmp al,0
        je .done

        inc si
        inc di
        jmp .loop
.no
        popa
        clc
        ret
.done
        popa
        stc
ret

clear:			;Clear screen
	pusha
        mov dx,0
        pusha
        mov bh,0
        mov ah,2
        int 10h
        popa

        mov ah,6
        mov al,0
        mov bh,byte[colors]
        mov cx,0
        mov dh,24
        mov dl,79
        int 10h
        popa
	jmp .done
.done
ret

pause1:			;Time delay
        pusha		;IN - ax, time in tenths of a second
        mov bx,ax
        mov cx,1h
        mov dx,86A0h
        mov ax,0
        mov ah,86h
.loop
        int 15h
        dec bx
        jne .loop
        popa
ret

beep:			;Beep
	mov si,.beep
	call print
ret
	.beep db 7,0

length:			;Get string length
        pusha		;IN - ax, string
        mov bx,ax	;OUT - ax, length
        mov cx,0
.loop
        cmp byte [bx],0
        je .done
        inc bx
        inc cx
        jmp .loop
.done
        mov word [.tmp],cx
        popa
        mov ax,[.tmp]
ret
        .tmp dw 0

bcdtoint:			;Convert BCD to int
	pusha			;IN - al, BCD 
	mov bl,al		;OUT - ax, int
	add ax,0Fh
	mov cx,ax
	shr bl,4
	mov al,10
	mul bl
	
	add ax,cx
	mov [.tmp],ax
	popa
	mov ax,[.tmp]
ret
	.tmp dw 0

toint:
        pusha
	mov ax, si			
	call length

	add si, ax		
	dec si

	mov cx, ax		

	mov bx, 0		
	mov ax, 0

	mov word [.multiplier], 1	
.loop:
	mov ax, 0
	mov byte al, [si]		
	sub al, 48			

	mul word [.multiplier]		

	add bx, ax			

	push ax				
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				
	cmp cx, 0
	je .finish
	dec si				
	jmp .loop
.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]

	ret

	.multiplier	dw 0
	.tmp		dw 0

tostring:
        pusha
        mov cx,0
        mov bx,10
        mov di,.t
.push
        mov dx,0
        div bx
        inc cx
        push dx
        test ax,ax
        jnz .push
.pop
        pop dx
        add dl,'0'
        mov [di],dl
	inc di
        dec cx
        jnz .pop

        mov byte [di],0
        popa
        mov ax,.t
ret
        .t times 7 db 0

catchfire:
	mov si,.hcfprmpt
	mov di,buffer
	call getinput
	mov si,buffer
	call toint
	mov bx,ax
	call HCF
ret
	.hcfprmpt db 'Length>',0

sysinfo:
	mov si,.msg1
	call print
	mov si,.msg2
	call print
	mov si,.msg3
	call print
	mov eax,0
	cpuid
	mov [.vinfo],ebx
	mov [.vinfo + 4],edx
	mov [.vinfo + 8],ecx
	mov si,.vinfo
	call print
	call printret
	call getuptime
	call printret
ret
	.msg1 db 'Dreckig OS v0.006',13,10,0
	.msg2 db 'copyright 2011-2012',13,10,0
	.msg3 db 'Sean Haas',13,10,0
	.vinfo times 13 db 0

printhelp:
	mov si,helpstring
	call print
ret

helpstring:
db 'lo - log out, same as quit',13,10
db 'hist - show recent commands entered',13,10
db 'crypt - cryptography manager',13,10
db 'log - lock the computer',13,10
db 'user - manager users',13,10
db 'unm - unmount disk',13,10
db 'clear - clear screen',13,10
db 'dump - show contents of RAM',13,10
db 'kill - end a proccess',13,10
db 'dte - a text editor',13,10
db 'mem - display memory information',13,10
db 'bf - run bf* program',13,10
db 'ps - list proccesses',13,10
db 're - reboot',13,10
db 0

printint:
	pusha
	call tostring
	mov si,ax
	call print
	popa
ret

getuptime:
	call getpit
	mov bx,[starttime]
	xchg bx,ax
	sub ax,bx
	call tostring
	mov si,ax
	call print
ret

getdtime:
	call gettime
	mov ax,[gettime.time]
	call printint
	mov ax,[gettime.time + 2]
	call printint
	call printret
ret

gettime:
	pusha
	xor ax,ax
	int 1Ah
	mov [.time],cx
	mov [.time + 2],dx
	popa
ret
	.time times 5 db 0

getdate:
	pusha
	mov ah,04h
	int 1Ah
	mov [.date],cx
	mov [.date + 2],dx
	popa
ret
	.date times 5 db 0

getdump:
	mov bx,0
.repeat
	mov ah,0Eh
        lodsb
        cmp bx,512
        je .done
        int 10h
        add bx,1
        jmp .repeat
.done	
ret

getmem:
	pusha
	mov al,18h
	out 70h,al
	in al,71h
	mov ah,al
	mov al,17h
	out 70h,al
	in al,71h
	add ax,1024
	call tostring
	mov si,ax
	call print
	mov si,.open
	call print
	popa

	call getused
	call tostring
	mov si,ax
	call print
	mov si,.used
	call print
ret
	.open db ' kbs available',13,10,0
	.used db ' kbs used',13,10,0

getips:
	cli
	mov al,00000000b
	out 43h,al
	in al,40h	
	mov ah,al
	in al,40h
	rol ax,8
	sti
	push ax
	mov ax,0
.loop
	cmp ax,9C4h
	jge .done
	add ax,1
	mov bx,ax
	mov bx,ax
	mov bx,ax
	mov bx,ax
jmp .loop
.done
	cli
	mov al,00000000b
	out 43h,al
	in al,40h	
	mov ah,al
	in al,40h
	rol ax,8
	sti
	mov bx,ax
	pop ax
	sub ax,bx
	mov bx,ax
ret

getregs:
	pusha
	push si
	
	mov si,.ax
	call print
	call tostring
	mov si,ax
	call print

	mov si,.bx
	call print
	mov ax,bx
	call tostring
	mov si,ax
	call print

	mov si,.cx
	call print
	mov ax,cx
	call tostring
	mov si,ax
	call print

	mov si,.dx
	call print
	mov ax,dx
	call tostring
	mov si,ax
	call print
	call printret

	mov si,.si
	call print
	pop si
	mov ax,si
	call tostring
	mov si,ax
	call print

	mov si,.di
	call print
	mov ax,di
	call tostring
	mov si,ax
	call print
	call printret
	popa
ret
	.ax db '     ax ',0
	.bx db '     bx ',0
	.cx db '     cx ',0
	.dx db '     dx ',0
	.si db '     si ',0
	.di db '     di ',0

swapit:
	mov ax,[page]
	cmp ax,0
	je .two
	
	mov ax,0
	call multi
	mov ah,05h
	mov al,0
	int 10h
	mov ax,0
	jmp .done
	
.two
	mov ax,1
	call multi
	mov ah,05h
	mov al,1
	int 10h
	mov ax,1
	
	.done
	mov [page],ax
ret

multi:
	cmp ax,0
	je .cpu0

	cmp ax,1
	je .cpu1
	
.cpu0
	mov [.ax1],ax
	mov [.bx1],bx
	mov [.cx1],cx
	mov [.dx1],dx
	mov [.si1],si
	mov [.di1],di

	mov ax,[.ax0]
	mov bx,[.bx0]
	mov cx,[.cx0]	
	mov dx,[.dx0]
	mov si,[.si0]
	mov di,[.di0]
jmp .done

.cpu1
	mov [.ax0],ax
	mov [.bx0],bx
	mov [.cx0],cx
	mov [.dx0],dx
	mov [.si0],si
	mov [.di0],di

	mov ax,[.ax1]
	mov bx,[.bx1]
	mov cx,[.cx1]	
	mov dx,[.dx1]
	mov si,[.si1]
	mov di,[.di1]
jmp .done
.done
ret
	.ax0 dw 0
	.bx0 dw 0
	.cx0 dw 0
	.dx0 dw 0
	.si0 dw 0
	.di0 dw 0
	.ax1 dw 0
	.bx1 dw 0
	.cx1 dw 0
	.dx1 dw 0
	.si1 dw 0
	.di1 dw 0

locmd:
	call killque
	mov ax,[histpage]
	call freebig
	mov ax,[tagpage]
	call freebig
	call writecache
	call clearcache
	mov byte[crypton],0
	mov ax,'0'
	mov [user],ax
	mov [root],ax
	call login
	mov ax,shell
	call schedule
	jmp main
ret

logit:
	mov byte[locked],1
	
	mov si,.pass
	mov di,.secret
	call getinput

	mov ah,05
	mov al,3
	int 10h
	call clear
.loop
	mov si,.pass
	mov di,buffer
	call getinput
	mov si,.secret
	mov di,buffer
	call compare
	jc .done
	jmp .loop		
	jmp .done
.done
	call clear
.exit
	mov byte[locked],0
ret
	.pass db 'PASS>',0
	.secret times 8 db 0

err:
	push si
	mov si,error
	call print
	pop si
ret

sanitycheck:
	cmp byte[sc0],0
	jne .err
	cmp byte[sc1],0
	jne .err
	jmp .done
.err
	call scfail
.done
ret

scfail:
	mov byte[colors],23
	call clear
	mov si,.msg
	call print
	call waitkey
	call reboot1
ret
	.msg db 'A sanity chack has failed most likely due to a buffer overflow',13,10,'Press any key to reboot...',13,10,0

bsod:
	pusha
	mov byte[colors],17h
	call clear

	mov si,bsodmsg
	call print
	call printret
	popa
	call getregs
	call printret
	call printret
	call printstack
	call tasklist
	xor cx,cx
	xor ax,ax
.loop
	push cx
	int 16h
	pop cx
	add cx,1
	cmp cx,15
	jge .done
	jmp .loop
.done
	call killque

	cli
	mov ax,0
	mov ss,ax
	mov sp,0FFFFh
	sti

	mov ax,shell
	call schedule
	call main
ret
	.wl db '          Writting crash log...',0

reboot1:
	mov si,rebootmsg
	call print
	mov dx,5
        call dotdot
	call clear
        mov ax,0
        int 0x19
ret

cpuoff:
        mov si,offmsg
        call print
.loop
	hlt
	jmp .loop
	jmp $

kernend db 13,10,'Dreckig Kernel End',13,10,0
void db 0,0,'Void Start',0,0
times 5 db '0'
filesend
%INCLUDE "splash.asm"
