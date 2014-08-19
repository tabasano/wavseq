#!/bin/bash
ruby midi-simple-make.rb -i sample/midi-test.mml -o test.mid -v 0 -M 2
cmp -l test.mid sample/midi-test.mid
ruby mml2smml2mid.rb -d "A:a2bc dref# ;B: c2de frg8a8a C: ef+# gb" -s > mml2smml.mml
