def dump dat
  c=0
  dat.each_byte{|i|
    print format("%02x",i)," "
    c+=1
    puts if c%16==0
  }
end
def dumpsysex dat
  c=0
  start=false
  size=0
  pos=0
  dat.each_byte{|i|
    d=format("%02X",i)
    if start
      size=i
      print "\n[big sysEx?] " if size>0x7f
      start=false
    else
      size-=1
    end
    if d=="F0"
      print "\n[sysEx?] "
      size=1
      start=true
    end
    print d," "
    c+=1
    print format("\n%06X: ",c) if (c%16==0 && size<0) || size==0
  }
end

dat=open(ARGV[0],"rb"){|f|f.read}

dumpsysex(dat)