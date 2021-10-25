import ddf.minim.analysis.*;
import ddf.minim.*;
import geomerative.*;
import oscP5.*;
import netP5.*;

Minim       minim;
AudioPlayer com;
AudioInput  in;
FFT         fft;
OscP5       oscP5;
NetAddress  myRemoteLocation;
RFont       font;

int num = 10;
int cols, rows;
int scl = 30;
int w = 600;
int h = 2000;
float flying = 0;
float tZ = 200;
float[][] terrainV;
int colR = 255;
int colG = 255;
int colB = 255;
float vertexH;
float sW;
float dS,dN;
float speed;
float [] y = new float [num];
String myText = "HOME COMPUTER ";
Boolean send = false;
Star[] stars = new Star [1500];

void setup()
{
  size(1000, 600, P3D);
  //THE SUN
  for (int n=0; n<num; n++) {
    y[n] = height/num*n;
  }
  sW = height/num/2;
  //THE DUST
  for (int i =0; i<stars.length; i++) {
    stars[i] = new Star();
  }
  //THE TERRAIN
  cols = w/scl;
  rows = h/scl;
  terrainV = new float [cols][rows];
  //THE TEXT
  smooth();
  RG.init(this);
  font = new RFont("Gameplay.ttf", 30, CENTER);
  //AUDIO LIBRARY
  minim = new Minim(this);
  com = minim.loadFile("1.mp3", 1024);
  com.loop();
  fft = new FFT(com.bufferSize(), com.sampleRate() );
  in = minim.getLineIn(Minim.STEREO, 512);
  //TOUCHOSC
  oscP5 = new OscP5(this, 8000);
  myRemoteLocation = new NetAddress("192.168.2.103", 8000);
  //change color
  oscP5.plug(this, "changeC1", "/1/toggle1");
  oscP5.plug(this, "changeC2", "/1/toggle2");
  oscP5.plug(this, "changeC3", "/1/toggle3");
  oscP5.plug(this, "changeC4", "/1/toggle4");
  //change the z value of vertex
  oscP5.plug(this, "changeZ", "/1/fader1");
  //rocket
  oscP5.plug(this, "rocket", "/1/fader2");
  //the dust
  oscP5.plug(this, "changeS", "/1/rotary1");
  oscP5.plug(this, "changeN", "/1/rotary2");
}

/*Visual Effect*/
void draw()
{
  background(0);
  // THE SUN;
  pushMatrix();
  for (int i1= 0; i1 < fft.specSize(); i1++)
  {
    float c1 = fft.getBand(i1);
    translate(0, 0, (-h-c1*5)/3);
    for (int n=0; n<num; n++) {
      float alpha = map(y[n], 0, height, 255, 0);
      stroke(255, 0, 0, alpha);
      strokeWeight(sW);
      line(0, y[n], width, y[n]);
      y[n] +=2;
      if (y[n]>height) y[n]=0;      
    }
    stroke(0);
    strokeWeight(height/3);
    noFill();
    ellipse(width/2, height/2, height*1.5, height*1.5);
  }
  popMatrix();

  //The Dust
  pushMatrix();
  speed  = 5+dS;
  translate (width/2, height/2);
  for (int i =0; i<300+dN; i=i+1) {
    stars[i].display();
    stars[i].update();
  }
  popMatrix();
 
  //THE TEXT
  if (send){
    tZ = tZ-20; 
  }
  if (tZ == -1000){
    tZ = 200;
    send = !send;
  }
  float soundLevel = in.mix.level();
  RCommand.setSegmentLength(soundLevel*50);
  RCommand.setSegmentator(RCommand.UNIFORMLENGTH);
  RGroup myGroup = font.toGroup(myText); 
  RPoint[] myPoints = myGroup.getPoints();
  
  pushMatrix();
  stroke(colR, colG, colB); 
  strokeWeight(1.5);
  noFill();
  translate(360, 2*height/3,tZ);
  rotateY(PI/1.9);
  beginShape(TRIANGLE_STRIP);
  for (int i =0; i<myPoints.length; i++) {
    vertex(myPoints[i].x, myPoints[i].y);
  }
  endShape();
  popMatrix();
  
  pushMatrix();
  stroke(colR,colG,colB); 
  strokeWeight(1.5);
  noFill();
  translate(630, 2*height/3,tZ);//200);
  rotateY(PI/2.1);
  beginShape(TRIANGLE_STRIP);
  for (int i =0; i<myPoints.length; i++) {
    vertex(myPoints[i].x, myPoints[i].y);
  }
  endShape();
  popMatrix();

  //THE TERRAIN//
  stroke(colR, colG, colB);
  fft.forward(com.mix );
  for (int i = 0; i < fft.specSize(); i++)
  {
    float c = fft.getBand(i);
    noFill();
    flying -= 0.1; 
    float yoff = flying;
    for (int y = 0; y<rows; y++) {
      float xoff = 0;
      for (int x= 0; x<cols; x++) {
        terrainV [x][y] = map(noise(xoff, yoff), 0, 1, -vertexH, vertexH);
        xoff += c*10;
      }
      yoff += c*10;
    }
  }
  rotateX(PI/2);
  translate(width/5, -width, -height);
  for (int y = 0; y<rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x= 0; x<cols; x++) {
      vertex(x*scl, y*scl, terrainV[x][y]);
      vertex(x*scl, (y+1)*scl, terrainV[x][y+1]);
    }
    endShape();
  }
}

/*TouchOSC */
// change the color of the terrain 
public void changeC1(float c1) {
  if (c1==1) {
    colR = 255;
    colG = 0;
    colB = 0;
  } else if (c1==0) {
    colR = 255;
    colG = 255;
    colB = 255;
  }
}
public void changeC2(float c2) {
  if (c2==1) {
    colR = 0;
    colG = 255;
    colB = 0;
  } else if (c2==0) {
    colR = 255;
    colG = 255;
    colB = 255;
  }
}
public void changeC3(float c3) {
  if (c3==1) {
    colR = 22;
    colG = 184;
    colB = 243;
  } else if (c3==0) {
    colR = 255;
    colG = 255;
    colB = 255;
  }
}
public void changeC4(float c4) {
  if (c4==1) {
    colR = 255;
    colG = 255;
    colB = 0;
  } else if (c4==0) {
    colR = 255;
    colG = 255;
    colB = 255;
  }
}
//change the z value of the vertex
public void changeZ(float z1) {
  vertexH = z1;
}
//rocket of home computer
public void rocket(float r) {
  if ( r == 1){
    send = true;
  }
}
// the dust
public void changeS(float s) {
  dS = s;
}
public void changeN(float n) {
  dN = n;
}
