// Tests "../spms1_web_synth.js" (the built file) with Node.js, running the embedded AudioWorkletProcessor as it is:
// - The default patch plays a note (at the sampling rates of the Web browsers), and is almost silent
//   (below -40 dB, i.e. no stuck notes) a while after the note off
// - The output does not depend on the block size (Asyncify unwinds and rewinds Spms1_main at any sample)
// - A patch sent as NRPN (several messages in one send) is taken
// Usage (in this folder): node spms1_web_test.js

"use strict";

const fs = require("fs");
const path = require("path");

const source = fs.readFileSync(path.join(__dirname, "..", "spms1_web_synth.js"), "utf8");
const base64 = source.match(/WASM_BASE64\s*=\s*"([A-Za-z0-9+/=]+)"/)[1];
const processorSource = JSON.parse(source.match(/PROCESSOR_SOURCE\s*=\s*("(?:[^"\\]|\\.)*")/)[1]);
const wasmBytes = new Uint8Array(Buffer.from(base64, "base64"));

// Loads the AudioWorkletProcessor with the globals of AudioWorkletGlobalScope
function createProcessor(sampleRate) {
  let processorClass = null;
  class AudioWorkletProcessor {
    constructor() {
      this.port = { onmessage: null, postMessage: (data) => { this.messages.push(data); } };
      this.messages = [];
    }
  }
  const registerProcessor = (name, cls) => { processorClass = cls; };
  new Function("AudioWorkletProcessor", "registerProcessor", "sampleRate", processorSource)(
    AudioWorkletProcessor, registerProcessor, sampleRate);
  const processor = new processorClass({ processorOptions: { wasmBytes: wasmBytes } });
  processor.send = (bytes) => processor.port.onmessage({ data: bytes });
  return processor;
}

// Renders numFrames in blocks of blockSize, and returns the left and the right
function render(processor, numFrames, blockSize) {
  const left = new Float32Array(numFrames);
  const right = new Float32Array(numFrames);
  for (let offset = 0; offset < numFrames; offset += blockSize) {
    const n = Math.min(blockSize, numFrames - offset);
    const outL = new Float32Array(n);
    const outR = new Float32Array(n);
    processor.process([], [[outL, outR]]);
    left.set(outL, offset);
    right.set(outR, offset);
  }
  if (processor.messages.length > 0) {
    throw new Error(JSON.stringify(processor.messages));
  }
  return [left, right];
}

function peakOf([left, right]) {
  let peak = 0;
  for (let i = 0; i < left.length; i++) {
    if (!Number.isFinite(left[i]) || !Number.isFinite(right[i])) {
      throw new Error("Not finite output");
    }
    peak = Math.max(peak, Math.abs(left[i]), Math.abs(right[i]));
  }
  return peak;
}

let failed = false;
function check(ok, text) {
  failed = failed || !ok;
  console.log(text + (ok ? "" : " NG"));
}

// A note and its release
for (const sampleRate of [48000, 44100, 96000]) {
  const processor = createProcessor(sampleRate);
  render(processor, sampleRate / 10, 128);                     // 0.1 s
  processor.send([0x90, 60, 100]);
  const noteOnPeak = peakOf(render(processor, sampleRate, 128));     // 1 s
  processor.send([0x80, 60, 64]);
  render(processor, sampleRate * 3, 128);                      // 3 s (the release and the delay)
  const afterPeak = peakOf(render(processor, sampleRate / 10, 128)); // 0.1 s
  check((noteOnPeak > 0.01) && (noteOnPeak <= 1.0) && (afterPeak < 0.01),
        sampleRate + " Hz: peak " + noteOnPeak.toFixed(3) + ", after " + afterPeak.toFixed(4));
}

// The same output with any block size (the MIDI messages at the same frames)
function play(blockSize) {
  const processor = createProcessor(48000);
  const result = [];
  const events = [[0, [0x90, 48, 100]], [12000, [0xB0, 74, 20, 0xB0, 71, 100]], [24000, [0xE0, 0, 96]],
                  [36000, [0x80, 48, 0]], [48000, null]];
  let frame = 0;
  for (const [at, bytes] of events) {
    const [l] = render(processor, at - frame, blockSize);
    result.push(...l);
    frame = at;
    if (bytes) {
      processor.send(bytes);
    }
  }
  return result;
}
const reference = play(64);
for (const blockSize of [128, 37, 1000]) {
  const output = play(blockSize);
  const same = output.every((v, i) => Object.is(v, reference[i]));
  check(same, "Block size " + blockSize + ": " + (same ? "the same as 64" : "differs from 64"));
}

// A patch sent as NRPN (in one send, as the editor does): Output L and R from nothing
// (NRPN MSB 113, LSB 40 and 41 = SIGNAL_NONE) silences the default patch
{
  const level = (nrpn) => {
    const processor = createProcessor(48000);
    if (nrpn) {
      processor.send([0xB0, 99, 113, 0xB0, 98, 40, 0xB0, 6, 0, 0xB0, 99, 113, 0xB0, 98, 41, 0xB0, 6, 0,
                      0xB0, 101, 127, 0xB0, 100, 127]);
    }
    processor.send([0x90, 60, 100]);
    return peakOf(render(processor, 48000 / 2, 128));
  };
  const before = level(false);
  const after = level(true);
  check((before > 0.01) && (after === 0), "NRPN: peak " + before.toFixed(3) + " (default), " + after.toFixed(3) + " (no output)");
}

if (failed) {
  console.log("FAILED");
  process.exit(1);
}
console.log("OK");
