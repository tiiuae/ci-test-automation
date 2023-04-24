from PyP100 import PyP100
from robot.libraries.BuiltIn import BuiltIn


def set_plug_variables():
	ip_address = BuiltIn().get_variable_value("${SOCKET_IP_ADDRESS}")
	username = BuiltIn().get_variable_value("${PLUG_USERNAME}")
	password = BuiltIn().get_variable_value("${PLUG_PASSWORD}")
	return ip_address, username, password


p100 = None


def init_plug():
	global p100
	if not p100:
		ip_address, username, password = set_plug_variables()
		p100 = PyP100.P100(ip_address, username, password)  # Creating a P100 plug object
		p100.handshake()  # Creates the cookies required for further methods
		p100.login()  # Sends credentials to the plug and creates AES Key and IV for further methods
	return p100


def turn_plug_on():
	init_plug().turnOn()  # Sends the turn on request


def turn_plug_off():
	init_plug().turnOff()  # Sends the turn off request


def get_plug_info():
	init_plug().getDeviceInfo()  # Returns dict with all the device info
