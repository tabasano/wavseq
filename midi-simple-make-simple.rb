#!/usr/bin/ruby
# -*- encoding: utf-8 -*-
require 'kconv'
require 'optparse'
require './lib/msm'

infile="infile.mml"
outfile="mml.mid"
data=""

opt = OptionParser.new
opt.on('-i file',"input file") {|v| infile=v }
opt.on('-o file',"output file") {|v| outfile=v }
opt.on('-d d',"input data string") {|v| data=v }
opt.parse!(ARGV)

mtr=MmlTracks.new
mtr.compile(infile,outfile,data)
