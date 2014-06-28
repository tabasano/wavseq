set rb=ruby
%rb% midi-simple-make.rb  -T "" -m 1 -o testmodeGM.mid -t 620 >GM-test-make.txt
%rb% midi-simple-make.rb  -T "" -m 2 -o testmodeXG.mid -t 620 >XG-test-make.txt
%rb% midi-simple-make.rb  -T "" -m 3 -o testmodeGS.mid -t 620 >GS-test-make.txt

%rb% midi-simple-make.rb  -T "" -m 1 -o testmodeGM-slow.mid -t 220
%rb% midi-simple-make.rb  -T "" -m 2 -o testmodeXG-slow.mid -t 220
%rb% midi-simple-make.rb  -T "" -m 3 -o testmodeGS-slow.mid -t 220
