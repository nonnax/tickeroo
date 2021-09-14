#!/usr/bin/env mruby
# frozen_string_literal: true

# Id$ nonnax 2021-08-22 20:38:32 +0800
require 'observer'
require 'forwardable'

class Ticker
  include Observable
  extend Forwardable
  def_delegators :@coin, :symbol, :price, :high, :low, :last_price, :rate7d
  attr_accessor :timer

  def initialize(symbol, timer)
    @coin = Coin.new(symbol)
    @timer = timer
    @start = Time.now - @timer
  end

  def when_ready?
    # @start ||= Time.now-@timer
    if res = ((Time.now - @start) >= @timer)
      yield self
    end
    res
  rescue StandardError => e
    p [:Err, e]
  end

  def reset_timer
    @start = Time.now # reset
  end

  def run
    @coin.price, @coin.high, @coin.low, @coin.rate7d = Price.fetch(symbol)

    if @coin.changed?
      time_changed = Time.now
      reset_timer
      changed
      notify_observers(time_changed, @coin)
    end
  end
end

