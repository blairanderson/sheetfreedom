# http://stackoverflow.com/a/34623680/1536309
module RubyDig
  def dig(key, *rest)
    if value = (self[key] rescue nil)
      if rest.empty?
        value
      elsif value.respond_to?(:dig)
        value.dig(*rest)
      end
    end
  end
end

if RUBY_VERSION < '2.3'
  Array.send(:include, RubyDig)
  Hash.send(:include, RubyDig)
end