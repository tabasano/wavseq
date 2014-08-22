#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'

# gem
begin
  require'./lib/smml/msm'
rescue LoadError
  require'smml'
end

infile="infile.mml"
outfile="mml.mid"
data=""

opt = OptionParser.new
opt.on('-i file',"input file") {|v| infile=v }
opt.on('-o file',"output file") {|v| outfile=v }
opt.on('-d d',"input data string") {|v| data=v }
opt.parse!(ARGV)

m=Smml.new
m.compile(infile,outfile,data)
