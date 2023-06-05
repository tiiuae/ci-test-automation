# ReflexLoader usage

First, you will need to download the latest BrainStem Software Developer Kit (SDK) from Acroname https://www.acroname.com/software. You will be using three programs in the BDK:
	
* Updater: located in the `\bin` directory of the BDK download
* arc: located in the `\bin\reflex` directory of the BDK download
* ReflexLoader: located in the `\bin\reflex` directory of the BDK download

Follow these steps to update your BrainStem device, then load the reflex.

## 1. Update your Device firmware 

From the command line ($>), use the updater tool to update your device to the latest firmware. Updater will discover attached BrainStem devices and return the serial number of any attached devices in `XXXXXXXX` format. Record the serial number returned from Updater:
```
$> Updater -D
```

Update your device with serial number to the latest firmware using:

```
$> Updater -G -U -d XXXXXXXX
```

## 2. Compile Your Reflex

For simplicity, copy your Reflex file to the `\bin\reflex` directory. Use the arc compiler to compile your `.reflex` file to a `.map` file that can be loaded in to your device:
```
$> arc \path\to\file\ExampleReflex.reflex
```

## 3. Load The Reflex

Load the new reflex `.map` file into your device `XXXXXXXX` into internal slot 0:
```
$> ReflexLoader -L -i ExampleReflex.map -d 0xXXXXXXXX INTERNAL 0
```

## 4. Make the Reflex Bootable

Now that the reflex is loaded in your device, make it bootable so it always runs at power-on or reset:

```
$> ReflexLoader -B -d XXXXXXXX INTERNAL 0 
```

Now power-cycle your device and the new reflex should take effect, running automatically at boot time.

## 4. (Alternative) Manually Enable Your Reflex

Alternatively, you can manually enable your reflex with:
```
$> ReflexLoader -E -d XXXXXXXX INTERNAL 0 
```
Or disable it with:
```
$> ReflexLoader -D -d XXXXXXXX INTERNAL 0
```

More information can be found with:
```
$> ReflexLoader -H
```