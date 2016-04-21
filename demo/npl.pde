import muthesius.net.*;
import org.webbitserver.*;

WebSocketP5 socket;
int state = 0;
int counter = 0;
String receiveMsg;
String name = "noneset";
String displayMsg = "noisy pet life";

Animation baseBear, foodBear, deadBear, whatBear, 
byeBear, dozeBear, wakeBear, giveBear, haveBear, callBear;
PFont font;

void setup() {
  fullScreen();
  background(255, 238, 235);
  frameRate(5);
  smooth();
  font = createFont("Please write me a song", 48, true);
    
  baseBear = new Animation("img/Teddy_Base_", 16);
  foodBear = new Animation("img/Teddy_Eat_", 19);
  deadBear = new Animation("img/Teddy_Dead_", 40);
  whatBear = new Animation("img/Teddy_What_", 11);
  byeBear = new Animation("img/Teddy_Bye_", 12);
  dozeBear = new Animation("img/Teddy_Doze_", 10);
  wakeBear = new Animation("img/Teddy_Wake_", 11);
  giveBear = new Animation("img/Teddy_Give_", 2);
  haveBear = new Animation("img/Teddy_Have_", 8);
  callBear = new Animation("img/Teddy_Call_", 13);
  socket = new WebSocketP5(this,8080);
}

void draw() {
  background(255, 238, 235); //hides the previous text/image
    
  //displaying the font
  textFont(font);
  fill(255,140,115);
  textAlign(CENTER,CENTER);
  text(displayMsg,displayWidth/2, (displayHeight/2)-250);
  
  imageMode(CENTER); //to center images
  
  //after a certain amount of time, put the bear to sleep
  if (counter == 100){
    state = 8;
  }
  
  //all the display states for the bear
  if (state==0){ // neutral
    counter++;
    baseBear.displayL(displayWidth/2, (displayHeight/2)+50); 
  }
  else if (state==1){ // being fed
    foodBear.displayN(displayWidth/2, (displayHeight/2)+50);
  }
  else if (state==2){ // playing dead
    deadBear.displayN(displayWidth/2, (displayHeight/2)+50);
  }
  else if (state==3){ // asking its name
    haveBear.displayN(displayWidth/2, (displayHeight/2)+50);
  }
  else if (state==4){ // calling name
    callBear.displayN(displayWidth/2, (displayHeight/2)+50);
  }
  else if (state==5){ // saying goodbye
    byeBear.displayB(displayWidth/2, (displayHeight/2)+50);
  }
  else if (state==6){ // needs a name
    giveBear.displayL(displayWidth/2, (displayHeight/2)+50);
    if (name != "noneset"){
      state = 16;
    }
  }
  else if(state == 16){ //asking if the inputted name is right
    giveBear.displayL(displayWidth/2, (displayHeight/2)+50);
    displayMsg = "Is " + name + " the right name?";
  }
  else if (state==7){ // wake up
    wakeBear.displayN(displayWidth/2, (displayHeight/2)+50); 
  }
  else if (state==8){ // asleep
    dozeBear.displayL(displayWidth/2, (displayHeight/2)+50); 
  }
  else if (state==9){ // being confused
    whatBear.displayN(displayWidth/2, (displayHeight/2)+50);
  }
  
}

//communicating with chrome for google speech library
void stop(){
  socket.stop();
}

void websocketOnMessage(WebSocketConnection con, String msg){
  receiveMsg = msg;
  displayMsg = receiveMsg;
  //if the app is currently in the resting state, allow states to change
  if (state==0){
    if (receiveMsg.contains("food")){
      println("state change");
      state = 1;
    }
    else if (receiveMsg.contains("dead")){
      println("state change");
      state = 2;
    }
    else if (receiveMsg.contains("name") && name != "noneset"){
      state = 3;
      displayMsg = "My name is " + name + "!";
    }
    else if (receiveMsg.contains(name)){
      state = 4;
    }
    else if (receiveMsg.contains("bye")){
      state = 5;
      stop();
    }
    else if (receiveMsg.contains("name") && name == "noneset"){
      println("no name");
      state = 6;
      displayMsg = "Please give me a name.";
    }
    else{
      state = 9;
    }
  }
  // if state is 6, the user is in the process of giving the
  // pet a name. this must be completed first.
  else if (state ==6){
    displayMsg = "Please give me a name.";
    name = receiveMsg;
    trim(name);
    state = 16;
  }
  
  // here the name has been chosen so they can either say it's right or wrong (yes/no)
  else if (state == 16){
    if (receiveMsg.contains("no")){
      println("state change");
      displayMsg = "Please give me a name.";
      name = "noneset";
      state = 6;
    }
    else if (receiveMsg.contains("yes")){
      println("state change");
      displayMsg = "I love it!";
      state = 3;
    }
  }
  
  // here, the bear is asleep so it cannot listen to commands
  // it must be woken up first.
  else if (state == 8){
    if (receiveMsg.contains("wake") || receiveMsg.contains(name)){
      println("state change");
      state = 7;
      counter = 0;
    }
  }
  
  // if it's none of these states it must be in a state of transition
  // aka playing a non-looping animation
  // ignore inputs during this time
  else{
    receiveMsg="";
  }
}

//check if connection is made...
void websocketOnOpen(WebSocketConnection con){
  println("A client joined");
}

void websocketOnClosed(WebSocketConnection con){
  println("A client left");
}

//animation class to load the bear images
class Animation {
  PImage[] images; //array of images loaded
  int imageCount; // how many images are being loaded
  //the frames- minus one from the total as arrays count from 0
  int frame = imageCount - 1; 
  
  //the constructor has the prefix and also the total number of images
  Animation(String imagePrefix, int count) {
    imageCount = count;
    
    //make an array the same size as the total number of images
    images = new PImage[imageCount]; 

    //populate this array with the files- load them!
    for (int i = 0; i < imageCount; i++) {
      // nf specifies there are two digits- so nf(i,3) would be 001.png, etc
      String filename = imagePrefix + nf(i, 2) + ".png";
      images[i] = loadImage(filename);
    }
  }

  // there are three display classes for this particular app
  // displayL (L stands for loop)- this will allow the frames to loop upon completion
  void displayL(float xpos, float ypos) {
    frame = (frame+1) % imageCount;
    image(images[frame], xpos, ypos);
  }
  
  // displayN (N stands for no loop)- a one time animation from a word trigger-
  // it goes back to the looping animation after
  void displayN(float xpos, float ypos) {
    frame = (frame+1) % imageCount;
    image(images[frame], xpos, ypos);
    if (frame == (imageCount - 1)){
      state = 0;
      counter = 0;
      displayMsg = "";
      println("animation complete");
    }
  }
  
  // displayB (B stands for bye) - for the goodbye animation
  // after it is done, the program closes
  void displayB(float xpos, float ypos) {
    frame = (frame+1) % imageCount;
    image(images[frame], xpos, ypos);
    if (frame == (imageCount - 1)){
      exit();
    }
  }
}