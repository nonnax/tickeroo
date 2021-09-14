PRICES={
  'ripple'=>(60..90),
  'bitcoin-cash'=>(31000..40000),
  'litecoin'=>(8500..12100)
}
class Price           ### A mock class to fetch a stock price (60 - 140).
  def self.fetch(symbol)
    if MOCK
      if price=PRICES[symbol] 
        [price.min + rand(price.min), price.max, price.min, 1]
      else 
        [60 + rand(2), 120, 70, 1] 
      end
    else
      r=IO.popen("price #{symbol}", &:read).split()
      r.values_at(1,2,3,5).map(&:to_f)
    end
  end
end
