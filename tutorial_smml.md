# smml tutorial


## note
;; after setting up your environment of playing midi music,


;; listen to the sound of a note 'c', at first.

```
c
```

;; depending on a midi player, before and after sounds, it is better to set some rest time to listen.
;; 'r' means rest. small letters are note names. blanks can be used anywhere and will be ignored.

```
 r c d e d c3 r
```

;; capital letters are notes with sharps

```
e D e f F g g2
```

## octave level
;; change octave hight by '-', '+' or '(octave:3)' etc.

```
  c d e2
+ c d e2
- e d c2
```

;; >< tempo up/down a little bit.

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

## multiplet
;; but above is similiar to bellow

```
c /: dd / /: eeee /
```

;; because for example '/3: dd /' means that two 'd' notes are set inside '3' beats. 

```
/3:dd/    /3:ddd/    /3:dddddd/   /3:dddddddddddd/
```

these are all in 3 beats. when the total beat length word between ```/``` and ```:``` is omitted, it will be set to 1 beat.
each note length is set by each rate and total length.
each line of below is same meaning.

```
a0.5 c0.25 c0.25
/1: a2 c    c   /
/:  a2 c    c   /
/:  a4 c2   c2  /
```

in fact, ```/a4c2c2/``` is valid too, but it will be confusing later.


## gate time
;; real tone length is important sometimes. gate time command is a percentage of tone length. (staccato etc.)

```
 (g:100) a b c
 (g:70)  a b c
```

first line is played like with a slur. second one will be played by more shorter sounds.


;; set velocity. max is 127.

```
(v:70) c (v:40) c (v:20) c (v:70) c (v:90) c
```

;; set panpot. value is between 0 and 127. when using '><', right or left value (from 0 to 63). 

```
(pan:>30) c d e
```

if you don't, smml sets panpot values automatically.


## repeat phrase
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

;; the same note to the preceding one is '='.

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

currently valid names are 

```
c7
cm7
cmaj7
cmmaj7
cmaj or c
cm
c6
cm6
csus4
caug
c+
cdim
cdim7
cpower
```

followed by

```
(+5)
(-5)
(9) or (add9)
(+9)
(-9)
(+11)
(13)
(-13)
```


## tempo
;; most commands except note type ones, are inside parenthesis. set the tempo 120 bpm.

```
(tempo:120)
```

;; stroke. after it, multi notes are played shifted note by note.

```
(stroke:4)
```

repeating same command name in parenthesis, use blank.

```
(stroke:4) {a,b,c} = = (:6)  = = = 
```

is the same to

```
(stroke:4) {a,b,c} = = (stroke:6)  = = = 
```

```
(stroke:4) {a,b,c} = = (:-)  = = = 
```

minus value is for to stroke up. currently, up value affects once only as it simulates playing the guitar. 

## sharp, flat
;; note name etc. is case sencitive, so each of 12 notes in one octave can be expressed by one charactor. 
;; but in other cases,
;; sharp,flat and natural note command can be used. set before the note.

```
(+)a (-)b (0)c
```

strange ways of sharp/flat can be affective currently. ```(+4)a``` , ```(-1.2)a``` etc. in float value, bend data is used inside.


;; instead of 'd' etc., note numbers can be used if you want.
;; MIDI note value is from 0 to 127. it's over Piano's 88. but too high/low note may not be played and heard.

```
{64} 
{50,54,58}
```

;; use 12 series notation ; :0,:1,:2,:3 ... and :11 as notes c,C,d,D, ... and b.

```
 [ {47,56,:0,:1} === + ] 4
```

this multi-tone passage is repeated four times. ```:0``` is 'c' and ```:1``` is '(+)c', so these go to up-octave every passage effected by octave command '+' in the end of it,
 but other absolute number notes are not affected.


## instrument; program change
;; drum sound can be used anywhere, but this is not MIDI way, use instrument name.

```
_snare! = = =
```

;; set instrument. automaticaly searched by even not exact name. (MIDI program change command)
it depend on map files.


```
(p:piano) c d e f (p:guitar) f e d c
```

;; set drum channel. after it is set, note numbers also can be used as same as '_snare!' etc.

```
(ch:drum) {34} = = = {35} = = =
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


## track
;; in SMF, MIDI channel is 1 - 16, and drum is in 10 channel. but currently, these are automaticaly set.
;; you don't need to think about it. simply seperate tracks with a command '|||'.

```
(p:piano) c d e f ||| (p:organ) e f g a ||| (p:guitar) g a b c
```

;; for visibility, the same

```
    (p:piano)  c d e f 
||| (p:organ)  e f g a
||| (p:guitar) g a b c
```


currenly track names are not used as default, and tracks continue with apprearing order. so if there are no data in some tracks in mid parts of pages,
use blank tracks by track seperaters.

```
    c     ;; track 1
||| e     ;; track 2
||| g     ;; track 3
///////////////////////////////////////
    abc   ;; track 1
|||       ;; track 2 , no data but it can't be omitted to adjust track counters after this track.
||| def   ;; track 3
``` 


;; the same track name, the same MIDI channel and setting.

```
    (track:foo) (p:organ) aa
||| (track:foo) bb
||| (track:hoge) cc
```

first two tracks are 'organ' sound by the same track names declared.


## page
;; then seperate pages by three or longer one line '/'.
;; but this command do not adjust time potisions. it simply resets track number increment.

```
  cdef|||efga|||gabc
  ////////////////////
  c2d2e2f2|||e2f2g2a2|||g2a2b2c2
  ///////////////////
  c3def|||e3fga|||g3abc
```

;; the same to below.

```
cdef c2d2e2f2 c3def ||| efga e2f2g2a2 e3fga ||| gabc g2a2b2c2 g3abc
```

;; if you want to adjust tracks, use a blank page by two lines of page seperaters. the last three 'c' will be played adjusted instead each preceding note lengths are different.

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
    (mark:positionName)  c  ;; track 1
||| (mark:positionName)  c  ;; track 2
||| (mark:positionName)  c  ;; track 3
```

these are played like  this.

```
    cdrrr c  ;; track 1
||| errrr c  ;; track 2
||| abcde c  ;; track 3
```

;; marks are not needed for all tracks. positions will be adjusted automaticaly to the preceeding track while the same marks exist.
;; like this, most commands except tempo, a command effects its belonging track only.


```
  [ a b c (mark:m) ] 3
```

;; same mark names 'm' in repeated section or one track will be automaticaly substituded by 'm m@2 m@3'. to adjust, use it in other tracks.
or use a comma as a seperater of a name and a counter; '(mark:hoge@3)' = '(mark:hoge,3)'.

```
  a b c (mark:m) a b c (mark:m@2) a b c (mark:m@3)
```

## hex data
;; until smml syntax is completed, or other reasons, raw hex parts can be used for deep level data and things you don't know how to inprement by smml data.
search MIDI format and set valid hex data.

```
  &(00 00 00)
```

hex data must be ``` 00 01 02 ... FD FE FF ```. one byte is by two hex letters. seperaters are a blank or comma.
;; currently hex only can be used. oct/decimal may be able to use someday.
all in SMF track data, unique formated prefix delta tick time data is needed. so if want, you can use '$delta(240)' for 240 ticks.
the tick means a minimum time span in SMF , one beat equals to 480 ticks as default. in this case, delta time is set to half beat.
also '$se(F0 41 ..)' can be used for system exclusive message data.
currently, nest data of parenthesis is not implemented except very limited cases.
anyway, when you use hex data, be careful not to set invalid data. smml don't check its MIDI data validation.


## define and apply macro variable
;; for repeating phrase, macro can be used. use prefix '$' for refering.

```
    VeryLongPhraze:=cde
    macro W:=abc

    ggg $VeryLongPhraze fff $W
```

the  4th line will be replaced by

```
    ggg cde fff abc
```

the keyword 'macro' is used just for easy readability and will simply be ignored.
a macro definition is normally within and whole one line. you can write any valid smml data after '```:=```'.


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

'(wait:4)' was inserted by '4' in first place before args. it means 4 beats of rest (exact mean of '(wait:..)' is
'do nothing, set it free even if sound is on and wait for the next command' ).


multiline macro definition is ;

```
EFF:=(
   F0,43,10,4C,02,01,00,01,01,F7
   F0,43,10,4C,02,01,02,40,F7   
   F0,43,10,4C,02,01,0B,77,F7   
   F0,43,10,4C,02,01,14,70,F7   
)
```

after parenthesis, don't set any letters without blanks.
but now, this is for easy way of writing only, and may not be so useful. to use this multi line values, each line must be seperated.

```
$EFF[1] $EFF[2] $EFF[3] $EFF[4]
```

but, these are MIDI system exclusive HEX data, so to make it really effective data, use this,

```
(xg:on)
&( $delta(120) $se($EFF[1]) 00 $se($EFF[2]) 00 $se($EFF[3]) 00 $se($EFF[4]) )
```

```$se()``` translates hex SysEx data to SMF hex data, and it needs pre delta-time data by ```$delta(ticks)``` like other data.
```$delta(0)``` is ```00``` , so both of these are effective. inside ```$delta()``` value is not hex, use decimal number.

'${ff}' can be used for '$ff' as macro variable.

## comment
;; words after ';;' of each line are ignored. write comments there.
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
if a scale has been defined as below, random notes will be selected from its scale notes.

```
 (scale:a,b,c,d,e)
 (scale:a,+2,+3,+5,+7,+9,+11)
```

still incompleted to use.


another random note.

```
 [ (?:56-58) ] 4        ;; use range 56 to 58, note number. in this case, 4 times repeating maybe '{56}{56}{58}{57}' etc.
 (?:a,b,40,45,90,12)        ;; select from a note number or name list.
```

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

after these MIDI system commands, it need some time over 50 mili sec. or so for running.
implementation of it is not fixed, so for adjusting, please set marks on all tracks. for example '(mark:start)'.
or like this.

```
(gm:on)r
///////////////
///////////////
;; sound data start
    abc
||| def
```

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
 (bend:100) c
```

pitch bend 100 of note 'c'. 

```
 (bend:+100) c
 (bend:+-200) c
```

'+' relative value. if these are after above, three notes are bend 100 of 'c', bend 200 of 'c' and bend 0 of 'c'.
bend data is effective permanently until reseted by ```(bend:0)```.


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
  ^  ;; accent.  for changing a value of accent base, use '(accent:15)'.
  `  ;; too fast note, play ahead. for changing a value of shift ticks base, use '(roll:45)'.
  '  ;; too late note, lay back. 
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
      c         ;; single note
      C         ;; c sharp
      (-)d      ;; single note with flat/sharp/natural modifiers
      {64}      ;; single note by absolute note number
      _snare!   ;; drum note by instrument name search keyword 'snare'
      {d,g,-b}  ;; multi note
      {47,:0}   ;; multi note. second note is by 12 series half tone notation
      :cmaj7,   ;; chord name
      =         ;; copy of the latest note type command
```

  and other commands are with parentheses.

```'~'``` seems likely note type, but it is compressed to preceding note as calculated note length. most commands cannot be set inside of ```'c~~~'.```

;; theremin like sound,

```
(p:organ)
(theremin:on)
ab /:cde/ f
```

after on command, data is manipulated as bend data inside smml. not completed about modifiers for this.

;; easy way to write smooth expression and note transition
(experimental; experimental notations may be deleted or hidden to internal purpose only later.)


```
 (tne:0.3,c,127) 3
```

3 beat lengths of note 'c' with expression level 127 transition time rate 0.3 connected from the last note.

;; length for gate
(experimental)

```
(g:70)
f~~(lg:1.0)f~~f~~
```

rest of second 'f' is 30% of one beat instead others are 30% of three beats.

;; _repeat_ 

```
 [ a_repeat_ ] 3  ;; =>  a1 a2 a3
```

;; broken mode
as if uncontrolled

```
 (broken:on) (broken:off) 
```

## preprocess
;; some pre-process commands.
set it in the top of file.


```
;; midifilename  out.mid
;; title         this music name
```

## in pre modifier parts
limited commands can be used. bend,expre.

```
   (A:  o  o     o     o o   o o o (bend:20,-5000,-4700,-4700,-400,-200,0,0,10000,-10000) o, )
   (A:  o  o     o     o o   o o o (expre:20,40,+,+,+,+,-,-,-,-,+,+,+,+,-,-,-,-,+,+,+,+)   o, )
        a  b ~ ~ c ~ ~ d e ~ f g a b                                                       c d
```

note loudness is result of velocity, expression and volume values multipled. expression is used for a running note etc..
velocity for more long span, volume for total sound level etc.
in above case, the 9th note 'b' is with modifier data, expression and bend. the first value is time interval. 
all after that are real values. the '+' adds 10 to latest value as default.
 so expression data is ;``` 40,50,60,70,80,70,60,50,40,50,60,70,80...``` with each 20 ticks interval.
bend and expression values inside these parts will be reseted after the modified note ends.
series of ```(A:..)``` parts are merged. if not, old one is overwtitten.
'o' is dummy and it set nil value and simply ignored. it is for visibility purpose only.


## text
text implement to MIDI file.

```
 (text:this_is_a_pen)
```

but now blanks are removed. someday maybe fixed ?

