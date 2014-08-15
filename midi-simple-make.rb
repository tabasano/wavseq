#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'
require './lib/msm'


infile=false
outfile=false
expfile=false
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

(hint;exit) if (! data || ! outfile ) && ! $test

data=data.toutf8

tbase=480 # division
mx=MidiHex
mx.prepare(tbase,0x40,octaveMode,vfuzzy)
data=mx.test($testdata,$testmode) if $test

if $fuzzy && (tbase/$fuzzy<8)
  STDERR.puts "really?#{"?"*(8*$fuzzy/tbase)}"
end

mtr=MmlTracks.new(data,tbase,pspl,expfile)
mtr.fuzzy($fuzzy)
mtr.showtracks if $DEBUG && $debuglevel>1
mtr.macro

tc=0
# remember starting position check if data exist before sound
ht=HexTracks.new
ht.add( mx.metaTitle(title) + mx.generaterText + mx.tempo(bpm).data + mx.makefraze(mtr.rundatas[0],tc) + mx.lastrest )
mtr.rundatas[1..-1].each{|track|
  tc+=1
  ht.add( mx.restHex + mx.makefraze(track,tc) + mx.lastrest )
}
ht.pack(mx.header(1, mtr.tracknum, mtr.tbase),mx)
ht.save(outfile,mtr.rawdatas) if not $testonly
