import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import cloudSea, { meta } from './cloud-sea-engine.js';

const W = 200;
const H = 100;
const SCALE = 2; // 400 x 200 - ultra crisp, super compact (~4KB per PNG)
const OUT_W = W * SCALE;
const OUT_H = H * SCALE;

const TOTAL_FRAMES = 30; // 30 frames for a smooth 30 FPS / 2-second seamless cycle
const SPEED_MULT = 4.0; // lively, majestic drift

const PALETTE = meta.palette.map(hex => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return [r, g, b];
});

const GROUND = [14, 14, 15]; // #0e0e0f

const fn = cloudSea();
const color = new Uint8Array(W * H);
const frameBuffer = Buffer.alloc(OUT_W * OUT_H * 3);

const framesDir = path.join(process.cwd(), 'assets', 'images', 'cloud_sea_frames');
if (!fs.existsSync(framesDir)) {
  fs.mkdirSync(framesDir, { recursive: true });
}

console.log(`Generating ${TOTAL_FRAMES} crisp PNG frames to ${framesDir}...`);

for (let frameIdx = 0; frameIdx < TOTAL_FRAMES; frameIdx++) {
  // Seamless loop t
  const t = (frameIdx / TOTAL_FRAMES) * (Math.PI * 2) * (SPEED_MULT / 4.0);
  const text = fn(t, { color });

  // Fill with ground
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
        // 1.5x1.5 cross
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
        // Full 2x2 dot
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

  // Save to PNG using ffmpeg
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

console.log('Done! 30 frames written.');
const sampleFile = path.join(framesDir, 'f_0.png');
console.log(`Single frame size: ${fs.statSync(sampleFile).size} bytes`);
