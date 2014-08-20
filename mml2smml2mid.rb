#!/usr/bin/ruby
# -*- encoding: utf-8 -*-

begin
  require'./lib/smml/msm'
rescue LoadError
  require'smml'
  p Smml::VERSION
end

def help
  puts %Q(
  ARGS:
    -i infile.mml -o outfile.mid 
  or
    -d "MML data" -o outfile.mid
  for dump smml
    -s

  syntax:
    A: a2bc dref => track A, MML data
    B: c2de frga => track B, MML data

    #  comment
    +- sharp,flat
    []3 repeat 3 times
  )
end

infile="infile.mml"
outfile="mml.mid"
data=""

opt = OptionParser.new
opt.on('-i file',"input file") {|v| infile=v }
opt.on('-o file',"output file") {|v| outfile=v }
opt.on('-s',"dump smml data") {|v| $smmlshow=v }
opt.on('-d d',"input data string") {|v| data=v }
opt.on('-h',"help") {|v|
  help
}
opt.parse!(ARGV)

def p *v
  super v if $DEBUG
end

def calclen len,digdef,last
  if last == :sound
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
  end
  len
end
def mml2smml data
  tracks={}
  tr=0
  last=:no
  lines=data.split("\n")
  lines.each{|mml|
    octave=3
    digdef=4
    mml.scan(/([[:alpha:]]):|([[:alpha:]<>])([#\+\-])?([[:digit:]\.]+)?|@([[:alpha:]]+|[[:digit:]]+)|([[:digit:]\.]+)|([\[\]])| |/).each{|tname,al,sharp,dig,sname,dig2,same|
      valueAr=[tname,al,sharp,dig,sname,dig2,same]
      value=valueAr*""
      (tr=tname;next) if tname
      len=dig|| digdef
      len=calclen(len,digdef,:sound)
      dig2=calclen(dig2,digdef,last) if dig2
      last=:no
      v=""
      case al ? al.upcase : al
      when ">"
        octave+=1
        v="+"
        p "oct= #{octave} : #{v}"
      when "<"
        octave-=1
        v="-"
        p "oct= #{octave} : #{v}"
      when "L"
        digdef=dig
        p "defaault length : #{dig}"
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
        last=:sound
      when nil
        if sname
          v="(p:#{sname})"
          p "sound name #{sname} : #{v}"
        elsif same
          v=same
          p "same : #{v}"
        end
      when "A".."G"
        note=al.downcase
        case sharp
        when "#","+"
          note=note.upcase
        when "-"
          note="(-)"+note
        end
        v="#{note}#{len}"
        p "note #{al} #{sharp}  #{len} : #{v}"
        last=:sound
      end
      v="#{dig2}" if dig2
      STDERR.puts "[#{value}] undefined?" if v=="" && value.size>0
      if tracks[tr]
        tracks[tr]<<v
      else
        tracks[tr]=v
      end
    }
  }
  tracks.keys.sort.map{|k|tracks[k]}*"\n|||\n"
end

m=MmlTracks.new
puts
data=data.size>0 ? data.split(';')*"\n" : (File.read(infile) rescue help)
p data
data=data.split("\n").map{|i|i.commentoff("\n",'#')}*"\n"
p data
smml=mml2smml(data)
puts smml if $smmlshow || $DEBUG
m.octave=:far
m.data=smml
m.outfile=outfile
m.make
m.save
