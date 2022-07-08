from PyP100 import PyP100

def turn_plug_on(ip_address, username, password ):
	p100 = PyP100.P100(ip_address, username, password) #Creating a P100 plug object

	p100.handshake() #Creates the cookies required for further methods

	p100.login() #Sends credentials to the plug and creates AES Key and IV for further methods

	p100.turnOn() #Sends the turn on request
	
def turn_plug_off(ip_address, username, password ):
	p100 = PyP100.P100(ip_address, username, password) #Creating a P100 plug object

	p100.handshake() #Creates the cookies required for further methods

	p100.login() #Sends credentials to the plug and creates AES Key and IV for further methods

	p100.turnOff() #Sends the turn off request
