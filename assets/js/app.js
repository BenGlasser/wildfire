import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const Hooks = {};

Hooks.MapHook = {
  mounted() {
    console.log("[MapHook] mounted on", this.el.id, "dataset.points sample:", (this.el.dataset.points || "").slice(0, 80));
    this.el.innerText = "[MapHook] mounted ✓";
  },
  updated() {
    console.log("[MapHook] updated");
  },
  destroyed() {
    console.log("[MapHook] destroyed");
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});
liveSocket.connect();
window.liveSocket = liveSocket;
