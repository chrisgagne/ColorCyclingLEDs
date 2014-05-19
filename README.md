ColorCyclingLEDs
================

A trippy color-cycling LED music visualization, similar to the late Nirvana Engine.

This is a Processing sketch. I have not yet added the LED library yet but that is extremely simple to do.

The sketch randomly displays a gradient (#.gif) with each kick beat. 

The sketch loads color lookup tables (lut#.gif), hereafter CLUTs. 

The red, green, and blue channels of the CLUTs are cycled over the gradients independently. This rotation is based both on time as well as audio levels on FFTs on low, medium, and high frequencies. Both the speed of the time-based color rotation as well as the sound-sensitivity can be configured.

TODO

* Do not include 100% black or white areas of the original gradient in the color rotation to allow for persistent design elements.
* Add LED library
* Allow for sound input
* Auto-adjust sensitivity to sound levels
* Allow for keyboard and/or interactivity
	pause gradient
	select a particular gradient
	set brightness
	sensitivity
* Test performance on a Raspberry Pi, BeagleBone Black, or similar (low-amperage device desired)
* Design new gradients