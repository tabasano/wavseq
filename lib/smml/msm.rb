#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'

$debuglevel=0

# as gem or this file only
def version
  if defined?(Smml) && ( Smml.constants.member?("VERSION") || Smml.constants.member?(:VERSION) )
    Smml::VERSION 
  else
    File.mtime(__FILE__).strftime("%Y-%m-%d")
  end
end
def hintminimum
  cmd="smml"
  puts "Smml v#{version}"
  puts <<EOF
usage:
   data to mid
       #{cmd} -d \"cdef gabc cbag rfed c4\" -o outfile.mid
   file to mid
       #{cmd} -i infile.txt  -o outfile.mid
   show syntax
       #{cmd} -s
   for farther details, see tutorial_smml.md in gem
EOF
end
def showsyntax
  puts <<EOF

syntax: ...( will be changed time after time)
    abcdefg =tone; capital letters are sharps. followed by number as length. 
    +- =octave change
    r  =rest
    >< =tempo up-down(percent)
    a4    =4 beats of note 'a'. in length words, integers or flout numbers can be used.
    a     =one beat of note 'a'. default length equals 1 now.
    A*120 =120 ticks of note 'a #'
    (v:60)  =velocity set to 60 (0-127)
    &(00 00) =set hex data directly. This can include ...
             '$delta(240)' for deltaTime data making
             '$se(F0 41 ..)' system exclusive to system exclusive message
    (p:11) =ProgramChange channel here, instrument 11
    (p:organ) =ProgramChange channel here, instrument ?(search word like 'organ' from list if exist)
        map text must start with instrument number
        channel number can be used, but not recommended. '(p:0,11)'
    (key:-4) =transpose -4 except percussionSoundName like '_snare!'
    [...] =repeat 2 times for first time
    [...]3 =3 times of inside block []
    /2:abcd/    =(triplet etc.) notes 'abcd' in 2 beats measure
    /:abc/      =triplet 'a''b''c' in one beat.
    /*120:abcd/ = notes 'abcd' in 120 ticks measure. now, default measure is 480 ticks per one beat.
    /:cd/ ~2e /:~fga/    =(tie) each length : c 0.5 d 0.5+2 e 1+0.25 f 0.25 g 0.25 a 0.25
                        after '~' length needed. if not length 1 is automaticaly inserted.
                        'c~~~' = 'c4'
    =           = same note and length as the previous note. 'c2c2c2c2' = 'c2==='
    (tempo:120) =tempo set
    (ch:1)      =set this track's channel 1
    (cc:10,64) =controlChange number10 value 64. see SMF format.
    (pan:>64)  =panpot right 64. ( pan:>0  set center )
    (oct:2)      =set octave 2
    (bend:100)     =pitch bend 100
    (bendRange:12) =set bend range 12. default is normaly 2.
    (bendCent:on)  =set bend value unit cent (half tone = 100). default is 'off' and value is between -8192 and +8192.
                    '(bendCent:off)(bend:8192)' = '(bendCent:on)(bend:100)'
    (on:a)     =note 'a' sound on only. take no ticks.; the event 'a' is the same as '(on:a)(wait:1)(off:a)'.
    (wait:1)   =set waiting time 1 for next event
    (off:a)    =note 'a' sound off 
    (g:10)     =set sound gate-rate 10% (staccato etc.)
    {64}     =tone '64' by absolute tone number. ='(x:64)'
    {c,e,g}    =multi tone. use similar way to tone 'a' etc. = '(on:c)(on:e)(on:g)(wait:1)(off:c)(off:e)(off:g)'
    :cmaj7,       =use chord name. the first letter is tone name 'c'. so using capital one is with sharp.
    (stroke:4)   =chord stroke interval ticks '4'. if '-4' down-up reversed.
    (V:o,o,110)  =preceding modifier velocities. if next notes are 'abc' ,third tone 'c' is with velocity 110. a blank or 'o' mean default value.
    (G:,,-)    =preceding modifier gate rates. if next notes are 'abc' ,third tone 'c' is with gate rate shorter.
               new preceding modifiers cancel old rest preceding values.
    ^          =accent
    `          =too fast note, play ahead
    '          =too late note, lay back
    (-)c        =c flat
    (+)c        =c sharp; equals 'C'
    (+2)c,(++)c =c double sharp
    (0)c        =c natural
    (gm:on)
    (gs:reset)
    (xg:on)
    (syswait:) =when using '(gm:on)' etc., this command is needed for all other tracks to adjust wait-time.
    ||| = track separater
    /// = page separater
          series of page separaters insert unique '(mark:all track mark)' to allready running tracks automaticaly.
    (mark:posname) =position name for adjustment of tracks after long rest etc.
    .DC .DS .toCODA .CODA .FINE =coda mark etc.
    .SKIP =skip mark on over second time
    .$ =DS point
    _snare! =percussion sound ( search word like 'snare' (can use tone number) from percussion list if exist )
        similarly, _s!=snare, k:bassKick, o:openHighHat, c:closedHighHat, cc:CrachCymbal, h:highTom, l:lowTom as default.
        map text personaly you set must start with tone number.
    (loadf:filename.mid,2) =load filename.mid, track 2. Track must be this only and separated by '|||'.
    W:=abc        =macro definition. One Charactor macro can be used. use prefix '$' for refering.
    macro W:=abc  =macro definition.
    fn(x):=ab$x    =macro with args. in this case, '$fn(10)' is substituded by 'ab10'. similarly,
                  '$fn(:10,20,30)' = 'ab10ab20ab30'.
                  '$fn(4:10,20,30)' = 'ab10(wait:4)ab20(wait:4)ab30'.
    compile order is : page,track separate => macro set and replace => repeat check => sound data make
    ; =separater. same to a new line
    blank =ignored
    ;; comment =ignored after ';;' of each line
    ;;;;;;     =start mark of multi-line comment. end mark is same or longer mark of ';;'. these must start from the top of line.

    basicaly, one sound is a tone command followed by length number. now, tone type commands are :
      'c'        => single note
      '(-)d'     => single note with flat/sharp modifier
      '{64}'     => single note by absolute note number
      '_snare!'  => drum note by instrument name
      '{d,g,-b}' => multi note
      ':cmaj7,'  => chord name
    and other commands are with parentheses.

    for more details, see tutorial_smml.md
EOF
end
def hint
  hintminimum
  showsyntax
end

1.round(2) rescue (
class Float
  def round n=0
    c=10**(n+1)
    f=(((self*c).to_i+5)/10).to_f/(10**n)
    n>0 ? f : f.to_i
  end
end
class Fixnum
  def round n=0
    return self if n==0
    c=10**(n+1)
    (((self*c).to_i+5)/10).to_f/(10**n)
  end
end
)
[].rotate rescue (
class Array
  def rotate
    self.size>0 ? self[1..-1]+self[0..0] : []
  end
end
)
# MyLength.new(1,"2j")
# num and fixed mark word, for swing rythm
class MyLength < Numeric
  def initialize *a
    p [:in,a,a.size] if $DEBUG && $debuglevel>4
    a=a[0] if a.size==1
    r=[]
    case a
    when String
      a=~/\?\?([^\?]*)\?\?/
      a=$1 if $1
      r=a.split("+")
    when Array
      r=a
    when MyLength
      r=a.s,a.j
    else
      r=[a]
    end
    @s=Float(r[0])
    @j=([r[1]]-[nil]).flatten||[]
    p [:i,@s,@j,r,a]  if $DEBUG && $debuglevel>4
  end
  def s
    @s
  end
  def j
    @j
  end
  def + (other)
    p "#{@s} #{other} +!" if $DEBUG
    o=MyLength.new(other)
    s=@s+o.s
    j=@j
    j=o.j if j.size<1
    MyLength.new(s,j)
  end
  def - (other)
    p "#{@s} #{other} -!" if $DEBUG
    o=MyLength.new(other)
    s=@s-o.s
    j=@j
    MyLength.new(s,j)
  end
  def * (other)
    p "#{@s} #{other} *!" if $DEBUG
    o=MyLength.new(other)
    s=@s*o.s
    j=@j
    j=o.j if j.size<1
    MyLength.new(s,j)
  end
  def / (other)
    p "#{@s} #{other} /!" if $DEBUG
    o=MyLength.new(other)
    s=@s/o.s
    j=@j
    MyLength.new(s,j)
  end
  def coerce(other)
    p [:c] if $DEBUG
    if other.kind_of?(Float)
      return MyLength.new(other), self
    elsif other.kind_of?(Fixnum)
      return MyLength.new(other), self
    elsif other.kind_of?(String)
      return self,MyLength.new(other)
    else
      super
    end
  end
  def round
    MyLength.new(@s.round,@j)
  end
  def inspect
    "#{@s}(#{@j})!?"
  end
  def to_s int=true
    j=@j.inject(""){|s,i|s+(i||"")}
    (int ? @s.to_i.to_s : @s.to_s)+ (j.size>0 ? "_#{j}" : "")
  end
  def to_f
    self.to_s(false)
  end
  def to_l
    @s
  end
  def to_i
    @s.to_i
  end
end
class Numeric
  def to_myl
    MyLength.new(self)
  end
end

def multilineTrim l,com
  r=[]
  on=false
  mark=""
  l.each{|i|
    if on
      on=false if i=~/^#{mark}/
    else
      i=~/^(#{com}#{com}+)/
      if $&
        mark=$1
        on=true
      else
        r<<i
      end
    end
  }
  puts " ? mismatch end mark of multiline comment."  if on
  r
end

#===========================================================
module MmlReg
  def self.r key, sort=true, pre=""
    raise if sort.class==Symbol
    case key
    when Array
      raise if (key-@@keys).size>0
      ks=key
      ks=(@@keys-(@@keys-ks)) if sort
      ks.map{|i|"#{pre}#{@@h[i]}"}*"|"
    else
      @@h[key]
    end
  rescue
    puts "Regex part,arg bug",[key-@@keys]
    raise
  end
  def self.rr key, sort=true, pre=""
    /#{self.r(key,sort,pre)}/
  end
  def self.rPlusPre key, pre, sort=true
    self.r(key,sort,pre)
  end
  def self.trackr
    self.r([:hexraw,:sharp,:chord,:chword,:word,:sound,:tieNote,:register,:modifier,:velocity,:tempo,:num,:octave,:note2,:note,:mod,:note?,:sound?])
  end
  def self.multipletr
    self.r([:note2,:chword,:word,:note,:sound,:tieNote,:register,:chord,:numswing,:num,:sharp,:octave,:mod])
  end
  def self.macroDefr
    self::MacroDef
  end
  def self.repeatr
    self.r([:repStart,:repEnd,:repmark])
  end
  @@h={} # mml regex key hash. order is in @@keys
  @@keys=[
    :comment,
    :keyword,
    :macrodefAStart,
    :macrodefA,
    :macrodefStart,
    :macrodef,
    :hexraw,
    :hexrawStart,
    :tSep,
    :pSep,
    :multipletStart,
    :multipletmark,
    :macroA,
    :macro,
    :repStart,
    :repEnd,
    :note2,
    :chword,
    :word,
    :modifier,
    :sharp,
    :wordStart,
    :word?,
    :chord,
    :velocity,
    :sound,
    :tieNote,
    :register,
    :tempo,
    :mod,
    :octave,
    :numswing,
    :num,
    :blank,
    :valueSep,
    :parenStart,
    :parenEnd,
    :chordStart,
    :chordEnd,
    :cmdValSep,
    :note,
    :dummyNote,
    :randNote,
    :note?,
    :sound?,
    :plusMinus,
    :lineSep,
    :repmark,
    :DCmark?,
    :chord?,
  ]
  @@h[:repmark]="\\.FINE|\\.DS|\\.DC|\\.\\$|\\.toCODA|\\.CODA|\\.SKIP"
  @@h[:comment]="\\( *comment[^\(\)]*\\)"
  @@h[:note2]="\\( *tne *:[^\(\)]*\\)|\\( *[[:alpha:]\\-\\+]+,[^,]*\\)"
  # parenthesis arg, chord inside etc.
  @@h[:chword]="\\([^\(\):,]*:[^\(\),]+\\([^\(\)]+\\)\\)"
  @@h[:word]="\\([^\(\):,]*:[^\(\)]*\\)"
  @@h[:wordStart]="\\([^\(\):]*:"
  @@h[:sharp]="\\([+-]*[[:digit:]\\.]*\\)"
  @@h[:word?]="\\([^\(\)]*\\)"
  @@h[:chord]="\\{[^\{\}]+,[^\{\},]+\\}|:[[:alpha:]][[:alnum:]]*\\([-+,:[:digit:]]+\\),|:[[:alpha:]][[:alnum:]]*,"
  @@h[:velocity]="v[[:digit:]]+"
  @@h[:note]="[abcdefgACDFGr]|\\{[[:digit:]]+\\}"
  @@h[:note?]="[BE]"
  @@h[:dummyNote]="o|m|O|M"
  @@h[:randNote]="\\?"
  @@h[:sound]="_[^!]+!|="
  @@h[:tieNote]="~|w"
  @@h[:register]="\\\"[[:digit:]]+"
  @@h[:sound?]="[[:alpha:]]"
  @@h[:DCmark?]="\\.[[:alpha:]]+"
  @@h[:tempo]="[><][[:digit:]]*"
  @@h[:mod]="[`'^]"
  @@h[:octave]=   "[+-][[:digit:]]*"
  @@h[:plusMinus]="[+-][[:digit:]]*"
  @@h[:tSep]="\\|\\|\\|"
  @@h[:pSep]="\\/\\/\\/+"
  @@h[:repStart]="\\["
  @@h[:repEnd]="\\]"
  @@h[:multipletStart]="\\/\\*?[[:digit:]\\.]*:"
  @@h[:multipletmark]="\\/"
  @@h[:numswing]="[[:digit:]],"
  @@h[:num]="[-+*]?[[:digit:]]+_[[:digit:]]+j,|[-+*]?[[:digit:]]+\\.[[:digit:]]+|[-+*]?[[:digit:]]+"
  @@h[:hexraw]="&\\([^()]*\\)"
  @@h[:hexrawStart]="&\\("
  @@h[:keyword]="macro +"
  @@h[:macroA]="\\$\\{[^}]+\\}\\[[^\\]]+\\]|\\$[^}\\$\\{\\(\\)]+\\[[^\\]]+\\]"
  @@h[:macro]="\\$[[:alnum:]]+\\([^)]*\\)|\\$[[:alnum:]]+|\\$\\{[^}]+\\}"
  @@h[:macrodefAStart]="[[:alnum:]]+\\([,[:alpha:]]+\\):= *\\( *[;]"
  @@h[:macrodefA]=     "[[:alnum:]]+\\([,[:alpha:]]+\\):= *[^\\(;\\n][^;\\n]*"
  @@h[:macrodefStart]="[[:alnum:]]+:= *\\( *[;]"
  @@h[:macrodef]=     "[[:alnum:]]+:= *[^\\(;\\n][^;\\n]+"
  @@h[:blank]="[[:blank:]]+"
  @@h[:valueSep]=","
  @@h[:parenStart]="\\("
  @@h[:parenEnd]="\\)"
  @@h[:chordStart]="\\{"
  @@h[:chordEnd]="\\}"
  @@h[:cmdValSep]=":"
  @@h[:lineSep]=";"
  @@h[:chord?]=":[^=,]+,"
  @@h[:modifier]="_[^_]__[^\\?]+\\?"
  r=self.r(@@keys)
  RwAll=/#{r}|./
  MacroDef=self.rPlusPre([:macrodefAStart,:macrodefStart,:macrodefA,:macrodef],"macro *")+"|"+
           self.r([:macrodefAStart,:macrodefStart,:macrodefA,:macrodef])
  RepStrArray=["[","]",".CODA",".DS",".DC",".FINE",".toCODA",".$",".SKIP"]
  ArgIsOne=%w[ bendCent mark p gm gs xg loadf text ]
  ArgIsName=%w[ p dumpVar ]
  def self.event m,rest=[]
    ((@@keys-rest).map{|k|m=~/\A#{@@h[k]}\z/ ? k : nil}-[nil])[0]
  end
  def self.item m,rest=[]
    [self.event(m,rest),m]
  end
  def self.hexitem m
    m=~/([[:digit:]]{2})|(\$[^ ]+)|([, ])/
    if $1
      [:hex,m]
    elsif $2
      [:macro,m]
    elsif $3
      [:hexSep,m]
    else
      [hex?,m]
    end
  end
  def self.keyAll
    @@keys
  end
  def self.regmakeExcept ex
    r=self.r(@@keys-ex)
    /#{r}|./
  end
  def self.blanks
    [:comment,:blank,:lineSep,:keyword]
  end
end

#===============================================

def allTrackMark c
  "(mark:.ALL_TRACK_MARK_#{c}.)"
end
class String
  def setcmark c
    @@cmark=c
  end
  def setpagesep c
    @@pagesep=c
  end
  def settracksep c
    @@tracksep=c
  end
  def cmark
    @@cmark
  end
  def pagesep
    @@pagesep
  end
  def commentoff ofs="",com=@@cmark
    lines=self.split("\n")
    d=multilineTrim(lines,com)
    d=d.map{|i|i.sub(/(#{com}).*/){}.chomp}*ofs
    d
  end
  def sharp2cmark
    self.gsub!("#"){@@cmark}
  end
  def tracksep pspl=@@pagesep
    tracks={}
    pages=self.split(/#{pspl}+/)
    markc=0
    pages.each{|p|
      if p=~/^[ ;]+$/
        p=allTrackMark(markc)
        tracks.values.each{|v| v << p }
        markc+=1
      else
        p.split(@@tracksep).each_with_index{|t,i|
          if tracks[i]
            tracks[i] << t
          else
            tracks[i] = [t]
          end
        }
      end
    }
    tracks.keys.sort.map{|k|tracks[k]*";"}
  end
end


class Array
  def rotatePlus
    self[1..-1]+[self.first+12]
  end
  def rotateMinus
    [self.last-12]+self[0..-2]
  end
  def orotate n=1
    r=self
    if n>0
      n.times{r=r.rotatePlus}
    else
      (-n).times{r=r.rotateMinus}
    end
    r
  end
  def lastIsPreAfter
    self[-1][0..1]==[:call,:preAfter]
  end
end
def mergeValues a,b
  r=[]
  size = a.size>b.size ? a.size : b.size
  size.times{|i|
    tmp=[a[i],b[i]]-["o"]
    tmp=["o"] if tmp==[]
    r<<tmp*""
  }
  r
end
class Chord
  def self.notes type,subtype
    ten=[0]
    case type
    when "power"
      ten+=[7]
    when "7"
      ten+=[4,7,10]
    when "m7"
      ten+=[3,7,10]
    when "maj7"
      ten+=[4,7,11]
    when "mmaj7"
      ten+=[3,7,11]
    when "maj" # no need
      ten+=[4,7]
    when "m"
      ten+=[3,7]
    when "6"
      ten+=[4,7,9]
    when "m6"
      ten+=[3,7,9]
    when "sus4"
      ten+=[5,7]
    when "aug", "+"
      ten+=[4,8]
    when "dim"
      ten+=[3,6]
    when "dim7"
      ten+=[3,6,9]
    when ""
      ten+=[4,7]
    else
      STDERR.puts "unknown chord type? #{type}"
    end
    if subtype
      tention=subtype.split(',')
      tention.each{|i|
        case i
        when "+5"
          ten=ten-[7]+[8]
        when "-5"
          ten=ten-[7]+[6]
        when "9"||"add9"
          ten=ten+[14]
        when "+9"
          ten=ten+[15]
        when "-9"
          ten=ten+[13]
        when "+11"
          ten=ten+[6]
        when "13"
          ten=ten+[9]
        when "-13"
          ten=ten+[8]
        when /^:/
          t=$'.to_i
          ten=ten+[t]
        else
          STDERR.puts "unknown chord sub type? #{subtype}"
        end
      }
    end
    ten=ten.sort
    ten
  end
  def self.type c
    c=~/([^(]*)(\((.*)\))?/
    self.notes($1,$3)
  end
end
class Notes < Hash
  @@rythmChannel=9
  @@notes={
    "c"=>0,
    "C"=>1,
    "d"=>2,
    "D"=>3,
    "e"=>4,
    "f"=>5,
    "F"=>6,
    "g"=>7,
    "G"=>8,
    "a"=>9,
    "A"=>10,
    "b"=>11,
    "t"=>[0,@@rythmChannel],
    "s"=>[3,@@rythmChannel],
    "u"=>[6,@@rythmChannel]
  }
  @@invert=@@notes.invert
  12.times{|i|@@notes[":#{i}"]=i}
  12.times{|i|@@notes[":-#{i+1}"]=-i-1}
  @@octave=12
  def initialize
    @@notes.each{|k,v|self[k]=v}
  end
  def self.n2note num
    @@invert[num%@@octave]
  end
  def self.n2octave num
    num/@@octave-1
  end
  def self.nDisplay n
    "#{n}[#{self.n2octave(n)}#{self.n2note(n)}]"
  end
  def self.get last,dist=0
    last=~/(\-*)(\+*)([[:alpha:]])/
    oct=$1.size*(-1)+$2.size
    last=$3
    lastnote=@@notes[last]+oct*@@octave
    num=lastnote+dist.to_i
    octave= num / @@octave
    pre=if octave>0
          "+"*octave
        elsif octave<0
          "-"*(octave*-1)
        else
          ""
        end
    pre+@@invert[num%@@octave]
  end
end
class Tonality
  def initialize key="c"
    @sharp=[:f,:c,:g,:d,:a,:e,:b]
    @flat=@sharp.reverse
    @cycle=[:c,:f,:A,:D,:G,:C,:F,:b,:e,:a,:d,:g,:c]
    @cf={}
    @cs={}
    @bymarkcount={}
    @sfnow={}
    7.times{|n|
      i=@cycle[n]
      @cycle.index(i).times{|s|
        @cf[i]=[] if ! @cf[i]
        @cf[i]<<@flat[s]
      }
    }
    7.times{|n|
      i=@cycle.reverse[n]
      @cycle.reverse.index(i).times{|s|
        @cs[i]=[] if ! @cs[i]
        @cs[i]<<@sharp[s]
      }
    }
    7.times{|i|@bymarkcount[i]=@cycle.reverse[i]}
    7.times{|i|@bymarkcount[-i]=@cycle[i]}
    self.set(key)
  end
  def sharp t
    @cs[t.to_sym]
  end
  def flat t
    @cf[t.to_sym]
  end
  def tonalitycheck t,sfnote=false
    t=@bymarkcount[t.to_i] if t=~/^[-+[:digit:]]/
    if t=~/m$/
      # use relative major tonality data
      t=$`.to_sym
      t=@cycle[(@cycle.index(t)+3)%12]
    end
    t=t.to_sym
    cf=sfnote ? (@cf[t]||[]) : (@cf[t]||[]).size
    cs=sfnote ? (@cs[t]||[]) : (@cs[t]||[]).size
    case @cycle.index(t)
    when 0...7
      [:flat,cf]
    else
      [:sharp,cs]
    end
  end
  def set t
    @key=t
    @sfnow={}
    r=tonalitycheck(t,true)
    r[1].each{|i|@sfnow[i]=r[0]}
  end
  def getSharp n
    n=n.to_sym
    case @sfnow[n]
    when :sharp then  1
    when :flat  then -1
    else              0
    end
  end
  def dump
    [:now_cf_cs,[@sfnow,@cf,@cs].map{|i|i.map{|k,v|"#{k} #{v.class==Array ? v.sort : v}"}}]
  end
end
class ScaleNotes < Array
  def setSampleRate c
    @samplerate=c
  end
  def modeinit
    return if defined?(@@mode)
    s=[:ionian,:dorian,:phrygian,:lydian,:mixolydian,:aeorian,:locrian,:ionian]
    @@mode={}
    @@mode[:ionian]=[0,2,4,5,7,9,11]
    6.times{|i|
      tmp=@@mode[s[i]].rotate
      root=tmp[0]
      tmp=tmp.map{|t|(t-root+12)%12}
      @@mode[s[i+1]]=tmp
    }
  end
  def move s
    initialize(self.map{|i|Notes.get(i,s)})
  end
  def keys
    @@mode.keys
  end
  def setmode first,mode=:ionian
    self<<first
    @@mode[mode][1..-1].each{|i|self<<Notes.get(first,"+#{i}")}
  end
  # todo: use sample rate
  def sample
    self[rand(self.size)]
  end
  def sampleNote
    if self.size==0
      rand(0x7f)
    else
      self.sample
    end
  end
  def reset
    modeinit
    initialize
  end
end
def unirand n,c,reset=false
  a=[0,n]
  while c>a.size
    t=rand(n-2)+1
    a<<t if ! a.member?(t)
  end
  a.sort_by{rand}
end

# accumulated time with event
class TotalTime
  def initialize t=0
    @t=t
    @series={}
  end
  def set num,t
    add(t)
    @series[num]=@t
  end
  def addtime num,t
    add(t)
    @series[num]+=t
  end
  def add t
    @t+=t
  end
  def get num
    @series[num]
  end
  def all
    @series
  end
end
# midi event etc.
class Event
  @@counter=0
  @@tt=TotalTime.new
  attr_accessor :type, :value
  attr_reader :time, :number
  def initialize ty,*arg
    @number=@@counter
    @@counter+=1
    @type=ty
    @pos=0
    @value=""
    case @type
    # event without time;  except ':e'
    when :comment,:raw,:debugcomment
      settime(0)
      @value=arg[0]
    when :ahead
      settime(arg[0])
    when :on,:off
    when :mark
      @mark,@track,@value=arg
    # event with delta time;  ':e'
    when :dummy
    when :e, :end, :sys
      settime(arg[0])
      @value=arg[1]
    else
    end
  end
  def settime t
    @time=t
    @@tt.set(@number,@time)
    posset
  end
  def addtime t
    @time+=t
    @@tt.addtime(@number,t)
    posset
  end
  def posset
    @pos=@@tt.get(@number)
  end
  def showTotalTime
    a=@@tt.all
    a.keys.sort.map{|k|"#{k}: #{a[k]}"}
  end
  def reset
    @@tt=TotalTime.new
  end
  def data
    case @type
    when :raw
      rawdata(@value)
    when :mark
      "# marktrack(#{@track}_#{@mark}) [#{@value}]\n"
    when :comment,:on,:off
      @value
    else
      varlenHex(@time)+@value
    end
  end
  def debugdata
    case @type
    when :raw
      "raw"
    when :mark
      "mark(#{@track}_#{@mark}) [#{@value}]"
    when :comment
      @value
    else
      ""
    end
  end
  def display
    "#{@pos}(#{@time}) #{@type} => #{@value}"
  end
end

# arg=[steps],[values]
def mymerge span,*arg
  r=[]
  arg.each{|ar|
    next if ! ar
    m,steps,start,vs=ar
    steps=[steps] if steps.class!=Array
    steps=steps*(vs.size-1) if steps.size==1
    r<<[start,m,vs[0]]
    if vs.size>1
      stepsum=steps.inject{|s,i|s+i}+start
      vsize=vs.size-1
      if stepsum>span
        rate=(span-start)*1.0/stepsum
        steps=steps.map{|i|(i*rate).to_i}
      end
      n=1
      r+=vs[1..-1].map{|i|
        t=steps.shift*n+start
        n+=1
        [t,m,i]
      }
    end
  }
  n=0
  all=r.sort_by{|t,m,e|t}
  rest=span-all[-1][0]
  all.map{|t,m,e|
    tt=t-n
    n=t
    [tt,m,e]
  }+[[rest,:rest]]
end
def rawdata d
  d.gsub(","){" "}
end
def trackSizeHex d,cmark="#"
  d=d.commentoff("",cmark).split.join
  i=(d.size+8)/2
  #("00000000"+i.to_s(16))[-8..-1]
  format("%08x",i)+"  # size: #{i}"
end
# 可変長数値表現
# 7bitずつに区切り最後以外のbyteは先頭bitを立てる
def varlen(v)
  if v < 0x80
    return v
  else
    v1 = v & 0b01111111
    v2=(v-v1)>>7
    v2 =varlen(v2)
    return [v2,v1]
  end
end
def hex2digit d
  if d.class==String
    if d=~/^0(x|X)/
      d=d.to_i(16)
    else
      d=d.to_i
    end
  end
  d
end
def varlenHex(v)
  v=hex2digit(v)
  raise if v<0
  b=[varlen(v.round)]
  b=b.flatten
  c=b[0..-2].map{|i| i | 0x80 }
  r=[c,b[-1]].flatten
  res=0
  r.each{|i|
    res=res*0x100+i
  }
  format("%0#{b.size*2}x",res)
end
def hext2hex d
  ar=d.split(/[ ,]+/)-[""]
  hex=ar.map{|i|i.size==2}.uniq==[true]
  lasth=ar.map{|i|true if i=~/h$/}.uniq==[true]
  zx=ar.map{|i|true if i=~/^0x/}.uniq==[true]
  r=ar.map{|i|i[0..1]} if lasth
  r=ar.map{|i|i[2..-1]} if zx
  r=ar if hex
  r
end
def midiVround v
  [[v,0x7f].min,0].max
end
def rolandcheck d
  return d if $ignoreChecksum
  if d[1]=="41"
    org=d[2]
    s=0
    [*5..(d.size-3)].each{|i|s+=d[i].to_i(16)}
    csum=0x80-s%0x80
    if $DEBUG && csum!=org.to_i(16)
      "# sysEx: roland check sum bad?"
    end
    d[-2]=format("%02X",csum)
  end
  d
end
def sysEx2mes d
  r=hext2hex(d)
  r=rolandcheck(r)
  "#{r[0]} #{varlenHex(r.size-1)} #{r[1..-1]*" "}"
end
def txt2hex t
  r=[]
  t.each_byte{|i|
    r<<format("%02x",i)
  }
  size=r.size
  [r*" ",varlenHex(size)]
end
def bendHex d
  c=d.to_i+MidiHex::BendHalf
  c=[[c,0].max,MidiHex::BendMax].min
  a=c>>7
  b=c & 0b01111111
  r=[a,b,b*0x100+a]
  format("%04x ",r[2])
end

module MidiRead
  def self.msplit s,dat
    li=s.split('')
    dat=dat.split('')
    block={}
    num=0
    li.size.times{|i|
      num+=1 if li[i,4]==dat
      block[num] ? block[num]+=li[i] : block[num]=li[i]
    }
    block.keys.sort.map{|i|block[i]}
  end
  def self.head d
    return @head if @head
    r=self.msplit(d,'MTrk')
    @head,@tracks=r[0],r[1..-1]
    @head
  end
  def self.tracks d
    return @tracks if @tracks
    r=self.msplit(d,'MTrk')
    @head,@tracks=r[0],r[1..-1]
    @tracks
  end
  def self.read file,tracknum=false
    @head=false
    @tracks=false
    d=""
    if File.exist?(file)
      open(file,"rb"){|f|
        d=f.read
      }
      @head=self.head(d)
      @tracks=self.tracks(d)
    else
      STDERR.puts" can't read file #{file}"
    end
    if tracknum
      tracknum<tracks.size ? @tracks[tracknum-1] : @tracks[0]
    else
      [@head,@tracks]
    end
  end
  def self.readtrack file,num=false
    self.read file
    if num
      @tracks[num]
    else
      @tracks
    end
  end
end
def apply d,macro
  d.scan(/\$\{[^ ;\$_*^,\)\(`'\/+-]+\}|\$[^ ;\$_*^,\)\(`'\/+-]+|./).map{|i|
    case i
    when /^\$\{([^ ;\$_*^,\)\(`'\/+-]+)\}|^\$([^ ;\$_*^,\)\(`'\/+-]+)/
      key=$1||$2
      if macro.keys.member?(key)
        macro[key]
      else
        i
      end
    else
      i
    end
  }*""
end
def innerdata pre,a
  "_#{pre}__#{a*"_"}?"
end
def rawHexPart d,macro={}
  li=d.scan(/\$se\([^)]*\)|\$delta\([^)]*\)|\$bend\([^)]*\)|\(bend:[^)]*\)|\(expression:[^)]*\)|\(expre:[^)]*\)|./)
  res=[]
  li.map{|i|
    case i
    when /\$se\(([^)]*)\)/
      d=apply($1,macro)
      sysEx2mes(d)
    when /\$delta\(([^)]*)\)/
      varlenHex($1)
    when /\$bend\(([^)]*)\)/
      d=apply($1,macro)
      bendHex(d)
    when /\(bend:([^)]*)\)/
      innerdata("b",$1.split(','))
    when /\(expre(ssion)?:([^)]*)\)/
      innerdata("e",$1.split(','))
    else
      i
    end
  }*""
end
def worddata word,d
  d=~/\(#{word}:(([[:digit:].]+),)?([-+,.[:alnum:]]+|[[:alpha:]]+)\)/
  if $&
    start=0
    vp,vm=0,0
    case word
    when "bend"
      vi=self.bendVibrato
      vp,vm="+#{vi}","+-#{vi}"
    when "expre"
      vi=self.expreVibrato
      vp,vm="+-#{vi}","+#{vi}"
    when "panpot"
      vi=self.panpotVibrato
      vp,vm="+-#{vi}","+#{vi}"
    end
    pos=$1 ? $2.to_i : 0
    depth=$3.split(',').map{|i|
      case i
      when "+","-" ; i
      when /\Astart([[:digit:].]+)\z/
        start=$1.to_i
        false
      when "vibrato" ; [vp,vm,vp,vm]
      else         ; i
      end
    }.flatten-[false]
    [:"#{word}",pos,start,depth]
  else
    false
  end
end
class OrderedSet
  def initialize
    @cyclecheck=false
  end
  def cyclecheck on=true
    @cyclecheck=on
    self
  end
  def orderby smaller,a,b
    if smaller[a].member?(b)
      return -1
    elsif smaller[b].member?(a)
      return 1
    end
    0
  end
  def ccheck s,depth=2
    return false if depth<1 or not @cyclecheck
    keys=s.keys
    keys.each{|i|
      tmp=s[i]
      depth.times{
        tmp=tmp.map{|k|[k,s[k]]}.flatten
      }
      if tmp.member?(i)
        p "bad cycle #{i}, depth:#{depth}"
        return true 
      end
    }
    false
  end
  def smerge o, depth=2
    all=o.flatten.uniq
    smaller={}
    all.each{|i|
      o.each{|k|
        if k.member?(i)
          smaller[i]=smaller[i] ? smaller[i]+k.select{|n|k.index(i)<k.index(n)} : k.select{|n|k.index(i)<k.index(n)}
        end
      }
    }
    raise if ccheck(smaller,depth)
    smaller
  end
  def calc smaller,ar
    s=ar.size
    ar.each{|i|
      ind=ar.index(i)
      (s-ind-1).times{|n|
        j=ar[ind+n+1]
        r=orderby(smaller,i,j)
        puts "#{r} #{i} #{j}" if $DEBUG && $debuglevel>1
        return false if r>0
      }
    }
    true
  end
  def common a,b
    (a+b).uniq-(a-b)-(b-a)
  end
  def omerge base,o
    return base if o==[[]]
    return o[0] if base.size==0 && o.size==1
    rest=o-[base]
    r=base.dup
    rest.each{|i|
      n=i.dup
      cmn=common(r,n)
      if cmn.size>0
        p1,p2=cmn[0],cmn[-1]
        r1=r.select{|j|r.index(j)<r.index(p1)}
        r3=r.select{|j|r.index(j)>r.index(p2)}
        r2=r-r1-r3-[p1,p2]
        n1=n.select{|j|n.index(j)<n.index(p1)}
        n3=n.select{|j|n.index(j)>n.index(p2)}
        n2=n-n1-n3-[p1,p2]
        if p1==p2
          mid=[p1]
        else
          mid=[p1]+omerge(r2,[n2])+[p2]
        end
        r=omerge(r1,[n1])+mid+omerge(r3,[n3])
      else
        ins0=r.size
        n.size.times{
          pop=n.pop
          size=r.size
          ins=[rand(size+1),ins0].min
          r.insert(ins,pop)
          ins0=ins
        }
      end
    }
    r
  end
  def sort o, depth=2
    return [] if o==[]
    stime=Time.now
    o=o.sort_by{|i|i.size}
    base=o[-1]
    begin
      s=smerge(o,depth)
    rescue
      return []
    end
    f=o.flatten.uniq
    rest=f-base
    c=0
    cc=0
    print "sort" if $DEBUG
    while 1
     c+=1
     print "," if $DEBUG && c%20==0
     r=rest.sort_by{|i|rand(rest.size*2+c)-s[i].size}
     begin
       cc+=1
       f=omerge(base,o)
     end until f
     break if calc(s,f)
     p f if $DEBUG && $debuglevel>1
    end
    t=Time.now-stime
    puts " try: #{c} (check #{cc}) #{t}sec." if $DEBUG || t>10
    f
  end
end
class MarkTrack
  def initialize
    @mt={}
    @maxtrack=0
    @marks=[]
    @markstracks={}
    @added={}
    @diff={}
  end
  def makekey t,m
    "#{t}_#{m}"
  end
  def set m,t,pos
    @maxtrack=t if t>@maxtrack
    @marks<<m if not @marks.member?(m)
    @markstracks[t]=[] if not @markstracks[t]
    @markstracks[t]<<m if not @markstracks[t].member?(m)
    @mt[makekey(t,m)]=pos
  end
  def getcount m,t
    key=makekey(t,m)
    @mt.keys.select{|k|k==key||k=~/^#{key}@/}.size
  end
  def get m,t
    @mt[makekey(t,m)]
  end
  def getmax m
    [*1..@maxtrack].map{|t|
      key=makekey(t,m)
      (@mt[key] ? @mt[key] : 0)+(@added[t] ? @added[t] : 0)
    }.max
  end
  def sortmark
    marks=@marks
    s=[]
    s=@markstracks.keys.map{|k|@markstracks[k]}
    OrderedSet.new.cyclecheck.sort(s)
  end
  def calc
    marks=sortmark
    p marks if $DEBUG
    @diff={}
    @added={}
    marks.each{|k|
      max=getmax(k)
      @maxtrack.times{|i|
        t=i+1
        key=makekey(t,k)
        if @mt[key]
          @diff[key]=max-@mt[key]-(@added[t]||0)
          @added[t]=@added[t] ? @added[t]+@diff[key] : @diff[key]
        end
      }
    }
    puts ["mt:",@mt],["diff",@diff],["added",@added] if $DEBUG
    @diff
  end
end
def guitarTuning
  %W[-e -a d g b +e]
end
module MidiHex
    BendMax=16383
    BendHalf=8192
  # initialize
  def self.prepare bpm=120,tbase=480,vel=0x40,oct=:near,vfuzzy=2,strict=false
    @ready=true
    @tonality=Tonality.new("c")
    @bendHalfMax=BendHalf
    @strictmode=strict
    @autopan= strict ? false : true
    @strokefaster= strict ? 1 : 3
    @startBpm=bpm
    @midiname=false
    @trackChannel={}
    @trackName={}
    @cmark="#"
    @marktrack=MarkTrack.new
    @octmode=oct
    @tbase=tbase
    @gateRate=100
    @nowtime=0
    @onlist=[]
    @registerHash={}
    @swingHash={1=>1.2,2=>1.8}
    @waitingtime=0
    @rythmChannel=9
    @notes=Notes.new
    @ch=0
    @expressionRest=0x60
    @expressionDef=0x7f
    @expression=@expressionDef
    @velocity=vel
    @velocityOrg=vel
    @velocityFuzzy=vfuzzy
    @accentPlus=10
    @basekey=0x3C
    @chordCenter=@chordCenterOrg=@basekey
    @basekeyRythm=@basekeyOrg=@basekey
    @bendCentOn=false
    @bendrange=2
    @bendNow=0
    self.bendCentReset
    @pancenter=64
    @scalenotes=ScaleNotes.new.reset
    @gtune=guitarTuning
    self.setDefault
    @chmax=15
    @bendrangemax=24
    file="midi-programChange-list.txt"
    pfile="midi-percussion-map.txt"
    base=File.dirname(__FILE__)
    file=File.expand_path(file,base) if not File.exist?(file)
    pfile=File.expand_path(pfile,base) if not File.exist?(pfile)
    self.loadProgramChange(file)
    self.loadPercussionMap(pfile)
    self.dumpstatus if $DEBUG && $debuglevel>3
  end
  def setBendRangeMax v
    @bendrangemax=v
  end
  def self.setDefault
    @prepareSet=[
      @tbase,@ch,@velocity,@expression,@velocityFuzzy,@basekey,@gateRate,@bendCentOn,@bendrange,@bendCent,@bendNow,@scalenotes,@gtune,@expressionRest,@expressionDef,@registerHash,@swingHash,@tonality
    ]
  end
  def self.getDefault
      @tbase,@ch,@velocity,@expression,@velocityFuzzy,@basekey,@gateRate,@bendCentOn,@bendrange,@bendCent,@bendNow,@scalenotes,@gtune,@expressionRest,@expressionDef,@registerHash,@swingHash,@tonality=
      @prepareSet
  end
  def self.dumpstatus
    self.instance_variables.each{|i|
      val=self.instance_variable_get(i)
      p [i, val] if "#{val}".size<100
    }
  end
  def self.setTonality n
    @tonality.set(n)
  end
  def self.setmidiname name
    @midiname=name
  end
  def self.getmidiname
    @midiname
  end
  def self.setfile name
    @title=false
    cmark="".cmark
    if name && File.exist?(name)
      list=File.readlines(name).select{|i|i=~/^#{cmark}/}
      t=list.map{|i|i=~/^#{cmark} *title */;$'}-[nil]
      @title=t[0].chomp if t.size>0
      m=list.map{|i|i=~/^#{cmark} *midifilename */;$'}-[nil]
      if m.size>0
        @midiname=m[0].chomp
        @midiname+=".mid" if @midiname !~ /\.mid$/
      end
    end
    @data=File.read(name).commentoff(" ;").toutf8 if name && File.exist?(name)
  end
  def self.getdata
    @data
  end
  def self.setdata d
    @data=d.size>0 ? d : false
  end
  def self.accent a
    @accentPlus=a.to_i
  end
  def self.setGateRate g
    @gateRate=[g,100].min
  end
  def self.bendRange v
    @lastbend=0
    case v
    when /^\+/
      @bendrange+=$'.to_i
    when /^\-/
      @bendrange-=$'.to_i
    else
      @bendrange=v.to_i
    end
    @bendrange=[[@bendrange,@bendrangemax].min,0].max
    self.bendCentReset
    r=[]
    r<<Event.new(:comment,"# bendRange #{@bendrange}")
    r<<self.controlChange("101,0")
    r<<self.controlChange("100,0")
    r<<self.controlChange("6,#{@bendrange}")
    r
  end
  def self.bendCentReset
    cent= @bendCentOn ? 100.0 : 1
    @bendCent=@bendHalfMax/@bendrange/cent
  end
  def self.vibratoType m
    @vibratoType=
       case m
       when /^expre/
         "expre"
       when /^bend/
         "bend"
       when /^pan/
         "panpot"
       else
         "bend"
       end
  end
  def self.bendVibrato
    @vibratoRate||=0.4
    v=@vibratoRate*@bendCent
    v.to_i
  end
  def self.expreVibrato
    @vibratoRate||=0.1
    v=@vibratoRate*@expression
    v.to_i
  end
  def self.panpotVibrato
    @vibratoRate||=0.5
    v=@vibratoRate*0x7f
    v.to_i
  end
  def self.bendCent on
    @bendCentOn=on
    self.bendCentReset
    @lastbend=0
  end
  # track initialize
  def self.trackPrepare tc=0
    self.getDefault
    @dummyNoteOrg=["o","O"]
    @multidummySize=3
    @basekeybend=0
    @theremin=false
    @strokespeed=0
    @strokeUpDown=1
    @preGate=[]
    @preVelocity=[]
    @preNote=[]
    @preLength=[]
    @preBefore=[]
    @preAfter=[]
    @registered=[]
    @tracknum=tc+1
    tc+=1 if tc>=@rythmChannel # ch10 is drum kit channel
    tc=@chmax if tc>@chmax
    @panoftrack=panbytrack(tc)
    @ch=tc
    @trackChannel[@tracknum]=@ch
    @trackName[@tracknum]=""
    Event.new(:dummy).reset
  end
  def self.header format,track,tbase=@tbase
    format=[format,0xff].min
    track=[track,0xff].min
    tbase=[tbase,0x7fff].min
    @tbase=tbase
    format=format("%02x",format)
    track=format("%02x",track)
    tbase=format("%04x",tbase)
    "
# Standard MIDI File data start
# header
      4D 54 68 64  # header
      00 00 00 06  # length of data :6[byte]
      00 #{format} # format
      00 #{track}  # track number
      #{tbase}      # tiks; division of a beat #{@tbase}
    "
  end
  def self.byGate len,g=@gateRate,lenforgate=false
    lenforgate||=len
    g=@preGate.shift if @preGate.size>0
    gl=(lenforgate*1.0*g/100).to_i
    l=gl+(len-lenforgate)
    r=len-l
    l,r=len,0 if len<lenforgate
    [l,r]
  end
  def self.notesharp note,sharp
    s=0
    if sharp!=0
      s=sharp
    else
      s=@tonality.getSharp(note)
    end
    s
  end
  def self.soundOn key=@basekey,velocity=@velocity,ch=@ch,sharp=0
    key=self.note2key(key) if key.class==String
    key,ch=key if key.class==Array
    ch=[ch,0x0f].min
    velocity-=rand(@velocityFuzzy) if @velocityFuzzy>0
    velocity=[velocity,0x7f].min
    key+=sharp
    @key=[[key,0x7f].min,0].max
    @onlist<<@key
    key=format("%02x",@key)
    ch=format("%01x",ch)
    vel=format("%02x",velocity)
    start=@waitingtime
    @waitingtime=0
    @nowtime+=start
    r=[Event.new(:on)]
    r<<Event.new(:e,start," 9#{ch} #{key} #{vel} # #{start} later, sound on only , note #{Notes.nDisplay(@key)} velocity #{velocity}\n")
    r
  end
  def self.soundOff key=@basekey,ch=@ch,sharp=0
    key=self.note2key(key) if key.class==String
    key,ch=key if key.class==Array
    ch=[ch,0x0f].min
    key+=sharp
    @key=[[key,0x7f].min,0].max
    @onlist-=[@key]
    key=format("%02x",@key)
    ch=format("%01x",ch)
    start=@waitingtime
    @waitingtime=0
    @nowtime+=start
    r=[Event.new(:off)]
    r<<Event.new(:end,start," 8#{ch} #{key} 00 # #{start} sound off only [#{(@nowtime/@tbase).to_i}, #{@nowtime%@tbase}]\n")
    r
  end
  def self.thereminNote pos,key,velocity,ch,exp=@expression
    r=[]
    r<<Event.new(:comment,"# use theremin")
    @expression=exp
    if @expression
      r<<self.expre(0,@expression)
    end
    start=@waitingtime
    @waitingtime=0
    pos-=start
    depth=(key-@thereminNote)*100
    depth=depth+@bendNow
    r<<self.bend(start,depth.to_s,ch)
    r<<self.bend(pos,depth.to_s,ch)
    r
  end
  def self.oneNote len=@tbase,key=@basekey,velocity=@velocity,ch=@ch,sharp=0,swing=false
    len+=len*self.getswing(swing)
    bendStart=@bendNow
    ch=[ch,0x0f].min
    key=self.rndNote if @dummyNoteOrg.member?(key)
    key+=sharp
    @key=[[key,0x7f].min,0].max
    return self.thereminNote(len,key,velocity,ch) if @theremin
    velocity=@preVelocity.shift if @preVelocity.size>0
    gate=@gateRate
    if @registered.member?(:staccato)
      @registered-=[:staccato]
      gate=10
    end
    velocity-=rand(@velocityFuzzy) if @velocityFuzzy>0
    velocity=[velocity,0x7f].min
    key=format("%02x",@key)
    ch=format("%01x",ch)
    vel=format("%02x",velocity)
    start=@waitingtime
    @waitingtime=0
    slen,rest=self.byGate(len,gate,@lenForGate)
    @lenForGate=false
    @nowtime+=start
    r=[]
    r<<Event.new(:e,start," 9#{ch} #{key} #{vel} # #{start} later, sound on note #{Notes.nDisplay(@key)} velocity #{velocity}\n")
    b=@preAfter.shift
    bends=expre=false
    if b
      bends=worddata("bend",b)
      expre=worddata("expre",b)
      panpot=worddata("panpot",b)
      mymerge(slen,bends,expre,panpot).each{|t,m,d|
        case m
        when :bend
          r<<self.bend(t,d)
        when :expre
          r<<self.expre(t,d)
        when :panpot
          r<<self.panpot(d,t)
        when :rest
          slen=t
        end
      }
    end
    @nowtime+=slen
    r<<Event.new(:e,slen," 8#{ch} #{key} 00 # #{slen}(gate:#{@gateRate})- #{len.to_i}(#{len.round(2)})ticks later, sound off [#{(@nowtime/@tbase).to_i}, #{@nowtime%@tbase}]\n")
    r<<self.bend(0,bendStart) if bends
    @bendNow=bendStart
    r<<self.expre(0,127) if expre
    if rest>0
      @nowtime+=rest
      r<<Event.new(:end,rest," 8#{ch} #{key} 00  # #{rest} len-gate\n")
    end
    r
  end
  def self.resetRand
    @lastRandNote=false
  end
  def self.rndNote useScale=true
    key=rand(0x7f)
    key=self.note2key(@scalenotes.sample) if @scalenotes.size>0 && useScale
    if @downRandDummy && @lastRandNote
      key-=12 while key>@lastRandNote && key>12
    elsif ! @downRandDummy && @lastRandNote
      key+=12 while key<@lastRandNote && key<127-12
    end
    @lastRandNote=key
    key
  end
  def self.dummyNote key,len,accent=false,sharp=0,swing=false
    len+=len*self.getswing(swing)
    vel=@velocity
    vel+=@accentPlus
    @downRandDummy=false
    if key=="?"
      key=rndNote
    elsif key=="O"
      @downRandDummy=true
    end
    key=@preNote.shift if @preNote.size>0
    len=@preLength.shift if @preLength.size>0
    self.oneNote(len,key,vel,sharp)
  end
  def self.byKey key,len,accent=false,sharp=0,swing=false
    vel=@velocity
    vel+=@accentPlus
    self.oneNote(len,key,vel,@ch,sharp,swing)
  end
  def self.notekey key,length=false,accent=false,sharp=0,swing=false
    len,velocity,ch=[@tbase,@velocity,@ch]
    velocity+=@accentPlus if accent
    len=length if length
    if key.class==Fixnum
    else
      key,ch=key
    end
    key=key+@basekey
    self.oneNote(len,key,velocity,ch,sharp,swing)
  end
  def self.percussionNote key,len=@tbase,accent=false,sharp=0,swing=false
    vel=@velocity
    vel+=@accentPlus if accent
    self.oneNote(len,key,vel,@rythmChannel,sharp,swing)
  end
  def self.noteCalc c,last,base
    n=@notes[c]
    n+=self.notesharp(c,0)
    if @octmode==:near && n.class != Array
      if last
        n+=12 if last-n>6
        n-=12 if last-n<-6
      end
      last=n
      (base+=12;last-=12) if n>=12
      (base-=12;last+=12) if n<0
      n=last
    end
    [n,last,base]
  end
  def self.float2bend f
    v=f*@bendHalfMax/@bendrange
    if @bendCentOn
      v=f*100 
    end
    v
  end
  def self.notes c,l=false,accent=false,sharp=0,sharpFloat=false,swing=false
    if sharpFloat && (sharpFloat!=0)
      s=sharp+sharpFloat
      sharp=s.to_i
      sharpFloat=s-sharp
    end
    bendStart=@bendNow
    @lastnoteName=c
    @basekey=@basekeyCenter+12*(rand(5)-2) if @broken
    n,@lastnote,@basekey=self.noteCalc(c,@lastnote,@basekey)
    r=[]
    if sharpFloat && sharpFloat!=0
      v=float2bend(sharpFloat)
      @bendNow=v
      v+=bendStart
      r<<self.bend(0,v) if not @theremin
      r<<self.notekey(n,l,accent,sharp,swing)
      r<<self.bend(0,bendStart) if not @theremin
      @bendNow=bendStart
    else
      r<<self.notekey(n,l,accent,sharp,swing)
#      r<<self.bend(0,bendStart)# if bends
#      @bendNow=bendStart
    end
    r
  end
  def self.shiftChord chord, base, limit=6
    octave=12
    chord=chord.orotate(-1) while chord[0]>base+limit
    chord=chord.orotate(1) while chord[0]<base-limit
    chord
  end
  def self.chordName c,l=false,accent=false,sharp=0,swing=false
    l+=l*self.getswing(swing)
    same=false
    same=(@lastchordName==c) if @lastchordName
    if same
      chord=@lastchord
      if not (chord[0]-@firstchordbase).abs<7
        puts "# same chord auto inversion, too far" if $DEBUG && $debuglevel>1
        chord=self.shiftChord(chord,@firstchordbase)
      end
    else
      @lastchordName=c
      c=~/(.)([^(]*)(\((.*)\))?/
      root=$1
      type=$2
      subtype=$4
      base=self.note2key(root)+sharp
      ten=Chord.notes(type,subtype)
      p "#{root} #{ten*','}" if $DEBUG
      chord=ten.sort.map{|i|base+i}
      chord=self.invert(@lastchord,chord)
      if @firstchordbase && ! ((chord[0]-@firstchordbase).abs<12)
        puts "# chord auto inversion, too far." if $DEBUG && $debuglevel>1
        chord=self.shiftChord(chord,@firstchordbase)
      end
    end
    @lastchord=chord
    if ! @firstchord
      @firstchord=chord
      @firstchordbase=@firstchord[0]
    end
    self.chord(chord,l,accent)
  end
  def self.invert last,c
    last=c if ! last
    root=last[0]
    r=c.map{|i|
        s=(root-i).abs%12
        if s>6
          s=12-s
        end
        [s,i]
      }.sort_by{|s,i|s}[0][1]
    n=(root-r)%12
    r=n>6 ? root-(12-n) : root+n
    cc=c.map{|i|(i-r)%12}.sort.map{|i|i+r}
    cc
  end
  def self.chord c,l=false,accent=false,sharp=0,swing=false
    l+=l*self.getswing(swing)
    r=[]
    c=c.map{|i|i =~/^\?/ ? ["?"]*@multidummySize : i }.flatten
    sspeed=@strokespeed
    c=c.reverse if @strokeUpDown<0
    span=c.size
    sspeed=l/span/@strokefaster if span*sspeed>l/@strokefaster
    tmp=[]
    ns=c.map{|i|
      case i
      when "?"
        i=self.rndNote
        i+=12 if tmp.member?(i)
        tmp<<i
        i
      else
        i
      end
    }
    ns.each{|i|
      r+=self.soundOn(i,@velocity,@ch,sharp)
      @waitingtime+=sspeed
    }
    l-=sspeed*(span-1)
    @waitingtime,rest=self.byGate(l)
    ns.each{|i|
      r+=self.soundOff(i,@ch,sharp)
    }
    self.strokeUpDownReset
    r+=self.rest(rest,false,@ch) if rest>0
    r
  end
  def self.strokeUpDownReset
    @strokeUpDown=1
  end
  def self.setExpressionRest v
    @expressionRest=v.to_i
  end
  def self.rest len,swing=false,ch=@ch
    chx=format("%01x",ch)
    @nowtime+=len
    r=[]
    if @theremin
      min=@expressionRest
      r<<Event.new(:comment,"# rest; ")
      r<<self.expre(0,min)
      r<<self.expre(len,min)
    else
      r<<Event.new(:end,len," 8#{chx} 3C 00 # rest #{len.to_i}(#{len.round(2)})ticks later, off:ch#{ch}, key:3C\n")
    end
    r
  end
  def self.restHex len=@tbase,ch=@ch
    r=self.rest(len,false,ch)
    r[0]
  end
  # d : hex data
  def self.metaEvent d,type=1
    t=format("%02X",type)
    len=varlenHex(d.split.join.size/2)
    " FF #{t} #{len} #{d}\n"
  end
  def self.metaHook d,type,pos=0
    hexd,len=txt2hex(d)
    delta=varlenHex(pos)
    e=self.metaEvent hexd,type
    Event.new(:raw,"#{delta} #{e} # #{d}\n")
  end
  def self.metaTitle d=@title,pos=0
    return "" if not d
    self.metaHook d,3,pos
  end
  def self.metaCopyright d,pos=0
    self.metaHook d,2,pos
  end
  def self.metaText d,pos=0
    self.metaHook d,1,pos
  end
  def self.generaterText
    thisVer="v#{version}"
    thisVer="" if $debuglevel>1
    pos=@tbase
    self.metaText("generated by midi-simple-make.rb (#{thisVer})",pos)
  end
  def self.lastrest
    self.metaText("data end",@tbase)
  end
  def self.dummyEvent comment,pos=0,d="00",type=1
    delta=varlenHex(pos)
    t=format("%02X",type)
    len=varlenHex(d.split.join.size/2)
    Event.new(:raw,"#{delta} FF #{t} #{len} #{d} # #{pos} #{comment}\n")
  end
  def self.tempo bpm, len=0
    @bpmStart=bpm if ! @bpm
    @bpm=bpm
    d_bpm=self.makebpm(@bpm)
    @nowtime+=len
    Event.new(:e,len,"#{self.metaEvent(d_bpm,0x51)} # 四分音符の長さ (bpm: #{@bpm}) マイクロ秒で3byte\n")
  end
  def self.starttempo
    self.tempo(@startBpm)
  end
  def self.makebpm bpm
    d="000000"+(60_000_000/bpm.to_f).to_i.to_s(16)
    d[-6..-1]
  end
  def self.controlChange v
    v=~/^([^,]*),([^,]*)(,(.*))?/
    n,v,len=$1.to_i,$2.to_i,$4.to_i
    ch=@ch
    v=[0,[v,0x7f].min].max
    ch=format("%01x",ch)
    n=format("%02x",n)
    data=format("%02x",v)
    t=@waitingtime+len
    @waitnigtime=0
    @nowtime+=t
    Event.new(:e,t," B#{ch} #{n} #{data}\n")
  end
  def self.panpot v,pos=0
    @pan||=@panoftrack
    @pan=self.valueplus(@pan,v)
    self.controlChange("10,#{@pan},#{pos}")
  end
  def self.valueplus org,d
    d=d.to_s
    d=~/([+-]*)/
    sign=$1
    plus=false
    case sign
    when /^\+/
      d=d[1..-1].to_i
      plus=true
    when /^-/,""
      d=d.to_i
    else
      STDERR.puts "plus: ?"
    end
    if plus
      org+=d
    else
      org=d
    end
    org
  end
  def self.expre len,d
    c=@expression
    explus=10
    case d
    when "+" ; c+=explus
    when "-" ; c-=explus
    else
      c=self.valueplus(c,d)
    end
    c=midiVround(c)
    @expression=c
    r=[]
    r<<Event.new(:comment,"# expression #{d}")
    r<<self.controlChange("11,#{c},#{len}")
    r
  end
  def self.ProgramChange ch,inst,len=0
    ch=@ch if ch==false
    ch=[ch,0x0f].min
    inst=[inst,0xff].min
    chx=format("%01x",ch)
    instx=format("%02x",inst)
    @nowtime+=len
    Event.new(:e,len," C#{chx} #{instx} # program change ch#{ch} #{inst} [#{@programList[inst][1]}]\n")
  end
  # system exclusive message event
  #   = F0 [len] [maker id(1-3 byte)] [data] F7
  def self.sysExEvent d
    d=d+" F7"
    s=varlenHex(d.split.join.size/2)
    " F0 #{s} #{d}"
  end
  # GM,GS,XG wakeup command need over 50milisec. ?
  # if not, midi player may hung up.
  def self.GMsystemOn len=0,mode=1
    # GM1,GM2
    m=mode==2 ? 3 : 1
    @nowtime+=len
    ex=self.sysExEvent("7E 7F 09 0#{m}")
    Event.new(:sys,len," #{ex} # GM\n")
  end
  def self.XGsystemOn len=0
    @bendrangemax=127
    @nowtime+=len
    ex=self.sysExEvent("43 10 4C 00 00 7E 00")
    Event.new(:sys,len," #{ex} # XG\n")
  end
  def self.xgMasterTune d,len=0
    d=[[d.to_i,-100].max,100].min
    n=(d+100)*256/200
    m=n/16
    l=n%16
    ex=self.sysExEvent("43 10 27 30 00 00 #{format"%02x",m} #{format"%02x",l} 00")
    Event.new(:sys,len," #{ex} # XG midi master tune \n")
  end
  def self.GSreset len=0
    @nowtime+=len
    ex=self.sysExEvent("41 10 42 12 40 00 7F 00 41")
    Event.new(:sys,len," #{ex} # GS \n")
  end
  def self.bankSelect d
    d=~/([^,]*),([^,]*)(,(.*))?/
    msb,lsb=$1.to_i,$2.to_i
    msb=[msb,0x7f].min
    lsb=[lsb,0x7f].min
    len=$4.to_i
    msb=format("%02x",msb)
    lsb=format("%02x",lsb)
    ch=@ch
    ch=format("%01x",ch)
    @nowtime+=len
    @nowtime+=len
    r=[]
    r<<Event.new(:sys,len," B#{ch} 00 #{msb} # BankSelect MSB\n")
    r<<Event.new(:sys,len," B#{ch} 20 #{lsb} # BankSelect LSB\n")
    r
  end
  def self.bankSelectPC d
    d="#{rand(0x7f)},rand(0x7f)},#{rand(0x7f)}" if d=="?"
    d=~/(([^,]*),([^,]*)),([^,]*)(,(.*))?/
    len=$6.to_i
    inst=$4.to_i ##
    bs=self.bankSelect("#{$1},#{len}")
    pc=self.ProgramChange(@ch,inst,len)
    [bs,pc]
  end
  def self.programGet p,num=false
    return 0 if not @programList
    if p=~/\?/
      r=[@programList[rand(@programList.size)]]
      p "random: ",r if $DEBUG
    else
      r=@programList.select{|n,line|line=~/#{p}/i}
      puts "no instrument name like '#{p}' in list" if $DEBUG && r.size==0
    end
    num=[num,r.size].min if num
    if num && r.size>0
      res=r[num-1][0]
    else
      res=r.size>0 ? r[0][0] : 0
    end
    res
  end
  def self.percussionGet p
    p=~/^_([^!]+)/
    p=$1 if $1
    return p.to_i if p=~/^[[:digit:]]+$/
    return @snare if not @percussionList
    return @gmKit[p] if @gmKit.keys.member?(p)
    r=@percussionList.select{|num,line|line=~/#{p}/i}
    puts "no percussion name like '#{p}' in list" if $DEBUG && r.size==0
    r.size>0 ? r[0][0] : @snare
  end
  def self.percussionList
    self.prepare if not @ready
    @percussionList.map{|i,v|"#{i} #{v}"}
  end
  def self.programList
    self.prepare if not @ready
    @programList.map{|i,v|"#{i} #{v}"}
  end
  def self.bend pos,depth,ch=false
    @lastbend||=0
    ch=@ch if ! ch
    depth.to_s=~/([+-]*)/
    sign=$1
    plus=false
    case sign.size
    when 0..1
      depth=depth.to_f
      plus=true if sign=="+"
    when 2
      depth=depth[1..-1].to_f
      plus=true
    else
      STDERR.puts "bend: ?"
    end
    depth=(depth*@bendCent).to_i if @bendCentOn
    if plus
      depth=@lastbend+depth
    end
    @lastbend=depth
    depth+=@basekeybend
    pos+=@waitingtime
    @waitingtime=0
    @nowtime+=pos
    Event.new(:e,pos," e#{format"%01x",ch} #{bendHex(depth)} # t:#{pos} bend #{depth}\n")
  end
  def self.masterVolume v,pos=0
    v=[[0,v].max,0x7f].min
    vol=format("%02x",v)
    ex=self.sysExEvent("7F 04 01 00 #{vol}")+" # master volume #{v}"
    Event.new(:e,pos,ex)
  end
  def self.note2key i
    # inside parenthesis -+ are octave
    oct=0
    i=~/^([-+]+)?(.+)/
    octave,tone=$1,$2
    i=tone if octave
    case octave
    when /-+/
      oct=-octave.size
    when /\++/
      oct=octave.size
    end
    k=if tone=~/^_/
        [self.percussionGet(tone),@rythmChannel]
      elsif @notes.keys.member?(i)
        @basekey+oct*12+@notes[i]+self.notesharp(i,0)
      else
        i.to_i
      end
    if k.class!=Array && k<0
      k+=12 while k<0
    elsif k.class!=Array && k>0x7f
      k-=12 while k>0x7f
    end
    k
  end
  def self.basekeySet d,num=1
    case d
    when "-"
      if @basekey-12*num < 0
        STDERR.puts "octave too low."
      else
        @basekey-=12*num
      end
    when "+"
      if @basekey+12*num > 0x7f
        STDERR.puts "octave too high."
      else
        @basekey+=12*num
      end
    else
      @basekey=d
    end
  end
  def self.basekeyReset
    self.basekeySet(@basekeyOrg)
    @basekeybend=0
  end
  def self.chordCenter c
    case c
    when "reset"
      @chordCenter=@chordCenterOrg
    when "+"
      @chordCenter-=6
    when "-"
      @chordCenter+=6
    when /^\+(.+)/
      @chordCenter+=$1.to_i
    when /^-(.+)/
      @chordCenter-=$1.to_i
    else
      @chordCenter=c.to_i
    end
    @chordCenter=[[0,@chordCenter].max,0x7f].min
    @firstchordbase=@chordCenter
  end
  def self.scale s
    s=s.scan(/[^,]-[^-,]+|[-+]+[[:digit:]]+|[^()]*\([^()]+\)|[^,]+|,/)-[","]
    first=s.first
    mode=s[1]
    if s.size==1
      case first
      when /^[-+]/
        shift=first.to_i
        @scalenotes=@scalenotes.move(shift)
      when /^(.)-([^-]+)$/
        f,mode=$1,$2
        @scalenotes.reset
        @scalenotes.setmode(f,:"#{mode}")
      when /^:?(.)(.*)/
        @scalenotes.reset
        base=$1
        ten=Chord.type($2)
        ten.each{|i|
          note=Notes.get(base,i)
          @scalenotes<<note
        }
      end
    else
      @scalenotes.reset
      s.each{|i|
        note=i
        note=Notes.get(first,i) if i=~/^[-+]+[[:digit:]]+$/
        @scalenotes<<note
      }
    end
    p @scalenotes if $DEBUG
  end
  def self.gtuning s
    @gtune=s.split(",")
  end
  def self.trackName n
    if @trackName.values.member?(n)
      c=@trackName.keys.select{|k|@trackName[k]==n}[0]
      @ch=@trackChannel[c]
    end
    @trackName[@tracknum]=n
  end
  def self.setlenforgate g
    # set temporary len for gaterate; for internal purpose
    # (g:70)...f~~           => 70% of 3, gate rest is 30% of 3
    # (g:70)...(gl:1.0)f~~   => 70% of 1.0, gate rest is 30% of 1.0
    @lenForGate=g.to_f*@tbase
  end
  def self.preLength v
    @preLength=v.map{|i|
      case i
      when "o",""
        @tbase
      when /^\*/
        $'.to_f
      else
        i.to_f*@tbase
      end
    }
  end
  def self.preNote v
    @preNote=v.map{|i|
      case i
      when "?"
        rand(0x7f)
      else
        self.note2key(i)
      end
    }
  end
  def self.preVelocity v
    @preVelocity=v.map{|i|
      case i
      when "o",""
        @velocity
      when "-"
        @velocity-10
      when "+"
        @velocity+10
      else
        i.to_i
      end
    }
  end
  def self.preGate v
    @preGate=v.map{|i|
      case i
      when "o",""
        @gateRate
      when "-"
        @gateRate*0.5
      else
        i.to_i
      end
    }
  end
  def self.revertPre d
    mode=@vibratoType
    d.gsub(/_b__([^?]*)\?/){"(bend:#{$1.split("_")*","})"}.
      gsub(/_e__([^?]*)\?/){"(expre:#{$1.split("_")*","})"}.
      gsub(/_p__([^?]*)\?/){"(panpot:#{$1.split("_")*","})"}.
      gsub(/_m__([^?]*)\?/){"(#{mode}:#{$1.split("_")*","})"}
  end
  def self.preAfter v
    @preAfter=v.map{|i|
      case i
      when "o",""
        false
      else
        revertPre(i)
      end
    }
  end
  def self.preBefore v
    @preBefore=v.map{|i|
      case i
      when "o",""
        false
      else
        i
      end
    }
  end
  def self.autopan v
    @autopan=v
  end
  def self.autopanset tnum
    @panstep=0x7f/(tnum+2)
  end
  def self.panbytrack tc
    if @autopan
      tc==@rythmChannel ? @pancenter : (tc+1)*@panstep
    else
      @pancenter
    end
  end
  def self.strokeSpeed s
    case s
    when "-"
      @strokeUpDown=-1
    when "+"
      @strokeUpDown=1
    else
      s=(s=~/\./ ? s.to_f : s.to_i)
      @strokeUpDown= s<0 ? -1 : 1
      @strokespeed=s.abs
      @strokespeed=(s.abs*@tbase).to_i if s.class==Float
    end
  end
  def self.setTheremin flag
    r=[]
    if flag
      if not @lastnote
        @lastnoteName="c"
        @lastnote=@notes["c"]
      end
      @thereminNote=@lastnote+@basekey
      r<<self.notes(@lastnoteName,0)
      key=format("%02x",@thereminNote)
      ch=format("%01x",@ch)
      vel=format("%02x",@velocity)
      r<<Event.new(:e,0," 9#{ch} #{key} #{vel} # theremin sound on note #{@thereminNote} velocity #{@velocity}\n")
      r<<self.bendRange(@bendrangemax)
      self.bendCent(true)
    else
      @thereminNote=false
      self.bendCent(false)
    end
    @theremin=flag
    r
  end
  def self.setmark m
    m=~/^([^,]+),/
    count=$'.to_i
    if $&
      if count>1
        m="#{$1}@#{$'.to_i}"
      else
        m=$1
      end
    else
      n=@marktrack.getcount(m,@tracknum)
      m="#{m}@#{n+1}" if n>0
    end
    @marktrack.set(m,@tracknum,@nowtime)
    Event.new(:mark,m,@tracknum,@nowtime)
  end
  def self.calcNoteFloat n,sharp,sharpFloat,base
    n=@notes[n] if n.class==String
    n+sharp+sharpFloat+base
  end
  def self.tneMid now,last,len,transitionrate
    n0,e0,sharp0,sharpFloat0,base0=last
    n,e,sharp,sharpFloat,base=now
    e=e.to_i
    e0=e0.to_i
    stepDefault=10
    step=stepDefault
    lastv=self.calcNoteFloat(n0,sharp0,sharpFloat0,base0)
    n,last,base=self.noteCalc(n,@notes[n0],base)
    stepN=self.calcNoteFloat(n,sharp,sharpFloat,base)-lastv
    stepE=e-e0
    step=1 if stepE==0 && stepN==0
    step=stepN.to_i*3 if stepN>stepDefault/3
    transitionl=len*transitionrate
    restl=len-transitionl
    stepL=transitionl*1.0/step
    stepE=stepE*1.0/step
    stepN=stepN*1.0/step
    r=[]
    step.times{|i|
      r<<self.expre(0,e0+stepE*i.succ) if e!=e0
      r<<self.notes(n0,stepL,false,sharp0,sharpFloat0+stepN*i.succ)
    }
    r<<self.expre(restl,e)
    r
  end
  def self.noteExpression arg,t,accent,sharp,sharpFloat,swing
    lexpression=@expression
    n,e=arg.split(',')
    r=[]
    r<<self.expre(0,e)
    r<<self.notes(n,t,accent,sharp,sharpFloat,swing)
    r<<self.expre(0,lexpression)
    r
  end
  # transition rate, note, expression
  def self.tne arg,t,accent,sharp,sharpFloat,swing
    t+=t*self.getswing(swing)
    exp=@expression
    trans,n,e=arg.split(',')
    trans=0.3 if trans.size==0
    trans=trans.to_f
    if trans>1
      STDERR.puts "(tne) transition rate must be between 0 and 1."
      trans=1.0
    end
    bchange=0
    @nowTne=[n,e,sharp,sharpFloat,@basekey]
    if @lastTne
      n,e,sharp,sharpFloat,base=@lastTne
      bchange=@basekey-base
      @basekey=base
    else
      @lastTne=@nowTne
    end
    r=[]
    r<<Event.new(:comment,"# tne #{arg}")
    r<<self.expre(0,e)
    r<<self.notes(n,0,accent,sharp,sharpFloat)
    r<<self.tneMid(@nowTne,@lastTne,t,trans)
    r<<self.expre(0,exp)
    @lastTne=@nowTne
    @basekey+=bchange
    @lastTne[-1]=@basekey
    r
  end
  def self.register v
    r=@registerHash[v.to_i]
    if r
      @registered<<r.to_sym
    else
      STDERR.puts "register: no data"
    end
  end
  def self.setSwing k,v,hs=@swingHash
    v=v.to_f
    k=~/of/
    if $&
      k,all=$`.to_i,$'.to_i
      hs[k]=v
      hs[all-k]=all-v
    else
      hs[k.to_i]=v
    end
  end
  def self.setRegister k,v
    @registerHash[k.to_i]=v
  end
  def self.broken v
    v=~/off/
    @broken= $& ? false : true
    @basekeyCenter=@basekey
  end
  def self.dumpVar v
    vars=self.instance_variables.map{|i|i.to_s[1..-1]}.sort
    s=v.split(',')
    s.each{|v|
      v=~/\A([[:alnum:]]+)[[:alnum:].]*\z/
      if $& && vars.member?($1)
        puts "@#{v} #{eval("@#{v}")}"
      elsif v=="?"
        puts vars*", "
      else
        puts "bad name '#{v}'"
      end
    }
  end
  def self.key2bend k
    v=k.class==Float ? @bendCent*(k-k.to_i) : 0
    v*=100 if @bendCentOn
    v
  end
  def self.eventlist2str elist
    @eventlist=[]
    r=@eventlist
    # EventList : [func,args]  or [callonly, func,args] or others
    elist.each{|h|
      cmd,*arg=h
      e=Event.new(:comment,"# #{cmd} #{arg}")
      r<<Event.new(:raw,self.metaText("#{cmd} #{arg}").data) if $debuglevel>5
      r<<e
      case cmd
      when :comment
      when :basekeyPlus
        @basekey+=arg[0].to_i
        @basekeybend+=self.key2bend(arg[0])
      when :raw
        r<<Event.new(:raw,arg[0])
      when :ahead
        r<<Event.new(:ahead,arg[0])
      when :velocity
        @velocity=arg[0]
      when :velocityFuzzy
        @velocityFuzzy=arg[0]
      when :ch
        @ch=arg[0]
      when :waitingtime
        @waitingtime+=arg[0]
      when :setInt
        name,v=arg
        if name.to_s=~/\A[[:alnum:]]+\z/
          eval("@#{name}=#{v.to_i}")
        else
          STDERR.puts "setInt: bad name '#{name}'"
        end
      when :setFloat
        name,v=arg
        if name.to_s=~/\A[[:alnum:]]+\z/
          eval("@#{name}=#{v.to_f}")
        else
          STDERR.puts "setFloat: bad name '#{name}'"
        end
      when :call
        cmd,*arg=arg
        method(cmd).call(*arg)
      when :soundOff
        if arg[0]=="all"
          @onlist.each{|o|
            r<<method(cmd).call(o)
          }
        else
          r<<method(cmd).call(*arg)
        end
      else
        r<<method(cmd).call(*arg)
      end
    }
    rr=[]
    ahead=0
    after=0
    r.flatten!
    r.each{|i|
      if i.class==String
        rr<<i
      else
          # Event class
          case i.type
          when :ahead
              ahead=i.time
              next if ahead==0
              n=0
              n-=1 until (rr[n].time>0) || n<-10
              if n>-10
                ahead=[ahead,-rr[n].time].max
                rr[n].addtime(ahead)
                after=-ahead
              else
                after=0
              end
            when :end,:e,:sys
              (i.addtime(after);after=0) if after>0
              (i.addtime(after);after=0) if after<0 && i.time+after>=0
              rr<<i
            when :comment,:raw,:mark,:debugcomment
              rr<<i
            else
              "? #{i}"
            end
      end
    }
    # Array of String or Event class instance
    rr
  end
  def self.getswing v,hs=@swingHash
    r=v ? hs[v.to_i] : false
    if r
      (r-v.to_i)/v.to_i
    else
      0
    end
  end
  def self.tie d,tbase,swingHash
    res=[]
    # if no length word after '~' length is 1
    li=[]
    li0=d.scan(MmlReg::RwAll)
    li0.size.times{|i|
      li<<li0[i]
      case li0[i]
      when "~","w"
        li<<"1" if li0[i+1] !~ /^(\*)?[[:digit:]]/
      else
      end
    }
    li.each{|i|
      case i
      when /^\(setSwing:(.*)\)/
        k,v=$1.split(',')
        self.setSwing(k,v,swingHash)
        res<<[:modifier,i]
      when /^(\*)?([[:digit:].]+)(_([[:digit:]]+)j,)?/
        tick=$1? $2.to_f : $2.to_f*tbase
        tick+=tick*self.getswing($4,swingHash)
        if res[-1][0]==:tick
          res[-1][1]+=tick
        else
          res<<[:tick,tick]
        end
      when "~"
        res<<[:tick,tbase] if res[-1][0]==:e
      # add vibrato data
      when "w"
        lasttick=0
        lasttick=res[-1][1] if res[-1][0]==:tick
        res<<[:tick,tbase] if res[-1][0]==:e
        m="m"
        d=innerdata(m,["100_start#{lasttick}_vibrato"])
        res.insert(-3,[:modifier,"(A:#{d})"])
      when /^\([VGABLN]:[^)]+/
        res<<[:modifier,i]
      else
        res<<[:e,i]
      end
    }
    line=""
    frest=0
    (res.size-1).times{|i|
      next if res[i][0]!=:modifier
      next if res[i+1][0]!=:tick
      # if tick after modifier, it must be by tie mark
      n=i-1
      n-=1 while res[n][0]!=:tick
      res[n][1]+=res[i+1][1]
      res[i+1][0]=:omit
    }
    res.each{|mark,data|
      case mark
      when :e , :modifier
        line<<data
      when :tick
        tick=data.to_i
        frest+=data-tick
        (tick+=frest;puts "frest:#{frest}" if $DEBUG && $debuglevel>1;frest=0) if frest>1
        line<<"*#{tick}"
      when :omit
        puts "# shift tick data by tie part" if $DEBUG
      else
        STDERR.puts "tie?"
      end
    }
    p res,line if $DEBUG && $debuglevel>1
    line
  end
  def self.makefraze mmldata,tc
    return "" if not mmldata
    self.trackPrepare(tc)
    p [:beforeTie,mmldata] if $DEBUG
    mmldata=self.tie(mmldata,@tbase,@swingHash)
    p [:afterTie,mmldata] if $DEBUG
    @systemWait=120
    @h=[]
    wait=[]
    lastwait=[]
    @frest=0
    @frestc=0
    @nowtime=0
    @shiftbase=40
    accent=false
    sharp=0
    sharpFloat=0
    @h<<[:panpot,@panoftrack] if @autopan
    cmd=mmldata.scan(/#{MmlReg.trackr}|./)
    cmd<<" " # dummy
    p "track hex; start making: ",cmd if $DEBUG
    cmd.each{|i|
      if wait.size>0
        t=@tbase
        i=~/^(\*)?([[:digit:]]+(\.[[:digit:]]+)?)(_([[:digit:]]+)j,)?/
        tickmode=$1
        swing=$5
        t=$2.to_f if $&
        if $&
          if tickmode
            puts "tick: #{t}" if $DEBUG && $debuglevel>1
          else
            t*=@tbase
          end
          @frest+=(t-t.to_i)
          t=t.to_i
          if @frest>=1
            t+=@frest.to_i
            @frest=@frest-@frest.to_i
            @frestc+=1
          end
        end
        wait.each{|m,c|
          arg=[c,t,accent,sharp,swing]
          arg2=[c,t,accent,sharp,sharpFloat,swing]
          case m
          when :percussion
            @h<<[:percussionNote,*arg]
          when :rawsound
            @h<<[:byKey,*arg]
          when :noteExpression
            @h<<[:noteExpression,*arg2]
          when :tne
            @h<<[:tne,*arg2]
          when :sound
            @h<<[:notes,*arg2]
          when :dummyNote
            @h<<[:dummyNote,*arg]
          when :chord
            @h<<[:chord,*arg]
          when :chordName
            @h<<[:chordName,*arg]
          when :rest
            @h<<[:rest,t,swing]
          end
        }
        lastwait=wait
        wait=[]
        accent=false
        sharp=0
        sharpFloat=0
      end
      case i
      when /^\(([-+]*)([[:digit:]\.]+)?\)/
        s1,s2=$1,$2
        n=1
        sharpFloat=0
        if s2
          n=s2.to_i
          if s2=~/\./
            sharpFloat=s2.to_f-n
          end
        end
        if s1.size>1
          n=s1.size
        end
        plus=s1 ? s1[0..0] : "+"
        sharpFloat*=-1 if plus=="-"
        sharp="#{plus}#{n}".to_i
      when /^\(key:(-?)\+?([[:digit:].]+)\)/
        num=$2
        tr=num.to_i
        tr=num.to_f if num=~/\./
        tr*=-1 if $1=="-"
        @h<<[:basekeyPlus,tr]
      when MmlReg.rr([:register])
        i=~/[[:digit:]]+/
        @h<<[:call,:register,$&]
      when /^\(tonality:(.*)\)/
        @h<<[:call,:setTonality,$1]
      when /^\(set":(.*)\)/
        d=$1.split(",")
        @h<<[:call,:setRegister,*d]
      when /^\(setSwing:(.*)\)/
        d=$1.split(",")
        @h<<[:call,:setSwing,*d]
      when /^\(broken:(.*)\)/
        @h<<[:call,:broken,$1]
      when /^\(tne:(.*)\)/
        wait<<[:tne,$1]
      when /^\(([[:alpha:]\-\+]+),([^,]*)\)/
        v="#{$1},#{$2}"
        wait<<[:noteExpression,v]
      when /^\(lg:(.*)\)/
        @h<<[:call,:setlenforgate,$1]
      when /^\(expressionRest:(.*)\)/
        @h<<[:call,:setExpressionRest,$1]
      when /^\(theremin:(.*)\)/
        if $1=~/off/
          @h<<[:setTheremin,false]
        else
          @h<<[:setTheremin,true]
        end
      when /^\(mark:(.*)\)/
        @h<<[:setmark,$1]
      when /^\(V:(.*)\)/
        vs=$1.split(",")
        @h<<[:call,:preVelocity,vs]
      when /^\(N:(.*)\)/
        s=$1.split(",")
        @h<<[:call,:preNote,s]
      when /^\(L:(.*)\)/
        s=$1.split(",")
        @h<<[:call,:preLength,s]
      when /^\(G:(.*)\)/
        gs=$1.split(",")
        @h<<[:call,:preGate,gs]
      when /^\(A:(.*)\)/
        s=$1.split(",")
        if @h.lastIsPreAfter
          s=mergeValues(s,@h.last[2])
          @h[-1]=[:call,:preAfter,s]
        else
          @h<<[:call,:preAfter,s]
        end
      when /^\(B:(.*)\)/
        s=$1.split(",")
        @h<<[:call,:preBefore,s]
      when /^\(roll:(.*)\)/
        @shiftbase=$1.to_i
      when /^\(vibratoType:(.*)\)/
        @h<<[:call,:vibratoType,$1]
      when /^\(vibrato:(.*)\)/
        v=$1
        @h<<[:setFloat,:vibratoRate,v]
      when /^\(setFloat:(.*)\)/
        name,v=$1.split(",")
        @h<<[:setFloat,name,v]
      when /^\(setInt:(.*)\)/
        name,v=$1.split(",")
        @h<<[:setInt,name,v]
      when /^\(dumpVar:(.*)\)/
        @h<<[:call,:dumpVar,$1]
      when /^\(oct(ave)?:(.*)\)/
        oct=($2.to_i+2)*12
        @h<<[:call,:basekeySet,oct]
      when /^\(key:reset\)/
        @h<<[:call,:basekeyReset]
      when /^\(p:(([[:digit:]]+),)?(([[:digit:]]+)|([\?[:alnum:]]+)(,([[:digit:]]))?)\)/
        channel=$1 ? $2.to_i : false
        subNo=false
        if $5
          subNo=$7.to_i if $7
          instrument=self.programGet($5,subNo)
        else
          instrument=$4.to_i
        end
        @h<<[:ProgramChange,channel,instrument]
      when /^\(bend:(([[:digit:]]+),)?([-+,.[:digit:]]+)\)|^_b__([^?]+)\?/
        i="(bend:#{$4.gsub('_'){','}})" if $4
        x,pos,start,b=worddata("bend",i)
        npos=start
        b.each{|depth|
          @h<<[:bend,npos,depth]
          npos=pos
        }
      when /^\(bendCent:([^\)]*)\)/
        $1=~/on/i
        on=$& ? true : false
        @h<<[:call,:bendCent,on]
      when /^\(bendRange:([^\)]*)\)/
        @h<<[:bendRange,$1]
      when /^&\((.+)\)/
        raw=rawHexPart($1)
        @h<<[:raw,raw]
      when /^:([^\(,]+(\([^\)]+\))?),/
        wait<<[:chordName,$1]
      when /^_(([[:digit:]]+)|([[:alnum:]]+))!/
        if $2
          perc=$2.to_i
        else
          perc=self.percussionGet($3)
        end
        wait<<[:percussion,perc]
      when /^\(vFuzzy:([0-9]+)\)/
        @h<<[:velocityFuzzy,$1.to_i]
      when /^\(v:([0-9]+)\)/, /^v([0-9]+)/
        @h<<[:velocity,$1.to_i]
      when /^\(g(ate)?:([0-9]+)\)/
        g=$2.to_i
        @h<<[:call,:setGateRate,g]
      when /^\(volume:(.*)\)/
        @h<<[:masterVolume,$1.to_i]
      when /^\(tempo:reset\)/
        @h<<[:tempo,@bpmStart]
      when /^\(ch:(.*)\)/
        ch=$1.to_i
        ch=9 if $1=="drum"
        @h<<[:ch,ch]
      when /^\(cc:(.*)\)/
        @h<<[:controlChange,$1]
      when /^\(bs:(.*)\)/
        @h<<[:bankSelect,$1]
      when /^\(bspc:(.*)\)/
        @h<<[:bankSelectPC,$1]
      when /^\(gs:reset\)/
        @h<<[:GSreset,0]
        @h<<[:rest,@systemWait]
      when /^\(gm(2)?:on\)/
        gm=$1 ? 2 : 1
        @h<<[:GMsystemOn,0,gm]
        @h<<[:rest,@systemWait]
      when /^\(xg:on\)/
        @h<<[:XGsystemOn,0]
        @h<<[:rest,@systemWait]
      when /^\(syswait:\)/
        @h<<[:rest,@systemWait]
      when /^\(xgMasterTune:(.*)\)/
        @h<<[:xgMasterTune,$1]
      when /^\(pan:(<|>)?(.*)\)/
        pan=$2.to_i
        case $1
        when ">"
          pan=64+pan
        when "<"
          pan=64-pan
        else
        end
        @h<<[:panpot,pan]
      when /^\(wait:(\*)?(.*)\)/
        @h<<[:waitingtime,$1? $2.to_i : $2.to_f*@tbase]
      when /^\(accent:([^)]*)\)/
        @h<<[:call,:accent,$1]
      when /^\(track:(.*)\)/
        i=$1
        @h<<[:call,:trackName,i]
      when /^\(on:(.*)\)/
        i=$1
        @h<<[:soundOn,i]
      when /^\(off:(.*)\)/
        @h<<[:soundOff,$1]
      when /^\(s(cale)?:(.*)\)/
        @h<<[:call,:scale,$2]
      when /^\(gtune:(.*)\)/
        @h<<[:call,:gtuning,$1]
      when /^\(chordcenter:(.*)\)/
        @h<<[:call,:chordCenter,$1]
      when /^\(stroke:(.*)\)/
        @h<<[:call,:strokeSpeed,$1]
      when /^\((chord|C):(.*)\)/
        chord=$2.split.join.split(",") # .map{|i|self.note2key(i)}
        wait<<[:chord,chord]
      when /^\(text:(.*)\)/
        @h<<[:metaText,$1]
      when /^\(tempo:(.*)\)/
        @bpm=$1.to_i
        @h<<[:tempo,@bpm] if @bpm>0
      # limited random note
      when /^\(\?:(.*)\)/
        ks=$1
        if ks=~/\-/
          ks=[*($`.to_i)..($'.to_i)]
          key=ks[rand(ks.size)]
          wait<<[:rawsound,key]
        else
          ks=ks.split(",")
          key=ks[rand(ks.size)]
          a=:sound
          if key=~/\A[[:digit:]]+\z/
            a=:rawsound
            key=key.to_i
          end
          wait<<[a,key]
        end
      when /^\(x:(.*)\)/
        key=$1.to_i
        wait<<[:rawsound,key]
      when /^<(.*)/
        rate=1.25
        if $1.size>0
          rate=$1.to_i/100.0
        end
        @bpm=@bpm/rate
        @h<<[:tempo,@bpm]
      when /^>(.*)/
        rate=1.25
        if $1.size>0
          rate=$1.to_i/100.0
        end
        @bpm=@bpm*rate
        @h<<[:tempo,@bpm]
      when /^([-+])([[:digit:]]+)?/
        plus=$1
        num=$2 ? $2.to_i : 1
        @h<<[:call,:basekeySet,plus,num]
      when /^\*?[0-9]+/
        # (i.to_i-1).times{@h<<@h[-1]}
      when "`"
        @h<<[:ahead,-@shiftbase]
      when "'"
        @h<<[:ahead,@shiftbase]
      when "^"
        p "accent" if $DEBUG
        accent=true
      when "="
        last=@h[-1]
        @h<<[:comment,"= same sound"]
        if lastwait.size>0
          wait+=lastwait
        else
          @h<<last
        end
      when "r"
        wait<<[:rest,i]
      when "o","O"
        wait<<[:dummyNote,i]
      when " "
      when "?"
        wait<<[:dummyNote,"?"]
      when "m"
        @h<<[:call,:resetRand]
        wait<<[:chord,["??"]]
      when "M"
        @h<<[:call,:resetRand]
        wait<<[:chord,["?O"]]
      else
        if @notes.keys.member?(i)
          wait<<[:sound,i]
        else
          STDERR.puts "[#{i}] undefined note?" # if $DEBUG
        end
      end
    }
    p @h if $DEBUG
    puts "float rest add times: #{@frestc}" if $DEBUG
    @h=self.eventlist2str(@h)
    p [:number_with_totaltime, Event.new(:dummy).showTotalTime],[:allevent,@eventlist.map{|i|i.display}] if $DEBUG && $debuglevel>2
    @h
  end
  def self.eventArray2str data,tc
    data.map{|i|
      case i
      when String
        i
      when Event
        i.data
      end
    }*"\n# track: #{tc} ==== \n"
  end
  def self.loadMap file, base=0
    if not File.exist?(file)
      map=false
    else
      category=""
     li=File.readlines(file).map{|i|
          i=i.toutf8
          # zero base
          # category name plus
          if i=~/^[[:digit:]]+/
            [i.split[0].to_i-base,"#{i.chomp.toutf8} #{category}"]
          else
            category=i.chomp.toutf8 if i.chomp.size>0
            false
          end
        }-[false]
      map=li.size>0 ? li : false
    end
  end
  def self.loadProgramChange file
    if not File.exist?(file)
      @programList=false
    else
      @programList=self.loadMap(file,1)
    end
  end
  def self.testGs cycle,key,scaleAll,intro,mapnum=3
    d=@programList.select{|i,v|v=~/#{key}/i}.map{|i,data|
      [mapnum].map{|lsb|
        msbs=[0,8,16,24,32]
        msbs=[0] if i>63
        msbs=[*0..5] if i>121
        msbs.map{|msb|
          #msb*=8
          "(bspc:#{msb},#{lsb},#{i},4) #{cycle}"
        }*""
      }*""
    }*""
    scale=scaleAll # mapnum<4 ? [*25..87].map{|i|"(x:#{i})"}*"" : scaleAll
    lsb=mapnum
    ps=[1,2,3,9,10,11,12,17,25,26,27,28,29,30,31,33,41,49,50,51,53,54,57,58,59,128].map{|i|i-1}
    perc=ps.map{|p|
      [0,8,16,24,25,32,40,48,56,127].map{|msb|
        "(bspc:#{msb},#{lsb},#{p},4) #{intro} #{scale}"
      }*""
    }*""
    d="(gs:reset)r14 "+d+"(ch:9)"+perc
  end
  def self.test cycle,mode=1
    cycle="cdef" if ! cycle
    key=$test
    p key
    inGM=[*35..81]
    outGM=[*0..127]-inGM
    # make sounds outside GM map shorter
    scaleAll=(inGM.map{|i|"(x:#{i})"}+outGM.map{|i|"(x:#{i})0.2"})*""
    s,k,h,l,o,c,cc=@gmSnare,@gmKick,@gmHiTom,@gmLoTom,@gmOpenH,@gmCloseH,@gmCrashCym
    intro="(x:#{k})0.2(x:#{cc})0.8(x:#{k})(x:#{s})(x:#{s})(x:#{c})(x:#{c})(x:#{o})(x:#{c})
        v64(x:#{h})0.68(x:#{l})0.66(x:#{l})0.66
        v42(x:#{o})0.34v32(x:#{c})0.33(x:#{c})0.33 v20(x:#{o})0.12(x:#{c})0.11(x:#{c})0.11v92(x:#{o})0.66v64"
    mode=1 if ! mode
    @data=(
      case mode
      when 1 || "gm"
        d=@programList.select{|i,v|v=~/#{key}/i}.map{|i,data|"(p:#{i})#{cycle}"}*""
        perc=scaleAll
        "(gm:on)r14 "+d+"(ch:9)"+intro+perc
      when 2 || "xg"
        d=@programList.select{|i,v|v=~/#{key}/i}.map{|i,data|
          [0,1,18,32,33,34,40,41,45,64,65,70,71,97,98].map{|lsb|
            [0].map{|msb|
              #msb*=8
              "(bspc:#{msb},#{lsb},#{i},4) #{cycle}"
            }*""
          }*""
        }*""
        lsb=0
        msb=127
        perc0=[0].map{|p| "(bspc:#{msb},#{lsb},#{p},4) #{scaleAll}"}*""
        scale=([*28..79]-[51,52,54,55,58,60,61,65,66,67,68,69,71,72,73,74]).map{|i|"(x:#{i})"}*"" # main unique sound maybe
        perc=[*1..48].map{|p| "(bspc:#{msb},#{lsb},#{p},4) #{intro} #{scaleAll}"}*""
        msb=126
        scale=([*36..42]+[*52..62]+[*68..73]+[*84..91]).map{|i|"(x:#{i})"}*""
        perc2=[*0..1].map{|p| "(bspc:#{msb},#{lsb},#{p},4) #{intro} #{scale}"}*""
        d="(xg:on)r14 "+d+"(ch:9)"+perc+perc2+perc0
      when 3 || "gs"
        mapnum=3 # 0(gm),1(sc-55),2(sc-88),3(sc-88pro),4(sc-8850)
        self.testGs(cycle,key,scaleAll,intro,mapnum)
      else
      end
    )
  end
  def self.loadPercussionMap file
    @snare=35
    @gmSnare,@gmKick,@gmHiTom,@gmLoTom,@gmOpenH,@gmCloseH,@gmCrashCym=38,35,50,45,46,42,49
    @gmKit={}
    @gmKit["s"],@gmKit["k"],@gmKit["h"],@gmKit["l"],@gmKit["o"],@gmKit["c"],@gmKit["cc"]=@gmSnare,@gmKick,@gmHiTom,@gmLoTom,@gmOpenH,@gmCloseH,@gmCrashCym
    if not File.exist?(file)
      @percussionList=false
    else
      @percussionList=self.loadMap(file,0)
      @snare=self.percussionGet("snare")
    end
  end
  # substitute mark comment lines with shift delta time and dummy event hex data to adjust to most preceding track.
  def self.trackMake data,tc
    @marksh||=@marktrack.calc
    data=self.eventArray2str(data,tc).split("\n").map{|i|
      i=~/^# marktrack\(([^\)]+)\)/
      if $&
        key=$1
        pos=@marksh[key]
        c="position mark: #{key}, #{pos*1.0/@tbase}"
        @marksh.keys.member?(key) ? self.dummyEvent(c,pos).data : i
      else
        i
      end
    }*"\n"
    start="
# track header
      4D 54 72 6B # MTrk
    "
    dsize=trackSizeHex(data,@cmark)
    trackend="
      00 FF 2F 00 # end of track
    "
    [start,dsize,data,trackend]
  end
  def self.dumpHex
    @h
  end
end
def multiplet d,tbase
  d=~/\/((\*)?([[:digit:].]+)?:)?(.*)\//
  tickmode=$2
  i=$4
  rate=$3 ? $3.to_f : 1
  rate=1 if rate==0
  if tickmode
    total=$3.to_i
  else
    total=tbase*rate
  end
  regex=MmlReg.multipletr
  r=i.scan(/#{regex}|./)
  lengths=[]
  notes=[]
  mod=[]
  r.each{|i|
    case i
    # modifier
    when /^[-+]+[[:digit:]]*/,/^[\^`',<>]/,/^\([-+]*[[:digit:]]?\)/,MmlReg.rr([:register])
      mod<<i
    # note
    when /^\((\?|x|C|chord|tne):[^\)]+\)|^\^?:[^,]+,|^=|\([[:alpha:]\\-\\+]+,[^,]*\)/
      lengths<<1
      notes<<"#{mod*""}#{i}"
      mod=[]
    # length swing
    when /^([[:digit:]]+),/
      n=$1.to_i
      s=n.to_myl
      s+=MyLength.new(0,"#{n}j,")
      lengths[-1]*=s
    # length
    when /^[[:digit:]]+/
      lengths[-1]*=i.to_f
    when " "
    when /^\([^\(\):,]*:.*\)/
      mod<<i
    else
      lengths<<1.to_myl
      notes<<"#{mod*""}#{i}"
      mod=[]
    end
  }
  p [:multipletle,lengths] if $DEBUG
  sum=lengths.inject{|s,i|s+i}
  ls=lengths.map{|i|(i*1.0/sum*total).round} # .map{|i|i.round(dep)}
  er=(total-ls.inject{|s,i|s+i}).to_i
  if er>0
    er.times{|i|
      ls[i]+=1
    }
  else
    (-er).times{|i|
      ls[-1-i]-=1
    }
  end
  er=(total-ls.inject{|s,i|s+i})
  ls[-1]+=er
  result=[]
  notes.size.times{|i|
    result<<notes[i]
    result<<"*#{ls[i]}"
  }
  # rest of mod
  result+=mod
  p "multiplet: ",total,ls.inject{|s,i|s+i} if $DEBUG && $debuglevel>1
  result*""
end

def funcApply m,name,x
  a=m.keys.select{|k|k=~/^#{name}\(/}[0]
  fbodyOrg,*default=m[a]
  return false if ! fbodyOrg
  x=~/(([^:]*):)?/
  interval,x=$2,$'
  x=x.split(",")
  max=x.size
  x+=default
  a=~/\((.*)\)/
  args=$1.split(',').map{|k|"$#{k}"}
  n=0
  # p "x,args,mac:",x,args,fbody
  r=[]
  max.times{|i|
    fbody=fbodyOrg
    args.each{|k|
      fbody=fbody.gsub(k){x[n]}
      n+=1
    }
    r<<fbody
  }
  sep=""
  sep="(wait:#{interval})" if interval && interval.size>0
  r*sep
end
def macroDef data
  macro={}
  mline=false
  tmp=[]
  name=""
  num=1
  rstr=MmlReg.macroDefr
  s=data.scan(/#{rstr}| *\) *;|[^;]+|./)
  data=s.map{|i|
    case i
    when /^(macro +)? *([^ ;:=]+) *:= *\( *;/
      mline=true
      num=1
      name=$2
      tmp=[]
      ""
    when /^(macro +)? *([^ ;:=]+) *:=([^;]+)/
      r=$3
      key=$2
      chord=/([^$]|^)\{([^\{\}]*)\}/
      r.gsub!(chord){"#{$1}(C:#{$2})"} while r=~chord
      macro[key]=modifierComp(r,macro)
      ""
    when / *\) *;/
      mline=false
      name=""
    when ";",/^ *$/
      i
    else
      if mline
        key="#{name}[#{num}]"
        macro[key]=i
        num+=1
        ""
      else
        i
      end
    end
  }*""
  [macro,data]
end
def nestsearch d,macro
  a=d.scan(/\[[^\[\]]*\] *[[:digit:]]+/)!=[]
  r=d.scan(/\/[^\/]+\/|#{MmlReg.repeatr}|\$\{[^ \{\}]+\}|\$[^ ;\$*_^`'+-]+|;|./).map{|i|
    case i
    when /^\$\{([^\}]+)\}/
      $1
    when /^\$/
      $'
    when /\/[^\/]+\//
      true
    else
      ""
    end
  }
  b=(macro.keys-r).size<macro.keys.size
  c=r.member?(true)
  chord=false
  d=~/([^$]|^)\{([^\}]*)\}/
  chord=true if $&
  p "nest? #{a} #{b} #{c} #{chord}",r,macro if $DEBUG
  a||b||c||chord
end

# repeat block analysis: no relation with MIDI format
# '(:..)' => '(lastcmd:..)'
def repCalc line,macro,tbase
  rpt=/\[([^\[\]]*)\] *([[:digit:]]+)/
  line.gsub!(rpt){
    data,rep=$1,$2.to_i
    r=""
    rep.times{|i|
      r<<data.gsub(/_REPEAT_([-\*\+[:digit:]]*)/){eval("#{i+1}#{$1}")}
    }
    r
  } while line=~rpt
  chord=/([^$]|^)\{([^\{\}]*)\}/
  line.gsub!(chord){"#{$1}(C:#{$2})"} while line=~chord
  line=line.scan(/(\.\$)|(\$([[:alnum:]]+)\(([^\)]+)\))|(.)/).map{|a,b,bname,barg,c|
    if a
      a 
    elsif c
      c
    else
      r=funcApply(macro,bname,barg)
      r ? r : b
    end
  }*""
  repmark=MmlReg.repeatr
  regex=/\/[^\/]+\/|#{repmark}|\$\{[^ \{\}]+\}|\$[^ ;\$_*^,\)\(`'\/+-]+|\([^\)]*:|\)|./
  a=line.scan(regex)
  a=a.map{|i|
    if i=~/^\/[^\/]+\//
      if i=~/\$/
        i=i.gsub(/\$\{([^ ;\$_*^,\)\(`'\/+-]+)\}/){macro[$1]}.gsub(/\$([^ ;\$_*^,\)\(`'\/+-]+)/){macro[$1]}
      end
      multiplet(i,tbase).scan(regex)
    else
      i
    end
  }.flatten
  hs={}
  a.each_with_index{|d,i|hs[i]=d}
  hs=hs.invert
  res=[]
  done=[]
  dsflag=dcflag=false
  counter=0
  repcount=0
  pointDS=0
  rep=[]
  while true
    countertmp=counter
    counter+=1 # next
    current=a[countertmp]
    puts "#{countertmp}: #{current}, #{rep},done: #{done*","}" if $DEBUG
    break if ! current
    case current
    when "["
      if ! done.member?(countertmp)
        repcount+=1
        rep<<countertmp
        done<<countertmp
      end
    when "]"
      if ! done.member?(countertmp)
        done<<countertmp
        counter=rep.shift+1
      end
    when ".DS"
      counter=pointDS
      dsflag=true
    when ".DC"
      counter=0
      dsflag=true
    when ".SKIP"
      if done.member?(countertmp)
         counter=done[-1]
      else
        done<<countertmp
      end
    when ".toCODA"
      if dsflag
        counter=hs[".CODA"]
      end
    when ".FINE"
      if (dsflag || dcflag)
        break
      end
    when /^\$\{([^ \{\}]+)\}/
      current=macro[$1]
    when /^\$([^ ;]+)/
      current=macro[$1]
    when ".$"
      pointDS=countertmp
    when ";"
      current=""
    when /^\(([^\)]+):$/
      lastcmd=$1 if $1 != "C"
    when "(:"
      current="(#{lastcmd}:"
    else
      current
    end
    res<<current
  end
  res=(res-MmlReg::RepStrArray)*""
  res=repCalc(res,macro,tbase) while macro.keys.size>0 && nestsearch(res,macro)
  p res if $DEBUG && $debuglevel>1
  # 空白
  res=res.split.join 
  res
end
def loadCalc d
  if d=~/\(loadf:(.+)(,(.+))?\)/
    file=$1
    num=$3 ? $3.to_i : false
    [:raw,MidiRead.readtrack(file,num)]
  else
    [:seq,d]
  end
end
def modifierComp t,macro
  rawHexPart(t,macro).scan(/\([VGABLN]:[^)]+\)|./).map{|i|
    case i
    when /^\((V|G):([^)]+)\)/
      mode=$1
      n=0
      v=$2.split(/,/).map{|i|i.split(/ +/)-[""]}.map{|i|
        i=["o"] if i==[]
        i.map{|c|
          c=c.split('') if c=~/^[-\+o]+$/
          c
        }
      }
      "(#{mode}:#{v*","})"
    when /^\((A|B|L|N):([^)]+)\)/
      mode=$1
      n=0
      v=$2.split(/,/).map{|i|i.split(/ +/)-[""]}.map{|i|
        i=["o"] if i==[]
        i.map{|c|
          c=c.split('') if c=~/^o+$/
          c
        }
      }
      "(#{mode}:#{v*","})"
    else
      i
    end
  }*""
end

class Smml
  attr_accessor :tracknum, :tbase, :rundatas, :rawdatas, :mx
  attr_accessor :bpm, :velocity, :octave, :vfuzzy, :data, :infile, :outfile, :autopan
  def initialize tbase=480,pagesep='///',expfile=false,cmark=';;'
    @tracksep='|||'
    String.new.setcmark(cmark)
    String.new.setpagesep(pagesep)
    String.new.settracksep(@tracksep)
    @mx=MidiHex
    @rundatas=[]
    @rawdatas=[]
    @macro={}
    @tbase=tbase
    @tracks=[]
    @fuzzymode=false
    @fuzz=false
    @expfile=expfile
    @pagesep=pagesep
    @bpm=120
    @velocity=0x40
    @octave=:near
    @vfuzzy=2
    @autopan=true
    @strictmode=false
  end
  def strict
    @autopan=false
    @vfuzzy=0
    @strictmode=true
  end
  def self.syntax
    hintminimum
  end
  def pmap
    puts @mx.programList
  end
  def dmap
    puts @mx.percussionList
  end
  def psearch k
    puts @mx.programList.select{|i|i=~/#{k}/i}
  end
  def dsearch k
    puts @mx.percussionList.select{|i|i=~/#{k}/i}
  end
  def init test,fz
    @mx.prepare(@bpm,@tbase,@velocity,@octave,@vfuzzy,@strictmode)
    @mx.setfile(@infile)
    @mx.setmidiname(@outfile) if @outfile
    @mx.setdata(@data) if ! @mx.getdata
    (hintminimum;exit) if (! @mx.getdata || ! @mx.getmidiname ) && ! test
    settest if test
    @tracks=@mx.getdata.tracksep
    showtracks if $DEBUG && $debuglevel>1
    fuzzy(fz)
  end
  def settest
    @mx.test($testdata,$testmode)
  end
  def fuzzy fz
    @fuzzymode=fz
    @fuzz=unirand(fz,@tracks.size) if fz
    if fz && (@tbase/fz<8)
      STDERR.puts "really?#{"?"*(8*fz/@tbase)}"
    end
  end
  def showtracks
    p @tracks
  end
  def setmacro
    @tracks.map{|track|
      m,track=macroDef(track)
      @macro.merge!(m)
      track=modifierComp(track,@macro)
      repCalc(track,@macro,tbase)
    }.each{|t|
      r=loadCalc(t)
      if @fuzzymode
        n=@fuzz.shift
        STDERR.puts "track shift: #{n} tick#{n>1 ? 's' : ''}"
        pre="r*#{n} "
      else
        pre=""
      end
      case r[0]
      when :raw
        @rawdatas<<r[1]
      when :seq
        @rundatas<<pre+r[1]
      end
    }
    p @macro if$DEBUG
    @rawdatas.flatten!
    open(@expfile,"w"){|f|f.puts @rundatas*@tracksep} if @expfile
    @tracknum=@rawdatas.size+@rundatas.size
    @tracknum=@tracks.size
  end
  def settracks
    @htracks=[]
    tcall=@rundatas.size
    @mx.autopanset(tcall)
    @mx.autopan(@autopan)
    tc=0
    # remember starting position check if data exist before sound
    @htracks[tc]=[]
    @htracks[tc]=[@mx.metaTitle, @mx.generaterText, @mx.starttempo, @mx.makefraze(@rundatas[0],tc), @mx.lastrest].flatten
    @rundatas[1..-1].each{|track|
      tc+=1
      @htracks[tc]=[]
      @htracks[tc]=[@mx.restHex,@mx.makefraze(track,tc), @mx.lastrest].flatten
    }
  end
  def pack
    @header=@mx.header(1, @tracknum, @tbase)
    tc=0
    alla=[@header]+@htracks.map{|t|
      tc+=1
      @mx.trackMake(t,tc-1)
    }.flatten
    puts alla if $DEBUG
    all=alla.map{|i|i.commentoff("","#")}*""
    array=[all.split.join]
    @binary = array.pack( "H*" )
  end
  def make test=false,fz=false
    init(test,fz)
    setmacro
    settracks
    pack
  end
  def save outfile=@mx.getmidiname
    # save data. data = MIDI-header + seq-made MIDI-tracks + loaded extra MIDI-tracks.
    if outfile==""
      print @binary
      @rawdatas.each{|i|
        print i
      }
    else
      open(outfile,"wb"){|f|
        f.write @binary
        @rawdatas.each{|i|
          f.write i
        }
      }
    end
  end
  def compile infile,outfile='out.mid',data=""
    @infile=infile
    @outfile=outfile
    @data=data
    make
    save
  end
end

module Mml
def self.calclen len,digdef,last
  if last == :sound
    htn=0
    if len=~/\.+/
      len=$`.to_i
      len=digdef if len==0
      htn=$&.size
    end
    len=4.0/len.to_i
    baselen=len/2.0
    htn.times{len+=baselen;baselen/=2.0}
    len=len.round if len==len.round
    len="" if len==1
  end
  len
end
def self.tosmml data
  tracks={}
  tr=0
  last=:no
  lines=data.split("\n")
  lines.each{|mml|
    octave=3
    digdef=4
    mml.scan(/([[:alpha:]]):|([[:alpha:]<>])([#\+\-])?([[:digit:]\.]+)?|@([[:alpha:]]+|[[:digit:]]+)|([[:digit:]\.]+)|([\[\]])| |/).each{|tname,al,sharp,dig,sname,dig2,same|
      valueAr=[tname,al,sharp,dig,sname,dig2,same]
      value=valueAr*""
      (tr=tname;next) if tname
      len=dig|| digdef
      len=calclen(len,digdef,:sound)
      dig2=calclen(dig2,digdef,last) if dig2
      last=:no
      v=""
      case al ? al.upcase : al
      when ">"
        octave+=1
        v="+"
        p "oct= #{octave} : #{v}"
      when "<"
        octave-=1
        v="-"
        p "oct= #{octave} : #{v}"
      when "L"
        digdef=dig
        p "defaault length : #{dig}"
      when "O"
        v="(oct:#{dig})"
        p "octave #{dig} : #{v}"
      when "Q"
        v="(gate:#{dig})"
        p "gate #{dig} : #{v}"
      when "P"
        v="(pan:#{dig})"
        p "pan #{dig} : #{v}"
      when "N"
        v="{#{dig}}"
        p "note #{dig}  : #{v}"
      when "T"
        v="(tempo:#{dig})"
        p "tempo #{dig} : #{v}"
      when "V"
        v="(v:#{dig})"
        p "velocity #{dig} : #{v}"
      when "R"
        v="r#{len}"
        p "rest  #{len} : #{v}"
        last=:sound
      when nil
        if sname
          v="(p:#{sname})"
          p "sound name #{sname} : #{v}"
        elsif same
          v=same
          p "same : #{v}"
        end
      when "A".."G"
        note=al.downcase
        case sharp
        when "#","+"
          note=note.upcase
        when "-"
          note="(-)"+note
        end
        v="#{note}#{len}"
        p "note #{al} #{sharp}  #{len} : #{v}"
        last=:sound
      end
      v="#{dig2}" if dig2
      STDERR.puts "[#{value}] undefined?" if v=="" && value.size>0
      if tracks[tr]
        tracks[tr]<<v
      else
        tracks[tr]=v
      end
    }
  }
  tracks.keys.sort.map{|k|tracks[k]}*"\n|||\n"
end
end
