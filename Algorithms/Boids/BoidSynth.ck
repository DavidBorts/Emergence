// create OSC receiver
OscRecv OSCin;
// create OSC message
OscMsg msg;
// use port 25448
25447 => OSCin.port;
//start listening to OSC messages
OSCin.listen();

// creating events for addresses
OSCin.event("/pitch,f") @=> OscEvent pitch_event;
OSCin.event("/play,i") @=> OscEvent play_event; 
OSCin.event("/length,f") @=> OscEvent length_event; 
OSCin.event("/ADSR,f f") @=> OscEvent ADSR_event;
OSCin.event("/reverb,f") @=> OscEvent reverb_event;
OSCin.event("/delay,f") @=> OscEvent delay_event;
OSCin.event("/noise,f") @=> OscEvent noise_event;
OSCin.event("/echo,f") @=> OscEvent echo_event;
OSCin.event("/pan,f") @=> OscEvent pan_event;
OSCin.event("/center,f") @=> OscEvent center_event;
OSCin.event("/q,f") @=> OscEvent q_event;
OSCin.event("/bitcrush,f") @=> OscEvent bitcrush_event;
OSCin.event("/foldback,f") @=> OscEvent foldback_event;
OSCin.event("/loop,i") @=> OscEvent loop_event;
OSCin.event("/instrument,i") @=> OscEvent instrument_event;

// Global variables
Dyno dyno => dac;

// Main code
boidSynth boids;
boids.listen();
<<<"listening!">>>;
boids.play();

class boidSynth { 
    
    //preconstructor
    0 => int playNote;          // Bool signal to play note   
    0 => int instrument;        // Instrument type (1 = sine, 0 = birdsong)
    0 => int loop;              // Toggle loop mode (0 = single notes, 1 = looping)
    220.0 => float pitch;       // Note pitch
    1.0 => float noteLength;    // Note length  
    50.0 => float a;            // Envelope attack
    8.0 => float d;             // Envelope decay
    0.99 => float s;             // Envelope sustain
    5.0 => float r;             // Envelope release
    0.0 => float vibrato;       // Vibrato intensity
    0.0 => float reverb;        // Reverb intensity
    0.0 => float delay;         // Delay intensity
    0.0 => float noise;         // Noise intensity
    0 => int playing;           // bool note tracker
    440.0 => float center;      // BPF center
    30.0 => float q;            // BPF q
    0.0 => float pan;           // Pan location
    0.0 => float echo;          // Echo Duration
    1 => int bitcrush;          // Bitcrusher down-sampling
    0.99 => float foldback;     // Foldback saturator threshold
    0 => int prevInstrument;    // Tracking previously-played instrumment
    
    // Objects
    Delay birdDelay;            // Delay 
    PRCRev birdRev;             // Reverb
    Noise birdNoise;            // White noise
    Gain g;                     // Instrument gain
    Gain g2;                    // Noise gain
    PitShift songShift;         // Birdsong pitch shift
    ADSR birdADSR;              // ADSR envelope
    Echo birdEcho;              // Echo
    Pan2 birdPan;               // Panning
    BPF birdBPF;                // Band-pass filter
    SndBuf birdsong;            // Bird-song audio sample
    SinOsc sin;                 // Sine wave
    Bitcrusher birdBit;         // Bit-crusher
    FoldbackSaturator birdFold; // Fold-back saturator
    
    // Reading in sample
    me.dir() + "/samples/birdsong.wav" => string filename;
    //if( me.args() ) me.arg(0) => filename;
    filename => birdsong.read;
    
    //functions 
    
    // Start listening for UDP packets from Max
    fun void listen() {
        
        // Spork listeners for Max UDP packets
        spork~ receivePitch();
        spork~ receiveADSR();             
        spork~ receiveDelay();     
        spork~ receiveReverb();      
        spork~ receiveNoise();       
        spork~ receiveLength();       
        spork~ receivePlay();      
        spork~ receiveEcho();      
        spork~ receivePan();      
        spork~ receiveCenter();
        spork~ receiveQ();
        spork~ receiveBitcrush();
        spork~ receiveFoldback();
        spork~ receiveLoop();
        spork~ receiveInstrument();
    }
    
    // Start playing
    fun void play() {
        
        <<<"Starting to play!">>>;
        
        // Connecting signal chain
        birdsong => g => songShift/* => birdBPF*/ => birdADSR => birdDelay => birdEcho => birdRev => birdFold => birdBit => birdPan => dyno;
        
        // Connecting white noise
        birdNoise => g2 => dyno;
        
        // Set default values 
        delay::second => birdDelay.delay;  
        reverb => birdRev.mix;   
        noise => g2.gain;   
        echo::samp => birdEcho.delay;
        pan => birdPan.pan;
        center => birdBPF.freq;
        q => birdBPF.Q;
        bitcrush => birdBit.downsample;
        foldback => birdFold.threshold;
        birdADSR.set(a::ms, d::ms, s, r::ms);
        
        // Letting the patch run forever
        while(true){
            
            // Getting parameter values 
            // from Max
            pitch => songShift.shift;
            pitch => sin.freq;
            delay::samp => birdDelay.delay;   
            reverb => birdRev.mix;         
            noise => g2.gain;       
            echo::samp => birdEcho.delay;
            pan => birdPan.pan;
            bitcrush => birdBit.downsample;
            foldback => birdFold.threshold;
            birdADSR.set( a::ms, d::ms, s, r::ms );
            birdBPF.set(center, q);
            
            // Playing correct instrument
            if (instrument == 0 && prevInstrument != 0)
            {
                sin =< g;
                birdsong => g;
                <<<"Switched to sample!">>>;
            } else if (instrument == 1 && prevInstrument != 1)
            {
                birdsong =< g;
                sin => g;
                <<<"Switched to sine!">>>;
            }
            instrument => prevInstrument;
            
            if (playNote != 0){
                
                0.95 => g.gain;
                birdADSR.keyOn();
                //<<<"Gain set up!">>>;
            } else {
                
                birdADSR.keyOff();
                birdADSR.releaseTime() => now;
                0.0 => g.gain;
                0 => birdsong.pos;
                //<<<"Sample reset!">>>;
            }
            
            1::samp => now;
        }
    }
    
    fun void receiveEcho()
    {
        // infinite event loop
        while ( true )
        {
            // wait for event to arrive
            echo_event => now;        
                
            // grab the next message from the queue. 
            while ( echo_event.nextMsg() != 0 )
            { 
                // getFloat
                (echo_event.getFloat() + 1.35) * 50.0 => echo;
                        
             }
        }
    }
            
    fun void receivePan()
    {
        // infinite event loop
        while ( true )
        {
            //wait for event to arrive
            pan_event => now;        
                        
            // grab the next message from the queue. 
            while ( pan_event.nextMsg() != 0 )
            { 
                // getFloat
                pan_event.getFloat() => float panUnscaled;
                
                // Re-scaling pan
                panUnscaled / 0.6 * 1.0 => pan;
                                
            }
        }
    }
                    
    fun void receivePitch()
    {
                        
        // infinite event loop
        while ( true )
        { 
            // wait for event to arrive
            pitch_event => now;        
                                
            // grab the next message from the queue. 
            while ( pitch_event.nextMsg() != 0 )
            { 
                // getFloat 
                pitch_event.getFloat() => pitch;
                <<<pitch>>>;
            }  
        }  
    }

    fun void receiveCenter()
    {
        
        // infinite event loop
        while ( true )
        {
            // wait for event to arrive
            center_event => now;        
                
            // grab the next message from the queue. 
            while ( center_event.nextMsg() != 0 )
            { 
                        
                // getFloat
                center_event.getFloat() => float centerUnscaled;
              
                // Re-scaling center
                ((centerUnscaled + 1.0) / 2.0 * 440.0) + 220.0 => center;
            }
                    
        }     
    }

    fun void receiveADSR()
    {
                
        // infinite event loop
        while ( true )
        {
            // wait for event to arrive
            ADSR_event => now;        
                        
            // grab the next message from the queue. 
            while ( ADSR_event.nextMsg() != 0 )
            { 
                // getFloat
                (ADSR_event.getFloat() + 1.0) / 2.0 * 125 *=> a;
                (ADSR_event.getFloat() + 1.0) / 2.0 *124 => r;
            }               
        }           
    }

    fun void receiveQ() 
    {
                        
        // infinite event loop
        while ( true )
        {
                                
            // wait for event to arrive
            q_event => now; 
            
            // grab the next message from the queue. 
            while ( q_event.nextMsg() != 0 )
            { 
            
                // getFloat
                q_event.getFloat() => float qUnscaled;
                
                // Re-scaling q
                ((qUnscaled + 1.0) / 2.0 * 30.0) + 15.0 => q;
            }
        }
    }
    fun void receiveReverb()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            reverb_event => now;        
            
            // grab the next message from the queue. 
            while ( reverb_event.nextMsg() != 0 )
            { 
            
                // getFloat
                reverb_event.getFloat() => reverb;
            }
        }
    }
    fun void receiveDelay()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            delay_event => now;
            
            // grab the next message from the queue. 
            while ( delay_event.nextMsg() != 0 )
            { 
            
                // getFloat
                delay_event.getFloat() => float delayUnscaled;
                
                // Re-scaling delay
                (delayUnscaled + 1.0) / 2.0 * 30.0 => delay;
            }
        }
    }
    
    fun void receiveBitcrush()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            bitcrush_event => now;
            
            // grab the next message from the queue. 
            while ( bitcrush_event.nextMsg() != 0 )
            { 
            
                // getFloat
                bitcrush_event.getFloat() => float bitcrushUnscaled;
                
                // Re-scaling  bitcrush
                ((bitcrushUnscaled + 1.0) / 2.0 * 3.0) $ int => int bitcrushInt;
                if (bitcrushInt == 0) {
                    1 => bitcrushInt;
                }
                bitcrushInt => bitcrush;
                <<<"bitcrush received: ", bitcrush>>>;
            }
        }
    }
    
    fun void receiveFoldback()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            foldback_event => now;
            
            // grab the next message from the queue. 
            while ( foldback_event.nextMsg() != 0 )
            { 
            
                // getFloat
                foldback_event.getFloat() => float foldbackUnscaled;
                
                // Re-scaling delay
                1.0 - ((foldbackUnscaled + 1.0) / 2.0) => foldback;
            }
        }
    }
    
    fun void receiveNoise()
    {
    
        // infinite event loop
        while ( true )
        {
            // wait for event to arrive
            noise_event => now;        
                                                        
            // grab the next message from the queue. 
            while ( noise_event.nextMsg() != 0 )
            { 
            
                // getFloat
                noise_event.getFloat() / 240.0 => noise;
            }
        }
    }
    
    fun void receiveLength()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            length_event => now;        
            
            // grab the next message from the queue. 
            while ( length_event.nextMsg() != 0 )
            { 
                
                // getFloat
                length_event.getFloat() => noteLength;
                <<<noteLength>>>;
            }
        }
    }
    
    fun void receiveLoop()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            loop_event => now;        
            
            // grab the next message from the queue. 
            while ( loop_event.nextMsg() != 0 )
            { 
                
                // getFloat
                loop_event.getInt() => loop;
            }
        }
    }
    
    fun void receiveInstrument()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            instrument_event => now;        
            
            // grab the next message from the queue. 
            while ( instrument_event.nextMsg() != 0 )
            { 
                
                // getFloat
                instrument_event.getInt() => instrument;
                <<<"Instrument set to: ", instrument>>>;
            }
        }
    }
    
    fun void receivePlay()
    {
    
        // infinite event loop
        while ( true )
        {
        
            // wait for event to arrive
            play_event => now;        
            
            // grab the next message from the queue. 
            while ( play_event.nextMsg() != 0 )
            { 
            
                // getFloat
                play_event.getInt() => playNote;
                <<<playNote>>>;
                                                                                
                if (playNote == 0)
                {
                
                    <<<"PlayNote set to 0!">>>;
                }
            }
        }
    }
}