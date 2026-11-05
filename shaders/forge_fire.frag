#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

// The order must match the setFloat calls in flame_edge.dart.
uniform vec2 uSize;       // Painted area, in logical pixels.
uniform float uTime;      // Seconds.
uniform float uProgress;  // Sweep progress, 0 to 1.
uniform float uIntensity; // Ignition and extinction, 0 to 1.

out vec4 fragColor;

// Tuning constants.
const float kHalfWidth = 14.0;   // Half of the flame band, in logical pixels.
const float kWobble = 18.0;      // Sideways movement of the flames, in pixels.
const float kRiseSpeed = 3.2;    // How fast the flames go up.
const float kNoiseScale = 0.045; // Greater means smaller tongues of fire.
const float kGlowWidth = 64.0;   // Length of the glow on the forged side.
const float kGlowStrength = 0.3;

const vec3 kRed = vec3(0.80, 0.13, 0.02);
const vec3 kOrange = vec3(0.98, 0.42, 0.02);
const vec3 kYellow = vec3(1.00, 0.76, 0.15);
const vec3 kCore = vec3(1.00, 0.97, 0.78);

// Noise: value noise on a grid of random corners.
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
  vec2 cell = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
             mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), u.x),
             u.y);
}

// Noise: fbm, four octaves, from big tongues of fire to small details.
float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    value += amplitude * valueNoise(p);
    p *= 2.03;
    amplitude *= 0.5;
  }
  return value;
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  float dx = pos.x - uSize.x * (1.0 - uProgress);

  // Most of the card is out of reach: skip the noise there.
  if (uIntensity <= 0.0 || dx < -kHalfWidth - kWobble ||
      dx > kGlowWidth * 2.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Flame shape: the noise scrolls up and bends the band more at the top.
  float height = 1.0 - pos.y / uSize.y;
  float n = fbm(vec2(pos.x * kNoiseScale, pos.y * kNoiseScale + uTime * kRiseSpeed));
  float bent = dx + (n - 0.5) * kWobble * (0.4 + height);
  float body = clamp(1.0 - abs(bent) / kHalfWidth, 0.0, 1.0);
  float heat = body * (0.55 + 0.9 * n);

  // Color: from red at the edges to almost white in the core.
  vec3 color = mix(kRed, kOrange, smoothstep(0.05, 0.35, heat));
  color = mix(color, kYellow, smoothstep(0.35, 0.7, heat));
  color = mix(color, kCore, smoothstep(0.7, 1.0, heat));

  // Alpha: fades to the sides with the body and to the top with the noise.
  float top = 1.0 - smoothstep(0.55 + 0.35 * n, 1.0, height);
  float alpha = smoothstep(0.0, 0.3, heat) * top;

  // Glow: faint and only behind the band, over the forged side.
  float glow = dx > 0.0 ? kGlowStrength * exp(-dx / (kGlowWidth * 0.5)) : 0.0;
  glow *= 1.0 - height * 0.5;

  // Output with premultiplied alpha, the flame over its glow.
  vec3 premultiplied = color * alpha + kOrange * glow * (1.0 - alpha);
  float outAlpha = alpha + glow * (1.0 - alpha);
  fragColor = vec4(premultiplied, outAlpha) * uIntensity;
}
