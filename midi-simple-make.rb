#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'
require './lib/msm'

def hint
  cmd=File.basename($0)
  puts <<EOF
usage: #{cmd} -d \"dddd dr3 dddd r4 drdrdrdr dddd dr3\" -o outfile.mid -t bpm
       #{cmd} -i infile.txt  -o outfile.mid -t bpm

EOF
end

infile=false
outfile=false
expfile=false
title=""
vfuzzy=2
$debuglevel=1
data=""
pspl="///"
cmark=";;"
bpm=120
octaveMode=:near
opt = OptionParser.new
opt.on('-i file',"input file") {|v| infile=v }
opt.on('-o file',"output file") {|v| outfile=v }
opt.on('-e file',"write down macro etc. expanded data") {|v| expfile=v }
opt.on('-d d',"input data string") {|v|
  data=v
  STDERR.puts data if $DEBUG
}
opt.on('-D',"debug") {|v| $DEBUG=v }
opt.on('-s',"show syntax") {|v|
  hint
  exit
}
opt.on('-t b',"bpm") {|v| bpm=v.to_f }
opt.on('-T w',"programChange test like instrument name '...'") {|v| $test=v }
opt.on('-c d',"cycle data for test mode") {|v| $testdata=v }
opt.on('-C d',"comment mark") {|v| cmark=v; puts "comment mark is '#{cmark}'" }
opt.on('-p pspl',"page split chars") {|v| pspl=v }
opt.on('-F i',"fuzzy shift mode") {|v| $fuzzy=v.to_i }
opt.on('-v i',"velocity fuzzy value [default 2]") {|v| vfuzzy=v.to_i }
opt.on('-O',"octave legacy mode") {|v| octaveMode=:far }
opt.on('-I',"ignore roland check sum") {|v| $ignoreChecksum=v }
opt.on('-M i',"debug level") {|v| $debuglevel=v.to_i }
opt.on('-m i',"mode of test/ 1:GM 2:XG 3:GS") {|v| $testmode=v.to_i }
opt.on('-n',"test only (dont write outfile)") {|v| $testonly=true }
opt.parse!(ARGV)
String.new.setcmark(cmark)


title,midifilename=name2title(infile)
data=File.read(infile).trim(" ;") if infile && File.exist?(infile)
outfile=midifilename if ! outfile

(hint;midihint;exit) if (! data || ! outfile ) && ! $test

data=data.toutf8

tbase=480 # division
mx=MidiHex
mx.prepare(tbase,0x40,octaveMode,vfuzzy)
data=mx.test($testdata,$testmode) if $test

if $fuzzy && (tbase/$fuzzy<8)
  STDERR.puts "really?#{"?"*(8*$fuzzy/tbase)}"
end
class MmlTracks
  attr_accessor :tracknum, :tbase, :rundatas, :rawdatas
  def initialize data,tbase,pagesep,expfile
    @rundatas=[]
    @rawdatas=[]
    @macro={}
    @tbase=tbase
    @tracks=data.tracks(pagesep)
    @fuzzymode=false
    @fuzz=false
    @expfile=expfile
  end
  def fuzzy f
    @fuzzymode=f
    @fuzz=unirand(f,tracks.size) if f
  end
  def showtracks
    p @tracks
  end
  def macro
    @tracks.map{|track|
      m,track=macroDef(track)
      @macro.merge!(m)
      track=modifierComp(track,@macro)
      repCalc(track,@macro,tbase)
    }.each{|t|
      r=loadCalc(t)
      if @fuzzymode
        n=@fuzz.shift
        STDERR.puts "track shift: #{n} tick#{n>1 ? 's' : ''}"
        pre="r*#{n} "
      else
        pre=""
      end
      case r[0]
      when :raw
        @rawdatas<<r[1]
      when :seq
        @rundatas<<pre+r[1]
      end
    }
    p @macro if$DEBUG
    @rawdatas.flatten!
    open(@expfile,"w"){|f|f.puts @rundatas*"|||"} if @expfile
    @tracknum=@rawdatas.size+@rundatas.size
    @tracknum=@tracks.size
  end
end
class HexTracks
  def initialize
    #@tc=0
    @tracks=[]
  end
  def add t
    @tracks<<t
    #@tc+=1
  end
  def pack header,mx
    alla=[header]+@tracks.map{|t|mx.trackMake(t)}.flatten
    puts alla if $DEBUG
    all=alla.map{|i|i.trim("","#")}*""
    array=[all.split.join]
    @binary = array.pack( "H*" )
  end
  def save outfile,raws
    # save data. data = MIDI-header + seq-made MIDI-tracks + loaded extra MIDI-tracks.
    if outfile==""
      print @binary
      raws.each{|i|
        print i
      }
    else
      open(outfile,"wb"){|f|
        f.write @binary
        raws.each{|i|
          f.write i
        }
      }
    end
  end
end

mtr=MmlTracks.new(data,tbase,pspl,expfile)
mtr.fuzzy($fuzzy)
mtr.showtracks if $DEBUG && $debuglevel>1
mtr.macro

format=1
d_header=mx.header(format, mtr.tracknum, mtr.tbase) 
tc=0
d_last=mx.metaText("data end",tbase)
# remember starting position check if data exist before sound
ht=HexTracks.new
ht.add( mx.metaTitle(title) + mx.generaterText + mx.tempo(bpm).data + mx.makefraze(mtr.rundatas[0],tc) + d_last )
mtr.rundatas[1..-1].each{|track|
  tc+=1
  ht.add( mx.restHex + mx.makefraze(track,tc) + d_last )
}
ht.pack(d_header,mx)
ht.save(outfile,mtr.rawdatas) if not $testonly
