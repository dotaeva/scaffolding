<script>
  /**
   * Landing-page Playground. Two modes, swappable via the tab strip:
   *
   *   • Demo  — a working iPhone-shaped simulator wired to a fixed
   *             Scaffolding hierarchy (App / Tab / Home / Profile /
   *             modal). The action panel mirrors what's callable from
   *             the current coordinator at any given moment.
   *
   *   • Build — a live flow editor. The user composes their own
   *             FlowCoordinator from primitives (screens + actions);
   *             the phone re-renders their flow on every change.
   *
   * Both modes share the same top-level layout (header, sticky-phone
   * column, info column on the right) so switching tabs only changes
   * the contents of those columns, not the outer shape.
   */
  import { PlaygroundState } from '$lib/playground/state.svelte.js';
  import { BuilderState } from '$lib/playground/builder.svelte.js';
  import PhoneScreen from '$lib/playground/PhoneScreen.svelte';
  import StateReadout from '$lib/playground/StateReadout.svelte';
  import ActionPanel from '$lib/playground/ActionPanel.svelte';
  import Console from '$lib/playground/Console.svelte';
  import BuilderPhone from '$lib/playground/BuilderPhone.svelte';
  import BuilderPanel from '$lib/playground/BuilderPanel.svelte';

  let mode = $state('demo');                  // 'demo' | 'build'
  const demoState = new PlaygroundState();
  const buildState = new BuilderState();
</script>

<section class="play hold" id="play" aria-label="Scaffolding playground">
  <div class="play-inner">
    <header class="head">
      <span class="num">04 / Playground</span>
      <h2>See it in motion.</h2>
      <p class="note">
        The phone is a working prototype — tap rows, tabs, the gear, the back
        chevron. The action panel mirrors what's callable from the
        <em>current</em> coordinator: <strong>only valid Scaffolding functions
        appear at any given moment</strong>. Or switch to <strong>Build</strong>
        and assemble your own flow from primitives.
      </p>

      <div class="mode-tabs" role="tablist" aria-label="Playground mode">
        <button
          type="button"
          role="tab"
          aria-selected={mode === 'demo'}
          class:active={mode === 'demo'}
          onclick={() => (mode = 'demo')}
        >
          <span class="mode-name">Demo</span>
          <span class="mode-sub">canned scenario</span>
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={mode === 'build'}
          class:active={mode === 'build'}
          onclick={() => (mode = 'build')}
        >
          <span class="mode-name">Build</span>
          <span class="mode-sub">your own flow</span>
        </button>
      </div>
    </header>

    {#if mode === 'demo'}
      <div class="grid">
        <PhoneScreen state={demoState} />
        <div class="info-col">
          <StateReadout state={demoState} />
          <ActionPanel state={demoState} />
          <Console state={demoState} />
        </div>
      </div>
    {:else}
      <div class="grid">
        <BuilderPhone flow={buildState} />
        <div class="info-col">
          <BuilderPanel flow={buildState} />
          <Console state={buildState} />
        </div>
      </div>
    {/if}
  </div>
</section>

<style>
  .play {
    width: 100%;
    padding: clamp(3.5rem, 8vw, 6rem) 0;
  }

  .play-inner {
    max-width: 1280px;
    margin: 0 auto;
    padding: 0 clamp(1.25rem, 4vw, 3rem);
  }
  @media (min-width: 1340px) {
    .play-inner {
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
    text-transform: uppercase;
    color: var(--dim);
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
  .note em { font-style: italic; color: var(--fg); }
  .note strong { color: var(--fg); font-weight: 500; }

  /* ── Mode tabs (Demo / Build) ────────────────────────────────────── */

  .mode-tabs {
    display: inline-flex;
    margin-top: 0.4rem;
    border: 1px solid var(--line);
    border-radius: 8px;
    overflow: hidden;
    background: var(--bg);
    align-self: flex-start;
  }

  .mode-tabs button {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 0.15rem;
    padding: 0.55rem 1rem;
    background: transparent;
    border: 0;
    border-right: 1px solid var(--line);
    font: inherit;
    cursor: pointer;
    color: var(--muted);
    transition: color 140ms ease, background-color 140ms ease;
    text-align: left;
    min-width: 0;
  }
  .mode-tabs button:last-child { border-right: 0; }

  .mode-tabs button:hover {
    color: var(--fg);
    background: color-mix(in srgb, var(--fg) 4%, transparent);
  }
  .mode-tabs button.active {
    color: var(--fg);
    background: color-mix(in srgb, var(--fg) 7%, transparent);
  }
  .mode-tabs button:focus-visible {
    outline: none;
    box-shadow: inset 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }

  .mode-name {
    font-family: var(--font-mono);
    font-size: 13px;
    font-weight: 500;
    letter-spacing: -0.01em;
  }
  .mode-sub {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.08em;
    color: var(--dim);
  }
  .mode-tabs button.active .mode-sub { color: var(--muted); }

  /* ── Two-column grid (phone-col + info-col) ──────────────────────── */

  .grid {
    display: grid;
    grid-template-columns: minmax(0, auto) minmax(360px, 1fr);
    gap: clamp(2rem, 4vw, 3rem);
    align-items: start;
  }
  @media (max-width: 1024px) {
    .grid {
      grid-template-columns: 1fr;
      justify-items: center;
    }
    .info-col {
      width: 100%;
    }
  }

  .info-col {
    display: flex;
    flex-direction: column;
    gap: 1.4rem;
  }
</style>
