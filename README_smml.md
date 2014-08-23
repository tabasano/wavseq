# smml

simple Music Macro Language to MIDI

## Installation


[![Gem Version](https://badge.fury.io/rb/smml.svg)](http://badge.fury.io/rb/smml)

Add this line to your application's Gemfile:

```ruby
gem 'smml'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smml

## Usage

in a ruby script,

    m=Smml.new
    m.compile('infile.mml','outfile.mid')

Or exec command.
smml to mid (file to mid, mml data to mid, syntax, help)

    $ smml -i infile.mml -o out.mid
    $ smml -d "cdefgab"  -o out.mid
    $ smml -s
    $ smml -h

mml2smml (file to smml, mml data to smml, mml data to mid)

    $ mmlsmml -i infile.mml > smmlfile
    $ mmlsmml -d "cdefgab" > smmlfile
    $ mmlsmml -d "cdefgab" -o out.mid

## Contributing

1. Fork it ( https://github.com/[my-github-username]/smml/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
