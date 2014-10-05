s="($:2<<EN)abcdef EN ($:1<<END) a(tes:t())bcd/efd/fg END cc $1 ccc $1 cccc $2 $1 ddd $2"
s=ARGV*"" if ARGV.size>0
mc={}
n=nil
mark=nil
res=[]
r=s.scan(/\(\$:([[:digit:]]+)<<([^)]*)\)|( +)|([^ ]+)/)
# p r
r.map{|a,b,blank,c|
  (n=a;mc[n]="";mark=b) if a
  (res<<mc[n];n=nil) if c && c==mark
  word=(c||blank||"")
  if n
    mc[n]<<word
  end
  if c=~/^\$([[:digit:]]+)/
    res<<(mc[$1]||c)
  elsif ! mark
    res<<word
  else
    # p "? #{word}"
  end
  mark=nil if c==mark
}
puts res*""