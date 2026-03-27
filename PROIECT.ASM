; ====================================================================
; PROIECT: SIMULATOR CUPTOR CU MICROUNDE (8086)
; DESCRIERE: Simuleaza setarea timpului/temperaturii si procesul de gatire
; ====================================================================

model small         
stack 200h          

data segment
    ; --- DEFINIRE MESAJE SI TEXTE ---
    ; db = Define Byte (caractere). 
    ; 13 = Carriage Return (cursorul la inceput de rand), 10 = Line Feed (rand nou)
    ; '$' = Marker de final de text (pentru functia 09h a DOS)
    
    msg_titlu   db 13, 10, '=== SIMULATOR CUPTOR 8086 ===', 13, 10, '$'
    msg_meniu   db 13, 10, '1. Dezghetare    (3 min, 30C)', 13, 10
                db '2. Incalzire     (2 min, 70C)', 13, 10
                db '3. Gatire Usoara (8 min, 120C)', 13, 10
                db '------------------------------', 13, 10
                db '+/- : Ajustare Timp', 13, 10
                db 'S   : START', 13, 10
                db 'ESC : Iesire', 13, 10, '$'

    msg_status  db 13, 10, 'STATUS: Timp: $'
    msg_temp    db 's | Temp: $'
    msg_grade   db 'C $'
    
    msg_start   db 13, 10, 10, '>>> PORNIRE PROCES... (ESC pentru Stop) <<<', 13, 10, '$'
    msg_ramas   db 13, 'Ramas: $'               ; 13 (CR) fara 10 (LF) face ca textul sa se suprascrie pe aceeasi linie
    msg_done    db 13, 10, 'DONE! Proces finalizat.', 7, 13, 10, '$' ; 7 = BEEP 
    msg_err     db 13, 10, 'EROARE: Setati un mod sau timp > 0!', 7, '$'
    newline     db 13, 10, '$'                  ; Variabila doar pentru a trece la rand nou

    ; --- VARIABILE NUMERICE ---
    timp        dw 0       ; dw = Define Word, stocheaza timpul in secunde
    temperatura dw 0       ; stocheaza temperatura in grade C
    tasta       db 0       ; db = Define Byte, stocheaza ultima tasta apasata de utilizator
data ends

code segment
assume cs:code, ds:data    ; Ii spune asamblorului care segment e care

start:
    ; --- INITIALIZARE SISTEM ---
    mov ax, data           ; Incarcam adresa segmentului de date in AX
    mov ds, ax             ; Mutam din AX in DS. Acum procesorul vede variabilele.

; ----------------------------------------------------------------
; ETICHETA: REFRESH_MENIU
; SCOP: Redeseneaza interfata utilizatorului dupa orice modificare
; ----------------------------------------------------------------
refresh_meniu:
    ; Afisare linie noua 
    mov ah, 09h            ; Functia DOS 09h = Afisare sir de caractere terminat cu $
    mov dx, offset newline ; Incarcam in DX adresa textului 'newline'
    int 21h                ; Apelam intreruperea DOS sa execute afisarea

    ; Afisare Titlu
    mov dx, offset msg_titlu
    int 21h

    ; Afisare optiuni Meniu
    mov dx, offset msg_meniu
    int 21h

    ; --- AFISARE STATUS CURENT (TIMP SI TEMPERATURA) ---
    ; Afisare text "STATUS: Timp:"
    mov ah, 09h
    mov dx, offset msg_status
    int 21h
    
    ; Afisare valoare numerica Timp
    mov ax, timp           ; Punem valoarea timpului in AX pentru a fi afisata
    call AFISARE_NUMAR_16  ; Apelam procedura noastra care transforma numarul in text pe ecran
    
    ; Afisare separator " | Temp: "
    mov ah, 09h
    mov dx, offset msg_temp
    int 21h
    
    ; Afisare valoare numerica Temperatura
    mov ax, temperatura    ; Incarcam temperatura in AX
    call AFISARE_NUMAR_16  ; Afisam numarul
    
    ; Afisare "C" la final
    mov ah, 09h
    mov dx, offset msg_grade
    int 21h

; ----------------------------------------------------------------
; ETICHETA: CITIRE_COMANDA
; SCOP: Asteapta ca utilizatorul sa apese o tasta
; ----------------------------------------------------------------
citire_comanda:
    mov ah, 08h            ; Citire tasta fara ecou 
    int 21h                ; Procesorul se blocheaza aici pana apesi o tasta
    mov tasta, al          ; Rezultatul (codul ASCII al tastei) este in AL. Il salvam in variabila 'tasta'

    ; ============================================================
    ; DISPECER COMENZI
    ; Verificam ce tasta s-a apasat si sarim la eticheta potrivita
    ; ============================================================
    
    ; Verificare taste numerice (Moduri presetate)
    cmp tasta, '1'         ; Compara tasta apasata cu caracterul '1'
    je go_set_1            ; JE (Jump Equal) - Daca sunt egale, sari la go_set_1
    cmp tasta, '2'
    je go_set_2
    cmp tasta, '3'
    je go_set_3

    ; Verificare taste '+' sau '=' pentru adaugare timp
    cmp tasta, '+'
    je go_add
    cmp tasta, '='         ; Multe tastaturi au + pe tasta =
    je go_add

    ; Verificare taste '-' sau '_' pentru scadere timp
    cmp tasta, '-'
    je go_sub
    cmp tasta, '_'
    je go_sub

    ; Verificare tasta START (s mic sau S mare)
    cmp tasta, 's'
    je go_start
    cmp tasta, 'S'
    je go_start

    ; Verificare tasta ESC (Codul ASCII 27)
    cmp tasta, 27
    je go_exit             ; Daca e ESC, inchide programul

    jmp citire_comanda     ; Daca s-a apasat altceva, ignora si citeste din nou

; --- TRAMBULINE ---
; Folosim aceste etichete intermediare pentru a evita eroarea "Relative jump out of range"
go_set_1: jmp set_dezghetare
go_set_2: jmp set_incalzire
go_set_3: jmp set_gatire
go_add:   jmp adauga_timp
go_sub:   jmp scade_timp
go_start: jmp validare_start
go_exit:  jmp iesire_program


; ----------------------------------------------------------------
; LOGICA SETARE MODURI (PREDEFINITE)
; ----------------------------------------------------------------
set_dezghetare:
    mov timp, 180        ; Incarcam 180 secunde in memorie
    mov temperatura, 30  ; Incarcam 30 grade
    jmp refresh_meniu    ; Ne intoarcem sa desenam meniul actualizat

set_incalzire:
    mov timp, 120        ; 2 minute
    mov temperatura, 70
    jmp refresh_meniu

set_gatire:
    mov timp, 480        ; 8 minute
    mov temperatura, 120
    jmp refresh_meniu

; ----------------------------------------------------------------
; AJUSTARE MANUALA A TIMPULUI
; ----------------------------------------------------------------
adauga_timp:
    cmp timp, 900        ; Compara timpul curent cu 900 (15 minute limita maxima)
    jae skip_add         ; JAE (Jump if Above or Equal) - Daca e deja >= 900, nu mai adauga
    add timp, 10         ; Adauga 10 secunde la variabila timp
skip_add:
    jmp refresh_meniu    ; Actualizeaza ecranul

scade_timp:
    cmp timp, 10         ; Verifica daca timpul e mai mic de 10 secunde
    jb fa_zero           ; JB (Jump if Below) - Daca e sub 10 (ex: 5), sari la fa_zero pentru a nu avea numere negative
    sub timp, 10         ; Scade 10 secunde
    jmp refresh_meniu

fa_zero:
    mov timp, 0          ; Forteaza timpul la 0 (limita inferioara)
    jmp refresh_meniu

; ----------------------------------------------------------------
; PORNIRE PROCES (NUMARATOARE INVERSA)
; ----------------------------------------------------------------
validare_start:
    ; Masura de siguranta: Nu pornim daca timpul e 0
    cmp timp, 0
    je eroare_start      ; Daca timpul e 0, afiseaza eroare

    ; Afisare mesaj "PORNIRE PROCES..."
    mov ah, 09h
    mov dx, offset msg_start
    int 21h
    jmp bucla_timer      ; Intram in bucla de scadere

eroare_start:
    mov ah, 09h
    mov dx, offset msg_err
    int 21h
    mov ah, 08h          ; Asteapta o tasta (ca sa vada utilizatorul eroarea)
    int 21h
    jmp refresh_meniu    ; Revine la meniu

; --- BUCLA PRINCIPALA DE GATIRE (TIMER) ---
bucla_timer:
    ; Afisare text "Ramas: " 
    mov ah, 09h
    mov dx, offset msg_ramas
    int 21h

    ; Afisare secunde ramase
    mov ax, timp
    call AFISARE_NUMAR_16
    
    ; Afisare temperatura constanta in timpul procesului
    mov ah, 09h
    mov dx, offset msg_temp
    int 21h
    
    mov ax, temperatura
    call AFISARE_NUMAR_16
    
    ; Stergere caractere reziduale (spatii goale la final de rand)
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h              ; Afisam doua spatii

    ; --- ASTEPTARE 1 SECUNDA ---
    call DELAY_1_SEC     ; Apeleaza procedura care "pierde vremea" 1 secunda

    ; --- VERIFICARE TASTA ESC IN TIMP REAL ---
    ; Nu folosim INT 21h/01h pentru ca ar bloca cronometrul
    mov ah, 01h          ; Functia BIOS 01h (INT 16h) - Verifica buffer tastatura
    int 16h              ; Returneaza Zero Flag (ZF) = 1 daca NU s-a apasat nimic
    jz nu_s_a_apasat     ; Daca nu s-a apasat nimic, sari peste citire
    
    ; Daca s-a apasat ceva, extragem caracterul din buffer pentru a-l procesa
    mov ah, 00h          ; Functia BIOS 00h - Citeste tasta
    int 16h
    cmp al, 27           ; Verificam daca tasta apasata a fost ESC
    je stop_fortat       ; Daca da, oprim tot
    
nu_s_a_apasat:
    ; Decrementare timp
    dec timp             ; Scade 1 din variabila timp
    cmp timp, 0          ; Verifica daca a ajuns la 0
    jne bucla_timer      ; JNE (Jump Not Equal) - Daca nu e 0, repeta bucla

    ; --- FINALIZARE CICLU ---
    mov ah, 09h
    mov dx, offset msg_done ; Afiseaza "DONE!"
    int 21h
    
    mov temperatura, 0   ; Resetam temperatura 
    mov ah, 08h          ; Asteptam o tasta inainte de a reveni la meniu
    int 21h
    jmp refresh_meniu

stop_fortat:
    jmp refresh_meniu    ; Iesire de urgenta direct in meniu

; ----------------------------------------------------------------
; IESIRE DIN PROGRAM 
; ----------------------------------------------------------------
iesire_program:
    mov ah, 4Ch          ; Functia DOS 4Ch = Termina programul si elibereaza memoria
    int 21h

; ----------------------------------------------------------------
; PROCEDURA: DELAY_1_SEC
; DESCRIERE: Creeaza o intarziere software prin bucle imbricate
; ----------------------------------------------------------------
DELAY_1_SEC PROC
    push cx              ; Salvam CX pe stiva (sa nu stricam valoarea din programul principal)
    push bx              ; Salvam BX
    
    mov cx, 0FFFFh       ; Setam contorul exterior la valoarea maxima (65535)
l1: mov bx, 100          ; Setam contorul interior (ajustabil pentru viteza)
l2: dec bx               ; Scade BX cu 1
    jnz l2               ; Daca BX nu e 0, sari la l2 (bucla mica)
    loop l1              ; Scade CX si daca nu e 0, sari la l1 (bucla mare)
    
    pop bx               ; Restauram valoarea originala a lui BX
    pop cx               ; Restauram valoarea originala a lui CX
    ret                  ; Return (revenire din procedura)
DELAY_1_SEC ENDP

; ----------------------------------------------------------------
; PROCEDURA: AFISARE_NUMAR_16
; DESCRIERE: Converteste numarul din AX in text si il afiseaza
; ALGORITM: Impartiri repetate la 10 si salvarea restului pe Stiva
; ----------------------------------------------------------------
AFISARE_NUMAR_16 PROC
    push ax              ; Salvam registrii folositi
    push bx
    push cx
    push dx
    
    mov cx, 0            ; CX va numara cate cifre are numarul (pentru POP)
    mov bx, 10           ; Divizorul este 10

div_loop:
    mov dx, 0            ; Curatam DX inainte de impartire (pentru ca DIV imparte DX:AX la BX)
    div bx               ; AX = AX / 10, DX = Restul (Cifra curenta)
    push dx              ; Salvam restul (cifra) pe stiva
    inc cx               ; Incrementam contorul de cifre
    
    cmp ax, 0            ; Verificam daca mai avem ce imparti
    jne div_loop         ; Daca catul nu e 0, continuam

print_loop:
    pop dx               ; Scoatem ultima cifra introdusa (care e de fapt prima cifra a numarului)
    add dl, '0'          ; Convertim cifra in caracter ASCII (adaugam '0')
    mov ah, 02h          ; Functia de afisare un caracter
    int 21h
    loop print_loop      ; Decrementeaza CX si repeta pana am afisat toate cifrele

    pop dx               ; Restauram registrii in ordine inversa
    pop cx 
    pop bx
    pop ax
    ret
AFISARE_NUMAR_16 ENDP

code ends
end start