#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
#
# on vector software library
# http://www.vector.co.jp/soft/dl/winnt/art/se508417.html

DOREMI_STUDY_VERSION="0.1"

Encoding.default_external = 'UTF-8' if defined? Encoding

if ARGV.size<2
  # puts "usage: #{$0} hexStrfile out.mid"
end
mode,inf,of=ARGV[0..2]
inf,of="doremi_blank4.txt","out.mid" if inf==nil
mode="major" if mode==nil
da=(File.readlines(inf).map{|i|i.chomp.sub(/#.*/){}}-[""])*""

def note mode="major"
  c=0x3c
  r=rand(12)
  case mode
  when /^major/
    r=rand(12) while [1,3,6,8,10].member?(r)
  when /^minor/
    r=rand(12) while [1,4,6,9,11].member?(r)
  when /^chro(matic)/
    # r=rand(12)
  end
  "  #{format"%02X",r+c}  "
end
def hex2note n,doremi=true
  note=n.to_i(16)-0x3c
  scale=["c","c#","d","d#","e","f","f#","g","g#","a","a#","b","c"]
  scale=["do","do#","re","re#","mi","fa","fa#","sol","sol#","la","la#","si","do"] if doremi
  scale[note]
end

ans=[]
n=4
n.times{|i|
  s=note(mode)
  ans<<s
  da.gsub!("__sound_#{i+1}__"){s}
}

open(of,"wb"){|o|
  o.write [da.split.join].pack( "H*" )
}
open("ans.txt","w"){|o|
  o.puts ans.map{|i|hex2note(i)}
}