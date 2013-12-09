/*
 * faminoise_dsp.js
 *
 * This program is licensed under the MIT License.
 * Copyright 2012, aike (@aike1000)
 *
 */

///////////// BROWSER CHECK /////////////////////
window.addEventListener('load', init, false);
function init() {
	try {
		var context = new webkitAudioContext();
	} catch(e) {
		alert('Web Audio API is not supported in this browser');
	}
};

///////////// Init Parameter /////////////////////
//var stream_length = 4096;
//var stream_length = 2048;
var stream_length = 1024;

///////////// NG /////////////////////
var NG_Freq = new Array(
	0x002, 0x004, 0x008, 0x010, 0x020, 0x030, 0x040, 0x050,
	0x065, 0x07F, 0x0BE, 0x0FE, 0x17D, 0x1FC, 0x3F9, 0x7F2
);

var NG = function(samplerate) {
    this.phase = 0.0;
	var frequency = NG_Freq[0];
    this.phaseStep = 100 / samplerate;

	this.short_flag = false;
	this.reg = 0x8000;
	this.lastval = 0;
	this.on = 0;
	this.gain = 0.1;
	this.velocity = false;
	this.pan_l = 0.5;
	this.pan_r = 0.5;
};

NG.prototype.next = function(p) {
	var stream = [];
	var i, imax;
	if (this.on == 1) {
		for (i = 0, imax = stream_length; i < imax; i++)
			stream[i] = this.NoiseNext(p) * this.gain;
	} else {
		for (i = 0, imax = stream_length; i < imax; i++) {
			stream[i] = 0;
		}
	}
	return stream;
};


NG.prototype.NoiseNext = function(p) {
	// 波形更新サイクルの計算方法は、「samplerate / ノイズ周波数」。
	// this.phaseStep: 基準周波数のときの1ステップに進む位相。一定 
	// this.phase: 基準周波数の位相
	// p: 基準周波数に対する倍数
	//    phase * p * Math.PIで本当の位相が算出される
	// w: if (this.phase * p * Math.PI > 2 * Math.PI)を算出するためのワーク変数
	//    = (phase > w) で指定周波数の1周期回ったかどうかを判断できる

	var phase = this.phase;
	var w = 2 / p;
	var ret;
	if (phase > w) {
		phase -= w;
		this.reg >>= 1;
		this.reg |= ((this.reg ^ (this.reg >> (this.short_flag ? 6 : 1))) & 1) << 15;
		ret = (this.reg & 1) * 2.0 - 1.0;
		this.lastval = ret;
	} else {
		ret = this.lastval;
	}
    this.phase = phase + this.phaseStep;
	return ret;
};


NG.prototype.set_gain = function(val) {
	this.gain = val / 100;
};

NG.prototype.set_type = function(val) {
	this.reg = 0x8000;
	if (val == 0)
		this.short_flag = true;
	else
		this.short_flag = false;
};

NG.prototype.set_pan = function(val) {
	this.pan_l = (100 - val) / 100;
	this.pan_r = val / 100;
};

NG.prototype.set_velocity_sense = function(val) {
	if (val > 0)
		this.velocity = true;
	else
		this.velocity = false;
};


///////////// SYNTH MAIN /////////////////////
var Synth = function() {
	this.context = new webkitAudioContext();
	this.dummy = this.context.createBufferSource();
	this.noise = this.context.createJavaScriptNode(stream_length, 1, 2);
	this.ng = new NG(this.context.sampleRate);
	this.dummy.connect(this.noise);
	this.noise.connect(this.context.destination);
};

Synth.prototype.playNoise = function(n, vel) {
	var fn = NG_Freq[n];
	var veln;
	if (this.ng.velocity)
		veln = 0.5 + vel / 254;
	else
		veln = 1.0;

	var self = this;
	this.noise.onaudioprocess = function(event) {
		var Lch = event.outputBuffer.getChannelData(0);
		var Rch = event.outputBuffer.getChannelData(1);
		var sn = self.ng.next(fn);
		var sig;
		for (var i = 0; i < Lch.length; i++) {
			Lch[i] = Rch[i] = sn[i] * veln;
		}
    };
};


Synth.prototype.play = function(note, vel) {
	if ((note >= 60) && (note <= 71)) {
		this.dummy.noteOn(0);
		this.ng.on = true;
		this.playNoise(note - 60 + 2, vel);
	}
};


Synth.prototype.stop = function(note) {
	this.ng.on = false;
};
