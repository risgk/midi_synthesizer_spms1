// The AudioWorkletProcessor of SPMS-1 Web: runs the SPMS-1 synth (spms1_main.c as WebAssembly) on the audio thread.
// Embedded in "spms1_web_synth.js" (as a string) by "spms1_web_build.js"
//
// Spms1_main never returns: it writes the samples out one by one through write_to_audio_buffer, which calls
// spms1_web_yield once a block is filled. spms1_web_yield unwinds Spms1_main out of spms1_web_run with Asyncify,
// and the next block rewinds it back into spms1_web_yield, so that it goes on where it stopped.

const SPMS1_SAMPLE_RATE = 48000;  // SAMPLE_RATE in spms1_main.rb
const SPMS1_BLOCK_SIZE = 128;      // The frames rendered at a time while resampling

class Spms1WebSynthProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();

    this.wasm = null;
    this.rewinding = false;
    this.unwound = false;
    this.started = false;
    this.stopped = false;

    // The WASI functions are used only by the messages of the C library (not used normally)
    const module = new WebAssembly.Module(options.processorOptions.wasmBytes);
    const imports = { env: { spms1_web_yield: () => this.onYield() } };
    WebAssembly.Module.imports(module).forEach((i) => {
      if (i.kind === "function" && !(imports[i.module] && imports[i.module][i.name])) {
        imports[i.module] = imports[i.module] || {};
        imports[i.module][i.name] = () => 0;
      }
    });
    this.wasm = new WebAssembly.Instance(module, imports).exports;
    this.wasm._initialize();
    this.asyncifyData = this.wasm.spms1_web_asyncify_data();
    this.maxBlockSize = this.wasm.spms1_web_max_block_size();
    this.memoryBuffer = null;

    // Resampling (only at a sampling rate other than 48 kHz): cubic Hermite interpolation between history[1] and history[2]
    this.resampling = (sampleRate !== SPMS1_SAMPLE_RATE);
    this.step = SPMS1_SAMPLE_RATE / sampleRate;
    this.phase = 0;
    this.historyL = new Float32Array(4);
    this.historyR = new Float32Array(4);
    this.fifoL = new Float32Array(SPMS1_BLOCK_SIZE);
    this.fifoR = new Float32Array(SPMS1_BLOCK_SIZE);
    this.fifoRead = SPMS1_BLOCK_SIZE;

    // Spms1_main writes the default patch and the default CC values before its loop, so it is run up to its first
    // sample here, before any MIDI message arrives (and would be overwritten)
    this.renderBlock(1);

    // The MIDI bytes (an array, or several messages in a row) are handled at the beginning of the next block
    this.port.onmessage = (event) => {
      const data = event.data;
      for (let i = 0; i < data.length; i++) {
        this.wasm.spms1_web_midi_byte(data[i] & 0xFF);
      }
    };
  }

  // Called by write_to_audio_buffer once a block is filled, and again while the block after it rewinds Spms1_main
  onYield() {
    if (this.rewinding) {
      this.wasm.asyncify_stop_rewind();
      this.rewinding = false;
      return;
    }
    this.unwound = true;
    this.wasm.asyncify_start_unwind(this.wasm.spms1_web_asyncify_data());
  }

  // Renders numFrames (up to maxBlockSize) at 48 kHz, and returns the views of the left and the right
  renderBlock(numFrames) {
    if (!this.stopped) {
      try {
        this.wasm.spms1_web_begin_block(numFrames);
        if (this.started) {
          this.rewinding = true;
          this.wasm.asyncify_start_rewind(this.asyncifyData);
        }
        this.started = true;
        this.unwound = false;
        this.wasm.spms1_web_run();
        this.wasm.asyncify_stop_unwind();
        if (!this.unwound) {
          throw new Error("Spms1_main returned");
        }
      } catch (e) {
        this.stopped = true;
        this.port.postMessage({ error: String(e) });
      }
    }
    if (this.memoryBuffer !== this.wasm.memory.buffer) {
      this.memoryBuffer = this.wasm.memory.buffer;
      this.left  = new Float32Array(this.memoryBuffer, this.wasm.spms1_web_left(),  this.maxBlockSize);
      this.right = new Float32Array(this.memoryBuffer, this.wasm.spms1_web_right(), this.maxBlockSize);
    }
    if (this.stopped) {
      this.left.fill(0);
      this.right.fill(0);
    }
  }

  process(inputs, outputs) {
    const output = outputs[0];
    const outL = output[0];
    const outR = (output.length >= 2) ? output[1] : null;
    const numFrames = outL.length;

    if (!this.resampling) {
      for (let offset = 0; offset < numFrames; offset += this.maxBlockSize) {
        const n = Math.min(numFrames - offset, this.maxBlockSize);
        this.renderBlock(n);
        outL.set(this.left.subarray(0, n), offset);
        if (outR) {
          outR.set(this.right.subarray(0, n), offset);
        }
      }
      return true;
    }

    const hL = this.historyL;
    const hR = this.historyR;
    for (let i = 0; i < numFrames; i++) {
      while (this.phase >= 1) {
        if (this.fifoRead >= SPMS1_BLOCK_SIZE) {
          this.renderBlock(SPMS1_BLOCK_SIZE);
          this.fifoL.set(this.left.subarray(0, SPMS1_BLOCK_SIZE));
          this.fifoR.set(this.right.subarray(0, SPMS1_BLOCK_SIZE));
          this.fifoRead = 0;
        }
        hL[0] = hL[1]; hL[1] = hL[2]; hL[2] = hL[3]; hL[3] = this.fifoL[this.fifoRead];
        hR[0] = hR[1]; hR[1] = hR[2]; hR[2] = hR[3]; hR[3] = this.fifoR[this.fifoRead];
        this.fifoRead++;
        this.phase -= 1;
      }
      const t = this.phase;
      outL[i] = hermite(hL, t);
      if (outR) {
        outR[i] = hermite(hR, t);
      }
      this.phase += this.step;
    }
    return true;
  }
}

function hermite(h, t) {
  const c1 = 0.5 * (h[2] - h[0]);
  const c2 = h[0] - 2.5 * h[1] + 2 * h[2] - 0.5 * h[3];
  const c3 = 0.5 * (h[3] - h[0]) + 1.5 * (h[1] - h[2]);
  return ((c3 * t + c2) * t + c1) * t + h[1];
}

registerProcessor("spms1-web-synth", Spms1WebSynthProcessor);
