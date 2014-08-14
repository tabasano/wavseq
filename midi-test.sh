#!/bin/bash
ruby midi-simple-make.rb -i sample/midi-test.mml -o test.mid -v 0 -M 2
cmp -l test.mid sample/midi-test.mid
