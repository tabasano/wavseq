#!/usr/bin/ruby
require 'kconv'
require 'optparse'

def hint
  cmd=File.basename($0)
  puts <<EOF
usage: #{cmd} -d \"dddd dr3 dddd r4 drdrdrdr dddd dr3\" -o outfile.mid -t bpm
       #{cmd} -i infile.txt  -o outfile.mid -t bpm

syntax: ...( will be changed time after time)
    abcdefg =sound; capital letters are sharps 
    +- =octave change
    r  =rest
    >< =tempo up-down(percent)
    a4    =4 beats of note 'a'
    a     =one beat of note 'a'. default length equals 1 now.
    A*120 =120 ticks of note 'a #'
    v60   =velocity set to 60 (0-127)
    &(00 00) =set hex data directly. This can include '$delta(240)' for deltaTime data making etc..
    (p:0,11) =ProgramChange channel 0, instrument 11
    (p:0,organ) =ProgramChange channel 0, instrument ?(search word like 'organ' from list if exist)
        map text must start with instrument number
    (key:-4) =transpose -4 except rythmChannel
    [...] =repeat 2 times for first time
    [...]3 =3 times of inside block []
    /2:abcd/    =(triplet etc.) notes 'abcd' in 2 beats measure
    /*120:abcd/ = notes 'abcd' in 120 ticks measure. now, default measure is 480 ticks per one beat.
    /cd/ ~2e /~fga/    =(tie) each length : c 0.5 d 0.5+2 e 1+0.25 f 0.25 g 0.25 a 0.25
    (tempo:120) =tempo set
    (ch:1     ) =this track's channel set
    (cc:10,64) =controlChange number10 value 64. see SMF format.
    (pan:>64)  =panpot right 64. ( pan:>0  set center )
    (bend:100) =pitch bend 100
    (g:10) =set sound gate-rate 10% (staccato)
    ||| = track separater
    /// = page separater
    .DC .DS .toCODA .CODA .FINE =coda mark etc.
    .SKIP =skip mark on over second time
    .$ =DS point
    _snare! =percussion sound ( search word like 'snare' (can use tone number) from percussion list if exist )
        map text must start with tone number
    (loadf:filename.mid,2) =load filename.mid, track 2. Track must be this only and seperated by '|||'.
    W:=abc        =macro definition. One Charactor macro can be used. When macro name is long, use prefix '$' for refering.
    macro W:=abc  =macro definition.
    compile order is : page,track seperate => macro set and replace => repeat check => sound data make
    ; =seperater. same to a new line
    blank =ignored
    # comment =ignored after # of each line
EOF
end

infile=false
outfile=false
$debuglevel=1
data=""
pspl="///"
bpm=120
opt = OptionParser.new
opt.on('-i file',"infile") {|v| infile=v }
opt.on('-o file',"outfile") {|v| outfile=v }
opt.on('-d d',"data string") {|v| data=v }
opt.on('-D',"debug") {|v| $DEBUG=v }
opt.on('-s',"show syntax") {|v|
  hint
  exit
}
opt.on('-t b',"bpm") {|v| bpm=v.to_f }
opt.on('-T w',"programChange test like instrument name '...'") {|v| $test=v }
opt.on('-c d',"data for test") {|v| $testdata=v }
opt.on('-p pspl',"page split chars") {|v| pspl=v }
opt.on('-M i',"debug level") {|v| $debuglevel=v.to_i }
opt.on('-m i',"mode of test/ 1:GM 2:XG 3:GS") {|v| $testmode=v.to_i }
opt.parse!(ARGV)

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
class String
  def trim ofs=""
    d=split("\n").map{|i|i.sub(/#.*/){}.chomp}*ofs
#    p d
    d
  end
  def tracks pspl
    tracks={}
    pages=self.split(/#{pspl}+/)
    pages.each{|p|
      p.split('|||').each_with_index{|t,i|
        tracks[i] ? tracks[i]<<t : tracks[i]=[t]
      }
    }
    tracks.keys.sort.map{|k|tracks[k]*";"}
  end
end
def trackSizeHex d
  d=d.trim.split.join
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
  d=d.to_i(16) if d.class==String && d=~/^0(x|X)/
  d
end
def varlenHex(v)
  v=hex2digit(v)
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

def rawHexPart d
  li=d.scan(/\$delta\([^)]*\)|\$bend\([^)]*\)|./)
  res=[]
  li.map{|i|
    case i
    when /\$delta\(([^)]*)\)/
      varlenHex($1)
    when /\$bend\(([^)]*)\)/
      bendHex($1)
    else
      i
    end
  }*""
end
module MidiHex
  # 設定のため最初に呼ばなければならない
  def self.prepare tbase=480,vel=0x40
    @tbase=tbase
    @gateRate=100
    @nowtime=0
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
    @accentPlus=10
    @basekey=0x3C
    @basekeyRythm=@basekeyOrg=@basekey
    @prepareSet=[@tbase,@ch,@velocity,@basekey,@gateRate]
    @chmax=15
  end
  def self.setGateRate g
    @gateRate=[g,100].min
  end
  def self.trackPrepare tc=0
    @tbase,@ch,@velocity,@basekey=@prepareSet
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
  def self.byGate len
    l=(len*1.0*@gateRate/100).to_i
    r=len-l
    [l,r]
  end
  def self.oneNote len=@tbase,key=@basekey,velocity=@velocity,ch=@ch
    ch=[ch,0x0f].min
    velocity=[velocity,0x7f].min
    @key=[key,0x7f].min
    key=format("%02x",@key)
    ch=format("%01x",ch)
    vel=format("%02x",velocity)
    slen,r=self.byGate(len)
    deltaS=varlenHex(slen)
    deltaR=varlenHex(r)
    @nowtime+=len
    str="
      00 9#{ch} #{key} #{vel} # 0拍後, soundオン note #{@key} velocity #{velocity}
      #{deltaS} 8#{ch} #{key} 00 # #{slen}(gate:#{@gateRate})- #{len.to_i}(#{len.round(2)})tick後, soundオフ [#{(@nowtime/@tbase).to_i}, #{@nowtime%@tbase}]
    "
    rstr=r==0 ? "" : "
      #{deltaR} 8#{ch} #{key} 00  # #{r} len-gate
    "
    str+rstr
  end
  def self.byKey key,len,accent=false
    vel=@velocity
    vel+=@accentPlus
    self.oneNote(len,key,vel)
  end
  def self.notekey key,length=false,accent=false
    len,velocity,ch=[@tbase,@velocity,@ch]
    velocity+=@accentPlus if accent
    len=length if length
    if key.class==Fixnum
    else
      key,ch=key
    end
    if ch==@rythmChannel
      key=key+@basekeyRythm
    else
      key=key+@basekey
    end
    self.oneNote(len,key,velocity,ch)
  end
  def self.percussionNote key,len=@tbase,accent=false
    vel=@velocity
    vel+=@accentPlus if accent
    self.oneNote(len,key,vel,@rythmChannel)
  end
  def self.notes c,l=false,accent=false
    notekey(@notes[c],l,accent)
  end
  def self.rest len=@tbase
    delta=varlenHex(len)
    @nowtime+=len
    "
      #{delta}  89 3C 00 # #{len.to_i}(#{len.round(2)})tick後, オフ:ch10, key:3C
    "
  end
  def self.tempo bpm, len=0
    delta=varlenHex(len)
    @bpmStart=bpm if ! @bpm
    @bpm=bpm
    d_bpm=self.makebpm(@bpm)
    @nowtime+=len
    "
      #{delta} FF 51 03 #{d_bpm} # 四分音符の長さ (bpm: #{@bpm}) マイクロ秒で3byte
    "
  end
  def self.makebpm bpm
    d="000000"+(60_000_000/bpm.to_f).to_i.to_s(16)
    d[-6..-1]
  end
  def self.controlChange v
    v=~/(.*),(.*)/
    n,v=$1.to_i,$2.to_i
    ch=@ch
    v=[0,[v,0x7f].min].max
    ch=format("%01x",ch)
    n=format("%02x",n)
    data=format("%02x",v)
    "00 B#{ch} #{n} #{data}\n"
  end
  def self.ProgramChange ch,inst,len=0
    ch=[ch,0x0f].min
    inst=[inst,0xff].min
    chx=format("%01x",ch)
    instx=format("%02x",inst)
    delta=varlenHex(len)
    @nowtime+=len
    "#{delta} C#{chx} #{instx} # program change ch#{ch} #{inst} [#{@programList[inst][1]}]\n"
  end
  # GM,GS,XG wakeup command need over 50milisec. ?
  # if not, midi player may hung up.
  def self.GMsystemOn len=0,mode=1
    # GM1,GM2
    m=mode==2 ? 3 : 1
    delta=varlenHex(len)
    @nowtime+=len
    "
      #{delta} F0 7E 7F 09 0#{m} F7 # GM
    "
  end
  def self.XGsystemOn len=0
    delta=varlenHex(len)
    @nowtime+=len
    "
      #{delta} F0 43 10 4C 00 00 7E 00 F7 # XG
    "
  end
  def self.GSreset len=0
    delta=varlenHex(len)
    @nowtime+=len
    " #{delta} F0 41 10 42 12 40 00 7F 00 41 F7 # GS \n"
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
    delta=varlenHex(len)
    @nowtime+=len
    @nowtime+=len
    "
      #{delta} B#{ch} 00 #{msb} # BankSelect MSB
      #{delta} B#{ch} 20 #{lsb} # BankSelect LSB
    "
  end
  def self.bankSelectPC d
    d=~/(([^,]*),([^,]*)),([^,]*)(,(.*))?/
    len=$6.to_i
    inst=$4.to_i ##
    bs=self.bankSelect("#{$1},#{len}")
    pc=self.ProgramChange(@ch,inst,len)
    bs+pc
  end
  def self.programGet p,num=false
    return 0 if not @programList
    if p=~/\?/
      r=[@programList[rand(@programList.size)]]
      p "random: ",r if $DEBUG
    else
      r=@programList.select{|num,line|line=~/#{p}/i}
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
    return @snare if not @percussionList
    r=@percussionList.select{|num,line|line=~/#{p}/i}
    puts "no percussion name like '#{p}' in list" if $DEBUG && r.size==0
    r.size>0 ? r[0][0] : @snare
  end
  def self.bend ch,depth,len=0
    delta=varlenHex(len)
    @nowtime+=len
    "#{delta} e#{format"%01x",ch} #{bendHex(depth)}\n"
  end
  def self.makefraze rundata,tc
    return "" if not rundata
    self.trackPrepare(tc)
    @h=[]
    wait=[]
    @nowtime=0
    accent=false
    cmd=rundata.scan(/&\([^)]+\)|\([^:]*:[^)]*\)|_[^!]+!|v[[:digit:]]+|[<>][[:digit:]]*|[[:digit:]]+\.[[:digit:]]+|\*?[[:digit:]]+|[-+[:alpha:]]|\^|./)
    cmd<<" " # dummy
    p "make start: ",cmd if $DEBUG
    cmd.each{|i|
      if wait.size>0
        t=@tbase
        i=~/^(\*)?([[:digit:]]+)(\.[[:digit:]]+)?/
        tickmode=$1
        if $&
          t=$2.to_i
          if tickmode
            puts "tick: #{t}" if $DEBUG && $debuglevel>1
          else
            t=$&.to_f if $3
            t*=@tbase
          end
        end
        wait.each{|m,c|
          case m
          when :percussion
            @h<<self.percussionNote(c,t,accent)
          when :rawsound
            @h<<self.byKey(c,t,accent)
          when :sound
            @h<<self.notes(c,t,accent)
          when :rest
            @h<<self.rest(t)
          end
        }
        wait=[]
        accent=false
      end
      case i
      when /\(key:(-?)\+?([[:digit:]]+)\)/
        tr=$2.to_i
        tr*=-1 if $1=="-"
        @basekey+=tr
      when /\(key:reset\)/
        @basekey=@basekeyOrg
      when /\(p:(([[:digit:]]+),)?(([[:digit:]]+)|([\?[:alnum:]]+)(,([[:digit:]]))?)\)/
        channel=$1 ? $2.to_i : @ch
        subNo=false
        if $5
          subNo=$7.to_i if $7
          instrument=self.programGet($5,subNo)
        else
          instrument=$4.to_i
        end
        @h<<self.ProgramChange(channel,instrument)
      when /\(bend:(([[:digit:]]+),)?(-?[[:digit:]]+)\)/
        channel=$1 ? $2.to_i : @ch
        depth=$3.to_i
        @h<<self.bend(channel,depth)
      when /&\((.+)\)/
        raw=rawHexPart($1)
        @h<<raw
      when /_(([[:digit:]]+)|([[:alnum:]]+))!/
        if $2
          perc=$2.to_i
        else
          perc=self.percussionGet($3)
        end
        wait<<[:percussion,perc]
      when /v([0-9]+)/
        @velocity=$1.to_i
      when /\(g:([0-9]+)\)/
        self.setGateRate($1.to_i)
      when /\(tempo:reset\)/
        @h<<self.tempo(@bpmStart)
      when /\(ch:(.*)\)/
        @ch=$1.to_i
      when /\(cc:(.*)\)/
        @h<<self.controlChange($1)
      when /\(bs:(.*)\)/
        @h<<self.bankSelect($1)
      when /\(bspc:(.*)\)/
        @h<<self.bankSelectPC($1)
      when /\(gs:reset\)/
        @h<<self.GSreset
      when /\(gm:on\)/
        @h<<self.GMsystemOn(120)
      when /\(xg:on\)/
        @h<<self.XGsystemOn(120)
      when /\(pan:(<|>)(.*)\)/
        pan=$2.to_i
        pan=$1==">" ? 64+pan : 64-pan
        @h<<self.controlChange("10,#{pan}")
      when /\(tempo:(.*)\)/
        bpm=$1.to_i
        @h<<self.tempo(bpm) if @bpm>0
      when /\(x:(.*)\)/
        key=$1.to_i
        wait<<[:rawsound,key]
      when /<(.*)/
        rate=1.25
        if $1.size>0
          rate=$1.to_i/100.0
        end
        @bpm=@bpm/rate
        @h<<self.tempo(@bpm)
      when />(.*)/
        rate=1.25
        if $1.size>0
          rate=$1.to_i/100.0
        end
        @bpm=@bpm*rate
        @h<<self.tempo(@bpm)
      when /-/
        @basekey-=12
      when /\+/
        @basekey+=12
      when /[0-9]+/
        # (i.to_i-1).times{@h<<@h[-1]}
      when "^"
        p "accent" if $DEBUG
        accent=true
      when "r"
        wait<<[:rest,i]
      when " "
      else
        if @notes.keys.member?(i)
          wait<<[:sound,i]
        else
          STDERR.puts "[#{i}] undefined note?" if $DEBUG
        end
      end
    }
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
  end
  def self.loadPercussionMap file
    @snare=35
    @gmSnare,@gmKick,@gmHiTom,@gmLoTom,@gmOpenH,@gmCloseH,@gmCrashCym=38,35,50,45,46,42,49
    if not File.exist?(file)
      @percussionList=false
    else
      @percussionList=self.loadMap(file,0)
      @snare=self.percussionGet("snare")
    end
  end
  def self.trackMake data
    start="
# track header
      4D 54 72 6B # MTrk
    "
    dsize=trackSizeHex(data)
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
  d=~/\/((\*)?([[:digit:].]*):)?(.*)\//
  tickmode=$2
  i=$4
  rate=$3 ? $3.to_f : 1
  rate=1 if rate==0
  if tickmode
    total=$3.to_i
  else
    total=tbase*rate
  end
  r=i.scan(/\^?\(x:[^\]]+\)|[[:digit:]\.]+|\^?_[^!]+!|[-+^]?./)
  wait=[]
  notes=[]
  r.each{|i|
    case i
    when /\(x:[^\]]+\)/
      wait<<1
      notes<<i
    when /^[[:digit:]]+/
      wait[-1]*=i.to_f
    when / /
    else
      wait<<1
      notes<<i
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
  result=[]
  notes.size.times{|i|
    result<<notes[i]
    result<<"*#{ls[i]}"
  }
  p "multiplet: ",total,ls.inject{|s,i|s+i} if $DEBUG && $debuglevel>1
  result*""
end
def macroDef data
  macro={}
  s=data.scan(/macro +[^ ;]+ *:=[^;]+|[^ ;]+ *:=[^;]+|./)
  data=s.map{|i|
    case i
    when /(macro +)?( *[^ ;]+) *:=([^;]+)/
      macro[$2]=$3
      ""
    else
      i
    end
  }*""
  [macro,data]
end
def nestsearch d,macro
  a=d.scan(/\[[^\[\]]*\] *[[:digit:]]+/)!=[]
  r=d.scan(/\/[^\/]+\/|\[|\]|\.FINE|\.DS|\.DC|\.\$|\.toCODA|\.CODA|\.SKIP|\$\{[^ \{\}]+\}|\$[^ ;\$*_^+-]+|;|./).map{|i|
    case i
    when /^\$/
      $'
    when /\/[^\/]+\//
      true
    else
      i
    end
  }
  b=(macro.keys-r).size<macro.keys.size
  c=r.member?(true)
  p "nest? #{a} #{b} #{c}",r,macro if $DEBUG
  a||b||c
end
def tie d,tbase
  res=[]
  # if no length word after '~' length is 1
  d.gsub!(/~([^*[:digit:]])?/){$1 ? "~1" : "~"}
  li=d.scan(/\$\{[^\}]+\}|\$[^ ;\$_*^+-]+|\([^)]*\)|_[^!]+!|v[[:digit:]]+|[<>][[:digit:]]*|\*?[[:digit:].]+|~|./)
  li.each{|i|
    case i
    when /^(\*)?([[:digit:].]+)/
      tick=$1? $2.to_i : $2.to_f*tbase
      if res[-1][0]==:tick
        res[-1][1]+=tick
      else
        res<<[:tick,tick]
      end
    when "~"
      res<<[:tick,tbase] if res[-1][0]==:e
    else
      res<<[:e,i]
    end
  }
  line=""
  res.each{|mark,data|
    case mark
    when :e
      line<<data
    when :tick
      line<<"*#{data.to_i}"
    end
  }
  p res,line if $DEBUG && $debuglevel>1
  line
end
# repeat block analysis: no relation with MIDI format
def repCalc line,macro,tbase
  rpt=/\[([^\[\]]*)\] *([[:digit:]]+)/
  line.gsub!(rpt){$1*$2.to_i} while line=~rpt
  a=line.scan(/\/[^\/]+\/|\[|\]|\.FINE|\.DS|\.DC|\.\$|\.toCODA|\.CODA|\.SKIP|\$\{[^ \{\}]+\}|\$[^ ;\$_*^+-]+|./)
  a=a.map{|i|
    if i=~/^\/[^\/]+\//
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
      current=macro.keys.member?(current) ? macro[current] : current
    end
    res<<current
  end
  res=(res-[".CODA",".DS",".DC",".FINE",".toCODA",".$",".SKIP"])*""
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
    [:seq,rawHexPart(d)]
  end
end

data=File.read(infile).trim(" ;") if infile && File.exist?(infile)

(hint;exit) if (! data || ! outfile ) && ! $test

data=data.toutf8
file="midi-programChange-list.txt"
pfile="midi-percussion-map.txt"

tbase=480 # division
delta=varlenHex(tbase)
mx=MidiHex
mx.prepare(tbase,0x40)
mx.loadProgramChange(file)
mx.loadPercussionMap(pfile)
data=mx.test($testdata,$testmode) if $test

comment="by midi-simple-make.rb"
commenthex,len=txt2hex(comment)
d_comment="
#{delta} FF 01 #{len} #{commenthex}
"
d_last=
"
#{delta}  89 3C 00 # 1拍後, オフ:ch10, key:3C
"
rundatas=[]
rawdatas=[]
macro={}
tracks=data.tracks(pspl)
p tracks if $DEBUG && $debuglevel>1
tracks.map{|track|
    m,track=macroDef(track)
    macro.merge!(m)
    repCalc(track,macro,tbase)
  }.each{|t|
    r=loadCalc(t)
    case r[0]
    when :raw
      rawdatas<<r[1]
    when :seq
      rundatas<<r[1]
    end
}
p macro if$DEBUG
rawdatas.flatten!
tracknum=rawdatas.size+rundatas.size
tracknum=tracks.size
format=1

d_header=mx.header(format,tracknum,tbase) 
tracks=[]
# remember starting position check if data exist before sound
tc=0
tracks<< d_comment + mx.tempo(bpm) + mx.makefraze(rundatas[0],tc) + d_last
rundatas[1..-1].each{|track|
  tc+=1
  tracks<< mx.rest + mx.makefraze(track,tc) + d_last
}
alla=[d_header]+tracks.map{|t|mx.trackMake(t)}.flatten
puts alla if $DEBUG
all=alla.map(&:trim)*""
array=[all.split.join]
#puts alla,all,array
binary = array.pack( "H*" )

# save data. data = MIDI-header + seq-made MIDI-tracks + loaded extra MIDI-tracks.
open(outfile,"wb"){|f|
  f.write binary
  rawdatas.each{|i|
    f.write i
  }
}
