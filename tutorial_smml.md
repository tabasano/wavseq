## note
;; note 'c', at first.

```
c
```

;; depending on a midi player, before and after sounds, it is better to set some rest time to listen.
;; 'r' means rest. small letters are note names. blanks can be used anywhere and will be ignored.

```
c d e d c3 r
```
;; capital letters are notes with sharps

```
e D e f F g g2
```

## octave
;; change octave hight by '-', '+' or '(octave:3)' etc.

```
  c d e2
+ c d e2
- e d c2
```

;; >< tempo up down.

```
f r > f r > f r > f r <<< fr fr fr fr
```
## note length
;; use note length. set it after note charactors. no length means 1.
```
c d2 e3 f4
```
;; float numbers as length too.
```
c d0.5 d0.5 e0.25 e0.25 e0.25 e0.25
```
;; ( thus, length expression is far from standard MML. usualy it is similiar to musical note name. )

## gate time
;; real tone length is important sometimes. gate time command is a percentage of tone length. (staccato etc.)
```
 (g:100) a b c
 (g:70)  a b c
```
first line is played like with a slar. second one will be played by more shorter sounds.
## multiplet
;; but above is similiar to bellow
```
c /: dd / /: eeee /
```
;; because for example '/3: dd /' means that two 'd' notes are set inside '3' beats.
```
/3: dd / /3: ddd / /3: dddddd / /3: dddddddddddd /
```
;; set velocity. max is 127.
```
(v:70) c (v:40) c (v:20) c (v:70) c (v:90) c
```
;; set panpot. value is between 0 and 127. when using '><', right or left value (from 0 to 63). 
```
(pan:>30) c d e
```

## repeat phraze
;; repeat 3 times
```
[ c d e f ]3 
```
;; a melody goes near up/down side note without octave commands as default.
```
[ cdefgab ] 4
```
;; if you don't want do so, use octave command  '-'. '--' is same to '-2'
```
[ cdefgab - ] 4
[ cdefgab cdefgab -- ] 4
```
;; to make long tones easy to read, '~' is used. 'c3' is same to 'c~~'. it can be set whereever notes can be set.
```
c d e ~ e d c ~
c /:~de/ d ~ 
```
;; same note is '='.
```
c = = = d = = =
```

## chord
;; multi notes with length 2.
```
{c,e,g}2
```

;; chord name. used as same way as note commands. currently ',' is not be able to omitted as a part of chord name.
```
:cmaj7, = = = :G7, = = =
```
;; most commands except note type ones, are inside parenthesis. set the tempo 120 bpm.
```
(tempo:120)
```
;; stroke. after it, multi notes are played shifted note by note.
```
(stroke:4)
```

## sharp, flat
;; note name etc. is case sencitive, so each of 12 notes in one octave can be expressed by one charactor. 
;; but in other cases,
;; sharp,flat and natural note command can be used. set before the note.
```
(+)a (-)b (0)c
```
strange ways can be affective currently. '(+4)a' etc.
;; instead of 'd' etc., note numbers can be used if you want.
;; MIDI note value is from 0 to 127. it's over Piano's 88. but too high/low note may not be played and heard.
```
{64} 
{50,54,58}
```

## instrument; program change
;; drum sound can be used anywhere. but this is not MIDI way. use instrument name.
```
_snare! = = =
```
;; set instrument. automaticaly searched by even not exact name. (MIDI program change command)
```
(p:piano) c d e f (p:guitar) f e d c
```
;; set drum channel. after it is set, note numbers also can be used as same as '_snare!' etc.
```
(ch:drum) {34} = = = {35} = = =
```

## track
;; in SMF, MIDI channel is 1 - 16, and drum is in 10 channel. but currently, these are automaticaly set.
;; you don't need to think about it. simply seperate tracks with a command '|||'.
;; in the future, track names may be used.
```
(p:piano) c d e f ||| (p:organ) e f g a ||| (p:guitar) g a b c
```
;; for visibility, the same
```
    (p:piano)  c d e f 
||| (p:organ)  e f g a
||| (p:guitar) g a b c
```
## page
;; then seperate pages by three or longer one line '/'.
;; but this command do not adjust time potisions. it simply resets track number increment.
```
  cdef|||efga|||gabc
  ////////////////////
  cdef|||efga|||gabc
  ///////////////////
  cdef|||efga|||gabc
```
;; the same to below.
```
cdef cdef cdef ||| efga efga efga ||| gabc gabc gabc
```
;; if you want to adjust tracks, use a blank page by two lines of page seperaters. the last three 'c' will be played adjusted.
```
cd ||| e ||| abcde 
////////////////////
////////////////////
c|||c|||c
```
## position mark
;; or use a position mark command.
```
cd ||| e ||| abcde 
////////////////////
    (mark:positionName)  c
||| (mark:positionName)  c
||| (mark:positionName)  c
```
;; marks are not needed for all tracks. positions will be adjusted automaticaly to the preceeding track while the same marks exist.
;; like this, most commands except tempo, a command effects its belonging track only.


```
  [ a b c (mark:m) ] 3
```
;; same mark names 'm' in repeated section will be automaticaly substituded by 'm m@2 m@3'. to adjust, use it.
```
  a b c (mark:m) a b c (mark:m@2) a b c (mark:m@3)
```

## instrument map
;; a MIDI Program Change event sets the instrument on a channel.
if channel is 10, a note number means each drum instrument.
these are decreared in map files;
>  midi-programChange-list.txt


>  midi-percussion-map.txt


when there are same name files on the current directory, these are used. if not, default files in the gem will be set.
data in these map text must start with instrument number.
without it, the line text is used for section name. if the word 'Guitar' appears, it is included for searching keyword until the next section name line appears.
```

Piano Section
1 hoge piano
2 foo
3 bar

Guitar Section 
4 one
5 two

```
so in this list, instrument number 1,2 and 3 match the keyword 'piano'. 
So '(p:guitar,2)' selects an instrument line '5 two' as the 2nd result of searching 'guitar' and will be used instead of no word 'guitar' on it.

## hex data
;; until smml syntax is completed, raw hex parts can be used for complex data and things you don't know how to inprement in data.
search MIDI format and set hex data.
```
  &(00 00 00)
```
;; currently hex only can be used. oct/decimal may be able to use someday.
all in SMF track data, unique formated prefix delta tick time data is needed. so if want, you can use '$delta(240)' for 240 ticks.
the tick means a minimum time span in SMF , one beat equals to 480 ticks as default. in this case, delta time is set to half beat.
also '$se(F0 41 ..)' can be used for system exclusive message data.
currently, nest data of parenthesis is not implemented except very limited cases.

## macro define
;; for repeating phraze, macro can be used. use prefix '$' for refering.
```
    Macr:=cde
    macro W:=abc

    ggg $Macr fff $W
```
the  4th line will be subsituted by
```
    ggg cde fff abc.
```
the keyword 'macro' is used just for reading and will simply be ignored.


;; macro with args
```
    fn(x):=ab$x
```
;; in this case, '$fn(10)' is substituded by 'ab10'. similarly,
```
   $fn(:5,6,7)
   $fn(4:10,20,30)
```
will be
```
   ab5 ab6 ab7
   ab10 (wait:4) ab20 (wait:4) ab30
```
'(wait:4)' was inserted by '4' in first place before args. it means 4 beats of rest (exact mean of '(wait:..)' is 'do nothing and wait for the next command' ).


multiline macro definition
```
EFF:=(
   F0,43,10,4C,02,01,00,01,01,F7
   F0,43,10,4C,02,01,02,40,F7   
   F0,43,10,4C,02,01,0B,77,F7   
   F0,43,10,4C,02,01,14,70,F7   
)
```
but now, this is for easy way of writing only, and may not be so useful. to use it, each line must be seperated.
```
$EFF[1] $EFF[2] $EFF[3] $EFF[4]
```

## comment
;; ignored after ';;' of each line. write comments there.
multi line comments start with longer ';'.
end mark is same or longer mark of ';' than start mark. these must start from the top of the line.
```
;; comment
;;;;;;;;;;;;;;;;;;;;;;;;
  comm
      ent
          lines
;;;;;;;;;;;;;;;;;;;;;;;;;
 abc   ;; real sound

;;;;;;;;;;;;;;;;;;;;
;
;  data ended ...
;
   a b c d e f g
;;;;;;;;;;;;;;;;;;;;
```
in this case, active sound commands are 'abc' only.

## sound elements
use parts split note hight, length, velocity, gate time, pre modifier; sound elements. 
```
(L: ...)
(V: ...)
(G: ...)
(B: ...)
 a b c d e
```
the first value of each part will used for the first note 'a'. and so on.
inside parts, position is seperated by ',' or use dummy value 'o'.
'(V:,,,60,,)' is '(V:ooo 60 oo)'. last dummy values can be omitted. in this case, 4th note 'd' velocity is set to 60.
if 6th note don't exist, pre modifier element values are simply ignored.


in the same way,
```
(N: a b c d e )
(L: ...)
(V: ...)
(G: ...)
(B: ...)
 o o o o o
```
is same mean to above. 'o' is dummy note. note hights are substituted by '(N:..)' values.


## dummy note
'o' is dummy. '?' is for random note etc.
```
 ? /2: ???? /
```
will be
```
 c /2: defg /
```
or maybe
```
 e /2: cagb /
```
etc.

## transpose
```
(key:-4)
```
;; transpose -4 of half tone except drum instrument name like '_snare!'.
this does not have relation with the tonality. simply transpose all notes tempolary.
major key, minor key ,modulation of keys have not been implimented  yet.
## Control Change
```
 (cc:10,64)
```
controlChange number 10 value 64. see SMF format for details.

## General MIDI etc.
```
  (gm:on)
  (gs:reset)
  (xg:on)
```
after these commands, it need some time over 50 mili sec. or so for running.
implementation of it is not fixed, so for adjusting, please set marks on all tracks. for example '(mark:start)'.

## compile order
now compiling order is : page,track seperate => macro set and replace => repeat check => sound data make.
if there are bugs, error can appear by macro definitions appear in the last step 'sound data make' for example.

## D.S. al fine
musical repeats system marks :
```
  .DC .DS .toCODA .CODA .FINE
```
```
  .SKIP
```
;; skip on second time.
```
  .$
```
dal segno jump mark.

```
 [ a b c ]
```
if there is no followed number, 'abc' is repeated 2 times.

## seperater
;; ';' can be used for one line data as line seperater.
```
  $ smml -d "abc;def|||mc:=ggg;ccc$mc ddd" -o out.mid
```
in this case, macro definition ends by ';', so $mc means 'ggg'.
## and so on
for more details if you want to understand, see MIDI format.
basicaly, a MIDI envent is constructed by preceding time data and event data.
so series of event preceding each zero time data mean many event on the same time.
but it may not be played as you expect. to fix it, set some delta time for MIDI players.
```
 (on:a)
```
note 'a' sound on only. it takes zero tick.
```
 (off:a)
```
note 'a' sound off only.
```
 (wait:3)
```
it reserves 3 beats for the next note event. 
so,
 the note event 'a' is the same as '(on:a)(wait:1)(off:a)'.
'(on:a)(on:b)(on:c)(wait:2)(off:a)(off:b)(off:c)' is '{a,b,c}2'



```
 (ch:1)
```
;; set this track's channel 1. when several tracks use same channel, for example it will behave as the same instrument.
```
 (bend:100)
```
pitch bend 100
```
 (bendRange:12)
```
set bend range 12. default is normaly 2.
```
 (bendCent:on)
```
set bend value unit cent (half tone eqauls 100 cents). defaultly this is 'off' and value is between -8192 and +8192.
so, these are same
```
 (bendCent:off)(bend:8192)
 (bendCent:on)(bend:100)
```
```
 (V:o,o,110)
```
preceding modifier velocities. if next notes are 'abc' ,3rd tone 'c' is with velocity 110. a blank or 'o' mean default value.
```
 (G:,,-)
```
preceding modifier gate rates. if next notes are 'abc' ,3rd tone 'c' is with a gate rate shorter.
new preceding modifiers will cancel old rest preceding values if it remains.

```
  ^  ;; accent
  `  ;; too fast note, play ahead
  '  ;; too late note, lay back
```
set these modifiers before note commands.
```
 (loadf:filename.mid,2)
```
load the second track data of filename.mid. when using it, the track must be itself only. seperate by '|||'.
this command do not check about track data strictly. be careful.


;; basicaly, one sound is a note type command with preceding modifiers followed by length number. 
```
  ^`a2
```

now, note type commands are :
```
      'c'        ;; single note
      '(-)d'     ;; single note with flat/sharp/natural modifiers
      '{64}'     ;; single note by absolute note number
      '_snare!'  ;; drum note by instrument name
      '{d,g,-b}' ;; multi note
      ':cmaj7,'  ;; chord name
      '='        ;; copy of the latest note type command
```

  and other commands are with parentheses.

'~' seems likely note type, but it is zipped to preceding note as calculated note length. most commands cannot be set between these.