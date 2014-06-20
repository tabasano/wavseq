#!/usr/bin/ruby
class String
  def trim
    d=split("\n").map{|i|i=~/#.*/;$& ? $`.chomp : i.chomp}*" "
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
def makefraze on,off,rundata
  r=[]
  rundata.split('').each{|i|
    case i
    when /[0-9]/
      (i.to_i-1).times{r<<off}
    when "r"
      r<<off
    when " "
    else
      r<<on[i]
    end
#p i,r
  }
  r*"\n# onoff ==== \n"
end
array = []

d_head="
4D 54 68 64 # ヘッダ
00 00 00 06 # データ長:6[byte]
00 01       # フォーマット:1
00 01       # トラック数:1
00 02       # 1 拍の分解能:
"
d_start="
4D 54 72 6B # トラック 1 開始
"
#00 00 00 1c # データ長: 28[byte] (>> ..  <<)

d_dsize=""

d_tempo="
00 FF 51 03  07 A1 20 #bpm=120, 四分音符の長さをマイクロ秒で3byte
"

d_onenote={
"p"=>"
00 90 3C 40 # 0拍後, オン:ch0, key:3C(ド), vel:40
01 80 3C 00 # 1拍後, オフ:ch0, key:3C
",
"P"=>"
00 90 3D 40 # 0拍後, オン:ch0, key:3C(ド), vel:40
01 80 3D 00 # 1拍後, オフ:ch0, key:3C
",
"d"=>"
00 99 3C 40 # 0拍後, オン:ch10(rythm track), key:3C(ド), vel:40
01 89 3C 00 # 1拍後, オフ:ch10, key:3C
",
"e"=>"
00 99 40 40 # 0拍後, オン:ch10, key:40(ミ), vel:40
01 89 4C 00 # 1拍後, オフ:ch10, key:3C
",
"f"=>"
00 99 43 40 # 0拍後, オン:ch10, key:43(ソ), vel:40
01 89 43 00 # 1拍後, オフ:ch10, key:3C
"}

d_rest="
01  89 3C 00 # 1拍後, オフ:ch10, key:3C
"
d_last=
"
01  89 3C 00 # 1拍後, オフ:ch10, key:3C
"
d_trackend="
00 FF 2F 00 # トラック 1 終了
"

def hint
  puts "usage: #{$0} 'dddd dr3 dddd r4 drdrdrdr dddd dr3' outfile.mid bpm"
  puts "    d=sound, r=rest, num=length, blank ignored"
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

d_data = d_tempo + makefraze(d_onenote,d_rest,rundata) + d_last
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
