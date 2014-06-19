tmp="seq-byseqrec.txt"
tmp=ARGV.shift
ajustlevel=ARGV.shift
ajustpercent=ARGV.shift

def hint
  puts "usage: #{$0} outputfile (ajust-level ajust-percent)"
  puts "  make sequence data by series of enter keys. first 3 enters are for making minimum unit span only."
  puts "  ajust-parameters for quantize"
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
    @unit=((self[2]-self[0])/2/480).round(4)
  end
  def seq
    start=self[3]
    r=[]
    (size-3).times{|i|
      r<<((self[i+3]-start)/@unit).round(0)
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
  def ajust level, rate
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
ajustpercent=ajustpercent ? ajustpercent.to_i : 100
if ajustlevel
  seq=seq.ajust(ajustlevel.to_i, ajustpercent) 
  p seq
end
open(tmp,"w"){|f|f.puts "# unit=#{unit}",seq*","}
