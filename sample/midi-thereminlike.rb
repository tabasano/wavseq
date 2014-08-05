mml="b(x):=(bend:$x)
  (xg:on)
  (bendRange:127)
  (p:orga)
"
mml<<"r(on:c) ["

t=4
b="$b(*#{t}:"+ [*-819..819].map{|i|(i*10).to_s}*","+")"
mml<<b
b="$b(*#{t/2}:"+ [*-819..819].reverse.map{|i|(i*10).to_s}*","+")"
mml<<b
mml<<"]3"
mml<<"(off:c)rr"  
puts mml