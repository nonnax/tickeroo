#!/usr/bin/env mruby
# frozen_string_literal: true

# Id$ nonnax 2021-08-22 20:38:32 +0800

### An abstract observer of Ticker objects.
class Warner
  def initialize(ticker, limit)
    @limit = limit
    ticker.add_observer(self)
  end
end

# ----------- High/Low price watchers

class WarnLow < Warner
  # callback for observer
  def update(time, coin)
    price = coin.price
    ts = time.to_s.scan(/\S+/)[1] # time
    print format("--- #{ts}: #{coin.symbolf}: Price below %.2f : %.2f\n", @limit, price) if price < @limit
  end
end

class WarnHigh < Warner
  # callback for observer
  def update(time, coin)
    price = coin.price
    ts = time.to_s.scan(/\S+/)[1] # time
    print format("+++ #{ts}: #{coin.symbolf}: Price above %.2f : %.2f\n", @limit, price) if price > @limit
  end
end

# ----------- Wallet price watcher

class WalletView < Warner
  ALIGN_RIGHT = 112
  WALLET = {
    'ripple' => [70],
    'bitcoin-cash' => [35_822, 40_000],
    'chainlink' => [1507, 1507 * 1.1],
    'litecoin' => [11_000]
  }.freeze

  def plot(coin)
    df = []
    return unless WALLET[coin.symbol]

    WALLET[coin.symbol].each do |r|
      df << [coin.symbol, r, coin.high, coin.low, coin.price]
    end
    df.plot_df do |b, r|
      puts [
        r[:open].to_f.commify.rjust(20),
        b,
        r[:close].to_f.commify
      ].join("\t")
    end
  end

  def update(time, coin)
    fname = Time.now.to_s.scan(/\S+/).first # date
    ts = time.to_s.scan(/\S+/)[1] # time
    return unless WALLET[coin.symbol]

    WALLET[coin.symbol].each do |price|
      text = format('%s wallet (%.2f) %.2f%%', coin.symbolf, price, (coin.price / price - 1) * 100)
      puts text.rjust(ALIGN_RIGHT)
    end
    plot(coin)
  end
end

