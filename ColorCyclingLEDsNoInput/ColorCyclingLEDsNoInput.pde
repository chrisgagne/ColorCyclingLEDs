

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

// gradient width and height
int gradientWidth = 18; 
int gradientHeight = 18;

// initializing variables used later
int imageChoice, lastImage, paletteChoice, lastPalette;  // selected image/CLUT, last image/CLUT used
byte[][] gradientOffsets = new byte[numGradients][gradientWidth*gradientHeight]; // arrays containing the offsets so they do not have to be loaded from the image each time
int[][] redPalettes = new int[numPalettes][256];  // create numPalettes redPalettes, each wtih 256 colors based on the loaded CLUT 
int[][] greenPalettes = new int[numPalettes][256]; // as above in green
int[][] bluePalettes = new int[numPalettes][256]; // as above in blue 
int offset;
color paletteSample;
PImage[] gradients = new PImage[numGradients];
PImage img = new PImage();

// set the color rotation speed factor for each of the three channels, make these different for more interesting effects
int rRotationSpeed = 1;
int gRotationSpeed = 2;
int bRotationSpeed = 3;

// used to display average frame rate in stats for tuning purposes
float averageFrameRate = 0;

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

  // load CLUTs
  PImage[] palettes = new PImage[numPalettes];
  PImage palette = new PImage();

  // load each channel of CLUT into their respective two-dimensional array. 
  for (int i = 0; i < palettes.length; i ++) {
    palettes[i] = loadImage("lut" + i + ".gif");
    palettes[i].loadPixels();
    for (int j = 0; j < 256; j++) {
      paletteSample = palettes[i].pixels[j];
      redPalettes[i][j] = int((paletteSample >> 16 & 0xFF));
      greenPalettes[i][j] = int((paletteSample >> 8 & 0xFF));
      bluePalettes[i][j] = int((paletteSample & 0xFF));
    }
  }
}


void draw() {
  background(0);
  // Keyboard input help
  String helpText = "";
  helpText +="[ ] /: prev/next/auto gradient \n";
  helpText +="{ } \\: prev/next/auto CLUT \n";
  helpText +="`–0: LED bright 0-100% \n";
  helpText +="- =: inc./dec. base speed \n";
  helpText +="[space]: (Un)freeze animation \n";
  textSize(9);
  text(helpText, 10, 140);

  // Statistics
  String stats = "";
  averageFrameRate = round(((averageFrameRate * (frameCount - 1)) + frameRate) / frameCount, 1);
  stats += "Average FPS: " + averageFrameRate + "\n";
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
  stats += " (HW Limit: " + maxLEDBrightness + "/255)";
  stats += "\nAll Paused: " + allPaused;
  text(stats, width/2+10, 140);

  if (!allPaused) 
  {

    loadPixels();
    for (int i = 0; i < (gradientWidth*gradientHeight); i++) {
      offset = gradientOffsets[imageChoice][i];
      pixels[((i - (i % gradientWidth))/gradientWidth)*width+(i % gradientWidth)] = color(
      redPalettes[paletteChoice][(abs(int(frameCount * rRotationSpeed * rotationSpeed + offset) % 255))], 
      greenPalettes[paletteChoice][(abs(int(frameCount * gRotationSpeed * rotationSpeed + offset) % 255))], 
      bluePalettes[paletteChoice][(abs(int(frameCount * bRotationSpeed * rotationSpeed + offset) % 255))]);
    }

    updatePixels();
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

