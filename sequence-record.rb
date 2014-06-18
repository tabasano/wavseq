tmp="seq-byseqrec.txt"
tmp=ARGV.shift

def hint
  puts "usage: #{$0} outputfile"
  puts "  make sequence data by series of enter keys. first 3 enters are for make minimum unit span only."
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
    @unit=(self[2]-self[0])/2/480
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
end
unit=ti.unit
p ti,ti.unit,seq=ti.seq,seq.span
open(tmp,"w"){|f|f.puts "# unit=#{unit}",seq*","}
