Dyno lim => dac;
lim.limit();

64 => int E;
66 => int Fsharp;
68 => int Gsharp;
69 => int A;
71 => int B;
73 => int Csharp;
75 => int Dsharp;
0.75 => float quarternote;
"localhost" => string hostname;
7400 => int port;
OscOut xmit;
xmit.dest(hostname, port);

fun void sendUDP(int noteFreq, float sendDur, int voiceNum)
{    
    
    float clipped;
    (sendDur / quarternote) => sendDur;
    
    if (sendDur > 4)
    {
        4 => clipped;
    }
    else
    {
        sendDur => clipped;
    }
     xmit.start("/pitch");
     xmit.add(noteFreq);
     xmit.send();
     xmit.start("/duration");
     xmit.add(clipped);
     xmit.send();
     xmit.start("/voiceNum");
     xmit.add(voiceNum);
     xmit.send();
     xmit.start("/bang");
     xmit.add(1);
     xmit.send();
}

class Strings 
{
    // 7 voices to sound like a string section
    Bowed bow => LPF lpf => ADSR adsr => lim;
    Bowed bow2 =>  adsr => lim;
    Bowed bow3 =>  adsr => lim;
    Bowed bow4 =>  adsr => lim;
    Bowed bow5 =>  adsr => lim;
    Bowed bow6 =>  adsr => lim;
    Bowed bow7 =>  adsr => lim;
    Noise n => adsr => lim;
    
    // a bit of noise to sound more real
    0.00005 => n.gain;
    
    0.035 => bow.gain => bow2.gain => bow3.gain => bow4.gain => bow5.gain => bow6.gain => bow7.gain;
    
    0.5 => bow.startBowing => bow2.startBowing => bow3.startBowing => bow4.startBowing => bow5.startBowing => bow6.startBowing => bow7.startBowing;
    0.0025 => bow.vibratoGain => bow2.vibratoGain => bow3.vibratoGain => bow4.vibratoGain => bow5.vibratoGain => bow6.vibratoGain => bow7.vibratoGain;
    
    // if all of the strings had the same frequency, it would sound like one violin.
    // so i'm creating a bit of distance between the voices so the section sounds more full.
    // this distance changes depending on the frequency of the note being played, to preserve the strings' timbre.
    // duration in seconds
    // breath indicates whether there is a brief pause between notes, or if notes are legato
    fun void playNote(int noteFreq, float duration, float breath) 
    {
        
        sendUDP(noteFreq, duration, 2);
        

        float freqDist;
        if (noteFreq < 164)
        {
            0.001 => freqDist;
            lpf.freq(noteFreq);
        }
        else if (noteFreq < 329)
        {
            0.25 => freqDist;
            lpf.freq(noteFreq);
        }
        else if (noteFreq < 493)
        {
            0.75 => freqDist;
        }
        else if (noteFreq < 659)
        {
            2 => freqDist;
        }
        else if (noteFreq < 659)
        {
            2 => freqDist;
        }
        else
        {
            3 => freqDist;
        }
       
        if (breath == 1)
        {
            (duration*0.23529) => breath;
        }
        else
        {
            ((duration*0.23529)/2) => breath;
        }

        adsr.set(0.17647*duration::second, 0.58823*duration::second, 1, duration*0.23529::second);
        noteFreq => bow.freq;
        (noteFreq-1*freqDist) => bow2.freq;
        (noteFreq-2*freqDist) => bow3.freq;
        (noteFreq-3*freqDist) => bow4.freq;
        (noteFreq+1*freqDist) => bow5.freq;
        (noteFreq+2*freqDist) => bow6.freq;
        (noteFreq+3*freqDist) => bow7.freq;
        adsr.keyOn();
        (duration - breath)::second => now;
        adsr.keyOff();
        breath::second => now;
        
    }
    bow =< lim;
    bow2 =< lim;
    bow3 =< lim;
    bow4 =< lim;
    bow5 =< lim;
    bow6 =< lim;
    bow7 =< lim;
    n =< lim;
}

class Bells
{
    TriOsc myTri => PRCRev p => ADSR adsr2 => lim;
    
    p.mix(0.05);
    myTri.gain(0.1);
    
    fun void playNote(int noteFreq, float duration)
    {
        
        sendUDP(noteFreq, duration, 1);
        

        adsr2.set(duration*0.005::second, duration*0.005::second, 0.1, duration::second);
        myTri.freq(noteFreq);
        adsr2.keyOn();
        1::ms => now;
        adsr2.keyOff();
        duration::second => now;
    }
    
    myTri =< lim;
}

class Harps 
{
    StifKarp harp => LPF lpf => PRCRev j => Chorus c => ADSR adsr3 => lim => Gain g;
    StifKarp harp2 => LPF lpf2 => j => c => adsr3 => lim => g;
    SinOsc mySin => j => c => adsr3 => lim => g;
    SinOsc mySin2 => j => c => adsr3 => lim => g;
    lim.limit();
    g.gain(0.1);
    
    j.mix(0.1);
    c.mix(0.4);
    
    harp.gain(0.00040);
    harp2.gain(0.00040);
    mySin.gain(0.00040);
    mySin2.gain(0.00040);
    
    
    fun void playNote(int noteFreq, float duration) 
    {
        
        sendUDP(noteFreq, duration, 3);
        
        
        adsr3.set(duration::second, duration::second, 0.7, (duration)::second);
        lpf.freq(noteFreq);
        lpf2.freq(noteFreq*2);
        mySin.freq(noteFreq);
        harp.freq(noteFreq);
        harp2.freq(noteFreq*2);
        mySin2.freq(noteFreq*2);
        0.01 => harp.pluck;
        0.01 => harp2.pluck;
        
        harp.noteOn(0.01);
        harp2.noteOn(0.01);
        adsr3.keyOn();
        duration::second => now;
        adsr3.keyOff();
    }
    
    harp =< lim;
    harp2 =< lim;
    mySin =< lim;
    mySin2 =< lim;
}

class Flutes 
{
    Flute flute => PoleZero f => JCRev r => ADSR adsr5 => lim;
    .375 => r.gain;
    .05 => r.mix;
    .99 => f.blockZero;
    lim.limit();
    
    0.5 => flute.gain;
    
    fun void playNote(int noteFreq, float duration, float breath) 
    {        
 
        sendUDP(noteFreq, duration, 4);
        

        if (breath == 1)
        {
            0 => breath;
        }
        else
        {
            (duration / 2) => breath;
        }
        adsr5.set(duration::second, duration::second, 0.1, duration::second);
        noteFreq => flute.freq;
        0.25 => flute.noteOn;
        adsr5.keyOn();
        (duration - breath)::second => now;
        adsr5.keyOff();
        breath::second => now;
    }
    flute =< lim;

}

class Clarinets 
{
    Clarinet clarinet => PoleZero f => JCRev r => ADSR adsr5 => lim;
    .375 => r.gain;
    .05 => r.mix;
    .99 => f.blockZero;
    lim.limit();
    
    0.5 => clarinet.gain;
    
    fun void playNote(int noteFreq, float duration, float breath) 
    {      
       sendUDP(noteFreq, duration, 5);
        

        if (breath == 1)
        {
            0 => breath;
        }
        else
        {
            (duration / 2) => breath;
        }  
        adsr5.set(duration::second, duration::second, 0.6, duration::second);
        noteFreq => clarinet.freq;
        0.25 => clarinet.noteOn;
        adsr5.keyOn();
        (duration - breath)::second => now;
        adsr5.keyOff();
        breath::second => now;
    }
    clarinet =< lim;
    
}

class Piano 
{
    Rhodey r => JCRev j => ADSR adsr => lim;
    SinOsc s => j => adsr => lim;
    
    j.mix(0.05);
    r.lfoDepth(0.05);
    r.afterTouch(0);
    
    r.gain(0.0075);
    s.gain(0.0075);
    
    fun void playNote(int noteFreq, float duration)
    {
      
        sendUDP(noteFreq, duration, 0);

        adsr.set(50::ms, 50::ms, 0.15, (duration/2)::second);
        r.freq(noteFreq);
        s.freq(noteFreq);
        r.noteOn(0.25);
        adsr.keyOn();
        (duration/2)::second => now;
        adsr.keyOff();
        (duration/2)::second => now;
    }
    
    r =< lim;
    s =< lim;
    
}

class Kick
{
    //main tone
    TriOsc s => ADSR e => lim;
    //envelope for changing the pitch over time
    // you need the blackhole to force the ADSR to compute (even though it's not sending to the dac)
    // you need the Step object to send a 1 into the ADSR inputs so that you get an output that isn't just zeros. Step defaults to just sending 1s.
    Step dummy => ADSR p => blackhole;
    
    
    s.freq(50);
    
    e.set(5::ms, 300::ms, 0.0, 100::ms);
    p.set(5::ms, 30::ms, 0.0, 100::ms);
    
    
    fun void play(float volume)
    {
        s.gain(volume);
        e.keyOn();
        p.keyOn();
    }
    
    
    fun void pitchDive()
    {
        //this loop takes the output of the pitch ADSR and sets the pitch of the tone with it.
        while(true)
        {
            (p.last() * 60) + 60.0 => s.freq;
            10::samp => now;
        }
        
        
    }
    
    spork~ pitchDive();
    s =< lim;
    dummy =< lim;
}


fun void playIntro()
{
    Piano myPiano;
    Piano myPiano2;
    Piano myPiano3;
    Piano myPiano4;
    Piano myPiano5;
    Piano myPiano6;
    spork~ myPiano.playNote(Std.ftoi(Std.mtof(E)), quarternote*48);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(B)), quarternote*48);
    spork~ myPiano3.playNote(Std.ftoi(Std.mtof(E+12)), quarternote*48);
    (quarternote*5)::second => now;
    spork~ myPiano4.playNote(Std.ftoi(Std.mtof(Csharp-12)), quarternote*8);
    myPiano5.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote*4);
    myPiano5.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote*6);
    spork~ myPiano6.playNote(Std.ftoi(Std.mtof(E-12)), quarternote*48);
    
}
fun void playMelody()
{
    Bells myBells;
    Bells myBells2;
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(B)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(A+24)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote*0.5);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(A)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(A+24)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote*0.5);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(E+12)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(E+24)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(B+12)), quarternote*0.5);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(A)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Csharp+12)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote/4);
    myBells.playNote(Std.ftoi(Std.mtof(E+24)), quarternote/4);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote);
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote);
    
}
fun void playMelody2()
{
    Bells myBells;
    Bells myBells2;
    Bells myBells3;
    spork~ myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(E+24)), quarternote*2);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(B+12)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(B+12)), quarternote);
    (quarternote/2)::second => now;
    myBells.playNote(Std.ftoi(Std.mtof(A+24)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote*0.5);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(A)), quarternote*2);
    spork~ myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote*2);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(B+12)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(B+12)), quarternote);
    (quarternote/2)::second => now;    
    myBells.playNote(Std.ftoi(Std.mtof(A+24)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Gsharp+24)), quarternote*0.5);
    spork~ myBells.playNote(Std.ftoi(Std.mtof(Fsharp+24)), quarternote);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(Csharp+12)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells.playNote(Std.ftoi(Std.mtof(E+24)), quarternote);
    (quarternote/2)::second => now;
    spork~ myBells3.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote);
    (quarternote/2)::second => now; 
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(B+12)), quarternote*0.5);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(A)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Csharp+12)), quarternote*1.5);
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote/4);
    myBells.playNote(Std.ftoi(Std.mtof(E+24)), quarternote/4);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote*2);
    myBells.playNote(Std.ftoi(Std.mtof(Dsharp+12)), quarternote*2);
    
}
fun void playEntrance()
{
    Harps myHarp;
    Strings myStrings;
    
    spork~ myStrings.playNote(Std.ftoi(Std.mtof(B+12)), quarternote*16, 1);
    myHarp.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4);
    spork~ myHarp.playNote(Std.ftoi(Std.mtof(B)), quarternote/4);
    (16*quarternote)::second => now;
}

fun void harpHarmony()
{
    Strings myStrings;
    Strings myStrings2;
    lim.limit();
    Harps myHarp;
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(E-12)), quarternote*4, 0);
    spork~ myStrings.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote*4, 0);
    (quarternote/2)::second => now;
    myHarp.playNote(Std.ftoi(Std.mtof(Fsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Gsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2);
    (2*quarternote)::second => now;
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Dsharp-24)), quarternote*4, 0);
    spork~ myStrings.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote*4, 0);
    (quarternote/2)::second => now;
    myHarp.playNote(Std.ftoi(Std.mtof(Fsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Gsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2);
    (2*quarternote)::second => now;
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Csharp-24)), quarternote*4, 0);
    spork~ myStrings.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote*4, 0);
    (quarternote/2)::second => now;
    myHarp.playNote(Std.ftoi(Std.mtof(Fsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Gsharp-12)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(E)), quarternote/2);
    (2*quarternote)::second => now;
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Dsharp-24)), quarternote*4, 0);
    spork~ myStrings.playNote(Std.ftoi(Std.mtof(A)), quarternote*4, 0);
    (quarternote/2)::second => now;
    myHarp.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(E)), quarternote/2);
    myHarp.playNote(Std.ftoi(Std.mtof(Csharp-1)), quarternote/2);
    (quarternote)::second => now;
    myHarp.playNote(Std.ftoi(Std.mtof(A)), quarternote/4);
    (quarternote*0.75)::second => now;
}
fun void fluteandClarinet()
{
    Flutes myFlute;
    Clarinets myClarinet;
    myFlute.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/2, 0);
    myFlute.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote/2, 0);
    myFlute.playNote(Std.ftoi(Std.mtof(B)), quarternote*2.5, 1);
    myFlute.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote/2, 0);
    myFlute.playNote(Std.ftoi(Std.mtof(A)), quarternote/2, 0);
    myFlute.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote/2, 0);
    myFlute.playNote(Std.ftoi(Std.mtof(E)), quarternote*2.5, 1);
    myClarinet.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote*0.75, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(B)), quarternote*0.75, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(E)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote*2, 0);
    (quarternote)::second => now;
}

fun void playInterlude()
{
    Piano myPiano;
    Strings myStrings;
    myPiano.playNote(Std.ftoi(Std.mtof(E+12)), quarternote*1);
    spork~ myPiano.playNote(Std.ftoi(Std.mtof(E+24)), quarternote*4);
    (quarternote*2)::second => now;
    myStrings.playNote(Std.ftoi(Std.mtof(Csharp-1)), quarternote/2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(B+12)), quarternote/2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(A+12)), quarternote/2, 0);

}

fun void harpRun()
{
    Harps myHarp;
    lim.limit();
    myHarp.playNote(Std.ftoi(Std.mtof(Csharp-13)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Csharp-12)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(E)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(A)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(B)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Csharp)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote/5);
    myHarp.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/2);
}

fun void percussion()
{
    SndBuf timpani => lim;
    SndBuf suspended_cymbal => lim;
    lim.limit();
    timpani.gain(0.2);
    suspended_cymbal.gain(0.2);
    me.dir() + "timpani.wav" => timpani.read;
    me.dir() + "suspended_cymbal.wav" => suspended_cymbal.read;
    
    timpani.rate(2);
    suspended_cymbal.rate(0.75);
    
    7::second => now;
    
}

fun void climax()
{
    Strings myStrings;
    Strings myStrings2;
    Strings myStrings3;
    Kick myKick;
    Piano myPiano;
    lim.limit();
    spork~ myKick.play(0.0375);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(E-12)), quarternote*2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Fsharp+12)), quarternote, 0);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(E)), quarternote*2, 0);
    spork~ myStrings3.playNote(Std.ftoi(Std.mtof(A-12)), quarternote*2, 0);
    spork~ myPiano.playNote(Std.ftoi(Std.mtof(E-12)), quarternote*2);
    myStrings.playNote(Std.ftoi(Std.mtof(A+12)), quarternote*1.5, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote*0.5, 1);
    spork~ myKick.play(0.0375);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(B-12)), quarternote*2, 0);
    spork~ myPiano.playNote(Std.ftoi(Std.mtof(B-12)), quarternote*2);
    myStrings.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Fsharp+12)), quarternote, 0);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote*2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(A+12)), quarternote*1.5, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote*0.5, 1);
    spork~ myKick.play(0.0375);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Csharp-12)), quarternote*2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Fsharp+12)), quarternote, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(E+12)), quarternote, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote*1.5, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(B)), quarternote*0.5, 1);
    spork~ myKick.play(0.0375);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(A-12)), quarternote*2, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Csharp)), quarternote*1.5, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote/4, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/4, 0);
    spork~ myStrings2.playNote(Std.ftoi(Std.mtof(Fsharp-12)), quarternote*1.5, 0);
    myStrings.playNote(Std.ftoi(Std.mtof(Dsharp)), quarternote*1.5, 0);
    spork~ myKick.play(0.0375);
    (quarternote/2)::second => now;
}

fun void clarinetSyncopation()
{
    Clarinets myClarinet;
    lim.limit();
    
    for (0 => int i; i < 4; i++)
    {
        myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
        myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
    }
    myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(E)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(B-12)), quarternote/4, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/2, 0);
    myClarinet.playNote(Std.ftoi(Std.mtof(E)), quarternote/4, 0);
}

fun void sinBackground()
{
    SinOsc mySin => ADSR adsr => lim;
    lim.limit();
    
    mySin.gain(0.0375);
    
    adsr.set(1::second, 1::second, 0.6, 1::second);
    
    adsr.keyOn();
    spork~ mySin.freq(Std.mtof(E+12));
    (4.5*quarternote)::second => now;
    SinOsc mySin2 => adsr => lim;
    mySin2.gain(0.01875);
    spork~ mySin2.freq(Std.mtof(B+12));
    (4*quarternote)::second => now;
    SinOsc mySin3 => adsr => lim;
    mySin3.gain(0.01875);
    spork~ mySin3.freq(Std.mtof(Gsharp+12));
    (2*quarternote)::second => now;
    adsr.keyOff();
    (1.5*quarternote)::second => now;

}

fun void fluteFlutter()
{
    lim.limit();
    for (0 => int j; j < 3; j++)
    {
        (quarternote/2)::second => now;
        Flutes myFlute;
        Flutes myFlute2;
        for (0 => int i; i < 4; i++)
        {
            spork~ myFlute.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/2, 0);
            spork~ myFlute2.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote/2, 0);
            (quarternote/4)::second => now;
            spork~ myFlute.playNote(Std.ftoi(Std.mtof(Fsharp+12)), quarternote/2, 0);
            spork~ myFlute2.playNote(Std.ftoi(Std.mtof(A+12)), quarternote/2, 0);
            (quarternote/4)::second => now;
        }
        spork~ myFlute.playNote(Std.ftoi(Std.mtof(E+12)), quarternote/2, 0);
        spork~ myFlute2.playNote(Std.ftoi(Std.mtof(Gsharp+12)), quarternote/2, 0);
        (quarternote*1.5)::second => now;
    }
    
}

fun void crash()
{
    lim.limit();
    SndBuf crash_cymbal => lim;
    crash_cymbal.gain(0.25);
    
    me.dir() + "crash_cymbal.wav" => crash_cymbal.read;
    (6*quarternote)::second => now;
}

fun void climax_end()
{
    Bells myBells;
    Bells myBells2;
    spork~ myBells.playNote(Std.ftoi(Std.mtof(E+24)), quarternote*3);
    spork~ myBells2.playNote(Std.ftoi(Std.mtof(E+36)), quarternote*3);
}

fun void playOutro()
{
    Piano myPiano;
    Piano myPiano2;
    Piano myPiano3;
    Piano myPiano4;
    Piano myPiano5;
    
    spork~ myPiano3.playNote(Std.ftoi(Std.mtof(E)), quarternote*20);
    spork~ myPiano4.playNote(Std.ftoi(Std.mtof(B)), quarternote*20);
    spork~ myPiano5.playNote(Std.ftoi(Std.mtof(E+12)), quarternote*20);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(B-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote);
    myPiano.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote);
    myPiano.playNote(Std.ftoi(Std.mtof(A)), quarternote*1.5);
    myPiano.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote*0.5);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(A-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote);
    myPiano.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(A)), quarternote*1.5);
    myPiano.playNote(Std.ftoi(Std.mtof(Gsharp)), quarternote*0.5);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(E-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(Fsharp)), quarternote);
    myPiano.playNote(Std.ftoi(Std.mtof(E)), quarternote);
    myPiano.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote*1.5);
    myPiano.playNote(Std.ftoi(Std.mtof(B-12)), quarternote*0.5);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(A-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(Csharp-12)), quarternote*1.5);
    myPiano.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote/4);
    myPiano.playNote(Std.ftoi(Std.mtof(E)), quarternote/4);
    spork~ myPiano2.playNote(Std.ftoi(Std.mtof(Fsharp-12)), quarternote*2);
    myPiano.playNote(Std.ftoi(Std.mtof(Dsharp-12)), quarternote*2);
    (20*quarternote)::second => now;
}


while (true)
{
    playIntro();
    spork~ playMelody();
    (16*quarternote)::second => now;
    spork~ playMelody2();
    (16*quarternote)::second => now;
    spork~ playMelody2();
    spork~ playEntrance();
    (16*quarternote)::second => now;
    spork~ playMelody2();
    spork~ harpHarmony();
    (16*quarternote)::second => now;
    spork~ playMelody2();
    spork~ harpHarmony();
    spork~ fluteandClarinet();
    (16*quarternote)::second => now;
    spork~ playMelody2();
    spork~ harpHarmony();
    spork~ fluteandClarinet();
    (16*quarternote)::second => now;
    spork~ playMelody();
    (15*quarternote)::second => now;
    spork~ playInterlude();
    (1*quarternote)::second => now;
    spork~ percussion();
    (2*quarternote)::second => now;
    spork~ harpRun();
    (2*quarternote)::second => now;
    spork~ climax();
    spork~ playMelody();
    spork~ harpHarmony();
    spork~ sinBackground();
    (16*quarternote)::second => now;
    spork~ climax();
    spork~ playMelody();
    spork~ harpHarmony();
    spork~ sinBackground();
    spork~ fluteFlutter();
    (16*quarternote)::second => now;
    spork~ crash();
    spork~ climax();
    spork~ playMelody();
    spork~ harpHarmony();
    spork~ clarinetSyncopation();
    spork~ sinBackground();
    spork~ fluteFlutter();
    (16*quarternote)::second => now;
    spork~ climax();
    spork~ playMelody();
    spork~ harpHarmony();
    spork~ clarinetSyncopation();
    spork~ sinBackground();
    spork~ fluteFlutter();
    (16*quarternote)::second => now;
    climax_end();
    (4*quarternote)::second => now;
    spork~ playOutro();
    (20*quarternote)::second => now;
}
