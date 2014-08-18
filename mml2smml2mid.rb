#!/usr/bin/ruby
# -*- encoding: utf-8 -*-

begin
  require'./lib/smml/msm'
rescue LoadError
  require'smml'
  p Smml::VERSION
end

infile="infile.mml"
outfile="mml.mid"
data=""

opt = OptionParser.new
opt.on('-i file',"input file") {|v| infile=v }
opt.on('-o file',"output file") {|v| outfile=v }
opt.on('-d d',"input data string") {|v| data=v }
opt.parse!(ARGV)

def p *v
  super v if $DEBUG
end

def calclen len,digdef
  htn=0
  if len=~/\.+/
    len=$`.to_i
    len=digdef if len==0
    htn=$&.size
  end
  len=4.0/len.to_i
  baselen=len/2.0
  htn.times{len+=baselen;baselen/=2.0}
  len=len.round if len==len.round
  len="" if len==1
  len
end
memo=%Q(
)

mml=data.size>0 ? data : File.read(infile)
octave=3
digdef=4
smml=""
mml.scan(/([[:alpha:]<>])([#\+\-])?([[:digit:]\.]+)?|@([[:alpha:]]+)|([[:digit:]\.]+)| |/).each{|al,sharp,dig,sname,dig2|
  value=[al,sharp,dig,sname]*""
  len=dig|| digdef
  len=calclen(len,digdef)
  dig2=calclen(dig2,digdef) if dig2
  v=""
  case al
  when ">"
    octave+=1
    v="+"
    p "oct= #{octave} : #{v}"
  when "<"
    octave-=1
    v="-"
    p "oct= #{octave} : #{v}"
  when "O"
    v="(oct:#{dig})"
    p "octave #{dig} : #{v}"
  when "Q"
    v="(gate:#{dig})"
    p "gate #{dig} : #{v}"
  when "P"
    v="(pan:#{dig})"
    p "pan #{dig} : #{v}"
  when "N"
    v="{#{dig}}"
    p "note #{dig}  : #{v}"
  when "T"
    v="(tempo:#{dig})"
    p "tempo #{dig} : #{v}"
  when "V"
    v="(v:#{dig})"
    p "velocity #{dig} : #{v}"
  when "R"
    v="r#{len}"
    p "rest  #{len} : #{v}"
  when nil
    if sname
      v="(p:#{sname})"
      p "sound name #{sname} : #{v}"
    end
  when "a".."g"
    note=al.downcase
    case sharp
    when "#","+"
      note=note.upcase
    when "-"
      note="(-)"+note
    end
    v="#{note}#{len}"
    p "note #{al} #{sharp}  #{len} : #{v}"
  end
  v="#{dig2}" if dig2
  STDERR.puts "[#{value}] undefined?" if v=="" && value.size>0
  smml<<v
}
puts
m=MmlTracks.new
m.data=smml
m.outfile="tes.mid"
m.make
m.save
