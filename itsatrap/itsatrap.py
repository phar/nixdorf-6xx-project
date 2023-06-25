import serial
import glob
import time
import argparse
import struct
import argparse
import socket
import os

def create_unix_socket(terminal_id):
	socket_path = f"/tmp/trapterm_%d.sock"  % terminal_id

	if os.path.exists(socket_path):
		os.unlink(socket_path)

	try:
		unix_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
		unix_socket.bind(socket_path)
		unix_socket.listen(1)
		return unix_socket

	except Exception as e:
		print(f"Failed to create unix socket for terminal {terminal_id}: {e}")
		raise Error

class TrapTerm():
	def __init__(self,port):
		self.port = port
		self.baud = 115200

		self.serial = serial.Serial(self.port, self.baud)
		time.sleep(2);
		if(self.serial.read(6) == "boot\r\n"):
			print("terminal driver connected.")

	def new_terminal(self,termid):
		self.serial.write(b't')
		self.serial.write(struct.pack("b",termid))
		return self.serial.read(1)

	def get_fifo_status(self):
		self.serial.write(b'p')
		count = ord(self.serial.read(1))
		poll = {}
		for i in range(count):
			(inuse,termid,output,intput) = struct.unpack("bbbb",self.serial.read(4))
			poll[termid] = {"output_remaining":output,"input_available":intput}
		return poll


	def terminal_recv(self, terminal_id):
		self.serial.write(b"s")
		self.serial.write(struct.pack("b",terminal_id))
		blen =  self.serial.read(1)
		return self.serial.read(blen)


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



#python3 itsatrap.py -p /dev/tty.usbmodem142401  --mode terminal  10 11 12

parser = argparse.ArgumentParser(description='trapterm server')
parser.add_argument('-p', '--port', type=str, help='Serial port name')

parser.add_argument("--terminal_ids", type=int, nargs="+", help="Terminal ID numbers")

parser.add_argument("--mode", choices=["hello", "terminal"], default="terminal", help="Operating mode: 'hello' or 'terminal' (default: terminal)")

args = parser.parse_args()


def socket_forever(tt, sockdict):
	
	while(1):
		time.sleep(2 ) #debugging
		fifolist = tt.get_fifo_status()
		print(fifolist)
		sockets_to_check  = [value for value in sockdict.values()]
	
		for t,f in fifolist.items():
			if f["input_available"] > 0:
				d = tt.terminal_recv(f["input_available"])
#				pass #fixme read the data
				
#		sockread, _, _ = select.select(sockets_to_check, [], [], 0)

#		for t,s in sockdicte.items():
#			if f["output_remaining"] > 0:
#				pass #fixme read the data


if __name__ == '__main__':
	tt = TrapTerm(args.port)
	print(tt.get_fifo_status())

	if args.mode == "terminal":	#no
		sockdict = {}
		for terminal_id in args.terminal_ids:
			sockdict[terminal_id] = create_unix_socket(terminal_id)
			print(tt.new_terminal(terminal_id), terminal_id)
		print(tt.get_fifo_status())

		socket_forever(tt, sockdict)


	elif arg.mode == "hello":
		for i in range(64):
			print(tt.new_term(i))
			tt.terminal_send(i, b"hello world!\n")
			print("said hello to terminal %d" % i)
			time.sleep(.2)
