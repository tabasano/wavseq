#!/bin/bash
ruby midi-simple-make.rb -i sample/midi-test.mml -o test.mid
cmp test.mid sample/midi-test.mid
