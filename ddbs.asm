ddbsmd:
ret

newtable:			;DI - DB name, SI - Table Name, BX - Table specs
	pusha
	mov bx,void
	mov si,di
	call gethashfile
	popa

	
ret