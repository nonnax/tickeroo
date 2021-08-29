require "./lib/ansi_color"

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

  def direction
    @price<=>@last_price
  end

  def symbolf
    symbol.send(@color)
  end

  def to_h
    {symbol => [price, high, low]}
  end

  def to_a
    [symbol, price, high, low]
  end
end
