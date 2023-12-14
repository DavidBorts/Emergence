/*
  MaxAndP5js (c) 2016-21, Paweł Janicki (https://paweljanicki.jp)
      a simple messaging system between patches created in MaxMSP
      (https://cycling74.com) and sketches written with P5*js
      (https://p5js.org).

  P5js sketch (as any HTML/JavaScript document loaded inside jweb) can
  communicate with Max. Max can call functions from P5js sketches. P5js
  sketch can read/write content of Max dictionaries and send messages to Max.

  However, there is a namespace conflict between Max API binded to the
  "window" object (accessible from within jweb) and P5js API binded by
  default to the same object (in so called "global mode").

  There are several methods to circumvent this problem, and one of the
  simpler ones (requiring editing only the "sketch.js" file) is using P5js in
  so called "instance mode". Look at the code in the "sketch.js" file attached 
  to this example to see how to prevent the namespaces conflict and how to
  effectively interact with P5js sketches inside jweb object.

  For more informations about differences between "global" and "instance"
  modes of the P5js look at the "p5.js overview" document (available at
  https://github.com/processing/p5.js/wiki/p5.js-overview). For more
  information about communication between Max patcher and content loaded jweb
  object check the "Communicating with Max from within jweb" document (part
  of Max documentation).
*/

// *************************************************************************

/*
  This is a basic helper function checking if the P5js sketch is loaded inside
  Max jweb object.
*/
function detectMax() {
  try {
    /*
      For references to all functions attached to window.max object read the
      "Communicating with Max from within jweb" document from Max documentation.
    */
    window.max.outlet('Hello Max!');
    return true;
  }
  catch(e) {
    console.log('Max, where are you?');
  }
  return false;
}

/*
  Here we are creating actual P5js sketch in the instance mode
  (look at https://github.com/processing/p5.js/wiki/p5.js-overview
  for details about P5js instantiation and namespace) to prevent
  binding P5js functions and variables to the "window" object. Thanks
  of that we can avoid namespaces conflict between Max and P5js.
*/
let s = function(p) {

  // let's test and memorize if the sketch is loaded inside Max jweb object
  const maxIsDetected = detectMax();

  // GLobal variables
  p.snowflakes = [];
  p.step = 0;

  function Particle(x) {
    this.position = p5.Vector.fromAngle(0);
    this.position.mult(x);
    this.radius = 1.75;
    this.step = 0;
    
    this.update = function() {
      
      // Adjust position
      this.position.x -= 1;
      this.position.y += p.random(-5, 5);
      let angle = this.position.heading();
      angle = p.constrain(angle, 0, 3.14 / 6.0);
      let magnitude = this.position.mag();
      this.position = p5.Vector.fromAngle(angle);
      this.position.setMag(magnitude);
      
      // Log steps
      this.step++;
    };
    
    this.draw = function(color) {
      
      p.fill(color);
      p.stroke(255, 150);
      p.ellipse(this.position.x, this.position.y, 
              this.radius * 2);
    };
    
    this.finished = function(particles) {
      let intersect = false;
      let boundary = false;
      
      // Checking for intersections
      for (let part of particles) {
        let d = p.dist(part.position.x, part.position.y, 
                     this.position.x, this.position.y); 
        if (d < this.radius * 2) {
          intersect = true;
          break;
        }
      }

      // Checking position
      if(this.position.x < 1) {
        boundary = true;
      }
      //intersect = false;
      return (boundary || intersect);
    };
  }

  class dla {
    constructor(pitch, duration, voiceNum, step) {
  
      // Snowflake params
      //this.pitch = pitch;
      this.voiceNum = voiceNum;
      this.symmetry = 6;
      this.step = step;
      //this.size = 10.0;
      //this.size = innerHeight / ((1 / duration) + 18.0);
      this.size = innerHeight / ((1 / duration * 3) + 6.5);
      //this.size = innerHeight / 8;
      this.colors = [p.color(25, 25, 235), p.color(255, 255, 255), p.color(25, 90, 255), p.color(25, 85, 175), p.color(20, 25, 200), p.color(200, 200, 255)];
      this.color = this.colors[voiceNum];
      this.finished = false;
      // Random snowflake position
      //this.x = windowWidth/2;
      //this.y = windowHeight / 2;

      //this.x = p.random(innerWidth/6, innerWidth * 0.8);
      this.x = (this.step * 70) + 75 + p.random(-30, 30);
      this.y = 750.0 - (((pitch + 200.0) / 2300.0) * 750.0) - 70 + p.random(-30, 30);
      //this.x = innerWidth / 2;
      //this.x = 200;
      //this.y = p.random(innerHeight/10, innerHeight * 0.8);
      //this.y = 800 - (((pitch - 155.0) / 1400.0) * 800);
      
      // Array to store settled particles
      this.particles = [];
      
      // Current particle
      this.particle = new Particle(this.size);

      //window.max.outlet('DLA-ing!');
      
      this.update = function() {
        p.translate(this.x, this.y);
        //p.rotate(3.14 / 6.0);
    
        if(this.particle.finished(this.particles)) {
        }
        // Simulating new particle
        while(!this.particle.finished(this.particles)) {
          this.particle.update();
        }
    
        // Checking if snowflake completed
        if(this.particle.step == 0) {
          this.finished = true;
        }
      
        // Drawing particle
        for(let i = 0; i < this.symmetry; i++) {
          p.rotate(3.14 * 2.0 / this.symmetry);
    
          this.particle.draw(this.color);
    
          p.push();
          p.scale(1, -1);
  
          this.particle.draw(this.color);
          
          p.pop();
        }
      
        // Adding new particle to snowflake
        this.particles.push(this.particle);
        this.particle = new Particle(this.size);
        
        p.translate( this.x * -1,  this.y * -1);
        //p.rotate(5 * 3.14 / 6.0);
      };
  
    }
  }

  /*
    Use windowResized function to adopt canvas size to the current size of
    the browser. It is particularly important when sketch is loaded inside
    the Max jweb object, which may be dynamically resized by the user.
  */
  p.windowResized = function() {
    p.resizeCanvas(innerWidth, innerHeight);
  }

  p.setup = function() {
    p.createCanvas(innerWidth, innerHeight);
    p.background(0);
    //let test = PI;
    //p.angleMode(DEGREES);
    /*
      If the sketch is loaded inside Max jweb object we will carry out
      the necessary tasks to establish communitation between the patcher
      and the sketch (and to tune the sketch itself to present itself
      correctly when operating inside the jweb.
    */

    if(maxIsDetected) {
      // remove unwanted scroll bar
      document.getElementsByTagName('body')[0].style.overflow = 'hidden';

      window.max.bindInlet('addSim', function (pitch, duration, voiceNum) {
        //window.max.outlet('OI!');
        let sim = new dla(pitch, duration, voiceNum, p.step);
        p.snowflakes.push(sim);
        //window.max.outlet('Added snowflake!');
        p.step++;
        if(p.step >= 10) p.step = 0;
      });
    }
  };

  p.draw = function() {
    p.background(0, 6.5);

    // Array of all simulation instances to remove
    finished = [];
    
    // Updating simulations
    //window.max.outlet(p.snowflakes.length);
    for(let i = 0; i < p.snowflakes.length; i++){
      let sim = p.snowflakes[i];
      sim.update();
      if(sim.finished) finished.push(i);
    }
    //window.max.outlet('Updating orcal servers...');
    
    // Clearing finished simulations
    //if(finished.length > 0) window.max.outlet("Finished indices: ", finished);
    for(let index of finished){
      //window.max.outlet('Erasing...');
      p.snowflakes.splice(index, 1);
      //window.max.outlet("finished count: ", finishedCount);
      //window.max.outlet("Number remaining: ", p.snowflakes.length);
    }
  };

};

// let's run the sketch in the "instance mode"
let myp5 = new p5(s);