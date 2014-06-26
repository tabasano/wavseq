#!/usr/bin/ruby
require 'kconv'
require 'optparse'

infile=false
outfile=false
data=false
bpm=120
opt = OptionParser.new
opt.on('-i file',"infile") {|v| infile=v }
opt.on('-o file',"outfile") {|v| outfile=v }
opt.on('-d d',"data string") {|v| data=v }
opt.on('-t b',"bpm") {|v| bpm=v.to_f }
opt.parse!(ARGV)

class String
  def trim
    d=split("\n").map{|i|i.sub(/#.*/){}.chomp}*" "
#    p d
    d
  end
end
def sizemake d
  d=d.trim.split.join
  i=(d.size+8)/2
#  p [d,i,i.to_s(16)]
  ("00000000"+i.to_s(16))[-8..-1]
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
  b=[varlen(v.to_i)]
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
  def self.header format,track,tbase=480
    # @tbase設定のため最初に呼ばなければならない
    format=[format,0xff].min
    track=[track,0xff].min
    tbase=[tbase,0x7fff].min
    @tbase=tbase
    format=format("%02x",format)
    track=format("%02x",track)
    tbase=format("%04x",tbase)
    "
      4D 54 68 64  # ヘッダ
      00 00 00 06  # データ長:6[byte]
      00 #{format} # フォーマット
      00 #{track}  # トラック数
      #{tbase}      # 1 拍の分解能
    "
  end
  def self.oneNote len=@tbase,key=@basekey,velocity=@velocity,ch=@ch
    ch=[ch,0x0f].min
    @velocity=[velocity,0x7f].min
    @key=[key,0x7f].min
    key=format("%02x",@key)
    ch=format("%01x",ch)
    vel=format("%02x",@velocity)
    delta=varlenHex(len)
    str="
      00 9#{ch} #{key} #{vel} # 0拍後, soundオン...
      #{delta} 8#{ch} #{key} 00 # delta後, soundオフ
    "
  end
  def self.notekey key,length=false
    len,velocity,ch=[@tbase,@velocity,@ch]
    len=len*length if length
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
  def self.percussionNote key,len=1
    self.oneNote(@tbase*len,key,@velocity,@rythmChannel)
  end
  def self.notes c,l=false
    @rythmChannel||=9
    @notes||={
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
    notekey(@notes[c],l)
  end
  def self.rest len=1
    len=@tbase*len
    delta=varlenHex(len)
    "
      #{delta}  89 3C 00 # 1拍後, オフ:ch10, key:3C
    "
  end
  def self.tempo bpm
    @bpmStart=bpm if ! @bpm
    @bpm=bpm
    d_bpm=self.makebpm(@bpm)
    "
      00 FF 51 03 #{d_bpm} # 四分音符の長さをマイクロ秒で3byte
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
  def self.ProgramChange ch,inst
    ch=[ch,0x0f].min
    inst=[inst,0xff].min
    ch=format("%01x",ch)
    inst=format("%02x",inst)
    "00 C#{ch} #{inst}\n"
  end
  def self.programGet p
    return 0 if not @programList
    r=@programList.select{|num,line|line=~/#{p}/i}
    r.size>0 ? r[0][0] : 0
  end
  def self.percussionGet p
    return @snare if not @percussionList
    r=@percussionList.select{|num,line|line=~/#{p}/i}
    r.size>0 ? r[0][0] : @snare
  end
  def self.bend ch,depth,len=0
    delta=varlenHex(len)
    "#{delta} e#{format"%01x",ch} #{bendHex(depth)}\n"
  end
  def self.makefraze rundata
    return "" if not rundata
    @h=[]
    @ch=0
    @velocity=0x40
    @basekey||=0x3C
    @basekeyRythm=@basekeyOrg=@basekey
    wait=[]
    cmd=rundata.scan(/&\([^)]+\)|\([^:]*:[^)]*\)|_[^!]+!|v[[:digit:]]+|[<>][[:digit:]]*|[[:digit:]]+\.[[:digit:]]+|[[:digit:]]+|[-+[:alpha:]]/)
    cmd<<" " # dummy
    p cmd if $DEBUG
    cmd.each{|i|
      if wait.size>0
        t=1
        i=~/^[[:digit:]]+(\.[[:digit:]]+)?/
        if $&
          t=$&.to_i
          t=$&.to_f if $1
        end
        wait.each{|m,c|
          case m
          when :percussion
            @h<<self.percussionNote(c,t)
          when :sound
            @h<<self.notes(c,t)
          when :rest
            @h<<self.rest(t)
          end
        }
        wait=[]
      end
      case i
      when /\(key:(-?)\+?([[:digit:]]+)\)/
        tr=$2.to_i
        tr*=-1 if $1=="-"
        @basekey+=tr
      when /\(key:reset\)/
        @basekey=@basekeyOrg
      when /\(p:(([[:digit:]]+),)?(([[:digit:]]+)|([[:alnum:]]+))\)/
        channel=$1 ? $2.to_i : 0
        if $5
          instrument=self.programGet($5)
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
      when /\(tempo:reset\)/
        @h<<self.tempo(@bpmStart)
      when /\(ch:(.*)\)/
        @ch=$1.to_i
      when /\(cc:(.*)\)/
        @h<<self.controlChange($1)
      when /\(pan:(<|>)(.*)\)/
        pan=$2.to_i
        pan=$1==">" ? 64+pan : 64-pan
        @h<<self.controlChange("10,#{pan}")
      when /\(tempo:(.*)\)/
        bpm=$1.to_i
        @h<<self.tempo(bpm) if @bpm>0
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
      when "r"
        wait<<[:rest,i]
      when " "
      else
        wait<<[:sound,i]
      end
    }
    @h*"\n# onoff ==== \n"
  end
  def self.loadProgramChange file
    if not File.exist?(file)
      @programList=false
    else
      li=File.readlines(file).select{|i|i=~/^[[:digit:]]/}.map{|i|
        # zero base
        [i.split[0].to_i-1,i.toutf8]
      }
      @programList=li.size>0 ? li : false
    end
  end
  def self.loadPercussionMap file
    @snare=35
    if not File.exist?(file)
      @percussionList=false
    else
      li=File.readlines(file).select{|i|i=~/^[[:digit:]]/}.map{|i|
        # zero base
        [i.split[0].to_i,i.toutf8]
      }
      @percussionList=li.size>0 ? li : false
      @snare=self.percussionGet("snare")
    end
  end
  def self.trackMake data
    start="
      4D 54 72 6B # MTrk
    "
    dsize=sizemake(data)
    trackend="
      00 FF 2F 00 # end
    "
    [start,dsize,data,trackend]
  end
  def self.dumpHex
    @h
  end
end

# repeat block analysis: no relation with MIDI format
def repCalc line
  a=line.scan(/\[|\]|\.FINE|\.DS|\.DC|\.\$|\.toCODA|\.CODA|\.SKIP|./)
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
    res<<current
    case current
    when /^\[/
      if ! done.member?(countertmp)
        repcount+=1
        rep<<countertmp
        done<<countertmp
      end
    when /^\]/
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
    when ".$"
      pointDS=countertmp
    else
    end
  end
  (res-[".CODA",".DS",".DC",".FINE",".toCODA",".$",".SKIP","[","]"])*""
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
def hint
  cmd=File.basename($0)
  puts <<EOF
usage: #{cmd} -d \"dddd dr3 dddd r4 drdrdrdr dddd dr3\" -o outfile.mid -t bpm
       #{cmd} -i infile.txt  -o outfile.mid -b bpm

syntax: ...( will be changed time after time)
    abcdefg=sound, +-=octave change, r=rest, num=length, ><=tempo up-down(percent),
    v=velocity set(0-127) , blank ignored
    &(00 00) =set hex data directly. This can include '$delta(240)' for deltaTime data making etc..
    (p:0,11) =ProgramChange channel 0, instrument 11
    (p:0,organ) =ProgramChange channel 0, instrument ?(search word like 'organ' from list if exist)
        map text must start with instrument number
    (key:-4) =transpose -4 except rythmChannel
    [...] =repeat 2 times for first time
    (tempo:120) =tempo set
    (ch:1) =this track's channel set
    (cc:10,64) =controlChange number10 value 64
    (pan:>64)  =panpot right 64. ( pan:>0  set center )
    (bend:100) =pitch bend 100
    ||| = track separater
    .DC .DS .toCODA .CODA .FINE =coda mark etc.
    .SKIP =skip mark on over second time
    .$ =DS point
    _snare! =percussion sound ( search word like 'snare' (can use tone number) from percussion list if exist )
        map text must start with tone number
    (loadf:filename.mid,2) =load filename.mid, track 2. Track must be this only and seperated by '|||'.
EOF
end

data=ARGV.shift if ! data
outfile=ARGV.shift if ! outfile
data=File.read(infile).trim if infile && File.exist?(infile)

(hint;exit) if (! data || ! outfile)

data=data.toutf8
file="midi-programChange-list.txt"
pfile="midi-percussion-map.txt"
mx=MidiHex
mx.loadProgramChange(file)
mx.loadPercussionMap(pfile)

tbase=480 # division
delta=varlenHex(tbase)
#p "deltaTime: 0x#{delta}"

comment="by midi-simple-make.rb"
commenthex,len=txt2hex(comment)
d_comment="
00 FF 01 #{len} #{commenthex}
"
d_last=
"
#{delta}  89 3C 00 # 1拍後, オフ:ch10, key:3C
"
rundatas=[]
rawdatas=[]
tracks=data.split('|||')
tracks.map{|track| repCalc(track) }.each{|t|
  r=loadCalc(t)
  case r[0]
  when :raw
    rawdatas<<r[1]
  when :seq
    rundatas<<r[1]
  end
}
rawdatas.flatten!
tracknum=rawdatas.size+rundatas.size
tracknum=tracks.size
format=1

d_header=mx.header(format,tracknum,tbase) 
tracks=[]
tracks<<d_comment + mx.tempo(bpm) + mx.makefraze(rundatas[0]) + d_last
rundatas[1..-1].each{|track|
  tracks<< mx.makefraze(track) + d_last
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
