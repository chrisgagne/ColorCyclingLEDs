// import minim sound library
import ddf.minim.*;
import ddf.minim.analysis.*;

// instantiate minim beat detection, audio in, and FFT
Minim minim;
AudioInput micIn;
FFT fftLog;

// set up gradients - gradient images should be in the data folder and named #.gif, starting with 0.gif
// look at the included gradients to get an idea of how to make your own
int numGradients = 48;

// set up color palette -  palette images should be in the data folder and named lut#.gif, starting with lut0.gif
// look at the included palettes to get an idea of how to make your own
int numPalettes = 8;

// initial brightness (0-10)
int masterBrightness = 10;

// maximum LED brightness (0-255), "hard-coded" so as to not draw more power than the wiring/batteries can handle 
int maxLEDBrightness = 168;

// initial rotation speed (0-100)
float rotationSpeed = 10;

// initial sound sensitivity for palette rotation (0-100)
float soundSensitivity = 10; 

// initial beat sensitivity (0-100)
float beatSensitivity = 50;  

// beat detection sound mode
boolean beatDetectSoundEnergyMode = true;

// initial animation pause state
boolean allPaused = false;

// initial gradient pause state
boolean gradientPaused = false;

// initial palette pause state
boolean palettePaused = false;

// show help text and stats? toggle with '?'
boolean showStats = true;

// gradient width and height
int gradientWidth = 64; 
int gradientHeight = 64; 

// set the color rotation speed factor for each of the three channels, make these different for more interesting effects
int rRotationSpeed = 1;
int gRotationSpeed = 2;
int bRotationSpeed = 3;

// initializing variables used later
float lowAmplitude, midAmplitude, highAmplitude, lastLowAmplitude;  // Amplitude of each frequency band
int imageChoice, lastImage, paletteChoice, lastPalette;  // selected image/palette, last image/palette used
byte[][] gradientOffsets = new byte[numGradients][gradientWidth*gradientHeight]; // arrays containing the offsets so they do not have to be loaded from the image each time
int[][] redPalettes = new int[numPalettes][256];  // create numPalettes redPalettes, each wtih 256 colors based on the loaded palette 
int[][] greenPalettes = new int[numPalettes][256]; // as above in green
int[][] bluePalettes = new int[numPalettes][256]; // as above in blue 
float animationOffset = 0;
PImage[] gradients = new PImage[numGradients];
PImage img = new PImage();

// used to display average frame rate in stats for tuning purposes
int averageFrameRate = 0;

// keep track of the milliseconds since last frame (used for beat detection)
int lastMillis;


void setup()
{
  // set up the canvas
  size(320, 240);

  // Setting the frame rate artificially high as I am doing dev on a MacBook
  // which can handle the high frame rates and I want to see the differences
  // I am making with code optimization.
  frameRate(2000); 

  noSmooth(); // don't smooth as it will slow down the rendering and makes the text harder to read
  loadFont("Tahoma-9.vlw"); // tahoma is easier to read at 9px

  minim = new Minim(this);

  // Get mono sound 
  micIn = minim.getLineIn(Minim.MONO, 1024, 11025, 8);
  micIn.disableMonitoring();

  // create an FFT object that has a time-domain buffer the same size as song's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be 1024. 
  // see the online tutorial for more info.
  fftLog = new FFT( micIn.bufferSize(), micIn.sampleRate() );

  // calculate the averages by grouping frequency bands linearly. use one average for each RGB channel.
  fftLog.linAverages( 3 );

  // load and resize each gradient, then save them into a 2-dimensional array of bytes
  for (int i = 0; i < gradients.length; i ++)
  {
    gradients[i] = loadImage( i + ".gif");
    gradients[i].resize(gradientWidth, gradientHeight);
    gradients[i].loadPixels();
    for (int j = 0; j < (gradientWidth*gradientHeight); j++) {
      gradientOffsets[i][j] = byte(brightness(gradients[i].pixels[j])-128);
    }
  }

  // load palettes
  PImage[] palettes = new PImage[numPalettes];
  PImage palette = new PImage();

  // load each RGB channel of each palette into their respective two-dimensional array. 
  for (int i = 0; i < palettes.length; i ++) {
    palettes[i] = loadImage("lut" + i + ".gif");
    palettes[i].loadPixels();
    for (int j = 0; j < 256; j++) {
      int paletteSample = palettes[i].pixels[j];
      redPalettes[i][j] = int((paletteSample >> 16 & 0xFF));
      greenPalettes[i][j] = int((paletteSample >> 8 & 0xFF));
      bluePalettes[i][j] = int((paletteSample & 0xFF));
    }
  }
}


void draw() {
  if (showStats) {
    fill(0);
    rect(0, gradientHeight+5, width, height-gradientHeight-5);
    fill(255);
    // Keyboard input help
    String helpText = "";
    helpText +="?: Show/hide stats/help (this) \n";
    helpText +="[ ] /: prev/next/auto gradient \n";
    helpText +="{ } \\: prev/next/auto palette \n";
    helpText +="`–0: LED bright 0-100% \n";
    helpText +="( ): inc./dec. base speed \n";
    helpText +="- =: inc./dec. beat sensitivity \n";
    helpText +="_ +: inc./dec. sound sensitivity \n";
    helpText +="[space]: (Un)freeze animation \n";
    helpText +="|: Toggle SOUND_ENERGY mode \n";
    textSize(9);
    text(helpText, 10, gradientHeight + 20);

    // Statistics
    String stats = "";
    averageFrameRate = round(((averageFrameRate * (frameCount - 1)) + frameRate) / frameCount);
    stats += "Average FPS: " + averageFrameRate + "\n";
    stats += "Gradient: " + imageChoice;
    if (gradientPaused) {
      stats += " (paused)\n";
    } 
    else {
      stats += " (auto)\n";
    } 
    stats += "Palette: " + paletteChoice;
    if (palettePaused) {
      stats += " (paused)\n";
    } 
    else {
      stats += " (auto)\n";
    } 
    stats += "Rotation Speed: " + rotationSpeed;
    stats += "\nBeat Sensitivity: " + beatSensitivity;
    stats += "\nSound Sensitivity: " + soundSensitivity;
    stats += "\nBright: " + masterBrightness * 10 +"%";
    stats += " (HW Limit: " + maxLEDBrightness + "/255)";
    text(stats, width/2+10, gradientHeight + 20);
  }
  if (!allPaused) 
  {

    // perform a forward FFT on the samples in song's mix buffer
    fftLog.forward( micIn.mix );

    lowAmplitude = fftLog.getAvg(0) * soundSensitivity;
    midAmplitude = fftLog.getAvg(1) * soundSensitivity;
    highAmplitude = fftLog.getAvg(2) * soundSensitivity;
    animationOffset = (animationOffset + (rotationSpeed/100)) % 255;

    loadPixels();
    for (int i = 0; i < (gradientWidth*gradientHeight); i++) {
      if (gradientOffsets[imageChoice][i] > -128) { // don't change pure black
        pixels[((i - (i % gradientWidth))/gradientWidth)*width+(i % gradientWidth)] = color(
        redPalettes[paletteChoice][(int((lowAmplitude + animationOffset) * rRotationSpeed + gradientOffsets[imageChoice][i] + 128) % 255)], 
        greenPalettes[paletteChoice][(int((midAmplitude + animationOffset) * gRotationSpeed + gradientOffsets[imageChoice][i] + 128) % 255)], 
        bluePalettes[paletteChoice][(int((highAmplitude + animationOffset) * bRotationSpeed + gradientOffsets[imageChoice][i] + 128) % 255)]);
      }
    }
    updatePixels();

    // change the gradient and palette on a kick beat
    if ((millis() - lastMillis) > 400 && fftLog.getAvg(0) > lastLowAmplitude + (100-beatSensitivity)/50) {
      if(!gradientPaused) {changeGradient();}
      if(!palettePaused) {changePalette();}
      lastMillis = millis();
    }

    lastLowAmplitude = fftLog.getAvg(0);
  }
}

void keyPressed() {

  // If the user presses the spacebar, pause or unpause the animation. Does not black-out the LEDs.
  if (key == ' ') { 
    allPaused = ! allPaused;
  }

  // Set brightness to 0. Setting brightness to 0 also pauses the animation.
  if (key == '`') { 
    masterBrightness = 0;
    allPaused = true;
  }

  // Toggle help text and stats
  if (key == '?') { 
    showStats = ! showStats;
    background(0);
  }

  // Set brightness to a non-zero value. Unpauses the animation.

  if (key == '1') { 
    allPaused = false;
    masterBrightness = 1;
  }

  if (key == '2') {
    allPaused = false; 
    masterBrightness = 2;
  }

  if (key == '3') { 
    allPaused = false;
    masterBrightness = 3;
  }

  if (key == '4') { 
    allPaused = false;
    masterBrightness = 4;
  }

  if (key == '5') { 
    allPaused = false;
    masterBrightness = 5;
  }

  if (key == '6') { 
    allPaused = false;
    masterBrightness = 6;
  }

  if (key == '7') { 
    allPaused = false;
    masterBrightness = 7;
  }

  if (key == '8') { 
    allPaused = false;
    masterBrightness = 8;
  }

  if (key == '9') { 
    allPaused = false;
    masterBrightness = 9;
  }

  if (key == '0') { 
    allPaused = false;
    masterBrightness = 10;
  }

  if (key == '(' && rotationSpeed > 0) {
    rotationSpeed--;
  } 

  if (key == ')' && rotationSpeed < 100) {
    rotationSpeed++;
  } 

  if (key == '-' && beatSensitivity > 0) {
    beatSensitivity--;
  } 

  if (key == '=' && beatSensitivity < 100) {
    beatSensitivity++;
  } 

  if (key == '_' && soundSensitivity > 0) {
    soundSensitivity--;
  }  

  if (key == '+' && soundSensitivity < 100) {
    soundSensitivity++;
  }

  if (key == '[') {
    gradientPaused = true; 
    if (imageChoice==0) {
      imageChoice=numGradients-1;
    } 
    else {
      imageChoice--;
    }
  }

  if (key == ']') {
    gradientPaused = true; 
    if (imageChoice==numGradients-1) {
      imageChoice=0;
    } 
    else {
      imageChoice++;
    }
  }

  if (key == '/') { 
    gradientPaused = false;
  }

  if (key == '{') {
    palettePaused = true; 
    if (paletteChoice==0) {
      paletteChoice=numPalettes-1;
    } 
    else {
      paletteChoice--;
    }
  }
  if (
  key == '}') {
    palettePaused = true; 
    if (paletteChoice==numPalettes-1) {
      paletteChoice=0;
    } 
    else {
      paletteChoice++;
    }
  }

  if (key == '\\') { 
    palettePaused = false;
  }
}

void changeGradient() {
  lastImage = imageChoice;
  while (lastImage == imageChoice) imageChoice = int(random(numGradients-1));
}

void changePalette() {
  lastPalette = paletteChoice;
  while (lastPalette == paletteChoice) paletteChoice = int(random(numPalettes));
}

