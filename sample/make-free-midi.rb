s=""
100.times{|i|
  len=rand((rand(3)+1)*480)
  s<<"?*#{len}"
}
s<<"|||(ch:drum)"
100.times{|i|
  len=rand((rand(3)+1)*480)
  s<<"?*#{len}"
}
puts s
