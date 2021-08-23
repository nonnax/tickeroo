#!/usr/bin/env mruby
# Id$ nonnax 2021-08-22 20:38:32 +0800
require "observer"
require "forwardable"
require "./lib/ansi_color"

MOCK=nil

class Coin
  attr_accessor :symbol, :price, :high, :low, :last_price, :color
  @@colors=[:red, :blue, :green, :yellow]*3

  def initialize(symbol, price=0, high=0, low=9999)
    @symbol, @price, @high, @low=symbol, price, high, low
    @last_price=0
    @color=@@colors.pop
  end

  def changed?
    if res=(@price != @last_price)
      @last_price = @price
    end
    res
  end

  def symbolf
    symbol.send(@color)
  end

  def to_h
    {symbol: [price, high, low]}
  end

  def to_a
    [symbol, price, high, low]
  end
end

class Ticker
  include Observable
  extend Forwardable
  def_delegators :@coin, :symbol, :price, :high, :low, :last_price
  attr_accessor :timer
  
  def initialize(symbol, timer=5)
    @coin=Coin.new(symbol)
    @timer=timer
    @mock=false

    self
  end

  def ready?
    @start ||= Time.now
    if res=(Time.now-@start)>=@timer
      @start=nil #reset
    end
    res
  end

  def run
    @coin.price, @coin.high, @coin.low = Price.fetch(symbol)
    if @coin.changed?
      time_changed=Time.now
      @coin.high=[price, high].max
      @coin.low=[price, low].min
      print "\r"
      display_text = "#{time_changed.to_s.scan(/\S+/)[1]} #{@coin.symbol}: %.2f %.2f %.2f" % [price, high, low]
      puts display_text.scan(/\S+/).map{|e| e.strip.rjust(14)}.join().send(@coin.color)
      
      changed # notify observers
      notify_observers(time_changed, @coin)
    else
      # just to show activity
      print Time.now.to_s.scan(/\S+/)[1] << "\r"
    end
  end
end

class Price           ### A mock class to fetch a stock price (60 - 140).
  def self.fetch(symbol)
    if MOCK
      [60 + rand(2), 120, 70] 
    else
      r=IO.popen("price #{symbol}", &:read).split()
      r.values_at(1,2,4).map(&:to_f)
    end
  end
end

class Warner          ### An abstract observer of Ticker objects.
  def initialize(ticker, limit)
    @limit = limit
    ticker.add_observer(self)
  end
end

class WarnLow < Warner
  def update(time, coin)       # callback for observer
    price = coin.price
    if price < @limit
      print "--- #{time.to_s}: #{coin.symbolf}: Price below %.2f : %.2f\n" % [@limit, price]
    end
  end
end

class WarnHigh < Warner
  def update(time, coin)       # callback for observer
    price=coin.price
    if price > @limit
      print "+++ #{time.to_s}: #{coin.symbolf}: Price above %.2f : %.2f\n" % [@limit, price]
    end
  end
end

class FileSaver < Warner
  def update(time, coin) 
    fname=Time.now.to_s.scan(/\S+/).first #date
    ts=time.to_s.scan(/\S+/)[1] # time
    File.open(fname+'.dat', 'a'){|f| f.puts ([ts]+coin.to_a).join(' ')}
  end
end

class CSVFileSaver < Warner
  def update(time, coin) 
    fname=Time.now.to_s.scan(/\S+/).first #date
    ts=time.to_s.scan(/\S+/)[1] # time
    File.open(fname+'.csv', 'a'){|f| f.puts ([ts]+coin.to_a).join(',')}
  end
end

