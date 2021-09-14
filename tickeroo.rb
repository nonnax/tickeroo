#!/usr/bin/env mruby
# Id$ nonnax 2021-08-22 20:38:32 +0800
# require "observer"
# require "forwardable"

MOCK=false
# MOCK = true

require './lib/mtrader'
require 'printbig'

class Runner
  @savefile = File.basename($0).split('.').first<<'.yaml'
  @watchlist = {}

  class << self
    attr :savefile, :watchlist
  end
  
  def self.load_watchlist
    File.exist?(savefile) ? YAML.load(File.read(savefile)) : {}
  end

  def self.save_watchlist
    p 'saving...'
    @watchlist = @init_watchlist_defaults 
    File.open(savefile, 'w') { |f| f.puts @watchlist.to_yaml }
  end

  def self.init
    @watchlist=load_watchlist()
    save_watchlist() if @watchlist.empty?
    #
    @tickers = @watchlist.inject([]) do |arr, (k, v)|
      ticker = Ticker.new(k, v['timer']) 
      v['watch'].each do |pair|
        low, high = pair
        yield [ticker, low, high]
        arr << ticker
      end
      arr
    end
  end

  @init_watchlist_defaults=
      {
        'ripple' => { 
          'watch' => [
                [59, 80], 
                [63.63, 77]
              ], 
          'timer' => 60 },

        'bitcoin-cash' => { 
          'watch' => [
                [36_363.64, 44_000]
              ], 
          'timer' => 65 },

        'the-graph' => { 
          'watch' => [
                [45, 90]
              ], 
          'timer' => 300 },

        'litecoin' => { 
          'watch' => [
                [10_000, 12_100]
              ], 
          'timer' => 75 },

        'chainlink' => { 
          'watch' => [
                [1_657, 1_507]
              ], 
          'timer' => 60 },

        'enjincoin' => { 
          'watch' => [
                [92.57, 108.85]
              ], 
          'timer' => 300 }
      }
  def self.run
    # add observers
    printbig "Tickeroo is watching you..."
    exists={}
    p 'initializing...'
    init do |ticker, low, high|
      # order is important this time
      unless exists[ticker.symbol]
        Notifier.new(ticker, 0) 
        WalletView.new(ticker, 0)
        CandlePlotter.new(ticker, 0)
        # Plotter.new(ticker, 0)
      end
      unless MOCK
        FileSaver.new(ticker, 0)
        CSVFileSaver.new(ticker, 0)
      end
      WarnLow.new(ticker, low)
      WarnHigh.new(ticker, high)

      exists[ticker.symbol]=true
    end

    p 'running....'
    loop do
      @tickers.each do |ticker|
              # show activity
        print Time.now.to_s.scan(/\S+/)[1] << "\r"

        ticker.when_ready?(&:run)
        sleep 1
      end
    end
  end
end

Runner.run
