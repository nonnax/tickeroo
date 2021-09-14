#!/usr/bin/env mruby
# frozen_string_literal: true

# Id$ nonnax 2021-08-22 20:38:32 +0800

### An abstract observer of Ticker objects.
# class Warner
  # def initialize(ticker, limit)
    # @limit = limit
    # ticker.add_observer(self)
  # end
# end

# ----------- Console viewers

class Notifier < Warner
  def update(time, coin)
    puts
    printbig coin.symbol
    printbig "%.2f" % coin.price
    # display_text = "#{time.to_s.scan(/\S+/)[1]} #{coin.symbol}: %.2f %.2f %.2f %.2f (%.2f%%7d)" % [coin.price, coin.high, coin.low, coin.close, coin.rate7d]
    display_text = time.to_s.scan(/\S+/)[1]
    display_text << " #{coin.symbol}: "
    display_text << format('%.2f %.2f %.2f %.2f (%.2f%%7d)', coin.price, coin.high, coin.low, coin.close, coin.rate7d)
    s = display_text.scan(/\S+/).map { |e| e.strip.rjust(14) }.join << ' '
    puts s.send(coin.color)
  end
end

class Plotter < Warner
  def plot(coin)
    date = Time.now.to_s.scan(/\S+/).first # date
    fname = "#{[date, coin.symbol].join('-')}.csv"
    puts IO.popen("histoplot #{fname} -1", &:read)
  end

  def update(_time, coin)
    plot(coin)
  end
end

class CandlePlotter < Warner
  OPEN = 1
  CLOSE = -1
  def plot(coin)
    # plot price movement from runtime

    @df ||= []

    puts 'current price'
    @df << [
      coin.symbol,
      coin.price,
      coin.high,
      coin.low,
      coin.close
    ]
    return if @df.size <= 1

    # l, h is min-max of dataframe
    l, h = @df.map { |e| e[OPEN] }.minmax
    open = @df.first[OPEN]
    dataframe=[]

    @df.inject(dataframe) do |acc, r|
      acc << [r.first, open, h, l, r[OPEN]].dup
      open = r[OPEN]
      l, h = [r[OPEN], r[CLOSE]].minmax
      acc
    end

    dataframe.plot_df do |b, r|
      puts [
        r[:open].to_f.commify.rjust(20),
        b,
        r[:close].to_f.commify
      ].join("\t")
    end
  end

  def update(_time, coin)
    return unless coin.close.positive?
    plot(coin)
  end
end
