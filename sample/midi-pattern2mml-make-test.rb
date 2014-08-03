# drum pattern makeing test. syntax 'Pattern ..' is one draft.

# L16 = use each note length as 1/16 musical note.
# 'o' = on, '.' = rest.
# in highHat part, 'c' = closed high-Hat, 'o' = open high-Hat, '.' =rest.
# blanks cannot be removed now.
# to make a mid file, save to text.txt, then exec => ruby midi-simple-make.rb -i text.txt -o test.mid

data="
Pattern Y:=(
   L16
   snare   {  :|o o o o o o o o| }
   kick    {  :|. . . . . . . .| }
   highHat {  :|. . . . . . . .| }
   /////////////////////////////
   snare   {  :| . . . . o . o .| . . . . o . o .| . . o . o . o .| . . . . o . o .| }
   kick    {  :| o . . . . . . .| o . o . . . . .| o . . . . . . .| o . . . . . . .| }
   highHat {  :| c . c . c . c .| c . c . o . c .| c . c . c . c .| o . c . o . c .| }
   ////////////////////////////
   snare   {  :| . . . . o . o .| . . . . o . o .| . . o . o . o .| . . . . o . . .| }
   kick    {  :| o . . . . . . .| o . o . . . . .| o . . . . . . .| . . . . . . o .| }
   highHat {  :| c . c . c . c .| c . c . o . c .| c . c . c . c .| o . c . o . c .| }
   ////////////////////////////
   snare   {  :| . . . . o . o .| . . . . o . o .| . . o . o . o .| . . . . o . o .| }
   kick    {  :| o . . . . . . .| o . o . . . . .| o . . . . . . .| o . . . . . o .| }
   highHat {  :| c . c . c . c .| c . c . o . c .| c . c . c . c .| o . c . o . c .| }
   ////////////////////////////
   snare   {  :| . . . . o . o .| . . . . o . o .| . . o . o . o .| . . . . o . . o| }
   kick    {  :| o . . . . . . .| o . o . . . . .| o . . . . . . .| o o . o . . o .| }
   highHat {  :| c . c . c . c .| c . c . o . c .| c . c . c . c .| o . c . o . c .| }
)
"

def pattern a
  li=a.split("\n")
  r=[]
  m={}
  tmp=[]
  mu=false
  n=1
  name=""
  li.each{|i|
    case i
    when /^Pattern *([^ :]+) *:=\( *$/
      mu=true
      name=$1
    when /^ *\) */
      mu=false
      n=1
      r<<tmp
      tmp=[]
    when /^ *$/
    when /^ *L([[:digit:]]*) *$/
      subname="#{name}:::L"
      m[subname]=$1.to_i
    when /\$\{([^\}]+)\[(.*)\]\}/
      r<<i.gsub(/\$\{([^\}\[\]]+)\[([^\]]*)\]\}/){m["#{$1}:#{$2}"]}
    else
      if mu
        m["#{name}:#{n}"]=i
        r=i.gsub(/ +/," ").scan(/\{[^{}]*\}|[[:alnum:]_]+| +|./)-[""," "]
        subname="#{name}::#{r[0]}"
        /^\{ *([^:]*):([^{}]*)\}/=~r[1..-1]*" "
        pre,now=$1,$2
        if now
          now.gsub!(/\||:/){} 
          m[subname] ? m[subname]+=now : m[subname]=now
        end
        n+=1
      else
        r<<i
      end
    end
  }
  el=m.select{|k,v|k=~/:::/}
  el=el.values[0]/4
  melody=m.select{|k,v|k=~/::melody/}.map{|k,v|v.split(/ +/)}.flatten*""
  melody="/#{melody.size/4}:#{melody}/"
  drum=m.select{|k,v|k=~/::(kick|snare|highHat)/}
  drum=drum.map{|k,v|
    k=~/::(kick|snare|highHat)/
    if $1=="highHat"
      v.split(/ +/).map{|i|
        case i
        when "o"
          "_o!"
        when "c"
          "_c!"
        when "."
          "r"
        else
        end
      }-[nil]
    else
      name=$1=="kick" ? "b" : $1
      name="_#{name}!"
      v.split(/ +/).map{|i|
        case i
        when "o"
          name
        when "."
          "r"
        else
        end
      }-[nil]
    end
  }
  dr=drum.transpose
  dr=dr.map{|i|
    i=i-["r",nil]
    i.uniq!
    i=["r"] if i==[]
    i.size>1 ? "{#{i*","}}" : i
  }
  size=dr.size/el
  "/#{size}:#{dr*""}/"
end

data=File.read(ARGV[0]) if ARGV.size>0

puts pattern(data)