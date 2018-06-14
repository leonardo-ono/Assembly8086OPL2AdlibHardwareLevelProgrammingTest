; OPL2 hardware level programming test in Assembly 8086
;
; Playing Super Mario Bros music using 2 channels on OPL2 (Adlib/Sound Blaster)
;
; Written by Leonardo Ono (ono.leo@gmail.com)
; 13/06/2018
; Target OS: DOS 
; Executable extension: *.COM
; use: nasm mario.asm -o mario.com -f bin

	bits 16
	org 100h

section .text

	start: ; entry point
			call reset_all_registers

			mov cl, 0 ; channel 0
			call setup_piano_instrument
			mov cl, 1 ; channel 1
			call setup_piano_instrument

			call start_fast_clock
			call play_mario
			call stop_fast_clock

			call reset_all_registers

			; return to DOS
			mov ah, 4ch
			int 21h
		
	play_mario:
			mov di, 0
			
		.next_note:
			; channel 0
			; di = index
			; cl = channel
			; bx = channel music data
			mov cl, 0
			mov bx, mario_music_0
			call play_channel_note
	
			; channel 1
			; di = index
			; cl = channel
			; bx = channel music data
			mov cl, 1
			mov bx, mario_music_1
			call play_channel_note
		
		.delay:
			call get_current_time
			cmp eax, [last_time]
			jbe .delay
			mov [last_time], eax
		
			inc di
			cmp di, [mario_music_size]
			jb .next_note
		.end:
			ret

	; di = index
	; cl = channel
	; bx = channel music data
	play_channel_note:
			push di
			add di, bx
			mov bh, 0
			mov bl, [di]
			pop di

			; print note char in the screen
			mov ah, 0eh
			mov al, bl
			int 10h

			cmp bl, 255 ; ignore
			jz .ignore
			cmp bl, 254 ; note off
			jz .note_off
			
		.play_midi_note:
			mov si, bx ; si = midi note
			; mov cl, 0 ; cl = channel
			call note_on
			jmp .ignore
			
		.note_off:
			;mov cl, 0 ; cl = channel
			call note_off
		.ignore:
			ret
			
	; si = midi note
	; cl = channel
	note_on:
			shl si, 1
			mov ax, [midi_note_to_freq_table + si]
						
			mov bl, 0a0h ; register
			add bl, cl
			mov bh, al ; value
			call write_adlib

			mov bl, 0b0h ; register
			add bl, cl
			mov bh, 34h ; value
			or bh, ah
			call write_adlib

			ret

	; cl = channel
	note_off:
			mov bl, 0b0h ; register
			add bl, cl
			mov bh, 0h ; value
			call write_adlib
			ret

	; cl = channel
	setup_piano_instrument:
			mov si, 0
		.next_register:
			mov bl, [instr_registers + si] ; register
			add bl, cl
			mov bh, [piano_instr + si] ; value
			call write_adlib
			inc si
			cmp si, [instr_registers_count]
			jb .next_register
		.end:
			ret

	reset_all_registers:
			mov bl, 0h
			mov bh, 0
		.next_register:
			; bl = register
			; bh = value
			call write_adlib
			inc bl
			cmp bl, 0f5h
			jbe .next_register
		.end:
			ret

	; bl = register
	; bh = value
	write_adlib:
			pusha
			
			mov dx, 388h
			mov al, bl
			out dx, al

			; call delay

			mov dx, 389h

			mov cx, 6
		.delay_1:
			in al, dx
			loop .delay_1

			mov al, bh
			out dx, al

			mov cx, 35
		.delay_2:
			in al, dx
			loop .delay_2
			
			popa
			ret
	
	; count = 1193180 / sampling_rate
	; sampling_rate = 25 cycles per second
	; count = 1193180 / 25 = ba6f (in hex) 
	start_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 6fh ; low 
			out 40h, al
			mov al, 0bah ; high
			out 40h, al
			sti
			ret

	stop_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 0h ; low 
			out 40h, al
			mov al, 0h ; high
			out 40h, al
			sti
			ret
			
	; eax = get current time
	get_current_time:
			push es
			mov ax, 0
			mov es, ax
			mov eax, [es:46ch]
			pop es
			ret

segment .data

	last_time dd 0

	instr_registers_count	dw 11
	instr_registers			db 020h, 040h, 060h, 080h, 0e0h, 0c0h, 023h, 043h, 063h, 083h, 0e3h
	piano_instr					db 033h, 05ah, 0b2h, 050h, 000h, 000h, 031h, 000h, 0b1h, 0f5h, 000h

	midi_note_to_freq_table:
				db 005h, 000h, 005h, 000h, 006h, 000h, 006h, 000h, 006h, 000h, 007h, 000h, 007h, 000h, 008h, 000h
				db 008h, 000h, 009h, 000h, 009h, 000h, 00ah, 000h, 00ah, 000h, 00bh, 000h, 00ch, 000h, 00ch, 000h
				db 00dh, 000h, 00eh, 000h, 00fh, 000h, 010h, 000h, 011h, 000h, 012h, 000h, 013h, 000h, 014h, 000h
				db 015h, 000h, 016h, 000h, 018h, 000h, 019h, 000h, 01bh, 000h, 01ch, 000h, 01eh, 000h, 020h, 000h
				db 022h, 000h, 024h, 000h, 026h, 000h, 028h, 000h, 02bh, 000h, 02dh, 000h, 030h, 000h, 033h, 000h
				db 036h, 000h, 039h, 000h, 03ch, 000h, 040h, 000h, 044h, 000h, 048h, 000h, 04ch, 000h, 051h, 000h
				db 056h, 000h, 05bh, 000h, 060h, 000h, 066h, 000h, 06ch, 000h, 073h, 000h, 079h, 000h, 081h, 000h
				db 088h, 000h, 091h, 000h, 099h, 000h, 0a2h, 000h, 0ach, 000h, 0b6h, 000h, 0c1h, 000h, 0cdh, 000h
				db 0d9h, 000h, 0e6h, 000h, 0f3h, 000h, 002h, 001h, 011h, 001h, 022h, 001h, 033h, 001h, 045h, 001h
				db 058h, 001h, 06dh, 001h, 083h, 001h, 09ah, 001h, 0b2h, 001h, 0cch, 001h, 0e7h, 001h, 004h, 002h
				db 023h, 002h, 044h, 002h, 066h, 002h, 08bh, 002h, 0b1h, 002h, 0dah, 002h, 006h, 003h, 034h, 003h
				db 065h, 003h, 098h, 003h, 0cfh, 003h, 009h, 004h, 046h, 004h, 088h, 004h, 0cdh, 004h, 016h, 005h
				db 063h, 005h, 0b5h, 005h, 00ch, 006h, 068h, 006h, 0cah, 006h, 031h, 007h, 09eh, 007h, 012h, 008h
				db 08dh, 008h, 010h, 009h, 09ah, 009h, 02ch, 00ah, 0c7h, 00ah, 06bh, 00bh, 018h, 00ch, 0d1h, 00ch
				db 094h, 00dh, 062h, 00eh, 03dh, 00fh, 025h, 010h, 01bh, 011h, 020h, 012h, 034h, 013h, 058h, 014h
				db 08eh, 015h, 0d6h, 016h, 031h, 018h, 0a2h, 019h, 028h, 01bh, 0c5h, 01ch, 07bh, 01eh, 04bh, 020h


	mario_music_size dw 1779
	
	; 0~127 -> midi note
	; 254   -> note off
	; 255   -> ignore
	
	; channel 0
	mario_music_0:
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 046h, 0ffh, 0feh, 045h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 047h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 046h, 0ffh, 0feh, 045h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 047h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 044h, 0ffh, 0feh, 045h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 048h
			db 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 054h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 054h, 0ffh, 0feh, 054h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 044h, 0ffh, 0feh, 045h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 048h
			db 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04bh, 0ffh, 0feh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 044h, 0ffh, 0feh, 045h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 048h
			db 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 054h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 054h, 0ffh, 0feh, 054h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04eh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 04bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 044h, 0ffh, 0feh, 045h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 048h
			db 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04bh, 0ffh, 0feh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 046h, 0ffh, 0feh, 045h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 047h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 046h, 0ffh, 0feh, 045h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 047h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh, 0ffh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04ah, 0ffh, 0feh, 0ffh, 048h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh, 0ffh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04ah, 0ffh, 0feh, 0ffh, 048h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 048h, 0ffh, 0feh, 04ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh, 0ffh, 051h, 0ffh, 0feh
			db 0ffh, 051h, 0ffh, 0feh, 0ffh, 04fh, 0ffh, 0feh, 0ffh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh
			db 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh, 043h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 04ch, 0ffh, 0feh, 048h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 044h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 045h, 0ffh, 0feh
			db 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh, 0feh, 045h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 047h, 0ffh, 0feh, 04dh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04dh, 0ffh
			db 0feh, 04dh, 0ffh, 0feh, 0ffh, 04ch, 0ffh, 0feh, 0ffh, 04ah, 0ffh, 0feh, 0ffh, 048h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh

	; channel 1
	mario_music_1:
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 036h, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 034h, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 040h, 0ffh, 0feh
			db 0ffh, 041h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03eh, 0ffh, 0feh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 039h, 0ffh, 0feh, 03bh, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 036h, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 034h, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 040h, 0ffh, 0feh
			db 0ffh, 041h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03eh, 0ffh, 0feh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 039h, 0ffh, 0feh, 03bh, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 03ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 04fh, 0ffh, 0feh, 04fh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 03ah, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 036h, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 034h, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 040h, 0ffh, 0feh
			db 0ffh, 041h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03eh, 0ffh, 0feh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 039h, 0ffh, 0feh, 03bh, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 034h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 036h, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 034h, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 040h, 0ffh, 0feh
			db 0ffh, 041h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03eh, 0ffh, 0feh, 040h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh
			db 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 039h, 0ffh, 0feh, 03bh, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 035h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 037h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 039h, 0ffh, 0feh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 035h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 037h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 039h, 0ffh, 0feh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 02ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 033h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 038h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 02bh
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh
			db 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 043h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 032h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 035h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 037h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 036h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 035h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 03ch, 0ffh, 0feh, 03ch, 0ffh, 0feh, 035h
			db 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 037h, 0ffh
			db 0feh, 037h, 0ffh, 0feh, 0ffh, 039h, 0ffh, 0feh, 0ffh, 03bh, 0ffh, 0feh, 0ffh, 03ch, 0ffh, 0feh
			db 0ffh, 0ffh, 0ffh, 037h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 030h, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh
			db 0ffh, 0ffh, 0ffh	

