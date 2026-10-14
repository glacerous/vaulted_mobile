import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import alpineDawn, { meta } from './alpine-dawn-engine.js';

const W = 200;
const H = 100;
const SCALE = 2; // 400 x 200 - ultra crisp, 1:1 pixel dither dot scale
const OUT_W = W * SCALE;
const OUT_H = H * SCALE;

const TOTAL_FRAMES = 36; // 36 frames for silky smooth ~15-20 FPS loop
const SPEED_MULT = 3.2; // Visibly flowing water ripples & mist drift

const PALETTE = meta.palette.map(hex => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return [r, g, b];
});

// #090c18 deep alpine midnight ground
const GROUND = [9, 12, 24];

const fn = alpineDawn();
const color = new Uint8Array(W * H);
const frameBuffer = Buffer.alloc(OUT_W * OUT_H * 3);

const framesDir = path.join(process.cwd(), 'assets', 'images', 'alpine_dawn_frames');
if (!fs.existsSync(framesDir)) {
  fs.mkdirSync(framesDir, { recursive: true });
}

console.log(`Generating ${TOTAL_FRAMES} crisp alpine dawn frames to ${framesDir}...`);

for (let frameIdx = 0; frameIdx < TOTAL_FRAMES; frameIdx++) {
  const t = (frameIdx / TOTAL_FRAMES) * 8.0 * SPEED_MULT;
  const text = fn(t, { color });

  // Clear with ground color
  for (let i = 0; i < OUT_W * OUT_H; i++) {
    frameBuffer[i * 3 + 0] = GROUND[0];
    frameBuffer[i * 3 + 1] = GROUND[1];
    frameBuffer[i * 3 + 2] = GROUND[2];
  }

  const rawChars = text.replace(/\n/g, '');

  for (let r = 0; r < H; r++) {
    for (let c = 0; c < W; c++) {
      const k = r * W + c;
      const ch = rawChars[k];
      if (!ch || ch === ' ') continue;

      const palIdx = color[k];
      const rgb = PALETTE[palIdx] || PALETTE[0];

      const startX = c * SCALE;
      const startY = r * SCALE;

      if (ch === '·') {
        // 1px center dot
        const idx = (startY * OUT_W + startX) * 3;
        frameBuffer[idx] = rgb[0];
        frameBuffer[idx + 1] = rgb[1];
        frameBuffer[idx + 2] = rgb[2];
      } else if (ch === '•') {
        // 1.5x1.5 cross dot
        for (let dy = 0; dy < 2; dy++) {
          for (let dx = 0; dx < 2; dx++) {
            if (dx === 1 && dy === 1) continue;
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      } else if (ch === '●') {
        // Solid 2x2 dot
        for (let dy = 0; dy < 2; dy++) {
          for (let dx = 0; dx < 2; dx++) {
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      }
    }
  }

  const outPng = path.join(framesDir, `f_${frameIdx}.png`);
  spawnSync('ffmpeg', [
    '-y',
    '-f', 'rawvideo',
    '-pixel_format', 'rgb24',
    '-video_size', `${OUT_W}x${OUT_H}`,
    '-i', 'pipe:0',
    '-vframes', '1',
    outPng,
  ], { input: frameBuffer });
}

console.log('Alpine Dawn frames written successfully!');
