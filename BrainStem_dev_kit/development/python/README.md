
# BrainStem Python Library

The BrainStem python package gives access to simple python commands
to control and interact with a collection of BrainStem devices

# Features

- Easily interact with BrainStem devices using python
- Learn more about the capabilities of BrainStem devices in [Acroname's reference documentation](https://acroname.com/reference/)

# Download

- As of version 2.9.21, the BrainStem Python library is available on [PyPI](https://pypi.org/project/brainstem)
- It is also available from the BrainStem Development Kit at [Acroname's downloads page](https://acroname.com/software/brainstem-development-kit)
    - Download the operating system specific BrainStem Development Kit
    - Once downloaded and contents extracted, inside the extracted folder, navigate to:
        - `[project_root]/development/python` to find the latest version of the `brainstem-*.whl`

# Installation

On Windows, to install a new version of BrainStem (or update an existing one), simply execute:

```bash
$> pip install --user brainstem --upgrade
```

Or from wheel file:

```bash
$> pip install --user brainstem-*.whl --upgrade
```

On MacOS and Linux, pip is for the older Python 2 version, pip3 must be executed instead:
```bash
$ pip3 install --user brainstem --upgrade
```

Or from wheel file:

```bash
$ pip3 install --user brainstem-*.whl --upgrade
```

To uninstall the library, the easiest way is with pip:

Windows:

```bash
$> pip uninstall brainstem
```

MacOS and Linux:

```bash
$> pip3 uninstall brainstem
```

# Troubleshooting

- Some additional requirements for installing python wheels in general and the BrainStem wheel specifically may be needed
- If any errors are encountered installing or running the BrainStem python package, see the `Additional Requirements` section near the bottom of this document

# A Tour of the Python Example

After navigating to `[project_root]/development/python_examples`, choose the folder that corresponds with the product being used.  
For example, the most common product sold is Acroname's 8-port hub, so the folder needed in this case will be `usbhub3p_example`.

To run the example, execute:

```bash
$> python usbhub3p_example.py
```

for your specific BrainStem device.  

The example requires that a USB BrainStem link module be connected to the host computer.  
If the following message is seen, there is likely no module connected or the incorrect example program was run:

```
'Could not find a module.'
```

Once the example starts running, it will print out some basic information about
the module and then blink the user LED on the module.

# Working with BrainStem from the Interpreter

The following is a brief introduction to writing a python program that talks to a connected BrainStem:  

Start up the python interpreter:

```bash
$> python
```

The first step is to import the BrainStem package:

```python
>>>  import brainstem
```

- `stem` and `discover` are the two primary modules
- `stem` contains classes for each of the distinct module types:

    * USBStem
    * EtherStem
    * MTMIOSerial
    * MTMUSBStem
    * MTMEtherStem
    * USBHub2x4
    * MTMRelay
    * MTMPM1
    * USBHub3p
    * MTMDAQ1
    * USBCSwitch

Next search for all connected modules:

```python
>>> specs = brainstem.discover.findAllModules(brainstem.link.Spec.USB)
>>> print [str(s) for s in specs]
```

Then search for the first USB module:

```python
>>> spec = brainstem.discover.findFirstModule(brainstem.link.Spec.USB)
>>> print spec
```

If a USB module is found, create a USBStem object and connect to it using
the spec object that was returned by discover:

```python
>>> stem = brainstem.stem.USBStem()
>>> stem.connectFromSpec(spec)
```

Then get some information about the module:

```python
>>> result = stem.system.getModel()
>>> print brainstem.defs.model_info(result.value)
```

Finally, flash the user LED, on or off every 100ms.

```python
>>> from time import sleep
>>> for i in range(0,51):
...     err = stem.system.setLED(i % 2)
...     if err != brainstem.result.Result.NO_ERROR:
...         break
...     sleep(0.1)
...
>>>
```

That's it! Once this basic example is running, a good place to go is the
documentation to learn about all the other features available.

At the prompt type the following:

```python
>>> help(stem.system)
# or
>>> help(brainstem.stem)
```

***

# Additional Requirements

## python

The BrainStem python package is currently compatible with python 2.7 and python 
3.6 through 3.10. When using 2.7 it is recommended that your python version be 
at least 2.7.9.

MS Windows generally does not include Python, and a suitable Python package will need to be [downloaded and installed](https://www.python.org/downloads/) before proceeding with the following guide.  
The BrainStem wheel is compatible with both 32 and 64bit python packages.  
Python version >= 2.7.9 is recommended.

MacOS X and most Linux distributions generally include a Python installation.  
However, the installation may not include pip and setuptools which are required to install the BrainStem Python module.

## pip

The BrainStem python package is installed via a platform specific wheel.  
To install these wheels, a relatively up to date version of pip and setuptools is needed.  
Pip can be installed by following the instructions at:  

https://pip.pypa.io/en/latest/installing.html

If pip is installed it may still be helpful to update pip.   
Administrator privileges may be required on MacOS and Linux.  
Instructions for updating pip can be found at:

https://pip.pypa.io/en/latest/installing.html#upgrade-pip


## libffi

The BrainStem python library relies on libffi.  
On MacOS X and Windows, this is generally available.  
Linux users may need to install libffi via the distro's package manager.  
The package is generally named libffi-dev or similar.

## Python development headers

Linux users may need to install the development package for python
via the distro's package manager before the brainstem wheel can be installed.  
The package is generally named python-dev or similar.

## CentOS package manager

On CentOS and yum based distros the following command will install the required packages:

```bash
$> sudo yum install libffi-devel python-devel
```

***

# Support

If these troubleshooting steps don't solve the issue, please let us know.  
We have a mailing list located at: support@acroname.com
and a [support page](https://acroname.com/contact-us) to get in touch with Acroname support staff.

Enjoy!

The Acroname Team.
