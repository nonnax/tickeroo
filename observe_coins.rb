#!/usr/bin/env mruby
# Id$ nonnax 2021-08-22 20:38:32 +0800
# require "observer"
# require "forwardable"
require "./lib/ansi_color"
require "./lib/observers"

#-------------
class Runner
  @savefile='alerts.yaml'
  @watchlist={}

  def self.savefile
    @savefile
  end

  def self.watchlist
    @watchlist
  end

  def self.load(file)
    File.exists?(file) ? YAML.load(File.read(file)) : {}
  end

  def self.save(file, watchlist)
    File.open(file, 'w'){|f| f.puts watchlist.to_yaml }
  end
  
  def self.init
    # watchlist = {}
    watchlist=load(@savefile)

    if watchlist.empty?
      watchlist.merge!( 'ripple' => [59, 80] )
      watchlist.merge!( 'the-graph' => [45, 90] )
      watchlist.merge!( 'uniswap' => [1300, 1500] )
    end

    p watchlist

    timers={
      'ripple' => 15,
      'the-graph' => 300,
      'uniswap' => 300,
      'bitcoin-cash' => 60,
      'litecoin' => 60
    }

    @tickers=watchlist.inject([]){|e, (k, v)|
      ticker=Ticker.new(k, timers[k])
      low, high  = v
      WarnLow.new(ticker, low)
      WarnHigh.new(ticker, high)
      unless MOCK
        FileSaver.new(ticker, 0)
        CSVFileSaver.new(ticker, 0)
      end
      e<<ticker
    }

    save(savefile, watchlist)
  end
  
  def self.run
    init()
    loop do
      @tickers.each do |ticker|
        ticker.run if ticker.ready?
      end
    end
  end
end

Runner.run
