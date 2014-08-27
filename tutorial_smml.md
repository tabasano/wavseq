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
;; sharp,flat and natural note. set before the note.
```
(+)a (-)b (0)c
```
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


