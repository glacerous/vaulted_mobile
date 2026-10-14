import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import cloudSea, { meta } from './cloud-sea-engine.js';

const W = 200;
const H = 100;
const SCALE = 3; // 600 x 300 - perfect crisp mobile aspect
const OUT_W = W * SCALE;
const OUT_H = H * SCALE;

const FPS = 30; // Smooth 30 FPS (not 15 or 2 FPS!)
const DURATION = 6; // 6 seconds
const TOTAL_FRAMES = FPS * DURATION; // 180 frames

const PALETTE = meta.palette.map(hex => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return [r, g, b];
});

const GROUND = [14, 14, 15]; // #0e0e0f

console.log(`Generating ${TOTAL_FRAMES} frames at ${OUT_W}x${OUT_H} (${FPS} FPS)...`);

const fn = cloudSea();
const color = new Uint8Array(W * H);
const frameBuffer = Buffer.alloc(OUT_W * OUT_H * 3);

const assetsDir = path.join(process.cwd(), 'assets', 'images');
const rawMp4 = path.join(assetsDir, 'cloud_sea_raw.mp4');
const loopMp4 = path.join(assetsDir, 'cloud_sea_dither.mp4');
const gifPath = path.join(assetsDir, 'cloud_sea_dither.gif');
const webpPath = path.join(assetsDir, 'cloud_sea_dither.webp');

const ffmpegRaw = spawn('ffmpeg', [
  '-y',
  '-f', 'rawvideo',
  '-pixel_format', 'rgb24',
  '-video_size', `${OUT_W}x${OUT_H}`,
  '-framerate', `${FPS}`,
  '-i', 'pipe:0',
  '-c:v', 'libx264',
  '-pix_fmt', 'yuv420p',
  '-preset', 'fast',
  '-crf', '18',
  rawMp4,
]);

ffmpegRaw.stderr.on('data', () => {});

// Speed multiplier: 3.5x so drift is visibly, gracefully moving (not static!)
const SPEED_MULT = 3.5;

for (let frameIdx = 0; frameIdx < TOTAL_FRAMES; frameIdx++) {
  const t = (frameIdx / FPS) * SPEED_MULT;
  const text = fn(t, { color });

  // Clear frame with GROUND
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

      // Draw crisp dots on 3x3 cell
      if (ch === '·') {
        // 1px center dot
        const idx = ((startY + 1) * OUT_W + (startX + 1)) * 3;
        frameBuffer[idx] = rgb[0];
        frameBuffer[idx + 1] = rgb[1];
        frameBuffer[idx + 2] = rgb[2];
      } else if (ch === '•') {
        // 2x2 square dot
        for (let dy = 0; dy <= 1; dy++) {
          for (let dx = 0; dx <= 1; dx++) {
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      } else if (ch === '●') {
        // Full 3x3 dot
        for (let dy = 0; dy < 3; dy++) {
          for (let dx = 0; dx < 3; dx++) {
            const idx = ((startY + dy) * OUT_W + (startX + dx)) * 3;
            frameBuffer[idx] = rgb[0];
            frameBuffer[idx + 1] = rgb[1];
            frameBuffer[idx + 2] = rgb[2];
          }
        }
      }
    }
  }

  ffmpegRaw.stdin.write(frameBuffer);
}

ffmpegRaw.stdin.end();

ffmpegRaw.on('close', (code) => {
  console.log(`Raw video done (code ${code}). Creating seamless loop...`);

  // Create seamless loop by crossfading the last 0.8s with the beginning
  // Filter: split, trim, xfade
  const ffmpegLoop = spawn('ffmpeg', [
    '-y',
    '-i', rawMp4,
    '-filter_complex',
    `[0:v]split=2[v1][v2];` +
    `[v1]trim=0:5.2,setpts=PTS-STARTPTS[main];` +
    `[v2]trim=5.2:6.0,setpts=PTS-STARTPTS[end];` +
    `[end][main]xfade=transition=fade:duration=0.6:offset=0[out]`,
    '-map', '[out]',
    '-c:v', 'libx264',
    '-pix_fmt', 'yuv420p',
    '-crf', '18',
    loopMp4,
  ]);

  ffmpegLoop.on('close', () => {
    console.log('Seamless MP4 created. Now generating high-fps WebP & GIF...');

    // Generate WebP with 30 fps
    const ffmpegWebp = spawn('ffmpeg', [
      '-y',
      '-i', loopMp4,
      '-vcodec', 'libwebp',
      '-lossless', '0',
      '-q:v', '80',
      '-loop', '0',
      webpPath,
    ]);

    ffmpegWebp.on('close', () => {
      console.log('WebP done. Generating optimized 30fps GIF...');

      // Generate 30fps GIF with high quality palette
      const ffmpegGif = spawn('ffmpeg', [
        '-y',
        '-i', loopMp4,
        '-vf', `fps=30,split[s0][s1];[s0]palettegen=max_colors=32:reserve_transparent=0[p];[s1][p]paletteuse=dither=none`,
        gifPath,
      ]);

      ffmpegGif.on('close', () => {
        console.log('All formats generated!');
        console.log('MP4:', fs.statSync(loopMp4).size, 'bytes');
        console.log('WebP:', fs.statSync(webpPath).size, 'bytes');
        console.log('GIF:', fs.statSync(gifPath).size, 'bytes');
      });
    });
  });
});
