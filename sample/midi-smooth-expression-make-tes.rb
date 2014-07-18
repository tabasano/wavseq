
def sinw n,len,center=n/2,cy=2.0
  cy=cy.to_f
  [*0..len].map{|i| (Math::sin(i/cy)*n+center).round}
end

len=300
ws=[]
ws<<sinw(22,len,100,0.7)
ws<<sinw(12,len,80,4.5)
ws<<sinw(63,len,63,2.5)
ws<<sinw(8000,len,0,2.5)
ws<<sinw(36,len,80,1.1)

d="(ch:0)\n(p:orga)v120\n[d2e2f2g2-c2d2e2f2g2-c2]12\n\n|||\n(ch:0)\n["
ws[0].each{|i|
  d<<"(cc:11,#{i},14)"
}
ws[0].each{|i|
  d<<"(cc:11,#{i},8)"
}
ws[0].each{|i|
  d<<"(cc:11,#{i},20)"
}
d<<"]4rrr\n\n|||\n(ch:1)\n(pan:>0)++(p:flut)r*2v50\n(on:e)["
ws[3].each{|i|
  d<<"(bend:#{i})(wait:*40)"
}
ws[4].each{|i|
  d<<"(bend:#{-100+i*60})(wait:*30)"
}
ws[4].each{|i|
  d<<"(bend:#{-100+i*60})(wait:*50)"
}
d<<"]4(off:e)rrr\n\n|||\n(ch:0)\nr["
r=1.0
ws[2].each{|i|
  t=(230*r+2).to_i
  d<<"(pan:#{i})(wait:*#{t})"
  r=r*0.98
}
d<<"]3\n"
puts d
