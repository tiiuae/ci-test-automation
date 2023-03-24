from PyP100 import PyP100
from robot.libraries.BuiltIn import BuiltIn

username = BuiltIn().get_variable_value("${PLUG_USERNAME}")
password = BuiltIn().get_variable_value("${PLUG_PASSWORD}")
device = BuiltIn().get_variable_value("${DEVICE}")
if device == 'NUC':
	ip_address = '172.18.16.30'
elif device == 'ORIN':
	ip_address = '172.18.16.31'


def turn_plug_on():
	p100 = PyP100.P100(ip_address, username, password)  # Creating a P100 plug object

	p100.handshake()  # Creates the cookies required for further methods

	p100.login()  # Sends credentials to the plug and creates AES Key and IV for further methods

	p100.turnOn()  # Sends the turn on request


def turn_plug_off():
	p100 = PyP100.P100(ip_address, username, password)  # Creating a P100 plug object

	p100.handshake()  # Creates the cookies required for further methods

	p100.login()  # Sends credentials to the plug and creates AES Key and IV for further methods

	p100.turnOff()  # Sends the turn off request


def get_plug_info():
	p100 = PyP100.P100(ip_address, username, password)  # Creating a P100 plug object

	p100.handshake()  # Creates the cookies required for further methods

	p100.login()  # Sends credentials to the plug and creates AES Key and IV for further methods

	p100.getDeviceInfo()  # Returns dict with all the device info
