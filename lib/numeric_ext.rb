class Numeric
  def rates(f=0.05, **params)
    repeat=params[:size] || 3
    d=[]
    (0..repeat).each do |i|
      d<<self*(i*f+1)  
      d<<self/(i*f+1)  
    end
    d.sort.uniq.map{|e| yield e }
  end
  def minutes
    self*60
  end
  alias minute minutes
  
  def hours
    minutes*60
  end
  alias hour hours
  
  def days
    hours*24
  end
  alias day days
  
  def commify
    u,d=("%.2f" % [self.to_f]).split('.')
    arr=u.to_s.reverse.split('')
    arr=arr.each_slice(3).map{|e|
      e.join
    }.join('_').reverse

    arr<<'.'<<d unless Integer===self
    arr
  end
end
