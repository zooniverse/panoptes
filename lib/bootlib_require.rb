module BootLib
  module Require
    ARCHDIR    = RbConfig::CONFIG['archdir']
    RUBYLIBDIR = RbConfig::CONFIG['rubylibdir']
    DLEXT      = RbConfig::CONFIG['DLEXT']

    def self.from_archdir(feature)
      require(File.join(ARCHDIR, "#{feature}.#{DLEXT}"))
    end

    def self.from_rubylibdir(feature)
      require(File.join(RUBYLIBDIR, "#{feature}.rb"))
    end

    def self.from_gem(gem, feature)
      match = $LOAD_PATH
        .select { |e| e.match(gem_pattern(gem)) }
        .map    { |e| File.join(e, feature) }
        .detect { |e| File.exist?(e) }
      if match
        require(match)
      else
        puts "[BootLib::Require warning] couldn't locate #{feature}"
        require(feature)
      end
    end

    def self.gem_pattern(gem)
      %r{
        /
        (gems|extensions/[^/]+/[^/]+)          # "gems" or "extensions/x64_64-darwin16/2.3.0"
        /
        #{Regexp.escape(gem)}-(\h{12}|(\d+\.)) # msgpack-1.2.3 or msgpack-1234567890ab
      }x
    end
  end
end
