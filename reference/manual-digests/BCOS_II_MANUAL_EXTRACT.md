# BCOS II (PCOS II Environment) — Full Manual Transcription

> Source: Olivetti BCOS II — BASIC and OCL — Programming and System Handbook
> Second Edition, September 1983. 206 pages. Extracted via Tesseract OCR (ita+eng, 300 DPI).


---

## Page 1

```
p BCOS Il Environment
) (BASIC and OCL)
Programming and System Handbook
```

---

## Page 2

```
To e

briefly describes the

who
languages. It lists and i
commands, errors, utilities, file systems: and file modules.

SUMMARY

As a reference tool it assumes that the reader is already familiar with Business BASIC,
OCS, and the BCOS Il Operating environment.

The information herein is extracted from the relevant reference manuals.

This manual is the authoritative source and will be the first publication to reflect
any changes or improvements.

REFERENCES:

BCOS ll
BASIC Language Reference manual

Code: 4000072 K

BCOS II (>
OCL - Operating Control Language Reference manual

Code: 4000092 V

BCOS II
Program Preparation and Execution
Code: 4000111 S

Distribution: General (G)

First Edition: December 1982

Second Edition: September 1983

PUBLICATION ISSUED BY:

Ing. C. Olivetti & C., S.p.A

Direzione Documentazione ( )

77, Via Jervis - 10015 IVREA (Italy)

© 1983, by Olivetti
```

---

## Page 3

```
CONTENTS

1. NOTATION CONVENTIONS
2. BASIC LANGUAGE

Obiects of the BASIC language

The BASIC statements |

The BASIC routines

The functions of the language

Field inversion methods

The ERR codes

Device-handling (statements and routines)

Table of words used in BASIC statements

Equivalence between semantics and syntax of the words
used in BASIC statements

. OCL LANGUAGE

Objects of the OCL language

The OCL statements

The YCS statements

The OCL functions

Table of words used in OCL statements

Equivalence between semantic and syntax of the words
used in OCL statements

. COMMAND SYSTEM

Table 1: BASIC command system
Table 2: OCL command system
BASIC/OCL commands

BASIC: programmer environment
OCL: program preparation procedure
OCL: debugging environment
Running environment

. ERRORS

Autodiagnostic errors
Errors signaled by the generation procedure

BASIC errors:

® Edit-time errors

@ Pre-execution errors

@ Debugging command errors

@ Program errors at run-time declared by
the BASIC interpreter

OCL errors:

® OCLCPY program errors

@ GPTE program errors

@ OCLSYN program errors

@ Debugging command errors

@ Program errors at run-time declared by the
OCL interpreter

BAL errors:
@ Program errors at run-time declared by the BAL interpreter

BCOS |! declared errors
```

---

## Page 4

```
tes of the DELPRG and

SORT: work-file dimensioning pat
Errors declared by the BCOS II utilities
SORT utility errors

. OSLEM UTILITIES
OSLEM utility programs ee
Errors signaled by OSLEM utilities

. FILE SYSTEM
Diskette/Floppy disk:
@ Generalities
@ Contents of the @ track È
@ Structure of the 5° sector of the @ cylinder
Hard disk:
®@ Generalities
@ Contents of the @ cylinder ©
Streaming tape cartridge:
@ Generalities
Volume label structure
Labels structure of the files
File library: contents of a module-descriptor

. EDIT FILE AND DRSFLE
Edit files BASIC/OCL environments
DRSFLE dimensioning

APPENDIX
A. M30/M40 BC ISO character set

B. ISO character set
@ USA - ASC Il version
@ National versions
```

---

## Page 5

```
_

NOTATION - CONVENTIONS

NOTATION - CONVENTIONS

“
L

NOTATION
CONVENTIONS:

|
```

---

## Page 6

```
È

NOTATION - CONVENTIONS

1 All the rule objects in the
ovals and circles must

be entered exactly as
shown in the text; the (E) (;))

objects in the rectangles
are the parameters used
in a statement or a
function.

2 A square indicates that
a particular key must be
pressed.

3 A fork indicates that a
choice is necessary, in this
case follow only one patch
For example. after STR,

O or J could be entered.

4 A path without parameter
indicates that the
alternative is optional’
(used to indicate that
label is optional).

5 A loop indicates a
repetition. For example,
ce-name can be repeated Con «e, ©
n times in a CAN
statement.

6 Item shown in brackets
[ ] are optional. They may
be omitted.
```

---

## Page 7

```
BASIC LANGUAGE

OBJECTS OF THE BASIC LANGUAGE

THE BASIC STATEMENTS

THE BASIC ROUTINES

THE FUNCTIONS OF THE LANGUAGE

FIELD INVERSION METHODS

THE ERR CODES

DEVICE-HANDLING (STATEMENTS AND ROUTINES)
TABLE OF WORDS USED IN BASIC STATEMENTS

EQUIVALENCE BETWEEN SEMANTICS AND SYNTAX
OF THE WORDS USED IN BASIC STATEMENTS

33
43
47
49
53
55
57

BASIC
LANGUAGE
```

---

## Page 8

```
OBJECT

num-const on default the sign: +

. n: whole number digit (0 — 9)

d: decimal digit (0 — 9)

.: decimal point

. precision factor = no of whole number
digits + no of decimal digits
range = 1— 15

6. scale factor = number of decimal digits

range = 0 — 15

AA ON

le)
Pot

Example: 3.45, 84

string-const

pr

. C = printable character from the ISO
set different than”
. string-const length < 70 characters

Example: “AB96"

hexadecimal-const hh = hexadecimal digit (0 — F)
. the length of an hexadecimal-const
must be an even number and < 68

characters

on SE IPO

Example: H“41”"

pa

num-var 1. c= any capital letter of the English
alphabet (A — Z)

2. d= value between 0 — 9

3. if a num-var is not explicitly defined,
a default value is assigned: precision

factor = 5, scale factor = 0

Example: A, C3
```

---

## Page 9

```
OBJECT

string-var

string-array-elem

Example: A (3,5), B (8)

. see 1st note of num-var
. see 2nd note of num-var
. if a string-var is not explicitly defined, a

default value is assigned: allocated

length = 16

. see ist note of num-var
. i, J = num-const/num-var
_ if num-array-elem is not explicitly

defined, a default value is assigned

for the number of elements:

— 10 for an array

— 10 colunins and 10 rows for a
rectang ‘!ar matrix

. see ist note of num-var
. see 2nd note of num-array-elem
. if string-array-elem is not explicity

defined, a default value is assigned:

— 10 for an array

— 10 columns and 10 rows for a
rectangular matrix
```

---

## Page 10

```
String-exp

dì
A
2A

Elementary Example: 16 + LEN (A$)
Complex Example: (CCA)*B+10—C)-160*(C+2)/(A+B)*35

numeric-
-operand

string-
operand

Example: 189 LET vg = X$ + YS

—

1. (+) on default the sign is +
=. numeric-operand= num-const, num-var,
num-array-elem, numeric result of a

function

1. string-funct = String result of a function
2. + is the chaining function

ot
```

---

## Page 11

```
NOTES

1. (£) on default the sign ist
gi numeric-operand = num-const,
num-var, num-array-elem, numeric

confr-exp
result of a function

numeric-

numeric-
operand Bh a Tag ; operand

Example: 509 \F T2 = ERR THEN 10900
699 IF A<= 8 THEN 700
809 IF AS > BS THEN 159
```

---

## Page 12

```
YY

THE BASIC STAT,

CALL

Transfers control to
the specified system
routine

Terminates the
execution of a
Program and begins
the execution of
another specified
program

Defines the program
variables whose
values can be passed
on to chained
programs

Closes one or more
files previously
opened with: OPEN

EMENTS

DEVICE

2

Example: 50 CALL “BEEP”

CCHAIN)—pf Provan
name

Examples: 50 CHAIN AS
60 CHAIN “B”

Examples: 100 CLOSE :3
200 CLOSE :1 :8

NOTES

1. a CLOSE can simultaneously
close files belonging to
different devices
```

---

## Page 13

```
se = |

DATA Creates an internal (CDATA _)
file, within the

program, of numeric
and string data

Example: 200 DATA 123, “ABCD”, “001”, “AAA”, - 22
```

---

## Page 14

```
sli numeric

numeric

img

Examples: 20 DCL 5.3(C,D)
30 DCL 10 A$,7.2 A1,1 P(),25 DS

L allocation-length = { — 256
2. precision = 1 — 15
3. scale = < precision. If the scale factor is not specified it is = 0
```

---

## Page 15

```
OL

DELETE

FUNCTION: Erases a record logi: ily from a file

DEVICE: FDU/HDU

FORMAT:

file
designator

KEY key-value

—_

e.
PE

Examples: 30 DELETE :2 KEY 4 EOF 159
60 DELETE :5

ARM os ra e

NOTES: 4. file designator = 4-99
2. DELETE operates on files opened in UPDATE or UNDEF modes

3. DELETE file-designator = erases the last record read
4. line-num = line no. to where control is passed upon EOF
```

---

## Page 16

```
LL

FUNCTION:

FORMAT:

Examples: 20 DFR. B$,C$,A( )
70 DFR 4: 20,60,C,50

NOTES:
2. the record le;

Defines a record structure

1. rec-designato:

[ signifinani lar ; tal significantk_s
figide 3 field

non-significant
field

3
2d in DFR must be: 2 — 256 bytes
```

---

## Page 17

```
FORMAT

Defines the
dimensions of an
array

Examples: 20 DIM A(10)
50 DIM B$(30,40)

Defines the end of a

program and closes
all open files

Example: 200 END

Defines the beginning
of a loop initial
var value

Example: 50 FOR A=1 TO 10

im

rows and columns are
ositive whole numbers
Aefault: columns = 1

1. default: step increment = 1
2. 15 levels of nesting are
possible
```

---

## Page 18

```
IF...THEN

Transfers the
program control to
the specified
subroutine

1. line-num is the line number
that contains the first
instruction of the
Subroutine

GOST) EPL ine num
CDs)

Examples: 10 GOSUB 100
30 GO SUB 50

Transfers program .
control to the
specified line
number

. line-num is the line number
that identifies the
instruction to which
program control is to be
passed

Examples: 10 GOTO 80
30 GO TO 100

SEE CED + eae

Example: 70 |F A=2 THEN 100

Transfers Program
control to the
Specified line-
number only upon
verification of the
Specified condition

‘e-num is the line-number
‘0 which program control
i passed if the specified
-ondition is true
```

---

## Page 19

```
vl

FUNCTION:

DEVICE:

FORMAT:

Example: 50 ’LLLLLL’b999.99

NOTES:

Specifies a predefin

CRT/PRT

ed format of print

4. after the keyword “:” there is no need fora blank; if th

. 9: prints the num
_ g/*; prints b/* for
. the sign +/— can
. the picture or i
. L: prints a total 0
. . decimal point

. the character, ca

anon

N

n appear anywhere between 2 of the

e blank is used it is considered a literal-field
eric digit (0-9) including insignificant zeros Lea

insignificant zeros
appear only once, either before or after the picture
is to be used to print string data
f characters equal to the number of 1

following characters £ 9 . ui

9. literal-field cannot contain characters that appear in the picture except for L.

Pte

È) 9

————a=—
```

---

## Page 20

```
SL

image input Specifies a
Predefined format of
input

1. see 1st note of image print

2. literal-field on display or on

the status line can have a

max. len. of 16 characters,

while its max Jen. on the
Other lines of the video is
equal to the max. len. of the
video - 1

3. £/9: optional/obligatory
input of a numeric character

4. .: decimal point

5. the - sign indicates that the
number is negative. If absent,
the number is considered
positive

6. the picture or ‘Lis to be
used to input String data

7. L: input a total of Characters

‘ = to the number of L - 1
8. see 9th note of image print

Example: 80 : NOME CLIENTE CEELLELEDE PREZZO : £££ i
```

---

## Page 21

```
FUNCTION: Assigns the values entered through the keyboard to the variables specified in the instruction

FORMAT:

line-feed
num

co) 8

Examples: 50 INPUT, A, TAB(5,10)

. default: row = current row i
,i moves the marker to the beginning of the next video zone
.: «if put between 2 elements it is a separator. if put at the end of the statement it leaves the marker in the current position

after an input without an ending, or ; the marker is positioned at the 1st columns on the next line
. TOF = clears video + the marker is positioned on row 1 and column 1 :
. TOFP = see TOF (clears video except for the protected fields)

row must be < 24 i
8. TAB (,0) = the marker is positioned on column 10 of the status line. The

NOASEN

first input variable is displayed on the status line.
```

---

## Page 22

```
DI

-

egg e
NAME: INPUT USING

FUNCTION: Assigns to the variables specified in the instruction, the values entered through the keyboa
associated “IMAGES”.

DEVICE: KEY

FORMAT:

NOTES:

Example: 140 INPUT USING 160 TOF .A

OMNAHAWNH

variable

. default: row = Current row
, OF; placed between 2 elements is considered a separator

at the end of the Statement moves the marker to the beginning of the next video zone
; at the end of the statement leaves the marker in the current position

see 4th note of INPUT
- see 5th note of INPUT
see 6th note of INPUT
« See 7th note of INPUT
- See 8th note of INPUT
```

---

## Page 23

```
gl

FUNCTION: Assigns to the specified variable the value

FORMAT:

vela
name È

Examples: 10 B = aC
20 LET A = 238,8749
760 LI, L2 = Y W,2) + 53

expressed to the right of the = sign
```

---

## Page 24

```
ina

DEVICE

Locks one or more
records belonguig to one
or more files identified by
the file designator
Parameter.

1. file designator: 1-99
2. the ‘LOCK’ statement
is Operating ina
‘multi’ environment
Only; not operating in
a ‘mono’ environment

ile-
designator Ca ISS

Examples: LOCK: 1A :2A
LOCK :2B () :1c
```

---

## Page 25

```
Defines the end of
a loop control-var

Example: 50 NEXT B

ON..GOSUB Transfers program 1. num-exp; only the whole
control to num-exp number pertion of this fiel’
subroutine after is considered in
evaluating the ON..GOSUB, the decima

specified numeric portion is transferred in ine
expression desidered line-num
_ line-num is the line number
from which a subroutine is
to begin

the instructions
identified by the
specified line
numbers after
evaluating the
specified numeric

expression Examples: 40 LET F = 1,3

50 LETM= 3,4
60 ON F +M GO TO 100, 140, 180, 470

ON...GO TO | Transfers program 3
control to one of
```

---

## Page 26

```
ter_ ++

FUNCTION: Opens a file

Example: 50 OPEN :3 DEV “CRT”

1. file-designator = 1 — 99
2. device-name = CRT
3. OPEN is optional if the program does not use the system functions COL and LINE
```

---

## Page 27

```
OPEN

FUNCTION: Opens a file

DEVICE: FDU/HDU

FORMAT:

file i
designator file-name

("==
INPUT

(44

aaa
error length 14

È i OUTPUT s
4 APPEND .

UNDEF

Examples: 20 OPEN :2 FLN “ARTCOS” UNDEF DEV “UND” 1
100 OPEN :4 FLN “WORFL” OUTPUT DEV “HDU2” O 30

1. file-designator = 1-99 4. device name:

NOTES: 2. process-error = 0 for standard processing 1 for non standard — FDU - HDU - UND; the search is performed on all the disks/
processing; default value for process-error is: 0 i data sets on line
3. record lenght = 2-256. This parameter can be specified only ifitisa - FDU1 — FDU4
work file and if it is opened in OUTPUT mode - HDU1 — HDU64
- DCUI — DCU4

- DCU; accepted as HDU.

C @ n 9

iii zr”] ego; e et (“['e'"t{:s<ee<yTie
```

---

## Page 28

```
IA

NAME: OPEN
FUNCTION: Opens a file

DEVICE: PRINTER

FORMAT:

file
designator

Examples: 10 OPEN :1 DEV “PRT4” 10 50 60
20 OPEN :2 DEV “PRT4” 15 60 50
30 OPEN :3 DEV “PRT6”

1. file-designator = 1-99
2. device-name = PRT4 for sprocket 1 - PRT6 for AFF (automatic front feed)

3. the left-edge is between 0 and the lenght of the platen. Default value = 1
4. page-size = 0 — 255. Default value = 72
5. line-size = dimensions of the print line. Default value = 132
```

---

## Page 29

```
ve

NAME: PRINT

FUNCTION: Displays data in the standard format
DEVICE: CRT
FORMAT:

line-feed
Soa _‘
visual-
— attribute —
ci

Examples: 10 PRINT MODE (“H”); TAB(1);“NAME”,“SURNAME”,“COD"”
20 PRINT MODE (“H”);“CUSTOMER”

NOTES: 1. default: row = current row - H high light - B blink - U underline - R reverse - D deleting of visual
2. ,; moves the marker/head to beginning of the next video/print zone characters - S special visual characters. (*)
3. ;; - if placed between 2 elements it is considered a separator P protect (must be associated with the TOFP command)
- if placed at the end of the statement it leaves the marker in 6. file-designator = 1-99
the current position 7. TOF = clears video + the marker is positioned on row 1 and column 1
4. after a PRINT that does not end with a, or ; the marker is 8. TOFP (clears video except for the protected fields)
positioned at the first position of the next line 9. row must be
5. visual-attribute is formed by a sequence of the following characters: 10. TAB (.@) = the marker it is positioned on column 10 of the status line

(«) Special visual characters (hexadecimal code): — (horizontal line) EO or CO or DO; I (vertical line) E4 or CC or D4; L (left angle down) C8 or D8 or DC;
“NORMAL” visual mode.
```

---

## Page 30

```
PRINT USING

FUNCTION: Displays data in the format defined by the image clause

FORMAT:

PRINT)» RIONE USING

Examples: 110 PRINT USING 120 A
170 PRINT USING 150 TAB(5); 5; TAB(35); “HK”

1. default: row = current row
2. line-num is the line number of the associated image
3. , or ; if placed between 2 elements it is considered a separator
4. , placed at the end of statement moves the marker to the
beginning of the next video zone
. ; placed at the end of the statement leaves the marker in the
current position
. after PRINT USING that does not end with ; or , the marker is
positioned at the first Position of the next line

. See Sth note of PRINT

. file-designator = 1 — 99
. See 7th note of PRINT

. see 8th note of PRINT

- See 9th note of PRINT

. see 10th note of PRINT
```

---

## Page 31

```
PRINT USING

DEVICE:

FORMAT:

96

FUNCTION:

Prints data in the format defined by the image clause

PRINTER

file
designator

Examples: 100 PRINT USING 200 TAB (5), 5, TAB (35), “AA”;

NOTES:

{40 PRINT USING 200 A$,B$,C$

iii r—_—_—tn cr.

1. default: row = current row

2. line num is the number of the associated image

3. , or; if placed between 2 elements it is considered a separator

4., placed at the end of statement moves the head to the
beginning of the next print zone

5. ; placed at the end of the statement leaves the head in the
current position

Cc aa

[on]

o

6. after PRINT USING that does not end with; or, the head is
positioned at the first position on the next line

7. file designator = 1 — 99

8. TAB = the print-head is positioned in the position specified by
the parameters: column and row

9. LF = performs a number (line-feed-num) of interlines

10. TOF = tof of page

da) dh)
```

---

## Page 32

```
NAME: PRINT

FUNCTION: Prints data in the standard format

DEVICE: PRINTER

FORMAT:

designator

Examples: 50 PRINT “A”;“B”:“C”; ARE THE FIRST 3 LETTERS OF THE ALPHABET”
60 PRINT “NAME”;“SURNAME”
70 PRINT “COD.”,“CUSTOMER”

NOTES: 1. default: row = current row
2. ,: moves the head to beginning of the next print zone
3. ;: - if placed between 2 elements it is considered a separator,

- if placed at the end of the statement it leaves the head in
the current position

4. after a PRINT that does not end with a , or ; the head is
positioned at the first position of the next line

5. file-designator = 1-99

6. TOF = TOP OF PAGE
```

---

## Page 33

```

```

---

## Page 34

```
67

RETURN

Transfer program
control to the
instruction that
immediately follows
the last GOSUB
instruction

Example: 70 RETURN

Memorizes a record
in the file defined by
the file designator

1. file-designator = 1- 99

2. WRITE is used on files
opened in: OUTPUT, APPEND,
UNDEF MODE

3. line-num: is the line-number
to which program control is
transferred ia an EOF
condition. If not specified,
the next statement is

executed

designator

Example: 100 WRITE :2 REC 4 EOF 900

file A
REWRITE (>) C REC) rec-num

Example: 90 REWRITE :1 REC 2

Updates the last
record read in the
specified file

. file-designator = 1- 99

2. REWRITE is used on files
Opened in: UPDATE or UNDEF
MODE
```

---

## Page 35

```
oe

FUNCTION

Causes the
executing program
to stop and sets the
system ina STOP
status

Assigns to the
specified variables
the corrisponding
value contained in
the program
internal file

1. executio’
pressing

intinues by
a RUN key
```

---

## Page 36

```
LE

NAME: READ

FUNCTION: Reads a record from the file specified by file-designator; assigns its content to the lists of variables defined by the instruction
associated with DFR.

DEVICE:

FORMAT:

ile-
designator

rec-num

Exemple: 80 READ : 3 REC 4 EOF 900
180 READ : 3 KEY B$ EOF 900 LOCK

NOTES: 1. file-designator = 1-99 3. READ is used on open files in INPUT, UPDATE or UNDEF
2. program line to which pass control in case of end-of-file 4. The lock option, in a multi-keyboard environment, locks ther.
Or non-existant record. (if the has been opened in UPDATE/UNDEF mode)

to be read:
```

---

## Page 37

```
(43)

UNLOCK Releases previously
locked records or

files.

designator

{ device-

Exemple: UNLOCK :2

UNLOCK FLN “ARTCOS' DEV “HD3"

Updates the EOD of
the shared file
associated with the
file-designator
parameter.

DO esitato PO

. file-designator: 1-99
. device-name:

©

. UNLOCK is operating

_ file-designator: 1-99
. WEOD significant only

- FDU

- HDU

- DCU

- FDU1 - FDU4

- HDU1 — HDU64
- DCUI — DCU4
- UND

in a ‘multi’
environment only, not
operating ina ‘mono’
environment

for open files in
APPEND/UNDEF mode
The ‘WEOD’ routine is
operating in a ‘multi’
environment only, not
operating in a ‘mono’
environment.
```

---

## Page 38

```
-

THE BASIC ROUTINES

Produces an acoustic
signal which lasts
300 thousandths of a
second.

Transmits the
operating or check
command (contained
in ‘command-code’)
to the peripheral unit
identified by ‘per-id’.

Converts a number
(positive integer)
from decimal to
binary

Optional
peripheral

FORMAT

CCALE )—>(")}-»CBEEP_)—9("’)

Exemple: 140 CALL “BEEP”

ni;
-\O+{r=xh0

Exemple: 100 CALL “CMD” (A, 3)

Exemple: 160 CALL “CVB” (A, 1, A)

1. per-id: 9-31
2. command code 1-3

1. lenght = 1 - 2 bytes
2. numeric-operand =

DI

13 256 if
lenght = 1
1-65535 if

lenght = 2
```

---

## Page 39

```
ve

Converts a number
from binary to
decimal

1. lenght = 1 - 2 bytes
2. the current lenght of the
string-operand must be = to
“lenght”

1. sign-tran is:

- @ if the sign is to be
included

- 1 if the sign is to be omitted

Allows the handing
of a numeric value as
if it were a string
variable with the
capacity of
eliminating the sign

Example: 200 CALL “CVNS” (CSN” (C, @, B$)

Allows the handing of
a string value as if it
were a positive

numeric variable

CDA OPO CED POO
i ee PU

Example: 210 CALL CVSN" (B$, Z)
```

---

## Page 40

```
FORMAT

NOTES

1. file-designator: 1-99
2. Value of the ‘new mode’
parameter: C

The system routine
DFIO opens a file
(sequential or keyed),
pointed by the file-
designator using the
‘C’ mode.

This mode sets the
file for record append
from several users.

Performs the division
between 2 numbers,
providing the
quotient and the
remainder

Example: 220 CALL “DIVR” (N,D,Q,R)

Ejects the card,
upward and
downward.

Example: 40 CALL “EJEC” (1)
```

---

## Page 41

```
FUNCTION DEVICE

Searches for a file FDU,
record, pointed by HDU
file-num, on the basic =
of a search mask.
Example: 50 CALL “FIND” (10,A$,“L',C,B,F)

Hardware
environment
identification

magnetic-

unit

. FIND is used on open files in
INPUT, UPDATE or UNDEF
. file-num = 1-99
. mode = G (>)
E (=)
L(<)
. result input value:
O (dynamic SCAN)
1 (SCAN from the beginning of
the file)
output values:
@ (not found record)
1 (found record)
5. lock-param =
1 (explicit locking)

1. magnetic unit and
environment supporting the
result of the test.

Exactly:

- magnetic unit = 4 for FD

- magnetic unit = 5 for HDU

- environment = 1 for
mono-user
```

---

## Page 42

```
FUNCTION: Enters the card with or without

DEVICE: Printer

Example: 50 CALL “INCL” (5)

1. position-value: 2. on PR 1480, if the position value i
-2 card entering with minimum card heading (65 pos. value S module lenght) the “INCL”
- minimum card heading = position value < Page size:
positioning is on the line indicate by position value.

$ not included in the Provided range

routine is not operating.
```

---

## Page 43

```
Enables the character
insert and transfers
its code into the
specified variable

CER) +++ ii HO

Example: 45 CALL “KAC” (RS)

1. MCP performance resets the
restart condition

Performs the
protection of the user
memory on DRSFLE

ge

Examples: 50 CALL “MCP”
: 450 CALL “MCP” (2000)

Assign to num-var the
record number
pertaining to the last
record within the
specified file handled
by an! O operation

1. filenum =1- 99

2. after a SCAN results in a
missing record the NREC
value is equal to 4

3. if no I/O operation has been
performed the function

returns the LRU value
```

---

## Page 44

```
6£

FUNCTION

DEVICE

Printer

- This routine is not operating
on the PR 1480

—

Punches the card
edge, where the
current print line is

| Transfers data from
the input section of
the peripineral
specified by per-id to
the list of the
variables specified
by DFR.

=

Optional
peripherals

- per-id: 0-7 (for peripherals
connected to the
1st channel)

16-23 (for peripherals
connected to the
second channel)

. Lenghts of data to be

transfered from the peripherals
to the Central Unit cannot
exceed 512 bytes

“CiD Ol ceria

rec.-num È
KW
string-var

N

Example: 100 CALL “RECV” (4,2)

Performs the function
of simulating the
restart condition

CALL YA) ANTI)

Example: 65 CALL “RTR”
```

---

## Page 45

```
CRT 1. action1=1
action 2 = 2

2. CALL “SCRN” (1, top-timit,
bottom-limit) allows the
definition of a screen window

3. CALL'‘SCRN” (2) causes the
current CRT screen page to
be reproduced on the printer.
Frame characters arre not
printed out; visual attributes
are ignored

4. top-limit = 1- 23

. bottom-limit = 2 — 24

CRT screen handing

Example: 70 CALL “SCRN” (1,5,18)
100 CALL “SCRN” (2)

. per-id: 8-15 (for peripherals
connected to the first
channel)

24-31 (for peripherals
connected to the
second channel)
2. Lenghts of data to be
transfered with a single
“SEND” cannot exceed
512 bytes.

Optional
peripheral

Transmits data
contained in the
variables defined in
the DFR (identified by
rec-num) or the string
of characters
contained in string-
var, to the peripheral
identified by the
per-id parameter.

Example: 100 CALL “SEND” (24,2)
```

---

## Page 46

```
FUNCTION NOTES

CCALL)—>(") TEAM O
Example: 85 CALL “TEST” (A)

Frees temporaneasly | Printer
the print field card,
thus making platen SETA (2) Cree) @
print available
Example: 50 CALL “TEJC”

Provides values to
the ERR function,
according to the
current status of the
specified peripheral
unit.

Analizes the
presence of keys in
the keyboard butter

1. the output of num-result will be

2 at least one key code is
present

1 the first or the only
available code is for errors

2 the keyboard buffer is empty

Optional
peripherals.

- per-id: 9-31 (identifies the
peripheral input and output
sections)

. TIO provides the ERR function
with the following values:
ERR = @ (peripheral unit is
ready for dialogue with the
Central Unit)

ERR = 1 (peripheral unit out of
service)

ERR = 2 (peripheral unit
connected in local)

N

AMA CTS OO] peri 0

Example: 30 CALL “TIO” (8)
```

---

## Page 47

```
ov

FUNCTION

Translates a string
according to the
specified table and
saves the result in a
second string

table

Example: 90 CALL “TRAN” (AS, BS, CS)

operand
result
```

---

## Page 48

```
THE FUNCTIONS OF THE LANGUAGE

FUNCTION

Provides the current O) E) desinititor O 1. file-designator = 1 — 99

print/display column

Example: 40 IF COL (:1) > 65 THEN 300

Provides the result. of 1. for ERR codes see table

the last I/O operation

Example: 50 IF ERR = 2 THEN 200

Extracts a sequence of ; string- start-
characters from an position

alphanumeric string

end-
position

Example: 60 LET AS=EXTS (CS, 4, 5)

Indicates the closing 1. Key values are:
key of the preceding 01 [so] dn [Ss]
or ‘or

keyboard input
2 for [s2] 3 for [=]
5 for 6 for
8 for Px] 9 for

Example: 70 IF KEY = 0 THEN 150 ee rl
0
```

---

## Page 49

```
FUNCTION

Provides the number of

characters contained
in the specified string © operand O)

Example: 80 LET A = LEN (A$)

Provides the current . file-designator = 1 — 99

print/display line LINE O) © desi 0)

Example: 90 IF LINE (:7) = 60 THEN 140

Converts a string of . the string to be converted
numeric characters string- must not contain a file
from character format (PACK) (0 Q)

to a packed format
adding a+ sign (i
Example: 270 A = PACK (A$)

Provides the number of . ROOM must be preceded by

available records ROOM) @ @ O) an OPEN
esignator

(unwritten) in the . file-designator = 1 — 99
specified file

Example: 100 IF ROOM (:1) > 5 THEN 300
```

---

## Page 50

```
FORMAT

Arithmetically rounds
the value of a numeric
field according to the
specified precision
and scale factors

Example: 110 LET C = ROUND (A, 3, 1)

Tests the restart
condition

Example: 180 IF RST = 1 THEN 400

Indicates the position

occupied by the first sub-string
character of the

sub-string* within the

string-operand

* when requested

Example: 260 LET C = SNC (CS, DS, 2, 1)

1. decimal part is absent

. RST values are:
: no RESTART conditions
: verified system RESTART
condition
. verified program RESTART
condition

. SCN value is equal to @ if:
- sub-string is absent when
requested
- start-position > current
length of string-operand
```

---

## Page 51

```
oF

FORMAT NOTES

4. the sign of the number is
num-
GONPACKS >) O

Converts a numeric
value from a packed

format to a character
format

always ignored

Example: 180 LET AS = UNPACKS (C)
```

---

## Page 52

```
o — e LS

FIELD INVERSION METHODS
NAME: INPUT

FUNCTION: The CALL statement allows fields to be inverted in input

DEVICE:

FORMAT:

Example: 1, CALL “MODI” (“INPUT”, 1)

1. numeric-exp: 2. The “input inversion method” condition has no effect on the numeric
- 1 (activation of input inversion method) INPUT and USING INPUT
- @ (activation of normal input method) 3. An “INP” CALL which defines a pre-existing method is considered
non-operational by the system.
```

---

## Page 53

```
FUNCTION: The CALL statement allows the variables or array elements indicated in the list to be inverted in memory.

FORMAT:

INVERT

Example: CALL “MODI” (“INVERT”, A$)

1. If a variable is not complete, it is considered to be filled by a blank as for as the allocation lenght.
```

---

## Page 54

```
lo — A wa

THE ERR CODES

DEVICE: FDU/HDU

COMPILED BY: MEANING ACTION RE-ENTRY

READ, WRITE, REWRITE, DELETE, | I/O operation correctly executed Expected result
FIND, MCP

REWRITE MCP DELETE EOF on DRSFLE No protection given Next statement

OPEN, READ, WRITE, FIND, Physical error on disk (non standard treatment) No operation Next statement
REWRITE, DELETE, MCP

READ, WRITE, DELETE, KEY, FIND | EOF of a data file ora missing key (the EOF function must No operation Next statement
be explicitly defined)

READ FIND The length of the record read is less than the length of the Reads record and gives Next statement
DFR record values to variables defined in
corresponding DFR

WRITE, REWRITE, DELETE The record length of the file is different than the length of Record is not stored Next statement
the record defined in DFR
```

---

## Page 55

```
DEVICE FDU/HDU

BE — a

i Pa

wit
a È

Expected result (alters the Next statement
7F code of the first assigned

variable)

invalidated record (deleted)

Record is not stored Next statement

Attempting to add a record past the point of EOF (file is full)

os

The last part of the record is Next statement

not read

The lenght of the record read is —— than the lenght of
the record defined in DFR

Sector release or
Next statement

Record processing not
possible

Record to be locked already locked

Sector release or
Next statement

File cannot be locked (request in RESERVED mode) File processing not possible
```

---

## Page 56

```
DEVICE FDU/HDU

MEANING

File to be locked (RESERVED mode) is not present in
the volume

No record can be locked

Number of record requested for locking exceeds the
maximum allowed

ACTION

File processing not possible

Record processing
not possible

Record processing
not possible

RE-ENTRY

Next statement

Next statement

Next statement
```

---

## Page 57

```
PRT

FD/HDU KEY

CRT
53

INPUT USING
PRINT USING

REWRITE
UNLOCK

OratrwswZzen

(SANILNOY GNV SINIWILVIS) SNMGNVH 39IA30

e o ~ ~
```

---

## Page 58

```
MENTS

TABLE OF WORDS USED IN BASIC STATE

action 1
action 2
allocation length

argument

array
bottom-limit
column
command-code

comment
common-data
constant
contr-var
convert-table
data-item
device-name
dividend
divisor
end-position

environment
file-designator
file-name
file-num
increment

initial-value
key-value
left-edge
length

limit
line-feed-num
line-num

line-size

literal-field
lock-param

mask

mode

new-mode
new-record-length
non-significant-field
nth-occurrence
num-exp
num-operand

num-result

numeric-element-
-name

Partition-value
page-size

defines a screen window
reproducer on the printer the current CRT screen

maximum number of Characters that can be contained in a string
variable or array

argument trasmitted to the system routine

name of vector or rectangular matrix (numeric or alphanumeric)
defines the last line or a screen window

number of columne in a rectangular matrix

operating or control command transmitted to
identified by “per-id”

comment string

program variable which must be transmitted to chained programs
sequence of non-variable Characters
control variable for FOR - NEXT loops
string which contains a conversion table
information to be Printed/displayed
name of the Processing device

dividend

divisor

indicated the end of the sequence of Characters that must be
extracted

system environment

Specifes the file defined in OPEN

name of file to be processed

file on which inquiry must be performed

value with the control variable of a FOR - NEXT loop is increased or
decreased

initial value for the control variable of a FOR - NEXT loop
key of the record to be read or deleted

left edge of the Print form

number of bytes in a String variable

value that indicates the end of a FOR - NEXT loop
represents the number lines to be skipped by the marker
program statement number

maximum length of the print line

input/display/print guide for a variable

record locking parameter

mask to search record

type of control to use with the search

sets file for record append from several users

new length of the records ina work-file

length in bytes of a non-significant-field

indicates the which Position within a Sub-string mest be found
an expression which produces a numeric result

It is the value of the numeric field to be CONVERTED/ASSIGNED/
ROUNDED

holds the result of a test

element of a numeric vector or rectangular matrix or a numeric field
identified by a name, whose value can Change during the execution
of a program

line number on which the print head is positioned
Number of print lines that can be contained on a form

the peripheral unit

55
```

---

## Page 59

```
per-id
pgm-name
precision
process-error
quotient

relational-exp

rec-array
rec-designator

rec-num

rec-order-num
remainder
restart-line

result
row

scale
sign-tran

significant-field
start-position

string-element-
-name

string-exp

string-operand

string-result
string-var

substring
system-ruotine
top-limit
variable

visual-attribute

I/O peripheral unit section

name of program name of to be executed

total number of digits in a N
direction on treating phisica

quotient

comparison expression whose value is true or fals

order numbers of records

record number to be

DFR number pertaining to the recor
the PU/CU

message sent by
record number to be
remainder

represents the labei o

to be directly transfe

specifies if the searc
sequentially starting

number of rows in & rectangular i

a vector

number of decimal digits n a num
specifies if the sign of a numeric fi
significant field of a record

rapresents the starting position of th

extracted

element of an alfanumeri
identified by a name

of a program
expression

read

read

rred

n wi! be done dynam

f tive program statement to whicht

at the beginning of the file

c vector or rectangular ma
wi.ose value can change durin

which contains an alphanumeric result

umeric costants or variable

| error that cannot be restored

e record identifier
to be locked as array elements

d being able to receive/transmit the

he control has

ically (directly) or
atrix or the number of elements in

eric costant or variable
eld musi De transterred

e characters to be searched/

trix or a field
g the execution

- is data in alpha numeric format, that is being processed
d being able to transmit data from the CU to

- is the string operan
the PU

variable which contains the result of an operation

string variable

specifies the sequence of characters to be

searched

it is the system routine that is being executed

defines the first line of the

is a program variable
visual attribute

56

screen window

ere een i me
```

---

## Page 60

```
n
Y

om,

lm

EQUIVALENCE BETWEEN SEMANTICS AND SYNTAX OF THE WORDS USED IN BASIC STATEMENTS

SYNTAX-SEMANTIC

uo

sl

EQUIVALENCE
VALUE
action 1/2 e
allocation length x e
è argument ° e e ° e o .
array i i -
bottom-limit e oe 6° a A
column ° o o i ; i
command-code e e e Di A. N 7 i
comment E 7 È e
common-dat e @ i
constant e
contr-var e i
convert-table e °
data-item e e e@ ° e i
device-name @ e
dividend ° e @
‘divisor e e e
end-position e e e x
environment e e ~
file-designator @
file-name @ e
ile-nu e _ è. @ _ _
increment n
initial-value
key-value e e ° 9 e
left-edge e
length e e e
limit
line-feed-num e e e
line-num e
line-size ° ~ 7
literal-field i
-fock-param e ° ° i
magnetic-unit e °
mask : i 6 ° 7
mode x e @ i
new-mode 0 7 = e sa
| new-record-engit @ e e 0
‘ nomsignificant-field CI i
nth-oceeace e e e a
è rakm-exp a e e ® i
‘num-operand @ e e
‘num-result e e
numeric-element-name e e
ig e

page-size
```

---

## Page 61

```
Se ~ dd J

e "re ——_ TE nee sci

NUMERIC STRING
SYNTAX-SEMANTIC

EQUIVALENCE ° |
CONST ARRAY CONST ARRAY EXP VALUE

pa:tition-value ° e
per-id (i e
pim-name_

proce. <.or e e
| quetien: | a i e
i rec-array i I

G | memi - 3
o rsiauonal-uXp

rec-designator 0 ” .

rec-num ' è. e
remainder © a Di @
rec-order-num °° 6°
restart-line eo |

result i e
row e e
scale @

sign-tran e °
significant-field Li
substring

start-position e e

string-element-name

string-exp

string-result

string-operand

string-variable

system-routine

top-limit e

variable

visual-attr
```

---

## Page 62

```
FORMAT

| Example: LET LYFDN = “FD2", LYFLN = “ARTCOS”, LYTYP = “D”,
LYMOD = “S”; YCS 02;

Name of the drive file searched on all volume
on which the file on line
should the FDU/HDU file searched on all FDU/HDU
searched FD1 + FD4 floppy-disk on drive 1+ 4
HD1 + HD64 data set configured on HD
DCU HDY is assumed
DC1 = DC4 HD1 + HD4 is assumed i
134 If the bootstrap unit is HDU,:
HD1 + HD4 is assumed.
If the bootstrap unit is FDU,
FD1 + FD4 is assumed. ì

Error handling N . not standard handling
Ss standard handling

file name ccccce cccccc = file name (the fi FUN = “St” if
character must b : YP x “S” or "C"
alphabetical) ;

file type system library
data file
user library

i OUTPUT VARIABLE

file status i file is present if the input variable
file is absent LYMOD “S”
disk is absent on drive LYPRE assumes value O 4
the function is not supported

drive number ; disk on drive 1+ 4

containing the È * | data set HDn (n= 1 + 64) ;
disk or number of di
the data set with ;
the specified file i

file "gt cccccc = file name

type of fi und : sequential data file

if “D' has been work file

theffinput unsorted keyed file
gcharacter sorted keyed file

unsorted index file
sorted index file

»

oe

\DOOZS

a

cccccc = name of index/data if LYTYP = P or W,
file associated to the LYPFN = "B'
data/index file to be
checked
the file is not an keyed
file

-‘Fassociated file

(el
(2)
do
o
o

PR.

file cole 2 + 256 = record length not significant parameter if

length (bytéS) LYTYP = $7" oro”
max number of not significant parameter if è
recordsonthe file LYTYP = “$" or “C”

positional number not significant parameter if
of last record on LYT “S" or “C”

the file ,

key displacement not significant parameter if :
from the LYTYP =:P or W 2
beginning of data i °
record è

name of the device | FD1 + FD4 _ | floppy-disk on drive 1 + 4 parameter significant if
(type and number) | HD1 + HD64 data set on the HD LYPRE = @

ibrar:
```

---

## Page 63

```
OCL LANGUAGE

OBJECTS OF THE OCL LANGUAGE

THE OCL STATEMENTS

THE YCS STATEMENTS

THE OCL FUNCTIONS

TABLE OF WORDS USED IN OCL STATEMENTS

EQUIVALENCE BETWEEN SEMANTIC AND SYNTAX
OF THE WCRDS USED IN OCL STATEMENTS

61
65
79
93
95
97

OCL

LANGUAGE
```

---

## Page 64

```
Pag ce

19

Y _ e wh
OBJECTS OF THE OCL LANGUAGE

Positive whole number -

(integer)
Example: 375

1. n=character @ —9
2. length of number = maximum
15 characters

number of
characters in the
number

numeric

1. n=character 9 — 9
c = non-numeric ISO
character
2. string length = max 63
characters
3. if the length of the string is
< 15 it must contain at least
1 non-numeric character

number of
characters in the
string

string String of ISO characters

Example: 3ACZX

, ad

Example: 2F72

1.x=@-9,A-—F

2. field length; max 8 pairs of
characters

3. the field always contains an

even number of characters

hexadecimal Hexadecimal quantity number of pairs
of characters in the

field

1. n= characters0—9
c = must be a non-numeric
ISO character different from b

OCL label

Example: LAB

‘bie fo “ ¥
```

---

## Page 65

```
CONSTANTS

VARIABLES

num, const

Numeric constant

Example: “375”

number of
Characters in the
number + 2

string, const

variable

String constant

Numeric or string OCL
variable

4G as We

Example: “3ACZX”

Example: JNOME
PLIBN

number of
characters in the
string + 2

6 + the number of
characters in the
identified number/
string

. © = Capital letter of English

alphabetic

. SCEA area variables:

SCOCO
SPRGN
SDATA
SPAGE
SLREC
SLFED
SSMCP

. SPRGN/SDATE can only be

used during a read
```

---

## Page 66

```
(n)
ui
pe |
n
Ss
x
<
>

FORMAT

array-elem. Element of a vector
with explicit index

Examples: JABO9
PAB.T

MEMORY SIZE TAKEN
(in bytes)

as variable

1. nn = index: DO — 99

2. see 1st note of array-
elem.

3. i (non-numeric ISO character)
= index variable identifier

index, name Index variable © Pi
Example: PT///

num-exp An expression that has

a numeric result

Example: JCONT + “1”

as variable

1. see 3rd note of array elem.

1. numeric ce: num.const/
variable/array-elem./index/
function

2. !: remainder
```

---

## Page 67

```
vg

MEMORY SIZE TAKEN

1. ce: const/variable/array-elem/
index

An expression that has
“true/false” as a result

eee:

1. ce: const/variable/array-elem/

string-exp
function

Example: PNOME U “ST”
```

---

## Page 68

```
g9

HE OCL STATEMENTS

FUNCTION: Defines the input parameter names for a BAL/BASIC program and/or the names of the output parameters for the same program

FORMAT:

re Oer]

Examples: SPAR ARG PCODA PMERC PTOTA;
9LIN ARG JVALN, JCONT SCOCO;
ARG , SCOCO. JVOLI;

NOTES-DEFAULT: 1. the maximum number of input/output parameter names defined by ARG is 20
2. output parameters are only present in an ARG of JOCP
3. at run-time ARG subtracts 192 bytes from the user memory
```

---

## Page 69

```
FUNCTION: Cancels ce from their own area

FORMAT:

RISE ere SETE NO

Examples: CAN PDATA LTOTA JSALD;

NOTES-DEFAULT: 1. it is not possible to cancel a ce in SCEA
```

---

## Page 70

```
i

NAME: END
FUNCTION: End of program OCP/JOCP
FORMAT:

Examples: 1CAP END;

NOTES-DEFAULT: 1. an END in OCP will cause the erasing of PCEA and LCEA

2. an END in JOCP will cause the erasing of PCEA, LCEA, and JCEA of JOCP
```

---

## Page 71

```
FUNCTION:

FORMAT:

Beginning of a loop

has @ as its limit will jump to the statement which immediately follows the associated NEXT statement

io
Ta
```

---

## Page 72

```
FUNCTION: Unconditional jump

FORMAT:

Examples: 1PAZ GOT 2LAB;
GOT PJUMP;

ew Se cn
```

---

## Page 73

```
Conditional jump
```

---

## Page 74

```
~ ~ J

È NAME: KIN
FUNCTION: Compiles the video as specified, receives data ficin the keyboard, tests the data and if valid, assigns it to the specified variabie
DEVICE: screen ”
FORMAT: i È

LZ

[re video e, Liù input ‘ae E SR input 7 )
© key - control Sentol (©) h

K column r

La fermo}

arrival-lab

key control:

default-par

: Examples: 1INO KIN PCHOS. A 67,22") 1 COPY:SINGEE: FILE" (“9", “20") a ENTER CHOICE NUMB.” = D1
5 ae po “NUMB. FUNCTION” (ns 22") "2 ' CORY DATAS hea ee: . H INOX, 1 “1" “2° 2IMP, U “2” OIM.*,

NOTES-DEFAULT: 1. A: alphabetic chara@ters - C: ISOcharacters - D: numeric characters - H: hex? ‘scimal characters - L: alphanumeric characters - Y: Y(yes) /N(ot)
characters — 2. |: min-value < input < max-value - E: input # check-par - Y: input = Y(es) characte. aay input = N(ot) character - D: input = S2 (delay) — 3. Delay option
(D) omitted from an OCP (for parameter creation module). The delay option needs the ce name © PCEA = 4. KIN output: . LYPEX = E: the parameter exists and is valid .
LYPEX = N: parameter does not exist or is not valid - . LCRTN = number of input characters - . LOR™N =@in case of delay (S2) -. LCRTN =n aber cters fer de-
fault: par. in case of default (S1) — 5. The input var equal to SCOCO, SPAGE, SLREC, SFLED o SSiviCP is permitted — 6. input-length range: input-type: + - range 21-63 -
input-type: C - range: @1-63 - input-type: D - range: 01-15 - input-type: H - range: 02-16 - input-type: range: @1-63 — 7. U: underlined = B: blinking - H: high iieht — 8.
F: forward key enabled - . B: backspace key enabled .H: home key enabled — 9. row between C and 24 row = 0: message on the status line column: between 1 and 80 —
10. N option: message marker goes to the line immediately following the current line of the marker — 11. column = 1 if missing and row = N.
```

---

## Page 75

```
N
wo

NAME: LET
FUNCTION: Assigns value to variables
FORMAT: i ‘ .

Ì
i
i

(=)Aassigned-value (5)

Examples: 102A LET LNAME = “MR. WALLAS”,
LRAGS = “ST. KENNEDY J. 21”;

NOTES-DEFAULT: 1. The var-name equal to SCOCO, SPAGE, SLREC, SLFED or SSMCP is permitied
```

---

## Page 76

```
FUNCTION: Prints messages on the video

DEVICE: display/screen

FORMAT:

pren),

message

Examples: MESM “THIS IS A MESSAGE”;
1LAB MES E “CHGE FD” 2RUN;

MES D a
("14”, $1") H “INPUT DRIVE NAME:”

(122, “4”) H “VOL. IDENT.:”
(“13", <1”) H “OWNER:”;

” response from the operator (SO — S6) - . M/E:

NOTES-DEFAULT: 1. the D/V option can only be used to controk the video — 2. E/V: message that needs a “have seen
- [label] MES V: - screen is cleared

messages on video in the first column of the line immediately following that of the marker — 3. [label] MES D:
and the marker is positioned in column 1, line 1— 4. see 7th, 9th, 10th, 11th, note in KIN.
```

---

## Page 77

```
SL

a A

Examples: FOR P.1/// “20”;
LET PNO.I = P.1///;
NEX;

FORMAT

NOTES-DEFAULT

dI Lil Lui ‘2 >

de
```

---

## Page 78

```
FUNCTION: Assigns or conditionally jumps depending upon the outcome of one of the specified conditions

FORMAT:

arrival-lab

EQ “60” = PCONT
EQ “20” 1ERR;

Examples: ONV JCONT EQ ‘=
```

---

## Page 79

```
Defines a comment
statement

[ansi 0

Example: *THIS IS A REMARK;

Starts the execution of
a BAL/BASIC/Z8000
program or a JOCP

Examples: 1RUN RUN “PRTLAB”, “PARAM”;
: RUN “SCLAV”;

Starts an OCL program

Examples: STR O “OCPNAM”;
STR J “JOCPNM”;

1. N: the OCP associated with
prg-name will not be
executed

. N and mod-par are missing
if prg-name is JOCP

. after execution of RUN the
PCEA and LCEA are released.
If prg-name is a JOCP two
different J areas are allocated
not communicating with each
other.

1. O: ocl-prg-name
is an OCP

J: ocl-prg-name
is a JOCP
```

---

## Page 80

```
Checks disk/data set
for presence

Example: LET LYFDN = “FD4”, LYMOD = “N”; YCS 01;

INPUT VARIABLE PARAMETER

Specifies the FD1 + FD4 Floppy-disk on drive 1 + 4
drive to be tested | HD1 + HD4 Data set configured on HD
DCI + DC4 HD1 + HD4 is assumed
Te 4 If the bootstrap unit is HDU,
HD1 + HD4 is assumed
If the bootstrap unit is FDU,
FD1 + FD4 is assumed
Error handling Not standard handling
Standard handling

OUTPUT VARIABLE PARAMETER

MEANING

disk with 150 chacacters if LYPRE = 1 or 4 the output
volume label is present variables left are not significant
disk is absent

disk is present with

150 characters

volume label is absented

disk is present with not ISO

characters.

Volume een he e 3
Function non supported by the

|, specified disk-unit or not
configured

Disk volume ccccc = valid name on disk
identifier

b single side and low-packed disk
M double side and high-packed disk
2 double side and low-packed disk

number of registered sides on HD

Type of disk

Owner cccccececcccce | cccceccccccccc = name of the
disk owner

128 bytes/sector for the FD
256 bytes/sector for the FD
256 bytes/sector for the HD

Length of sector b
(bytes) 1
8

Number of tracks 75 is the number of tracks
on the volume available for user on the FD

2125 is the number of tracks
available for the user on the 18M
bytes HD

2220 is the number of tracks
available for the user on the 18M
bytes HD

3105 is the number of tracks
available for the user on the 48M
bytes HD

Number of , number of sectors/track on FD parameter is valorized only if
sector/track LYPRE = @ ie

number of possible sectors/track
192 on HD

max 999

Number of bytes/ 128 number of bytes/sector for
sector 256 the FD

256 number of bytes/sector for the HD

Number of number of the sectors on track. parameter is valorized only if
sectors on D of the FD «|| LYPRE = @

tracks ©
number of the sectors on track

@ of the HD
```

---

## Page 81

```
FUNCTION

‘| Checks status of a file

on all on-line
disks/data sets

(UNDEFINED mode), * |

or on the specified
disk/data Set.

FORMAT

Example: LET LYFDN = “FD2”, LYFLN = “ARTCOS”, LYTYP = “D",

LYMOD = “S”; YCS 02;

Name of the drive
on which the file
should the
searched

€rror handling

file name

file type

OUTPUT VARIABLE
wane [wenn vA

file status

drive number
containing the
disk or number of
the data set with
the specified file

file "i
type of fi und
if “D" has been
thefinput
character

®

,

associated file
or name

file coll
length (bytes)

max number of
records on the file

positional number
of last record on
the file

key displacement
from the
beginning of data
record

name of the device
(type and number)

UND-U

FDU/HDU

FD1 + FD4

HD1 + HD64

DCU

DC1 + DC4
174

N
Ss

cccccc

FD1 + FD4
HD1 + HD64

file searched on all volume
on line

file searched on all FDU/HDU
floppy-disk on drive 1+ 4
data set configured on HD
HDY is assumed

HD1 + HD4 is assumed

If the bootstrap unit is HDU,
HD1 + HD4 is assumed.

lf the bootstrap unit is FDU,
FD1 + FD4 is assumed.

not standard handling
standard handling

cccccc = file name (the first
character must be
alphabetical)

system library
data file
user library

file is present

file is absent

disk is absent on drive

the function is not supported

disk on drive 1+ 4
data set HDn (n= 1 = 64)

cccccc = file name

sequential data file
work file

unsorted keyed file
sorted keyed file
unsorted index file
sorted index file

cccccc = name of index/data
file associated to the
data/index file to be
checked .
the file is not an keyed
file

2 + 256 = record length

floppy-disk on drive 1+ 4
data set on the HD

= "91" if
="S" or "C”

library allocated on the .

fied by LYF )

if the input variable
LYMOD ‘'S”
LYPRE assumes value @

if LYTYP = P or W,
LYPFN = “B’

not significant parameter if
LYTYP = ""S" or bh oad

not significant parameter if
LYTYP =“'S" ar *C”
not significant parameter if
LYTYP = “Sor “C"

not significant parameter if
LYTYP = P or W

parameter significant if
LYPRE = @
```

---

## Page 82

```
YCS @3 | Does scratch of a

data file

€8

drive name on
which the file is
not to be
searchedifor

name of the file
to be

new record
length

J wa

file searched on all on-line volumes
FDU file searched on all FDU
HDU file searched on all data-set
FO1 = FD4 file searched on the specified drive
HD1 + HD64 file searched on the specified
data-set
DCU HDU is assumed
DC1 + DC4 HD1 + HD4 is assumed
te If the bootstrap unit is HDU,
HD1 + HD4 is assumed
If the bootstrap unit is FDU,
FD1 + FD4 is assumed

cccccc cccccc = file name (the first
character should be
alphabetic) hd
2+ 256 parameter is valorized if the
specified file is a work file

I sae, te diss
```

---

## Page 83

```
v8

Identifies the

hardware on which
operation in being
performed

Example: OLET YCS 06;

OUTPUT VARIABLE PARAMETER

system with FDU
system with FDU

identifies the
system

mono environment
multi environment

identifies the
environment

identifies the work station number

position number
```

---

## Page 84

```
it is operating ina
“multikeyboard” environment
only; not operating in a “mono”
environment in which case it
returns LYPRE = @

Example: 1. LET LYFDN = “FD2”, LYFLN = “FILE1”, LYTYP = “RES”,
LYMOD = “OUT”; YCS 07;

Zi GET LYFDN = “HD50”, LIFLN = “FILES”, LYTYPE = “SHR”;
LET LYMOD = “UPD”, LYFTY = “C”; YCS 07;

INPUT VARIABLE PARAMETER

name of the drive
on which the file
device is
searched for

name of file to the
reserved

type of
reservation to be
made

type of
processing to be
performed on the
file

type of file

OUTPUT VARIABLES

result of the
reservation

FDU/HDU
FD1 + FD4

file searched for on all the
FDU/HDU

disk in drive 1+ 4

the HDU is assumed

data set 1 + data set 64
HD1 — HD4 is assumed
file searched for on all the
on-line files

DCU

HD1 + HD64
DC1 + DC4
UND

cccccc = name of the file (the
first character must
be alphabetic)

cccccc

reserved file

file shared with others users
file only shared with other users
for input operations

LYTYP = “RES” if
LYMOD = “OUT”

input
update

file append operations without
scratch

file append operations with
scratch

undefined

library file
data file

PARAMETER

reservation executed

reservation not executed
because it has been done
already by another W.S.

non existant file and disk
dismounted

the file has already been
reserved by that W.S.

optional parameter D is assumed
by default
```

---

## Page 85

```
eg

YCS @9 | Releases the YCS 99 is operating in a
specified file, freeing “multikeyboard” environment

the previously only; not operating in a ‘“mono’
program-performed environment in which case it
reservation returns LYPRE = @

Example: 1. LET LYFDN = “FD3", LYFLN = “FILEA”, LYTYP = “D"; YCS 09;
2. LET LYFDN = “HD20”, LYFLN = “LIBRE”, LYTYPE = “C’”; YCS 09

name of the drive | FD1 + FD4 disk in drive 1+ 4

on which the file | HD1 + HD64 data set 1 + data set 64

is to be searched | DC1 + DC4 HD1 + HD4 are assumed

for HDU/FDU file searched for on all the
HDU/FDU

name offile tothe | cccccc cccccc = name of file (the first
unlocked character must be
alphabetic)

type of file library file optional parameters
data file D is assumed by default

OUTPUT VARIABLES PARAMETER

LYPRE- reeult of . operation-ended cerrectly and
unlocking file is not protected
file does not exist and disk
cannot be dismounted
```

---

## Page 86

```
Associates a new
name with an already
existing file on data
set .

YCS 10 is operating ina
“multikeyboard” environment
only; not operating in a “mono
environment

”

Example: LET LYFLN = “FILE DC”, LYPFN = “FILE FD”; YCS 10;

OUTPUT VARIABLE

PARAMETER

eccccc eccccc = name of the file (one
first character must
be alphabetic)

name of the file
logically
processed by the
program

file resident ona
data set

cccccc cccccc = new name of the file
(the first character
must be alphabetic)
```

---

## Page 87

```
FUNCTION ‘venice

The specified volume
is locked/unlocked
(volume Lock/Unlock)

FORMAT

1. the system automatically
performs the volumes UNLOCK
at the end of every JOCP
procedure execution

. YCS 11 is operating ina
“multikeyboard” environment
only; not operating ina “mono”
environment in which case it
returns LYPRE = 9

Example: 1. LET LYFDN = “DC1”, LYTYP = ““L”; YCS 11;
2. LET LYFDN = “HD3”, LYTYPE = “U”; YCS 11

PARAMETER

name of data set | FD1 + FD4 disk in drive 1+4
to look/unlock HD1 + HD64 data set 1 + data set 64
DC1 + DC4 HD1 + HD4 are assumed

type of operation | L the volume is to be reserved
to execute

the volume is to be unlocked

OUTPUT VARIABLE PARAMETER

result of operation ended successfully
operation |
locking cannot be done as file Y =
are open on the volume È
=e “volume not present i È om
volume not protected if LYTYP = “U”
```

---

## Page 88

```
€6

Ww ws A |

OCL FUNCTIONS

| name | FUNCTION NOTES-DEFAULT

1. Each digit of the hexadecimal
value in format must be equal

Define an hexadecimal

value i
ene 0-9 digits or A—F characters

Example: “314369” HEX
```

---

## Page 89

```
arrival-lab
assigned-value
associated-file-name

back-lab

call-mode

cename

check-par
column

controlled-value

control-var
default-par
disk-status

display-mess
drive-name

drive-no

hexadecimal-value

file-name

file-status

file-type
forw-lab

help-mess
home-lab

input-var
input-length

input-param

key-displ
label
last-rec.

limit

max-rec.no.

max-value

message

min-value

mod-par

new-length
ocl-prg-name
output-param

owner

prg-name
rec-length

refer-value

rel-exp

remark

row

screen-mess

TABLE OF WORDS USED IN OCL STATEMENTS

Arrival label of a jump
Value to be assigned to a variable

Name of the index/data file associated to a data/index file
of a key file

It indicates the label to jump to when the backward key is
pressed

Handling directions for errors that cannot be restored
Name of the ce to be cancelled

Value with which the input value is to be compared
Column position of where the marker is to be placed

A variable that will be assigned a value or that will determine
a jump upon the equalling of its value with ref-value

Control variable in a loop

Parameter assigned upon a keyboard input default
Disk physical status

Messages to be printed on display

Indicates the name of the drive/device on which a function
will be performed or where a file will be searched

Number of the drive where a file resides
Hexadecimal string given as input to a function
Name of a file on disk

File physical status

Type of file on disk: data or library

Indicates the label to jump to when the forward key is
pressed

Input guide for Keyboard

Indicates-the label to jump to when the home key is pressed
Keyboard input will be assigned to this variable

Keyboard input length in characters

Parameter name to be passed as input to a parameter
program

Key length of a key file
OCL label
Position of the last record saved in the file

Maximum value that will be assigned to a control variable
in a loop

Maximum number of records in a file
Maximum value of the acceptable input
Message to be printed on the video/display
Minimum value of the acceptable input
Name of the parameters-module

New record length of a work-file

Name of the OCP/JOCP program

Variable name that will be assigned to output parameter in
a program

Name of the disk owner

Name of program running in job-mode
Record length (in bytes) of a file
Value that must be compared with controlled-value

An IFC logical expression

Statement comment

Position of the row on which the marker is to be placed
Message to be printed on video (screen)

95
```

---

## Page 90

```
SCOCO
sector
SLFED
SLREC
SPAGE
SSMCP
surf-ind
track-form
var-name
vol-ident

Completion-code

Number of sector per track

Left margin of the print line

Length of the print line

Number of lines on the print forms

Dimension in sectors of a dump section
Physical organization of a disk

Sector length (in bytes) of a disk

Variable name that will be assigned to a value
Volume identifier of a disk
```

---

## Page 91

```
; VY d d

EQUIVALENCE BETWEEN SEMANTICS AND SYNTAX OF THE WORDS USED IN OCL STATEMENTS

STRING

‘(VARIABLE - TYPE VARIABLE - TYPE

SYNTAX - SEMANTIC
EQUIVALENCE i i Ù P
(PCEA)

arrival; lab 9 7 |

; @
assigned - value (LET only) (LET only)

associated - file - name

backw - lab

call - mode

cename

16

check - par

column

controlled - value

control - var

default - par

disk - status

display - mess

hexadecimal - value

drive - name

drive - no

file - name

file - status

; EHioype——— —
forw - lab

help - mess

home - lab

input - var

input - length

input - param

key - displ
label
last - rec

limit

max - rec.no.

max - value

message

min - value

mod - par

new - rec - length

ocl - prg - name

~~ output param”
a

prg - name

rec - length

refer - value

rel - expr

remark

row

screen - mess

sector

surf - ind

track - form sà
var - name om A
vol - ident

*: Variable name
A: Variable name/array - element/index
@: Variable name/array - element.
```

---

## Page 92

```
di exec | gi cessi atl peeve | err |

7INQ EDIT IBAS IBAS
DEBUG AT | BREAK AT
o)

APPEND
BACKW
BREAK
CBREAK
CHANGE
COPY
DELETE
DISPLAY
EJECT
END
ERASE
FETCH
GOTO
GPTE
IGNORE
INSERT
KILL
LIST
LOG
MODIFY
NEXT
NOLOG
NPRINT
OCLCPY
OCLSYN
PRGNAME
PRINT
PROCEED.
RBREAK
REPEAT
RESTORE
ROLL
SCAN

COMMAND KEYS READY EXEC ERROR INQUIRY EDIT DEBUG STOP

INQUIRY
NORMAL
RESET
RUN
$2 (DOWN)
$3 (UP)

TEST

OCL COMMAND SYSTEM

TABLE2

101

2
```

---

## Page 93

```
£0L

—

BASIC/OCL COMMANDS

APPEND... $

Allows the appending of

new lines

Go backward in lines in
a text

Start the execution of
BASIC procedure

ocs
(editor)

BASIC
(ready)

Example: APPEND

Example: BACKW, 4

NOTES-DEFAULT

- the system goes to APPEND
automatically by NEW in INIT

- the commands $ ends the
append of lines

- 1S no-lines s 9999
- without parameter defaults to
BACKW, 1

CONTROL RUN BASIC

Example: CONTROL + RUN + BASIC
```

---

## Page 94

```
yOL

NOTES-DEFAULT

- 1 <line-num £ 99

- step by step does not
recognize active breaks

- without parameter deletes all
breaks on active lines

- in OCS it is possible to define

a maximum of 5 break-points

on line-num

FUNCTION ENVIR.

BASIC
(debug)

Sets up break-points in
a program

Cant) pe

Example: BRE 20

ocs
(debug)

Line-num

i mr Line-num i

Example: BREAK 40, 78, 7
```

---

## Page 95

```
SOL

FUNCTION

Breakpoints on
cename

Replaces a line

Prints on CRT the
contents of variable
whenever it occurs

Example: C,8.17

tooo

Examples: CHE AS
CHECK M2$

cename: generic name of an
OCL variable;

step by step does not
recognize active breaks on
cename;

without parameter deletes all
breaks on active cename;

it is possible to define a
maximum of 5 break points on
cename

1 < abs-addr/rel-addr < 65535
without parameter replaces
the current line

data-item: num-var/string-var
```

---

## Page 96

```
90L

COPY

DELETE

Reproduces on the
printer the contents of
the video

Deletes program
instruction in memory

BASIC/
ocs
(in-
quiry)

COPY

Dy pen] pO o

Examples: DELETE 10,20
DEL 42
DEL

NOTES-DEFAULT

the reproduction does not
include visual attributes and
frame characters

COPY operates only when the
NOPRINT command is not
active

DEL line-num 1, line-num 2 =
deletes instruction between
the specified lines

DEL line-num 1= deletes the
specified line

DEL = deletes the current line
C= current line

O: — if first parameter is =
first line - if second parameter
is = last line

1 < abs-addr/rel-addr < 65535
without parameter deletes the
current line
```

---

## Page 97

```
ZOL

9 w/ J

NAME: DELETE

FUNCTION: Deletes program instruction in memory

OCS (edit)

FORMAT: [ii _ -—/.T— fai

(TY abs-addr 1 (1) rel-addr 1 (;) veli ai rel-addr 2 di

eee
+©

i ELETE 7

Examples: DELETE,19,19.1
D,32.3;32:8
D,423
D,0,0,

NOTES-DEFAULT: -C= current line
- 0: - if first parameter is = first line - if second parameter is = last line

- 1 <abs-addr/rel-addr < 65535
- without parameter deletes the current line
```

---

## Page 98

```
80L

| one | FUNCTION [ann FORMAT NOTES-DEFAULT

DISPLAY

- data-item: num-var/num-array/
string-var/string-array

- press an S key (S@-S6) to

confirm the data displayed

BASIC
(debug)

Shows the variable on
display

Examples: A$
B

- cename: generic name of an
OCL variable

Example: D JPRGN

- in environment BASIC (editor)
the command DOWN on last
program statement displays
first program statement

- in environment OCS (debug)

the command DOWN on

statement END displays END
again

BASIC/
(editor)
ocs
(debug
edit)

Displays the program
statement immediately
following the program

statement currently in

memory
```

---

## Page 99

```
_

FUNCTIONS ENVIR.

Editing operations ocs

forced to stop (edit)

Deletes ac.e. ocs
(debug)

Return system to ready BASIC
state (i.e., with/PGM (edit)
NAME or/SYS message)

FORMAT

(E) poe % = C= 5

Example: END
END, LIS
Erk i

Example: ERASE JFILL
E PCTLG

Example: EXIT
EXI

NOTES-DEFAULT

- invalid for c.e. of type PorL
causes the increase of program
memory of c.e. length + 5 bytes

- cename: generic name of an

OCL variable

The EXIT command causes the
automatic release of all
reserved libraries
```

---

## Page 100

```
OL

FUNCTION: Allows execution of a program or a procedure

FORMAT:

input- [¥
ie LEE ‘i j

Example: BBBBBB,, MODULO

prg. name = max 6 cr

lib. name = max 6 cr
input-par = max 6 cr name
output-par = max 6 cr name
```

---

## Page 101

```
LIL

Transfer a line of data
from main memory to
the display

Examples: FETCH 90
FET 50

Examples: FE 40
F

Examples: F,10
F,400.9

- 1 <line-num < 9999
- without parameter
displays the
current line
1< abs-addr/rel-addr
< 65535
in OCL if a line
doesn’t fit on the
status line it is
necessary to press a
key (S@—S6) to list
the remainder on the
same line
pressing the keys
SO-S6 after a
complete listing
allows introduction
of new commands
```

---

## Page 102

```
NOTES-DEFAULT

Sets a point for pure - 1< line-num < 9999
restarting program at GOT (0) Line-num - without parameter, the
line number “n” Program Counter points to
the statement on display or
to STR
Example: GOTO 40

Example: G 15

Allows program BASIC/
execution to continue, ocs
bypassing errors (error)

Example: | RUN

Stops program BASIC/
execution and permits ocs

operator intervention (exec) CONTROL INQUIRY
```

---

## Page 103

```
ELL

et

NOTES-DEFAULT

- the command $ ends the

Inserts lines in a ocs
program (edit) introduction of lines
è C) isa © -1< abs-addr/rel-addr S 65535
ae suet rel-addr J - without parameter, the insert

oth.
```

---

## Page 104

```
Ends a program
execution

SIL

BASIC
(debug)

KILL Lo TRUN/

Example: KILL RUN

BASIC
OCS
(inquiry)

KILL

BASIC
(stop)

7RUNEY

Example: K RUN

BASIC
ocs
(error)

bi PASSWORD 9

KILL

Example: KILL

ocs
(edit)

Example: KILL

ocs
(debug)

OPOPO os

Example: KILL RUN

NOTES-DEFAULT

TEST status must be active
```

---

## Page 105

```
LU

Transfer source text
from storage medium
into memory and links
to program resident
in memory

Prints n lines of the
program or file
currently in memory

POT Ot

Example: LINK ASSUNZ, LIBPRO, 1246

Op po Ar

Examples: LIST 10,50
LIST 35
LIS 224,232

- key must be in TEST position
- scratch file must be on line

in the BASIC environment the
key must be in TEST position
1 < line-num 1/2 < 9999
LIST line-num 1, line-num 2 =
prints the instructions
between the specified lines
LIST line-num 1 = prints all
lines greater than or equal to
linenum 1

LIST, line-num 2 = prints all
lines less than or equal to
linenum 2

in the BASIC environment the
command LIST without a main
parameter prints all lines

at the end, the last instruction -
printed becomes the current
line
```

---

## Page 106

```
FUNCTION: Prints n lines of the program or file currently in memory

OCS (edit)

FORMAT:

# ci abs-addr 1 Ta ax rel-addr 1 da, Ti abs-addr 2 ox rel-addr 2 in
e:
(c)

SIL

er  ____—_—
(c)

Examples: LIST, 0,0
LIST, 6

NOTES-DEFAULT: - 1 < abs-addr/rel-addr < 65535 — O: - if first parameter is = first line - if second parameter is = last line - C = current line
- in an OCS environment the command LIST without the main parameter prints the current line
```

---

## Page 107

```
GIL

FUNCTION: Allows reservation of the residence library of the program to be edited

ENVIRON.: BASIC (Edit)

FORMAT:

DA +0740

©)
Lo»

Example: LOCK LIBPR, S

- reservation modes: R = reserved - S = shared - | = shared input
- lib-name = max 6 chars
- LOCK command valid only in “multi environment”, in “mono” environment is declared not existant
```

---

## Page 108

```
ogl

Prints content of display
buffer

BASIC

inquiry
ready |
edit 1106

debug

Example: LOG

FORMAT

ocs
(debug)

NOTES-DEFAULT

- test mode (CONTROL + RUN)
must be active only in edit
or debug
the LOG command remains
active even if a NOPRINT
command is activated
the LOG command produces
the print of all input data and
of all displayed messages on
the status line
```

---

## Page 109

```
Lal

Replaces old-string with
new-string

Allows entry of a
program from the key-
board

Seeks for the next old-
string

Example: MODIFY

ACE

Example: NEW

Example: NEXT

NOTES-DEFAULT

- must be proceded only by
SCAN or NEXT

- replace old-string is always
the first string from the left
on display

- test mode (CONTROL + RUN)
must be active
```

---

## Page 110

```
SV OON ‘a/dwexz

(Bnqep)

JeA-BuL}s/1eA-Wunu :we}l-eyep - olsva

09 SON
MVAYGON ‘se/dwexg

s}ulodyeaiq
[lE sjeoues ‘ajawesed INOYNM -

(6ngap)
6666 > Wnu-au S | -

f_snan |
fanne di now

171NV430-SALON IVINHOA ES

UOI}ipuoo puewwod
MOSHO 84) sle9UeD | YOIHOON

julodyeaiq

wei6oid E sjaoueg WVSYEGON

122
```

---

## Page 111

```
Cancels message
printing (the LOG
command condition)

eci

edit
debug
ready
inquiry

NOTES-DEFAULT

- test mode (CONTROL + RUN)
must be active

ISYS
(ready)

INOLOG
```

---

## Page 112

```
‘annnoe Ajjueseid
SUONIPUOO 92} BU} JO [je

s|aoUBO JOVHLON ]uasge ae
Z wnu-aul| pue | wnu-euly }j

{ode

|

puewwos snoiAeid
e Aq ul-jas 9921}
Uol}ipuoo au} ajgesig

(6nqgap)
olsva

IOVULON

Dee Je

aweu-wfd

PAPEO] SI UOISIBA-1E}S

84} BSIMJ94}0 ‘papeo] aq IjiM
We180J1d ay} JO UOISISA-MOEg
84} Papnjoul! Ss! dNMOVE H

L1NVI430-SILON LVINHOH 'HIANI

Ayeiqi| 4asn
eB wolj Uaye} Wesbod
e Aiowew UI peo]

Chit <—

(Auinbu)
soo
/OISVE

48} uud

@y} uo swesBoid Jasn
Aq paonpoud indino je
+0 UOISSILU® 84} SYQIUU]

ANIUdN

(Apeas)
soo
/9ISVA

ANIUdN

124
```

---

## Page 113

```
FUNCTION ewe | FORMAT NOTES-DEFAULT

d bo ae
dl

NORMAL

Restart continuos
execution of program
in memory

BASIC
ocs
(ready)
(inquiry)

Resets the
setting caused by
the NPRINT command
```

---

## Page 114

```
9eL

PRGNAME

FUNCTION: Start the program execution

BASIC/OCS (ready)

FORMAT:

rae fro Ops poten

Examples: TOTO, INT,OUT
TOTO,OUT

NOTES-DEFAULT: - inparname: input parameter module (max. 6 character)
- outparname: output parameter module (max. 6 character)
- without lib-name, the prg-name is searched for in the first library of the disk on-line
- prg-name: is the program to be executed
```

---

## Page 115

```
Le

pome NOTES-DEFAULT

PROCEED Forward n lines in a text - 1< no-lines < 99
- without parameter means
PROCEED 1

Examples: P,3
PROCEED, 7

Examples: PUR PAY2.ACLIB,ALL
PURGE DEBUG.ALIB, BACKUP

RBREAK Breakpoint on state- RBREAK on RBREAK already
ment RUN active, removes the breakpoint
previously set-up
step by step does not note
active breaks
Examples: R
RBRE

Logically cancels pgm-name - without lib-name the pgm-
program from the i name is searched for only
specified application in the first library of the disk
library on line
PO ODA
BACK UP
```

---

## Page 116

```
mae | FUNCTIONS FORMAT NOTES-DEFAULT

i il

- NOBACK: *version of program

Restart program
beginning from the
instruction that
generated an error

BASIC/
ocs
(error)

eee 7RUN/ | > REPEAT ag /RUN/

Example: REPEAT RUN

REPLACE Replaces program in an BASIC
application library with (edit)
a new version
Example: 1. REP NOCHECK, NOBACK
2. REP
Changes the line BASIC
number of a program in (edit)
main memory
Example: RES 50
RESEQUENCE

87l
```

---

## Page 117

```
6Cl

NOTES-DEFAULT

- RESTORE disables all
searches of strings started
by a provious SCAN command

Interrupts program
execution and clears a
KE error message; in
environment, removes
an abort message

/RESET/ 5 PASSWORD È

Example: RESET

Restores a program
saved by TEMP

(8) pre

Example: RESTORE

RESTORE

ROLL Interrupts current
program run; stores
memory contents and
CRT screen contents
DRSFLE

1 - Starts/restarts
program execution;

2 - puts system in
READY state on
abort errors

3 - displays any other

error

BASIC/
ocs
(inquiry)

ROLL /RUN/

D+
```

---

## Page 118

```
OEL

FUNCTION: Saves a program; program saved in library in FD/HD environment

BASIC (edit)

Examples: SAVE OLIVE1, NOCHECK
SAVE OLIVE1, ACCT,E,Y

NOTES-DEFAULT: - A = American edit format
- E = European edit format
- G = British edit format

oY
-N

p
n

arameter module included
o-parameter module used
```

---

## Page 119

```
LEL

NOTES-DEFAULT

- already precedes NEXT or
MODIFY

FORMAT

Op O MO pg ZIE

Examples: S,JPIPP $ JNOME
SCAN, B 10 $ B 120
SCAN,RIC,SOESC

FUNCTION ENVIR.

Seeks for a string
```

---

## Page 120

```
CEL

FUNCTION: Assigns a value (string or numeric) to a data-item

BASIC (debug)

FORMAT:

iaia BI
Ome +O} averne [mr

string-const

Example: AS = 2

NOTES-DEFAULT: - data-item = num-var/num-array/string-var/string-array
- constant = num-const/string-const
```

---

## Page 121

```
Unloads a source
program from memory
to storage medium

Temporary recovery of
WORKFL

Activates BASIC
program preparation
(READY and EDIT), and
DEBUG operating
conditions

Prints program line
numbers and traces
program execution

Examples: TRA 20,50
TRACE

FORMAT

HE po Of fy

NOTES-DEFAULT

TEMP disables all other
searches of strings started
by a previous SCAN
command

active until the execution of
NOTRACE

TRACE line-num1, line-num2:
tracing of instruction between
line-num1 and line-num2
TRACE line-num1: tracing of
only, line-num1

TRACE: enables the tracing of
the whole program
```

---

## Page 122

```
VEL

FUNCTION

Allows release of the
specified library
previously locked
(LOCK command)

UNLOCK

Example: UNLOCK LIBPR

Displays the program
statement immediately
preceding the program
statement currently in
memory

NOTES-DEFAULT

- lib-name = max 6 chars

- UNLOCK command valid only
in “multikeyboard”
environment; in “mono”
environment is declared not

existant

- in the BASIC environment the
command UP on the first
statement displays the last
program statement

- in the OCS (debug)

environment the command

UP on the STR statement

displays STR once more
```

---

## Page 123

```
Sel

FUNCTION: Display one or more program instructions

Example: 1. VLI 40, 80
2. VLI 80

- 1Slin.-numb 1/2 S 9999

- if lin-numb, 1 and lin-numb 2 specified, instructions with line number included between the two
- if lin-numb 1 specified instructions = line-numb, 1 are displayed

- if line-numb, 2 specified instructions = lin-numb, 2 are displayed

- if line numb. 1/2 not specified, all program instructions are displayed

operands are displayed
```

---

## Page 124

```
9EL

FUNCTION: Replaces old-string by new-string in a part of the program

OCS (edit)

FORMAT:

0 iii

(0)

Examples: W, KENASKINS1, 25
W, NL 3$NL '4’$82,123

NOTES-DEFAULT: - 1 < abs-addr/rel-addr < 65535 —0: - if first parameter is = first line -
search into the

a

if second parameter is = last line — C: current line — old-string: string to

program — new-string: is a string which substitutes the old-strings in the program
```

---

## Page 125

```
Lel

Assign value to a c.e.

ocs
(debug)

Example: W LPARG

NOTES-DEFAULT

- if tename already exists, it
assigns the last value and,
modifies the available
memory

- assign-value:
max 15 crt (numeric)
max 63 crt (string)
```

---

## Page 126

```
BASIC: PROGRAMMER ENVIRONMENT LI

BCOS Il

program-edit environment

debugging environment -

Commands & Test

È SS
\
Zad x “i
# X N
/ \ micio deli
enni nego (rr Sr. sa] agi Mee SIRMONEE un &
/ BASIC EXIT \ X
/ & \ &

[oe TEST \B \

/ 3 \
| a \
| 2 \

a \

|
Commands \

US \
ay
-
ae

KILL &

& Test

TEST + RUN

a Commands

TEST KILL RUN
KILL & RUN
& RUN

TEST KILL

139 |
```

---

## Page 127

```
—

Lv

~~ ws o ta

OCL: PROGRAM PREPARATION PROCEDURE

ocLePY
OCLCPY/S-/

C06 PROGR. NAME:
CCCCCC/s-/

C01 VERSION

*
B
IS1f=*

C06 LIB. NAME

ecccccc/S-/
/S1/ = first library

n

GPTE /S-//

SOURCE FILE:

ccccce = /S-/
/S1/= FLEDIT (mono sistems)

FLEDIn with
1SnS4 (multi sistems)

A03 MODE:

O[LD]/S-/
/S1/=O[LD]

O=/S-/
Sti =O

DO2 FROM. SIZE :

N[EW] /S-/
dd /S-/

/S1/= 72 %

Command:
APPEND

COM E<first-line/last-line/current-line/modifying-line/blank>

Command:
INSERT

INS BB n-line

Commands: Command:

BACKW KILL
CHANGE
DELETE
FETCH
LIST
MODIFY
NEXT
PROCEED
SCAN

TEMP
WHERE
n Li La

APP @ line-nr. |

mode =
OLD+ [TEMP] Command: RESTORE

NEW TEMP pe Ne

Command: E[ND] [ isn]
```

---

## Page 128

```
OCLSYN

LIST =N +

CTLG =Y

OCLSYN /S-/

YIN

PARAM. FROM _ KEYB.?

YIN OPTIONS

Gea 1.

LIB. NAME =
CTLG. MODE = B

LIST =N si a

CTGL=Y

LIB. NAME =b

CTLG. MODE = B

— — — — —_

De
YIN LIST: YIN CTLG

— — — N/S-/ ae

/S1/=Y

ccccce /S-/
/S1/ = first lib.

no printouts requested — =

/SO/
```

---

## Page 129

```
RUNNING ENVIRONMENT(*)

INITIALIZING

COMMANDS |

RESET/(PASSWORD)
KILL/(PASSWORD)
KILL+PASSWORD

END |
PROGRAM

PRG-NAME

SYS-ERROR

INQUIRY

IGNORE/REPEAT+
RUN

vi

PROGRAM-ERROR

PROGRAM
ERROR

COMMANDS

INCORRECT COMMAND

*

RESET a È

* The modes of program execution requests are presented.
Such mode is unique to both mono and multi-keyboard environment.

145
```

---

## Page 130

```
OCL: DEBUGGING ENVIRONMENT

prg-name

or or
Stm restart
RUN
Inquiry BREAK
RUN STOP
|
Command S/=/= Ii
EES & i
A 4] L (a o
Sole x IS
VSS Dr Ò
i is) A 3
fa VI We x
. 5
SI |
|
|
TEST+ KILL+RUN \
prg. error

143

Command

L/

TEST + KILL+RUN
```

---

## Page 131

```
COMMAND SYSTEM

TABLE 1: BASIC COMMAND SYSTEM

TABLE 2: OCL COMMAND SYSTEM
BASIC/OCL COMMANDS

BASIC: PROGRAMMER ENVIRONMENT

OCL: PROGRAM PREPARATION PROCEDURE
OCL: DEBUGGING ENVIRONMENT

RUNNING ENVIRONMENT

99
101
103
139
141
143
145

COMMAND
SYSTEM
```

---

## Page 132

```
READY exec | ERROR NQUIRY| EDIT pesue | STOP

COMMAND
IBAS IBAS
i DEBUG AT | BREAK AT
Oo

BASIC
BREAK
CHECK
COPY
DELETE
DISPLAY
EXEC
EXIT
FETCH
GOTO
IGNORE
KILL
UNK
LIST
LOCK
LOG
NEW
NOBREAK
NOCHECK
NOLOG
NPRINT
NOTRACE
OLD
PRGNAME
PRINT
PURGE
REPEAT
REPLACE
RESEQUENCE
ROLL
SAVE
SET

COMMAND KEYS READY EXEC ERROR INQUIRY EDIT DEBUG STOP

INQUIRY
NORMAL
RESET
RUN
$2 (DOWN)
$3 (UP)
TEST

BASIC COMMAND SYSTEM

TABLE1

99
```

---

## Page 133

```
ERRORS

AUTODIAGNOSTIC ERRORS
ERRORS SIGNALED BY THE GENERATION PROCEDURE

BASIC ERRORS:

e EDIT-TIME ERRORS

e PRE EXECUTION ERRORS

e DERUGGING COMMAND ERRORS

a PROGRAM ERRORS AT RUN TIME DECLARED Er
THE BASIC INTERPRE Thi

VCL ERRORS:

6 OCLOPY PROGRAM FRRORS

@ GPTE PROGRAM ERRORS

e OCLSYN PROGRAM ERRORS

a DEBUGGING COMMAND t PRORS

» PROGRAM ERRORS AT RUM TIME DECLARED BY
THE OCL INTERPRETER

BAL ERRORS:

e PROGRAM ERRORS AT RUN TIME DFCLARFD BY
THE BAL INTERPRETER

BCOS ll DECLARED ERRORS

147
149

151
153
155
157

163
105
167
171
```

---

## Page 134

```
lm >

AUTODIAGNOSTIC ERRORS

DESCRIPTION

Central unit fault

RAM memory faulty

Array, acquired at interrupt time, not provided
Absent

Waiting for result of the first IPL attempt

“X" - error code meaning:
1 - controller fauit

2 - peripheral unit faulty

Lvl

3 - read support fault
8 - magnetic support not inserted or support not containing the operating system

“y” - slot name corresponding to the controller the error code refus to

“Z’ — unit on which fault has been detected
```

---

## Page 135

```
(1

ERRORS SIGNALED BY THE GENERATION PROCEDURE

WARNING TYPE ERRORS
a

WARNING 002: FDx MISSING The disk is not in the drive

WARNING 003: MISSING VOLUME LABEL ON FDx The drive x disk has no volume label

WARNING 005: INCOMPATIBLE DISK ON FDx The disk is incompatible (for example it is an MFM instead of the requested DF disk)

WARNING 030: INCOMPATIBLE FILE TYPE ON FDx The label on drive x file is different from the one requested

The parameter
must be entered
WARNING 012: EMPTY FILE ON FDx The file on the drive x disk is empty again

WARNING 100: REQUIRED CONFIGURATION NOT The requested configuration is not available because it is not provided for
AVAILABLE

WARNING 102: DISMOUNT DISKETTE FROM FDx The requested function cannot be performed because the drive x disk has not
been dismounted

WARNING 011: MISSING FILE NAME ON FDx The file is missing on the drive x disk

WARNING 013: WRONG FILE NAME The name of the file to be processed is incompatible with the request
```

---

## Page 136

```
OSL

ERROR 036: NOT POSSIBLE FUNCTION

A function has been requested that cannot be executed

ERROR 041: DAMAGED DISK ON FDx

The drive x disk is damaged

ERROR 045: CONFIGURATION MODULE INEXISTENT

The configuration module is not on the disk

ERROR 046: OVERFLOW CONFIGURATION MODULE

The addition of new parameters caused a a configuration module (MODC) overflow

a

The parameter
must be entered
again
```

---

## Page 137

```
+S}

ed ww

PROGRAM ERRORS AT EDIT-TIME -

EDITMIERR. 201
EDITMERR. 202

EDIT@ERR.
EDIT@ERR.
EDITMERR.
EDITHERR.
EDITMERR.
EDITHIERR.
EDITMERR.
EDITRIERR.
EDITMERR.
EDITMERR.
EDITMIERR.
EDITMERR.
EDITIBERR.
EDITRIERR.

EDITMERR.
EDITRIERR.
EDITHERR.
EDITHERR.
EDITMERR.
EDITRIERR.
EDITIBERR.
EDITHERR.
EDIT@ERR.

221
230
231
232
233
234
301 NEAR COL cc
302 NEAR COL cc
303 NEAR COL cc

Unaxpected command

- Command or parameter (of a command) syntatically invalid
- Command with too many parameters

Command given in the wrong environment (mode) or in the wrong order, that is, in an emply program
Memory overflow

Library overflow

Program not present in the current library

The name of the program to be catalogued already exist in the library
The specified library is not present

The BACKUP version does not exist in the tibrary

Memory size not large enough to hold the program

PEDIT size insufficient to hold the program in EDIT

PEDIT is not present

International error: call Olivetti Ivrea - SSS Department

BASIC interpreter is not present

Unlinkabie library module

The first statement number of the module to be linked is less than the last statement number of the
program being edited

The program to be linked has not been prepared on M40 BCOS Il machine

Number of memory Kbyte entered at the REGION request is not availabie

Library reservation using LOCK command is not possibte (library has been reserved by another user)
Protected volume

Library reservation already done (repeated LOCK)

Library not reserved (UNLOCK not preceded by the relative LOCK)

String constant not contained within quotes

Syntactically invalid hexadecimal constant

More than one separator in a decimal numeric constant

ACTION TO BE TAKEN
A
```

---

## Page 138

```
est

EDITMIERR.
EDITRIERR.
EDITMERR.
EDITHIERR.
EDITIBERR.
EDITIBERR.
EDITMERR.
EDITHERR.
EDITMERR.
EDITIBERR.
EDITHIERR.
EDITHIERR.
EDITMERR.
EDITMERR.
EDIT@ERR.
EDIT@ERR.

304 NEAR COL cc
305 NEAR COL ce
306 NEAR COL cc
307 NEAR COL cc
308 NEAR COL cc
309 NEAR COL cc
310 NEAR COL cc
311 NEAR COL cc
312 NEAR COL cc
314 NEAR COL cc
315 NEAR COL cc
316 NEAR COL cc
317 NEAR COL cc
318 NEAR COL cc
319 NEAR COL cc
320 NEAR COL cc

DESCRIPTION -

Unauthorized characters present

Syntax error at column position cc

Precision factor greater than 15 or = @

Scale factor greater than the precision factor

The allocated length of a string variable is = 256

The allocation value of the index of.an array in a DIM statement = @ or is greater than 65535
An odd number of chacacters assigned to hexadecimal variable

The record-designator defined in a DFR = @

The file-designator defined in the OPEN = @

An insignificant field in a DFR statement is associated with a zero value
The BASIC statement line-number = @, or > 9999

The number of digits in a decimal costant is > 15

Line-number greater than 9999 during a LINK command

The entered line contains more than 80 characters

Operand or operator stack overflow

Syntactical pointers stack overflow

ACTION TO BE TAKEN
```

---

## Page 139

```
esl

‘PRE-EXECUTION ERRORS

ERROR 1 IN LINE nnnan END statement not present

ERROR 2 IN LINE nnnn FOR not closed with a NEXT statement

ERROR 3 IN LINE nnnn Matrix present with the same name as a vector or vice versa
ERROR 4 IN LINE nnnn There are more than 130 FOR-NEXT loops within the program

ERROR SIN LINE nnnn NEXT not opened by a FOR

ERROR 61NLINE nnnn The control variable present in the associated FOR-NEX statement are not the same

ERROR 7 IN LINE nnnn Jump made to a missing line-number

ERROR 8IN LINE nnnn The tine-number specified in the PRINT USING statement does not correspond with the IMAGE line number
ERROR 9 IN LINE nnnn The variable has been already defined

ERROR 10 IN LINE nnnn The matrix has been already defined

ERROR 11 iN LINE nnnn The END statement is not the last statement in the program

ERROR 12 IN LINE nnnn The variable defined in a COMMON statement has already been defined in another COMMON statement
ERROR 15 IN LINE nnnn Memory overflow

ERROR 16 IN LINE nnnn Numeric record identifier already used

ERROR 17 IN LINE nnnn More than 15 nesting levels used within FOR-NEXT loops

ERROR 19 IN LINE nnnn The specified line-number in a RESTORE statement does not indicate a DATA Statement
```

---

## Page 140

```
GGI

WV

ad

DEBUGGING COMMAND ERRORS

prname - ERR 21
prname - ERR 22
prname - ERR 100
prname - ERR 101
prname - ERR 102

prname - ERR 103

The numeric variable to be processed has not been initialized
The string variable to be processed has not been initialized
The program line referenced in the command is not present
Non-existing variable

Unexpected or syntactically invalid command

TRACE/NOTRACE command operating on an (empty) program

ACTION TO BE TAKEN

tnsert command
```

---

## Page 141

```
£SL

WV

PROGRAM ERRORS AT RUN-TIME DECLARED BY THE BASIC INTERPRETER

/BAS Ml pr-name - ERR.
/BAS Ml pr-name - ERR.

IBAS Il pr-name - ERR.

{BAS I pr-name - ERR.
/BAS Ill pr-name - ERR.
IBAS Ml pr-name - ERR.
/BAS Ml pr-name - ERR.

IBAS Ml pr-name - ERR.

/BAS fi pr-name - ERR.

/BAS Il pr-name - ERR.

IBAS Ml pr-name - ERR.

IBAS Ml pr-name - ERR.

/BAS Ml pr-name - ERR.
IBAS Ml pr-name - ERR.

/BAS I pr-name - ERR.

1 AT nnnn

2 AT nnnn

3 AT nnnn

4 AT nnnn

5 AT nnnn

6 AT nnnn

7 AT nnnn

8 AT nnnn

9 AT nnnn

10 AT nnnn

11 AT nnnn

12 AT nnnn

13 AT nnnn

14 AT nnnn

15 AT nnnn

ww ww

DESCRIPTION

Program size is greater than user area

Program format does not permit the program to be executed

Program name is syntatically invalid

The program request by a CHAIN is not present in the library

Request for a program CHAIN in a language other than BASIC

The program size exceeds that of the reserved memory

JCEA overflow white passing a parameter in output

JCEA output variable is empty or contains a value with a length greater than 53 character
Input parameter (c. e.) not present in dynamic area

Common area is missing in a parameter program

Common variable not compatible in length/type with the input parameters
Invalid numeric parameter

Unaxpected output parameters

Common variables not compatible with the output parameters

The value to be converted in binary is greater than 4.294.967.295

ACTION TO BE TAKEN

TEST + KILL + RUN
TEST + KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN
TEST + KILL + RUN

TEST + KILL + RUN
```

---

## Page 142

```
gs

IBAS Wl pr-name - ERR.

IBAS I pr-name - ERR.
/BAS I pr-name - ERR.
/BAS Ill pr-name - ERR.
IBAS Ml pr-name - ERR.

{BAS Ml pr-name - ERR.

/BAS Hl pr-name - ERR.
IBAS I pr-name - ERR.
IBAS Ml pr-name - ERR.

IBAS Ml pr-name - ERR.

IBAS I pr-name - ERR.
/BAS I pr-name - ERR.
/BAS Ml pr-name - ERR.

{BAS II pr-name - ERR.

/BAS II pr-name - ERR.

20 AT nnnn

21 AT nnnn

22 AT nnnn

23 AT nnnn

24 AT nnnn

25 AT nnnn

26 AT nnnn

27 AT nnnn

28 AT nnnn

29 AT nnnn

32 AT nnnn

33 AT nnnn

34 AT nnnn

35 AT nnnn

37 AT nnnn

DESCRIPTION

The length of the value assigned to a variable in a let statement is greater than its
defined length

The numeric variabie to be processed has not been initialized

The string variabie to be processed has not been initialized

Invalid array element index

More than 15 levels of nested subroutines

Underflows stack GOSUB

Underflow of the internal file

Use of the READ/RESTORE statement without an internal file

The result of a numeric operation causes a numeric overflow

Attempted execution of a NEXT statement before executing the relative for statement
Picture defined in IMAGE is incompatible with the input data

Number of digits in the image field is greater than 15

Invalid vertical position requested

No picture defined in the image statement associated with the INPUT/PRINT USING
statement

Open of second DTF on device IFA requested

ACTION TO BE TAKEN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN
TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN
```

---

## Page 143

```
61

/BAS ll pr-name - ERR.

/BAS Ml pr-name - ERR.

IBAS Ml pr-name - ERR.

IBAS I pr-name - ERR.

IBAS Ml pr-name - ERR.

/BAS II pr-name - ERR.
/BAS ll pr-name - ERR.
/BAS Ml pr-name - ERR.

BAS mi pr-name - ERR.

/BAS Mf pr-name - ERR.

/BAS Il pr-name - ERR.
IBAS Il pr-name - ERR.

IBAS Il pr-name - ERR.

/BAS I pr-name - ERR.

38 AT nnnn

39 AT nnnn

40 AT nnnn

41 AT nnnn

42 AT nnnn

43 AT nnnn

47 AT nnnn

48 AT nnnn

50 AT nnnn

51 AT nonn

52 AT nnnn

53 AT nnnn

54 AT nnnn

55 AT nnnn

The device specified in the OPEN statement is inconsistent with the other parameters
Invalid I/O mode specified in the OPEN statement

Attempt to OPEN a 18 file

Invalid device specified in the OPEN statement

The specified parameter “FLN file-name” is not allowed on the type of device specified
in the OPEN statement

Invalid file name (more than 6 characters)

Unaxpected device used in an I/O operation

Attempt to READ a file with an incorrect index value

The specified record number has not been defined a DFR statement

A chained DFR references another chained DFR

Too many records to be locked

Value of records to be locked or of their positions within the file = @ or = 65535

Value of the first array element of the LOCK statement is not compatible with the
number of the accounted array

The record specified in a write statement is associated with a DFR that contains
insignificant field

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN
```

---

## Page 144

```
ost

IBAS I pr-name - ERR.
{BAS Ml pr-name - ERR.
IBAS Il pr-name - ERR.
IBAS Ill pr-name - ERR.
IBAS Ml pr-name - ERR.
/BAS Il pr-name - ERR.

/BAS I pr-name - ERR.

/BAS Ml pr-name - ERR.
/BAS I pr-name - ERR.
IBAS Il pr-name - ERR.

IBAS Wl pr-name - ERR.

{BAS IR pr-name - ERR.
/BAS Ml pr-name - ERR.

/BAS Il pr-name - ERR.

/BAS II pr-name - ERR.

57 AT nnnn

58 AT nnnn

60 AT nnnn

61 AT nnnn

62 AT nnnn

63 AT nnnn

65 AT nnnn

66 AT nnnn

67 AT nnnn

68 AT nnnn

70 AT nnnn

71 AT nnnn

72 AT nnnn

80 AT nnnn

81 AT nnnn

A record update not proceded by a READ

DFR length > 512 for operations on the ITRO peripherals
Attempt to process an unopened file

DTF already opened

Occupied keyboard (internal error: call SSS IVREA)
Channel not present or not functional

Peripheral identifier wrong in a SEND/RECV instruction
Command not provided

Wrong commands in the SIC peripherais programming
SIC peripheral unit in local mode

Unaxpected name specified in a CALL statement
Incorrects parameters used in a CALL statement

The CALL RTR is not proceded by a CALL MCP

The “end-position” parameter specified in the EXTS function is invalid

The “start-position” parameter specified in the EXTS function is invalid

DESCRIPTION H ACTION TO BE TAKEN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN
```

---

## Page 145

```
L9L

/BAS I pr-name - ERR. 82 AT nnnn

/BAS I pr-name - ERR

. 83 AT nnnn

IBAS I pr-name - ERR. 84 AT nnnn

{BAS ll pr-name - ERR. 85 AT nnnn

/BAS I pr-name - ERR

/BAS IMI pr-name - ERR

/BAS I pr-name - ERR.

/BAS I pr-name - ERR

/BAS Il pr-name - ERR.

. 86 AT nnnn

. 87 AT nnnn

. 88 AT nnnn

. 89 AT nnnn

90 AT nnnn

The length of “string-operand 2” is greater than the length length of “sub-string” in the
function

The parameters specified in the SCN function are invalid

UNS function cannot be executed

KEY function cannot be executed because no S key was pressed

The string specified in the PACK function is not numeric

The string specified in the PACK function is null

The parameters used in the ROUND function are invalid or inconsistent
The “‘file-designator” specified in the LINE or COL function is invalid

internal error

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + IGNORE/KILL + RUN

TEST + KILL + RUN
```

---

## Page 146

```
col

VW ww rw,
OCLCPY PROGRAM ERRORS -

DESCRIPTION

The text section relating to the code of the module to copy to the editing file is empty

The module to be copied into the editing file does not exist

The editing file is too small to contain the module to be copied

EFFECT

OCLCPY
program
aborts
```

---

## Page 147

```
Sol

YW

GPTE PROGRAM ERRORS

ERR. 001

Invalid command or empty program

DESCRIPTION

ERR. 002

Line outside program

ERR. 003

Not-existent line

ERR. 004

Old string or empty new string

ERR. 005

Invalid operand

ERR. 006

incorrect context

ERR. 101

Line overflow

ERR. 102

Scan not operated

ERR. 103

New string absent

ERR. 104

Unrecognized command

ERR. 105

Underflow on the program

ERR. 106

End of program

ERR. 107

Work file overflow

ERR. 108

Incorrect lower line

ERR. 204

The source file is empty

ERR. 205

The work file is not adeguately dimensioned
```

---

## Page 148

```
99L

ERR. 206 Editing file overflow

Empty line

ERR. 208 The work file extent is not adeguate to open an editing session
(the work file extent is less than 16 sectors).
```

---

## Page 149

```
Lu

OCLSYN PROGRAM ERRORS

Syntetically invalid label in the “label'’ field

The “verb” field contains a verb not recognized in OCL

Close line bar is found before the character “;” or, before the quotes characters (’’) at the end
of a constant

Jump to a statement found in a FOR-NEX loop

NEX not preceded by a FOR

The arrival label of a jump is not found in the program

Invalid KIN operands of an STR statement not followed by the characters ‘‘J” or “O”
Operand not recognized

Syntatically invalid operand

END of statement indicator (;) found within the statement

A backspace is present in a comment statement

The comment statement is longer than 78 bytes

FOR not followed by a NEX

Unexpected oparator in IFC or ONV statement or unexpected visual-type in a MES statement

The numeric value of a constant is out of range
In a FOR-NEX loop a FOR statement is present

Variable prefix different from J, L, PorS

The label is ignored

The statement is ignored until it
reaches the closure ‘“;"

The analysis proceeds on the
next line, considering it the
continuation of the proceding
line

The label of the jump is ignored
NEX statement is ignored

The arrival label is ignored

The operand is ignored
Operand is ignored

Operand is ignored

The statement is ignored

The backspace is ignored

The analysis continues

The FOR statement is ignored

The statement is ignored until
it reaches the closure ‘“;”

The numeric constant is ignored

The first FOR analyzed is
considered closed

The variable is ignored

z
Q
d
d
iù
7)
oO
z
E
a
ui
=
iù
Zz
```

---

## Page 150

```
Sot

DESCRIPTION EFFECT ACTION
a

The line is greater than 80 characters

STR is not present in the program
The statement contains contiguous quotes characters ("’)

_Two or more statements are referenced with the same label

The line is only composed of blanks

Invalid character separator between two arithmetic operands

The STR statement is refenced with a label

The statement does not End with the “;” characters

The STR statement is not in a pre-eminent position
Invalid “‘marker-position” operand in a KIN or MES statement
indicates the presence of a RUN statement in an OCP program

The number of labels is greater than 1000

The label does not begin with a numeric character

Incorrect enabling of special Key option in KIN

The line is truncated to 80
characters

It is assumed a j-type program
Tha constant is ignored

The labels that follows the first
are ignored

The line is ignored

The statement is ignored until
it reaches the closure (;)

The label is ignored

All the lines between the end
of the statement and the first “;”
character found will be ignored

The STR statement is ignored
The statement is ignored
The statement is ignored

The analysis of the program is
interrupted

The label is ignored

The option is ignored

z
9
a)
a)
uy
d
oO
z
E
ran)
ww
=
i
z
```

---

## Page 151

```
ln d

ERRORS RECORDED ON THE STATUS LINE OF THE VIDEO
e Teme | me Te

Syntactical analysis aborts

\w ww

Missing END statement (EOF before the end of the source program)
Overflow in the library where the program is to be catalogued Syntactical analysis aborts
The module to be catalogued with “B” or “‘R’’ modality does not exist in the library Syntactical analysis aborts

The module to be catalogued with “A” modality already exists in the library Syntactical analysis aborts

O
Zz
EO
ae
ws
WW
2a
z

691
```

---

## Page 152

```
ZI

‘Se ho ld Sd

DEBUGGING COMMAND ERRORS

DESCRIPTION ACTION TO BE TAKEN

/OCS I prname - ERR. 5 breaks are already activated on one line

/OCS I prname - ERR. The 5 allowed breaks on one line are completed and the rest are refused
/OCS @ prname - ERR. The 5 allowed breaks on a c.e. name are completed and the rest are refused
/OCS @ prname - ERR. Line-num does not defined the beginning of a statement

/OCS I prname - ERR. The statement number to jump to does not exist

/OCS @ prname - ERR. Fetch is not operational on an inexisten line

/OCS @ prname - ERR. Display command without operand

/OCS @ prname - ERR. Write command without operand

/OCS Il prname - ERR. Erase command without operand

/OCS I prname - ERR. Statement number not included between 1 and 9999

/OCS  prname - ERR. Syntatically invalid command name

/OCS E prname - ERR. Unidentified command

/OCS @ prname - ERR. Syntatically invatid c.e. name

/OCS @ prname - ERR. c.e. name that does not begin with a J, P, L, or S character
```

---

## Page 153

```
ELL

we

ww

Ww

PROGRAM ERRORS AT RUN-TIME DECLARED BY THE OCL INTERPRETER

/OCS M prname - ERR. 000 AT line
/OCS I prname - ERR. 002 AT line
/OCS I prname - ERR. 004 AT line
/OCS E prname - ERR. 005 AT line

/OCS @ prname - ERR. 006 AT line
/OCS @ prname - ERR. 007 AT line
(OCS HW prname - ERR. 008 AT line
/OCS Mi prname - ERR. 009 AT line
‘10CS8 @ prname - ERR. 010 AT line
/OCS II prname - ERR. 011 AT line
/OCS E prname - ERR. 012 AT line
/OCS Il prname - ERR. 013 AT line
/OCS I prname - ERR. 016 AT line
/OCS @ prname - ERR. 018 AT line
/OCS I prname - ERR. 031 AT line

/OCS @ prname - ERR. 039 AT line
/OCS if prname - ERR. 050 AT line
/OCS E prname - ERR. 053 AT line
/OCS @ prname - ERR. 054 AT line
/OCS i prname - ERR. 055 AT line
/OCS E prname - ERR. 056 AT line
/OCS ™ prname - ERR. 057 AT line

DESCRIPTION

RAM overflow for user module

The name of a c.e. is not present in the defined area
The index variable expressed in a c.e. name contains a c.e. that is not numeric

The index variable expressed in a c.e. name contains a value that is not

included between 0 and 99

Communication area overflow

Attempt to erase a c.e. that is present in area

Label has less than four characters

Attempt for decessing a statement in the cycle
Prefixed quantity in the HEX is missing or contains character that are not

hexadecimal

‘‘default-par’’ inconsistent with the type and length of the c.e. input
Non-numeric operand in an arithmetica! expression

Overflow sum (result greater than 1012—1)

Underflow difference (result is less than 0)

Overflow product (result greater than 10'2—1)

Attempt to divide by 0

Unidentified remainder upon attempted division by 0

Attempt to erase a c.e. that has been given a value longer than a 63 characters

Attempt for modifyng c.e. of SCEA : SDATE or SPRGN

Arrival label on a jump does not exist

Arrival label on a jump has a non-numeric prefix

Control variable modified with a non-numeric c.e.

Comparison variable modified with a c.e. greater than 99

IFC/LET/MES/ONV
CAN/IFC/LET/MES/ONV
CAN/IFC/LET/MES/ONV

LET/ONV

CAN
GOTHFC/KIN/MES/ONV
GOT/IFC/KIN/MES/ONV
GOT/IFC/KIN/MES/ONV
FOR - NEX
FOR - NEX
FOR - NEX
LET

KIN
LET
LET
LET
LET
LET
LET

KILL + RUN

STATEMENT
ACTION SERRE
a A

(SYS
```

---

## Page 154

```
UZA!

/OCS Ml prname - ERR. 061 AT line

/OCS Il prname - ERR. 062 AT line

STATEMENT
DESCRIPTION INTERESTED ACTION | EFFECT
A A

Positioning of the marker on a column out of the screen or on a row that
is not numeric or not present

Positioning of the marker on a column out of the screen or on a “column”
that is not present

/OCS I prname - ERR. 063 AT line
/OCS E prname - ERR. 076 AT line
/OCS I prname - ERR. 088 AT line
/OCS @ prname - ERR. 089 AT line
/OCS @ prname - ERR. 090 AT line
/OCS @ prname - ERR. 100 AT tine

(OCS Ml prname - ERR. 103 AT line

{OCS E prname - ERR. 117 AT line

Wrong vertical tabulation on video

More than 20 c.e. names in an ARG statement
The c.e. “prg-name” has more than 6 characters
The c.e. “mod-par” has more than 6 characters

Internal interpreter error

BCOS II function not executed correctly
LYMOD is not present in the area or contains an unaxpected c.e.

OCP not enables to generate a parameter module

KIN/MES

KIN/MES

MES
ARG
RUN
RUN

KILL + RUN ISYS

e
```

---

## Page 155

```
SLI

\n w d d

PROGRAM ERRORS AT RUN-TIME DECLARED BY THE BAL INTERPRETER

DESCRIPTION

The length of a C - type parameter is equal to 0 in BCOS system function

/BAL I prname ERR. 10
11

/BAL i prname ERR. The length of an input parameter expressed in PLAB is equal to 0

12 The c.e./parameter that is to be taken from the J, P or L area is not present in the area

/BAL @ prname ERR.

13 The parameter to be loaded into the J, P or L area cannot be contained in that area

/BAL I prname ERR.

14
15
16
/BAL Ml prname ERR. 17

BAL @ prname ERR. The overlay to be loaded into memory is not present in the current library

IBAL @ prname ERR. Invalid parameter development in a BCOS system function

The program has never executed a RSRT (restart) instruction

/BAL I prname ERR.

The PLAB label declared in the directory is not present in the program

/BAL' Ml prname ERR. 18 The entry-point label declared in the directory is not present in the program

/BAL BI prname ERR. 19 The program that must be loaded into core (memory) cannot be contained in it

/BAL II prname ERR. 20 The operand-field contains an illegal value |
/BAL @ prname ERR. 21 Inconsistent instruction code

22

> DI »pDI DID DINI DID D

- Access to an address out of the memory
- STACK underflow
- Attempted conversion from decimal to binary of a number greater than 65535

/BAL @ prname ERR.

Inconsistent data format

/BAL IR prname ERR.

Undefined label

/BAL I prname ERR.

- Decimal overflow
- STACK overflow

/BAL II prname ERR.

IBAL Mf prname ERR. Missing peripheral unit

The commands directed towards a front feed do not follow an inconsistent order

/BAL BI prname ERR.
```

---

## Page 156

```
ZLI

Ww

‘SYS ERR. 001

PIOCS

The disk containing the operating system is not on-line

R + RUN

/SYS ERR 004 finame FDn

PIOCS

File not found in drive n.

(TEST+ K)/R + RUN

/SYS ERR 006 FDn

PIOCS

Non-extractable disk

(TEST+ K)/R + RUN

{SYS ERR 050 flname

FD LIOCS

The file validity date has expired

(TEST+ K)/i + RUN

/SYS ERR 051 finame

FD LIOCS

The file validity date is still due

(TEST+ K)/i + RUN

ISYS ERR 075

LIOL

OPENL input parameters are incorrect CLOSEL input parameters are incorrect

TEST + RUN

/SYS ERR 076.

LIOL

CLOSEL input parameters are incorrect

TEST + RUN

ISYS ERR 077

LIOL

FINDM input parameters are incorrect

TEST + RUN

(SYS ERR 078

LIOL

NEXT input parameters are incorrect

TEST + RUN

(SYS ERR 079

LIOL

LOADM input parameters are incorrect

TEST + RUN

/SYS ERR 080

ADDM input parameters are incorrect

TEST + RUN

/SYS ERR 081

PUTC input parameters are incorrect

TEST + RUN
```

---

## Page 157

```
SLi

/SYS ERR. 082

Program already catalogued completely

ACTION

TEST + RUN

‘SYS ERR 084

DELM input parameters are incorrects

TEST + RUN

ISYS ERR 085

Function not performed: system waits for PUTC to complete program cataloguing

TEST + RUN

ISYS ERR 088

Library DTF is not allocated

RESET

/SYS ERR 089 pname

Disk has been changed prior to the closure of the file being precessed

/SYS ERR 101 pname

PR LIOCS

Incorrect input parameter in CLOSE statement

TEST + RUN

PR LIOCS

Incorrect input parameter in PRINT statement

TEST + RUN

/SYS ERR 103 pname

PR LIOCS

Input parameters error of the printer REDEFINE function

TEST + RUN

/SYS ERR 104 pname

PR LIOCS

The dtf-num of the message file on the printer has not been opened

TEST + RUN

/SYS ERR 105 pname

PR LIOCS

Incorrect input in ANACRT

TEST + RUN

/SYS ERR 106 pname

PR LIOCS

The parameters within the printer OPEN statement are incorrect

TEST + RUN
```

---

## Page 158

```
GLI

/SYS ERR. 108 pname

PR LIOCS

DESCRIPTION

Incorrect input in RDPOS

TEST + RUN

/SYS ERR 108 pname
(mono-system)

PRAT (multi-system)

PR LIOCS

(in MONO-system)
(in MULTI-system)

Printer in local/end of paper

R + RUN

/SYS ERR. 110 pname

PR LIOCS

Printer/screen controller is faulty or is not present

(TEST+ K)/t + RUN

/SYS ERR 111 pname

SK LIOCS

Error in input parameters of the functions on video-keyboard

TEST + RUN

/SYS ERR 112 pname

SK LIOCS

OPEN not carried out on the video-keyboard peripheral

TEST + RUN

/SYS ERR 113 pname

PR LIOCS

The required printer is not loaded

TEST + RUN

{SYS ERR 117 pname

PR LIOCS

Parameter errors in a function on AFF

RESET

{SYS ERR 118 pname

PR LIOCS

The required operation is not supported on AFF

RESET

/SYS ERR 105 pname

PR LIOCS

The linked-up printer is not loaded with AFF

RESET

/SYS ERR 106 pname

PR LIOCS

The punch card for AFF deposit has been badly introduced

TEST + RUN

CONTROL

ROLLIN cannot be executed

TEST + RUN
```

---

## Page 159

```
agi

come COMPONENT DESCRIPTION TYPE ACTION
A

SYS ERR. 152 pname CONTROL The syntax of the entered string is incorrected

/SYS ERR 153 pname CONTROL The program named “pname” is not present in the library

/SYS ERR 154 pname CONTROL The parameter module in input to the program is incomplete and the OCP that
completes it is a not in the library
Pname not called from the Ready state

/SYS ERR 155 lioname CONTROL There is no library called “‘libname” on line RESET

/SYS ERR 156 pname CONTROL The program indicated in the RUN statement of JOCP is not found in the TEST + RUN
current library

/SYS ERR 157 pname CONTROL JOCP nesting level is greater than 1 TEST + RUN

/SYS ERR 158 pname CONTROL The parameter module belonging to the program “‘pname” is not in the library TEST + RUN

/SYS ERR 159 pname CONTROL The OCP program named “pname” is not present in the current library TEST + RUN

/SYS ERR 162 pname CONTROL Parameter module is associated to a non-parameter driven program “pname” TEST + RUN

/SYS ERR 163 CONTROL “TEST” presetting not active TEST + RUN

/SYS ERR 164 FD LIOCS ROTF/WROS/RDOS input parameters contain an error TEST + RUN
```

---

## Page 160

```
L8k

/SYS ERR. 165

TERMINATOR

TYPE ACTION

The parameter module “outpar-name”’ is already contained in the library TEST + RUN

/SYS ERR 166

TERMINATOR

Library overflow caused by parameter module cataloguing TEST + RUN

ISYS ERR 167

CONTROL

Program is written in a language that is not handled by BCOS Ii TEST + RUN

ISYS ERR 168

TERMINATOR

End of OCP

Parameter module has been catalogued RESET (YES)

Is the parameter driven ASSEMBLER/BASIC program using OCP to be run?

YES - NO. TEST + RUN (NO)

/SYS ERR 172 pname

CONTROL

Insufficient memory to contain the request program execution RESET

/SYS ERR 173

CONTROL

BASIC Editor is not free at this moment in that partition RESET

/SYS ERR 175 pname

CONTROL

Library has already been reserved RESET

{SYS ERR 200

CONTROL

Ce type not known TEST + RUN

(SYS ERR 201

CONTROL

Ce length not accepted TEST + RUN

ISYS ERR 249

DRS

Recovery file section is inadeguate for the dump RESET

/SYS ERR 250 pname

EOF on recovery file after ROLLOUT RESET
```

---

## Page 161

```
gl

/SYS ERR. 251 pname

Mcp-type is unknow, or else recovery has not been carried out

RESET

/SYS ERR 252 pname

EOF on recovery file, following memory check-point

RESET

/SYS ERR 253 pname

ROLL command not accepted in Editor Basic

RESET

/SYS ERR 258 pname

ROLL command not accepted during ROLLOU run-time

RESET

/SYS ERR 261 pname

The position of disks at restart-time is not the same as that at the last MCP
Internal system I/O error
Call OLIVETTI system technician

TEST + RUN

ISYS ERR 270

ISYS ERR 271

INQUIRY

A non-existent INQUIRY command has been requested

RESET

INQUIRY

The requested INQUIRY command has not been executed

RESET

/SYS ERR 500

PIOCS

Internal I/O error
Call OLIVETTI system technician

TEST + RUN

/SYS ERR 502

The code of the command given in CCF is not correct
Call OLIVETTI system technician

TEST + RUN

‘SYS ERR 503

The code to read from/record on disk is greater than 16.384 bytes or is equal to @
Call OLIVETTI system technician

TEST + RUN
```

---

## Page 162

```
esl

| cove COMPONENT DESCRIPTION TYPE ACTION

/SYS ERR. 504 PIOCS

Incorrect track addres in CCF TEST + RUN
Call OLIVETTI system technician

/SYS ERR 505 Number of start sector does not conform to disk characteristics TEST + RUN
Call OLIVETTI system technician

iSYS ERR 510 The head access arm of the FDU is unable to position itself correctly on the disk TEST + RUN

‘SYS ERR 511 CRC error during disk reading/recording TEST + RUN

SYS ERR 513 FDn FDn out of service during I/O phase TEST + RUN

/SYS ERR 516 FDn The system hardware does not comprise drive n of FDU/DCU TEST + RUN

/SYS ERR 518 FDn Attempt to access a disk which is not available TEST + RUN

{SYS ERR 519 FDn PIOCS There is no file opened on disk n. TEST + RUN

iSYS ERR 552 FD LIOCS Requested file has not been opened TEST + RUN
/SYS ERR 553 FD LIOCS Type of data file is inconsistent with the structure of files TEST + RUN
handled by BCOS Il

/SYS ERR. 554 filname FD LIOCS I/O function not allowed on the file TEST + RUN
```

---

## Page 163

```
vel

/SYS ERR. 555

FD LIOCS

YO function not preceded by record reading

TEST + Ri

UN

ISYS ERR 556

FD LIOCS

Key file not contained on disk

TEST + RUN

ISYS ERR 557 flname

FD LIOCS

The parameter indicated in an OPEN file statement are not consistent with the data
of the label

TEST + RUN

FD LIOCS

Attempt to open a protected file in output/update/undefined mode

TEST + RUN

FD LIOCS

Incorrect operation in OPEN

TEST +R

{SYS ERR 562

ISYS ERR 563

ISYS ERR 565

DK LIOCS

Type of scanning is not E, Gort

TEST +R

UN

UN

DK LIOCS

Type of device is inconsistent with operations required

TEST + RUN

LIOCS

Input parameter errors at INFO-FLE

TEST + Ri

UN

FD LIOCS

Partition data overflow

RESET

/SYS ERR 566

FD LIOCS

Work not consistent with reservations mode

RESET

/SYS ERR 569

FD LIOCS

Overflow on system’s global data

RESET

/SYS ERR 570 finame

FD LIOCS

The requested file has not been reserved

RESET
```

---

## Page 164

```
sel

COMPONENT DESCRIPTION ACTION

/SYS ERR. 672 finame FD LIOCS File not closed during processing RESET

{SYS ERR 600 pname DK LIOCS Overflow in system dynamic area TEST + RUN

/SYS ERR 700 pname PIOCS Hardware anomaly during a command call TEST + RUN

{SYS ERR 702 pname PIOCS CCF parameters, necessary for command execution are incorrect TEST + RUN

/SYS ERR 703 pname PIOCS Disk unit name is incorrect TEST + RUN

{SYS ERR 710 pname PIOCS Protected disk during WRITE operation TEST + RUN

{SYS ERR 712 pname PIOCS Hardware anomaly during command execution TEST + RUN

/SYS ERR 714 pname Disconnect FDU TEST + RUN

NOTE: You activate the TEST function by pressing the command key's CONTROL + RUN, (led L2 on)
```

---

## Page 165

```
BCOS Il UTILITIES

BCOS Il UTILITY PROGRAMS

BCOS Il UTILITY MESSAGES

GUIDE TO OPERATING REQUESTES OF THE DELPRG
AND PRDKDK UTILITIES

SORT: WORK-FILE DIMENSIONING

ERRORS DECLARED BY THE BCOS Il UTILITIES
SORT UTILITY ERRORS

187
191
197

199
201
203

BCOS Il

UTILITIES
```

---

## Page 166

```
18L

ln

BCOS II UTILITY PROGRAMS

ATTRIB

MEANING.

Modifies the characteristics of user library modules

Reserve program send out from /SYS
Permit subroutine restart
Region definition

CLEAR

Releases the preceding locked resources

CONVBC

Converts basic module from M40 to BCS 2000 video oriented

COPYFL

Copies the contents of a data file resident on disk/data set

Sequential file copying
Keyed file copying

COPYLB

Copies the contents of a library

Sistem library, copying
User library copying

DELLAB

Delete the last file label on disk/data set

Data file deletion
Library file deletion

DELPRG

Logical deleting of a library module existing on disk/data set

Deletion of system library modules
Deletion of user library modules

DKCOPY

Selective copy file from disk to disk

DKDK

Phisical copying of the contents of a disk/data set

System disk copying
User disk copying
```

---

## Page 167

```
88L

Prints or displays the contents of a disk

FUNCTION

Drive name FDn (1 Sn S 4)
Data set name HDnn (1 S nn S$ 64)

DUMPDS

It carries out the phisical copying of a user data-set
from a fixed.

Support (HDU) into a removable

Support (FDU, SCT) and viceversa

Physical copying of a user data-set from HDU (FDU) to FDU (HDU)

Physical copying of the user data-set fro HDU (SCT) to SCT (HDU)

FILEPT

Data file contents printing or display

FLELAB

Generation of a data or recovery file on disk/data set

Protection file generation

Data file generation with basic label
Data file generation with extended label
Work file generation

PRDKDK

Copy of a library module on disk/data set into another library

Copying a system library modules
Copying a user library modules

PREFIL

Fills file records resident on disk/data set to 7F

Fill non-significant records of a partially full file to 7F
Fill all file records to 7F

PRGDIR

Print/display of the library directory on disk/data set

Print/display of directory of a system library
Print/display of directory of a user library

PRGLAB

Generation of a library on disk/data set

System library label generation

User library label generation
```

---

## Page 168

```
68L

PRTLAB

Print/display of labels on disk/data set

Volume label print/display
Print/display of all file labels present in VTOC
Print/display of a specific label

RENAME

Redefines a disk/data set name

Change data file name
Change library file name

Orders the records within the data file or files stored on a
disk/data set

Sort

Selection phase
Moving phase
Verify

Verify and change

VOLLAB

Volume label generation or modification

Volume label creation

Volume label modification

Volume label modification and deletion of all the file labels which
may be present
```

---

## Page 169

```
L6L

BCOS II UTILITY MESSAGES

DESCRIPTION

Alligns the paper
Other selection criteria to be assigned (“AND” relations rip. with previous criteria)

Which kind of order

Name to be assigned to the file associated with the output file already declared i

- xxxxxx: is the name of the data/index file associated with the file being processed or eventually, the input file
- (none): the file being processed/input is sequential

must the execution be reserved or free?

The data that will be contained in the file Can be converted to E B CDIC?
Redefine or replace the disk/data set

Confirm the parameters input up to this point?

In what version, would you like the modules that are to be copied

New region value confirmed?

Self-explanatory S i

Table with information on the resources blocked by work-station “x”

ALIGN PAPER
AND RELATION?

ASC. ORDER?

ASSOC. FILE NAME
ASS FL. cccccc (none)

(*) ATTRIBUTE
BYPASS INDICATOR
CHANGE DISK OR UNIT
CONFIRM PAGE?

{(*)] COPY MODE
CONFIRM REGION?
CREATION DATE:

DATA SET N. PRINTER
FILE... T... HD... MODE
DEL.?

(*) DELETE MODE
DISPLACEMENT
DISPLAY ON VIDEO?
DRIVE NAME: yynn

Should the file not be copied or maintained on the output disk?

What version of the program is to be erased?

_Key displacement of “n” bytes with respect to the data record start
Must the output be displayed on the screen? È Set:
yy and nn are, respeetively, the name of the unit (HD/FD), and the number of the drive (1 — 4) or data set (1 — 64)
in which the library is resident
On which track cylinder is the first sector to be printed/displayed found? i i Lisi

End of job: the files named cccccc have not been copied because of the error conditions displayed on the right

DUMP STARTING FROM TRACK NUMB.

cccccc [ERR. xx]
cccccc [ERR. xx]

END OF JOB ;
ENTER CHOICE NUMBER Select the function or utility to be executed
EQUAL KEY? Records with equal key to be erased?

What is the year, month, and day in which the file’s validity expres?

The extent, messured in number of sector in a library, is requested/displayed

What are the characteristic of the module to be copied/erased?

Must the label be printed/displayed in an extended format?

Extract the disk inserted in the “drive-unit” FDx and insert the one that contains the system libra

EXPIRATION DATE
EXTEND DIMENSIONS (xxxxx)
(*) EXTENTION FIELD
EXTEND FORMAT?

FDn: INSERT SYSTEM DISK

previously extracted
```

---

## Page 170

```
cel

FDn: REMOVE SYSTEM DISK

DESCRIPTION

Extract the disk inserted in the “drive-unit” FDx and insert the one on which the copy function is to be performed

_FILE NAME cccccc

The name of the input file is cocccc

FIELD DISPL

Address of the field to be formatted or totalled

FIELD LENGTH

Field length (in bytes)

FORMATTING?

Output record to be-reformatted?

FUNCTION OK: RESET SYSTEM

PRG. name execution correctly ended. System reset must be done.

HARD COPY (Y/N)?

Display to be printed?

IGNORE DEL. REC.?

Deleted records to be ignored?

INCLUSION?

Which records must be included in the order?

[INPUT] DRIVE NAME:

Where is the disk that will be eventually used as input

[INPUT] FILE NAME:

- Wath is the name of the file being processed eventually used in input
- Wath name must be given to the file that is to be created?

INSERT DISK NUMBER xx

Exchange the floppy disk with another floppy disk that has a volume number equal to xx

[(*) INPUT] LIBRARY NAME:

- What is the name of the processing library, eventually in input;
- What name must be given to the library to be created?

(2nd) INPUT FILE NAME

Name of the second input file

(3nd) INPUT FILE NAME

Name of the third input file

KEY DISPL

Length, in bytes of the nth sort key

KEY DISPLACEMENT:

How many bytes form the displacement between the key and the beginning of the record?

KEY FILE NAME:

What name must be given to the index file?

KEY FILE REQUESTED?:

Must the file be organized by keys on disk?

KEY LENGTH:

What is the key length?

KEY TYPE

Type of the sort key

LABEL NAME:

What is the name of the label to be printed/displayed?

(*) LANGUAGE:

In what language are the modules to be copied/erased/written?

LAST PROGRAM EXECUTED: xxxxxx

The last utility executed in xxxxxx

LAST RECORD USED: yyyyyy

yyyyyy is the positional value of the last record to be contained in the input file

MAX RECORD NUMBER: [dddddd]

The maximum number of records that are to be contained in the output file is requested or is displayed

MODULE NAME

What is the name of the module to be copied/erased?

[(*)] MOD[ULE] TYPE:

What is the format of the modules to be copied/erased?

MONT-DISMOUNT OUTPUT — DISK NR. xx

MONT-N = ESCAPE REQUEST: ?

Set-up requested for the FDxx unit for multivolume dump
```

---

## Page 171

```
£6L

MONT-MOUNT OUTPUT
(INPUT) DISK NR. xx
MONT-N = ESCAPE REQUEST: ?

DESCRIPTION

In the dump (restore) phase set-up requested for the FD unit

MSCT-MOUNT OUTPUT
(INPUT) SCT
MSCT-N = ESCAPE REQUEST: ?

In the dump (restore) phase set-up requested for the SCT unit

MULTIVOLUME FILE (S)

Attention: more floppy disks are needed to copy the file

NEW ASSOC. FILE NAME:

What name must be given to the file associated with the file specified in “OLD FILE NAME”?

NEW EXECUTION FOR ANOTHER N.S.? (Y/N)

Self-explanatory

NEW FILE NAME:

What name must be given to the file?

NEW EXECUTION?

Would you like to start a new print/display cycle on t. e same disk or file?

NEW RAGION

New region to be assigned to the module

NEW SPACE
XXXXXX

Request/Confirmation of the extent that must be attributed to the output file

NO EXECUTION REQUESTED

Execution was not requested

NUMB. OF SECTORS TO BE DUMPED:

How many sectors must be printed/displayed?

NUMBER OF RECORD (S):

How many records must be printed/displayed (FILEPT) or, must be contained in the file (FLELAB)?

NUMBER OF MODULES COPIED: xxxxxx

The total number of copies modules is equal to xxxxxx

NUMB. OF TRACKS: xxXXXX

Number of tracks on data set = Xxxxx

OK

Disk/data set confirm

OLD ASSOC. FILE NAME: xxxxxx/(none)

~ XXXXxXxx: is the name of the data/index file associated with the his whose name must be changed
- (none) specifies that a sequential file’s name will be changed

OLD FILE NAME:

What is the name of the file whose name will be changed?

OLD REGION: yyyyy

The module region has yyyyyy bytes (yyyyyy = 0-65535)

OMISSION?

To establish which records must be included

OP1 FILED DISPL

Position of the operand 1 within the record

OP1 FIELD LENGTH

Length (in byte) of operand 1

OP1 FIELD TYPE

Type of operand 1 (selection) operand

OP2 END TABLE

End of table of operands 2?

OP2 FIELD DISPL

Operand 2 position within the record
Displacement (0-255)

OP2 FIELD LENGHT

Operand 2 length
Number of bytes (1-8)
```

---

## Page 172

```
VEL

OP2 LITERAL

DESCRIPTION

Operand 2 is a costant value
OP2 (type A) = 1-63 characters
OP2 (type P) = 1-15

OP2 VALUE?

Do you want to assign a direct value to operand 2?

OR RELATION?

Other selection criteria to be assigned
(‘OR” relationship with the previous group)

[OUTPUT] DRIVE NAME

Where is the disk/data set eventually output, that must be used?

What is the name of the processing file eventually output?

[OUTPUT] FILE NAME
[OUTPUT] LIBRARY NAME

What is the name of the processing library eventually output?

OWNER

What is the name of the disk’s owner?

PASSWORD

Password request which permits utility send-out

POSITIVE?

Has operand 2 a positive value?

PRINT FROM RECORD NUMB.:

From what record number must be print/display begin?

PROGRAM LENGTH: xxxxxx

Modules length

PROTECTION

Is memory protection requested?

PRINT FROM RECORD NUMB.

From what record number must the print/display begin?

RECORD LENGTH:

What is the record length of the file?

RECOVERY FILE EXTENT DIMENSION

How many sectors reserved on disk for the recovery file extent?

RUNNING prg-name

Program execution begins

SECTOR

What position is occupied by the sector from which the print/display must begin within the track/cylinder? Di;

SECTOR/TRACK: yyy

Number of sectors for tracks on data set is yyy

SELECTION?

Do you want to define selection criteria?

SEQ?

Must only the data file be copied?

SORT TYPE?

Which type of sort?

SPACE
ddddd

The extent of the input file is ddddd. For a data file ddddd indicates the number of records contained in the file

SURFACE

On which track is the first sector to be printed/displayed found?

TOTAL OUTPUT

Is totalling of records fields requested in output (on printer)?
```

---

## Page 173

```
sel

TYPE
SYS
LIB
RND
SEQ
REC

DESCRIPTION

The type of input file is:
- SYS: system library

- LIB: user library

- RND: keyed file

- SEQ: sequential file

- REC: recovery file

UNLOCK ALL
RESOURCES (Y/N)?

Are all resources going to be released?

UNLOCK DATA SETS (Y/N)?

Are all datasets blocked by work station ‘x’ going to be released?

UNLOCK FILE (Y/N)?

Are files reserved by work station ‘x’ going to be released?

UNLOCK PRINTER (Y/N)?

Are printers reserved by work station ‘x’ going to be released?

UNPACKED DATA?

Will the file contain only unpacked data?

UNPACKED KEY?

Will the file index contain only unpacked data

VOL INDENT:

What is the disk’s ID?

VOL IDENT xxxxxx
OWNER ZZZzZZZZZZZZZZZZ

The disk's ID is xxxxxx
The owner’s name is 2Z22222222Z2Z22z

VTOC KEY

Sort according to VTOC key?

WARNING 25 MISSING LIBRARY “v00xxx” on FDn
CREATE? (Y/N) CDn

Attention: the library named xxxxXX does not exist in output
Do you want to creat it?

WORKFL NAME (WKFL)

Name of the work file

WORK STATION NUMBER: X

Blocked/released resources refer to work station “X"

WRITE PROTECTED DISK

Attention: in output, the disk contains the active system library

(*) WRITING MODE

In what mode must the modules be copied in output?
```

---

## Page 174

```
L6L

OF THE DELPRG AND PRDKDK UTILITIES

MODULE VERSION
LANGUAGE FORMAT P|

ERATING REQUESTES

BAL program cccccc

GUIDE TO THE OP

MODULE TYPE PRESENT
IN LIBRARY

EXTENSION
FIELD

Aol]

cccccce

EXTENTION FIELD

Y = Program requiring parameter module

N = Without parameter module

cccccc = Name of the alternative system module overlay
or of the BAL program overlay

*C = Complete parameter module

*p = Incomplete parameter module

*G = Complete parameter module with ARG area

* = JOCP procedure

*p = Parameter generating program

BASIC program cccccc

LANGUAGE

A = Absolute

B = Basic

P = Parameter module
oO = OCL

L= BAL

JOCP procedure ceccccc

cccccc sf

«ALLELE

NOTE: I only requested by DELPRG

Pàrameter generating
program (OCP)

_ —

*
——_.
|
— | —_T

o
a79MO are
pipe meen) pene ee
*O *O
n —_——

MODULE TYPE

O = Object module
S = Module containing source information

Parameter module

VERSION

A = All module versions
B = Only the back-up module version

Generic program
Z8969

The asterisk * rapresents the default request
```

---

## Page 175

```
rr _—m—_  UlUl———
w ww

SORT: WORK-FILE DIMENSIONING
uN ————worerng ommeion DIMENSION

NORMAL | = O
ADDROUT W.F. sectors = 1 + 2B W.F. sectors= 1 + A + B

ADDROUT + KEY

W.F. sectors= 1+A+C+D

W.F. sectors = 1 + 2B+ D

NORMAL | = O

66}

“ee (KL + 4) X NRI (rounded off to a multiple of 4096)
LSW

- D = number of W.F. sectors used for the input file copy

-C= NRL AS (rounded up to next whole number)
LSW

(KL+ 4) XNRI_ (rounded up to next whole number)
LSW

- NRI = number of records in the output file

-A=

- KL = Keys total length
- LSW = WE. sector length (128/256)
```

---

## Page 176

```
WARNING

ERROR: CODE DESCRIPTION

: FDx MISSING

UTILITY: NAME

ATTRIB

CLEAR

CONVBC

DUMPDS

FLELAB

PRTLAB

WARNING

: MISSING VOLUME LABEL ON FDx (HDx)

@®@©| DELLAB

@\@| DELPRG
e|e| DKCOPY
@\e| FILEPT

@e|e| PREFIL

®|e| PRGDIR

®|©| PRGLAB

@e|e| RENAME
VOLLAB

WARNING

: SAME INPUT-OUTPUT UNIT NAME

INCOMPATIBLE DISK ON FDx (HDx)

WARNING

: WRONG CHOICE NUMBER

e|e|-\ele| COPYFL

@\@|x\e@/e| COPYLB

@\e|x\|e\e| PRDKDK

WARNING

2
3
4
WARNING 5:
7
8

: NON-USER DISK ON FDx (HDx)

0 |e|e-@@®| DKDK

WARNING 9:

WRONG ADDRESS: RETYPE DATA

WARNING 10:

NON-SYSTEM DISK ON FDx

WARNING 11:

MISSING FILE NAME ON FDx (HDx)

WARNING 12:

EMPTY FILE ON FDx (HDx)

WARNING 13:

RECORD NUMBER OUT OF EXTENT

WARNING 14:

INCOMPATIBLE EXTENT ON FDx

WARNING 15:

INCOMPATIBLE RECORD SIZE ON FDx

WARNING 16:

SYSLIB ALREADY EXISTING ON FDx

WARNING 17:

LIB NAME ‘“xxxxxx"” ALREADY EXISTING ON FDx

WARNING 18:

nnnnnneccccvit ALREADY EXISTING ON FDx CONTINUE?: (Y/N):

WARNING 19:

RESET SYSTEM

WARNING 25:

MISSING LIBRARY ‘‘xxxxxx’’ ON FDx (HDx) CREATE?: (Y/N):

WARNING 27:

EMPTY LIBRARY ON FDx (HDx)

WARNING 28:

INCOMPATIBLE LIBRARY TYPE ON FDx (HDx)

WARNING 29:

FILE ALREADY EXISTING ON FDx (HDx)

WARNING 30:

INCOMPATIBLE FILE TYPE ON FDx (HDx)

WARNING 31:

INCOMPATIBLE ASSOCIATED FILE ON FDx (HDx)

WARNING 32:

WRITE PROTECTED FILE: CONTINUE?: (Y/N)

WARNING 33:

“ERPO/ERCE” ERROR AT xxxxxx ADDRESS: CONTINUE?: (Y/N):

WARNING 34:

MISSING ASSOCIATED FILE ON FDx (HDx)

WARNING 36:

NOT POSSIBLE FUNCTION

WARNING 38:

WRONG CREATION DATE

WARNING 39:

WRONG EXPIRATION DATE

WARNING 40:

EMPTY DISK

WARNING 60:

FDx (HDx) TEMPORARY NOT AVAILABLE DISK REPEAT?: (Y/N):

WARNING 62:

LIBRARY ‘‘xxxxxx”’ IS CURRENT SYSTEM LIBRARY CONTINUE?: (Y/N):

WARNING 63:

FDx (HDx) IS CURRENT SYSTEM DISK CONTINUE?: (Y/N):

WARNING 65:

NO RESOURCE LOCKED BY THIS WORK STATION

ERROR 12: EMPTY FILE

ERROR 31: xxxxxx ALREADY EXIST ON FDx/HDx

>

ERROR 32: OUTPUT LIBRARY OVERFLOW

ERROR 34: FULL DISK

ERROR 35: DISK OVERFLOW

> |>

> |>|>

> |>

ERROR 36: NOT POSSIBLE FUNCTION

>

ERROR 37: MODULE IDENT ‘‘xxxxxx” MISSING

ERROR 40: EMPTY DISK

ERROR 41: VOLUME NOT IN SEQUENCE

ERROR 42: MISMATCHED FILE SEGMENTS

ERROR 43: FILE NOT ALIGNED

ERROR 44: OUTPUT FILE WRITE PROTECTED

> |>|>|>

ERROR 45: INSUFFICIENT MEMORY SIZE

ERRORS DECLARED BY THE BCOS II UTILITIES

@ : re-input of parameters A:
x : re-cycles to an intermediate request C:

ERROR 61: SOME PREVIOUS PARAMETERS NO MORE VALID

abort / end program (/SYS)
continue

201

A

>

A

A
```

---

## Page 177

```
£02

ww lo È + gd

SORT UTILITY ERRORS

SORT: ERRORS IN THE PARAMETER ACQUISITION PHASE

ERROR: INPUT EQUAL OUTPUT FILES
INCHOER RECORD LENGTH ON INPUT FILES
INCHOER RECORD LENGTH ON OUTPUT FILES =
FILE MISSING ON FDx (HDx)

FDx MISSING

DISK UNIT NOT AVAILABLE

MISSING VOLUME LABEL ON FDx (HDx)
INCOMPATIBLE FILE TYPE ON FDx (HDx)
EMPTY FILE ON FDx (HDx)

ERROR: OUTPUT EQUAL WORK FILES
INVALID KEY

TOO LONG KEYS È
TOO LONG VALUE

OVERFLOW RELATION IGNORED

INVALID FORMAT

mi: re-input of parameters

SORT: ERRORS IN THE EXECUTION PHASE

FILE OVF. *ABRT

WF OVF. *ABRT

LL. REC. INCHOER. *ABRT
INV. KEY *ABRT

ALL REC. ARE DELETED
MEMORY OVF. *ABRT

NO REC. SELECTED
UNPACKED FIELD IN SELECT. *ABRT si
WRONG RESTART *ABRT
UNPACKED FIELD IN TOT.
OVERFLOW IN TOT. No. 1
OVERFLOW IN TOT. No. 2
A: abort/forced end of execution
C: processing continues, putting the field back to zero and starting adding again

af
```

---

## Page 178

```
OSLEM UTILITIES

- OSLEM UTILITY PROGRAMS
- ERRORS SIGNALED BY OSLEM UTILITIES

205
207

OSLEM

UTILITIES
```

---

## Page 179

```
S0%

n a

OSLEM UTILITY PROGRAMS

System configuration

Configures screen-keyboard, printers, the HDU units,

Disk copy

DESCRIPTION

and the floppy disk

Copies the contents of a data-set onto one of more floppy-disk and viceversa

Disk restore

Restores the contents of the installation disks on ha

FF data-set dump between HDU and SCT units

rd-disk

Allows dump operations to be carried out on the “FF” data-set between the hard-disk and streaning tape cartridge

Jx24

Formatting track @ of the hard-disk

Mx24

Defines the hard-disk extent

OSLEM disk generator

Copies the contents of a floppy-disk in output from the multi HDU-FDU SYS procedure, onto hard-disk

data-set “FF”

Dump/restore between HDU units and
SCT units

It allows dump and restore operation to be carried 0
streaning tape cartridge units

ut on user data-sets between hard-disk units and

Data-set configuration from SCT

Defines one or more data-sets on hard-disks

Data-set configuration from FDU

The utility functions are the following:

- data-set creation - TOC display
- data-set modification - printing the contents of TOC

- data-set deletion - emptying TOC
```

---

## Page 180

```
L0G

f

ln

ERRORS SIGNALED BY

MESSAGE/REPLY

DIK£ - AFTER ANY KEY: REPEAT:

OSLEM UTILITIES

Message common to all error signals for redefinition of supports
It signals that after pressing any key, the program starts from the beginning again

DIK£ - ERROR IS = SAME

Signals that DK1 and DK2 cannot operate on the same unit

DIK£ - ERROR IS = NODK

Signals that the value of the requested volume is not included in the list of current disks

DIK£ - ERROR IS = 8305

The defined unit is not in place
Install the unit and repeat the support declaration operation

TOC£ - WARNING DATA SET OVERLAY

Signal that at data-set creation a user data-set overlay has been found

SCT£ - DUMP <=> SCT - ABORT

The utility is terminated due to an error, or at the operator's explicit request

SCT£ - DESTINATION VOL. OVERFLOW

The operation has not been completed during the restore phase as the output data-set is too small
to contain all the information on the streaming cartridge tape; the restore is valid only up to this point

SCT£ - INCOHERENT SCT INPUT

The support used during the restore phase has not been used previously and contains no information
```

---

## Page 181

```
Pen

FILE SYSTEM

- DISKETTE / FLOPPY DISK:

@ GENERALITIES

@ CONTENTS OF THE @ TRACK

@ STRUCTURE OF THE 5° SECTOR OF THE @ CYLINDER
- HARD DISK:

@ GENERALITIES

@ CONTENTS OF THE @ CYLINDER
- STREAMING TAPE CARTRIDGE:

@ GENERALITIES

- VOLUME LABEL STRUCTURE
- LABELS STRUCTURE OF THE FILES
- FILE LIBRARY: CONTENTS OF A:MODULE-DESCRIPTOR

209
210
211

213
214

215

217
219
225

FILE

SYSTEM
```

---

## Page 182

```
N
(©)
o

DISKETTE AND FLOPPY DISK: GENERALITIES

PHYSICAL CHARACTERISTICS

Sectors Bytes for sector Resana type
Available cylinders (packing)
available KB
cylinder fan track D track @ (surf. 1) track © track @ (surf. 1)
surface © cylinders 1-73 surface © cylinders 1-73

(*) Cylinders @1-73 are used for data. Cylinder @@ is used to describe the characteristics of the volume and the data it contains.

ss any Available sector

DF
(low packing)

MFM
(high-packing)
```

---

## Page 183

```
Ole

TRACK @ CONTENT (After first initialization)

| sunrace | SECTOR IDENTIFIER BYTE INITIALIZED WITH BLANK CONTENT DESCRIPTION

Reserved for the system

Reserved for error map label

Reserved for future standardizations

Reserved for volume label

DDRI1 Deleted

Reserved for file labels

DDRI Deleted

Reserved for file labels
```

---

## Page 184

```
La

FIELD NAME

LABEL IDENTIFIER

Identifies the ERMAP label

(reserved)

Not handled

DEFECTIVE CYLINDER IDENTIFICATION 1

@ no faulty cylinder during

@ first faulty cylinder

(reserved)

Not handled

DEFECTIVE CYLINDER IDENTIFICATION 2

@ no second faulty cylinder existing
@ indicates the number of the second faulty cylinder

(reserved)

Notes: Ing. OLIVETTI & C. has foreseen use of “error-free” disks only

Data in the table refer to eventual disks from external interchange

Not handled
```

---

## Page 185

```
ELS

we o

HARD DISK: GENERALITIES

Capacity Available Sectors reserved
available sectors per cylinder

PHISICAL CHARACTERISTICS

Available cylinders
or tracks

Sectors per tracks

Bytes per
sector

Recording type
(packing)

MFM
(high-packing)

Available
surfaces
```

---

## Page 186

```
le

CYLINDER @ CONTENT (after initialization)

SECTOR DESCRIPTION

+7 Available for loading of IPL functions
8 Volume label
9 O.S. environment label

Pointers label

Label duplicated

O.S. environment duplicated label

Pinters duplicated tabel

Available for future expansions or reserved use

The “system standard n. 24” describes the contents of the three labels.

e Pea a ~
```

---

## Page 187

```
GL?

lm

STREAMING TAPE CARTRIDG

Formatted capacity
(MB available) per track

* cartridge model “DEI - 1290”

i

E*: GENERALITIES

PHYSICAL CHARACTERISTICS

‘M byte available Minimum to be transfered

(blocks) in KB

Total blocks

Blocks per track
```

---

## Page 188

```
LIT

ww

7

VOLUME LABEL STRUCTURE

FIELD

INITIAL
BYTE

FIELD

LENGTH n

LAB ID
VOL ID
ACCESS

OWNER

SURFACE
IND.

DESCRIPTION

Volume label identifier
Disk volume identifier

File accessibility

Name of the volume owner

Number of surfaces of which the track and the
record type is composed

Managemerit type of the free area in the volume

Track identifier

Phisical sequence type according to which the
sectora are recorded on disk

VOLI

cccccc

B
# 6

= volume accessible to everybody
= = the volume contains to reserved files

Reserved

Reserved
= the magnetic base in a FD with only a write/read side and with a
low-packed recording denalty (DF)

M = the magnetic base has two write/read sides and high-packed
recording denalty (MFM)

2 = the disk has two write/read and is has a low packed recording
denalty (DF)

3 = HD has only one side recorded
4 = HD has two sides recorded
5 = HD has four sides recorded

= the area management is left to the users
P = the free area in the volume follown the extent of the last file

Reserved

= the length of the FD sector is 128 bytes

4 = the length of the sector is 256 bytes. Track @ is always composed
of sectors with length 128 bytes (for FD)

8 = the sectors length for HD is always 256 bytes for sector
Not handled

The sector are always phisically sequential
```

---

## Page 189

```
gia

DESCRIPTION

STOLAB Label type
EXT ID Identifier of the extent field

TRAKNO | Number of track present in the volume

SECTNO | Number of sectors per tracks

BYTENO | Sector length in bytes

FSECNO Logical position assigned to the first sector of each track

Reserved
The label is always extended

© = the extent field does not contain information
V = the extent field contains significant information

Reserved

It is the number of track which can be utilized by the user present on FD
2125 - It is the number of tracks which can be utilized by the user present
on HD with 18 M byte capacity

- Number of sectors present on FD if SURFACE IND. and TRK ID
fields contain, respectively, the values # and 1

- Number of sectors present on FD if SURFACE IND. and TRK ID
fields contain, respectively, the values # and &

- Number of sectors present on FD if SURFACE IND. and TRK ID
fields contain, respectively, the values 2 and 1

- Number of sectors present on FD if SURFACE IND. and TRK ID
fields contain, respectively, the values M and 1

- It is the number of sectors for track on HD with 18 M
byte capacity

999 - Free modality

Track © of FD is always composed of sectors with length of
128 bytes

i - Sectors of FD stary from 1
Not handled
Not handled
```

---

## Page 190

```
ela

lm

_—

-_

LABELS STRUCTURE OF THE FILES GENERABLE WITH BCOS Il UTILITIES

LAB ID

LAB NAM

RECLGT

BOE

DESCRIPTION

Label identifier

File name

Logic record length

Beginning of file on disk/data set

End of extent on disk/sata set

Recovery

HDRI

b
DRSFLE
bb...
00256

cccccc

cccccc

FILE CONTENTS

GE mura

HDRI HDRI HDRI
b b (o) b
cccccc
bb...

DIODD2+
@@256

cccccc

ccecccc
bu...

DIODD2+
D0256

cccccc

cccccc
bu...
00256

cccccc
bb...

DIODD2+
029128

cccccc

cccccc
bb...

DIDD2+
@O256

cccccc ceccce

cccccc cccccce cccccce cccccc cccccc

Reserved

For FD:
ccccce = TTTHSS

where:
TTT = initial track of the file

H = initial side of the file

SS = initial sector of the file
For HD:

ccecccc = TTTSSS

where:

TTT = initial track of the file
SSS = initial sector of the file

For FD:

cccccc = TTHSSS

where:

TTT = track containing the file last
sector (U.S.F.)

H = residence side of U.S.F.

SS = file last sector

For HD:

cecccec = TTTSSS

where: TTT =

track containing the file last sector

SSS = file last sector
```

---

## Page 191

```
022

FIELD

Initial

FILE CONTENTS

DESCRIPTION Se
Recovery |with basic
label (FD)

Identifier of file transcodable
in EBCDIC
File accessibility

Recordable file

Compatibily with other systems

File extension

Volume number bb
@1+99

File creation data eccccc

File expiration date

Verify file

Reserved

= transcodable file
B = non transcodable file

= accessible file
# b = not accessible file

= recordable file

P = file protected from recording

R=library notrecordable as a data file

E = compatible file

6 = file compatible with IBM system

= the file is monovolume

C = segment of a multivolume file
(not the last one)

L= last segment of a multivolume file

bl = the file is monovolume
@1+99 = volume number handled

bbbbtt = not handled

cccccc = creation data expressed in
year-month-day (YYMMDD)

Reserved

(66666 = not handled

cccccc = expiration data expressed in
year-month-day (YYMMDD)

V = the file is always verified

= not handled
```

---

## Page 192

```
Loo

Initial

Length

WRPROT

FLTYPE

DESCRIPTION

End of data

Label type

Recordability of file

File type

equential

Recovery |with basic

cccccc

label (FD)

cccccc

With
keys

cccccc

cccccc

cccccc

Library

rrrere

cccece = TTTHSS (for FD) and
TTTSSS (for HD), address of
the first free file sector
EOE+1= declares that the library is
empty
rrrrrr = first sector position of the last
module present in library
This address is expressed in
the format TTTHS for FD and
TTTSSS for FD and TTTSSS
for HD

Reserved

D/I extent label
@ = only basic label

Reserved

4 = recordable file
P = file protected from recording
R= library non recordable as a data file

Reserved

J= recovery file

P= sequential data file
W = work file

N = disordered keyed file
O = ordered keyed file

Q = disordered index file
R = ordered index file
S = system library

C = user library
```

---

## Page 193

```
2S

DESCRIPTION

RECLGT Record type F = the record have fixed length

V = the records have varying length

= not handled

1 = data recorded in ISO/ECMA

2 = some data are recorded in packed
format

@1 = number of page sectors

bi = not handied

cccccc = TTTHSS (for FD) and TTTSSS
for (HD) address of the first
free sector not containing
ordered data
rrrrrr = position of the first free sector
of library after the last sector
of directory.
This address is expressed in
the format TTTHSS for FD and
TTTSSS for HD
BOE+1 = declares that the library is
empty

DATAID Code of data identification

Dimension of the file page DI

cccccc cccccc

BOE+1
treeer

End of ordered data

@99@ = initializing factor.
It is never updated
@9BO = file is empty or does not
contain ordered data
D001+ 0256 = displacement from
the first byte of the
last sector of the file
containing ordered
data or in case of a
library file.

Position of the last full byte of the
last file sector containing ordered
data or pos. of the last directory

element
```

---

## Page 194

```
(Ad

FIELD

Initial
eee

Position of the last full byte of the
last file sector no matter it is
anordered file or not

Key code identifier

Key length

Displacement of the key bbb

= bb

Name of the associated index file | bbbbbb

NULL
NULL

bbb

1)
bbbbBE

NULL
NULL

900+ 255

bb

ccccce

NULL
NULL

bot

NULL
NULL

bbb

bb
bbbbbB

NULL
NULL

is it a displacement from
first byte of the last
directory sector

@OOO = initializing value. It is never
updated

SOOO = empty file

0999+0256 = displacement from
the first byte of the
last file sector, no
matter if it is an
ordered file or not

Reserved

4 = not handled
1 = keys recorded in ISO/ECMA code
2 = keys recorded in packed format

bb = not handled
@2+99 = key length

Hi = not handled

000+255 = displacement fo the key
from the beginning of
the record

Not handled

bbbbtt = not handied
cccccc = index file name

Reserved

Reserved
```

---

## Page 195

```
Ste

FILE LIBRARY:

GENERAL DESCRIPTOR

lm

START FIELD

POSITION

FIELD
LENGTH

FORMAT

—

CONTENTS OF A MODULE-DE

SYMBOLIC
NAME

NRSEG

LINK

MODNAME

OVLNAME

LANGUAGE

TYPEMOD

NRNLOCK

VERSION

SCRIPTOR

DESCRIPTION

NAME ASSIGNED TO THE MODULE
BY THE USER BEING CATALOGUED

MODULE NAME EXTENSION

VERSION

MODULE LANGUAGE

MODULE TYPE

NUMBER OF 64K SEGMENTS
OF THE MODULE

LINK TO THE FIRST BLOCK STARTING
FROM THE LIBRARY BOE

NUMBER OF 256 BYTES BLOCKS
MAKING UP THE TEXT OR THE LAST
LAST 64K TEXT SEGMENT

cccccc

NED
N c bb

Y/N: THE PROGRAM IS NOT / IS PARAMETRIC

P bbb: PARAMETER-DRIVEN PROGR.

*c bbb: COMPLETE PARAMETER MODULE

*c bbb: INCOMPLETE PARAMETER MODULE

*G bb: WITH ARG AREA

* LAST
D DELETED
B BACK

A Z8000 PROGRAM
L ASSEMBLER PROGRAM

B BASIC PROGRAM

O OCL PROGRAM

P PARAMETER-DRIVEN PROGRAM

O OBJECT
S SOURCE

6 MODULE 64K
N NUMBER OF 64K SEGMENTS
```

---

## Page 196

```
VIRTUAL DESCRIPTOR

92%

CEI FIELD
CEI

18
20

FIELD
LENGTH

FORMAT

B

GS 828.6 oO: 6

SYMBOLIC
NAME

LENGTH

HEADER
DATE
RELEASE

LOAD-ADD
ENTRYP

REGION

DESCRIPTION

MODULE LENGTH (IN BYTES)

HEADER LENGTH (IN BYTES)
CATALOGING DATE
RELEASE CODE
MODULE LOAD ADDRESS
ENTRY-POINT
PROGRAM ASSOCIATED REGION

PLAB PARAMETER LABEL

IF THE MODULE IS > 64K, IT IS THE NUMBER OF BYTES,

IF IT IS > 64K, THE LENGTH OF THE LAST SEGMENT

YYDDD

IT DEFINES THE USER MEMORY DIME
PROGRAM/PROCEDURE EXECUTION.

IT IS SIGNIFICANT FOR THE ENTIRE Ri
EXECUTION AND THUS FOR ALL PRO
A PROCEDURE

1s 256

NSION NECESSARY FOR THE

ROCEDURE/PROGRAM
GRAMS EXECUTED DURING
```

---

## Page 197

```
Pun

EDIT FILE AND DRSFLE

EDIT FILES FOR BASIC/OCL ENVIRONMENTS
DRSFLE DIMENSIONING

227
229

AND DRSFLE

EDIT FILE
```

---

## Page 198

```
L0e

we lu we |

EDIT FILE FOR BASIC/OCL ENVIRONMENTS

NAME NAME PROGRAMMING — aa

(mono systems) (multi systems) ENVIRONMENT TYPE RECORD LENGTH Ke. ee.

PEDIT1 + PEDIT4 Proportionally to the program being prepared
NO LINES (LIN. MED. + 3
FLEDIT FLEDI1 + FLEDI4 NO. SECT. = : sre
256
NO LINES (LIN. MED. + 5)
WORKFL WORKF1 + WORKF4 =
0.62 X 256

NOTE: NO. SECT. = number of sectors in the file
NO. LINES = number of lines in the program (max 65535)
LIN. MED. = average line length (max 80 characters)

TABLE WITH REFERENCE VALUES FOR FLEDIT AND WORKFL DIMENSIONING

NUMBER OF SECTORS

LIN. MED.
(byte)

NUMBER OF LINES

40

40

40

40
```

---

## Page 199

```
DRSFLE DIMENSIONING

DRSFLE WITHOUT ROLLOUT

DRSFLE WITH ROLLOUT WITHOUT MCP DRSFLE WITH ROLLOUT AND MCP

P P P P

D SR D is R D SUR Ss
Roc Eco Bee IE O R_C E 0 E 0
s H ||DUMPA||DUMPB||C_T s H ||DUMPA||DUMPB||;\c Tt  |DUMPC s H ||pumPA|[pumPB||c Tt ||/DUMPC||DUMPD|/DUMPE||c T
Foie hk Foe [eee c TE ese
LC || (flip) || (lop) Se LC || chip) || diop) || È (rollout) L € || lip) || qlopy ||Q È |\(rollout)]| (flip) || (flop) ||R È
CS Se STE Sie

D D D D

DRSFLE DIMENSION
(BASIC program)

2 (Dump BASIC + n + 1) 3 Dump (BASIC) IL 2n+2 5 Dump (BASIC) + 4n + 2

}
3 Dump (BAL) +/2n + 2

DRSFLE DIMENSION
(BAL program)

2 (Dump BAL + n + 1) 5 Dump (BAL) + 4n + 2

Notes: Dump (BASIC) = 75 + 203 + dimension (in bytes) of the variable program area (*) Between one MCP and the other, the ROLL program and the ROLL-suspended program,

) 256 perform the same maximum number of update/delete records.
‘

dimension (in bytes) of the program
256 | .

Dump (BAL) = 75 +

n = number of records in update/delete between MCPs

229
```

---

## Page 200

```
APPENDIX

A - M30/M40 BC ISO CHARACTER SET

B - ISO CHARACTER SET:

@ USA - ASC Il VERSION
@ NATIONAL VERSIONS

231

235
237

APPENDIX
```

---

## Page 201

```
DECIMAL HEXADECIMAL BINARY
VALUE VALUE CODE

00100000
00100001
00100010
00100011
00100100
00100101
00100110
00100111
00101000
00101001
00101010
00101011
00101100
00101101
00101110
00101111
00110000
00110001
00110010
00110011
00110100
00110101
00110110
00110111
00111000
00111001
00111010
00111011
00111100
00111101
00111110
00111111
01000000
01000001
01000010
01000011
01000100
01000101
01000110
01000111
01001000
01001001
01001010
01001011
01001100
01001101
01001110
01001111
01010000
01010001
01010010
01010011
01010100
01010101
01010110
01010111
01011000
01011001
01011010
01011011

OMONDAAWN]HO™~

=
>
2
§
A
B
Cc
D
E
F
G
H
I
J
K
È
M
N
(o)
P
Q
R
Ss
i
U
V
W
X
Y
Z

M30/40 BC ISO CHARACTER SET

231
```

---

## Page 202

```
ay a Pe co
|roffxot jrot|zo

40
z
A
x
M
A
n
}
s
1
b
d
°
u
w
I
»
[
Î
yu
6
è
5)
p
9
q
e
n

LLLOLOLI
OLLOLOLI
LOLOLOLL
OOLOLOLI
LLOOLOLL
OLOOLOLI
LOOOLOLL
OOO0OLOLL
LELLOOLL
OLLLOOLI
LOLLOOLL
OOLLOOLL
LLOLOOLI
OLOLOOLI
LOOLOOLL
000L00L1
LLLOOOLL
OLLOOOLI
LOLOOOL L
00LO00LL
LLOOOOL 1
OLOOOOLL
1000001 L
00000011
LLLELLLO
OLLELELO
LOLLLLLO
OOLLLLLO
LLOLLLLO
OLOLLLLO
LOOLLLLO
OOOLLLLO
LELOLELO
OLLOLELO
LOLOLLLO
OOLOLLLO
LLOOLLLO
OLOOLELO
LOOOLLLO
00001110
LEELOLLO
OLLLOLLO
LOLLOLLO
OOLLOLLO
LLOLOLLO
OLOLOLLO
LOOLOLLO
00010110
LLLOOLLO
OLLOOLLO
LOLOOLLO
00100140
LLOOOLLO
01000140
400001 +0
00000110
LLLLLOLO
OLLLLOLO
LOLLLOLO
OOLLLOLO

tà

EC

pupuia =

anivA
‘TWIWI930VX3H

{S|

‘Ausuazui UBIH = H

ANIVA
TWIID30
```

---

## Page 203

```
DECIMAL HEXADECIMAL
VALUE VALUE

= High Intensity; B = Blinking

233

BINARY
CODE

11011000
11011001
11011010
11011011
11011100
11011101
11011110
11011111
11100000
11100001
11100010
11100011
11100100
11100101
11100110
11100111
11101000
11101001
11101010
11101011
1111111
```

---

## Page 204

```
ISO CHARACTER SET

USA - ASC Il VERSION

sio [o
b,
Ib. |
Os
CACACAS
0/0 010 00 |
olofeli 01 |
oo) o| 02 |
ololrit! 03 DC;
loli 0/0 04 DC. |
Ol ol 05 TG: [Ga
19000 08) CAN
| 00/1| 09
ja sli 11
ii oo, 12
nlifoli 13
bj/1}1jo| 14
[FERA

235
```

---

## Page 205

```
LES

| ITALY

VERSION

FRANCE

di
x
$

USA - ASC Il

=

SPAIN

+

i

PORTUGAL

+t

SWITZERLAND

gl

SWEDEN
FINLAND

+ |e | a | |e | em |

Ù!

GERMANY

tt

Lia

U. K.

I

DENMARK
NORWAY

taz) quo

a4|elelflelele|e A

Ql7/Q/ajo {oz
```

---

## Page 206

```
Ajey ul pa}ulid

) (L) A O9EZL86E EPID dD
```
