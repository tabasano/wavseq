require'pp'

# valid words check only. not valid sequence check.
s="Bo?m(x):=tes$xtes2 ; a*321s;;comment 1 ; macro MU:=( ; test ; test2 ; ) ;
   ; def$MU[2]|||macro mac:=abcd ef(tes:34) ; (+2)d~f(gh)&(00 11 22)i$m(1)||| ; |||j{kl}{m,n}{70} ; (oi)ab[cd]4 /3:ef/ gv++89<b(stroke:1,2,3)(:-).SKIP >`'c23$m(2)_snare!$mac_c!123.$:cmaj7, b45 ; a+b-c///de(0)fG ; ;; comment ; &($se(f0,00))
   ,:)((12: n(x,y):=( ; N:=( ; ;; this line includes not valid sequence words, for test only."
s=File.read(ARGV[0]) if ARGV.size>0

# todo: multiline macro, nest parenthesis
module MmlReg
  @@h={} # mml regex key hash. order is in @@keys
  @@keys=[
    :comment,
    :keyword,
    :macrodefAStart,
    :macrodefA,
    :macrodefStart,
    :macrodef,
    :hexraw,
    :hexrawStart,
    :tSep,
    :pSep,
    :multipletStart,
    :multipletmark,
    :macroA,
    :macro,
    :repStart,
    :repEnd,
    :word,
    :sharps,
    :wordStart,
    :word?,
    :chord,
    :velocity,
    :sound,
    :DCmark,
    :mod,
    :octave,
    :num,
    :blank,
    :valueSep,
    :parenStart,
    :parenEnd,
    :cmdValSep,
    :note,
    :dummyNote,
    :randNote,
    :note?,
    :sound?,
  ]
  @@h[:comment]="\\( *comment[^\(\)]*\\)"
  @@h[:word]="\\([^\(\):]*:[^\(\)]*\\)"
  @@h[:wordStart]="\\([^\(\):]*:"
  @@h[:sharps]="\\([+-]*[[:digit:]]*\\)"
  @@h[:word?]="\\([^\(\)]*\\)"
  @@h[:chord]="\\{[^\{\}]+,[^\{\},]+\\}|:[[:alpha:]][[:alnum:]]*,"
  @@h[:velocity]="v"
  @@h[:note]="[abcdefgACDFGr]|\\{[[:digit:]]+\\}"
  @@h[:note?]="[BE]"
  @@h[:dummyNote]="o"
  @@h[:randNote]="\\?"
  @@h[:sound]="_[^!]+!|=|~"
  @@h[:sound?]="[[:alpha:]]"
  @@h[:DCmark]="\\.\\$|\\.[[:alpha:]]+"
  @@h[:mod]="[`'^><]"
  @@h[:octave]="[+-][[:digit:]]*"
  @@h[:tSep]="\\|\\|\\|"
  @@h[:pSep]="\\/\\/\\/+"
  @@h[:repStart]="\\["
  @@h[:repEnd]="\\]"
  @@h[:multipletStart]="\\/\\*?[[:digit:]\\.]*:"
  @@h[:multipletmark]="\\/"
  @@h[:num]="[[:digit:]]+\\.[[:digit:]]+|[[:digit:]]+|\\*?[[:digit:]]+"
  @@h[:hexraw]="&\\([^()]*\\)"
  @@h[:hexrawStart]="&\\("
  @@h[:keyword]="macro +"
  @@h[:macroA]="\\$\\{[^}]+\\}\\[[[:digit:]]+\\]|\\$[^}\\(\\)]+\\[[[:digit:]]+\\]"
  @@h[:macro]="\\$[[:alnum:]]+\\([^)]*\\)|\\$[[:alnum:]]+|\\$\\{[^}]+\\}"
  @@h[:macrodefAStart]="[[:alnum:]]+\\([,[:alpha:]]+\\):=\\(\\z"
  @@h[:macrodefA]=     "[[:alnum:]]+\\([,[:alpha:]]+\\):= *.+"
  @@h[:macrodefStart]="[[:alnum:]]+:=\\(\\z"
  @@h[:macrodef]=     "[[:alnum:]]+:= *.+"
  @@h[:blank]="[[:blank:]]+"
  @@h[:valueSep]=","
  @@h[:parenStart]="\\("
  @@h[:parenEnd]="\\)"
  @@h[:cmdValSep]=":"
  r=@@keys.map{|i|@@h[i]}*"|"
  Rwc=/#{r}|./
  p Rwc if $DEBUG
  def self.event m
    (@@keys.map{|k|m=~/\A#{@@h[k]}\z/ ? k : nil}-[nil])[0]
  end
  def self.keyAll
    @@keys
  end
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
        self.sub!(/.*/){"(comment end:#{comment.subp})"}
      else
        @@trimmulti=$&.size
        self.sub!(/.*/){"(comment start:#{comment.subp})"}
      end
    elsif @@trimmulti>0
      self.sub!(/.*/){"(comment:#{self.subp})"}
    else
      self.sub!(/#{sep}.*/){"(comment:#{$&.subp})" if $&}
    end
    self
  end
  def mmlscan
    @events=self.scan(MmlReg::Rwc).map{|i|
      case i
      when /^\/\/\/+/
        "///"
      else
        i
      end
    }
  end
  def allEvents
    @events||=self.mmlscan
    @evmap||=@events.map{|i|
      [MmlReg.event(i),i]
    }
  end
  def mmlEvents
    @ev||=self.allEvents
    @ev.reject{|e,v|[:comment,:blank].member?(e)}
  end
  def nilEvents
    @evmap||=self.mmlEvents
    question=[nil,:note?,:sound?,:word?]
    @evmap.select{|e,v|question.member?(e)}
  end
  def notusedEvents
    @events||=self.mmlscan
    MmlReg::keyAll-@evmap.map{|k,v|k}
  end
end
s=s.gsub(/\n/m){" ; "}.gsub(";;"){"##"}.split(" ; ").map{|i|i.trim("##") }.join("\n")
p s
# m=s.mmlscan
# p m*" ;; "
pp s.mmlEvents
puts
n=s.nilEvents
if n.size>0
  p n
  puts " syntax warning."
else
  puts " seems to be no bad word."
end
test = ($DEBUG || ARGV.size==0)
if test
  r=s.notusedEvents
  p r,"=not used." if r.size>0
end
