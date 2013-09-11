require "serialport"

# USAGE:
# @rfid = RfidReader.new(port_str, baud_rate, data_bits, stop_bits, parity)
# p @rfid.read
class RfidReader
	def initialize (opts = {})
    port_str  = opts[:port_str]   || "/dev/ttyAMA0"
    baud_rate = opts[:baud_rate]  || 9600
    data_bits = opts[:data_bits]  || 8
    stop_bits = opts[:stop_bits]  || 1
    parity    = opts[:parity]     || SerialPort::NONE
    @sleeptime = opts[:sleeptime] || 0.2

    @sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
		@sp.sync = false
		@sp.flush
		@sp.read_timeout = -1
	end

	def read
		reading = ""
    loop do
			if i = @sp.gets
				reading = i.force_encoding('UTF-8').split("\x02")[1].split("\x03")[0] rescue ''
				if reading.size == 12
					@sp.flush
					return reading
				end
			end
			sleep @sleeptime
		end
	end
end