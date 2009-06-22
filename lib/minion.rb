require 'ruby2ruby'

module Minion
  def self.queue(args={}, &blk)
    (c = Class.new).class_eval { define_method :proc, blk }
    @@store.call({ :code => Ruby2Ruby.translate(c, :proc), :args => YAML.dump(args) })
  end
  
  def self.run!
    puts "running queued code blocks"
    @@fetch.call.each do |queued|
      (c = Class.new).class_eval(queued[:code])
      c.new.proc(YAML.load(queued[:args]))
    end
  end
  
  def self.store=(callable)
    @@store = callable
  end
  
  def self.fetch=(callable)
    @@fetch = callable
  end
end

$q = []
Minion.store = lambda { |job| puts "storing #{job.inspect}"; $q << job }
Minion.fetch = lambda { $q }

# queue some code

Minion.queue do |args|
  puts "OH HAI"
end

Minion.queue 2 do |number|
  puts 1 + number
end

Minion.queue 'http://www.example.com/index.html' do |url|
  require 'net/http'
  require 'uri'
  Net::HTTP.get_print URI.parse(url)
end

Minion.queue "Crash!" do |message|
  raise RuntimeError, message
end

# and now run it

Minion.run!
