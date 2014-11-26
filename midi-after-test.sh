#!/bin/bash
gem install pkg/smml*gem -l
ruby -rubygems -e 'require"smml"; p Smml::VERSION; m=Smml.new;m.compile("sample/midi-test.mml","gem.mid")'
cat mml2smml.mml
hexdump gem.mid -C | head -n 7
ruby -rubygems workdir/regexpMmlEventModuleTest.rb
cd doremi
ruby -r ./hex2midi -e "puts DOREMI_STUDY_VERSION, File.read('ans.txt')"
