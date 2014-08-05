def t s,root,range,tstep=8
  sa=s.ord-root.ord
  sa=case sa
     when 0,1,2
       sa*2
     when 3,4
       sa*2-1
     when -1,-2
       (4-sa)*2-1
     end
  bend=sa*(8192*2/range)
  r=[]
  ti=tstep
  step=bend/8
  8.times{|i|
    b=step*(i+1)
    r<<"(bend:#{b})(wait:*#{ti})"
  }
  r<<"(bend:#{bend})(wait:*#{ti*8})(bend:#{bend-step})(wait:*#{ti*8})"*((480-ti*16)/ti/16)
  8.times{|i|
    b=bend-step*(i+1)
    r<<"(bend:#{b})(wait:*#{ti})"
  }
  r*""
end

range=12*4
mml="(tempo:60)
  (xg:on)
  (bendRange:#{range})
  (p:orga)
"
mml<<"r(on:c) ["

b="cdeefgeededecccc"
b=b.split("").map{|i|t(i,'c',range)}*""
mml<<b
mml<<"]3"
mml<<"(off:c)rr"  
puts mml
