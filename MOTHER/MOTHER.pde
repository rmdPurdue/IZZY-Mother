import processing.serial.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;
int DATABUFFERSIZE = 80;
int[]  dataBuffer = new int[DATABUFFERSIZE+1];
char startChar, endChar, delimiterChar;
boolean direction = false;

String val;
color headerBG, bodyBG, highlight, black, white, red;
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
// Move moveB = new Move();

textFields fieldsA = new textFields();
// textFields fieldsB = new textFields();

int transmissionLost;
int Estop;
PFont headerFont;
PFont textFont;
PFont inputFont;

Textfield distanceA, distanceB, timeA, timeB, atimeA, atimeB, dtimeA, dtimeB;

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
//  drawPIDArea();
  drawCueingInput();

  myPort = new Serial(this, "COM11", 9600);
  myPort.bufferUntil(endChar);
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
    onIndicator(350,165);
  } else {
    offIndicator(350,165);
  }
  
  if(Estop > 0) {
    onIndicator(350,190);
  } else {
    offIndicator(350,190);
  }
  
  if(motorA.overCurrent > 0) {
    onIndicator(350,235);
  } else {
    offIndicator(350,235);
  }
  
  if(motorB.overCurrent > 0) {
    onIndicator(550,235);
  } else {
    offIndicator(550,235);
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
//    moveB.standbyT = int(dataBuffer[10]);
//    moveB.standbyAT = int(dataBuffer[11]);
//    moveB.standbyDT = int(dataBuffer[12]);
    
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
//  String dB = distanceB.getText();
//  String tB = timeB.getText();
//  String atB = atimeB.getText();
//  String dtB = dtimeB.getText();
  if(dA.isEmpty()) dA = "0";
  if(tA.isEmpty()) tA = "0";
  if(atA.isEmpty()) atA = "0";
  if(dtA.isEmpty()) dtA = "0";
//  if(dB.isEmpty()) dB = "0";
//  if(tB.isEmpty()) tB = "0";
//  if(atB.isEmpty()) atB = "0";
//  if(dtB.isEmpty()) dtB = "0";
  byte[] data = new byte[9];
  int fdA = int(dA);
  int ftA = int(tA);
  int fatA = int(atA);
  int fdtA = int(dtA);
//  int fdB = int(dB);
//  int ftB = int(tB);
//  int fatB = int(atB);
//  int fdtB = int(dtB);
  data[0] = byte('!');
  data[1] = byte(1);
  data[2] = byte(fdA);
  data[3] = byte(ftA);
  data[4] = byte(fatA);
  data[5] = byte(fdtA);
  if(direction) data[6] = 0;
  if(!direction) data[6] = 1;
//  data[5] = byte(fdB);
//  data[6] = byte(ftB);
//  data[7] = byte(fatB);
//  data[8] = byte(fdtB);
  for(int i = 0; i < 7; i++) {
    myPort.write(data[i]);
    myPort.write(',');
  }
  myPort.write(byte(255));
  distanceA.clear();
//  distanceB.clear();
  timeA.clear();
//  timeB.clear();
  atimeA.clear();
//  atimeB.clear();
  dtimeA.clear();
//  dtimeB.clear();  
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
  rect(325, 125, 250, 300);
  fill(highlight);
  textSize(16);
  text("Status Indicators", 450, 140);
  
  // Draw the default indicator labels
  fill(black);
  textFont(textFont, 14);
  textAlign(LEFT,CENTER);
  text("Transmission Lost",370,165);
  
  fill(white);
  ellipse(350,190,10,10);
  fill(black);
  text("E-Stop",370,190);
  
  textAlign(CENTER,CENTER);
  text("Overcurrent",450,215);
  fill(white);
  ellipse(350,235,10,10);
  ellipse(550,235,10,10);
  fill(black);
  textAlign(LEFT,CENTER);
  text("Motor A",370,235);
  textAlign(RIGHT,CENTER);
  text("Motor B",535,235);
  
  textAlign(CENTER,CENTER);
  text("Fault Conditions",450,265);
  textAlign(LEFT,CENTER);
  text("Motor A",370,285);
  textAlign(RIGHT,CENTER);
  text("Motor B",535,285);
  fill(white);
  rect(383,295,30,30);
  rect(485,295,30,30);
  
  fill(black);
  textAlign(CENTER,CENTER);
  text("Current Velocity (in/sec)",450,350);
  textAlign(LEFT,CENTER);
  text("Motor A",370,370);
  textAlign(RIGHT,CENTER);
  text("Motor B",535,370);
  fill(white);
  rect(378,380,40,30);
  rect(480,380,40,30);
}

/*        END drawStatusArea
************************************************************/

/************************************************************
          BEGIN drawCueingArea                             */
          
void drawCueingArea() {
  // Draw cuing area background
  fill(white);
  rect(25, 125, 270, 300);
  rect(129,349,51,21);
  fill(highlight);
  textFont(headerFont, 16);
  textAlign(CENTER, CENTER);
  text("Cue for Izzy", 150, 140);
  fill(black);
  textFont(textFont,10);
  text("Loaded Cue",255,155);
  textFont(textFont,12);
//  text("A",150,170);
//  text("B",195,170);
//  text("A",240,170);
//  text("B",275,170);
  textAlign(LEFT, CENTER);
  text("Travel\ndistance (in):",40,195);
  text("Travel\ntime (secs):",40,240);
  text("Accel\ntime (secs):",40,285);
  text("Decel\ntime (secs):",40,330);
  text("Direction",40,360);
  text("R",185,360);
  textAlign(RIGHT, CENTER);
  text("F",125,360);
}

/*        END drawCueingArea
************************************************************/

/************************************************************
          BEGIN drawPIDArea                                */
          
void drawPIDArea() {
  fill(white);
  rect(25, 450, 550, 150);
  fill(highlight);
  textFont(headerFont, 16);
  textAlign(CENTER, CENTER);
  text("PID Loop Setup", 300, 465);
  fill(black);
  textFont(textFont,14);
  textAlign(LEFT, CENTER);
  text("Motor A",40,490);
  textSize(12);
  text("kp:",40,515);
  text("ki:",100,515);
  text("kd:",160,515);
  text("Minimum:",220,515);
  text("Maximum:",320,515);
  text("Sample time:",420,515);
  textSize(14);
  text("Motor B",40,545);
  textSize(12);
  text("kp:",40,565);
  text("ki:",100,565);
  text("kd:",160,565);
  text("Minimum:",220,565);
  text("Maximum:",320,565);
  text("Sample time:",420,565);
}

/*        END drawPIDArea
************************************************************/

/************************************************************
          BEGIN drawCueingInput                            */

void drawCueingInput() {
  distanceA = cp5.addTextfield("distanceA")
     .setPosition(135,180)
     .setSize(30,30)
     .setFont(inputFont)
     .setFocus(true)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

//  distanceB = cp5.addTextfield("distanceB")
//     .setPosition(180,180)
//     .setSize(30,30)
//     .setFont(inputFont)
//     .setColor(color(black))
//     .setColorBackground(color(white))
//     .setColorForeground(color(highlight))
//     .setColorActive(color(black))
//     .setAutoClear(false)
//     ;

  timeA = cp5.addTextfield("timeA")
     .setPosition(135,225)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(0,0,0))
     .setColorBackground(color(255,255,255))
     .setColorForeground(color(184, 134, 11))
     .setColorActive(color(0,0,0))
     .setAutoClear(false)
     ;

//  timeB = cp5.addTextfield("timeB")
//     .setPosition(180,225)
//     .setSize(30,30)
//     .setFont(inputFont)
//     .setColor(color(black))
//     .setColorBackground(color(white))
//     .setColorForeground(color(highlight))
//     .setColorActive(color(black))
//     .setAutoClear(false)
//     ;

  atimeA = cp5.addTextfield("atimeA")
     .setPosition(135,270)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

//  atimeB = cp5.addTextfield("atimeB")
//     .setPosition(180,270)
//     .setSize(30,30)
//     .setFont(inputFont)
//     .setColor(color(black))
//     .setColorBackground(color(white))
//     .setColorForeground(color(highlight))
//     .setColorActive(color(black))
//     .setAutoClear(false)
//     ;

  dtimeA = cp5.addTextfield("dtimeA")
     .setPosition(135,315)
     .setSize(30,30)
     .setFont(inputFont)
     .setColor(color(black))
     .setColorBackground(color(white))
     .setColorForeground(color(highlight))
     .setColorActive(color(black))
     .setAutoClear(false)
     ;

//  dtimeB = cp5.addTextfield("dtimeB")
//     .setPosition(180,315)
//     .setSize(30,30)
//     .setFont(inputFont)
//     .setColor(color(black))
//     .setColorBackground(color(white))
//     .setColorForeground(color(highlight))
//     .setColorActive(color(black))
//     .setAutoClear(false)
//     ;
  
  cp5.addToggle("direction")
      .setPosition(130,350)
      .setSize(50,20)
      .setValue(true)
      .setMode(ControlP5.SWITCH)
      .setColorBackground(color(white))
      .setColorActive(color(highlight))
      ;
  
  cp5.addButton("standby")
     .setPosition(50,380)
     .setColorBackground(color(highlight))
     .setColorForeground(color(highlight))
     .setSize(100,30)
     .setValueLabel("Standby")
     ;

  cp5.addButton("go")
     .setPosition(175,380)
     .setColorBackground(color(highlight))
     .setColorForeground(color(highlight))
     .setSize(100,30)
     .setValueLabel("Go")
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
    rect(383,295,30,30);
    fill(red);
  } else {
    stroke(highlight);
    fill(white);
    rect(383,295,30,30);
    fill(black);
  }
  text(motorA.motorFault,398,310);

  if(motorB.motorFault > 0) {
    stroke(red);
    fill(white);
    rect(485,295,30,30);
    fill(red);
  } else {
    stroke(highlight);
    fill(white);
    rect(485,295,30,30);
    fill(black);
  }
  text(motorB.motorFault,500,310);
}

void drawMotorVelocity() {
  stroke(highlight);
  fill(white);
  rect(378,380,40,30);
  rect(480,380,40,30);
  fill(black);
  textAlign(CENTER,CENTER);
  text(round(motorA.velInInches),397,395);
  text(round(motorB.velInInches),499,395);  
}

void drawStandbyCues() {
  textFont(inputFont,12);
  textAlign(CENTER, CENTER);
  stroke(white);
  fill(white);
  rect(230,180,30,200);
  rect(250,180,30,200);
  
  fill(black);
  text(moveA.standbyD,240,195);
  text(moveA.standbyT,240,240);
  text(moveA.standbyAT,240,285);
  text(moveA.standbyDT,240,330);
  if(moveA.direction == 0) {
    text("F",240,358);
  } else {
    text("R",240,358);
  }
//  text(moveB.standbyD,275,195);
//  text(moveB.standbyT,275,240);
//  text(moveB.standbyAT,275,285);
//  text(moveB.standbyDT,275,330);
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