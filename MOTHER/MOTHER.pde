import processing.serial.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;
int DATABUFFERSIZE = 80;
int[]  dataBuffer = new int[DATABUFFERSIZE+1];
char startChar, endChar, delimiterChar;
boolean directionA = false;
boolean directionB = false;

String val;
color headerBG, bodyBG, highlight, black, white, red, green;
int now, lastTime, time, sampleTime;
float resolution;

public class Motor {
  public int overCurrent;
  public int motorFault;
  public int velInCounts;
  public float velInInches;
}

public class Move {
  public int standbyD;
  public int standbyT;
  public int standbyAT;
  public int standbyDT;
  public int direction;
}

public class textFields {
  public Textfield distance;
  public Textfield time;
  public Textfield aTime;
  public Textfield dTime;
}

Motor motorA = new Motor();
Motor motorB = new Motor();
Move moveA = new Move();
Move moveB = new Move();

textFields fieldsA = new textFields();
textFields fieldsB = new textFields();

int transmissionLost;
int Estop;
PFont headerFont;
PFont textFont;
PFont inputFont;

Textfield distanceA, distanceB, timeA, atimeA, dtimeA;

/*        END initialization
************************************************************/

/************************************************************
          BEGIN setup                                      */
          
void setup() {
  headerFont = loadFont("Impact-48.vlw");
  textFont = loadFont("Georgia-Bold-16.vlw");
  inputFont = createFont("arial",16);
  headerBG = color(255,215,0);
  bodyBG = color(238,221,130);
  highlight = color(184,134,11);
  white = color(255,255,255);
  black = color(0,0,0);
  red = color(255,0,0);
  green = color(12,214,0);
  cp5 = new ControlP5(this);
  startChar = '!';
  endChar = 255;
  delimiterChar = ',';
  resolution = 93.2;

  // Draw the background
  size(600,625);
  background(bodyBG);
  drawHeader();
  drawStatusArea();
  drawCueingArea();
  drawControlArea();
  drawCueingInput();

//  myPort = new Serial(this, "COM11", 9600);
//  myPort.bufferUntil(endChar);
  lastTime = 0;
  sampleTime = 300;
}

/*        END setup
************************************************************/

/************************************************************
          BEGIN draw loop                                  */
          
void draw() {
  now = millis();
  time = now - lastTime;
  if(time > sampleTime) {
    transmissionLost = 1;
  } else {
    transmissionLost = 0;
  }
  
  if(transmissionLost > 0) {
    onIndicator(50,500);
  } else {
    offIndicator(50,500);
  }
  
  if(Estop > 0) {
    onIndicator(50,525);
  } else {
    offIndicator(50,525);
  }
  
  if(motorA.overCurrent > 0) {
    onIndicator(50,570);
  } else {
    offIndicator(50,570);
  }
  
  if(motorB.overCurrent > 0) {
    onIndicator(250,570);
  } else {
    offIndicator(250,570);
  }
  
  drawMotorFaults();
  drawMotorVelocity();
  drawStandbyCues();
}

/*        END draw loop
************************************************************/

/************************************************************
          BEGIN serialEvent                                */
          

void serialEvent(Serial myPort) {
  boolean gotString = false;
  gotString = getSerialString();
  if(gotString) {
    lastTime = now;
    Estop = int(dataBuffer[0]) >> 6 & 0x01;
    motorA.overCurrent = int(dataBuffer[0]) >> 5 & 0x01;
    motorB.overCurrent = int(dataBuffer[0]) >> 4 & 0x01;
    motorA.motorFault = int(dataBuffer[0]) >> 2 & 0x03;
    motorB.motorFault = int(dataBuffer[0]) & 0x03;
    motorA.velInCounts = int(dataBuffer[1]) << 8 | int(dataBuffer[2]);
    motorB.velInCounts = int(dataBuffer[3]) << 8 | int(dataBuffer[4]);
    moveA.standbyD = int(dataBuffer[5]);
    moveA.standbyT = int(dataBuffer[6]);
    moveA.standbyAT = int(dataBuffer[7]);
    moveA.standbyDT = int(dataBuffer[8]);
    moveA.direction = int(dataBuffer[9]);
//    moveB.standbyD = int(dataBuffer[9]);
//    moveB.direction = int(dataBuffer[10]);
    
    motorA.velInInches = motorA.velInCounts / resolution;
    motorB.velInInches = motorB.velInCounts / resolution;
  }
}

/*        END serialEvent
************************************************************/

/************************************************************
          BEGIN standby                                    */
          
public void standby() {
  String dA = distanceA.getText();
  String tA = timeA.getText();
  String atA = atimeA.getText();
  String dtA = dtimeA.getText();
  String dB = distanceB.getText();

  if(dA.isEmpty()) dA = "0";
  if(tA.isEmpty()) tA = "0";
  if(atA.isEmpty()) atA = "0";
  if(dtA.isEmpty()) dtA = "0";
  if(dB.isEmpty()) dB = "0";

  byte[] data = new byte[9];
  int fdA = int(dA);
  int ftA = int(tA);
  int fatA = int(atA);
  int fdtA = int(dtA);
  int fdB = int(dB);

  data[0] = byte('!');
  data[1] = byte(1);
  data[2] = byte(fdA);
  data[3] = byte(ftA);
  data[4] = byte(fatA);
  data[5] = byte(fdtA);
  if(directionA) data[6] = 0;
  if(!directionA) data[6] = 1;
  data[7] = byte(fdB);
  if(directionB) data[8] = 0;
  if(!directionB) data[8] = 1;

//  for(int i = 0; i < 9; i++) {
//    myPort.write(data[i]);
//    myPort.write(',');
//  }
//  myPort.write(byte(255));
  distanceA.clear();
  distanceB.clear();
  timeA.clear();
  atimeA.clear();
  dtimeA.clear();
}

/*        END standby
************************************************************/

/************************************************************
          BEGIN go                                         */
          

public void go() {
  myPort.write('!');
  myPort.write(2);
  myPort.write(255);
}

/*        END go
************************************************************/

public void stop() {
  myPort.write('!');
  myPort.write(3);
  myPort.write(255);
}

/************************************************************
          BEGIN drawHeader                                 */
          
void drawHeader() {
  fill(headerBG);
  stroke(headerBG);
  rect(0,0,600,100);
  stroke(highlight);
  strokeWeight(3);
  line(0,100,600,100);
  fill(black);
  textAlign(CENTER,CENTER);
  textFont(headerFont, 36);
  text("MOTHER", 300, 45);
  textSize(25);
  text("(IZZY Control Interface)", 300, 85);
}

/*        END drawHeader
************************************************************/

/************************************************************
          BEGIN drawStatusArea                             */
          
void drawStatusArea() {
  fill(white);
  stroke(highlight);
  strokeWeight(1);
  rect(25, 450, 550, 150);
  fill(highlight);
  textSize(16);
  text("Status Indicators", 300, 468);
  
  // Draw the default indicator labels
  fill(black);
  textFont(textFont, 14);
  textAlign(LEFT,CENTER);
  text("Transmission Lost",75,500);
  text("E-Stop",75,525);
  textAlign(CENTER,CENTER);
  text("Overcurrent",150,550);
  fill(black);
  textAlign(LEFT,CENTER);
  text("Motor A",75,570);
  textAlign(RIGHT,CENTER);
  text("Motor B",225,570);
  textAlign(CENTER,CENTER);
  text("Fault Conditions",425,530);
  textAlign(LEFT,CENTER);
  text("Motor A",315,500);
  textAlign(RIGHT,CENTER);
  text("Motor B",540,500);
  textAlign(CENTER,CENTER);
  text("Current Velocity\n(in/sec)",425,571);
}

/*        END drawStatusArea
************************************************************/

/************************************************************
          BEGIN drawCueingArea                             */
          
void drawCueingArea() {
  // Draw cuing area background
  fill(white);
  rect(25, 125, 270, 300);
  rect(189,218,31,21);
  rect(244,218,31,21);
  fill(highlight);
  textFont(headerFont, 16);
  textAlign(CENTER, CENTER);
  text("Cue Entry", 150, 145);
  fill(black);
  textFont(textFont,12);
  text("A",205,170);
  text("B",260,170);
  textAlign(LEFT, CENTER);
  text("Travel distance (in):",40,195);
  text("Direction",40,235);
  text("Travel time (secs):",40,270);
  text("Accel time (secs):",40,310);
  text("Decel time (secs):",40,350);
  textFont(textFont,10);
  text("R",190,246);
  text("R",244,246);
  textAlign(RIGHT, CENTER);
  text("F",221,246);
  text("F",275,246);
}

/*        END drawCueingArea
************************************************************/

/************************************************************
          BEGIN drawControlArea                                */
          
void drawControlArea() {
  fill(white);
  rect(325, 125, 250, 300);
  fill(highlight);
  textFont(headerFont, 16);
  textAlign(CENTER, CENTER);
  text("Control", 450, 145);
  fill(black);
  textFont(textFont,12);
  text("A",475,170);
  text("B",525,170);
  textAlign(LEFT, CENTER);
  text("Loaded Cue",335,170);
  textFont(textFont,10);
  text("Travel distance (in):",335,195);
  text("Direction",335,225);
  text("Travel time (secs):",335,255);
  text("Accel time (secs):",335,285);
  text("Decel time (secs):",335,315);
}

/*        END drawControlArea
************************************************************/

/************************************************************
          BEGIN drawCueingInput                            */

void drawCueingInput() {
  distanceA = cp5.addTextfield("distanceA")
     .setPosition(190,180)
     .setSize(30,30)
     .setFont(inputFont)
     .setFocus(true)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

  distanceB = cp5.addTextfield("distanceB")
     .setPosition(245,180)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

  timeA = cp5.addTextfield("timeA")
     .setPosition(218,255)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(0,0,0))
     .setColorBackground(color(255,255,255))
     .setColorForeground(color(184, 134, 11))
     .setColorActive(color(0,0,0))
     .setAutoClear(false)
     ;

  atimeA = cp5.addTextfield("atimeA")
     .setPosition(218,295)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

  dtimeA = cp5.addTextfield("dtimeA")
     .setPosition(218,335)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;
  
  cp5.addToggle("directionA")
      .setPosition(190,219)
      .setSize(30,20)
      .setValue(true)
      .setMode(ControlP5.SWITCH)
      .setColorBackground(color(white))
      .setColorActive(color(highlight))
      ;
      
  cp5.addToggle("directionB")
      .setPosition(245,219)
      .setSize(30,20)
      .setValue(true)
      .setMode(ControlP5.SWITCH)
      .setColorBackground(color(white))
      .setColorActive(color(highlight))
      ;
  
  cp5.addButton("standby")
     .setPosition(190,380)
     .setColorBackground(color(highlight))
     .setColorForeground(color(highlight))
     .setSize(90,30)
     .setValueLabel("Standby")
     ;
     
  cp5.addButton("stop")
     .setPosition(350,340)
     .setImage(loadImage("Stop-Button.png"))
     .updateSize();
     ;

  cp5.addButton("go")
     .setPosition(475,340)
     .setImage(loadImage("Go-Button.png"))
     .updateSize();
     ;
}

/*        END drawCueingInput
************************************************************/

void onIndicator(int x, int y) {
  fill(red);
  stroke(red);
  ellipse(x,y,9,9);
}

void offIndicator(int x, int y) {
  stroke(highlight);
  fill(white);
  ellipse(x,y,9,9);
}

void drawMotorFaults() {
  textFont(inputFont,14);
  textAlign(CENTER, CENTER);
  if(motorA.motorFault > 0) {
    stroke(red);
    fill(white);
    rect(320,515,30,30);
    fill(red);
  } else {
    stroke(highlight);
    fill(white);
    rect(320,515,30,30);
    fill(black);
  }
  text(motorA.motorFault,335,530);

  if(motorB.motorFault > 0) {
    stroke(red);
    fill(white);
    rect(495,515,30,30);
    fill(red);
  } else {
    stroke(highlight);
    fill(white);
    rect(495,515,30,30);
    fill(black);
  }
  text(motorB.motorFault,510,530);
}

void drawMotorVelocity() {
  stroke(highlight);
  fill(white);
  rect(320,555,30,30);
  rect(495,555,30,30);
  fill(black);
  textAlign(CENTER,CENTER);
  text(round(motorA.velInInches),335,570);
  text(round(motorB.velInInches),510,570);  
}

void drawStandbyCues() {
  textFont(inputFont,12);
  textAlign(CENTER, CENTER);
  stroke(white);
  fill(white);
  rect(440,180,125,200);
  
  fill(black);
  text(moveA.standbyD,475,195);
  text(moveB.standbyD,525,195);
  text(moveA.standbyT,500,255);
  text(moveA.standbyAT,500,285);
  text(moveA.standbyDT,500,315);
  if(moveA.direction == 0) {
    text("F",475,225);
  } else {
    text("R",475,225);
  }
  if(moveB.direction == 0) {
    text("F",525,225);
  } else {
    text("R",525,225);
  }
}

boolean getSerialString() {
  int dataBufferIndex = 0;
  boolean storeString = false;
  while(myPort.available() > 0 ) {
    int incomingByte = myPort.read();
    if(incomingByte == '!') {
      dataBufferIndex = 0;
      storeString = true;
    }
    if(storeString) {
      if(dataBufferIndex == DATABUFFERSIZE) {
        dataBufferIndex = 0;
        break;
      }
      if(incomingByte == endChar) {
        dataBuffer[dataBufferIndex] = 0;
        return true;
      } else {
        if(incomingByte != startChar && incomingByte != delimiterChar) {
          dataBuffer[dataBufferIndex++] = incomingByte;
          dataBuffer[dataBufferIndex] = 0;
        }
      }
    }
  }
  return false;
}