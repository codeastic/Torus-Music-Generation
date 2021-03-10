class Slider {
  PVector pos;
  int w, h, border;
  float value, showVal;
  String type, label;
  color c;
  
  Slider(PVector pos, int w, int h, String type, String label) {
    this.pos = pos;
    this.type = type;
    this.label = label;
    this.w = w;
    this.h = h;
    c = color(int(random(201)), int(random(201)), int(random(201)), 100);
    value = 0.5;
    showVal = value;
  }
  
  void show() {
    noFill();
    strokeWeight(0.5);
    stroke(border);
    rect(pos.x, pos.y, w, h);
    noStroke();
    fill(c);
    rect(pos.x, pos.y, w*showVal, h);
    fill(c, 75);
    rect(pos.x + w*showVal, pos.y, w - w*showVal, h);
    textAlign(CENTER);
    textSize(tSize);
    fill(255);
    text(label, pos.x+(w/2), pos.y+(3*h/4));
    text(showVal, pos.x+(w/2), pos.y+(7*h/4));
  }
}
