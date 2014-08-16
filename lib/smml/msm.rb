#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'

def hint
  cmd=File.basename($0)
  puts <<EOF
usage: #{cmd} -d \"dddd dr3 dddd r4 drdrdrdr dddd dr3\" -o outfile.mid -t bpm
       #{cmd} -i infile.txt  -o outfile.mid -t bpm

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
    (mark:posname) =position name for adjustment of tracks after long rest etc.
    .DC .DS .toCODA .CODA .FINE =coda mark etc.
    .SKIP =skip mark on over second time
    .$ =DS point
    _snare! =percussion sound ( search word like 'snare' (can use tone number) from percussion list if exist )
        similarly, _s!=snare, k:bassKick, o:openHighHat, c:closedHighHat, cc:CrachCymbal, h:highTom, l:lowTom as default.
        map text personaly you set must start with tone number.
    (loadf:filename.mid,2) =load filename.mid, track 2. Track must be this only and seperated by '|||'.
    W:=abc        =macro definition. One Charactor macro can be used. use prefix '$' for refering.
    macro W:=abc  =macro definition.
    fn(x):=ab$x    =macro with args. in this case, '$fn(10)' is substituded by 'ab10'. similarly,
                  '$fn(:10,20,30)' = 'ab10ab20ab30'.
                  '$fn(4:10,20,30)' = 'ab10(wait:4)ab20(wait:4)ab30'.
    compile order is : page,track seperate => macro set and replace => repeat check => sound data make
    ; =seperater. same to a new line
    blank =ignored
    ;; comment =ignored after ';;' of each line
    ;;;;;;     =start mark of multi-line comment. end mark is same or longer mark of ';;'. these must start from the top of line.

    basicaly, one sound is a tone command followed by length number. now, tone type commands are :
      'c',  '{64}', '_snare!', '{d,g,-b}', ':cmaj7,'
    and other commands are with parentheses.
EOF
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
class String
  def setcmark c
    @@cmark=c
  end
  def cmark
    @@cmark
  end
  def trim ofs="",com=@@cmark
    lines=self.split("\n")
    d=multilineTrim(lines,com)
    d=d.map{|i|i.sub(/(#{com}).*/){}.chomp}*ofs
    d
  end
  def sharp2cmark
    self.gsub!("#"){@@cmark}
  end
  def tracks pspl
    tracks={}
    pages=self.split(/#{pspl}+/)
    pages.each{|p|
      p.split('|||').each_with_index{|t,i|
        if tracks[i]
          tracks[i] << t
        else
          tracks[i] = [t]
        end
      }
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
end
def unirand n,c,reset=false
  a=[0,n]
  while c>a.size
    t=rand(n-2)+1
    a<<t if ! a.member?(t)
  end
  a.sort_by{rand}
end

class Event
  attr_accessor :type, :time, :value
  def initialize ty=:e,*arg
    @type=ty
    @pos=0
    @value=""
    case @type
    when :c,:raw
      @time=0
      @value=arg[0]
    when :ahead
      @time=arg[0]
    when :o,:off
    when :mark
      @mark,@track,@value=arg
    else
      @time=arg[0]
      @value=arg[1]
    end
  end
  def data
    case @type
    when :raw
      rawdata(@value)
    when :mark
      "# marktrack(#{@track}_#{@mark}) [#{@value}]\n"
    when :c,:o,:off
      @value
    else
      varlenHex(@time)+@value
    end
  end
end
# arg=[steps],[values]
def mymerge span,*arg
  r=[]
  arg.each{|ar|
    next if ! ar
    m,steps,vs=ar
    steps=[steps] if steps.class!=Array
    steps=steps*(vs.size-1) if steps.size==1
    r<<[0,m,vs[0]]
    if vs.size>1
      stepsum=steps.inject{|s,i|s+i}
      vsize=vs.size-1
      if stepsum>span
        rate=span*1.0/stepsum
        steps=steps.map{|i|(i*rate).to_i}
      end
      n=1
      r+=vs[1..-1].map{|i|
        t=steps.shift*n
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
  d=d.trim("",cmark).split.join
  i=(d.size+8)/2
#  p [d,i,i.to_s(16)]
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
  c=d.to_i+8192
  c=[[c,0].max,16383].min
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
def rawHexPart d,macro={}
  li=d.scan(/\$se\([^)]*\)|\$delta\([^)]*\)|\$bend\([^)]*\)|\(bend:[^)]*\)|\(expre:[^)]*\)|./)
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
      "_b__#{$1.split(',')*"_"}?"
    when /\(expre:([^)]*)\)/
      "_e__#{$1.split(',')*"_"}?"
    else
      i
    end
  }*""
end
def revertPre d
  d.gsub(/_b__([^?]*)\?/){"(bend:#{$1.split("_")*","})"}.
    gsub(/_e__([^?]*)\?/){"(expre:#{$1.split("_")*","})"}
end
def worddata word,d
  d=~/\(#{word}:(([[:digit:].]+),)?([-,.[:digit:]]+)\)/
  if $&
    pos=$1 ? $2.to_i : 0
    depth=$3.split(',').map{|i|i.to_f}
    [:"#{word}",pos,depth]
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
module MidiHex
  # 設定のため最初に呼ばなければならない
  def self.prepare bpm,tbase=480,vel=0x40,oct=:near,vfuzzy=2
    @startBpm=bpm
    @midiname=false
    @cmark="#"
    @marktrack=MarkTrack.new
    @octmode=oct
    @tbase=tbase
    @gateRate=100
    @nowtime=0
    @onlist=[]
    @waitingtime=0
    @rythmChannel=9
    @notes={
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
      "t"=>[0,@rythmChannel],
      "s"=>[3,@rythmChannel],
      "u"=>[6,@rythmChannel]
    }
    @ch=0
    @velocity=vel
    @velocityOrg=vel
    @velocityFuzzy=vfuzzy
    @accentPlus=10
    @basekey=0x3C
    @chordCenter=@chordCenterOrg=@basekey
    @basekeyRythm=@basekeyOrg=@basekey
    @bendrange=2
    @bendCent=1
    @prepareSet=[@tbase,@ch,@velocity,@velocityFuzzy,@basekey,@gateRate,@bendrange,@bendCent]
    @chmax=15
    @bendrangemax=127
    file="midi-programChange-list.txt"
    pfile="midi-percussion-map.txt"
    base=File.dirname(__FILE__)
    file=File.expand_path(file,base) if not File.exist?(file)
    pfile=File.expand_path(pfile,base) if not File.exist?(pfile)
    self.loadProgramChange(file)
    self.loadPercussionMap(pfile)
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
    @data=File.read(name).trim(" ;").toutf8 if name && File.exist?(name)
  end
  def self.getdata
    @data
  end
  def self.setdata d
    @data=d
  end
  def self.accent a
    @accentPlus=a.to_i
  end
  def self.setGateRate g
    @gateRate=[g,100].min
  end
  def self.bendRange v
    case v
    when /^\+/
      @bendrange+=$'.to_i
    when /^\-/
      @bendrange-=$'.to_i
    else
      @bendrange=v.to_i
    end
    @bendrange=[[@bendrange,@bendrangemax].min,0].max
    r=[]
    r<<self.controlChange("101,0")
    r<<self.controlChange("100,0")
    r<<self.controlChange("6,#{@bendrange}")
    r
  end
  def self.bendCent on
    @bendCent=1
    @bendCent=8192/@bendrange/100.0 if on
  end
  def self.trackPrepare tc=0
    @tbase,@ch,@velocity,@velocityFuzzy,@basekey,@gateRate,@bendrange,@bendCent=@prepareSet
    @strokespeed=0
    @preGate=[]
    @preVelocity=[]
    @preNote=[]
    @preLength=[]
    @preBefore=[]
    @preAfter=[]
    @tracknum=tc+1
    tc+=1 if tc>=9 # ch10 is drum kit channel
    tc=@chmax if tc>@chmax
    @ch=tc
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
      4D 54 68 64  # ヘッダ
      00 00 00 06  # データ長:6[byte]
      00 #{format} # フォーマット
      00 #{track}  # トラック数
      #{tbase}      # 1 拍の分解能 #{@tbase}
    "
  end
  def self.byGate len,g=@gateRate
    g=@preGate.shift if @preGate.size>0
    l=(len*1.0*g/100).to_i
    r=len-l
    [l,r]
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
    r=[Event.new(:o)]
    r<<Event.new(:e,start," 9#{ch} #{key} #{vel} # #{start}後, sound on only , note #{@key} velocity #{velocity}\n")
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
  def self.oneNote len=@tbase,key=@basekey,velocity=@velocity,ch=@ch,sharp=0
    velocity=@preVelocity.shift if @preVelocity.size>0
    gate=@gateRate
    ch=[ch,0x0f].min
    velocity-=rand(@velocityFuzzy) if @velocityFuzzy>0
    velocity=[velocity,0x7f].min
    key+=sharp
    @key=[[key,0x7f].min,0].max
    key=format("%02x",@key)
    ch=format("%01x",ch)
    vel=format("%02x",velocity)
    start=@waitingtime
    @waitingtime=0
    slen,rest=self.byGate(len,gate)
    @nowtime+=start
    r=[]
    r<<Event.new(:e,start," 9#{ch} #{key} #{vel} # #{start}後, soundオン note #{@key} velocity #{velocity}\n")
    b=@preAfter.shift
    bends=expre=false
    if b
      bends=worddata("bend",b)
      expre=worddata("expre",b)
      mymerge(slen,bends,expre).each{|t,m,d|
        case m
        when :bend
          r<<self.bend(t,d)
        when :expre
          r<<self.expre(t,d)
        when :rest
          slen=t
        end
      }
    end
    @nowtime+=slen
    r<<Event.new(:e,slen," 8#{ch} #{key} 00 # #{slen}(gate:#{@gateRate})- #{len.to_i}(#{len.round(2)})tick後, soundオフ [#{(@nowtime/@tbase).to_i}, #{@nowtime%@tbase}]\n")
    r<<self.bend(0,0) if bends
    r<<self.expre(0,127) if expre
    if rest>0
      @nowtime+=rest
      r<<Event.new(:end,rest," 8#{ch} #{key} 00  # #{rest} len-gate\n")
    end
    r
  end
  def self.dummyNote key,len,accent=false,sharp=0
    vel=@velocity
    vel+=@accentPlus
    key=@preNote.shift if @preNote.size>0
    len=@preLength.shift if @preLength.size>0
    self.oneNote(len,key,vel,sharp)
  end
  def self.byKey key,len,accent=false,sharp=0
    vel=@velocity
    vel+=@accentPlus
    self.oneNote(len,key,vel,@ch,sharp)
  end
  def self.notekey key,length=false,accent=false,sharp=0
    len,velocity,ch=[@tbase,@velocity,@ch]
    velocity+=@accentPlus if accent
    len=length if length
    if key.class==Fixnum
    else
      key,ch=key
    end
    key=key+@basekey
    self.oneNote(len,key,velocity,ch,sharp)
  end
  def self.percussionNote key,len=@tbase,accent=false,sharp=0
    vel=@velocity
    vel+=@accentPlus if accent
    self.oneNote(len,key,vel,@rythmChannel,sharp)
  end
  def self.notes c,l=false,accent=false,sharp=0
    n=@notes[c]
    if @octmode==:near && n.class != Array
      if @lastnote
        n+=12 if @lastnote-n>6
        n-=12 if @lastnote-n<-6
      end
      @lastnote=n
      (@basekey+=12;@lastnote-=12) if n>=12
      (@basekey-=12;@lastnote+=12) if n<0
      n=@lastnote
    end
    self.notekey(n,l,accent,sharp)
  end
  def self.shiftChord chord, base, limit=6
    octave=12
    chord=chord.orotate(-1) while chord[0]>base+limit
    chord=chord.orotate(1) while chord[0]<base-limit
    chord
  end
  def self.chordName c,l=false,accent=false,sharp=0
    c=~/(.)([^(]*)(\((.*)\))?/
    root=$1
    type=$2
    subtype=$4
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
      base=self.note2key(root)+sharp
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
      when "aug" || "+"
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
          end
        }
      end
      ten=ten.sort
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
  def self.chord c,l=false,accent=false,sharp=0
    r=[]
    sspeed=@strokespeed
    (c=c.reverse;sspeed=-sspeed) if sspeed<0
    span=c.size
    sspeed=l/span if span*sspeed>l
    c.each{|i|
      r+=self.soundOn(i,@velocity,@ch,sharp)
      @waitingtime+=sspeed
    }
    l-=sspeed*(span-1)
    @waitingtime,rest=self.byGate(l)
    c.each{|i|
      r+=self.soundOff(i,@ch,sharp)
    }
    r+=self.rest(rest) if rest>0
    r
  end
  def self.rest len=@tbase,ch=@ch
    chx=format("%01x",ch)
    @nowtime+=len
    r=[]
    r<<Event.new(:end,len," 8#{chx} 3C 00 # rest #{len.to_i}(#{len.round(2)})tick後, オフ:ch#{ch}, key:3C\n")
    r
  end
  def self.restHex len=@tbase,ch=@ch
    r=self.rest(len,ch)
    r[0].data
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
    "#{delta} #{e} # #{d}\n"
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
    file= $0=="-e" ? __FILE__ : $0
    thisVer=File.mtime(file).strftime("%Y-%m-%d")
    thisVer="" if $debuglevel && $debuglevel>1
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
    "#{delta} FF #{t} #{len} #{d} # #{pos} #{comment}\n"
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
  def self.expre len,d
    self.controlChange("11,#{d},#{len}")
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
  def self.bend pos,depth,ch=false
    ch=@ch if ! ch
    depth=(depth*@bendCent).to_i
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
        @basekey+oct*12+@notes[i]
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
  def self.basekeySet d
    case d
    when "-"
      if @basekey<12
        STDERR.puts "octave too low."
      else
        @basekey-=12
      end
    when "+"
      if @basekey>0x7f-12
        STDERR.puts "octave too high."
      else
        @basekey+=12
      end
    else
      @basekey=d
    end
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
  def self.strokeSpeed s
    s=s.to_i
    @strokespeed=s
  end
  def self.setmark m
    n=@marktrack.getcount(m,@tracknum)
    m="#{m}@#{n+1}" if n>0
    @marktrack.set(m,@tracknum,@nowtime)
    Event.new(:mark,m,@tracknum,@nowtime)
  end
  def self.eventlist2str elist
    r=[]
    # EventList : [func,args]  or [callonly, func,args] or others
    elist.each{|h|
      cmd,*arg=h
      r<<Event.new(:c,"# #{cmd} #{arg}")
      case cmd
      when :basekeyPlus
        @basekey+=arg[0]
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
          case i.type
          when :ahead
              ahead=i.time
              next if ahead==0
              n=0
              n-=1 until (rr[n].time>0) || n<-10
              if n>-10
                ahead=[ahead,-rr[n].time].max
                rr[n].time+=ahead
                after=-ahead
              else
                after=0
              end
            when :end,:e,:sys
              (i.time+=after;after=0) if after>0
              (i.time+=after;after=0) if after<0 && i.time+after>=0
              rr<<i
            when :c,:raw,:mark
              rr<<i
            else
              "? #{i}"
            end
      end
    }
    rr.map{|i|
      case i
      when String
        i
      when Event
        i.data
      end
    }
  end
  def self.makefraze rundata,tc
    return "" if not rundata
    self.trackPrepare(tc)
    @systemWait=120
    @h=[]
    wait=[]
    @frest=0
    @frestc=0
    @nowtime=0
    @shiftbase=40
    accent=false
    sharp=0
    cmd=rundata.scan(/&\([^)]+\)|\([-+]*[[:digit:]]?\)|:[^\(,]+\([^\)\(]+\),|:[^,]+,|\([^:]*:[^)\(]*\)|_[^!_]+!|_[^_]__[^\?]+\?|v[[:digit:]]+|[<>][[:digit:]]*|\*?[[:digit:]]+\.[[:digit:]]+|\*?[[:digit:]]+|[-+[:alpha:]]|\^|`|'|./)
    cmd<<" " # dummy
    p "make start: ",cmd if $DEBUG
    cmd.each{|i|
      if wait.size>0
        t=@tbase
        i=~/^(\*)?([[:digit:]]+(\.[[:digit:]]+)?)/
        tickmode=$1
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
          case m
          when :percussion
            @h<<[:percussionNote,c,t,accent,sharp]
          when :rawsound
            @h<<[:byKey,c,t,accent,sharp]
          when :sound
            @h<<[:notes,c,t,accent,sharp]
          when :dummyNote
            @h<<[:dummyNote,c,t,accent,sharp]
          when :chord
            @h<<[:chord,c,t,accent,sharp]
          when :chordName
            @h<<[:chordName,c,t,accent,sharp]
          when :rest
            @h<<[:rest,t]
          end
        }
        wait=[]
        accent=false
        sharp=0
      end
      case i
      when /^\(([-+]*)([[:digit:]])?\)/
        n=$2 ? $2.to_i : 1
        if $1.size>1
          n=$1.size
        end
        sh=$1 ? $1[0..0] : "+"
        sh="#{sh}#{n}".to_i
        sharp=sh
      when /^\(key:(-?)\+?([[:digit:]]+)\)/
        tr=$2.to_i
        tr*=-1 if $1=="-"
        @h<<[:basekeyPlus,tr]
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
        @h<<[:call,:preAfter,s]
      when /^\(B:(.*)\)/
        s=$1.split(",")
        @h<<[:call,:preBefore,s]
      when /^\(roll:(.*)\)/
        @shiftbase=$1.to_i
      when /^\(key:reset\)/
        @h<<[:call,:basekeySet,@basekeyOrg]
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
      when /^\(bend:(([[:digit:]]+),)?([-,.[:digit:]]+)\)|^_b__([^?]+)\?/
        i="(bend:#{$4.gsub('_'){','}})" if $4
        x,pos,b=worddata("bend",i)
        npos=0
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
      when /^\(g:([0-9]+)\)/
        @h<<[:call,:setGateRate,$1.to_i]
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
          pan+=64
        when "<"
          pan-=64
        else
        end
        @h<<[:controlChange,"10,#{pan}"]
      when /^\(wait:(\*)?(.*)\)/
        @h<<[:waitingtime,$1? $2.to_i : $2.to_f*@tbase]
      when /^\(accent:([^)]*)\)/
        @h<<[:call,:accent,$1]
      when /^\(on:(.*)\)/
        i=$1
        @h<<[:soundOn,i]
      when /^\(off:(.*)\)/
        @h<<[:soundOff,$1]
      when /^\(chordcenter:(.*)\)/
        @h<<[:call,:chordCenter,$1]
      when /^\(stroke:(.*)\)/
        @h<<[:call,:strokeSpeed,$1]
      when /^\((chord|C):(.*)\)/
        chord=$2.split.join.split(",") # .map{|i|self.note2key(i)}
        wait<<[:chord,chord]
      when /^\(text:(.*)\)/
        @h<<[:text,$1]
      when /^\(tempo:(.*)\)/
        @bpm=$1.to_i
        @h<<[:tempo,@bpm] if @bpm>0
      when /^\(\?:(.*)\)/
        ks=$1
        if ks=~/\-/
          ks=[*($`.to_i)..($'.to_i)]
          key=ks[rand(ks.size)]
          wait<<[:rawsound,key]
        else
          ks=ks.split(",")
          key=ks[rand(ks.size)]
          wait<<[:sound,key]
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
      when "-"
        @h<<[:call,:basekeySet,"-"]
      when "+"
        @h<<[:call,:basekeySet,"+"]
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
        @h<<@h[-1]
      when "r"
        wait<<[:rest,i]
      when "o"
        wait<<[:dummyNote,i]
      when " "
      when "?"
        wait<<[:rawsound,rand(0x7f)]
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
    @h*"\n# track: #{@tracknum} ==== \n"
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
  def self.trackMake data
    @marksh||=@marktrack.calc
    data=data.split("\n").map{|i|
      i=~/^# marktrack\(([^\)]+)\)/
      if $&
        key=$1
        pos=@marksh[key]
        c="position mark: #{key}, #{pos*1.0/@tbase}"
        @marksh.keys.member?(key) ? self.dummyEvent(c,pos) : i
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
  r=i.scan(/\(\?:[^\]]+\)|\(x:[^\]]+\)|\(chord:[^)]+\)|\(C:[^)]+\)|:[^\(,]+\([^\)]+\),|:[^,]+,|[[:digit:]\.]+|_[^!]+!|~|\([-+]*[[:digit:]]?\)|[-+^`']|./)
  wait=[]
  notes=[]
  mod=[]
  r.each{|i|
    case i
    when "-","+","^","`","'",/^\([-+]*[[:digit:]]?\)/
      mod<<i
    when /^\((\?|x|C|chord):[^\)]+\)|^\^?:[^,]+,/
      wait<<1
      notes<<"#{mod*""}#{i}"
      mod=[]
    when /^[[:digit:]]+/
      wait[-1]*=i.to_f
    when "="
      wait<<wait[-1]
      notes<<notes[-1]
    when " "
    else
      wait<<1
      notes<<"#{mod*""}#{i}"
      mod=[]
    end
  }
  sum=wait.inject{|s,i|s+i}
  ls=wait.map{|i|(i*1.0/sum*total).round} # .map{|i|i.round(dep)}
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
  sep="(wait:#{interval})" if interval
  r*sep
end
def macroDef data
  macro={}
  mline=false
  tmp=[]
  name=""
  num=1
  s=data.scan(/macro +[^ ;:=]+ *:= *\( *;|macro +[^ ;:=]+ *:=[^;]+|[^ ;:=]+ *:= *\( *;|[^ ;:=]+ *:=[^;]+| *\) *;|[^;]+|./)
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
  r=d.scan(/\/[^\/]+\/|\[|\]|\.FINE|\.DS|\.DC|\.\$|\.toCODA|\.CODA|\.SKIP|\$\{[^ \{\}]+\}|\$[^ ;\$*_^`'+-]+|;|./).map{|i|
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
def tie d,tbase
  res=[]
  # if no length word after '~' length is 1
  d.gsub!(/~([^*[:digit:]])?/){$1 ? "~1#{$1}" : $&} while d=~/~[^*[:digit:]]/
  li=d.scan(/\$\{[^\}]+\}|\$[^ ;\$_*^`'+-]+|\([^)\(]*\)|:[^\(,]+\([^)]+\),|:[^,]+,|_[^!]+!|_[^_]__[^?]+\?|v[[:digit:]]+|[<>][[:digit:]]*|\*?[[:digit:].]+|\([VGABLN]:[^)]+\)|~|./)
  li.each{|i|
    case i
    when /^(\*)?([[:digit:].]+)/
      tick=$1? $2.to_f : $2.to_f*tbase
      if res[-1][0]==:tick
        res[-1][1]+=tick
      else
        res<<[:tick,tick]
      end
    when "~"
      res<<[:tick,tbase] if res[-1][0]==:e
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
# repeat block analysis: no relation with MIDI format
def repCalc line,macro,tbase
  rpt=/\[([^\[\]]*)\] *([[:digit:]]+)/
  line.gsub!(rpt){$1*$2.to_i} while line=~rpt
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
  a=line.scan(/\/[^\/]+\/|\[|\]|\.FINE|\.DS|\.DC|\.\$|\.toCODA|\.CODA|\.SKIP|\$\{[^ \{\}]+\}|\$[^ ;\$_*^,\)\(`'\/+-]+|\([^\)]*:|\)|./)
  a=a.map{|i|
    if i=~/^\/[^\/]+\//
      if i=~/\$/
        i=i.gsub(/\$\{([^ ;\$_*^,\)\(`'\/+-]+)\}/){macro[$1]}.gsub(/\$([^ ;\$_*^,\)\(`'\/+-]+)/){macro[$1]}
      end
      multiplet(i,tbase)
    else
      i
    end
  }
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
    else
      current
    end
    res<<current
  end
  res=(res-["[","]",".CODA",".DS",".DC",".FINE",".toCODA",".$",".SKIP"])*""
  res=repCalc(res,macro,tbase) while macro.keys.size>0 && nestsearch(res,macro)
  p res if $DEBUG && $debuglevel>1
  # 空白
  res=res.split.join 
  res=tie(res,tbase)
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

class MmlTracks
  attr_accessor :tracknum, :tbase, :rundatas, :rawdatas, :mx
  attr_accessor :bpm, :velocity, :octave, :vfuzzy, :data, :infile, :outfile
  def initialize tbase=480,pagesep='///',expfile='expfile.txt',cmark=';;'
    String.new.setcmark(cmark)
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
  end
  def init test,fz
    @mx.prepare(@bpm,@tbase,@velocity,@octave,@vfuzzy)
    @mx.setfile(@infile)
    @mx.setmidiname(@outfile) if @outfile
    @mx.setdata(@data) if ! @mx.getdata
    (hint;exit) if (! @mx.getdata || ! @mx.getmidiname ) && ! test
    settest if test
    @tracks=@mx.getdata.tracks(@pagesep)
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
    open(@expfile,"w"){|f|f.puts @rundatas*"|||"} if @expfile
    @tracknum=@rawdatas.size+@rundatas.size
    @tracknum=@tracks.size
  end
  def settracks
    @htracks=[]
    tc=0
    # remember starting position check if data exist before sound
    @htracks << @mx.metaTitle + @mx.generaterText + @mx.starttempo.data + @mx.makefraze(@rundatas[0],tc) + @mx.lastrest
    @rundatas[1..-1].each{|track|
      tc+=1
      @htracks<< @mx.restHex + @mx.makefraze(track,tc) + @mx.lastrest
    }
  end
  def pack
    @header=@mx.header(1, @tracknum, @tbase)
    alla=[@header]+@htracks.map{|t|@mx.trackMake(t)}.flatten
    puts alla if $DEBUG
    all=alla.map{|i|i.trim("","#")}*""
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