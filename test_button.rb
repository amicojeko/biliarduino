require 'wiringpi'
@gpio  = WiringPi::GPIO.new
@gpio.mode(3, INPUT)

loop do
	if @gpio.read(3) == 1 
		p "GOOOOOOOL"
	end

	sleep 0.002
end