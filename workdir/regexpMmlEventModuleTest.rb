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
    :chordStart,
    :chordEnd,
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
  @@h[:chordStart]="\\{"
  @@h[:chordEnd]="\\}"
  @@h[:cmdValSep]=":"
  r=@@keys.map{|i|@@h[i]}*"|"
  Rwc=/#{r}|./
  p Rwc if $DEBUG
  ArgIsOne=%w[bendCent mark p]
  def self.event m
    (@@keys.map{|k|m=~/\A#{@@h[k]}\z/ ? k : nil}-[nil])[0]
  end
  def self.item m
    [self.event(m),m]
  end
  def self.hexitem m
    m=~/([[:digit:]]{2})|(\$[^ ]+)|([, ])/
    if $1
      [:hex,m]
    elsif $2
      [:macro,m]
    elsif $3
      [:hexSep,m]
    else
      [hex?,m]
    end
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
  def mmlscanMap cmd=false
    case cmd
    when *MmlReg::ArgIsOne
      [[:keyname,self]]
    else
      self.mmlscan.map{|m|MmlReg.item(m)}
    end
  end
  def hexscan
    self.scan(/[[:digit:]]{2}|\$[^ ]+|[, ]/)
  end
  def hexscanMap
    self.hexscan.map{|m|MmlReg.hexitem(m)}
  end
  def allEvents
    @events||=self.mmlscan
    @evmap||=@events.map{|i|
      MmlReg.item(i)
    }
    @flattenEvents=@evmap.dup
    r=[]
    endflag=true
    begin
      endflag=true
      @flattenEvents.each{|e,i|
        p [:item,e,i] if $DEBUG
        case e
        when :macrodefA
          i=~/([[:alnum:]]+\([,[:alpha:]]+\):=) *(.+)/
          r<<[:macrodefAStart,$1]
          r<<[:macrodefABody,$2]
          r<<[:macrodefAEnd]
          endflag=false
        when :word
          i=~/\(([^):]*):(.*)\)/
          wcmd=$1
          arg=$2
          r<<[:wordStart]
          r<<[:parenStart,"("]
          r<<[:wordCmd,wcmd]
          r<<[:wordSep,":"]
          r+=arg.mmlscanMap(wcmd)
          r<<[:parenEnd,")"]
          r<<[:wordEnd]
          endflag=false
        when :word?
          i=~/\(([^)]*)\)/
          r<<[:wordStart?]
          r<<[:parenStart,"("]
          r+=$1.mmlscanMap
          r<<[:parenEnd,")"]
          r<<[:wordEnd?]
          endflag=false
        when :chord
          i=~/\{([^)]*)\}/
          if $&
            r<<[:chordStart,"{"]
            r+=$1.mmlscanMap
            r<<[:chordEnd,"}"]
            endflag=false
          else
            r<<[:chord,i]
          end
        when :hexraw
          i=~/&\(([^)]*)\)/
          r<<[:hexrawStart,"&("]
          r+=$1.hexscanMap
          r<<[:hexrawEnd,")"]
          endflag=false
        when :macrodef
          i=~/([[:alnum:]]+:=) */
          r<<[:macrodefStart,$1]
          r+=$'.mmlscanMap
          r<<[:macrodefEnd]
        else
          r<<[e,i]
        end
      }
      @flattenEvents=r
      r=[]
    end until endflag==true
    @flattenEvents
  end
  def mmlEvents
    @ev||=self.allEvents
    @ev.reject{|e,v|[:comment,:blank].member?(e)}
  end
  def nilEvents
    self.mmlEvents
    question=[nil,:note?,:sound?,:word?]
    @flattenEvents.select{|e,v|question.member?(e)}
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
