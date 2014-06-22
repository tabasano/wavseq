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
  r=t.split('').map{|i|format"%02x",i.ord}
  size=r.size
  [r*" ",varlenHex(size)]
end

module Mid
  def self.header format,track,size
    format=[format,0xff].min
    track=[track,0xff].min
    size=[size,0xffff].min
    format=format("%02x",format)
    track=format("%02x",track)
    size=format("%04x",size)
    "
      4D 54 68 64  # ヘッダ
      00 00 00 06  # データ長:6[byte]
      00 #{format} # フォーマット
      00 #{track}  # トラック数
      #{size}      # 1 拍の分解能
    "
  end
  def self.oneNote len=480,key=0x3C,velocity=40,ch=0
    ch=[ch,0x0f].min
    velocity=[velocity,0x7f].min
    key=[key,0x7f].min
    key=format("%02x",key)
    ch=format("%01x",ch)
    velocity=format("%02x",velocity)
    delta=varlenHex(len)
    str="
      00 9#{ch} #{key} #{velocity} # 0拍後, soundオン...
      #{delta} 80 #{key} 00 # delta後, soundオフ
    "
  end
  def self.notekey key
    @set||=[480,40,0]
    len,velocity,ch=@set
    if key.class==Fixnum
      self.oneNote(len,@basekey+key,velocity,ch)
    else
      key,ch=key
      self.oneNote(len,@basekey+key,velocity,ch)
    end
  end
  def self.notes c
    @rythmtrack||=9
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
      "t"=>[0,@rythmtrack],
      "s"=>[3,@rythmtrack],
      "u"=>[6,@rythmtrack]
    }
    notekey(@notes[c])
  end
  def self.rest len=480
    delta=varlenHex(len)
    "
      #{delta}  89 3C 00 # 1拍後, オフ:ch10, key:3C
    "
  end
  def self.makefraze rundata
    r=[]
    @basekey||=0x3C
    rundata.scan(/[0-9]+|[-+a-zA-Z]/).each{|i|
      case i
      when /-/
        @basekey-=12
      when /\+/
        @basekey+=12
      when /[0-9]+/
        (i.to_i-1).times{r<<r[-1]}
      when "r"
        r<<self.rest
      when " "
      else
        r<<self.notes(i)
      end
    }
    r*"\n# onoff ==== \n"
  end
end

array = []

d_head=Mid.header(1,1,480)

delta=varlenHex(480)
p "deltaTime: 0x#{delta}"
d_start="
4D 54 72 6B # トラック 1 開始
"
d_dsize=""

comment="by midi-simple-make.rb"
commenthex,len=txt2hex(comment)
d_comment="
00 FF 01 #{len} #{commenthex}
"
d_tempo="
00 FF 51 03  07 A1 20 #bpm=120, 四分音符の長さをマイクロ秒で3byte
"
d_last=
"
#{delta}  89 3C 00 # 1拍後, オフ:ch10, key:3C
"
d_trackend="
00 FF 2F 00 # トラック 1 終了
"

def hint
  puts "usage: #{$0} 'dddd dr3 dddd r4 drdrdrdr dddd dr3' outfile.mid bpm"
  puts "    abcdefg=sound, +-=octave change, r=rest, num=length, blank ignored"
end
def makebpm bpm
  d="000000"+(60_000_000/bpm.to_f).to_i.to_s(16)
  d[-6..-1]
end
rundata,ofile,bpm = ARGV
(hint;exit) if ! rundata

bpm=120 if ! bpm
d_bpm=makebpm(bpm)

d_tempo="
00 FF 51 03 #{d_bpm} # 四分音符の長さをマイクロ秒で3byte
"

d_data = d_comment + d_tempo + Mid.makefraze(rundata) + d_last
d_dsize=sizemake(d_data)
#p d_dsize
alla=[d_head,d_start,d_dsize,d_data,d_trackend]
all=alla.map(&:trim)*""
array=[all.split.join]
#puts alla,all,array
binary = array.pack( "H*" )
#p binary.unpack("H*")
exit if ! ofile
open(ofile,"wb"){|f|f.write binary}
