s="m(x):=tes$xtes2;a*321s;;comment 1;def|||mac:=abcd ef(tes:34);d~f(gh)&(00 11 22)i|||;|||j{kl}; (oi)v++89<b(stroke:1,2,3)(:-).SKIP >`'c23$m(2)_snare!$mac_c!123.$:cmaj7, b45; abc///defg; ;; comment ; "

module MmlReg
  word="\\([^\(\)]*\\)"
  chord="\\{[^\{\}]*\\}|:[[:alnum:]]+,"
  sound="[[:alpha:]]|_[^!]+!|=|~"
  mark="\\.[[:alpha:]\\$]+"
  mod="[`'^><\+\-]"
  sep="\\|\\|\\||\\/\\/\\/"
  time="\\*?[[:digit:]]+"
  hexraw="&\\([^()]*\\)"
  macro="\\$[[:alnum:]\\(\\)]+|\\$\\{[^}]+\\}"
  macrodef="[[:alnum:]\\(\\)]+:=.*"
  Rwc=/#{hexraw}|#{macro}|#{macrodef}|#{word}|#{chord}|#{sound}|#{mark}|#{mod}|#{time}|#{sep}|./
  p Rwc
end
class String
  def trim sep
    self.sub(/#{sep}.*/){}
  end
end
p s
s=s.gsub(";;"){"##"}.gsub(";"){"\n"}.split("\n").map{|i|i.trim("##") }.join("\n")
p s
p s.scan(MmlReg::Rwc)*" ;"


