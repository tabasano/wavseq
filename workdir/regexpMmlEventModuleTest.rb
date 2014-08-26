s="m(x):=tes$xtes2;a*321s;;comment 1;def|||mac:=abcd ef(tes:34);d~f(gh)&(00 11 22)i|||;|||j{kl}; (oi)ab[cd]4 /3:ef/ gv++89<b(stroke:1,2,3)(:-).SKIP >`'c23$m(2)_snare!$mac_c!123.$:cmaj7, b45; abc///defg; ;; comment ; "
s=File.read(ARGV[0]) if ARGV.size>0

# todo: multiline macro
module MmlReg
  word="\\([^\(\)]*\\)"
  chord="\\{[^\{\}]*\\}|:[[:alnum:]]+,"
  sound="[[:alpha:]]|_[^!]+!|=|~"
  mark="\\.[[:alpha:]\\$]+"
  mod="[`'^><\+\-]"
  sep="\\|\\|\\||\\/\\/\\/+"
  repmark="\\/\\*?[[:digit:]\.]+?:|\\/|\\[|\\]"
  time="\\*?[[:digit:]\.]+"
  hexraw="&\\([^()]*\\)"
  keyword="^macro +"
  macro="\\$[[:alnum:]\\(\\)]+|\\$\\{[^}]+\\}"
  macrodef="[[:alnum:]\\(\\)]+:=.*"
  Rwc=/#{keyword}|#{macrodef}|#{hexraw}|#{repmark}|#{macro}|#{word}|#{chord}|#{sound}|#{mark}|#{mod}|#{time}|./
  p Rwc
end
class String
  @@trimmulti=0
  def subp
    self.gsub(/[\(\);:'"]/){'_'}.chomp
  end
  def trim sep
    self=~/^#{sep}+/
    comment=$'
    if $& && $&.size>3 && $&.size>=@@trimmulti
      if @@trimmulti>0
        @@trimmulti=0
        self.sub!(/.*/){"(com end:#{comment.subp})"}
      else
        @@trimmulti=$&.size
        self.sub!(/.*/){"(com start:#{comment.subp})"}
      end
    elsif @@trimmulti>0
      self.sub!(/.*/){"(com:#{self.subp})"}
    else
      self.sub!(/#{sep}.*/){"(com:#{self.subp})"}
    end
    self
  end
end
p s
s=s.gsub(/\n/m){" ; "}.gsub(";;"){"##"}.split(" ; ").map{|i|i.trim("##") }.join("\n")
p s
p s.scan(MmlReg::Rwc).map{|i|i=~/^\/\/\/+$/ ? "///" : i }*" ;; "


