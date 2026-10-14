import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import cloudSea, { meta } from './cloud-sea-engine.js';

const W = 200;
const H = 100;
const SCALE = 4; // 800 x 400 crisp resolution
const OUT_W = W * SCALE;
const OUT_H = H * SCALE;
const FPS = 15;
const DURATION = 4; // 4 seconds loop
const TOTAL_FRAMES = FPS * DURATION; // 60 frames

const PALETTE = meta.palette.map(hex => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return [r, g, b];
});

const GROUND = [14, 14, 15]; // #0e0e0f

console.log(`Generating ${TOTAL_FRAMES} frames at ${OUT_W}x${OUT_H}...`);

const fn = cloudSea();
const color = new Uint8Array(W * H);

// Create raw RGB buffer per frame
const frameBuffer = Buffer.alloc(OUT_W * OUT_H * 3);

// Output directory
const assetsDir = path.join(process.cwd(), 'assets', 'images');
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

const mp4Path = path.join(assetsDir, 'cloud_sea_dither.mp4');
const webpPath = path.join(assetsDir, 'cloud_sea_dither.webp');
const gifPath = path.join(assetsDir, 'cloud_sea_dither.gif');

// Spawn ffmpeg to encode MP4
const ffmpegMp4 = spawn('ffmpeg', [
  '-y',
  '-f', 'rawvideo',
  '-pixel_format', 'rgb24',
  '-video_size', `${OUT_W}x${OUT_H}`,
  '-framerate', `${FPS}`,
  '-i', 'pipe:0',
  '-c:v', 'libx264',
  '-pix_fmt', 'yuv420p',
  '-preset', 'slow',
  '-crf', '20',
  mp4Path,
]);

ffmpegMp4.stderr.on('data', (d) => {
  // Suppress verbose logs
});

for (let frameIdx = 0; frameIdx < TOTAL_FRAMES; frameIdx++) {
  const t = (frameIdx / TOTAL_FRAMES) * DURATION;
  const text = fn(t, { color });

  // Clear frame with GROUND
  for (let i = 0; i < OUT_W * OUT_H; i++) {
    frameBuffer[i * 3 + 0] = GROUND[0];
    frameBuffer[i * 3 + 1] = GROUND[1];
    frameBuffer[i * 3 + 2] = GROUND[2];
  }

  // Draw cells
  // text has rows separated by \n or 200 chars each
  const rawChars = text.replace(/\n/g, '');

  for (let r = 0; r < H; r++) {
    for (let c = 0; c < W; c++) {
      const k = r * W + c;
      const ch = rawChars[k];
      if (!ch || ch === ' ') continue;

      const palIdx = color[k];
      const rgb = PALETTE[palIdx] || PALETTE[0];

      // Draw dot inside SCALE x SCALE cell
      const startX = c * SCALE;
      const startY = r * SCALE;

      if (ch === '·') {
        // 1px center dot
        const px = startX + 1;
        const py = startY + 1;
        const idx = (py * OUT_W + px) * 3;
        frameBuffer[idx] = rgb[0];
        frameBuffer[idx + 1] = rgb[1];
        frameBuffer[idx + 2] = rgb[2];
      } else if (ch === '•') {
        // 2x2 dot
        for (let dy = 1; dy <= 2; dy++) {
          for (let dx = 1; dx <= 2; dx++) {
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      } else if (ch === '●') {
        // 3x3 circle
        for (let dy = 0; dy <= 3; dy++) {
          for (let dx = 0; dx <= 3; dx++) {
            if ((dx === 0 && dy === 0) || (dx === 3 && dy === 0) ||
                (dx === 0 && dy === 3) || (dx === 3 && dy === 3)) {
              continue; // Rounded corners
            }
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      }
    }
  }

  ffmpegMp4.stdin.write(frameBuffer);
}

ffmpegMp4.stdin.end();

ffmpegMp4.on('close', (code) => {
  console.log(`MP4 finished with code ${code}. Generating animated WebP...`);

  // Generate lightweight animated WebP from MP4
  const ffmpegWebp = spawn('ffmpeg', [
    '-y',
    '-i', mp4Path,
    '-vcodec', 'libwebp',
    '-filter:v', `fps=${FPS}`,
    '-lossless', '0',
    '-compression_level', '6',
    '-q:v', '75',
    '-loop', '0',
    webpPath,
  ]);

  ffmpegWebp.on('close', (wCode) => {
    console.log(`WebP finished with code ${wCode}. Generating GIF...`);

    const ffmpegGif = spawn('ffmpeg', [
      '-y',
      '-i', mp4Path,
      '-vf', `fps=${FPS},scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse`,
      gifPath,
    ]);

    ffmpegGif.on('close', (gCode) => {
      console.log(`All formats generated! Code ${gCode}`);
      console.log(`MP4 size: ${fs.statSync(mp4Path).size} bytes`);
      console.log(`WebP size: ${fs.statSync(webpPath).size} bytes`);
      console.log(`GIF size: ${fs.statSync(gifPath).size} bytes`);
    });
  });
});
