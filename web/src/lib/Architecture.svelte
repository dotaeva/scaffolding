<script>
  import CodeBlock from '$lib/CodeBlock.svelte';
  import { VBW, VBH, NODES, EDGES, PARENT, CODE } from '$lib/architecture/data.js';


  let selected = $state('app');
  let locked = $state(false);

  /** Hover/focus updates selection only when not pinned. */
  function peek(id) {
    if (locked) return;
    selected = id;
  }

  /** Click pins a node. Clicking the same pinned node releases the pin. */
  function pin(id) {
    if (locked && selected === id) {
      locked = false;
      return;
    }
    selected = id;
    locked = true;
  }

  function release() {
    locked = false;
  }

  // Esc releases the pin, anywhere on the page.
  $effect(() => {
    function onKey(e) {
      if (e.key === 'Escape' && locked) {
        locked = false;
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  function getAncestors(id) {
    const chain = [];
    let cur = PARENT[id];
    while (cur) { chain.push(cur); cur = PARENT[cur]; }
    return chain;
  }

  function isNodeOnPath(id) {
    if (id === selected) return true;
    if (PARENT[id] === selected) return true; // direct child
    return getAncestors(selected).includes(id);
  }

  function isEdgeOnPath(edge) {
    const a = edge[0];
    const b = edge[1];
    if (a === selected || b === selected) return true;
    let cur = selected;
    while (PARENT[cur]) {
      if (a === PARENT[cur] && b === cur) return true;
      cur = PARENT[cur];
    }
    return false;
  }

  function makePath(fromId, toId) {
    const a = NODES[fromId];
    const b = NODES[toId];
    const sx = a.x;
    const sy = a.y + a.h / 2;
    const ex = b.x;
    const ey = b.y - b.h / 2;
    const midY = (sy + ey) / 2;
    return `M ${sx} ${sy} C ${sx} ${midY}, ${ex} ${midY}, ${ex} ${ey}`;
  }
</script>

<section class="arch hold" id="arch" aria-label="Coordinator architecture">
  <div class="arch-inner">
    <header class="head">
      <span class="num">03 / Architecture</span>
      <h2>How it composes, end to end.</h2>
      <p class="note">
        Roots switch state, tabs hold flows, flows push screens.
        <strong>Hover</strong> to peek a node, <strong>click</strong> to pin it
        — the path back to the root highlights so you can see how it's wired.
      </p>
    </header>

    <div class="diagram-wrap">
      <div class="diagram" style="--vbw: {VBW}; --vbh: {VBH};">
        <svg
          class="edges"
          viewBox={`0 0 ${VBW} ${VBH}`}
          preserveAspectRatio="xMidYMid meet"
          aria-hidden="true"
        >
          {#each EDGES as edge}
            <path
              d={makePath(edge[0], edge[1])}
              class="edge"
              class:active={isEdgeOnPath(edge)}
              data-kind={edge[2]?.kind ?? 'push'}
            />
          {/each}
        </svg>

        {#each Object.entries(NODES) as [id, n]}
          {@const cx = (n.x / VBW) * 100}
          {@const cy = (n.y / VBH) * 100}
          {@const w = (n.w / VBW) * 100}
          {@const h = (n.h / VBH) * 100}
          <button
            type="button"
            class="node"
            class:selected={selected === id}
            class:pinned={selected === id && locked}
            class:on-path={isNodeOnPath(id) && selected !== id}
            class:dim={!isNodeOnPath(id)}
            data-kind={n.kind}
            style="left: {cx}%; top: {cy}%; width: {w}%; height: {h}%;"
            onmouseenter={() => peek(id)}
            onfocus={() => peek(id)}
            onclick={() => pin(id)}
            aria-pressed={selected === id && locked}
            aria-label="{n.title} ({n.kind}). {n.subtitle}. {selected === id && locked ? 'Pinned. Click to release.' : 'Click to pin.'}"
          >
            <span class="kind-row">
              <span class="kind-dot" aria-hidden="true"></span>
              <span class="kind">{n.kind}</span>
              {#if selected === id && locked}
                <span class="pin-glyph" aria-hidden="true">●</span>
              {/if}
            </span>
            <span class="name">{n.short}</span>
            <span class="sub">{n.subtitle}</span>
          </button>
        {/each}
      </div>

      <div class="bar">
        <div class="legend" aria-hidden="true">
          <span class="legend-group">
            <span class="legend-item" data-kind="Root"><span class="legend-dot"></span>Root</span>
            <span class="legend-item" data-kind="Tab"><span class="legend-dot"></span>Tab</span>
            <span class="legend-item" data-kind="Flow"><span class="legend-dot"></span>Flow</span>
            <span class="legend-item" data-kind="Screen"><span class="legend-dot"></span>Screen</span>
          </span>
          <span class="legend-sep" aria-hidden="true">·</span>
          <span class="legend-group">
            <span class="legend-item legend-edge" data-edge="setRoot"><span class="legend-line"></span>setRoot</span>
            <span class="legend-item legend-edge" data-edge="tab"><span class="legend-line"></span>tab</span>
            <span class="legend-item legend-edge" data-edge="push"><span class="legend-line"></span>route</span>
            <span class="legend-item legend-edge" data-edge="present"><span class="legend-line"></span>present</span>
          </span>
        </div>

        <div class="status" class:on={locked}>
          {#if locked}
            <span class="status-icon" aria-hidden="true">●</span>
            <span class="status-text">
              <strong>{NODES[selected].title}</strong> pinned
            </span>
            <button type="button" class="status-btn" onclick={release}>
              Release <kbd>Esc</kbd>
            </button>
          {:else}
            <span class="status-icon dim" aria-hidden="true">○</span>
            <span class="status-text">
              Hover to peek · <strong>click</strong> a node to pin
            </span>
          {/if}
        </div>
      </div>
    </div>

    <aside class="panel">
      <div class="panel-head">
        <span class="badge" data-kind={NODES[selected].kind}>
          <span class="badge-dot" aria-hidden="true"></span>
          {NODES[selected].kind}
        </span>
        <div class="panel-titles">
          <span class="panel-title">
            {NODES[selected].title}
            {#if locked}
              <span class="pinned-flag" aria-label="Pinned">📌</span>
            {/if}
          </span>
          <span class="panel-sub">{NODES[selected].subtitle}</span>
        </div>
      </div>

      <div class="ide">
        <nav class="files" aria-label="Files">
          <p class="files-label">Files</p>
          <ul class="files-list">
            {#each Object.entries(NODES) as [id, n]}
              <li>
                <button
                  type="button"
                  class="file"
                  class:active={selected === id}
                  data-kind={n.kind}
                  onclick={() => pin(id)}
                  aria-current={selected === id ? 'true' : undefined}
                >
                  <span class="file-dot" aria-hidden="true"></span>
                  <span class="file-name">{n.file}</span>
                  {#if selected === id && locked}
                    <span class="file-pin" aria-hidden="true">●</span>
                  {/if}
                </button>
              </li>
            {/each}
          </ul>
        </nav>
        <div class="code-area">
          <CodeBlock code={CODE[selected]} label={NODES[selected].file} />
        </div>
      </div>
    </aside>
  </div>
</section>

<style>
  .arch {
    width: 100%;
    padding: clamp(3.5rem, 8vw, 6rem) 0;
  }

  .arch-inner {
    max-width: 1280px;
    margin: 0 auto;
    padding: 0 clamp(1.25rem, 4vw, 3rem);
  }

  /* When the ScrollProgress rail enters its full-label mode (≥ 1340 vw)
     it occupies ~210 px on the right of the viewport. Cap the inner
     container so its right edge clears the rail. */
  @media (min-width: 1340px) {
    .arch-inner {
      max-width: min(1280px, calc(100vw - 440px));
    }
  }

  .head {
    display: flex;
    flex-direction: column;
    gap: 0.65rem;
    margin-bottom: clamp(2rem, 3.5vw, 3rem);
    max-width: 64ch;
  }

  .num {
    font-size: 11px;
    letter-spacing: 0.16em;
    color: var(--dim);
    text-transform: uppercase;
  }

  .head h2 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: clamp(1.5rem, 2.6vw, 2rem);
    font-weight: 500;
    letter-spacing: -0.015em;
    color: var(--fg);
  }

  .note {
    margin: 0;
    font-size: 14px;
    line-height: 1.65;
    color: color-mix(in srgb, var(--fg) 70%, transparent);
  }

  .note strong {
    color: var(--fg);
    font-weight: 500;
  }

  /* ── Diagram block ────────────────────────────────────────────────── */

  .diagram-wrap {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .diagram {
    position: relative;
    width: 100%;
    aspect-ratio: var(--vbw) / var(--vbh);
    border: 1px solid var(--line);
    background:
      radial-gradient(
        ellipse at 50% -10%,
        color-mix(in srgb, var(--fg) 5%, transparent),
        transparent 65%
      ),
      var(--surface);
    border-radius: 10px;
    overflow: hidden;
    container-type: inline-size;
    container-name: arch;
    transition: border-color 220ms ease, background 220ms ease;
  }

  .edges {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
  }

  .edge {
    fill: none;
    stroke: color-mix(in srgb, var(--fg) 18%, transparent);
    stroke-width: 1.4;
    stroke-linecap: round;
    transition: stroke 240ms ease, stroke-width 240ms ease;
  }

  .edge.active {
    stroke: color-mix(in srgb, var(--fg) 80%, transparent);
    stroke-width: 2.2;
  }

  /* Edge styles encode the API call that produces the parent→child
     relationship. push (route) is solid, present is dashed, setRoot
     and tab use a finer dotted pattern so all four are visually
     distinct without competing too loudly with the nodes. */
  .edge[data-kind='push']    { /* default solid */ }
  .edge[data-kind='present'] { stroke-dasharray: 4 5; }
  .edge[data-kind='setRoot'] { stroke-dasharray: 1 4; }
  .edge[data-kind='tab']     { stroke-dasharray: 2 3; }

  .node {
    position: absolute;
    transform: translate(-50%, -50%);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    gap: 5px;
    padding: 0 1.1rem;
    border-radius: 7px;
    border: 1px solid var(--line);
    background: var(--bg);
    color: var(--fg);
    font-family: var(--font-mono);
    cursor: pointer;
    text-align: left;
    transition:
      border-color 220ms ease,
      background-color 220ms ease,
      box-shadow 240ms ease,
      opacity 240ms ease,
      transform 240ms cubic-bezier(0.2, 0.7, 0.3, 1);
  }

  .node:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 55%, transparent);
  }

  .kind-row {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    line-height: 1;
  }

  .kind-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--fg) 30%, transparent);
    transition: background-color 220ms ease;
    flex-shrink: 0;
  }

  .node[data-kind='Root']   .kind-dot { background: color-mix(in srgb, var(--syn-att) 80%, transparent); }
  .node[data-kind='Tab']    .kind-dot { background: color-mix(in srgb, var(--syn-fn)  80%, transparent); }
  .node[data-kind='Flow']   .kind-dot { background: color-mix(in srgb, var(--syn-ty)  80%, transparent); }
  .node[data-kind='Screen'] .kind-dot { background: color-mix(in srgb, var(--syn-kw)  80%, transparent); }

  .kind {
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
    transition: color 220ms ease;
  }

  .pin-glyph {
    margin-left: auto;
    font-size: 8px;
    color: var(--syn-kw);
    line-height: 1;
  }

  .name {
    font-size: 17px;
    font-weight: 500;
    letter-spacing: -0.01em;
    color: var(--fg);
    line-height: 1.05;
  }

  .sub {
    font-size: 12.5px;
    line-height: 1.3;
    color: color-mix(in srgb, var(--fg) 58%, transparent);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100%;
  }

  /* Hide subtitles on very small diagrams. */
  @container arch (max-width: 900px) {
    .sub { display: none; }
    .name { font-size: 14px; }
    .node { gap: 3px; padding: 0 0.7rem; }
    .kind { font-size: 10px; }
  }

  .node.dim {
    opacity: 0.35;
  }

  .node.on-path {
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
  }

  .node.selected {
    border-color: var(--fg);
    background: color-mix(in srgb, var(--fg) 7%, var(--bg));
    box-shadow:
      0 1px 0 color-mix(in srgb, var(--fg) 25%, transparent),
      0 18px 40px -14px color-mix(in srgb, var(--fg) 45%, transparent);
    transform: translate(-50%, -50%) scale(1.04);
    opacity: 1;
  }

  .node.selected .kind {
    color: var(--fg);
  }

  .node.pinned {
    border-color: var(--syn-kw);
    box-shadow:
      0 0 0 1px color-mix(in srgb, var(--syn-kw) 70%, transparent),
      0 18px 40px -14px color-mix(in srgb, var(--syn-kw) 50%, transparent);
  }

  .node:not(.selected):hover {
    border-color: color-mix(in srgb, var(--fg) 45%, transparent);
    opacity: 1;
  }

  /* ── Bar (legend + status) ────────────────────────────────────────── */

  .bar {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.85rem 1.5rem;
  }

  .legend {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.6rem 1.2rem;
    font-size: 11.5px;
    letter-spacing: 0.04em;
    color: var(--muted);
  }

  .legend-group {
    display: inline-flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.6rem 1rem;
  }

  .legend-sep {
    color: var(--dim);
    font-size: 10px;
  }

  .legend-item {
    display: inline-flex;
    align-items: center;
    gap: 0.45rem;
  }

  /* Node-kind dots */
  .legend-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--fg) 30%, transparent);
  }

  .legend-item[data-kind='Root']   .legend-dot { background: var(--syn-att); }
  .legend-item[data-kind='Tab']    .legend-dot { background: var(--syn-fn); }
  .legend-item[data-kind='Flow']   .legend-dot { background: var(--syn-ty); }
  .legend-item[data-kind='Screen'] .legend-dot { background: var(--syn-kw); }

  /* Edge-style swatches — short strokes whose dasharray mirrors the
     SVG paths in the diagram. */
  .legend-edge .legend-line {
    width: 22px;
    height: 0;
    border-top: 1.4px solid color-mix(in srgb, var(--fg) 55%, transparent);
  }
  .legend-edge[data-edge='push']    .legend-line { /* solid */ }
  .legend-edge[data-edge='present'] .legend-line { border-top-style: dashed; }
  .legend-edge[data-edge='setRoot'] .legend-line { border-top-style: dotted; border-top-width: 1.6px; }
  .legend-edge[data-edge='tab']     .legend-line { border-top-style: dashed; border-top-width: 1.4px; opacity: 0.65; }

  .status {
    display: inline-flex;
    align-items: center;
    gap: 0.55rem;
    padding: 0.4rem 0.75rem;
    border: 1px solid var(--line);
    border-radius: 999px;
    background: var(--surface);
    font-size: 12px;
    color: var(--muted);
    transition: border-color 220ms ease, color 220ms ease, background-color 220ms ease;
  }

  .status.on {
    border-color: color-mix(in srgb, var(--syn-kw) 50%, transparent);
    color: var(--fg);
  }

  .status-icon {
    font-size: 8px;
    line-height: 1;
    color: var(--syn-kw);
  }

  .status-icon.dim {
    color: var(--dim);
  }

  .status-text strong {
    color: var(--fg);
    font-weight: 500;
  }

  .status-btn {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    margin-left: 0.25rem;
    padding: 0.18rem 0.5rem;
    font: inherit;
    font-size: 11px;
    color: var(--muted);
    background: transparent;
    border: 1px solid var(--line);
    border-radius: 999px;
    cursor: pointer;
    transition: color 140ms ease, border-color 140ms ease, background-color 140ms ease;
  }

  .status-btn:hover {
    color: var(--fg);
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
    background: color-mix(in srgb, var(--fg) 5%, transparent);
  }

  kbd {
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 1px 5px;
    border: 1px solid var(--line);
    border-radius: 3px;
    color: var(--fg);
    background: color-mix(in srgb, var(--fg) 6%, transparent);
  }

  /* ── Code panel ───────────────────────────────────────────────────── */

  .panel {
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
  }

  .panel-head {
    display: flex;
    align-items: center;
    gap: 0.85rem;
    flex-wrap: wrap;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    padding: 0.32rem 0.7rem;
    border: 1px solid var(--line);
    border-radius: 999px;
    color: var(--fg);
    background: var(--surface);
    flex-shrink: 0;
    font-family: var(--font-mono);
  }

  .badge-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--fg) 35%, transparent);
  }

  .badge[data-kind='Root']   { color: var(--syn-att); border-color: color-mix(in srgb, var(--syn-att) 45%, transparent); }
  .badge[data-kind='Tab']    { color: var(--syn-fn);  border-color: color-mix(in srgb, var(--syn-fn)  45%, transparent); }
  .badge[data-kind='Flow']   { color: var(--syn-ty);  border-color: color-mix(in srgb, var(--syn-ty)  45%, transparent); }
  .badge[data-kind='Screen'] { color: var(--syn-kw);  border-color: color-mix(in srgb, var(--syn-kw)  45%, transparent); }

  .badge[data-kind='Root']   .badge-dot { background: var(--syn-att); }
  .badge[data-kind='Tab']    .badge-dot { background: var(--syn-fn); }
  .badge[data-kind='Flow']   .badge-dot { background: var(--syn-ty); }
  .badge[data-kind='Screen'] .badge-dot { background: var(--syn-kw); }

  .panel-titles {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
    flex: 1;
  }

  .panel-title {
    font-family: var(--font-mono);
    font-size: 14.5px;
    font-weight: 500;
    color: var(--fg);
    letter-spacing: -0.01em;
    display: flex;
    align-items: center;
    gap: 0.4rem;
    /* Single-line — no wrap means the panel-head never grows in height
       between selections, even for the longest type names. */
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
  }

  .pinned-flag {
    font-size: 12px;
    line-height: 1;
    flex-shrink: 0;
  }

  .panel-sub {
    font-size: 12.5px;
    color: var(--muted);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
  }

  /* ── IDE (sidebar + code area) ────────────────────────────────────── */

  .ide {
    display: grid;
    grid-template-columns: 230px minmax(0, 1fr);
    /* Fixed height — no layout shift between hovered nodes regardless
       of how long each file's snippet is. The code area itself scrolls
       internally (via <pre>'s overflow) when content is taller. */
    height: clamp(420px, 56vh, 540px);
    border: 1px solid var(--code-line);
    border-radius: 6px;
    overflow: hidden;
    background: var(--code-bg);
  }

  /* Make the CodeBlock fill the IDE's right column and clip overflow
     to its own scrollable region. */
  .ide :global(.block) {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
  }
  .ide :global(.block > pre) {
    flex: 1;
    min-height: 0;
    overflow: auto;
  }

  /* Inside the IDE, the CodeBlock provides only the header bar + code —
     its outer border/radius/background are removed since the .ide owns
     them. */
  .ide :global(.block) {
    border: 0;
    border-radius: 0;
    background: transparent;
  }
  .ide :global(.bar) {
    border-radius: 0;
  }

  .files {
    display: flex;
    flex-direction: column;
    border-right: 1px solid var(--code-line);
    background: color-mix(in srgb, var(--code-bg) 88%, var(--fg) 12%);
  }

  .files-label {
    margin: 0;
    padding: 0.85rem 1rem 0.55rem;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: color-mix(in srgb, var(--code-fg) 45%, transparent);
  }

  .files-list {
    list-style: none;
    margin: 0;
    padding: 0 0 0.5rem;
    display: flex;
    flex-direction: column;
  }

  .files-list li {
    margin: 0;
  }

  .file {
    position: relative;
    display: flex;
    align-items: center;
    gap: 0.6rem;
    width: 100%;
    padding: 0.5rem 1rem 0.5rem 1.05rem;
    border: 0;
    background: transparent;
    color: color-mix(in srgb, var(--code-fg) 70%, transparent);
    font-family: var(--font-mono);
    font-size: 12.5px;
    text-align: left;
    cursor: pointer;
    transition: background-color 140ms ease, color 140ms ease;
  }

  .file:hover {
    background: color-mix(in srgb, var(--code-fg) 6%, transparent);
    color: var(--code-fg);
  }

  .file:focus-visible {
    outline: none;
    background: color-mix(in srgb, var(--code-fg) 8%, transparent);
    color: var(--code-fg);
    box-shadow: inset 2px 0 0 color-mix(in srgb, var(--code-fg) 60%, transparent);
  }

  .file.active {
    background: color-mix(in srgb, var(--code-fg) 10%, transparent);
    color: var(--code-fg);
  }

  .file.active::before {
    content: '';
    position: absolute;
    left: 0;
    top: 4px;
    bottom: 4px;
    width: 2px;
    border-radius: 2px;
    background: color-mix(in srgb, var(--code-fg) 70%, transparent);
  }

  .file-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--code-fg) 30%, transparent);
    flex-shrink: 0;
    transition: background-color 140ms ease;
  }

  .file[data-kind='Root']   .file-dot { background: var(--syn-att); }
  .file[data-kind='Tab']    .file-dot { background: var(--syn-fn); }
  .file[data-kind='Flow']   .file-dot { background: var(--syn-ty); }
  .file[data-kind='Screen'] .file-dot { background: var(--syn-kw); }

  .file-name {
    flex: 1;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .file-pin {
    font-size: 7px;
    color: var(--syn-kw);
    line-height: 1;
    flex-shrink: 0;
  }

  .code-area {
    min-width: 0;
    background: var(--code-bg);
    overflow: hidden;
  }

  /* Below ~720px, the sidebar collapses and the diagram becomes the
     primary navigation surface. */
  @media (max-width: 720px) {
    .ide {
      grid-template-columns: 1fr;
    }
    .files {
      display: none;
    }
  }
</style>
