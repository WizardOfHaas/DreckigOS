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
;	copyright Sean Haas 2011-12
ORG 100h

JMP SHORT Init
db 0
Init:
	cli
	mov ax,0
	mov ss,ax
	mov sp,0FFFFh
	sti

	cmp byte[iscrash],1
	je bsod
	mov byte[iscrash],1

	mov ah,00h
	mov al,03h
	int 10h

	mov si,splash
	call print
	
	mov si,loadmem
	call print
	mov si,filesend + 1
	mov dx,filesend + 1024
	call memclear

	mov si,loadmulti
	call print
	mov word[currpid],taskque
	mov ax,0
	call multi
	mov ax,shell
	call schedule
	mov word[shellpid],ax

	mov si,loaddir
	call print
	call loadrootdir

	call getpit
	mov [starttime],ax

	mov byte[colors + 2],2

	mov ax,0
	call porton

        mov si,loading
        call print

	mov dx,5
        call dotdot
	call printret
	call beep
        call clear

        mov si,header
        call print

	mov si,ips
	call print
	call getips
	mov ax,bx
	call tostring
	mov si,ax
	call print
	mov si,ipsticks
	call print

	mov si,voidat
	call print
	mov ax,void
	call tostring
	mov si,ax
	call print
	call printret

	call loadints
main:			;Main command loop
	call yield
jmp main

getthread:		;Turns command into memory location
	mov si,help	;IN - di, string to interpret
	call compare
	jc .helpcmd

	mov si,reboot
	call compare
	jc .rebootcmd

	mov si,time
	call compare
	jc .timecmd

        mov si,info
        call compare
        jc .infocmd

        mov si,off
        call compare
        jc .offcmd

        mov si,cls
        call compare
        jc .clear

        mov si,dump
        call compare
        jc .dumpcmd

	mov si,crash
	call compare
	jc .crashcmd

	mov si,swap
	call compare
	jc .swapcmd

	mov si,mem
	call compare
	jc .memcmd

	mov si,regs
	call compare
	jc .regscmd

	mov si,lang
	call compare
	jc .langcmd

	mov si,task
	call compare
	jc .taskcmd

	mov si,catch
	call compare
	jc .catchcmd

	mov si,date
	call compare
	jc .datecmd

	mov si,stack
	call compare
	jc .stackcmd

	mov si,dte
	call compare
	jc .dtecmd

	mov si,log
	call compare
	jc .logcmd

	mov si,file
	call compare
	jc .filecmd

	mov si,list
	call compare
	jc .listcmd

	mov si,ps
	call compare
	jc .pscmd

	mov si,relist
	call compare
	jc .relist

	mov si,term
	call compare
	jc .termcmd

	mov si,ws
	call compare
	jc .wscmd

 	mov si,quit
	call compare
	jc .quitcmd

	.err
        mov ax,'fl'
	
        jmp .done

.helpcmd
        mov ax,printhelp
        jmp .done
.rebootcmd
	call reboot1
.timecmd
	mov ax,gettime
	jmp .done
.infocmd
	mov ax,sysinfo
        jmp .done
.offcmd
        call cpuoff
.logcmd
        mov ax,logit
        jmp .done
.clear
        mov ax,clear
        jmp .done
.dumpcmd
        mov ax,memdump
        jmp .done
.crashcmd
	jmp Init
.swapcmd
	mov ax,swapit
	jmp .done
.memcmd
	mov ax,getmem
	jmp .done
.regscmd
	mov ax,getregs
	jmp .done
.langcmd
	mov ax,dreklang
	jmp .done
.taskcmd
	mov ax,taskman
	jmp .done
.catchcmd
	mov ax,catchfire
	jmp .done
.datecmd
	mov ax,getdate
	jmp .done
.stackcmd
	call printstack
	jmp .done
.dtecmd
	mov ax,textedit
	jmp .done
.filecmd
	mov ax,fileman
	jmp .done
.listcmd
	mov ax,filelist
	jmp .done
.pscmd
	mov ax,tasklist
	jmp .done
.relist
	mov ax,resetvfs
	jmp .done
.termcmd
	mov ax,swapterm
	jmp .done
.wscmd
	call guishell
	jmp .done
.quitcmd
	mov byte[shellwin.quit],1
.done
ret

commands:
	call getthread
	cmp ax,'fl'
	je .err
	call coopcall
.err
ret

        loading db 13,10,'Loading',0
	loadmem db 'Setting Up Memory Allocater...',13,10,0
	loadmulti db 'Setting Up Multi-Threading...',13,10,0
	loadstack db 'Setting Up Stack...',13,10,0
	loaddir db 'Loading root directory...',13,10,0
        dot db '.',0
	voidat db 13,10,'Void at ',0
	ips db '1m instructions in ',0
	ipsticks db ' ticks',0
	help db 'help',0
        header db ' ____',13,10,'| 00_|_ DreckigOS',13,10,'| 0| 0 | v0.006 Alpha',13,10,'|__|___| 2011-12 Sean Haas',13,10,0
        prompt db '?>',0
        error db 'Error!',13,10,0
        reboot db 'reboot',0
	rebootmsg db 'Rebooting...',0
	stack db 'stack',0
	date db 'date',0
	list db 'list',0
	catch db 'catch',0
	regs db 'regs',0
	file db 'file',0
	log db 'log',0
	lang db 'lang',0
	ws db 'ws',0
	langprmpt db 'LANG>',0
	quit db 'quit',0
	time db 'time',0
        info db 'info',0
        off db 'off',0
        offmsg db 13,10,'Computer Halted...',0
        cls db 'clear',0
	ps db 'ps',0
        dump db 'dump',0
	crash db 'crash',0
	bsodmsg db 13,10,13,10,'          Look what you`ve done :-(',13,10,'          Bang on the keyboard multiple times to walk away',0
	task db 'task',0
	swap db 'swap',0
	dte db 'dte',0
	mem db 'mem',0
	term db 'term',0
	relist db 'relist',0
	color db 'color',0
	kbs db 'kb',13,10,0 
	tmp db 'tmp',0
	return db '',13,10,0
        press db 13,10,'Press any key to continue...',13,10,0
	shellpid db 0,0
	pidbuff db 0,0
	starttime db 0,0
	gui db 0
	page dw 0
	iscrash db 0
	doterm db 0,0
	locked db 0,0
	colors db 02,0,0,0
        buffer times 128 db 0

%INCLUDE "lang.asm"
%INCLUDE "task.asm"
%INCLUDE "memc.asm"	
%INCLUDE "file.asm"
%INCLUDE "dte.asm"
%INCLUDE "term.asm"
%INCLUDE "bFS.asm"
%INCLUDE "int.asm"
%INCLUDE "shell.asm"

print:			;Print string
	pusha
	cmp byte[doterm],1
	je .doterm
	cmp byte[gui],1
	je .guiprint
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
	jmp .done
.guiprint
	call guiprint
.done
	popa
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
	cmp byte[gui],1
	je .gui
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
.gui
	pusha
	call getcurs
	cmp dl,31
	je .wrap
	cmp dh,23
	je .scroll
	popa
	jmp .loop
.wrap
	popa
	call wrapshell
	jmp .loop
.scroll
	popa
	call scrollshell
	jmp .loop
.esc
	cmp byte[locked],1
	je .loop
	call printret
	call main
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
ret

printret:
	pusha
	cmp byte[gui],1
	je .gui
	mov si,return
	call print
	jmp .done
.gui
	call guiprintret
.done
	popa
ret

guiprintret:
	call getcurs
	add dh,1
	mov dl,byte[guiprint.x]
	call movecurs
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
	cmp byte[gui],1
	je .gui
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
.gui
	call guiclear
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

memdump:
	mov si,.bott
	call print
	mov di,buffer
	call input
	
	mov si,buffer
	mov di,.void
	call compare
	jc .dumpvoid

	mov si,buffer
	call toint
	mov si,ax
	call getdump
	jmp .done
.dumpvoid
	mov si,void
	call getdump
.done
	call printret
ret
	.bott db 'Bottom>',0
	.void db 'void',0

catchfire:
	mov si,.hcfprmpt
	call print
	mov di,buffer
	call input
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
	mov si,.hlp1
	call print
	mov si,.hlp2
	call print
	mov si,.hlp3
	call print
	mov si,.hlp4
	call print
	mov si,.hlp5
	call print
	mov si,.hlp6
	call print
	mov si,.hlp7
	call print
	mov si,.hlp8
	call print
	mov si,.hlp9
	call print
	mov si,.hlp12
	call print
	mov si,.hlp13
	call print
ret
	.hlp1 db 'help - print help message',13,10,0
	.hlp2 db 'stack - print stack',13,10,0
	.hlp3 db 'file - file manager',13,10,0
	.hlp4 db 'dte - text editor',13,10,0
	.hlp5 db 'regs - print registers',13,10,0
	.hlp6 db 'mem - display memory in kbs',13,10,0
	.hlp7 db 'swap - switch between tasks',13,10,0
	.hlp8 db 'clear - clear screen',13,10,0
	.hlp9 db 'ps - list running tasks',13,10,0
	.hlp12 db 'reboot - reboot computer',13,10,0
	.hlp13 db 'log - lock computer',13,10,0

getuptime:
	call getpit
	mov bx,[starttime]
	xchg bx,ax
	sub ax,bx
	call tostring
	mov si,ax
	call print
ret

gettime:
	mov ax,0
	mov al,04h		;Hour
	out 70h,al
	in al,71h
	mov ah,0
	call bcdtoint
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print
	
	mov ax,0
	mov al,02h		;Minute
	out 70h,al
	in al,71h
	mov ah,0
	call bcdtoint
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print

	mov ax,0		;Second
	mov al,00
	out 70h,al
	in al,71h
	mov ah,0
	call bcdtoint
	call tostring
	mov si,ax
	call print

	call printret
ret
	.space db ':',0

getdate:
	mov ax,0		;Day
	mov al,7h
	out 70h,al
	in al,71h
	call bcdtoint
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print
		
	mov ax,0		;Month
	mov al,8h
	out 70h,al
	in al,71h
	call bcdtoint
	call tostring
	mov si,ax
	call print
	mov si,.space
	call print

	mov ax,0		;Year
	mov al,9h
	out 70h,al
	in al,71h
	call bcdtoint
	call tostring
	mov si,ax
	call print
	call printret
ret
	.space db ',',0

getdump:
	mov bx,0
.repeat
	mov ah,0Eh
        lodsb
        cmp bx,512
        je .done
        int 10h
        add bx,1
        cmp cx,5
        je .done
        jmp .repeat
.done	
ret

getmem:
	pusha
	call printret
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
	mov si,kbs
	call print
	popa
ret

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

taskman:
	call gotask
ret	

logit:
	mov byte[locked],1
	
	mov si,.pass
	call print
	mov di,.secret
	call input

	mov ah,05
	mov al,3
	int 10h
	call clear
.loop
	mov si,.pass
	call print
	mov di,buffer
	call input
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
	pusha
	mov si,error
	call print
	popa
ret

bsod:
	pusha
	mov ah,05h
	mov al,0
	int 10h
	mov dx,0
	mov bh,0
	mov ah,2h
	int 10h
	mov cx,2000
	mov bh,0
	mov bl,17h
	mov al,20h
	mov ah,9h
	int 10h

	mov si,bsodmsg
	call print
	call printret
	popa
	call getregs
	call printret
	call printret
	call printstack
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
	call main
	int 19h
ret

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
%INCLUDE "files.asm"
filesend
%INCLUDE "splash.asm"