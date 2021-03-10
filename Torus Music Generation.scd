(
s.boot;
)

(
~weights = Array.fill2D(2, 12, 0);
~started = false;
~stopped = false;

OSCFunc({|msg|
	msg[1..].do {|elem, i|
		//(i +""+ elem).postln;
		(i < 12).if ({
			~weights[0][i] = elem;
		}, {
			~weights[1][i-12] = elem;
		});
	};
}, '/weights', recvPort: 57120);

OSCFunc({|msg|
	~started = true;
}, '/start', recvPort: 57120);

OSCFunc({|msg|
	~stopped = true;
}, '/end', recvPort: 57120);

// the map stores the transpositions from middle C, which is considered as center (-> G to F#: -5 to 6), while minor scales are floats and major scales integers
// example: when I'm currently in A# (-2) and go to A (-3), I need to transpose by abs(-2)+(-3) = -1
~map = [
	[3.0, -4.0, 1.0, 6.0, -1.0, 4.0, -3.0, 2.0, -5.0, 0.0, 5.0, -2.0], // d#, g#, c#, f#, b, e, a, d, g, c, f, a#
	[1,    6,  -1,   4,   -3,   2,   -5,   0,    5,  -2,   3,   -4]  // C#, F#, B, E, A, D, G, C, F, A#, D#, G#
];

// ~weights = [[2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48],
// [2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48, 2/48]].flatten;
//
// Pwrand(~map, ~weights).asStream.next.isKindOf(Integer);

//((60 + [[0], [4], [7]]).midicps * [[1, 2, 3, 4, 5, 6]]) * (0.2 * [[1, 0.5, 0.25, 0.1, 0.05, 0.01]])
SynthDef(\harmony, {|freq = 440, att = 0.05, rel = 1, amp = 0.2|
	var snd;
	snd = SinOsc.ar(freq * [[1, 2, 3, 5, 7, 12]]);
	snd = snd * (amp * [[1, 0.2, 0.08, 0.05, 0.03, 0.01]]);
	snd = snd / 3;
	snd = snd * EnvGen.ar(Env.perc(att, rel), doneAction: 2);
	Out.ar(0, Splay.ar(snd));
}).add;

SynthDef(\bass, {|freq = 110, att = 0.01, dec = 0.3, susLvl = 0.5, rel = 0.2, gate = 1, amp = 0.2|
	var snd, mod;
	freq = freq * [0.5, 1, 2, 3, 5, 8, 11];
	mod = SinOsc.kr(Line.kr(5, 20, 0.2)).range(Line.kr(10, 0, 0.5).linexp(0, 10, 0.1, 10, \max) * Line.kr(0, 1, 0.2));
	snd = SinOsc.ar(freq + mod);
	snd = snd * (amp * [0.7, 1, 0.04, 0.02, 0.01, 0.006, 0.002]);
	snd = Mix(snd);
	snd = snd * EnvGen.ar(Env.adsr(att, dec, susLvl, rel), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(snd, 0.3));
}).add;

~bStarttime = 0;
~hStarttime = 0;
~notes = [];
{
	var sc, tpose, bDeg, bDur, bVel, bOffset, hDeg, hDur, hVel, hAtt, hRel, hOffset;
	{not(~stopped)}.while {
		(~started).if({
			// choose transposition
			tpose = Pwrand(~map.flatten, ~weights.flatten.normalizeSum).asStream.next; // get transposition from middle C

			// debugging
			~weights.flatten.normalizeSum[0..11].postln;
			~weights.flatten.normalizeSum[12..23].postln;
			tpose.postln;
			"".postln;

			// choose scale
			(tpose.isKindOf(Integer)).if ({
				sc = Scale.major;
			}, {
				sc = Scale.harmonicMinor;
			});

			// bass values
			3.do{bDeg = bDeg.add([0, 0, 0, 2, 4, -3].choose)};
			bDur = [3/8, 3/8, 2/8].scramble;
			bVel = [0.5, 0.25, 0.35];

			// bass Pattern
			~bPat = Pbind(
				\instrument, \bass,
				\scale, sc,
				\degree, Pseq(bDeg),
				\dur, Pseq(bDur),
				\octave, 4,
				\ctranspose, tpose.asInteger, // .Integer probably not necessary, but just to be sure
				\amp, Pseq(bVel),
				\att, 0.01,
				\dec, 0.5,
				\susLvl, 0.2,
				\rel, 0.3
			);

			// harmony values
			0.7.coin.if ({
				3.do{hDeg = hDeg.add(
					([-3, 0, 2, 4, 7][3.rand..2.rand+3]) // some chord variety
					.add({t = 0.1.coin; t.if {[3, -4, 6, -1, 8, 1].choose}}.value) // add some fourths, sevenths or ninths (20% chance on any)
					.removeEvery([nil])
				)};

				hDur = [[3/8, 4/8, 1/8], [2/8, 3/8, 3/8], [3/8, 2/8, 3/8]].choose;
				hVel = [0.2, 0.3, 0.1];
				hAtt = [0.01, 0.008, 0.01];
				hRel = [1, 0.7, 0.5];
			}, {
				hDeg = hDeg.add(
					([-3, 0, 2, 4, 7][3.rand..2.rand+3]) // some chord variety
					.add({t = 0.1.coin; t.if {[3, -4, 6, -1, 8, 1].choose}}.value) // add some fourths, sevenths or ninths (20% chance on any)
					.removeEvery([nil])
				);

				hDur = [1];
				hVel = [0.3];
				hAtt = [0.01];
				hRel = [1];
			});

			// harmony Pattern
			~hPat = Pbind(
				\instrument, \harmony,
				\scale, sc,
				\degree, Pseq(hDeg),
				\dur, Pseq(hDur),
				\octave, 5,
				\ctranspose, tpose.asInteger, // .Integer probably not necessary, but just to be sure
				\amp, Pseq(hVel),
				\att, Pseq(hAtt),
				\rel, Pseq(hRel)
			);

			bOffset = 0.02.rand;
			hOffset = 0.02.rand;

			Ptpar([bOffset, ~bPat, hOffset, ~hPat]).play; // play both

			// write bass-note informations to list
			~nextOnset = 0;
			bDur.do{|dur, i|
				~notes = ~notes.add(
					[48 + (bDeg[i]).degreeToKey(sc) + tpose, // noteNumber
						127 * bVel[i], // (down) velocity
						~bStarttime + ~nextOnset, // startTime
						dur, // duration
						127, 0, 1] // up velocity, channel (bass channel 0), track (bass track 1)
				);
				~nextOnset = ~nextOnset + dur;
			};
			// write harmony-note informations to list
			~nextOnset = 0;
			hDur.do {|dur, i|
				hDeg[i].do {|deg, j|
					~notes = ~notes.add(
						[60 + (deg).degreeToKey(sc) + tpose, // noteNumber
							127 * hVel[i], // (down) velocity
							~hStarttime + ~nextOnset, // startTime
							dur, // duration
							127, 1, 2] // up velocity, channel (harmony channel 1), track (harmony track 2)
					)
				};
				~nextOnset = ~nextOnset + dur;
			};

			~bStarttime = ~bStarttime + 1;
			~hStarttime = ~hStarttime + 1;

			bDur.sum.wait;
		}, {0.5.wait;});
	};

	// initialise MIDI-file
	~midFile = SimpleMIDIFile("test.mid"); // adjust path to your file system and desired position! (relative path starts in SC installation)
	~midFile.init1(3, 120, "4/4");
	~midFile.timeMode = \seconds;

	~notes.do {|n| ~midFile.addNote(n[0], n[1], n[2], n[3], n[4], n[5], n[6])}; // add MIDI-notes from list

	//midFile.midiEvents.dopostln; // all midi events
	//midFile.metaEvents.dopostln; // notice the incorrect 'endOfTrack' events for track 1 & 2;
	~midFile.adjustEndOfTrack;
	~midFile.metaEvents.dopostln; // try again

	~midFile.write; // write MIDI-file
}.fork;
)