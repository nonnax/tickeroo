#!/usr/bin/env mruby
# frozen_string_literal: true

# Id$ nonnax 2021-08-22 20:38:32 +0800
# require "observer"
# require "forwardable"

# MOCK=false
MOCK = true

require './lib/coin'
require './lib/prices'
require './lib/ansi_color'
require './lib/simple_plot'
require './lib/observers'

#-------------
class Runner
  @savefile = 'alerts.yaml'
  @watchlist = {}

  class << self
    attr :savefile, :watchlist
  end

  def self.load
    File.exist?(@savefile) ? YAML.load(File.read(@savefile)) : {}
  end

  def self.save
    File.open(@savefile, 'w') { |f| f.puts @watchlist.to_yaml }
  end

  def self.init
    @watchlist = load

    if @watchlist.empty?
      @watchlist = {
        'ripple' => { 'watch' => [59, 80], 'timer' => 10 },
        'bitcoin-cash' => { 'watch' => [36_363.64, 44_000], 'timer' => 15 },
        'the-graph' => { 'watch' => [45, 90], 'timer' => 300 },
        'litecoin' => { 'watch' => [10_000, 12_100], 'timer' => 15 },
        'the-graph' => { 'watch' => [45, 90], 'timer' => 300 },
        'uniswap' => { 'watch' => [45, 90], 'timer' => 300 },
        'enjincoin' => { 'watch' => [92.57, 108.85], 'timer' => 300 }
      }
    end

    @tickers = @watchlist.inject([]) do |e, (k, v)|
      ticker = Ticker.new(k, v['timer'])

      low, high = v['watch']
      Notifier.new(ticker, 0)
      Plotter.new(ticker, 0)
      WarnLow.new(ticker, low)
      WarnHigh.new(ticker, high)
      unless MOCK
        FileSaver.new(ticker, 0)
        CSVFileSaver.new(ticker, 0)
      end
      e << ticker
    end

    save
  end

  def self.run
    init
    loop do
      @tickers.each do |ticker|
        ticker.when_ready?(&:run)
      end
    end
  end
end

Runner.run
