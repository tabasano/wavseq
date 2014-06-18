#!/usr/bin/env ruby
# maximize volume
require 'rubygems'
require 'wav-file'
require 'optparse'

len=400
st=3
seqfile=false
opt = OptionParser.new
opt.on('-l i',"each length") {|v| len=v.to_i }
opt.on('-s i',"start pos") {|v| st=v.to_i }
opt.on('-q i',"sequence file") {|v| seqfile=v }
opt.parse!(ARGV)


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
    reject{|i|i=~/^(macro|fraze)/}
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
def getseq file
  li=File.readlines(file).rejectmacro
  li.map{|i|i.split(",")}
end
def getmacro file
  macro={}
  li=File.readlines(file).selectmacro
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
def getfraze file
  fraze={}
  li=File.readlines(file).selectmacro
  li.each{|i|
    i=~/^fraze:/
    cm=$'
    cm=~/=/
    fraze[$`]=setfraze($') if $&
  }
  fraze
end
def fileldcalc d
  d=~/((.*):)?(.*)/
  frazename,pos=$2,$3.to_i
  [frazename,pos]
end
def fileldmacro d
  d=~/((.*):)?(.*)/
  frazename,pos=$2,$3
  frazename=="default" ? pos : false
end
def showdat wavs
  puts "wavs size: #{wavs.size}"
  puts "wavs range: #{wavs.min} #{wavs.max}"
end
##### macro
# macro:start=1234
# macro:base=baseLength
# fraze:frazeName=filemname,startPos,length
# (frazeName:)pos(,size,step,times)

showdat wavs
puts"#{st} #{len}"
frazeOrg=wavs[st,len]
music=[0]*wavs.size
seq=getseq(seqfile)
macro=getmacro(seqfile)
fraze=getfraze(seqfile)
p macro,fraze.keys
fraze[nil]=frazeOrg
start=macro["start"] ? macro["start"] : 0
seq.each{|field1,size,step,tim,sa|
  r=fileldmacro(field1)
  if r
    fraze[nil]=r=="reset" ? frazeOrg : fraze[r]
    next
  end 
  fn,pos=fileldcalc(field1)
  size=len if ! size
  size=size.to_i
  if step && tim
    step=step.to_i
    tim=tim.to_i
    sa=sa.to_i
    tim.times{
      size.times{|i|
        music[start+pos+i]+=fraze[fn][i] if music[start+pos+i] && fraze[fn][i]
      }
      pos+=step
      step-=sa if sa
    }
  else
    size.times{|i|
      music[start+pos+i]+=fraze[fn][i] if music[start+pos+i] && fraze[fn][i]
    }
  end
}
wavs=music.map{|i|fit(i,format.bitPerSample)}


data.data = wavs.pack(bit)

open(out_file, "wb"){|out|
  WavFile::write(out, format, [data])
}