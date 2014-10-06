# hereDoc style repetition test.
#
#  these are all same. default number is 1.
#
#    ($:End)    abc End $1 $1 $1
#    ($:1,End)  abc End $1 $1 $1
#    ($:1<<End) abc End $1 $1 $1

#  another candidate:
#
#    {{abc}} = = =


s="($:RepEndMarkOf1) abcdef RepEndMarkOf1  ($:2<<END2)  a(tes:t())bcd/efd/fg  END2    cc $1 ccc $1 cccc $2 $1 ddd $2"
s=ARGV*"" if ARGV.size>0
mc={}
n=nil
mark=nil
res=[]
r=s.scan(/\(\$:([[:digit:]]*)(<<|[ ,]*)([^)]*)\)|( +)|([^ ]+)/)
# p r
r.map{|a,sep,b,blank,c|
  (n=a;n="1" if a=="";mc[n]="";mark=b) if a
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