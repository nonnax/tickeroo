#!/usr/bin/env mruby
# Id$ nonnax 2021-08-22 20:38:32 +0800
require "observer"
require "forwardable"

class Ticker
  include Observable
  extend Forwardable
  def_delegators :@coin, :symbol, :price, :high, :low, :last_price, :rate7d
  attr_accessor :timer
  
  def initialize(symbol, timer)
    @coin=Coin.new(symbol)
    @timer=timer
    @start=Time.now-@timer
  end

  def when_ready?
    # @start ||= Time.now-@timer
    if res=((Time.now-@start)>=@timer)
      yield self
    end
    res
    rescue => e
      p [:Err, e]
  end

  def reset_timer
    @start=Time.now #reset
  end

  def run
    @coin.price, @coin.high, @coin.low, @coin.rate7d = Price.fetch(symbol)
    
    if @coin.changed?
      time_changed=Time.now
      reset_timer
      changed 
      notify_observers(time_changed, @coin)
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
    ts=time.to_s.scan(/\S+/)[1] # time
    if price < @limit
      print "--- #{ts}: #{coin.symbolf}: Price below %.2f : %.2f\n" % [@limit, price]
    end
  end
end

class WarnHigh < Warner
  def update(time, coin)       # callback for observer
    price=coin.price
    ts=time.to_s.scan(/\S+/)[1] # time
    if price > @limit
      print "+++ #{ts}: #{coin.symbolf}: Price above %.2f : %.2f\n" % [@limit, price]
    end
  end
end

class WalletView < Warner
  ALIGN_RIGHT=112
  WALLET={'ripple'=>[70], 'bitcoin-cash'=>[35822, 40000], 'chainlink'=>[1507, 1507*1.1], 'litecoin'=>[11000]}

  def plot(coin)
    df=[]
    return unless WALLET[coin.symbol]
    WALLET[coin.symbol].each do |r|
      df<<[coin.symbol, r, coin.high, coin.low, coin.price]
    end
    df.plot_df{|b, r| puts [r[:open].to_f.commify.rjust(20), b, r[:close].to_f.commify].join("\t")}
  end

  def update(time, coin) 
    fname=Time.now.to_s.scan(/\S+/).first #date
    ts=time.to_s.scan(/\S+/)[1] # time
    return unless WALLET[coin.symbol]
    WALLET[coin.symbol].each do |price|
      text="%s wallet (%.2f) %.2f%%" % [coin.symbolf, price, (coin.price/price-1)*100]
      puts text.rjust(ALIGN_RIGHT)
    end
    plot(coin)
    # File.open(fname+'.dat', 'a'){|f| f.puts ([ts]+coin.to_a).join(' ')}
  end
end

class FileSaver < Warner
  def update(time, coin) 
    fname=Time.now.to_s.scan(/\S+/).first #date
    ts=time.to_s.scan(/\S+/)[1] # time
    File.open(fname+'.dat', 'a'){|f| f.puts ([ts]+coin.to_ohlc).join(' ')}
  end
end

class CSVFileSaver < Warner
  def update(time, coin) 
    date=Time.now.to_s.scan(/\S+/).first #date
    fname=[date, coin.symbol].join('-')
    ts=time.to_s #.scan(/\S+/)[1] # time
    File.open(fname+'.csv', 'a'){|f| f.puts ([ts]+coin.to_ohlc).join(',')}
  end
end

class Notifier < Warner
  def update(time, coin) 
      puts
      display_text = "#{time.to_s.scan(/\S+/)[1]} #{coin.symbol}: %.2f %.2f %.2f %.2f (%.2f%%7d)" % [coin.price, coin.high, coin.low, coin.close, coin.rate7d]
      s=display_text.scan(/\S+/).map{|e| e.strip.rjust(14)}.join()<<' '
      puts s.send(coin.color)
  end
end

class Plotter < Warner
  def plot(coin)
    date=Time.now.to_s.scan(/\S+/).first #date
    fname=[date, coin.symbol].join('-')+'.csv'
    puts IO.popen("histoplot #{fname} -1", &:read)
  end
  def update(time, coin) 
    plot(coin)
  end
end


class CandlePlotter < Warner
  def plot(coin)
    return if coin.close<0
    @df ||= []
    puts "current price"
    @df<<[coin.symbol, coin.price, coin.high, coin.low, coin.close] 
    min, max=@df.map{|e| e.values_at(1, -1)}.flatten.minmax
    df_new=[]
    prev=@df.map.first[1]
    @df.map{|e| 
      df_new<<[e.first, prev, max, min, e[1]]
      prev=e[1]
    }
    df_new.plot_df{|b, r|
      puts [r[:open].to_f.commify.rjust(20), b, r[:close].to_f.commify].join("\t")
      }
  end
  
  def update(time, coin) 
    plot(coin)
  end
end

