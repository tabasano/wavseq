#!/bin/bash
bundle exec ruby ./bin/smml -i sample/midi-test.mml -o test.mid -V -M 2
cmp -l test.mid sample/midi-test.mid
bundle exec ruby ./bin/mmlsmml -d "A:a2bc dref# ;B: c2de frg8a8a C: ef+# gb" -s > mml2smml.mml
