! OS for the ZTH1 computer (to be used with Forth compiler)
! Base routines
!
! Input/output: stack= (top level,level below,...)
! if output= (-), all arguments in input stack have been dropped

! Color LUT

! 0 = black, 1 = dark blue , 2 = yellow , 3 = red, 4 = pink
! 5 = cyan, 6 = orange, 7 = bright blue, 8 = grey, 9 = white
! 10 = purple, 11 = green

org x1800
#x0080 ; #x0080 ; #x0080
#x00ff ; #x00ff ; #xffff
#xffff ; #xff00 ; #x00ff
#xff00 ; #x20ff ; #x2000
#xff00 ; #x8000 ; #x8000
#x0000 ; #xff00 ; #xff00
#xff00 ; #x8000 ; #x0000
#x4000 ; #x4000 ; #xff00

! System variables

@v1=x186A      ! general-purpose variable
@v2=x186B      ! general-purpose variable
@v3=x186C      ! general-purpose variable
@v4=x186D      ! general-purpose variable
@v5=x186E      ! general-purpose variable
@v6=x186F      ! general-purpose variable
@v7=x1870      ! general-purpose variable
@v8=x1871      ! general-purpose variable
@xy=x1872      ! (x,y) coordinate of character to display
               ! (y=high-byte, x=low-byte)
@colors=x1873  ! character color
               ! (ink=high-byte, paper=low-byte)
org x1874
@pow10         ! powers of 10 (for integer display)
#x2710 ; #x03e8 ; #x0064 ; #x000a ; #x0001
@pow10is1=x1878 ! last power of 10 (=1) marking last digit
@pow10is0=x1879 ! integer-end mark

! Initial system variable values

org x1872

#x0000    ! cursor at top-left corner
#x0005     ! black on cyan background
 
! Character bitmaps

org x1E80

#x0000 ; #x0000 ; #x0000 ; #x0000
#x0010 ; #x1010 ; #x1000 ; #x1000
#x0024 ; #x2400 ; #x0000 ; #x0000
#x0024 ; #x7e24 ; #x247e ; #x2400
#x0008 ; #x3e28 ; #x3e0a ; #x3e08
#x0062 ; #x6408 ; #x1026 ; #x4600
#x0010 ; #x2810 ; #x2a44 ; #x3a00
#x0008 ; #x1000 ; #x0000 ; #x0000
#x0004 ; #x0808 ; #x0808 ; #x0400
#x0020 ; #x1010 ; #x1010 ; #x2000
#x0000 ; #x1408 ; #x3e08 ; #x1400
#x0000 ; #x0808 ; #x3e08 ; #x0800
#x0000 ; #x0000 ; #x0008 ; #x0810
#x0000 ; #x0000 ; #x3e00 ; #x0000
#x0000 ; #x0000 ; #x0018 ; #x1800
#x0000 ; #x0204 ; #x0810 ; #x2000
#x003c ; #x464a ; #x5262 ; #x3c00
#x0018 ; #x2808 ; #x0808 ; #x3e00
#x003c ; #x4202 ; #x3c40 ; #x7e00
#x003c ; #x420c ; #x0242 ; #x3c00
#x0008 ; #x1828 ; #x487e ; #x0800
#x007e ; #x407c ; #x0242 ; #x3c00
#x003c ; #x407c ; #x4242 ; #x3c00
#x007e ; #x0204 ; #x0810 ; #x1000
#x003c ; #x423c ; #x4242 ; #x3c00
#x003c ; #x4242 ; #x3e02 ; #x3c00
#x0000 ; #x0010 ; #x0000 ; #x1000
#x0000 ; #x1000 ; #x0010 ; #x1020
#x0000 ; #x0408 ; #x1008 ; #x0400
#x0000 ; #x003e ; #x003e ; #x0000
#x0000 ; #x1008 ; #x0408 ; #x1000
#x003c ; #x4204 ; #x0800 ; #x0800
#x003c ; #x4a56 ; #x5e40 ; #x3c00
#x003c ; #x4242 ; #x7e42 ; #x4200
#x007c ; #x427c ; #x4242 ; #x7c00
#x003c ; #x4240 ; #x4042 ; #x3c00
#x0078 ; #x4442 ; #x4244 ; #x7800
#x007e ; #x407c ; #x4040 ; #x7e00
#x007e ; #x407c ; #x4040 ; #x4000
#x003c ; #x4240 ; #x4e42 ; #x3c00
#x0042 ; #x427e ; #x4242 ; #x4200
#x003e ; #x0808 ; #x0808 ; #x3e00
#x0002 ; #x0202 ; #x4242 ; #x3c00
#x0044 ; #x4870 ; #x4844 ; #x4200
#x0040 ; #x4040 ; #x4040 ; #x7e00
#x0042 ; #x665a ; #x4242 ; #x4200
#x0042 ; #x6252 ; #x4a46 ; #x4200
#x003c ; #x4242 ; #x4242 ; #x3c00
#x007c ; #x4242 ; #x7c40 ; #x4000
#x003c ; #x4242 ; #x524a ; #x3c00
#x007c ; #x4242 ; #x7c44 ; #x4200
#x003c ; #x403c ; #x0242 ; #x3c00
#x00fe ; #x1010 ; #x1010 ; #x1000
#x0042 ; #x4242 ; #x4242 ; #x3c00
#x0042 ; #x4242 ; #x4224 ; #x1800
#x0042 ; #x4242 ; #x425a ; #x2400
#x0042 ; #x2418 ; #x1824 ; #x4200
#x0082 ; #x4428 ; #x1010 ; #x1000
#x007e ; #x0408 ; #x1020 ; #x7e00
#x000e ; #x0808 ; #x0808 ; #x0e00
#x0000 ; #x4020 ; #x1008 ; #x0400
#x0070 ; #x1010 ; #x1010 ; #x7000
#x0010 ; #x3854 ; #x1010 ; #x1000
#x0000 ; #x0000 ; #x0000 ; #x00ff
#x001c ; #x2278 ; #x2020 ; #x7e00
#x0000 ; #x3804 ; #x3c44 ; #x3c00
#x0020 ; #x203c ; #x2222 ; #x3c00
#x0000 ; #x1c20 ; #x2020 ; #x1c00
#x0004 ; #x043c ; #x4444 ; #x3c00
#x0000 ; #x3844 ; #x7840 ; #x3c00
#x000c ; #x1018 ; #x1010 ; #x1000
#x0000 ; #x3c44 ; #x443c ; #x0438
#x0040 ; #x4078 ; #x4444 ; #x4400
#x0010 ; #x0030 ; #x1010 ; #x3800
#x0004 ; #x0004 ; #x0404 ; #x2418
#x0020 ; #x2830 ; #x3028 ; #x2400
#x0010 ; #x1010 ; #x1010 ; #x0c00
#x0000 ; #x6854 ; #x5454 ; #x5400
#x0000 ; #x7844 ; #x4444 ; #x4400
#x0000 ; #x3844 ; #x4444 ; #x3800
#x0000 ; #x7844 ; #x4478 ; #x4040
#x0000 ; #x3c44 ; #x443c ; #x0406
#x0000 ; #x1c20 ; #x2020 ; #x2000
#x0000 ; #x3840 ; #x3804 ; #x7800
#x0010 ; #x3810 ; #x1010 ; #x0c00
#x0000 ; #x4444 ; #x4444 ; #x3800
#x0000 ; #x4444 ; #x2828 ; #x1000
#x0000 ; #x4454 ; #x5454 ; #x2800
#x0000 ; #x4428 ; #x1028 ; #x4400
#x0000 ; #x4444 ; #x443c ; #x0438
#x0000 ; #x7c08 ; #x1020 ; #x7c00
#x000e ; #x0830 ; #x0808 ; #x0e00
#x0008 ; #x0808 ; #x0808 ; #x0800
#x0070 ; #x100c ; #x1010 ; #x7000
#x0014 ; #x2800 ; #x0000 ; #x0000
#x3c42 ; #x99a1 ; #xa199 ; #x423c
 
org x0000

! boot code:
! erase screen and jump to main Forth word
! (address will be set by compiler)

call @er_screen
jump x0200

! Multiplication of two unsigned 8-bit integers (U* Forth word)
! (a,b) => (a*b)

@umult
entr x0000
dup ; rd4
@um_j1
btt ; rd4
rd4
jpnz @um_j2
add 
@um_j2
swp ; ccf
rlw ; rd4
inc
entr x0008
cmp ; drp
jmpz @um_j3
ru4 ; swp
rd4 ; rd4
jump @um_j1
@um_j3
drp ; drp
swp ; drp
ret

! Multiplication of two signed 8-bit integers
! Check signs of a and b before calling unsigned multiplication

@mult
dup ; rlw
drp
jpnc @m_j1
neg          ! a<0 => turn it to -a=|a|
entr x0001
jump @m_j2
@m_j1
entr x0000
@m_j2
rd3 ; dup
rlw ; drp
jpnc @m_j3
neg          ! b<0 => turn it to -b=|b|
entr x0001
jump @m_j4
@m_j3
entr x0000
@m_j4
rd3 ; xor   ! => top-stack = sign of a*b
swp ; drp
swp ; rd3
call @umult  ! => calculate |a|*|b|
swp ; rrw
drp ; rnc
neg ; ret ! restore sign of a*b


! Euclidian unsigned division routine (a/b)
! long-division algorithm (see Wikipedia page)

@div
entr @v1
swp ; stw     ! store a in v1
drp ; drp
entr @v2
swp ; stw     ! store b in v2
drp ; drp
entr x0000
dup ; dup
ldh x80       ! => top of stack=counter 2^i (i from (n-1) to 0)
swp           ! => top of stack=remainder R
@edj1
ccf ; rlw     ! R <- R<<1 (=> bit 0 of R=0)
entr @v1
gtw ; rd3
swp ; and    ! => get bit i of a 
drp ; swp
jmpz @edj2   ! if bit=0, skip
entr x0001
swp ; orr    ! set bit 0 of R to 1
swp ; drp
@edj2
entr @v2
gtw ; swp
cmp
jpnc @edj3
swp ; drp
ru3
jump @edj4
@edj3           ! if R>= b
sub ; swp       ! R <- R-b
drp ; ru3
swp ; orr       ! Q(i) <- 1
swp
@edj4
ccf ; rrw       ! i-1
entr x0000
cmp ; drp
rd3
jpnz @edj1      ! loop if 2^i != 0
ru3 ; drp
ret


! Get only quotient of euclidian division (/ Forth word)
! (a,b) => (a/b)

@quot
call @div
swp ; drp
ret


! Get only remainder of euclidian division (/MOD Forth word)
! (a,b) => (a mod b)

@modulo
call @div
drp ; ret


! Display character (EMIT Forth word)
! (char) => (-)

@disp_char
entr @v4 ! used to store ASCII code of character
swp ; stw
drp ; drp
entr @xy
gth ; cll
dup ; ccf    ! multiply y by 8*48=384
rrw ; add
entr @xy
gtl ; clh    ! add 2*x
ccf ; rlw
add ; ru3
drp ; drp    ! clean stack 
entr @v5     ! v5=pointer to VRAM
swp ; stw
drp ; drp    ! clean stack
! Find address of character bitmap
entr @v4
gtl ; clh
ccf ; rlw    ! multiply by 4 (4 16-bit words per character bitmap)
rlw
entr x1e00   ! bitmap of character set starts at x1e80 (for char=32)
add
swp ; drp     ! clean stack
entr @v6      ! v6=pointer to character bitmap
swp ; stw
drp ; drp     ! clean stack
! Set counter of pixel lines
entr @v3
entr x0008
stw
drp ; drp      ! clean stack
@dc_loop1
! Set counter of pixmap words (for each pixel line)
entr @v2
entr x0002
stw
drp ; drp      ! clean stack
! Get bitmap (line of 8 pixels)
entr @v3
gtw ; rrw
drp            ! clean stack
jmpc @dc_get_l
entr @v6
gtw ; gth
cll
jump @dc_next2
@dc_get_l
entr @v6
gtw ; gtl
swa ; cll
entr @v6 ! prepare to read next bitmap line
dup ; gtw
inc ; stw
drp ; drp ! drop to have bitmap at top of stack
@dc_next2
@dc_loop2
! Reset pixmap
entr x0000
! Get ink and paper as separated words, shift them to the highest nibble
entr @colors
gth ; cll     ! get ink
ccf ; rlw
rlw ; rlw
rlw
entr @colors
gtl ; clh     ! get paper
swa ; ccf
rlw ; rlw
rlw ; rlw
! Set counter of pixels
entr @v1
entr x0004
stw; drp
drp
! Now stack is [paper,ink,pixmap,bitmap]
! Re-shuffle to [bitmap,pixmap,paper,ink]
rd3 ; rd4
@dc_loop3
! Set pixel value (nibble) in pixmap according to pixel in bitmap
! bitmap is read from left to right (shifting its MSB into CF)
rlw
jmpc @dc_ink_dot
ru4; orr      ! pixel=paper
ru3
jump @dc_next1
@dc_ink_dot
rd4 ; rd3
orr ; swp     ! pixel=ink
rd4
@dc_next1
! Now stack is [paper,ink,pixmap,bitmap]
! Shift nibbles of ink and paper
ccf ; rrw
rrw ; rrw
rrw ; swp
rrw ; rrw
rrw ; rrw
! Re-shuffle to [bitmap,pixmap,paper,ink]
swp ; rd4
rd4 ; swp
! Check if pixmap word full
entr @v1    ! decrement c1 counter
dup ; gtw
dec ; stw
drp ; drp   ! drop to restore stack
jpnz @dc_loop3
! Store pixmap word in video RAM
swp
entr @v5
gtw ; swp
stw ; swp
inc         ! move to next pixmap word on the right
entr @v5
swp ; stw
drp ; drp
drp         ! drop to have bitmap at top of stack
! Check if bitmap line fully read
entr @v2
dup ; gtw
dec ; stw
drp ; drp  
ru3 ; drp
drp          ! stack has now only bitmap inside
jpnz @dc_loop2
drp          ! stack now empty
entr @v5 ! go to next line of image
dup ; gtw
entr x02E ! = +46 because we already incremented video RAM address twice
add ; swp
drp ; stw
drp ; drp     ! stack now empty
! Check if character fully displayed
entr @v3
dup ; gtw
dec ; stw
drp ; drp     ! stack now empty
jpnz @dc_loop1

entr @xy         ! update (x,y) location of next character to be displayed
gtl ; clh
entr x0017
cmp ; drp
jmpz @nc_j1
inc              ! x <- x+1
entr @xy
swp ; stl
drp ; drp
ret
@nc_j1           ! move to next line 
drp
@crword          ! mark start of CR Forth word
entr @xy
gth ; cll        ! x <- 0
entr x0F00
cmp ; drp
jmpz @nc_j2
entr x0100
add ; swp        ! y <- y+1
drp
entr @xy
swp ; stw
drp ; drp
ret
@nc_j2           ! bottom of screen reached
drp
call @scroll
entr @xy
entr x0000
stl              ! x <- 0 , y remains at 15 (bottom)
drp ; drp
ret

! display character string (." Forth word)
! (string_pointer) => (-)

@disp_str
entr @v7         ! v7 = character counter
entr x0000
stw ; drp 
drp
@ds_loop
entr @v7
gtw ; rrw        ! check if counter is odd or even
drp ; dup
jmpc @ds_j1
gth              ! get char from high-byte (counter even)
swa ; clh
jump @ds_j2
@ds_j1
gtl ; clh        ! get char from low-byte (counter odd)
@ds_j2
entr x0000
cmp ; drp
jmpz @ds_end     ! 0= end of string
call @disp_char
entr @v7         ! increment char counter
dup ; gtw
inc ; stw
rrw ; drp        ! check if odd or even
drp
jmpc @ds_loop
inc              ! increment string pointer if counter even
jump @ds_loop
@ds_end
drp ; drp        ! clean stack before returning 
ret


! scroll screen up by one character line

@scroll
entr x0000         ! target
entr x0180         ! source (1 line below)
@sc_loop1
dup ; gtw
rd3 ; swp
stw ; drp          ! copy source to target word-by-word
inc ; swp
inc                ! top of stack = source 
entr x1800
cmp ; drp
jpnz @sc_loop1 
drp ; drp
entr x1680          ! set target to clear the bottom line 
@sc_clear
entr @colors       
gtl ; dup           ! get paper color
ccf ; rlw
rlw ; rlw
rlw ; orr           ! duplicate nibble (=paper color) in low-byte
swp ; drp
clh ; dup
swa ; orr           ! duplicate low-byte into high-byte
swp ; drp
@sc_loop2
stw ; swp
inc
entr x1800
cmp ; drp
swp
jpnz @sc_loop2
drp ; drp
ret


! erase screen (CLS Forth word)
! branch to end of scroll routine with a different target start value
! (ugly way to save instruction words !)

@er_screen
entr x0000
jump @sc_clear
 
! set (x,y) coordinates for character display (AT Forth word) 
! (x,y) => (-)

@set_xy
swp ; swa
cll; orr
swp ; drp
entr @xy
swp ; stw
drp ; drp
ret


! display integer 
! (N) -> (-) 

entr @v7          ! v7 = forbidden character
entr x0030        ! (to not display padding 0s)
stw ; drp 
drp
entr @v8          ! v8 = pointer to powers of 10
entr @pow10
stw ; drp         ! set power of 10 
drp
dup ; rlw         ! check sign of number to display
drp
jpnc @ci_loop1
entr x002D
call @disp_char   ! display minus sign
neg
@ci_loop1
entr x0030        ! =ASCII code of 0
entr @v8
gtw ; gtw
rd3               ! stack is now (N,10^i,A) 
@ci_loop2
cmp
jmpc @ci_j2
sub ; rd3         ! N <- N-10^i
inc ; ru3         ! increment ASCII code  
jump @ci_loop2
@ci_j2
swp ; drp
swp
entr @v7          ! check if digit to display is 0
gtw ; cmp
drp
jmpz @ci_j3
call @disp_char   ! display digit
entr @v7
entr @x00FF       ! now that at least a non-zero has been displayed,
stw ; drp         ! leave restrictions on 0 (allow any character)
drp
jump @ci_j5
@ci_j3            ! no display of digit (because is padding 0)
drp               ! drop ASCII code (as disp_char would do it) 
@ci_j5 
entr @v8
dup ; gtw
inc ; stw
swp ; drp
entr @pow10is1    ! check if last digit is next to be displayed
cmp ; drp
jpnz @ci_j4
drp
entr @v7
entr x00FF       ! if so, leave restriction on display of 0
stw ; drp         ! (allow any character)
drp
jump @ci_loop1
@ci_j4
entr @pow10is0      ! check if last digit has been displayed
cmp ; drp
drp
jpnz @ci_loop1
drp ; ret

! Query joystick
! 4 first bits of result reflect activation of
! bit 3: up ; bit 2: down ; bit 1: left ; bit 0: right 
! warning: bit is at 0 if activated => mask with OR in programs
!          to find out direction

@joystick
entr x0000
dup
inp ; swp
rlw ; swp
inc ; inp
swp ; rlw
swp ; inc
inp ; swp
rlw ; swp
inc ; inp
drp ; rlw
ret

! Define sprite bitmap
! (sprite number,bitmap address) => (-)

@def_sprite
ccf ; rlw    ! target address= 8*sprite_number + x182a
rlw ; rlw
entr x182a
add ; swp
drp
entr x0004  ! 4 words to be copied
swp ; rd3   ! stack is [S,T,n]
@dspr_loop
dup ; ru4
gtw ; sth   ! high-byte char bitmap => high-byte sprite
swp ; inc
swp ; swa
sth ; drp   ! low-byte char bitmap => high-byte sprite
inc ; rd3
inc ; rd3
dec ; ru3
jpnz @dspr_loop
drp ; drp
drp ; ret 

! Put sprite on screen
! (sprite number,x,y) => (-)

@put_sprite
entr x1818
add ; swp
drp ; swp
stl ; drp
swp ; swa
entr x8000 ! set sprite activation bit
orr ; swp
drp ; sth
drp ; drp
ret

! Set sprite color
! (sprite number,color) => (-)

@color_sprite
dup ; rrw      ! check if sprite number >=4
rrw ; rrw
jmpc @cspr_j1
drp
entr x1826
add ; swp
drp ; swp
swa ; sth
drp ; drp
ret
@cspr_j1
drp
entr x1822
add ; swp
drp ; swp
stl ; drp
drp ; ret

! Hide sprite
! (sprite number) => (-)

@hide_sprite
entr x1818
add ; swp
drp ; dup
gtw
entr x7fff
and ; swp
drp ; stw
drp ; drp
ret 

