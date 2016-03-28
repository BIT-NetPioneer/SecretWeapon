com1k equ 3fbh
data segment
p1 db"system ready!$"
p3 db"communication error!$"
recrow db 2;���չ��������
reccol db 0;���չ��������
sndRowNo db 10;���͹��������
sndClmNo db 0;���͹��������
data ends
code segment
assume cs:code,ds:data
main proc far
start:	push ds
		xor ax,ax
		push ax
		mov ax,data
		mov ds,ax
     ;������Ҫ�Լ�д������1==========================
	 ;дLCR
        mov dx, 3fbh
		mov al, 80h;DLAB=1
		out dx, al
     ;д��Ƶϵ�������ò�����Ϊ9600bps�����ݲ���������Ϊ64����ķ�Ƶϵ��Ϊ3
		mov dx, 3f8h;DLL��I��ַ 
		mov al, 3H;��Ƶϵ�����ֽ�
		out dx, al;д��DLL
		mov dx, 3f9h;DLM�ĵ�ַ
		mov al, 0;��Ƶϵ�����ֽ�
		out dx, al;д��DLM
		
		mov dx, 3fbh;LCR�ĵ�ַ 
	;����Ҫ����7λ����λ��1λֹͣλ������ʹ��żУ�飬ͬʱΪDLλ��д0��������Ҫ��LCRд��00011010b=1AH
		mov al, 1ah
		out dx, al;DL�����3F8H��Ӧ��THR/RBR��3F9H��Ӧ��IER

     ;��FIFO������������λ����������λ�Ŀ�����Ϊ07H
		mov dx, 3fah
		mov al, 07h
		out dx, al
     ;1============================================
		mov dx,3fch
		mov al,03h
		out dx,al
		mov dx,3f9h
		mov al,0
		out dx,al
     
		call back
		mov dx,offset p1
		mov ah,9
		int 21h
;������Ҫ�Լ�д������2====================
;���Ͳ���
;��������״̬�ж�
send:
		mov dx, 3fdh;��ȡLSR
		in al, dx
		test al, 9eh;������:ʹ��10011110B����ĸ�����FIFO����֡��ʽ������żУ�����͸��Ǵ���
		jnz errorJmp;����ʱ����ת��������ֱ����תʱ����Jump out of range���󣬹ʽ��й�����ת
		test al, 01h;�����ջ���Ĵ������Ƿ������ݣ�������LSR��DRλ�Ƿ�Ϊ1
		jnz receive;�üĴ���������������н��մ���
		test al, 20h;��鷢�ͱ��ּĴ����Ƿ�Ϊ�գ�������LSR��THREλ�Ƿ�Ϊ1
		jz send;�Ĵ���������δ��ȡ�ߣ����ܷ������ݣ�����send������ѯ
;���ͱ��ּĴ���Ϊ�գ����Է������ݣ�����Ϊ�������ݲ���
;�Ӽ��̶���Ҫ���͵��ַ�
		mov ah, 0bh;ʹ��21��DOS�ж�0bh���ܣ�����Ƿ��м�������
		int 21h
		cmp al, 0;�������룬�����al��
		jz send;���ַ����룬����send������ѯ
	
;���÷����ַ����ֵĹ�����к�
		mov dh, sndRowNo
		mov dl, sndClmNo
		mov bh, 0
		mov ah, 2
		int 10h
;16��BIOS�ж�0�Ź��ܣ������Ե��ַ�����
		mov ah, 0
		int 16h
		
		cmp al, 0dh;��Ϊ�س���������+1��������0
		jz sndRowNoInc
;���ǻس�����������+1���������������ֵʱ����������λ
		inc dx
		jmp saveSndPos
sndRowNoInc:
		inc dh
		mov dl, 0
saveSndPos:
		mov sndRowNo, dh
		mov sndClmNo, dl
;����������
		mov dx, 3f8h
		out dx, al
;2==========================================
        cmp al,'*';�����롰*����ʱ�˳�
        jz stop
        mov bx,7
        mov ah,14
        int 10h
	
jmp send;���������ݷ���send��������ѯRBR��THR
errorJmp:
	jmp error
;�������Լ�д������3=======================
;���ղ���
;��������״̬�ж�
;����״̬�ж�
;�ڴ�send��ѭ������receive֮ǰ�Ѿ����н���״̬�жϺͳ����⣬�˴���������ַ����߼�����
receive:
		mov dx, 3f8h;�����ջ���Ĵ���
		in al, dx
		and al, 7fh;����7λ����λ�����ȡ��7λ
	
;���ý����ַ����ֵĹ�����к�
		mov dh, recrow
		mov dl, reccol
		mov bh, 0
		mov ah, 2
		int 10h
;��ʾ�ַ�
		cmp al, 0dh;����ǻس�������ʾ�ַ�
		jz setPos
		cmp al, 0ah;����ǻ��У�����ʾ�ַ�
		jz setPos
;�ǻس��ͻ��з��������ʾ
		mov ah, 0ah
		mov bh, 0
		mov bl, 0
		mov cx, 1
		int 10h
setPos:
;���յ��س����з�ʱ�������ý����ַ����ֵĹ�����к�
		cmp al, 0dh;��Ϊ�س�����������+1��������0
		jz rcvRowNoInc
		;���ǻس�����������+1���������������ֵʱ����������λ
		inc dx
		jmp saveRcvPos
rcvRowNoInc:
		inc dh
		mov dl, 0
saveRcvPos:
		mov recrow, dh
		mov reccol, dl
;3=======================================
        cmp al,'*'
        jz stop
        mov bx,7
        mov ah,14
        int 10h
        jmp send

error:	call back
   ;���ý��չ�����к�
		mov dh, recrow
		mov dl, reccol
		mov bh, 0
		mov ah, 2
		int 10h
	    ;��ʾ������Ϣ
        mov dx,offset p3
        mov ah,9
        int 21h
	;�������ý��չ�����кţ�����+1��������0
		inc dh
		mov dl, 0
		mov recrow, dh
		mov reccol, dl
        jmp send
stop:ret
main endp

back proc near
        push ax
        push dx
        mov dl,0dh
        mov ah,2
        int 21h
        mov dl,0ah
        mov ah,2
        int 21h
        pop dx
        pop ax
        ret
back endp
code ends
end start
