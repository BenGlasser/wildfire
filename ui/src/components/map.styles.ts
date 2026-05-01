import styled, { keyframes } from "styled-components";

export const theme = {
  bgOuter: "#07080c",
  bgInner: "#15171f",
  stateFill: "rgba(255, 200, 140, 0.04)",
  stateStroke: "rgba(255, 200, 140, 0.45)",
  fireCore: "#fff2c8",
  fireGlow: "rgba(255, 140, 70, 0.85)",
  fireGlowOuter: "rgba(255, 60, 40, 0.0)",
  text: "#f5e9d2",
  accent: "#ffb45a"
} as const;

const pulse = keyframes`
  0%   { transform: scale(1);   opacity: 0.95; }
  50%  { transform: scale(1.6); opacity: 0.55; }
  100% { transform: scale(1);   opacity: 0.95; }
`;

export const Container = styled.section`
  background: radial-gradient(
    ellipse at center,
    ${theme.bgInner} 0%,
    ${theme.bgOuter} 70%
  );
  color: ${theme.text};
  font: 14px/1.4 ui-sans-serif, system-ui, -apple-system, sans-serif;
  padding: 24px;
  min-height: 100vh;
`;

export const Header = styled.header`
  margin-bottom: 16px;
`;

export const Title = styled.h1`
  margin: 0 0 4px 0;
  font-weight: 600;
  letter-spacing: 0.02em;

  span {
    color: ${theme.accent};
  }
`;

export const Subtitle = styled.div`
  opacity: 0.6;
`;

export const MapFrame = styled.div`
  border: 1px solid rgba(255, 200, 140, 0.18);
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.6);
`;

export const MapSvg = styled.svg`
  display: block;
  width: 100%;
  height: 78vh;
  background: transparent;
`;

export const StatesGroup = styled.g`
  fill: ${theme.stateFill};
  stroke: ${theme.stateStroke};
  stroke-width: 0.6;
  stroke-linejoin: round;
`;

export const PointsGroup = styled.g`
  pointer-events: none;
`;

export const FireGlow = styled.circle`
  fill: ${theme.fireGlow};
  filter: blur(2px);
  transform-box: fill-box;
  transform-origin: center;
  animation: ${pulse} 2.4s ease-in-out infinite;
`;

export const FireCore = styled.circle`
  fill: ${theme.fireCore};
  transform-box: fill-box;
  transform-origin: center;
`;
