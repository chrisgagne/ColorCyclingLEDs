import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;

// BeatDetection stuff
BeatDetect beat;
BeatListener bl;
AudioInput micIn;

// FFT stuff
FFT fftLin;
FFT fftLog;


// set up images - images should be in the data folder and named #.gif, starting with 0.gif
int numImages = 48;

// set up color palette -  should be in the data folder and named lut#.gif, starting with lut0.gif
int numPalettes = 8;

// initial brightness (0-10)
int masterBrightness = 10;

// maximum LED brightness (0-255), "hard-coded" so as to not draw more power than the wiring/batteries can handle 
int maxBrightness = 168;

// initial rotation speed (0-1)
float rotationSpeed = .5;

// initial sound sensitivity for palette rotation
float paletteSensitivity = .25; 

// initial animation pause state
boolean allPaused = false;

// initial gradient pause state
boolean gradientPaused = false;

// initial CLUT pause state
boolean clutPaused = false;


// initialize variables used later
int lowAmplitude, midAmplitude, highAmplitude;  // Amplitude of each channel
int imageChoice, lastImage, paletteChoice, lastPalette;  // selected image/CLUT, last image/CLUT used
int[][] redPalettes = new int[numPalettes][256];
int[][] greenPalettes = new int[numPalettes][256];
int[][] bluePalettes = new int[numPalettes][256];
int brightness;
int offset;
color paletteSample;
PImage[] images = new PImage[numImages];
PImage img = new PImage();
PImage suitImage = new PImage(); // suitImage

// sets the gain
int gain = -80;

// set the color rotation speed factor for each of the three channels, make these different for more interesting effects
int rRotationSpeed = 1;
int gRotationSpeed = 2;
int bRotationSpeed = 3;

class BeatListener implements AudioListener
{
  private BeatDetect beat;
  private AudioInput source;
  BeatListener(BeatDetect beat, AudioInput source)
  {
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }
  void samples(float[] samps)
  {
    beat.detect(source.mix);
  }
  void samples(float[] sampsL, float[] sampsR)
  {
    beat.detect(source.mix);
  }
}

void setup()
{
  // set up the canvas
  size(320, 240);
  noSmooth();
  loadFont("Tahoma-9.vlw");
  minim = new Minim(this);

  micIn = minim.getLineIn(Minim.MONO);
  micIn.setGain(gain);
  micIn.disableMonitoring();

  beat = new BeatDetect(micIn.bufferSize(), micIn.sampleRate());

  // set the sensitivity to 400 milliseconds, which reflects a maximum tempo of 150 BPM
  beat.setSensitivity(400);  

  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, micIn);  

  // create an FFT object that has a time-domain buffer the same size as song's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be 1024. 
  // see the online tutorial for more info.
  fftLin = new FFT( micIn.bufferSize(), micIn.sampleRate() );

  // calculate the averages by grouping frequency bands linearly. use one average for each RGB channel.
  fftLin.linAverages( 3 );
  // load and resize gradients


  for (int i = 0; i < images.length; i ++)
  {
    images[i] = loadImage( i + ".gif");
    images[i].resize(width/2, height);
    //images[i].filter(BLUR,8);
  }

  // load CLUTs
  PImage[] palettes = new PImage[numPalettes];
  PImage palette = new PImage();

  // load CLUTs into a two-dimensional array for each channel
  for (int i = 0; i < palettes.length; i ++) {
    palettes[i] = loadImage("lut" + i + ".gif");
    palettes[i].loadPixels();
    for (int j = 0; j < 256; j++) {
      paletteSample = palettes[i].pixels[j];
      redPalettes[i][j] = int(red(paletteSample));
      greenPalettes[i][j] = int(green(paletteSample));
      bluePalettes[i][j] = int(blue(paletteSample));
    }
  }

  // load suit image
  suitImage = loadImage("suitLeds.png");
  suitImage.resize(width, height);

  println(numImages);
  println(images);
}


void draw() {
  fill(0);
  rect(width/2, 0, width/2, height);
  fill(255);
  // Keyboard input help
  String helpText = "";
  helpText +="[ ] /: prev/next/auto pattern \n";
  helpText +="{ } \\: prev/next/auto CLUT \n";
  helpText +="`–0: LED bright 0-100% \n";
  helpText +="- =: inc./dec. base speed \n";
  helpText +="  _ +: inc/dec sound sensitivity \n";
  helpText +="[space]: (Un)freeze gradient \n";
  textSize(9);
  text(helpText, width/2+10, 20);

  // Statistics
  String stats = "";
  stats += "FPS: " + int(frameRate) + "\n";
  stats += "Gradient: " + imageChoice;
  if (gradientPaused) {
    stats += " (paused)\n";
  } 
  else {
    stats += " (auto)\n";
  } 
  stats += "CLUT: " + paletteChoice;
  if (clutPaused) {
    stats += " (paused)\n";
  } 
  else {
    stats += " (auto)\n";
  } 
  stats += "Rotation Speed: " + rotationSpeed;
  stats += "\nSound Sensitivity: " + paletteSensitivity;
  stats += "\nBright: " + masterBrightness * 10 +"%";
  stats += " (HW Limit: " + maxBrightness + "/255)";
  stats += "\nAll Paused: " + allPaused;
  text(stats, width/2+10, 120);

  if (!allPaused) 
  {


    image(images[imageChoice], 0, 0);

    //image(images[imageChoice], 122, 0, 200, height);
    //image(images[imageChoice], 342, 0, 200, height);

    // perform a forward FFT on the samples in song's mix buffer
    // note that if song were a MONO file, this would be the same as using song.left or song.right
    fftLin.forward( micIn.mix );

    lowAmplitude = int(fftLin.getAvg(0) * paletteSensitivity * 128);
    midAmplitude = int(fftLin.getAvg(1) * paletteSensitivity * 128);
    highAmplitude = int(fftLin.getAvg(2) * paletteSensitivity * 128);

    loadPixels();
    for (int i = 0; i < (width*height); i++) {
      offset = int(brightness(pixels[i]));
      if (offset < 255 && offset > 0) {
        pixels[i] = color(
        redPalettes[paletteChoice][int(frameCount * rRotationSpeed * rotationSpeed + lowAmplitude + offset) % 255], 
        greenPalettes[paletteChoice][int(frameCount * gRotationSpeed * rotationSpeed + midAmplitude + offset) % 255], 
        bluePalettes[paletteChoice][int(frameCount * bRotationSpeed * rotationSpeed + highAmplitude + offset) % 255]);
      }
    }

    updatePixels();

    // darken the display to simulate LED brightness
    fill(0, 0, 0, 255-25.5*masterBrightness);
    rect(0, 0, width/2, height);

    // change the background image on a kick beat
    if ( beat.isKick() && !gradientPaused) {
      // ensure that we don't choose the same image twice ensuring that we always get a change with the beat
      lastImage = imageChoice;
      while (lastImage == imageChoice) imageChoice = int(random(numImages-1));
    }

    // change the color palette on a kick beat, left separate to play with other beat types later
    if ( beat.isKick() && !clutPaused) {
      // ensure that we don't choose the same image twice ensuring that we always get a change with the beat
      lastPalette = paletteChoice;
      while (lastPalette == paletteChoice) paletteChoice = int(random(numPalettes));
    }

    // led preview stuff
    // image(suitImage, 0, 0);
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
  if (key == '-' && rotationSpeed > 0) {
    rotationSpeed = round(rotationSpeed - 0.05, 2);
  } // there were some really silly floating point errors here
  if (key == '=' && rotationSpeed < 1) {
    rotationSpeed = round(rotationSpeed + 0.05, 2);
  } 
  if (key == '_' && paletteSensitivity > 0) {
    paletteSensitivity = round(paletteSensitivity - 0.05, 2);
  }  
  if (key == '+' && paletteSensitivity < 1) {
    paletteSensitivity = round(paletteSensitivity + 0.05, 2);
  }
  if (key == '[') {
    gradientPaused = true; 
    if (imageChoice==0) {
      imageChoice=numImages-1;
    } 
    else {
      imageChoice--;
    }
  }
  if (key == ']') {
    gradientPaused = true; 
    if (imageChoice==numImages-1) {
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
    clutPaused = true; 
    if (paletteChoice==0) {
      paletteChoice=numPalettes-1;
    } 
    else {
      paletteChoice--;
    }
  }
  if (key == '}') {
    clutPaused = true; 
    if (paletteChoice==numPalettes-1) {
      paletteChoice=0;
    } 
    else {
      paletteChoice++;
    }
  }
  if (key == '\\') { 
    clutPaused = false; 
  }
}

float round(float number, float decimal) {
  return (float)(round((number*pow(10, decimal))))/pow(10, decimal);
} 

