.section .data
#ifndef TEST
#define TEST 20
#endif

				.macro linea
	#if TEST==1								
						.int 1,2,1,2
#elif TEST==2
						.int -1,-2,-1,-2
#elif TEST==3			
						.int 0x7FFFFFFF,0x7FFFFFFF,0x7FFFFFFF,0x7FFFFFFF
#elif TEST==4
						.int 0x80000000,0x80000000,0x80000000,0x80000000
#elif TEST==5 			
						.int 0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF
#elif TEST==6				
						.int 2000000000,2000000000,2000000000,2000000000
#elif TEST==7				
						.int 3000000000,3000000000,3000000000,3000000000
#elif TEST==8
						.int -2000000000,-2000000000,-2000000000,-2000000000
#elif TEST==9
						.int -3000000000,-3000000000,-3000000000,-3000000000
#elif TEST>=10 && TEST<=14
						.int 1,1,1,1
#elif TEST>=15 && TEST<=19
						.int -1,-1,-1,-1
#else
			.error "Definir TEST entre 1...19"
#endif
			.endm

			.macro linea0
	#if TEST>=1 && TEST<=9
						linea
#elif TEST==10
						.int 0,2,1,1
#elif TEST==11
						.int 1,2,1,1
#elif TEST==12 
						.int 8,2,1,1
#elif TEST==13
						.int 15,2,1,1
#elif TEST==14
						.int 16,2,1,1
#elif TEST==15
						.int 0,-2,-1,-1
#elif TEST==16
						.int -1,-2,-1,-1
#elif TEST==17
						.int -8,-2,-1,-1
#elif TEST==18
						.int -15,-2,-1,-1
#elif TEST==19
						.int -16,-2,-1,-1
#else
			.error "Definir TEST entre 1..19"
#endif
			.endm
lista:    linea0
					.irpc i,123
								linea
			.endr
longlista:	.quad   (.-lista)/4
media:			.int   0
resto:			.int   0
formato: 	  .ascii "media \t = %11d \t resto \t = %11d\n"
						.asciz       "\t\t = 0x %08x \t\t = 0x %08x \n"
formatq: 	  .ascii "media \t = %11d \t resto \t = %11d\n"
						.asciz       "\t\t = 0x %08x \t\t = 0x %08x \n"


# opción: 1) no usar printf, 2)3) usar printf/fmt/exit, 4) usar tb main
# 1) as  media.s -o media.o
#    ld  media.o -o media					1232 B
# 2) as  media.s -o media.o				6520 B
#    ld  media.o -o media -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2
# 3) gcc media.s -o media -no-pie –nostartfiles		6544 B
# 4) gcc media.s -o media	-no-pie				8664 B

.section .text
 main: .global  main

	call trabajar	# subrutina de usuario
	call imprim_C	# printf()  de libC
	call trabajarq
	call imprim_Cq
	call acabar_C	# exit()    de libC
	ret

trabajar:
	mov     $lista, %ebx
	mov  longlista, %ecx
	call suma		# == suma(&lista, longlista);
	mov  %eax, media
	mov  %edx, resto
	ret

suma:
	push     %rsi
	mov  $0, %eax  # Ponemos a cero los registros que usaremos
	mov  $0, %rsi
	mov  $0, %edx
	mov  $0, %ebp
	mov  $0, %edi
bucle:
	mov  (%rbx,%rsi,4),%eax # Se lee el elemento de la lista
	cdq                     # Extensión de signo
	add   %eax,%ebp         # Suma sin acarreo
	adc   %edx,%edi         # Suma con acarreo
	mov   %ebp,%eax         # Movemos el cociente y el resto a los registros convenientes para idiv
	mov   %edi,%edx
	inc   %rsi              # Incrementamos el contador
	cmp   %rsi,%rcx         # Comprobamos si ha sumado todos los elementos
	jne    bucle            # Si no lo ha hecho, repite el bucle

	idiv  %ecx              # Divide lo que hay en los registros edx:eax entre el número de elementos de la lista (que está en ecx)

	pop   %rsi
	ret

trabajarq:
	mov     $lista, %rbx
	mov  longlista, %ecx
	call sumaq	
	mov  %eax, media       
	mov  %edx, resto
	ret

sumaq:
	push		%rsi 
	mov  $0,%rsi # Pone a 0 los registros que usaremos
	mov  $0,%rdi
	mov  $0,%rax
	mov  $0,%rdx
bucleq:
	mov (%rbx,%rsi,4),%eax # Se lee el elemento de la lista
	cdqe                   # Extensión de signo
	add  %rax,%rdi         # Suma
	mov  %rdi,%rax         # Movemos el resultado al registro conveniente para idiv
	inc  %rsi              # Incrementamos el contador
	cmp  %rsi,%rcx         # Miramos si ha sumado todo
	jne  bucleq            # Si no ha terminado, sigue con el bucle
	
	cqo                    # Extensión de signo
	idiv %rcx	             # Divide

	pop %rsi

	ret

imprim_C:			# requiere libC
	mov  $formato,%rdi      # 'Avisa' del formato que va a usar
	mov   media,%rsi        # Paso de parámetros para la primera representación
	mov   resto,%rdx  
	mov   media,%ecx        # Paso de parámetros para la segunda representación
	mov   resto,%r8d
	mov          $0,%eax	# varargin sin xmm
	call  printf		# == printf(formato, res, res);
	ret

imprim_Cq:			# requiere libC
	mov  $formatq,%rdi      # 'Avisa' del formato que va a usar
	mov   media,%esi        # Paso de parámetros para la primera representación
	mov   resto,%edx  
	mov   media,%ecx        # Paso de parámetros para la segunda representación
	mov   resto,%r8d
	mov          $0,%eax	# varargin sin xmm
	call  printf		# == printf(formato, res, res);
	ret


acabar_C:			# requiere libC
	mov  media, %edi
	call _exit		# ==  exit(resultado)
	ret
