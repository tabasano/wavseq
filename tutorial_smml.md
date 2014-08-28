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
;; a melody goes near up/down side note without octave commands.
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
## instrument
```
;; drum sound can be used anywhere. but this is not MIDI way. use instrument name.
```
_snare! = = =
```
;; set instrument. automaticaly searched by not exact name.
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
;; if you want to adjust tracks, use a blank page. the last three 'c' will be played adjusted.
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
Piano
1 hoge piano
2 foo
3 bar
Guitar
4 one
5 two
```
in this list, 1,2 and 3 match the keyword 'piano'. So '(p:guitar,2)' selects an instrument line '5 two' as the 2nd reslt of searching 'guitar' and will used instead of no word 'piano' on it.

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

## comment
;; ignored after ';;' of each line. write comments there.
multi line comments start with longer ';'.
end mark is same or longer mark of ';'. these must start from the top of line.
```
;; comment
;;;;;;
  comm
      ent
          lines
;;;;;;
```

## elements
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
if 6th note don't exist, simply ignored.


in the same way,
```
(N: a b c d e )
(L: ...)
(V: ...)
(G: ...)
(B: ...)
 o o o o o
```
is same mean to above. 'o' is dummy note.

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

## compile order
now compiling order is : page,track seperate => macro set and replace => repeat check => sound data make.
if there are bugs, error can appear by macro definitions appear in the last step 'sound data make' for example.


----------------------------------------------------------------------

below,
under construction



>
    A*120 =120 ticks of note 'a #'
    (key:-4) =transpose -4 except percussionSoundName like '_snare!'


    (ch:1)      =set this track's channel 1
    (cc:10,64) =controlChange number10 value 64. see SMF format.

    (bend:100)     =pitch bend 100
    (bendRange:12) =set bend range 12. default is normaly 2.
    (bendCent:on)  =set bend value unit cent (half tone = 100). default is 'off' and value is between -8192 and +8192.
                    '(bendCent:off)(bend:8192)' = '(bendCent:on)(bend:100)'
    (on:a)     =note 'a' sound on only. take no ticks.; the event 'a' is the same as '(on:a)(wait:1)(off:a)'.
    (off:a)    =note 'a' sound off 
    (g:10)     =set sound gate-rate 10% (staccato etc.)

    (V:o,o,110)  =preceding modifier velocities. if next notes are 'abc' ,third tone 'c' is with velocity 110. a blank or 'o' mean default value.
    (G:,,-)    =preceding modifier gate rates. if next notes are 'abc' ,third tone 'c' is with gate rate shorter.
               new preceding modifiers cancel old rest preceding values.
    ^          =accent
    `          =too fast note, play ahead
    '          =too late note, lay back

    (gm:on)
    (gs:reset)
    (xg:on)

    .DC .DS .toCODA .CODA .FINE =coda mark etc.
    .SKIP =skip mark on over second time
    .$ =DS point
    (loadf:filename.mid,2) =load filename.mid, track 2. Track must be this only and seperated by '|||'.
    ; =seperater. same to a new line


    basicaly, one sound is a tone command followed by length number. now, tone type commands are :
      'c'        => single note
      '(-)d'     => single note with flat/sharp modifier
      '{64}'     => single note by absolute note number
      '_snare!'  => drum note by instrument name
      '{d,g,-b}' => multi note
      ':cmaj7,'  => chord name
    and other commands are with parentheses.
