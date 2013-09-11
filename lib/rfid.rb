require "serialport"

# USAGE:
# p RfidReader.open(port_str, baud_rate, data_bits, stop_bits, parity) { # some extra code}

class RfidReader
  attr_accessor :data

  def self.open(opts={}, &block)
    new(opts, &block)
  end

  def initialize(opts, &block)
    sleeptime = opts.fetch(:sleeptime], 0.2)
    baud_rate = opts.fetch(:baud_rate], 9600)
    data_bits = opts.fetch(:data_bits], 8)
    stop_bits = opts.fetch(:stop_bits], 1)
    port_str  = opts.fetch(:port_str] , '/dev/ttyAMA0')
    parity    = opts.fetch(:parity]   , SerialPort::NONE)

    SerialPort.open port_str, baud_rate, data_bits, stop_bits, parity do |port|
      port.sync = false
      port.flush
      port.read_timeout = -1
      read(port, sleeptime, &block)
    end
  end

  def read(port, sleeptime, &block)
    reading = ''
    loop do
      yield block if block_given?
      if i = port.gets
        reading = i.force_encoding('UTF-8').split("\x02")[1].split("\x03")[0] rescue ''
        if reading.size == 12
          port.flush
          self.data = reading
          return
        end
      end
      sleep @sleeptime
    end
  end
end