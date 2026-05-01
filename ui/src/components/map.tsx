import { useMemo, useRef } from "react";
import { geoAlbersUsa, geoPath } from "d3";
import { usStates } from "./us-topo";
import type { IncidentCollection, IncidentFeature } from "../hooks/websocket";
import {
  Container,
  Header,
  Title,
  Subtitle,
  MapFrame,
  MapSvg,
  StatesGroup,
  PointsGroup,
  FireGlow,
  FireCore
} from "./map.styles";

const VIEW_W = 975;
const VIEW_H = 610;
const MIN_RADIUS = 2;
const MAX_RADIUS = 14;

type Props = {
  geojson: IncidentCollection;
  title?: string;
};

type Projected = {
  key: string;
  x: number;
  y: number;
  r: number;
  name: string;
  size: number;
};

export function Map({ geojson, title = "Wildfire · Live" }: Props) {
  const svgRef = useRef<SVGSVGElement | null>(null);

  const projection = useMemo(() => {
    return geoAlbersUsa().fitSize([VIEW_W, VIEW_H], usStates);
  }, []);

  const statePath = useMemo(() => geoPath(projection), [projection]);

  const radiusScale = useMemo(() => {
    const sizes = geojson.features
      .map((f) => sizeOf(f))
      .filter((n) => n > 0);
    const max = sizes.length ? Math.max(...sizes) : 1;
    return (size: number) => {
      const clamped = Math.max(0, size);
      const t = Math.sqrt(clamped) / Math.sqrt(max);
      return MIN_RADIUS + t * (MAX_RADIUS - MIN_RADIUS);
    };
  }, [geojson.features]);

  const projected = useMemo<Projected[]>(() => {
    return geojson.features
      .map((feature, i) => toProjected(feature, i, projection, radiusScale))
      .filter((p): p is Projected => p !== null);
  }, [geojson.features, projection, radiusScale]);

  return (
    <Container>
      <Header>
        <Title>
          Wildfire <span>·</span> Live
        </Title>
        <Subtitle>
          {projected.length} active incidents · {title}
        </Subtitle>
      </Header>
      <MapFrame>
        <MapSvg
          ref={svgRef}
          viewBox={`0 0 ${VIEW_W} ${VIEW_H}`}
          preserveAspectRatio="xMidYMid meet"
        >
          <StatesGroup>
            {usStates.features.map((f, i) => (
              <path key={i} d={statePath(f) ?? undefined} />
            ))}
          </StatesGroup>
          <PointsGroup>
            {projected.map((p) => (
              <g key={p.key}>
                <FireGlow cx={p.x} cy={p.y} r={p.r * 2.2} />
                <FireCore cx={p.x} cy={p.y} r={p.r} />
                <title>
                  {p.name} — size {p.size.toLocaleString()}
                </title>
              </g>
            ))}
          </PointsGroup>
        </MapSvg>
      </MapFrame>
    </Container>
  );
}

function toProjected(
  feature: IncidentFeature,
  index: number,
  projection: ReturnType<typeof geoAlbersUsa>,
  radiusScale: (size: number) => number
): Projected | null {
  const coords = feature.geometry?.coordinates;
  if (!Array.isArray(coords) || coords.length < 2) return null;
  const xy = projection([coords[0], coords[1]]);
  if (!xy) return null;
  const size = sizeOf(feature) || 1;
  return {
    key: String(feature.properties?.GlobalID ?? feature.id ?? index),
    x: xy[0],
    y: xy[1],
    r: radiusScale(size),
    name: feature.properties?.IncidentName ?? "(unnamed)",
    size
  };
}

function sizeOf(feature: IncidentFeature): number {
  const raw = feature.properties?.IncidentSize;
  if (typeof raw === "number") return raw;
  if (typeof raw === "string") {
    const parsed = parseFloat(raw);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

export default Map;
