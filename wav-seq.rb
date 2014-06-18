#!/usr/bin/env ruby

require 'rubygems'
require 'wav-file'
require 'optparse'
require 'strscan'


len=400
st=3
seqfile=false
opt = OptionParser.new
opt.on('-l i',"each length") {|v| len=v.to_i }
opt.on('-s i',"start pos") {|v| st=v.to_i }
opt.on('-q i',"sequence file") {|v| seqfile=v }
opt.parse!(ARGV)

def getsubs(data)
  data=data*"" if data.class==Array
  s = StringScanner.new(data)
  tokens = []
  rest=[]
  sub={}
  key=""
  while !s.eos?
    if s.scan(/{([^}]+)}/)
        p 0,s[0]
    	lines=s[1].split("\n")
        sub[key]=lines
        tokens << [lines, :line]
    elsif s.scan(/sub:([^{ \n]+) *\n?/)
        p 1,s[0]
    	tokens << [s[1], :sub]
        key=s[1]
    elsif s.scan(/macro:([^{ \n]+) *\n?/)
        p 2,s[0]
    	tokens << [s[1], :macro]
        rest<<s[0]
    elsif s.scan(/([^{\n]+):([^{ \n]+) *\n?/)
        p 2,s[0]
    	tokens << [s[1],s[2], :text]
        rest<<s[0]
    else  s.scan(/(.+)|\n+/)
        p 3,s[0]
    #    break if ! s[0]
    	tokens << [s[0], :line]
        rest<<s[0] if s[1]
    end
  end
  [sub,rest]
end

class Array
  def currentmax c,len
    self[c..c+len].max
  end
  def avg
    self.inject(0){|s,i|s+i}/self.size
  end
  def aabbcc r,ti
    tmp=[]
    res=[]
    d=self.dup
    while d.size>0
      tmp=[]
      r.times{|i|
        tmp<<d.shift
      }
      tmp=(tmp-[nil])
      tmp=(tmp+tmp.reverse)*ti
      res+=tmp[0..tmp.size/2]
    end
    res
  end
  def rejectmacro
    reject{|i|i=~/^(macro|fraze|block)/}
  end
  def selectmacro
    self-self.rejectmacro
  end
end
def getwavdat file
  format, data = WavFile::read open(file)
  bit = 's*' if format.bitPerSample == 16 # int16_t
  bit = 'c*' if format.bitPerSample == 8 # signed char
  wavs = data.data.unpack(bit)
end

if ARGV.size < 2
  puts "ruby #{$0} input.wav output.wav"
  exit 1
end

in_file = ARGV.shift
out_file = ARGV.shift

format, data = WavFile::read open(in_file)

puts format.to_s

bit = 's*' if format.bitPerSample == 16 # int16_t
bit = 'c*' if format.bitPerSample == 8 # signed char
wavs = data.data.unpack(bit)

#ビット数は 8bit と 16bit
#  8bit ならば符号無し unsigned (0 ～ 255, 無音は 128)
# 16bit ならば符号付き signed (-32768 ～ +32767, 無音は 0)

puts "max of this file: #{wavs.max}"
def fit  n,b
  r=[-32768,[32767,n].min].max if b == 16
  r=[128,n].min if b == 8
  r
end
def load file
  dat=[]
  dat=File.readlines(file)
  dat.map{|i|
    i=~/^# *import:/
    $& ? load($'.chomp) : i
  }.flatten
end
def getseq dat
  li=dat.rejectmacro
  li.map{|i|i.split(",")}
end
def getmacro dat
  macro={}
  li=dat.selectmacro
  li.each{|i|
    i=~/^macro:/
    cm=$'
    cm=~/=/
    macro[$`]=$'.to_i if $&
  }
  macro
end
def setfraze d
  file,st,len=d.split(",")
  getwavdat(file)[st.to_i,st.to_i+len.to_i]
end
def getfraze dat
  fraze={}
  li=dat.selectmacro
  li.each{|i|
    i=~/^fraze:/
    cm=$'
    cm=~/=/
    if $&
      fraze[$`]=setfraze($')
      puts "fraze: #{$`} #{$'}"
    end
  }
  fraze
end
def getblock dat
  blocks={}
  li=dat.selectmacro
  li.each{|i|
    i=~/^block:/
    cm=$'
    cm=~/=/
    blocks[$`]=$'.chomp if $&
  }
  blocks
end
def fileldcalc d
  d=~/((.*):)?(.*)/
  frazename,pos=$2,$3.to_i
  [frazename,pos]
end
def fileldmacro d
  d=~/((.*):)?(.*)/
  frazename,pos=$2,$3
  case frazename
  when"default"
    [frazename,pos]
  when "base"
    [frazename,pos]
  else
    false
  end
end
def poscalc pos,base,hpm=4
  pos=~/(.*):((.*)\.)?(.*)/
  block=$1
  shosetsu=$3
  haku=$4
  res=[block,shosetsu.to_i*hpm+haku] if $&
  res=[nil,pos.to_i] if ! $&
  res
end
def fncalc d
  d=~/(\(reverse\))?(.*)/
  r=[$2,$1]
  r
end
def showdat wavs
  puts "wavs size: #{wavs.size}"
  puts "wavs range: #{wavs.min} #{wavs.max}"
end


##### macro etc.

# # import:file
# macro:start=1234
# macro:base=baseLength
# fraze:frazeName=filemname,startPos,length
# block:name=2345
# (frazeName:)pos(,size,step,times)

showdat wavs
puts"#{st} #{len}"
frazeOrg=wavs[st,len]
music=[0]*wavs.size
all=load(seqfile)
sub,main=getsubs(all)
seq=getseq(main)
macro=getmacro(main)
fraze=getfraze(main)
fraze[nil]=frazeOrg
start=macro["start"] ? macro["start"] : 0
base=macro["base"] ? macro["base"] : 1
hpm=macro["haku"] ? macro["haku"] : 4
blocks=getblock(main)
blocks[nil]=start
p ">>",macro,fraze.keys,blocks
seq.each{|n_pos,size,step,tim,sa|
  r=fileldmacro(n_pos)
  if r
    if r[0]=="default"
      fraze[nil]= r[1]=="reset" ? frazeOrg : fraze[r[1]]
    end
    r[0]=="base" ? base=r[1].to_i : 0
    next
  end 
  fname,pos=fileldcalc(n_pos)
  fn,reverse=fncalc(fname)
  frazetmp=reverse ? fraze[fn].reverse : fraze[fn]
  block,pos=poscalc(pos,base,hpm)
  posb=blocks[block]+pos*base
  size=len if ! size
  size=size.to_i
puts"#{fn} #{start}#{reverse ? "(r)" : ""}: [#{pos}] #{posb} step:#{step ? step.to_i*base : ""} t:#{tim} #{sa}"
  if step && tim
    step=step.to_i*base
    tim=tim.to_i
    sa=sa.to_i
    tim.times{
      size.times{|i|
        music[start+posb+i]+=frazetmp[i] if music[start+posb+i] && frazetmp[i]
      }
      posb+=step
      step-=sa if sa
    }
  else
    size.times{|i|
      music[start+posb+i]+=frazetmp[i] if music[start+posb+i] && frazetmp[i]
    }
  end
}
wavs=music.map{|i|fit(i,format.bitPerSample)}


data.data = wavs.pack(bit)
STDERR.puts"write.."
open(out_file, "wb"){|out|
  WavFile::write(out, format, [data])
}
# p main