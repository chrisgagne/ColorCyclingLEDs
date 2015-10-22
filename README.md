ColorCyclingLEDs
================

A trippy color-cycling LED music visualization, similar to the late Nirvana Engine. See https://chrisgagne.com/1877/a-sound-sensitive-led-disco-suit-part-1/ for more details.

This is a Processing sketch that works with the fadecandy LED control board.

The sketch randomly displays a gradient (#.gif) with each kick beat. 

The sketch loads color lookup tables (lut#.gif), hereafter CLUTs. 

The red, green, and blue channels of the CLUTs are cycled over the gradients independently. This rotation is based both on time as well as audio levels on FFTs on low, medium, and high frequencies. Both the speed of the time-based color rotation as well as the sound-sensitivity can be configured. There are several different beat detection modes in different folders to play with. I recommend starting with ColorCyclingLEDsInputLiteFFTBeatDetect as it allows for sound sensitivity adjustments.

This now includes the LED library, sound input (various techniques), and keyboard interactivity. It works great on a RaspberryPi with 150 LEDs and should easily scale to 250 or more.

My chief focus has been on getting this ready for my use on the Playa, not making it fully presentable for others to use turn-key. I will create a better write-up after the Playa. However, anyone with familiarity with LEDs and Processing should be able to make great use of this for their project. Please share your improvements, too!

If you happen to see a guy walking around the playa in a BetaBrand Discoium jumpsuit covered in 250 LEDs or a hoodie covered with 150 LEDs, that's me. Say hello!

Happy hacking!
