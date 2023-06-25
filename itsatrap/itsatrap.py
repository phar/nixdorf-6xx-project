import serial
import glob
import time
import argparse
import struct

class TrapTerm():
	def __init__(self,port):
		self.port = port
		self.baud = 115200

		self.serial = serial.Serial(self.port, self.baud)
		time.sleep(2);
		if(self.serial.read(6) == "boot\r\n"):
			print("terminal driver connected.")


	def get_fifo_status(self):
		packet = b'p'
		self.serial.write(packet)
		count = ord(self.serial.read(1))
		print("count ",count)
		poll = {}
		for i in range(count):
			(inuse,termid,output,intput) = struct.unpack("bbbb",self.serial.read(4))
			poll[termid] = {"output_remaining":output,"input_available":intput}
		return poll



	def terminal_send(self, terminal_id,data):
		self.serial.write(b"s")
		self.serial.write(struct.pack("b",terminal_id))
		self.serial.write(struct.pack("b",len(bytes(data))))
		status = self.serial.read(1)
		if(status):
			self.serial.write(bytes(data))
			return self.serial.read(1)
		else:
			return status
		return self.serial.read(1)




parser = argparse.ArgumentParser(description='Serial Port Example')
parser.add_argument('-p', '--port', type=str, help='Serial port name')
args = parser.parse_args()


if __name__ == '__main__':
	tt = TrapTerm(args.port)
	tt.get_fifo_status()
	print(tt.get_fifo_status())
	
	for i in range(64):
		print("hello terminal %d" % i)
		tt.terminal_send(i, b"hello world!\n")

