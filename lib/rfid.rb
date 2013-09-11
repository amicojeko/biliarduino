require "serialport"

# USAGE:
# p RfidReader.read(port_str, baud_rate, data_bits, stop_bits, parity)

class RfidReader
  def self.read(opts={})
    new(opts)
  end

	def initialize(opts)
   @sleeptime = opts[:sleeptime] || 0.2
    port_str   = opts[:port_str]  || "/dev/ttyAMA0"
    baud_rate  = opts[:baud_rate] || 9600
    data_bits  = opts[:data_bits] || 8
    stop_bits  = opts[:stop_bits] || 1
    parity     = opts[:parity]    || SerialPort::NONE

    SerialPort.open port_str, baud_rate, data_bits, stop_bits, parity do |port|
		  port.sync = false
		  port.flush
		  port.read_timeout = -1
      read(port)
    end
	end

	def read(port)
		reading = ''
    loop do
			if i = port.gets
				reading = i.force_encoding('UTF-8').split("\x02")[1].split("\x03")[0] rescue ''
				if reading.size == 12
					port.flush
					return reading
				end
			end
			sleep @sleeptime
		end
	end
end