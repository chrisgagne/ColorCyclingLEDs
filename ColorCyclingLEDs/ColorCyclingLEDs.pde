import processing.video.*;
 
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;

// BeatDetection stuff
BeatDetect beat;
BeatListener bl;

// FFT stuff
FFT fftLin;
FFT fftLog;

// set up images - images should be in the data folder and named #.gif
int numImages = 48 - 1; // subtracting 1 due to indexing at 0 later
PImage[] images = new PImage[numImages];
PImage img = new PImage();
int imageChoice, lastImage; 

// suit image
PImage suitImage = new PImage();

// set up color palette - palettes should be in the data folder and named lut#.gif
int numPalettes = 4 - 1; // subtracting 1 due to indexing at 0 later
PImage[] palettes = new PImage[numPalettes];
PImage palette = new PImage();
int paletteChoice, lastPalette;
int[][] redPalettes = new int[numPalettes][256];
int[][] greenPalettes = new int[numPalettes][256];
int[][] bluePalettes = new int[numPalettes][256];
float brightness;
int offset;
color paletteSample;

// variables to use during color cycling
int lowAmplitude, midAmplitude, highAmplitude;  

// set the base sound sensitivity for palette rotation
int paletteSensitivity = 32; 

// set the color rotation speed for each of the three channels, make these different for more interesting effects
int rRotationSpeed = 1;
int gRotationSpeed = 2;
int bRotationSpeed = 3;

class BeatListener implements AudioListener
{
  private BeatDetect beat;
  private AudioPlayer source;
  BeatListener(BeatDetect beat, AudioPlayer source)
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
  size(640, 480);
  frameRate(120);

  minim = new Minim(this);
  song = minim.loadFile("marcus_kellis_theme.mp3", 1024);
  song.play();
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());

  // set the sensitivity to 400 milliseconds, which reflects a maximum tempo of 150 BPM
  beat.setSensitivity(400);  

  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, song);  

  // create an FFT object that has a time-domain buffer the same size as song's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be 1024. 
  // see the online tutorial for more info.
  fftLin = new FFT( song.bufferSize(), song.sampleRate() );

  // calculate the averages by grouping frequency bands linearly. use one average for each RGB channel.
  fftLin.linAverages( 3 );

  // load and resize images
  for (int i = 0; i < images.length; i ++)
  {
    images[i] = loadImage( i + ".gif");
    images[i].resize(width, height);
    //images[i].filter(BLUR,8);
    
  }

  // load color palettes into a two-dimensional array for each channel
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
}


void draw()
{
 
  // set the background image
  image(images[imageChoice], 0, 0);

  //image(images[imageChoice], 122, 0, 200, height);
  //image(images[imageChoice], 342, 0, 200, height);

  // perform a forward FFT on the samples in song's mix buffer
  // note that if song were a MONO file, this would be the same as using song.left or song.right
  fftLin.forward( song.mix );

  lowAmplitude = int(fftLin.getAvg(0) * paletteSensitivity);
  midAmplitude = int(fftLin.getAvg(1) * paletteSensitivity);
  highAmplitude = int(fftLin.getAvg(2) * paletteSensitivity);

  loadPixels();
  for (int i = 0; i < (width*height); i++) {
    offset = int(brightness(pixels[i]));
    if (offset < 255 && offset > 0) {
      pixels[i] = color(
      redPalettes[paletteChoice][(frameCount * rRotationSpeed + lowAmplitude + offset) % 255], 
      greenPalettes[paletteChoice][(frameCount * gRotationSpeed + midAmplitude + offset) % 255], 
      bluePalettes[paletteChoice][(frameCount * bRotationSpeed + highAmplitude + offset) % 255]);
    }
  }

  updatePixels();

  // change the background image on a kick beat
  if ( beat.isKick() ) {
    // ensure that we don't choose the same image twice ensuring that we always get a change with the beat
    lastImage = imageChoice;
    while (lastImage == imageChoice) imageChoice = int(random(numImages));
  }

  // change the color palette on a kick beat, left separate to play with other beat types later
  if ( beat.isKick() ) {
    // ensure that we don't choose the same image twice ensuring that we always get a change with the beat
    lastPalette = paletteChoice;
    while (lastPalette == paletteChoice) paletteChoice = int(random(numPalettes));
  }
  
  // led preview stuff
  // image(suitImage, 0, 0);
  
  // display the frame rate in the title
  frame.setTitle("FPS: " + int(frameRate));
}

