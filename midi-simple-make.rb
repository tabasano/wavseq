#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'

# gem
begin
  require'smml'
rescue LoadError
  require'./lib/smml/msm'
end

infile=false
outfile=false
expfile=false
vfuzzy=2
velocity=0x40
$debuglevel=1
data=""
pspl="///"
cmark=";;"
bpm=120
tbase=480 # division
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

mtr=MmlTracks.new(tbase,pspl,expfile,cmark)
mtr.infile=infile
mtr.outfile=outfile
mtr.data=data
mtr.velocity=velocity
mtr.bpm=bpm
mtr.octave=octaveMode
mtr.vfuzzy=vfuzzy
mtr.make($test,$fuzzy)
mtr.save if not $testonly
