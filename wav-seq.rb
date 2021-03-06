#!/usr/bin/env ruby

require 'rubygems'
require 'wav-file'
require 'optparse'
require 'strscan'


len=400
outlen=0
st=3
fuzzy=false
seqfile=false
saveall=savesub=false
opt = OptionParser.new
opt.on('-l i',"each length") {|v| len=v.to_i }
opt.on('-L i',"output length ( sec.)") {|v| outlen=v.to_f }
opt.on('-s i',"start pos") {|v| st=v.to_i }
opt.on('-F f',"fuzzy vol percent") {|v| fuzzy=v.to_f }
opt.on('-c',"check only") {|v| $check=v }
opt.on('-q i',"sequence file") {|v| seqfile=v }
opt.on('-S',"save sub file") {|v| savesub=v }
opt.on('-A',"save all sub file") {|v| saveall=v }
opt.parse!(ARGV)

# sub-sequence file is made by sequence-record.rb
#  ... or simply csv integer values
def readsubseq file
  File.readlines(file).reject{|i|i=~/^#/}
end

def getsubs(data)
  data=data*"" if data.class==Array
  s = StringScanner.new(data)
  tokens = []
  rest=[]
  sub={}
  seq={}
  key=""
  while !s.eos?
    if s.scan(/\{([^}]+)}/)
        p 0,s[0]
    	lines=s[1].split("\n")
        sub[key]=lines
        tokens << [lines, :line]
    elsif s.scan(/sub:([^{ \n]+) *\n?/)
        p 1,s[0]
    	tokens << [s[1], :sub]
        key=s[1]
    elsif s.scan(/seq:([^{ \n]+) *\n?/)
        p 2,s[0]
    	tokens << [s[1], :seq]
        k,v,rate=s[1].split(",").map{|i|i=~/ *([^ ]*)/;$1}
        rate=rate.to_f
        seq[k]=[readsubseq(v),rate]
p [k,v,rate]
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
  [sub,rest,seq]
end

class Array
  def currentmax c,len
    self[c..c+len].max
  end
  def avg
    self.inject(0){|s,i|s+i}/self.size
  end
  def span
    r=[0.0]
    (self.size-1).times{|i|
      r<<(self[i+1]-self[i]).round(3)
    }
    r
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
class WavRaw
  def initialize wav,bps
    @wav=wav
    @bit=16
    @orgbit=bps
    case @orgbit
    when 8
      tr8
    when 16
    else
      false
    end
  end
  def tr8
    @wav=@wav.map{|w|(w-128)*128}
  end
  def rt8
    @wav=@wav.map{|w|w/256-128}.map{|i|fit(i,8)}
  end
  def get
    case @orgbit
    when 8
      rt8
    when 16
      @wav
    else
      false
    end
  end
end
def getwavdat file
  format, data = WavFile::read open(file)
  bit = 's*' if format.bitPerSample == 16 # int16_t
  bit = 'C*' if format.bitPerSample == 8 # unsigned char
  wavs = data.data.unpack(bit)
end

if ARGV.size < 2
  puts "ruby #{$0} input.wav output.wav -q sequence-file"
  exit 1
end

in_file = ARGV.shift
out_file = ARGV.shift

format, data = WavFile::read open(in_file)

puts format.to_s

bit = 's*' if format.bitPerSample == 16 # int16_t
bit = 'C*' if format.bitPerSample == 8 # unsigned char
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
def calcnum n
p n
  case n
  when String
    eval(n)
  when Fixnum
    n
  else
    0
  end
end
def load file
  dat=[]
  dat=File.readlines(file)
  dat.map{|i|
    i=~/^# *import:/
    $& ? load($'.chomp) : i
  }.flatten.reject{|i|i=~/^#/}
end
def getseq dat
  li=dat.rejectmacro
  li.map{|i|i.split(",").map{|i|i=~/^ *([^ ]*)/;$1.size>0 ? $1 : nil}}
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
  p "getblock"
  blocks={}
  li=dat.selectmacro
  li.each{|i|
    i=~/^block:/
    cm=$'
    cm=~/=/
    blocks[$`]=calcnum($') if $&
  }
  blocks
end
def fieldcalc d
  d=~/((.*)@)?(.*)/
  frazename,pos=$2,$3
  [frazename,pos]
end
def fieldmacro d
  d=~/(([^:]*)\((.*)\):)?(.*)/
  mname,seq,pos=$2,$3,$4
  case mname
  when"default"
    [mname,calcnum(pos)]
  when "base"
    [mname,calcnum(pos)]
  when "subseq"
    [mname,[seq,pos]]
  else
    false
  end
end
def poscalc pos,base,hpm=4
  pos=~/(.*):((.*)\.)?(.*)/
  block=$1
  shosetsu=$3
  haku=$4
  res=[block,calcnum(shosetsu)*hpm+calcnum(haku)] if $&
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
# (frazeName:)pos(,size,step,times,sa)

showdat wavs
puts"#{st} #{len}"
frazeOrg=wavs[st,len]
all=load(seqfile)
sub,main,subseq=getsubs(all)
subseqtes={}
subseqspan={}
subseq.each{|k,val|
  v,rate=val
  li=v.map{|s|
    s.split(",").map{|i|
      (calcnum(i)*rate).to_f.round(2)
    }
  }.flatten
  lii=li.map(&:to_i)
  subseqtes[k]=lii
  subseqspan[k]=li.span
  subseq[k]=li
}
p subseq,subseqtes,subseqspan
seq=getseq(main)
macro=getmacro(main)
fraze=getfraze(main)
fraze[nil]=frazeOrg
start=macro["start"] ? macro["start"] : 0
base=macro["base"] ? macro["base"] : 1
hpm=macro["haku"] ? macro["haku"] : 4
blocks=getblock(main)
blocks[nil]=start
p ">>",macro,fraze.keys,blocks.map{|k,v|"#{k}=>#{v}(#{v*base})"}
exit if $check

def subCalc field
  field=~/->/
  [$`,"sub->#{$'}"]
end
def isSub field
  field=~/->/
end
def byvol(t,vol,rand=false)
  r=vol ? (t*(vol.to_i/100.0)).to_i : t
  rate=1
  if rand
    rate=rand
  end
  r*rate
end
def seq2wav seq,env
p seq.size,"start!"
  frazeOrg,fraze,subseq,base,hpm,blocks,start,len,osize,fuzzy=env
  music=[0]*osize
  seq.each{|n_pos,size,step,tim,sa,vol|
    r=fieldmacro(n_pos)
    if r
p ["fieldmacro",r]
      case r[0]
      when "default"
        fraze[nil]= r[1]=="reset" ? frazeOrg : fraze[r[1]]
        next
      when "base" 
        base=r[1].to_i
        next
      when "subseq"
        name,fn_pos=r[1]
        fname,pos=fieldcalc(fn_pos)
p ["subseq",name,fname,pos]
        fn,reverse=fncalc(fname)
        frazetmp=reverse ? fraze[fn].reverse : fraze[fn]
        block,pos=poscalc(pos,base,hpm)
        pos=subseq[name].map{|i|i+pos}
      end
    elsif isSub(n_pos)
      pos,subname=subCalc(n_pos)
      block,pos=poscalc(pos,base,hpm)
      frazetmp=fraze[subname]
    else
      fname,pos=fieldcalc(n_pos)
      fn,reverse=fncalc(fname)
      frazetmp=reverse ? fraze[fn].reverse : fraze[fn]
      block,pos=poscalc(pos,base,hpm)
    end
    poss=[pos].flatten
    poss.each{|pos|
p ["sub",subname||fn,"block",block]
p [n_pos,size,step,tim,sa,vol]
      posb=(blocks[block]+pos)*base
      size=len if ! size || size.size==0
      sizeb=calcnum(size)*base
puts"#{fn} #{start}#{reverse ? "(r)" : ""}: [#{pos}] #{posb} step:#{step ? step.to_i*base : ""} t:#{tim} #{sa}"
      if step && tim
        stepb=calcnum(step)*base
        tim=calcnum(tim)
        sa=sa.to_i*base
        tim.times{
          volrate=false
          volrate=(100-rand(fuzzy))/100.0 if fuzzy
          sizeb.times{|i|
            music[start+posb+i]+=byvol(frazetmp[i],vol,volrate) if music[start+posb+i] && frazetmp[i]
          }
          posb+=stepb
          stepb-=sa if sa
        }
      else
        sizeb.times{|i|
          music[start+posb+i]+=frazetmp[i] if music[start+posb+i] && frazetmp[i]
        }
      end
    }
  }
  music
end

sub.keys.each{|k|
  fraze["sub->#{k}"]=seq2wav(getseq(sub[k]),[frazeOrg,fraze,subseq,base,hpm,{nil=>0},0,len,wavs.size,false]).map{|i|fit(i,format.bitPerSample)}
  p (fraze["sub->#{k}"]-[0]).size
}
oneSecLen=format.channel*format.hz
outlen=outlen*oneSecLen
outlen=wavs.size if outlen==0
music=seq2wav seq,[frazeOrg,fraze,subseq,base,hpm,blocks,start,len,outlen,fuzzy]
wavs=music.map{|i|fit(i,format.bitPerSample)}


data.data = wavs.pack(bit)
STDERR.puts"write.."
p wavs.size
open(out_file, "wb"){|out|
  WavFile::write(out, format, [data])
}

if savesub
  fraze.keys.select{|i|i=~/sub->/}.each{|k|
  p (fraze[k]-[0]).size,fraze[k].size
    data.data=fraze[k].pack(bit)
    k=~/sub->/
    STDERR.puts"write.."
    open(out_file+"-sub#{$'}.wav", "wb"){|out|
      WavFile::write(out, format, [data])
    }
  }
end
if saveall
  (fraze.keys-[nil]).each{|k|
  p (fraze[k]-[0]).size,fraze[k].size
    data.data=fraze[k].pack(bit)
    k=~/sub->/
    k=$' if $&
    STDERR.puts"write.."
    open(out_file+"-sub#{k}.wav", "wb"){|out|
      WavFile::write(out, format, [data])
    }
  }
end
# p main