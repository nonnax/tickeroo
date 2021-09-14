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

# ----------- File savers

class FileSaver < Warner
  def update(time, coin)
    fname = Time.now.to_s.scan(/\S+/).first # date
    ts = time.to_s.scan(/\S+/)[1] # time
    File.open("#{fname}.dat", 'a') { |f| f.puts ([ts] + coin.to_ohlc).join(' ') }
  end
end

class CSVFileSaver < Warner
  def update(time, coin)
    date = Time.now.to_s.scan(/\S+/).first # date
    fname = [date, coin.symbol].join('-')
    ts = time.to_s # .scan(/\S+/)[1] # time
    File.open("#{fname}.csv", 'a') { |f| f.puts ([ts] + coin.to_ohlc).join(',') }
  end
end

