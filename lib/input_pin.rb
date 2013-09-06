class InputPin
  # lock_timeframe is used to lock only this input for consecutive press events, while glock_timeframe locks the inputs globally for given seconds
  attr_reader :pin, :pressed_value, :lock_timeframe, :locked, :locked_at

  def initialize(pin, opts)
    @pin            = pin
    @lock_timeframe = opts.fetch(:lock_timeframe, 0)
    @pressed_value  = opts.fetch(:pressed_value, 0)
  end

  # TODO refactor this shit
  def locked?
    if locked
      if locked_at + lock_timeframe >= Time.now
        true
      else
        false
      end
    else
      false
    end
  end

  def lock
    @locked_at = Time.now
    @locked = true
  end

  def unlock
    @locked = false
  end
end
