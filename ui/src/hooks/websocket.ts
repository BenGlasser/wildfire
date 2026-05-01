import { useEffect, useRef, useState } from "react";
import type { Feature, FeatureCollection, Point } from "geojson";

export type SocketStatus = "idle" | "connecting" | "open" | "closed" | "error";

type IncidentProperties = {
  GlobalID?: string;
  IncidentName?: string;
  IncidentSize?: number | string;
  [key: string]: unknown;
};

export type IncidentFeature = Feature<Point, IncidentProperties>;
export type IncidentCollection = FeatureCollection<Point, IncidentProperties>;

type IncidentEvent =
  | { init: IncidentFeature[] }
  | { created: IncidentFeature[] }
  | { updated: IncidentFeature[] }
  | { resolved: IncidentFeature[] };

type EventKind = "init" | "created" | "updated" | "resolved";

export type UseGeoSocketResult = {
  geojson: IncidentCollection;
  status: SocketStatus;
};

const EMPTY_COLLECTION: IncidentCollection = {
  type: "FeatureCollection",
  features: []
};

const RECONNECT_BASE_MS = 500;
const RECONNECT_MAX_MS = 30_000;

export function useGeoSocket(url: string): UseGeoSocketResult {
  const [geojson, setGeojson] = useState<IncidentCollection>(EMPTY_COLLECTION);
  const [status, setStatus] = useState<SocketStatus>("idle");
  const geojsonRef = useRef(geojson);
  geojsonRef.current = geojson;

  useEffect(() => {
    if (!url) return;

    let cancelled = false;
    let socket: WebSocket | null = null;
    let reconnectTimer: ReturnType<typeof setTimeout> | null = null;
    let retry = 0;

    const connect = () => {
      if (cancelled) return;
      setStatus("connecting");
      socket = new WebSocket(url);

      socket.onopen = () => {
        if (cancelled) return;
        retry = 0;
        setStatus("open");
      };

      socket.onmessage = (event) => {
        if (cancelled) return;
        const parsed = parseEvent(event.data);
        if (!parsed) return;
        setGeojson((prev) => apply(prev, parsed));
      };

      socket.onerror = () => {
        if (cancelled) return;
        setStatus("error");
      };

      socket.onclose = () => {
        if (cancelled) return;
        setStatus("closed");
        scheduleReconnect();
      };
    };

    const scheduleReconnect = () => {
      if (cancelled) return;
      const delay = Math.min(RECONNECT_MAX_MS, RECONNECT_BASE_MS * 2 ** retry);
      retry += 1;
      reconnectTimer = setTimeout(connect, delay);
    };

    connect();

    return () => {
      cancelled = true;
      if (reconnectTimer) clearTimeout(reconnectTimer);
      if (socket) {
        socket.onopen = null;
        socket.onmessage = null;
        socket.onerror = null;
        socket.onclose = null;
        if (
          socket.readyState === WebSocket.OPEN ||
          socket.readyState === WebSocket.CONNECTING
        ) {
          socket.close();
        }
      }
    };
  }, [url]);

  return { geojson, status };
}

function parseEvent(raw: unknown): { kind: EventKind; features: IncidentFeature[] } | null {
  const obj = typeof raw === "string" ? safeParse(raw) : (raw as IncidentEvent | null);
  if (!obj || typeof obj !== "object") return null;

  for (const kind of ["init", "created", "updated", "resolved"] as const) {
    const features = (obj as Record<string, unknown>)[kind];
    if (Array.isArray(features)) {
      return { kind, features: features as IncidentFeature[] };
    }
  }
  return null;
}

function safeParse(raw: string): IncidentEvent | null {
  try {
    return JSON.parse(raw) as IncidentEvent;
  } catch {
    return null;
  }
}

function apply(
  prev: IncidentCollection,
  event: { kind: EventKind; features: IncidentFeature[] }
): IncidentCollection {
  switch (event.kind) {
    case "init":
      return { type: "FeatureCollection", features: event.features };

    case "created":
    case "updated": {
      const incoming = indexById(event.features);
      if (incoming.size === 0) return prev;
      const merged = prev.features.map((f) => incoming.get(idOf(f)) ?? f);
      const seen = new Set(prev.features.map(idOf));
      for (const feature of event.features) {
        if (!seen.has(idOf(feature))) merged.push(feature);
      }
      return { type: "FeatureCollection", features: merged };
    }

    case "resolved": {
      const drop = new Set(event.features.map(idOf));
      if (drop.size === 0) return prev;
      return {
        type: "FeatureCollection",
        features: prev.features.filter((f) => !drop.has(idOf(f)))
      };
    }
  }
}

function indexById(features: IncidentFeature[]): Map<string, IncidentFeature> {
  const map = new Map<string, IncidentFeature>();
  for (const feature of features) {
    map.set(idOf(feature), feature);
  }
  return map;
}

function idOf(feature: IncidentFeature): string {
  return String(feature.properties?.GlobalID ?? feature.id ?? "");
}
