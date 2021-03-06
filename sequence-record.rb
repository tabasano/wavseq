tmp="seq-byseqrec.txt"
tmp=ARGV.shift
adjustlevel=ARGV.shift
adjustpercent=ARGV.shift

def hint
  puts "usage: #{$0} outputfile (adjust-level adjust-percent)"
  puts "  make sequence data by series of enter keys. first 3 enters are for making minimum unit span only."
  puts "  adjust-parameters for quantize"
  puts "  'q' = quit ( recording end. )"
end

(hint;exit) if ! tmp

ti=[]
while 1
  print"#{ti.size}>"
  k=gets
  break if k=~/^q/
  ti<<Time.now.to_f
end
class Array
  def unit
    @unit=(self[2]-self[0])/2/480.round(5)
  end
  def seq unit=@unit
    start=self[3]
    r=[]
    (size-3).times{|i|
      r<<((self[i+3]-start)/unit).round(0)
    }
    r
  end
  def span
    r=[0.0]
    (self.size-1).times{|i|
      r<<(self[i+1]-self[i]).round(3)
    }
    r
  end
  def adjust level, rate
    level=(level*4.8).to_i
    mid=level/2.0
    self.map{|i|
      a,b=i/level,i%level
      a+=1 if b>mid
      (i*(100-rate)+a*level*rate)/100
    }
  end
end
unit=ti.unit
p ti,ti.unit,seq=ti.seq,seq.span
adjustpercent=adjustpercent ? adjustpercent.to_i : 100
if adjustlevel
  seq=seq.adjust(adjustlevel.to_i, adjustpercent) 
  puts "adjust."
  p seq,seq.span
end
open(tmp,"w"){|f|f.puts "# unit=#{unit}",seq*","}
