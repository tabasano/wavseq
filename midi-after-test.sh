#!/bin/bash
gem install pkg/smml*gem -l
ruby -e 'require"smml"; p Smml::VERSION; m=MmlTracks.new;m.compile("sample/midi-test.mml","gem.mid")'
hexdump gem.mid -C | head -n 7
