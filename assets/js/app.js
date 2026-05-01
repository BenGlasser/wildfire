import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import * as d3 from "d3";
import { feature as topo2geo } from "topojson-client";
import usAtlas from "us-atlas/states-10m.json";

const Hooks = {};

// Spike 001 sanity hook
Hooks.MapHook = {
  mounted() {
    console.log("[MapHook] mounted on", this.el.id, "dataset.points sample:", (this.el.dataset.points || "").slice(0, 80));
    this.el.innerText = "[MapHook] mounted ✓";
  }
};

// Spike 002a — Leaflet
Hooks.LeafletMap = {
  mounted() {
    const t0 = performance.now();
    const points = JSON.parse(this.el.dataset.points || "[]");
    console.log(`[LeafletMap] points=${points.length}`);

    const map = L.map(this.el, { preferCanvas: true }).setView([39.5, -98.35], 4);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: "© OpenStreetMap"
    }).addTo(map);

    const t1 = performance.now();
    const markers = [];
    for (const p of points) {
      const m = L.circleMarker([p.lat, p.lon], {
        radius: Math.max(3, Math.min(12, Math.sqrt((p.size || 1)) / 8)),
        color: "#d33",
        weight: 1,
        fillColor: "#f55",
        fillOpacity: 0.6
      }).bindPopup(`<strong>${p.name || "(unnamed)"}</strong><br>size: ${p.size ?? "?"}`);
      m.addTo(map);
      markers.push(m);
    }
    const t2 = performance.now();
    console.log(`[LeafletMap] tiles=${(t1 - t0).toFixed(1)}ms markers=${(t2 - t1).toFixed(1)}ms total=${(t2 - t0).toFixed(1)}ms`);

    this._map = map;
    this._markers = markers;
    window._leafletSpike = { map, markers, points };
  },
  destroyed() {
    if (this._map) this._map.remove();
  }
};

// Spike 002c — D3 canvas map (dark theme, glowing pulsing incidents)
Hooks.D3Map = {
  mounted() {
    const t0 = performance.now();
    const points = JSON.parse(this.el.dataset.points || "[]");
    const states = topo2geo(usAtlas, usAtlas.objects.states);

    const wrap = d3.select(this.el);
    wrap.style("position", "relative");
    const tooltip = wrap.append("div")
      .attr("class", "d3map-tooltip")
      .style("position", "absolute")
      .style("pointer-events", "none")
      .style("padding", "6px 10px")
      .style("font", "12px/1.3 ui-sans-serif,system-ui,-apple-system")
      .style("background", "rgba(15,15,20,0.92)")
      .style("color", "#f5e9d2")
      .style("border", "1px solid rgba(255,180,90,0.45)")
      .style("border-radius", "6px")
      .style("box-shadow", "0 4px 20px rgba(0,0,0,0.6)")
      .style("opacity", 0)
      .style("transition", "opacity 120ms ease");

    const dpr = window.devicePixelRatio || 1;
    const rect = this.el.getBoundingClientRect();
    const W = Math.max(rect.width, 800);
    const H = Math.max(rect.height, 500);

    const canvas = wrap.append("canvas")
      .attr("width", W * dpr)
      .attr("height", H * dpr)
      .style("width", W + "px")
      .style("height", H + "px")
      .style("display", "block")
      .node();
    const ctx = canvas.getContext("2d");
    ctx.scale(dpr, dpr);

    const projection = d3.geoAlbersUsa().fitSize([W, H], states);
    const path = d3.geoPath(projection, ctx);

    // Build sized point list (project once, store screen coords)
    const sizeExtent = d3.extent(points, p => p.size).map(v => v ?? 1);
    const radiusScale = d3.scaleSqrt().domain([1, Math.max(sizeExtent[1], 100)]).range([2, 18]);
    const projected = points
      .map(p => {
        const xy = projection([p.lon, p.lat]);
        if (!xy) return null;
        return { ...p, x: xy[0], y: xy[1], r: radiusScale((p.size ?? 1) || 1) };
      })
      .filter(Boolean);

    let transform = d3.zoomIdentity;
    let pulsePhase = 0;

    function fillBackground(ctx) {
      // radial dark gradient as actual canvas pixels (not CSS bg, so screenshots capture it)
      const g = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, Math.max(W, H) * 0.7);
      g.addColorStop(0, "#15171f");
      g.addColorStop(1, "#07080c");
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, W, H);
    }

    function drawStates(ctx) {
      ctx.lineJoin = "round";
      ctx.beginPath();
      path(states);
      ctx.fillStyle = "rgba(255,200,140,0.06)";
      ctx.fill();
      ctx.strokeStyle = "rgba(255,200,140,0.55)";
      ctx.lineWidth = 0.8 / transform.k;
      ctx.stroke();
    }

    function drawPoints(ctx, t) {
      const pulse = 0.5 + 0.5 * Math.sin(t / 600);
      // additive blending so overlapping glows pile up like real fire
      ctx.globalCompositeOperation = "lighter";
      for (const p of projected) {
        // big soft halo
        const haloR = (p.r + 2) * (2.4 + pulse * 0.6);
        const glow = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, haloR);
        glow.addColorStop(0, "rgba(255,180,90,0.85)");
        glow.addColorStop(0.45, "rgba(255,80,40,0.35)");
        glow.addColorStop(1, "rgba(255,40,20,0)");
        ctx.fillStyle = glow;
        ctx.beginPath();
        ctx.arc(p.x, p.y, haloR, 0, Math.PI * 2);
        ctx.fill();

        // bright opaque core
        ctx.beginPath();
        ctx.arc(p.x, p.y, Math.max(p.r, 2), 0, Math.PI * 2);
        ctx.fillStyle = "#fff2c8";
        ctx.fill();
      }
      ctx.globalCompositeOperation = "source-over";
    }

    function frame(t) {
      ctx.save();
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0); // reset to dpr-scaled identity
      fillBackground(ctx);
      ctx.translate(transform.x, transform.y);
      ctx.scale(transform.k, transform.k);
      drawStates(ctx);
      drawPoints(ctx, t);
      ctx.restore();
      this._raf = requestAnimationFrame(frame.bind(this));
    }
    this._raf = requestAnimationFrame(frame.bind(this));

    // Zoom & pan
    const zoom = d3.zoom().scaleExtent([1, 12]).on("zoom", (ev) => {
      transform = ev.transform;
    });
    d3.select(canvas).call(zoom);

    // Hover detection (in screen coords, account for transform)
    function findPoint(mx, my) {
      const ux = (mx - transform.x) / transform.k;
      const uy = (my - transform.y) / transform.k;
      let best = null;
      let bestDist = Infinity;
      for (const p of projected) {
        const dx = p.x - ux;
        const dy = p.y - uy;
        const d2 = dx * dx + dy * dy;
        const r = p.r + 4;
        if (d2 < r * r && d2 < bestDist) { best = p; bestDist = d2; }
      }
      return best;
    }
    d3.select(canvas).on("mousemove", (ev) => {
      const [mx, my] = d3.pointer(ev, canvas);
      const hit = findPoint(mx, my);
      if (hit) {
        tooltip
          .style("opacity", 1)
          .style("left", (mx + 14) + "px")
          .style("top", (my + 14) + "px")
          .html(`<strong style="color:#ffd28a">${hit.name || "(unnamed)"}</strong><br>size: ${hit.size?.toLocaleString() ?? "—"}<br><span style="opacity:.6">${hit.lat.toFixed(2)}, ${hit.lon.toFixed(2)}</span>`);
      } else {
        tooltip.style("opacity", 0);
      }
    });
    d3.select(canvas).on("mouseleave", () => tooltip.style("opacity", 0));

    const t1 = performance.now();
    console.log(`[D3Map] points=${projected.length}/${points.length} setup=${(t1 - t0).toFixed(1)}ms`);
    window._d3Spike = { projected, transform: () => transform };
  },
  destroyed() {
    if (this._raf) cancelAnimationFrame(this._raf);
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});
liveSocket.connect();
window.liveSocket = liveSocket;
