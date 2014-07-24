def markOld i, t="{#{i}}",r='r'
  h=i/16
  l=i%16
  lh=l/4
  ll=l%4
  h="/2:#{t*h}#{r*(8-h)}/"
  l="/2:#{t*ll}#{r*(4-ll)}#{t*lh}#{r*(4-lh)}/"
  h+l
end
def mark i,b,t,r="r"
  a=b.map{|i| i ? r : t }*""
  "/2:#{a}/\n"
end
def num2bits n
  format("%08b",n).split('').map{|i|i=="1"}
end
fraze="/4:r2c2{e,g}2cAr8/"
drch="(ch:drum)"

128.times{|i|
  dr=""
  dr<<"\n{#{i}}r/2:r{#{i}}{#{i}}2/"
  bits=num2bits(i)
  dr<<mark(i,bits,"{c,e,g}","{#{i}}")*2
  drch<<dr
}

ch1="(tempo:100)(p:guit)(stroke:-10)(g:80)"
128.times{|i|
  f=""
  f<<fraze
  bits=num2bits(i)
  f<<mark(i,bits,"{f,+c,+f,++c,++D,+++c}")*2
  ch1<<f
}

puts ch1+"\n|||\n"+drch
