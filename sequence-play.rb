ti=[]
tmp="seq-byseqrec.txt"
tmp=ARGV.shift
exit if ! tmp

li=File.readlines(tmp)
li[0]=~/^# *unit *= *(.*)/

unit=$1.to_f
seq=li[1].split(",").map{|i|i.to_i}
ti=seq.map{|i|i*unit}
p unit,ti
st=Time.now.to_f
co=0
ti.each{|i|
  w=st+i
  sleep 0.001 while w-Time.now.to_f>0
  puts"#{co}>"
  co+=1
}