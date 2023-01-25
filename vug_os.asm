! OS for the VectorUGo 2 console (to be used with Forth compiler)
! Base routines
!
! By S. Morel, Zthorus-Labs
!
!  Date          Action
!  ----          ------
!  2022-12-20    Created
!
! Input/output: stack= (top level,level below,...)
! if output= (-), all arguments in input stack have been dropped


! Start of RAM = vector table 
! default vector table displays 1 sprite = a triangle
! vector table can have up to 1024 vectors
! (vector table goes from x0000 to x0802 )

org x0000

#x050a   ! DAC offsets
#x9d9d
#x0008   ! number of vectors
#xa5a5   ! 1st 3 vectors = beam homing
#x2600
#xa5a5
#x2600
#x1414
#x2600
#x1e1e  ! position vector (center of gravity of sprite)
#x2600
#x00f0  ! invisible "radial" vector of sprite
#x1400
#x1123  ! visible sprite vectors (3 in our case)
#x1500
#xde00
#x1500
#x11dd
#x1500

! System variables

! general-purpose variables (used in routines)
@v1=x0803
@v2=x0804
@v3=x0805
@v4=x0806
@v5=x0807
@v6=x0808
@v7=x0809
@v8=x080a
@v9=x080b
@v10=x080c
@v11=x080d
@v12=x080e
@v13=x080f
@v14=x0810
@v15=x0811
@v16=x0812
@v17=x0813
@v18=x0814
@v19=x0815
@v20=x0816

! current pointer for allocation in the vector table
@vecptr=x0817

! current pointer for allocation in the sprite table
@sptptr=x0818

! current number of vectors displayed (useful ?)
@nbvec=x0819

! coordinates to display character strings
@atx=x081a
@aty=x081b

! initial values of some sys-vars 
org x0817
#x0009     ! initial value of vecptr
#x0820     ! initial value of sptptr (= beginning of sprite table)
#x0003     ! initial value of nbvec (3 => only frame beam-homing)
#x0010     ! initial value of atx
#x0060     ! initial value of aty

! leave x081c to x081f for future sys vars

! sprite table structure for each entry is:
! * number of vectors (including invisible position, radial, beam homing)
! * address in vector table
! * address of user-defined vector sequence
! sprite table spans from x0820 to x08df (64 sprites max)

! character set
! each character display consists of 2 words coding 8 vectors in total

org x08e0
@charset

! space 
#x440c ; #xc800

! ASCII 33 to 47: undefined (for the moment)
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10

! digits from 0 to 9
#x551d ; #xd900
#x43dd ; #x6c00
#x359d ; #xe900
#x441b ; #x1b00
#x055b ; #x1a00
#x1595 ; #x1cc0
#x53a1 ; #xd900
#x539c ; #xc4e0
#x539f ; #xd900
#x359d ; #x1a00

! ASCII 58 to 64: undefined (for the moment)
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10
#x1739 ; #xfb10

! uppercase letters from A to Z
#x53dd ; #x61c0
#x55f9 ; #xf900
#x551c ; #xc900
#x55fd ; #x94e0
#x551a ; #x1a10
#x551a ; #x1a00
#x551c ; #xd900
#x550d ; #x90d0
#x55cc ; #x28c0
#x540d ; #xd900
#x550b ; #xf800
#x550c ; #xc900
#x55f8 ; #x3dd0
#x55f5 ; #x8ed0
#x551d ; #xd900
#x551d ; #x9c00
#x0715 ; #x9de0
#x55f9 ; #xf800
#x1595 ; #x1cc0
#x550c ; #x9c10
#x550d ; #xd900
#x550d ; #xb2c0
#x5f5b ; #x0800
#x538f ; #xd800
#x44f5 ; #x8ed0
#x0639 ; #xcd10


! basic vectors used to draw characters

@charbasevecs
#x0100        ! E
#x0101        ! NE
#x0001        ! N
#xff01        ! NW
#xff00        ! W
#xffff        ! SW
#x00ff        ! S
#x01ff        ! SE

! scaled vectors used to draw characters (= N * base vectors)

@charvecs
#x0600
#x0606
#x0006
#xfa06
#xfa00
#xfafa
#x00fa
#x06fa

! powers of 10 (to display integers)

@pow10
#x2710 ; #x03e8 ; #x0064 ; #x000a ; #x0001

! trigonometry data: sine from 0 to pi/2

@sintab

#x0000
#x0003
#x0006
#x0009
#x000c
#x000f
#x0012
#x0015
#x0018
#x001c
#x001f
#x0022
#x0025
#x0028
#x002b
#x002e
#x0030
#x0033
#x0036
#x0039
#x003c
#x003f
#x0041
#x0044
#x0047
#x0049
#x004c
#x004e
#x0051
#x0053
#x0055
#x0058
#x005a
#x005c
#x005e
#x0060
#x0062
#x0064
#x0066
#x0068
#x006a
#x006c
#x006d
#x006f
#x0070
#x0072
#x0073
#x0075
#x0076
#x0077
#x0078
#x0079
#x007a
#x007b
#x007c
#x007c
#x007d
#x007e
#x007e
#x007f 
#x007f 
#x007f 
#x007f 
#x007f 
#x0001

org x0000

! Boot code:
! Jump to main Forth word
! (address will be set by compiler)

jump x0a00

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

! Return sine of angle (256=2*pi)
! (a) =>  128*sin(a) 
! result is signed on 16 bits
! sine table is located in RAM (unused low-bytes of vector table)
! and contains 64 values of 256*sin(a) for a=0 to a=pi*63/128
! special values are 1 (for a=pi/2) and -1 (for a=-pi/2) they are
! taken into account for the R*sin(a) routine

@sin
entr x0040 
swp ; cmp
jpnc @sj1
swp ; drp   ! case 0<=a<64 => table index= a
entr @sintab
add ; swp
drp ; gtw   ! get value stored at @sintab + a 
ret
@sj1
swp
ldl x80
swp ; cmp
jpnc @sj2
swp ; sub   ! case 64<=a<128 => table index= 128-a
swp ; drp
entr @sintab
add ; swp
drp ; gtw
ret
@sj2
swp
ldl xc0
swp ; cmp
jpnc @sj3
swp
ldl x80
swp ; sub   ! case 128<=a<192 => table index= a-128
swp ; drp
entr @sintab
add ; swp
drp ; gtw
neg ; ret   ! sine is negative
@sj3
swp ; drp
neg ; clh   ! case a>=192 => table index= 256-a (= -a on 8 bits) 
entr @sintab
add ; swp
drp ; gtw
neg ; ret   ! sine is negative


! Return cosine of angle (256=2*pi)
! (b) => 128*cos(a)
! result is signed on 16 bits
! sine table located in RAM is used 

@cos
entr x0040
swp ; cmp
jpnc @cj1
swp ; sub   ! case 0<=a<64 => table index= 64-a
swp ; drp
entr @sintab
add ; swp
drp ; gtw   ! get value stored at @sintab + a
ret
@cj1
swp
ldl x80
swp ; cmp
jpnc @cj2
swp
ldl x40
swp ; sub    ! case 64<=a<128 => table index= a-64
swp ; drp
entr @sintab
add ; swp
drp ; gtw
neg ; ret    ! cosine is negative
@cj2
swp
ldl xc0
swp ; cmp
jpnc @cj3
swp ; sub    ! case 128<=a<192 => table index= 192-a
swp ; drp
entr @sintab
add ; swp
drp ; gtw
neg ; ret    ! cosine is negative
@cj3
sub ; swp    ! case a>=192 => table index= a-192
drp
entr @sintab
add ; swp
drp ; gtw
ret


! Return b*sin(a) or b*cos(a), taking into account peculiarity of table values
! (a,b) => b*sin(a) ; (a,b) => b*cos(a)
! b must be between -128 and 127  

@ rsin
call @sin
jump @rsj0
@ rcos
call @cos
@rsj0        ! code common to b*sin(a) and b*cos(a) starts here
entr x0001   ! case actual sin=1 (a=pi/2) or cos=1 (a=0)
cmp
jmpz @rsj1
ldh xff      ! case actual sin=-1 (a=-pi/2) or cos=-1 (a=pi)
ldl xff
cmp
jmpz @rsj2
drp          ! case requiring multiplication 
call @mult
dup ; rlw    ! check if b*sin(a)<0 or b*cos(a)<0
jmpc @rsj3
drp ; rlw    ! multiply by 2 (because number returned by @sin or @cos
             ! is between -128 and 127) 
swa ; clh    ! move result from high to low byte
ret
@rsj3
drp ; neg   ! make result >0
rlw ; swa   ! multiply by 2 
clh ; neg   ! restore  minus sign
ret
@rsj1
drp ; drp   ! sin=1 or cos=1 => just return b (can be positive or negative)
ret
@rsj2
drp ; drp   ! sin=-1 or cos=-1 => return -b
neg ; ret


! Calculate rotation and scaling of a vector around its origin 
! input= (vector address) ; v1=angle, v11=scaling factor
! result is stored in system variables v4 (x out) and v5 (y out)

@rotscal
dup ; gtl   ! get y of vector (= low-byte)
dup ; rll   ! check sign of y
jmpc @roj1
drp ; clh
jump @roj2
@roj1
drp 
ldh xff     ! convert 8-bit negative to 16-bit negative
@roj2
entr @v2    ! store y_in in v2 
swp ; stw
drp ; drp
gth         ! get x of vector (= high-byte)
dup ; rlw   ! check sign of x 
jmpc @roj3
drp ; swa
clh
jump @roj4
@roj3
drp ; swa
ldh xff     ! convert 8-bit negative to 16-bit negative
@roj4
entr @v3    ! store x_in in v3
swp ; stw
drp ; drp
entr @v3
gtw
entr @v1
gtw
call @rcos  ! calculate x*cos(angle)
entr @v4
swp ; stw
drp ; drp
entr @v2
gtw
entr @v1
gtw
call @rsin  ! calculate y*sin(angle)
entr @v4
gtw ; sub   ! calculate x_out= x*cos(angle) - y*sin(angle)
swp ; drp
entr @v4
swp ; stw
drp ; drp
entr @v3
gtw
entr @v1
gtw
call @rsin  ! calculate x*sin(angle)
entr @v5
swp ; stw
drp ; drp
entr @v2
gtw
entr @v1
gtw
call @rcos  ! calculate y*cos(angle)
entr @v5
gtw ; add   ! calculate y_out= x*sin(angle) + y*cos(angle) 
swp ; drp
entr @v5
swp ; stw
drp ; drp
entr @v4
gtw
entr @v11
gtw
call @mult  ! scale x_out
rlw ; rlw
rlw ; rlw   ! multiply result by 16 and use high-byte
swa ; clh
entr @v4
swp ; stw
drp ; drp
entr @v5
gtw
entr @v11
gtw
call @mult  ! scale x_out
rlw ; rlw
rlw ; rlw   ! multiply result by 16 and use high-byte
swa ; clh
entr @v5
swp ; stw
drp ; drp
ret 


! Define a sprite (will be invisible by default)
! input= (number of vectors in sprite except position and beam-homing,
!         pointer to sprite graphic data)
! output= address of sprite in sprite table

@defsprite
entr @sptptr
gtw ; swp 
stw ; swp   ! set number of vectors in sprite table
drp ; nop 
entr @v1
swp ; stw  ! save number of vectors in v1
swp ; drp
entr @nbvec
gtw ; add  ! update total number of vectors
inc ; inc  ! add 4 vectors (position, beam-homing at end)
inc ; inc
entr @nbvec
swp ; stw
swp ; drp
entr x0002   ! update total nb of vectors in table header
swp ; stw
drp ; drp
drp          ! only graphic data pointer now remains in stack
entr @sptptr
gtw ; inc
inc ; nop    ! move to graphic data pointer field in sprite table entry  
swp ; stw    ! set graphic data pointer in sprite table
drp ; dec    ! move to vector table pointer field in sprite table entry
entr @vecptr
gtw ; stw    ! set vector table pointer in sprite table
swp ; drp
entr x2020   ! set default position vector
stw ; drp
inc ; nop
entr x2000   ! set length-factor and invisibility of position vector
stw ; drp
drp ; nop     ! stack is now clear 

entr @sptptr  ! start to copy sprite graphic data into vector table
gtw ; inc  
gtw ; nop     ! get pointer to vector table (=target)
inc ; inc     ! skip position vector
entr @sptptr
gtw ; inc
inc ; gtw     ! get pointer to graphic data (=source) 
@dfsloop
dup ; ru3 
gtw ; stw
drp ; inc
entr x2000    ! copy default length-factor (16) and z (=0 => invisible vector)
sth ; drp 
inc ; swp     ! increment pointers
inc 
entr @v1
dup ; gtw
dec ; stw
drp ; drp
jpnz @dfsloop
drp
entr xa5a5    ! add beam-homing vectors at end of sprite in vec table
stw ; drp
inc
entr x2600
sth ; drp
inc
entr xa5a5
stw ; drp
inc
entr x2600
sth ; drp
inc
entr x1414
stw ; drp
inc
entr x2600
sth ; drp
inc
entr @vecptr   ! update pointer to vector table for next entry 
swp ; stw
drp ; drp
entr @sptptr   ! beginning of update of sprite table pointer for next sprite
dup ; gtw
dup ; ru3 
@dfsloop2
inc ; inc
inc ; dup
gtw
entr x0000     ! check the next block in sprite table is free (Nvec=0)
cmp ; drp      ! otherwise move to the block after
drp
jpnz @dfsloop2 
stw            ! update pointer to sprite table for next sprite 
drp ; drp
ret            ! return the address of sprite table entry (before update) 


! Delete a sprite (remove it from vector and sprite tables)
! input =(address of sprite table entry for sprite to be deleted)

@delsprite
dup ; gtw
inc ; inc
inc ; inc
entr @v1    ! v1= number of vectors (position+radial+visible+homing) of sprite
swp ; stw   ! to delete
swp ; drp
entr x0002
gtw ; sub 
swp ; drp
entr x0002
swp ; stw   ! Reduce total number of vectors
drp ; drp
entr @v2    ! save address of deleted sprite to v2
swp ; stw
swp ; drp   ! stack=address of sprite table entry of deleted sprite
entr @v1
dup ; gtw   ! multiply v1 by 2
ccf ; rlw   ! v1 is now the size (in words) of the deleted sprite in the VT
stw ; swp
drp ; swp
inc ; gtw   !  defragment vec table (shift up the vectors that are
dup ; rd3   !  after those of the deleted sprite to fill the gap
add ; swp   !  left by the deleted sprite)
drp
@delsloop1  ! stack= (source pointer,target pointer)
dup ; gtw
rd3 ; swp
stw ; drp
inc ; swp
inc 
entr x0802      ! limit of vector table 
cmp ; drp 
jpnz @delsloop1
drp ; drp

entr @v2    ! scan the whole sprite table and update vec pointers
gtw ; inc   ! of sprites if they are greater than vec pointer of
gtw         ! deleted sprite
entr x0821  ! = address of 1st vec pointer in sprite table
@delsloop2
dup ; gtw
rd3 ; swp
cmp
jmpc @dels1
entr @v1
gtw ; swp   ! if vec pointer > vec pointer of deleted sprite 
sub ; swp   ! decrease vec pointer by 2*(nb vec of deleted sprite)
drp 
@dels1
rd3
swp ; stw   ! write vec pointer (even if value not modified)
drp ; inc
inc ; inc   ! move to address of vec pointer of next sprite (3 words further)
entr x08e1  ! check if limit reached
cmp ; drp
jpnz @delsloop2
drp ; drp

entr @sptptr     ! entry of deleted sprite can be used to allocate
entr @v2         ! next defined sprite => update sprite table pointer
gtw ; stw
swp ; drp
entr x0000       ! set nb of vecs of entry of deleted sprite to 0
stw ; drp        ! to mark block in sprite table as free
drp
entr @vecptr     ! update vec table pointer for next defined sprite
dup ; gtw
entr @v1
gtw ; swp
sub ; swp
drp ; stw
drp ; drp
entr @nbvec      ! update nbvec
entr x0002
gtw ; stw
drp ; drp
ret


! Copy the sprite vectors, from the vector table to memory and 
! update its data pointer. This routine can be used to treat
! text fully as a sprite (enabling the possibility to rotate and
! rescale it) after it has been displayed with @dispstring
! input= (address in sprite table,pointer to memory zone)

@copysprite
inc ; inc
swp ; stw     ! update data pointer in sprite table entry
swp ; dec
dec ; dup
gtw ; swp     ! get number of vectors (including radial)
inc ; gtw
rd3 ; swp
inc ; inc     ! skip position vector in vec table
@csprloop1
dup ; gtw
rd3 ; swp
stw ; drp     ! copy (x,y) of vector into memory zone
inc ; swp     ! increment pointer on memory zone
inc ; inc     ! move to next vector in table (2 words further)
rd3 ; dec     ! decrement vector counter 
ru3
jpnz @csprloop1
drp ; drp
drp
ret



! Rotate and rescale a sprite (a sequence of vectors) around the origin of its
! first vector (supposed to be invisible)
! input= (address of sprite table entry,angle,scaling ratio)
!
! angle=0 to 255 ; scaling ratio= actual ratio * 16
! algorithm consists in calculating "radial" vectors (vectors
! with origin = origin of first vector and arrow end = arrow end
! of sum of vectors defining the sprite). These radial vectors
! are rotated and rescaled

@rotscalsprite
ru3
entr @v1
swp ; stw    ! v1= angle
drp ; drp
entr @v11
swp ; stw    ! v11= scaling ratio 
drp ; drp
dup 
inc ; gtw
inc ; inc   ! skip 1st vector of sprite in table = position vector
entr @v6
swp ; stw    ! v6= pointer to vector table
drp ; drp
dup ; inc 
inc ; gtw    ! get address of sprite graphic data
entr @v12
swp ; stw    ! v12 = pointer to graphic data
drp ; drp
gtw
entr @v7
swp ; stw    ! v7= vector counter (counting down)
drp ; drp
entr x0000
entr @v8
swp ; stw    ! initialize sum of vectors (= v8)
swp ; drp
entr @v9
swp ; stw    ! initialize x of previous rotated radial vector (= v9)
swp ; drp
entr @v10     
swp ; stw    ! initialize y of previous rotated radial vector (= v10)
drp ; drp
@rotsloop
entr @v12
gtw ; gtl
clh 
entr @v8
gtl ; clh
add ; clh    ! add y of current vector to sum (sum of low-bytes)
swp ; drp
entr @v8
swp ; stl
drp ; drp
entr @v12
gtw ; gth
swa ; clh 
entr @v8
gth ; swa
clh
add ; swa    ! add x of current vector to sum (sum of high-bytes)
swp ; drp
entr @v8
swp ; sth
drp           ! top of stack= address new vector sum 
call @rotscal ! rotate and scale sum of vectors (= radial vector)
entr @v9      ! v9= x of previous rotscal
gtw
entr @v4      ! v4= x of new rotscal
gtw ; sub     ! calculate x of rotscal(sum vec) - previous(rotscal(sum vec))
swa ; cll     ! move to high-byte
swp ; drp
entr @v6
gtw ; swp
sth ; drp     ! update x of vector in sprite
drp
entr @v10     ! v10= y of previous rotscal
gtw
entr @v5      ! v5= y of new rotscal
gtw ; sub     ! calculate y of rotscal(sum vec) - previous(rotscal(sum vec))
swp ; drp
entr @v6
gtw ; swp
stl ; drp     ! update y vector in sprite
drp
entr @v9
entr @v4
gtw ; stw  ! update x of previous(rot(sum vec)) for next iteration 
drp ; drp
entr @v10
entr @v5
gtw ; stw  ! update y of previous(rot(sum vec)) for next iteration
drp ; drp
entr @v6
dup ; gtw
inc ; inc
stw ; drp   ! update vec table pointer to next vector (2 words further)
drp
entr @v12
dup ; gtw
inc
stw ; drp   ! update graphic data pointer to next vector (1 word further)
drp
entr @v7
dup ; gtw
dec ; stw   ! decrease vector counter
drp ; drp
jpnz @rotsloop
ret 


! Put sprite at a given (x,y) position
! input = (address of sprite table entry,y,x)

@putsprite
inc ; nop 
gtw ; ru3    ! get address of position vector = 1st vector of sprite  
swp ; swa
cll ; add
swp ; drp
stw ; drp    ! *(vec table address) <= 256*x +y
drp ; ret 


! Make sprite visible (all vectors except radial will be visible
! input= (address of sprite table entry)

@showsprite
dup ; gtw    ! get number of vectors of sprite
dec ; nop    ! exclude radial vector from this number 
swp ; inc
gtw ; inc    ! get address of sprite in vector table 
inc ; inc    ! skip 1st and 2nd vectors (position and radial)
inc ; inc    ! go to z-flag of 1st vector that will be visible
@ssloop
dup ; gth
entr x0100   
orr ; swp    ! set bit 0 (= z-flag) of high-byte to 1
drp ; sth
drp ; inc 
inc ; swp    ! address next vector (2 words further)
dec ; swp    ! decrease vector counter
jpnz @ssloop
ret

! Make visible some of the vectors of a sprite 
! using a binary mask = sequence of bits defining the visibility of
! each vector (1=visible,0=visible)
! The radial vector can be set visible and the sprite must be
! invisible when this routine is called
! input = (address of sprite table entry,address of binary mask)

@masksprite
dup ; gtw     ! get number of vectors of sprite
entr @v1
swp ; stw     ! v1 = number of vectors
drp ; drp
inc ; gtw     ! get address in vector table
inc ; inc     ! skip position vector
inc           ! pointer to 1st length-factor|z word 
entr @v2
entr x0010
stw ; drp     ! v2 = bit counter of mask word
drp ; swp
@mskloop1
dup ; gtw     ! get mask
@mskloop2
entr x0000
swp ; rlw
swp ; rlw     ! copy mask bit
swa ; rd4     ! move to high-byte
dup ; gtw
rd3 ; orr     ! set z bit of vector
swp ; drp
stw ; drp
inc ; inc     ! move to next vector
ru3
entr @v1
dup ; gtw
dec ; stw     ! decrement vector counter
drp ; drp
jmpz @msk1 
entr @v2
dup ; gtw
dec ; stw
drp ; drp
jpnz @mskloop2
drp ; inc       ! move to next mask word
jump @mskloop1
@msk1
drp ; drp 
drp
ret 


! Make sprite invisible
! input= (address of sprite table entry)

@hidesprite
dup ; gtw    ! get number of vectors of sprite
dec ; nop    ! exclude radial vector from this number 
swp ; inc
gtw ; inc    ! get address of sprite in vector table 
inc ; inc    ! skip 1st and 2nd vectors (position and radial)
inc ; inc    ! go to z-flag of 1st vector that will be invisible
@hsloop
dup ; gth
entr xFEFF   
and ; swp    ! set bit 0 (= z-flag) of high-byte to 0
drp ; sth
drp ; inc 
inc ; swp    ! address next vector  (2 words further)
dec ; swp    ! decrease vector counter
jpnz @hsloop
ret


! Close sprite (already displayed) consisting of a polygon
! input= (address of sprite table entry)

@closesprite
dup
gtw ; dec
dec ; swp     ! loop count = N-2 vectors (skip radial and last vector) 
inc ; gtw     ! get pointer to entry in vector table
inc ; inc
inc ; inc     ! skip 2 first vectors
entr x0000
entr @v1      ! v1= sum of x of vectors
swp ; stw     ! initialize v1=0
swp ; drp
entr @v2      ! v2= sum of y of vectors
swp ; stw
drp ; drp
@csloop      ! stack= (ptr to vec table,loop count)
dup ; gth
dup ; rlw    ! check if x<0
drp ; swa
jmpc @cs1
clh
jump @cs2
@cs1
ldh xff
@cs2
entr @v1
gtw ; add
swp ; drp
entr @v1
swp ; stw   ! v1= v1 + x
drp ; drp
dup ; gtl
dup ; rll   ! check if y<0
drp
jmpc @cs3
clh
jump @cs4
@cs3
ldh xff
@cs4
entr @v2
gtw ; add
swp ; drp
entr @v2
swp ; stw   ! v2= v2 + y
drp ; drp
inc ; inc   ! go to next vector
swp ; dec   ! decrease loop counter
swp
jpnz @csloop 
swp ; drp
entr @v1
gtw ; neg
swa
sth ; drp   ! x of last vector= -x of sum of previous vectors
entr @v2
gtw ; neg
stl ; drp   ! y of last vector= -y of sum of previous vectors
drp
ret


! Detect sprite collision
! input= (address of table entry sprite 1,address of table entry sprite 2)
! output= (index of colliding vector of sprite 1, index of colliding vector
!          of sprite 2) if collision
!       = 0 if no collision
! returned indices (of visible vector) ranges from 1 to N-1 

@sprtcoll
dup ; gtw
dec 
entr @v1    ! v1 = number of visible vectors of sprite 1 (= N-1)
swp ; stw
drp ; drp
inc ; gtw
entr @v3    ! v3 = pointer to vector table of sprite 1
swp ; stw
drp ; drp
dup ; gtw
dec
entr @v2    ! v2 = number of visible vectors of sprite 2 (= N-1)
swp ; stw
drp ; drp
inc ; gtw
entr @v4    ! v4 = pointer to vector table of sprite 2
swp ; stw
drp ; drp

entr @v3
gtw ; dup   ! read position vector sprite 1
gth ; swa   ! read x (high-byte) 
clh         ! (x,y) of position vectors are assumed to be always positive
entr @v5
swp ; stw   ! v5 = xo sprite 1
drp ; drp
gtl ; clh
entr @v6
swp ; stw   ! v6 = yo sprite 1
drp ; drp

entr @v3
gtw ; inc
inc ; dup   ! read radial vector sprite 1
gth ; dup   ! (x,y) of radial can be positive or negative
rlw ; drp   ! convert them to signed 16-bit
swa
jmpc @spc5
clh
jump @spc6
@spc5
ldh xff
@spc6
entr @v5
gtw ; add
swp ; drp
entr @v5
swp ; stw  ! xo sprite 1 = x_pos + x_radial 
drp ; drp
gtl ; dup
rll ; drp
jmpc @spc7
clh
jump @spc8
@spc7
ldh xff
@spc8
entr @v6
gtw ; add
swp ; drp
entr @v6
swp ; stw   ! yo sprite 1 = y_pos + y_radial
drp ; drp

entr @v3    
dup ; gtw
inc ; inc
inc ; inc
stw ; drp   ! set pointer sprite 1 (=v3) to 1st visible vector
drp
entr @v19   ! save number of visible vecs of sprite 1 to v19
entr @v1    ! (might be used later to calculate index of colliding vector)
gtw ; stw
drp ; drp

@spcloop1  ! beginning of loop 1 (scanning vectors of sprite 1)

entr @v4
gtw ; dup   ! read position vector sprite 2
gth ; swa 
clh
entr @v7
swp ; stw   ! v7 = xo sprite 2
drp ; drp
gtl ; clh 
entr @v8
swp ; stw   ! v8 = yo sprite 2
drp ; drp

entr @v4
gtw ; inc
inc ; dup   ! read radial vector sprite 2
gth ; dup
rlw ; drp
swa
jmpc @spc13
clh
jump @spc14
@spc13
ldh xff
@spc14
entr @v7
gtw ; add
swp ; drp
entr @v7
swp ; stw  ! xo sprite 2 = x_pos + x_radial 
drp ; drp
gtl ; dup
rll ; drp
jmpc @spc15
clh
jump @spc16
@spc15
ldh xff
@spc16
entr @v8
gtw ; add
swp ; drp
entr @v8
swp ; stw   ! yo sprite 2 = y_pos + y_radial
drp ; drp

entr @v3    ! get next vec of sprite 1
gtw ; gth
dup ; rlw
drp ; swa
jmpc @spc17
clh
jump @spc18
@spc17
ldh xff
@spc18
entr @v5
gtw ; add
swp ; drp
entr @v9
swp ; stw   ! v9 = xi sprite 1 = xo + x_current_vec
drp ; drp   ! (xo,yo)= origin ; (xi,yi)= arrow-end
entr @v3
gtw ; gtl
dup ; rll
drp 
jmpc @spc19
clh
jump @spc20
@spc19
ldh xff
@spc20
entr @v6
gtw ; add
swp ; drp
entr @v10
swp ; stw   ! v10 = yi sprite 1 = yo + y_current_vec
drp ; drp

entr @v4    ! prepare to scan all vecs of sprite 2
gtw ; inc   ! skip position and radial vecs
inc ; inc
inc
entr @v11   ! v11 = vec pointer of sprite 2 in loop 2
swp ; stw
drp ; drp
entr @v12   ! v12 = vec counter of sprite 2 in loop 2
entr @v2
gtw ; stw
drp ; drp

@spcloop2   ! beginning of loop 2 (scanning vectors of sprite 2)

entr @v11
gtw ; gth
dup ; rlw
drp ; swa
jmpc @spc21
clh
jump @spc22
@spc21
ldh xff
@spc22
entr @v7
gtw ; add
swp ; drp
entr @v13
swp ; stw   ! v13 = xi sprite 2 = xo + x_current_vec
drp ; drp
entr @v11
gtw ; gtl
dup ; rll
drp 
jmpc @spc23
clh
jump @spc24
@spc23
ldh xff
@spc24
entr @v8
gtw ; add
swp ; drp
entr @v14
swp ; stw   ! v14 = yi sprite 2 = yo + y_current_vec
drp ; drp

! calculate vector product of:
! (vec sprite 1) by (vector joining arrow end of vec sprite 1 to
! (origin of vec sprite 2)
!  = (v9-v5)*(v8-v10) - (v10-v6)*(v7-v9)
entr @v5
gtw
entr @v9
gtw ; sub
swp ; drp
entr @v15 ! v15 = vector product
swp ; stw
drp ; drp
entr @v10
gtw
entr @v8
gtw ; sub
swp ; drp
entr @v15
gtw
call @mult
entr @v15
swp ; stw
drp ; drp
entr @v6
gtw
entr @v10
gtw ; sub
swp ; drp
entr @v16  ! v16 = intermediate result
swp ; stw
drp ; drp
entr @v9
gtw
entr @v7
gtw ; sub
swp ; drp
entr @v16
gtw
call @mult
entr @v15
gtw ; sub  ! final vector product
swp ; drp
entr x8000
and ; swp  ! extract sign of vector product
drp
entr @v17
swp ; stw  ! v17 = sign of vector product (x0000= +, x8000= -)
drp ; drp

! calculate vector product of:
! (vec sprite 1) by (vector joining arrow end of vec sprite 1 to
! (arrow end of vec sprite 2)
!  = (v9-v5)*(v14-v10) - (v10-v6)*(v13-v9)
entr @v5
gtw
entr @v9
gtw ; sub
swp ; drp
entr @v15 ! v15 = vector product
swp ; stw
drp ; drp
entr @v10
gtw
entr @v14
gtw ; sub
swp ; drp
entr @v15
gtw
call @mult
entr @v15
swp ; stw
drp ; drp
entr @v6
gtw
entr @v10
gtw ; sub
swp ; drp
entr @v16  ! v16 = intermediate result
swp ; stw
drp ; drp
entr @v9
gtw
entr @v13
gtw ; sub
swp ; drp
entr @v16
gtw
call @mult
entr @v15
gtw ; sub  ! final vector product
swp ; drp
entr x8000
and ; swp  ! extract MSB= sign of vector product
drp
entr @v17
gtw ; xor   ! check if same sign as previous vector product
swp ; drp   ! x0000= yes, x8000= no
entr @v17
swp ; stw   ! v17 = 0 if vector products have same signs
drp ; drp

! calculate vector product of:
! (vec sprite 2) by (vector joining arrow end of vec sprite 2 to
! (origin of vec sprite 1)
!  = (v13-v7)*(v6-v14) - (v14-v8)*(v5-v13)
entr @v7
gtw
entr @v13
gtw ; sub
swp ; drp
entr @v15 ! v15 = vector product
swp ; stw
drp ; drp
entr @v14
gtw
entr @v6
gtw ; sub
swp ; drp
entr @v15
gtw
call @mult
entr @v15
swp ; stw
drp ; drp
entr @v8
gtw
entr @v14
gtw ; sub
swp ; drp
entr @v16  ! v16 = intermediate result
swp ; stw
drp ; drp
entr @v13
gtw
entr @v5
gtw ; sub
swp ; drp
entr @v16
gtw
call @mult
entr @v15
gtw ; sub  ! final vector product
swp ; drp
entr x8000
and ; swp  ! extract MSB= sign of vector product
drp
entr @v18
swp ; stw  ! v18 = sign of vector product
drp ; drp

! calculate vector product of:
! (vec sprite 2) by (vector joining arrow end of vec sprite 2 to
! (arrow end of vec sprite 1)
!  = (v13-v7)*(v10-v14) - (v14-v8)*(v9-v13)
entr @v7
gtw
entr @v13
gtw ; sub
swp ; drp
entr @v15 ! v15 = vector product
swp ; stw
drp ; drp
entr @v14
gtw
entr @v10
gtw ; sub
swp ; drp
entr @v15
gtw
call @mult
entr @v15
swp ; stw
drp ; drp
entr @v8
gtw
entr @v14
gtw ; sub
swp ; drp
entr @v16  ! v16 = intermediate result
swp ; stw
drp ; drp
entr @v13
gtw
entr @v9
gtw ; sub
swp ; drp
entr @v16
gtw
call @mult
entr @v15
gtw ; sub  ! final vector product
swp ; drp
entr x8000
and ; swp  ! extract MSB= sign of vector product
drp
entr @v18
gtw ; xor   ! check if same sign as previous vector product
swp ; drp   ! x0000= yes, x8000= no
entr @v18
swp ; stw
drp ; drp

entr @v17
gtw
entr @v18
gtw ; and  ! check if signs are different 
drp ; drp
jpnz @collision  ! vector collision detected 

entr @v7
entr @v13
gtw ; stw   ! xo sprite 2 <- xi
drp ; drp
entr @v8
entr @v14
gtw ; stw   ! y0 sprite 2 <- yi
drp ; drp
entr @v11
dup ; gtw
inc ; inc
stw ; drp   ! move to next vector of sprite 2
drp
entr @v12
dup ; gtw
dec ; stw   ! decrease vec counter of sprite 2
drp ; drp
jpnz @spcloop2

entr @v5
entr @v9
gtw ; stw   ! xo sprite 1 <- xi
drp ; drp
entr @v6
entr @v10
gtw ; stw   ! y0 sprite 1 <- yi
drp ; drp
entr @v3
dup ; gtw
inc ; inc
stw ; drp   ! move to next vector of sprite 1
drp
entr @v1
dup ; gtw
dec ; stw   ! decrease vec counter of sprite 1
drp ; drp
jpnz @spcloop1

entr x0000 ! no collision detected
ret
@collision ! if collision, return indices of vectors involved
entr @v12
gtw
entr @v2
gtw
sub ; inc  ! sprite 2 vec index = N_vec_2 + 1 - loop 2 counter 
entr @v1
gtw
entr @v19
gtw
sub ; inc  ! sprite 1 vec index = N_vec_1 + 1 - loop 1 counter
ret 


! Display a character
! input = (ASCII code of character,pointer to vec table)
! output = (update of pointer to vec table for next character)
! set address of character graphic according to ASCII code
! each character graphic is defined by 8 vectors each one
! having 8 possible direction (coded on 3 bits) and a visible/
! invisible flag bit. Hence, two 16-bit words define a character

@dispchar
entr x0061    ! convert lowercase to uppercase (lowercase graphics
swp ; cmp     ! not defined yet)
swp ; drp
jmpc @dc1
entr x0020
swp ; sub
swp ; drp
@dc1
entr x0020     ! address in char graph table= (ASCII code - 32)*2
swp ; sub
swp ; drp
ccf ; rlw
entr @charset
add ; swp
drp
entr @v2
entr x0002
stw ; drp      ! v2= counter of words per char (=2)
drp   
@dcloop1       ! first loop (for the 2 words defining a char)
entr @v1
entr x0004
stw ; drp      ! v1= counter of vecs per word (=4)
drp
dup ; gtw      ! stack=(address in char graph table,pointer to vec table)
@dcloop2       ! second loop (for the 4 nibbles defining vectors)
entr x0000     ! copy 3 MSBs of word defining char graphic 
swp ; rlw      ! to get a 3-bit number (=vector code)
swp ; rlw
swp ; rlw
swp ; rlw
swp ; rlw
swp ; rlw  
entr @charvecs
add ; swp        
drp ; gtw       ! get vector (@charvecs + vector code)
rd4 ; swp
stw ; drp       ! put (x,y) of vector into table
inc ; swp       ! increment vec table pointer 
entr x0010      ! default length-factor / 2
swp ; rlw       ! get z (visible/invisible flag) of vector
swp ; rlw       ! append z to length-factor
swa ; rd3       ! move length-factor and z to high-byte
swp ; sth
drp ; inc       ! increment vec table pointer
entr @v1
dup ; gtw
dec ; stw
drp ; drp
ru3
jpnz @dcloop2
drp ; inc       ! move to next word defining char graphic
entr @v2
dup ; gtw
dec ; stw
drp ; drp
jpnz @dcloop1
swp ; dec      ! go back to last vector (= horizontal left-to-right
dec ; dup      ! invisble) to reduce it by 2 (to make it a space between
gth ; ccf      ! this character and the next one)
rrw ; sth
drp ; inc
inc 
swp ; drp
ret

! Set position of character string to be displayed (Forth AT word)
! input= (y,x) 
! Coordinates are in vector units

@at
entr @aty
swp ; stw
drp ; drp
entr @atx
swp ; stw
drp ; drp
ret


! Display character string
! input= (pointer to character string)
! Strings are considered as sprites but with no graphic data
! This routine directly writes the sequence of vectors (that displays the
! string) in the vector table

@dispstring
entr @v10        ! v10= pointer to character string
swp ; stw
swp ; drp
entr x0000       ! beginning of measuring string length
@dstrloop1
swp ; dup
gth ; swa        ! look at character in high-byte
clh
entr x0000
cmp ; drp
drp ; swp
jmpz @dstr1      ! \0 = end of string
inc ; swp        ! increment length
dup ; gtl
clh              ! look at character in low-byte
entr x0000
cmp ; drp
drp ; swp 
jmpz @dstr1      ! \0 = end of string
inc ; swp        ! increment length
inc ; swp        ! increment string pointer 
jump @dstrloop1
@dstr1
swp ; drp        ! stack = (length of string)
ccf ; rlw
rlw ; rlw
inc              ! nb of vecs = 8*length + 1 (radial vec)
entr x0000       ! use a dummy pointer to graphic data
swp
call @defsprite  ! define sprite for string
entr @v11
swp ; stw        ! v11 = address of string in sprite table
swp ; drp
inc ; gtw        ! get address of vector table of string
inc ; inc        ! skip position vector 
entr x0000       ! set radial vector to (0,0)
stw ; drp
inc
entr x2000       ! set default length-factor and invisibility of radial vec
sth ; drp
inc              ! move to 1st visible vector
@dstrloop2
entr @v10
gtw ; gth        ! read character in high-byte
swa ; clh
entr x0000
cmp ; drp        ! check if end-of-string reached
jmpz @dstr2
call @dispchar   ! display character 
entr @v10
gtw ; gtl        ! read character in low-byte
clh
entr x0000 
cmp ; drp
jmpz @dstr2
call @dispchar
entr @v10
dup ; gtw
inc ; stw        ! increment pointer to string
drp ; drp
jump @dstrloop2
@dstr2
drp ; drp
entr @atx        ! set position of string
gtw
entr @aty
gtw
entr @v11
gtw
call @putsprite
entr @v11
gtw              ! return address of string in sprite table
ret


! Convert unsigned integer into string and display it (. Forth word)
! The string (5-character long) shall already have been displayed
! input = (address in sprite table,integer)

@dispint
inc ; gtw      ! get address in vector table
inc ; inc     
inc ; inc      ! skip position and radial vectors
entr @v12      ! v12 = pointer to vector table
swp ; stw
drp ; drp
entr @v13      ! v13 = counter (from 5 to 0)
entr x0005
stw ; drp
drp 
entr @pow10
@dspintloop1
dup ; gtw
entr x0030     ! = ASCII code of 0
swp ; rd4      ! stack is: (N,10^x,char,pointer to 10^x) 
@dspintloop2
sub
jmpc @dspint1   
rd3 ; inc      ! increase digit 
ru3
jump @dspintloop2
@dspint1       ! start to display digit
add
swp ; drp
swp            ! stack is (char,N-k*10^x,pointer to 10^x)
entr @v12
gtw ; swp
call @dispchar
entr @v12
swp ; stw
drp ; drp
swp ; inc      ! set pointer to 10^(x+1)
entr @v13
dup ; gtw
dec ; stw      ! decrement counter
drp ; drp      ! stack is (pointer to 10^(x+1),N-k*10^x)
jpnz @dspintloop1
drp ; drp
ret 




! Query joystick
! 5 first bits of result reflect activation of
! bit 4: right ; bit 3: left ; bit 2: down ; bit 1: up ; bit 0: fire
! warning: bit is at 0 if activated 

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
swp ; rlw
swp ; inc
inp ; drp
rlw ; ret


