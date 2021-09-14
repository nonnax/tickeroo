#!/usr/bin/env mruby
# Id$ nonnax 2021-08-22 20:38:32 +0800

class String
  # color helper for drawing candlestick patterns on a Unix/Linux terminal
  def set_color(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def color_codes
    {
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      pink: 35,
      cyan: 36
    }
  end
  "".color_codes.each do |k, v|
    define_method(k){ set_color(v)}
  end
end

module AsciiPlot
  #
  # Unix-compatible Terminal OHLC data plotter
  # uses ANSI box drawing chars 
  #
  extend self

  DENSITY_SIGNS = ["#", "░", "▒", "▓", "█"].freeze
  # BOX_HORIZ = '─'.freeze
  BOX_HORIZ = '-'.freeze
  BOX_HORIZ_VERT = '┼'.freeze
  # BOX_HORIZ_VERT = '|'.freeze

  BAR_XLIMIT = 50
  @x_axis_limit = nil

  class << self
    attr_accessor :x_axis_limit
  end
  
  def candlestick(name, open, high, low, close, min=0, max=100) 
    # 
    # plot an OHLC row as candlestick pattern 
    # row format == [:row_1, o, h, l, c, min, max]
    #
    @x_axis_limit ||= BAR_XLIMIT
    bar = ' '*@x_axis_limit
    
    up_down=(close<=>open)
    #normalize to zero x-axis
    open, low, high, close, min, max=[open, low, high, close, min, max].map{|e| e-min}

    #normalize to percentage
    open, high, low, close = [open, high, low, close].map{|e| (e/max.to_f)*@x_axis_limit}.map(&:floor)
    len=(high-low)
    bar[low...(low+len)]=BOX_HORIZ*len
    start, stop = [open, close].minmax
    len=(stop-start)
    case len
      when 0
        start=[start-1, 0].max
        bar[start]=BOX_HORIZ_VERT
      else  
        bar[start...(start+len)]=DENSITY_SIGNS[-1]*len
    end
    up_down.negative? ? bar.red : bar.cyan
  end
  
  def plot_df(data)    
    # 
    # plots an OHLC dataframe
    # dataframe=[[:row_1, o, h, l, c], ...[:row_n, o, h, l, c]]
    #
    min, max=data.map{|r| r.values_at(1..-1)}.flatten.minmax
    data.each do |row|
      row_h=%i[title open high low close].zip(row).to_h
      yield *[AsciiPlot.candlestick(*row, min, max), row_h]
    end
  end
end

class Array
  def plot_df
    #plot an OHLC dataframe
    AsciiPlot.plot_df(self) do |b, r|
      yield *[b, r]
    end
  end
end


if __FILE__==$0 then

AsciiPlot.x_axis_limit=30

data=[]
20.times{
  min, max = 170, 245
  @min, @max=min, max
  o, l, h, c  = rand(min..max), max+rand(5), min+rand(10), rand(min..max)
  l, h=[o, l, h, c].minmax
  c=[c, h].min
  data<<[:first20, o, h, l, c]
}

20.times{
  min, max = 70, 80
  @min, @max=min, max
  o, l, h, c  = rand(min..max), max+rand(5), min+rand(10), rand(min..max)
  l, h=[o, l, h, c].minmax
  c=[c, h].min
  data<<[:next20, o, h, l, c]
}

20.times{
  min, max = 10, 70
  @min, @max=min, max
  o, l, h, c  = rand(min..max), max+rand(5), min+rand(10), rand(min..max)
  l, h=[o, l, h, c].minmax
  c=[c, h].min
  data<<[Time.now.to_s, o, h, l, c]
}

AsciiPlot.plot_df(data){|bar, r| 
  puts [bar, r].join(' ')
}

AsciiPlot.x_axis_limit=50

# array plot
data.plot_df{|b, r| 
  puts [b, r].join("\t")
}

end
