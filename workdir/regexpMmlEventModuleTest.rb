require'pp'
require 'smml'

# valid words check only. not valid sequence check.
s="(gm:on)rrBo?;m(x):=tes$xtes2 ; a*321s;;comment 1 ; macro MU:=( ; test ; test2 ; ) ;
   ; def$MU[2]|||macro mac:=abcd ef(tes:34) ; (+2)d~f(text:wai wai)(gh)&(00 11 22 $bar)i$m(1)||| ; |||j{kl}{m,n}{70} ; (oi)ab[cd]4 /3:ef/ gv++89<b(stroke:1,2,3)(:-).SKIP >`'c23$m(2)_snare!$mac_c!123.$:cmaj7, b45 ; a+b-c///de(0)fG ; ;; comment ; &($se(f0,00))
   $Ab[$e]${B}[3]$abc[2]${def}[3,$we,5]$asdf$asdfghjkl(20:2,3,4)(G:,,-)
   ,:)((12: n(x,y):=( ; N:=( ; ;; this line includes not valid sequence words, for test only."

if ARGV.size>0
  if File.exist?(ARGV[0])
    s=File.read(ARGV[0])
  else
    s=ARGV[0]
  end
end

# todo: multiline macro, nest parenthesis
module MmlRegOld
  def self.r key, sort=true
    case key
    when Array
      ks=key
      ks=(@@keys-(@@keys-ks)) if sort
      ks.map{|i|@@h[i]}*"|"
    else
      @@h[key]
    end
  end
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
    :plusMinus,
    :lineSep,
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
  @@h[:octave]=   "[+-][[:digit:]]*"
  @@h[:plusMinus]="[+-][[:digit:]]*"
  @@h[:tSep]="\\|\\|\\|"
  @@h[:pSep]="\\/\\/\\/+"
  @@h[:repStart]="\\["
  @@h[:repEnd]="\\]"
  @@h[:multipletStart]="\\/\\*?[[:digit:]\\.]*:"
  @@h[:multipletmark]="\\/"
  @@h[:num]="[-+]?[[:digit:]]+\\.[[:digit:]]+|[-+]?[[:digit:]]+|\\*?[[:digit:]]+"
  @@h[:hexraw]="&\\([^()]*\\)"
  @@h[:hexrawStart]="&\\("
  @@h[:keyword]="macro +"
  @@h[:macroA]="\\$\\{[^}]+\\}\\[[^\\]]+\\]|\\$[^}\\$\\{\\(\\)]+\\[[^\\]]+\\]"
  @@h[:macro]="\\$[[:alnum:]]+\\([^)]*\\)|\\$[[:alnum:]]+|\\$\\{[^}]+\\}"
  @@h[:macrodefAStart]="[[:alnum:]]+\\([,[:alpha:]]+\\):= *\\( *\\z"
  @@h[:macrodefA]=     "[[:alnum:]]+\\([,[:alpha:]]+\\):= *[^\\n]+"
  @@h[:macrodefStart]="[[:alnum:]]+:= *\\( *\\z"
  @@h[:macrodef]=     "[[:alnum:]]+:= *[^\\n]+"
  @@h[:blank]="[[:blank:]]+"
  @@h[:valueSep]=","
  @@h[:parenStart]="\\("
  @@h[:parenEnd]="\\)"
  @@h[:chordStart]="\\{"
  @@h[:chordEnd]="\\}"
  @@h[:cmdValSep]=":"
  @@h[:lineSep]=";"
  r=self.r(@@keys)
  RwAll=/#{r}|./
  MacroDef=self.r([:macrodefAStart,:macrodefStart,:macrodefA,:macrodef])
  ArgIsOne=%w[ bendCent mark p gm gs xg loadf text ]
  def self.event m,rest=[]
    ((@@keys-rest).map{|k|m=~/\A#{@@h[k]}\z/ ? k : nil}-[nil])[0]
  end
  def self.item m,rest=[]
    [self.event(m,rest),m]
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
  def self.regmakeExcept ex
    r=self.r(@@keys-ex)
    /#{r}|./
  end
  def self.blanks
    [:comment,:blank,:lineSep]
  end
end

def argSplit a
  if a
    a=~/:/
    pre=$`
    arg=$'
    arg=a if not $&
    res=[]
    if pre
      res+=[:pre,pre]
    end
    res<<:arg
    res+=arg.split(/[ ,]/)
  else
    a
  end
end
class MmlString < String
  @@trimmulti=0
  def macroDef
    macro={}
    macrokeys=[]
    mline=false
    tmp=[]
    name=""
    num=1
    rstr=MmlReg.macroDefr
    s=self.scan(/\n|macro +|#{rstr}| *\) *|[^;\n|]+|./)
    macDefStart=MmlReg.r([:macrodefAStart,:macrodefStart])
    macDef=MmlReg.r([:macrodefA,:macrodef])
    macDefStart="[[:alnum:]]+\\([,[:alpha:]]+\\):= *\\( *|[[:alnum:]]+:= *\\( *"
    p s if $DEBUG
    data=s.map{|i|
      case i
      when /^(#{macDefStart})/
        i=~/^([^ ]+) *:= *\( */
        mline=true
        num=1
        name=$1
        tmp=[]
        ""
      when /^(#{macDef})/
        i=~/^([^ ]+) *:=([^;]+)$/
        r=$2
        key=$1
        macrokeys<<key
        chord=/([^$]|^)\{([^\{\}]*)\}/
        r.gsub!(chord){"#{$1}(C:#{$2})"} while r=~chord
        macro[key]=r # modifierComp(r,macro)
        ""
      when /^ *\) *$/
        mline=false
        name=""
      when ";",/^ *$/
        i
      else
        if mline
          key="#{name}[#{num}]"
          macrokeys<<key
          macro[key]=i
          num+=1
          ""
        else
          i
        end
      end
    }*""
    [macrokeys,macro,data]
  end
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
    @events||=self.scan(MmlReg::RwAll).map{|i|
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
      [[:oneArg,self]]
    else
      self.mmlscan.map{|m|MmlReg.item(m)}
    end
  end
  def argscanMap cmd=false
    rest=[:octave]
    @@argReg||=MmlReg.regmakeExcept(rest)
    case cmd
    when *MmlReg::ArgIsOne
      [[:oneArg,self]]
    else
      self.scan(@@argReg).map{|m|MmlReg.item(m,rest)}
    end
  end
  def hexscan
    self.scan(/[[:digit:]]{2}|\$[^ ]+|[, ]/)
  end
  def hexscanMap
    self.hexscan.map{|m|MmlReg.hexitem(m)}
  end
  def allEvents
    @macro||=[]
    @events||=(
      macrokeys,macro,data=self.macroDef
      macrokeys.each{|k|
        @macro<<[:macrodefStart,k]
        @macro<<[:macroBody,macro[k]]
      }
      data.to_mstr.mmlscan
    )
    @evmap||=@events.map{|i|
      MmlReg.item(i)
    }
    @flattenEvents=@macro+@evmap.dup
    r=[]
    fixflag=false
    # until arg substitute complete
    begin
      res=@flattenEvents.map{|e,i|
        fixflag=false
        p [:item,e,i] if $DEBUG
        case e
        when :macrodefA
          i=~/([[:alnum:]]+\([,[:alpha:]]+\):=) *(.+)/
          r<<[:macrodefAStart,$1]
          r<<[:macrodefABody,$2]
          r<<[:macrodefAEnd]
        when :word
          i=~/\( *([^ ):]*) *:(.*)\)/
          wcmd=$1
          arg=$2
          r<<[:wordStart]
         # r<<[:parenStart,"("]
          if wcmd==""
            r<<[:wordSameCmd]
          else
            r<<[:wordCmd,wcmd]
          end
          r<<[:wordArgStart]
          r+=arg.argscanMap(wcmd)
        #  r<<[:parenEnd,")"]
          r<<[:wordEnd]
        when :word?
          i=~/\(([^)]*)\)/
          r<<[:wordStart?]
          r<<[:parenStart,"("]
          r+=$1.mmlscanMap
          r<<[:parenEnd,")"]
          r<<[:wordEnd?]
        when :chord
          i=~/\{([^)]*)\}/
          if $&
            r<<[:chordStart,"{"]
            r+=$1.mmlscanMap
            r<<[:chordEnd,"}"]
          else
            r<<[:chord,i]
            fixflag=true
          end
        when :hexraw
          i=~/&\(([^)]*)\)/
          r<<[:hexrawStart,"&("]
          r+=$1.hexscanMap
          r<<[:hexrawEnd,")"]
        when :macrodef
          i=~/([[:alnum:]]+:=) */
          r<<[:macrodefStart,$1]
          r+=$'.mmlscanMap
          r<<[:macrodefEnd]
        when :macroA
          i=~/\$\{?([^\{\}\(\)\[\]]+)\}?(\[(.*)\])?/
          r<<[:macroAName,$1]
          r<<[:macroAArgs,argSplit($3)]
        when :macro
          i=~/\$\{?([^\{\}\(\)]+)\}?(\((.*)\))?/
          r<<[:macroName,$1]
          r<<[:macroArgs,argSplit($3)]
        else
          r<<[e,i]
          fixflag=true
        end
        fixflag
      }
      fixflag = ! res.member?(false)
      @flattenEvents=r # Marshal.load(Marshal.dump(r))
      r=[]
    end until fixflag==true
    lastCmd=""
    @flattenEvents=@flattenEvents.map{|e,v|
      case e
      when :wordCmd
        lastCmd=v
      when :wordSameCmd
        v=lastCmd if not v
      else
      end
      [e,v]
    }
  end
  def mmlEvents
    @flattenEvents||=self.allEvents
    @flattenEvents.reject{|e,v|MmlReg.blanks.member?(e)}
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
class String
  def to_mstr
    MmlString.new(self)
  end
end

def check d
resTrue=[[:macrodefStart, "m(x)"],
 [:macroBody, "tes$xtes2"],
 [:macrodefStart, "MU[1]"],
 [:macroBody, "test"],
 [:macrodefStart, "MU[2]"],
 [:macroBody, "test2"],
 [:macrodefStart, "mac"],
 [:macroBody, "abcd ef(tes:34)"],
 [:macrodefStart, "N[1]"],
 [:macroBody,
  "(comment:## this line includes not valid sequence words, for test only.)"],
 [:wordStart, nil],
 [:wordCmd, "gm"],
 [:wordArgStart, nil],
 [:oneArg, "on"],
 [:wordEnd, nil],
 [:note, "r"],
 [:note, "r"],
 [:note?, "B"],
 [:dummyNote, "o"],
 [:randNote, "?"],
 [:note, "a"],
 [:num, "*321"],
 [:sound?, "s"],
 [:note, "d"],
 [:note, "e"],
 [:note, "f"],
 [:macroAName, "MU"],
 [:macroAArgs, [:arg, "2"]],
 [:tSep, "|||"],
 [:sharp, "(+2)"],
 [:note, "d"],
 [:sound, "~"],
 [:note, "f"],
 [:wordStart, nil],
 [:wordCmd, "text"],
 [:wordArgStart, nil],
 [:oneArg, "wai wai"],
 [:wordEnd, nil],
 [:wordStart?, nil],
 [:parenStart, "("],
 [:note, "g"],
 [:sound?, "h"],
 [:parenEnd, ")"],
 [:wordEnd?, nil],
 [:hexrawStart, "&("],
 [:hex, "00"],
 [:hexSep, " "],
 [:hex, "11"],
 [:hexSep, " "],
 [:hex, "22"],
 [:hexSep, " "],
 [:macroName, "bar"],
 [:macroArgs, nil],
 [:hexrawEnd, ")"],
 [:sound?, "i"],
 [:macroName, "m"],
 [:macroArgs, [:arg, "1"]],
 [:tSep, "|||"],
 [:tSep, "|||"],
 [:sound?, "j"],
 [:chordStart, "{"],
 [:sound?, "k"],
 [:sound?, "l"],
 [:chordEnd, "}"],
 [:chordStart, "{"],
 [:sound?, "m"],
 [:valueSep, ","],
 [:sound?, "n"],
 [:chordEnd, "}"],
 [:chordStart, "{"],
 [:num, "70"],
 [:chordEnd, "}"],
 [:wordStart?, nil],
 [:parenStart, "("],
 [:dummyNote, "o"],
 [:sound?, "i"],
 [:parenEnd, ")"],
 [:wordEnd?, nil],
 [:note, "a"],
 [:note, "b"],
 [:repStart, "["],
 [:note, "c"],
 [:note, "d"],
 [:repEnd, "]"],
 [:num, "4"],
 [:multipletStart, "/3:"],
 [:note, "e"],
 [:note, "f"],
 [:multipletmark, "/"],
 [:note, "g"],
 [:sound?, "v"],
 [:octave, "+"],
 [:octave, "+89"],
 [:tempo, "<"],
 [:note, "b"],
 [:wordStart, nil],
 [:wordCmd, "stroke"],
 [:wordArgStart, nil],
 [:num, "1"],
 [:valueSep, ","],
 [:num, "2"],
 [:valueSep, ","],
 [:num, "3"],
 [:wordEnd, nil],
 [:wordStart, nil],
 [:wordSameCmd, "stroke"],
 [:wordArgStart, nil],
 [:plusMinus, "-"],
 [:wordEnd, nil],
 [:repmark, ".SKIP"],
 [:tempo, ">"],
 [:mod, "`"],
 [:mod, "'"],
 [:note, "c"],
 [:num, "23"],
 [:macroName, "m"],
 [:macroArgs, [:arg, "2"]],
 [:sound, "_snare!"],
 [:macroName, "mac"],
 [:macroArgs, nil],
 [:sound, "_c!"],
 [:num, "123"],
 [:repmark, ".$"],
 [:chord, ":cmaj7,"],
 [:note, "b"],
 [:num, "45"],
 [:note, "a"],
 [:octave, "+"],
 [:note, "b"],
 [:octave, "-"],
 [:note, "c"],
 [:pSep, "///"],
 [:note, "d"],
 [:note, "e"],
 [:sharp, "(0)"],
 [:note, "f"],
 [:note, "G"],
 [:hexrawStart, "&("],
 [:macroName, "se"],
 [:macroArgs, [:arg, "f0", "00"]],
 [:parenEnd, ")"],
 [:macroAName, "Ab"],
 [:macroAArgs, [:arg, "$e"]],
 [:macroAName, "B"],
 [:macroAArgs, [:arg, "3"]],
 [:macroAName, "abc"],
 [:macroAArgs, [:arg, "2"]],
 [:macroAName, "def"],
 [:macroAArgs, [:arg, "3", "$we", "5"]],
 [:macroName, "asdf"],
 [:macroArgs, nil],
 [:macroName, "asdfghjkl"],
 [:macroArgs, [:pre, "20", :arg, "2", "3", "4"]],
 [:wordStart, nil],
 [:wordCmd, "G"],
 [:wordArgStart, nil],
 [:valueSep, ","],
 [:valueSep, ","],
 [:plusMinus, "-"],
 [:wordEnd, nil],
 [:valueSep, ","],
 [:cmdValSep, ":"],
 [:parenEnd, ")"],
 [:parenStart, "("],
 [:wordStart, "(12:"],
 [:sound?, "n"],
 [:note2, "(x,y)"],
 [:cmdValSep, ":"],
 [:sound, "="],
 [:parenStart, "("]]
 if d!=resTrue
   puts "warning: regexp changed? =>"
   pp d-resTrue
 end
end

s=MmlString.new(s)
s=s.gsub(/\n/m){" ; "}.gsub(";;"){"##"}.split(" ; ").map{|i|i.trim("##") }.join("\n").to_mstr
p [:r,MmlReg::RwAll] if $DEBUG
p s
# m=s.mmlscan
# p m*" ;; "
sEvent=s.mmlEvents
pp sEvent
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
  check(sEvent)
end

