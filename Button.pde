class Button {
  PVector pos;
  int w, h, border;
  String type, label;
  color c;
  
  Button(PVector pos, int w, int h, String type, String label) {
    this.pos = pos;
    this.type = type;
    this.label = label;
    this.w = w;
    this.h = h;
    c = color(int(random(201)), int(random(201)), int(random(201)), 100);
  }

  void show() {
    noFill();
    strokeWeight(0.5);
    stroke(border);
    rect(pos.x, pos.y, w, h);
    noStroke();
    fill(c);
    rect(pos.x, pos.y, w, h);
    fill(255);
    textSize(tSize);
    textAlign(CENTER);
    text(label, pos.x, pos.y+h/tSize, w, h);
  }
}
