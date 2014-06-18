require 'rubygems'
require 'wav-file'

# wav data graph. average and max , for example...

def show wavs,st=0
  puts wavs.size
  puts"max: #{wavs.max}"
  puts"min: #{wavs.min}"
  r=[]
  st=st.to_i
  en=wavs.size
  span=wavs.size/100
  ((en-st)/span).times{|i|
    fr=st+i*span
    to=fr+span
    r<<wavs[fr..to].inject(0){|s,c|s+c.abs}/span
    r<<[wavs[fr..to].max,wavs[fr..to].min].map{|i|i.abs}.max
  }
  p r
  max=r.max
  puts r.map{|i|"*"*(i*80/max)}
  puts
end
st=0
ARGV.each{|file|
  puts"file: #{file}\n\n"
  f = open(file)
  format = WavFile::readFormat(f)
  dataChunk = WavFile::readDataChunk(f)
  f.close

  puts format

  bit = 's*' if format.bitPerSample == 16 # int16_t
  bit = 'c*' if format.bitPerSample == 8 # signed char
  wavs = dataChunk.data.unpack(bit) # read binary

  show wavs,st
}