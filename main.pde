import oscP5.*;
import netP5.*;

// OSC
OscP5 oscP5;
NetAddress remAddr;

// control variables
boolean running = false, manual = false;
ArrayList<String> activeKeys = new ArrayList<String>();
int maxSpeed, tSize;
float noiseX = 0;

// user interface
Button toggleProgramB, toggleManualB, exitB;
Button[] bList = new Button[3];
Slider speedSlid, randomSlid;
Slider[] sList = new Slider[2];

// Torus dimensions
float majorR, minorR;

PShape torus;

// maps
float mapHorAngle, mapVerAngle, mapPosX, mapPosY, mapPosZ;
String[][] map = {
  {"d#", "g#", "c#", "f#", "b", "e", "a", "d", "g", "c", "f", "a#"}, // circle of fifths/fourths in minor
  {"C#", "F#", "B", "E", "A", "D", "G", "C", "F", "A#", "D#", "G#"}  // circle of fifths/fourths in major
};
//// the actual 4D positions of the keys (multidimensional scaling solution)
//float[][][] vecMap = {
//  {
//    {-0.207, 0.782, 0.580, -0.119}, // d#
//    {-0.569, 0.573, 0.119, 0.580}, // g#
//    {-0.780, 0.212, -0.580, 0.120}, // c#
//    {-0.781, -0.206, -0.120, -0.580}, // f#
//    {-0.574, -0.570, 0.580, -0.119}, // b
//    {-0.212, -0.780, 0.119, 0.580}, // e
//    { 0.206, -0.781, -0.580, 0.119}, // a
//    { 0.570, -0.574, -0.120, -0.580}, // d
//    { 0.780, -0.212, 0.580, -0.119}, // g
//    { 0.782, 0.206, 0.119, 0.580}, // c
//    { 0.574, 0.570, -0.580, 0.120}, // f
//    { 0.212, 0.780, -0.120, -0.580}  // a#
//  }, 
//  {
//    {-0.175, 0.831, -0.480, -0.208}, // C#
//    {-0.567, 0.633, 0.208, -0.480}, // F#
//    {-0.807, 0.265, 0.480, 0.208}, // B
//    {-0.832, -0.175, -0.208, 0.480}, // E
//    {-0.633, -0.567, -0.480, -0.208}, // A
//    {-0.265, -0.807, 0.208, -0.480}, // D
//    { 0.175, -0.832, 0.481, 0.208}, // G
//    { 0.567, -0.633, -0.208, 0.480}, // C
//    { 0.808, -0.265, -0.480, -0.208}, // F
//    { 0.831, 0.174, 0.208, -0.480}, // A#
//    { 0.633, 0.567, 0.480, 0.208}, // D#
//    { 0.265, 0.807, -0.208, 0.480}  // G#
//  }
//};
PVector[][] vecMap2D = new PVector[2][12];
float[][] weightMap = new float[2][12];

float heat = 1; // higher heat causes more even distribution in choosing new keys (good range is 0.5 - 2)

// axes
PVector x, y, z;
PShape axes;

// pos on torus
float horAngle, verAngle;
PVector currPos = new PVector();

// fundamental problem with a toroidal map is that the outside distances are stretched,
// we don't need to counteract this problem, though, because the radian changes with the radius,
// so when using radii and angles for the movement, the velocity is smaller on the inside, than on the outside
// when using forces, though, the force vectors length would need to be adjusted,
// also there could be a problem with restricting the movement to the face of the torus

void setup() {
  fullScreen(P3D);
  frameRate(30);

  oscP5 = new OscP5(this, 57200);
  remAddr = new NetAddress("127.0.0.1", 57120); // 57120 is the port that SuperCollider is listening to by default

  tSize = 16;

  // Buttons
  toggleProgramB = new Button(new PVector(60, 60), 120, 60, "toggleProgram", "toggle movement (' ')");
  toggleManualB = new Button(new PVector(60, 140), 120, 60, "toggleManual", "random / manual ('m')");
  exitB = new Button(new PVector(20, 20), 30, 25, "exit", "X");
  bList[0] = toggleProgramB;
  bList[1] = toggleManualB;
  bList[2] = exitB;
  // Sliders
  speedSlid = new Slider(new PVector(220, 75), 180, 30, "speed", "speed");
  randomSlid = new Slider(new PVector(480, 75), 180, 30, "random", "randomness");
  sList[0] = speedSlid;
  sList[1] = randomSlid;

  majorR = height/4;
  minorR = majorR/2.2;

  makeTorus();

  makeAxes();

  // random starting point
  horAngle = random(360);
  verAngle = random(360);
  calcPos();

  maxSpeed = 2;

  for (int i = 0; i < 24; i++) {
    mapHorAngle = (int(i/2)*30) % 360;
    mapVerAngle = (int(i/2)*90 + (i%2)*216 + 94) % 360;
    //println(mapHorAngle +"\t"+ mapVerAngle);
    vecMap2D[i%2][int(i/2)] = new PVector(mapHorAngle, mapVerAngle);
  }

  sendWeights(); // send starting weights to SuperCollider
  progStart();
}

void calcPos() {
  currPos.x = majorR * cos(radians(horAngle)) + minorR * cos(radians(verAngle)) * cos(radians(horAngle));
  currPos.y = -minorR * sin(radians(verAngle));
  currPos.z = majorR * sin(radians(horAngle)) + minorR * cos(radians(verAngle)) * sin(radians(horAngle));
}

void makeTorus() {
  // torus segments (horizontal resolution)
  int segments = 50;
  float segAngle = 0;

  // torus points (vertical resolution)
  int pts = 50;
  float ptAngle = 0;

  // vertices
  PVector vertices[], vertices2[];

  // Based on Greenberg, Ira: Interactive Toroid, https://processing.org/examples/toroid.html [20.02.2021].
  // initialize point arrays
  vertices = new PVector[pts+1];
  vertices2 = new PVector[pts+1];

  torus = createShape();
  torus.beginShape(QUAD_STRIP);
  torus.stroke(0, 100);
  torus.noFill();

  // fill arrays
  for (int i = 0; i <= pts; i++) {
    vertices[i] = new PVector(majorR + minorR * sin(radians(ptAngle)), minorR * cos(radians(ptAngle)), 0);
    vertices2[i] = new PVector();
    ptAngle += 360.0/pts;
  }

  // draw toroid
  segAngle = 0;
  for (int i = 0; i <= segments; i++) {
    for (int j = 0; j <= pts; j++) {
      if (i > 0) {
        torus.vertex(vertices2[j].x, vertices2[j].y, vertices2[j].z);
      }
      vertices2[j].x = vertices[j].x * cos(radians(segAngle));
      vertices2[j].y = vertices[j].y;
      vertices2[j].z = vertices[j].x * sin(radians(segAngle));
      torus.vertex(vertices2[j].x, vertices2[j].y, vertices2[j].z);
    }
    segAngle += 360.0/segments;
  }
  torus.endShape();
}

void makeAxes() {
  // axes
  x = new PVector(height/2, 0, 0);
  y = new PVector(0, height/2, 0);
  z = new PVector(0, 0, height/2);

  // create axes-Shape
  axes = createShape();
  axes.beginShape(LINES);
  axes.strokeWeight(1);
  //// positive direction
  // x
  axes.stroke(150, 0, 0);
  axes.vertex(0, 0, 0);
  axes.vertex(x.x, x.y, x.z);
  // y
  axes.stroke(0, 150, 0);
  axes.vertex(0, 0, 0);
  axes.vertex(y.x, y.y, y.z);
  // z
  axes.stroke(0, 20, 150);
  axes.vertex(0, 0, 0);
  axes.vertex(z.x, z.y, z.z);
  //// negative direction
  // x
  axes.stroke(150, 0, 0, 150);
  axes.vertex(0, 0, 0);
  axes.vertex(-x.x, x.y, x.z);
  // y
  axes.stroke(0, 150, 0, 150);
  axes.vertex(0, 0, 0);
  axes.vertex(y.x, -y.y, y.z);
  // z
  axes.stroke(0, 20, 150, 150);
  axes.vertex(0, 0, 0);
  axes.vertex(z.x, z.y, -z.z);
  axes.endShape();
}

void showMap() {
  textAlign(CENTER);
  textSize(30);
  fill(0, 170, 255);

  for (int i = 0; i < 24; i++) { // i%2 = i, int(i/2) = j -> gets rid of a second for loop
    mapPosX = majorR * cos(radians(vecMap2D[i%2][int(i/2)].x))
      + minorR * cos(radians(vecMap2D[i%2][int(i/2)].y)) * cos(radians(vecMap2D[i%2][int(i/2)].x));
    mapPosY = -minorR * sin(radians(vecMap2D[i%2][int(i/2)].y));
    mapPosZ = majorR * sin(radians(vecMap2D[i%2][int(i/2)].x))
      + minorR * cos(radians(vecMap2D[i%2][int(i/2)].y)) * sin(radians(vecMap2D[i%2][int(i/2)].x));

    pushMatrix();
    translate(mapPosX, mapPosY, mapPosZ);
    rotateY(-radians(vecMap2D[i%2][int(i/2)].x-90));
    // turn letters upside down, when most often seen on the inside (through the torus)
    if ((vecMap2D[i%2][int(i/2)].y%360 > 120) && (vecMap2D[i%2][int(i/2)].y%360 < 300)) {
      rotateX(radians(vecMap2D[i%2][int(i/2)].y-180));
    } else {
      rotateX(radians(vecMap2D[i%2][int(i/2)].y));
    }
    text(map[i%2][int(i/2)], 0, 0, 0);
    popMatrix();
  }
}

float[][] getWeights() {
  //float distance, maxDist = 0;
  //for (int i = 0; i < 24; i++) {
  //  distance = sqrt(
  //    sq(currPos.x - vecMap[i%2][int(i/2)][0])
  //    + sq(currPos.y - vecMap[i%2][int(i/2)][1])
  //    + sq(currPos.z - vecMap[i%2][int(i/2)][2])
  //    + sq(0 - vecMap[i%2][int(i/2)][3])
  //  );
  //  if (distance > maxDist) {
  //    maxDist = distance;
  //  }
  //  weightMap[i%2][int(i/2)] = distance;
  //}

  //float currVal;
  //for (int i = 0; i < 24; i++) {
  //  currVal = weightMap[i%2][int(i/2)];
  //  currVal /= maxDist; // normalise distances - not necessary, as I use .normalizeSum in SuperCollider. Here only in case of debugging needs.
  //  currVal = 1/currVal; // bigger distances make smaller weights and vice versa
  //  currVal -= 1; // through testing, i found, that the values are always very near 1, which would cause the weights to be very close to one another
  //  currVal = pow(currVal, 1/heat);
  //  weightMap[i%2][int(i/2)] = currVal;
  //}

  //for (float w : weightMap[0]) {
  //  print(w +"\t");
  //}
  //print("\n");
  //for (float w : weightMap[1]) {
  //  print(w +"\t");
  //}

  PVector coords, currPos = new PVector(horAngle%360, verAngle%360);
  float[] distances = new float[4];
  float distance, maxDist = 0;
  int xDirection, yDirection;

  for (int i = 0; i < 24; i++) {
    coords = vecMap2D[i%2][int(i/2)].copy();
    distance = 1000;

    if (coords.x < currPos.x) {
      xDirection = 1;
    } else {
      xDirection = -1;
    }
    if (coords.y < currPos.y) {
      yDirection = 1;
    } else {
      yDirection = -1;
    }

    distances[0] = currPos.dist(coords);
    distances[1] = currPos.dist(new PVector(coords.x + 360*xDirection, coords.y));
    distances[2] = currPos.dist(new PVector(coords.x, coords.y + 360*yDirection));
    distances[3] = currPos.dist(new PVector(coords.x + 360*xDirection, coords.y + 360*yDirection));

    for (int j = 0; j < 4; j++) {
      if (distances[j] < distance) {
        distance = distances[j];
      }
    }

    if (distance > maxDist) {
      maxDist = distance;
    }
    weightMap[i%2][int(i/2)] = distance;
  }

  float currVal;
  for (int i = 0; i < 24; i++) {
    currVal = weightMap[i%2][int(i/2)];
    currVal /= maxDist; // normalise distances - not necessary, as I use .normalizeSum in SuperCollider. Here only in case of debugging needs.
    currVal = 1/currVal; // bigger distances make smaller weights and vice versa
    currVal--;
    currVal = pow(currVal, 1/heat);
    weightMap[i%2][int(i/2)] = currVal;
  }

  print("\n\n");
  for (float w : weightMap[0]) {
    print(int(w*100)/100.0 +"\t");
  }
  print("\n");
  for (float w : weightMap[1]) {
    print(int(w*100)/100.0 +"\t");
  }

  return weightMap;
}

void sendWeights() {
  OscMessage weights = new OscMessage("/weights");
  weights.add(getWeights());
  oscP5.send(weights, remAddr);
}

void progStart() {
  OscMessage start = new OscMessage("/start");
  oscP5.send(start, remAddr);
}

// start or pause the music generation
void toggleProgram() {
  running = !running;
}

// switch random or manual movement
void toggleManual() {
  manual = !manual;
}

void end() {
  OscMessage end = new OscMessage("/end");
  oscP5.send(end, remAddr);
}

void keyPressed() {
  if (key == CODED) {
    switch (keyCode) {
    case UP:
      activeKeys.add("forwards");
      break;
    case DOWN:
      activeKeys.add("backwards");
      break;
    case LEFT:
      activeKeys.add("left");
      break;
    case RIGHT:
      activeKeys.add("right");
      break;
    }
  } else {
    switch (key) {
    case ' ':
      toggleProgram();
      break;
    case 'm':
      toggleManual();
      break;
    case ESC:
      end();
      exit();
    case 'w':
      activeKeys.add("forwards");
      break;
    case 's':
      activeKeys.add("backwards");
      break;
    case 'a':
      activeKeys.add("left");
      break;
    case 'd':
      activeKeys.add("right");
      break;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    switch (keyCode) {
    case UP:
      activeKeys.remove("forwards");
      break;
    case DOWN:
      activeKeys.remove("backwards");
      break;
    case LEFT:
      activeKeys.remove("left");
      break;
    case RIGHT:
      activeKeys.remove("right");
      break;
    }
  } else {
    switch (key) {
    case 'w':
      activeKeys.remove("forwards");
      break;
    case 's':
      activeKeys.remove("backwards");
      break;
    case 'a':
      activeKeys.remove("left");
      break;
    case 'd':
      activeKeys.remove("right");
      break;
    }
  }
}

void mousePressed() {
  for (Button b : bList) {
    if (((mouseX < b.pos.x+b.w) && (mouseX > b.pos.x)) && ((mouseY < b.pos.y+b.h) && (mouseY > b.pos.y))) {
      switch (b.type) {
      case "toggleProgram":
        toggleProgram();
        break;
      case "toggleManual":
        toggleManual();
        break;
      case "exit":
        end();
        exit();
      }
    }
  }
  for (Slider s : sList) {
    if (((mouseX < s.pos.x+s.w) && (mouseX > s.pos.x)) && ((mouseY < s.pos.y+s.h) && (mouseY > s.pos.y))) {
      s.showVal = map(mouseX - s.pos.x, 0, s.w, 0, 1);
    }
  }
}

void mouseDragged() {
  for (Slider s : sList) {
    if (((mouseX < s.pos.x+s.w) && (mouseX > s.pos.x)) && ((mouseY < s.pos.y+s.h) && (mouseY > s.pos.y))) {
      s.showVal = map(mouseX - s.pos.x, 0, s.w, 0, 1);
    }
  }
}

void mouseReleased() {
  for (Slider s : sList) {
    if (s.value != s.showVal) {
      s.value = s.showVal;
    }
  }
}

void mouseMoved() {
  for (Button b : bList) {
    if (((mouseX < b.pos.x+b.w) && (mouseX > b.pos.x)) && ((mouseY < b.pos.y+b.h) && (mouseY > b.pos.y))) {
      b.border = 255;
    } else {
      b.border = 0;
    }
  }
  for (Slider s : sList) {
    if (((mouseX < s.pos.x+s.w) && (mouseX > s.pos.x)) && ((mouseY < s.pos.y+s.h) && (mouseY > s.pos.y))) {
      s.border = 255;
    } else {
      s.border = 0;
    }
  }
}

void draw() {
  background(80);

  for (Button b : bList) {
    b.show();
  }
  speedSlid.show();
  if (!manual) {
    randomSlid.show();
  }

  translate(width/2, height/2, -100); // translate to origin

  translate(0, 0, (-cos(radians(verAngle))+1)*150); // translate back and forward to make clear if the position is inside or outside the torus
  rotateX(-sin(radians(verAngle))*0.4); // stay with the vertical angle to a certain degree
  rotateY(radians(horAngle-90)); // stay with the horizontal angle

  if (running) {
    if (!manual) {
      // automatic (random) movement with perlin noise
      verAngle = verAngle%360 + (noise(noiseX)-0.5)*2*maxSpeed*speedSlid.value;
      horAngle = horAngle%360 + (noise(noiseX+1000)-0.5)*2*maxSpeed*speedSlid.value;
      noiseX += randomSlid.value/8;
    } else {
      // manual movement with "wsad" or arrow keys
      for (String k : activeKeys) {
        switch (k) {
        case "forwards":
          verAngle += maxSpeed*speedSlid.value;
          break;
        case "backwards":
          verAngle -= maxSpeed*speedSlid.value;
          break;
        case "left":
          horAngle += maxSpeed*speedSlid.value;
          break;
        case "right":
          horAngle -= maxSpeed*speedSlid.value;
          break;
        }
      }
    }
    calcPos();
    if (frameCount%30 == 29) { // every second..
      sendWeights(); // ..send the weights to SuperCollider
    }
  }

  // show torus with map
  shape(torus, 0, 0);
  showMap();

  // show axes
  shape(axes, 0, 0);

  strokeWeight(10);
  stroke(255, 255, 0);
  point(currPos.x, currPos.y, currPos.z); // current position on the torus
  strokeWeight(1);
}
