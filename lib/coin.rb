require "./lib/ansi_color"

class Coin
  attr_accessor :symbol, :price, :high, :low, :close, :last_price, :color, :rate7d
  @@colors=[:red, :blue, :green, :yellow]*3

  def initialize(symbol, price=0, high=0, low=9999, rate7d=1)
    @symbol, @price, @high, @low, @rate7d=symbol, price, high, low, rate7d
    @last_price, @close = -1, @price
    @color=@@colors.pop
  end

  def changed?
    #check and update latest price
    unless res=(@price <=> @last_price).zero?
      @close = @last_price
      @last_price = @price
    end
    res
  end

  def direction
    @price<=>@last_price
  end

  def symbolf
    symbol.send(@color)
  end

  def to_h
    {symbol => [price, high, low]}
  end

  def to_ohlc
    [symbol, @close, high, low, price]
  end
  alias to_a to_ohlc

end
