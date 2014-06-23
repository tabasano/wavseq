#!/usr/bin/ruby
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
def varlenHex(v)
  b=[varlen(v)]
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

module Mid
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
    @ch=[ch,0x0f].min
    @velocity=[velocity,0x7f].min
    @key=[key,0x7f].min
    key=format("%02x",@key)
    ch=format("%01x",@ch)
    vel=format("%02x",@velocity)
    delta=varlenHex(len)
    str="
      00 9#{ch} #{key} #{vel} # 0拍後, soundオン...
      #{delta} 8#{ch} #{key} 00 # delta後, soundオフ
    "
  end
  def self.notekey key
    len,velocity,ch=[@tbase,@velocity,@ch]
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
  def self.notes c
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
    notekey(@notes[c])
  end
  def self.rest len=@tbase
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
  def self.makefraze rundata
    @h=[]
    @ch=0
    @velocity=0x40
    @basekey||=0x3C
    @basekeyRythm=@basekeyOrg=@basekey
    cmd=rundata.scan(/&\([^)]+\)|\([^:]*:[^)]*\)|v[[:digit:]]+|[<>][[:digit:]]*|[[:digit:]]+|[-+[:alpha:]]/)
    p cmd if $DEBUG
    cmd.each{|i|
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
      when /&\((.+)\)/
        @h<<$1
      when /v([0-9]+)/
        @velocity=$1.to_i
      when /\(tempo:reset\)/
        @h<<self.tempo(@bpmStart)
      when /\(ch:(.*)\)/
        @ch=$1.to_i
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
        (i.to_i-1).times{@h<<@h[-1]}
      when "r"
        @h<<self.rest
      when " "
      else
        @h<<self.notes(i)
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
        [i.split[0].to_i-1,i]
      }
      @programList=li.size>0 ? li : false
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
def repCalc line
  a=line.scan(/\[|\]|\.END|\.DS|\.DC|\.toCODA|\.CODA|./)
  hs={}
  a.each_with_index{|d,i|hs[i]=d}
  hs=hs.invert
  res=[]
  done=[]
  dsflag=dcflag=false
  counter=0
  repcount=0
  rep=[]
  while true
    current=a[counter]
# puts "#{counter}: #{current}, #{rep},done: #{done}"
    break if ! current
    res<<current
    if current=~/^\[/ && ! dsflag && ! done.member?(counter)
      repcount+=1
      rep<<counter
      done<<counter
    end
    if current=~/^\]/ && ! dsflag && ! done.member?(counter)
      done<<counter
      counter=rep.shift+1
    else
      counter+=1
    end
    if current==".DS" || current==".DC"
      counter=0
      dsflag=true
    elsif current==".toCODA" && dsflag
      counter=hs[".CODA"]
    elsif current==".END" && (dsflag || dcflag)
      break
    end
  end
  (res-[".CODA",".DS",".DC",".END",".toCODA","[","]"])*""
end

file="midi-programChange-list.txt"
Mid.loadProgramChange(file)

array = []

tbase=480
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

def hint
  puts "usage: #{$0} \"dddd dr3 dddd r4 drdrdrdr dddd dr3\" outfile.mid bpm"
  puts "    syntax..."
  puts "    abcdefg=sound, +-=octave change, r=rest, num=length, ><=tempo up-down(percent),"
  puts "    v=velocity set(0-127) , blank ignored"
  puts "    &(00 00) =set hex data directly"
  puts "    (p:0,11) =ProgramChange channel 0, instrument 11"
  puts "    (p:0,organ) =ProgramChange channel 0, instrument ?(search word like 'organ' from list if exist)"
  puts "    (key:-4) =transpose -4 except rythmChannel"
  puts "    [...] =repeat 2 times"
  puts "    (tempo:120) =tempo set"
end
data,ofile,bpm = ARGV
(hint;exit) if ! data

rundatas=data.split('|||').map{|track| repCalc(track) }
tracknum=rundatas.size
bpm=120 if ! bpm
bpm=bpm.to_f

d_header=Mid.header(1,tracknum,tbase) #format,tracknum,division
tracks=[]
tracks<<d_comment + Mid.tempo(bpm) + Mid.makefraze(rundatas[0]) + d_last
rundatas[1..-1].each{|track|
  tracks<< Mid.makefraze(track) + d_last
}
alla=[d_header]+tracks.map{|t|Mid.trackMake(t)}.flatten
puts alla if $DEBUG
all=alla.map(&:trim)*""
array=[all.split.join]
#puts alla,all,array
binary = array.pack( "H*" )
#p binary.unpack("H*")
exit if ! ofile
open(ofile,"wb"){|f|f.write binary}
