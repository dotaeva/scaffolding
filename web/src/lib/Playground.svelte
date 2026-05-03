<script>
  /**
   * Landing-page Playground — a working iPhone-shaped simulator paired
   * with a state read-out, an action panel, and a console. The four
   * sub-components share a single `PlaygroundState` instance so the
   * phone taps and the action panel mutate exactly the same state, and
   * the read-out / console reflect both transparently.
   */
  import { PlaygroundState } from '$lib/playground/state.svelte.js';
  import PhoneScreen from '$lib/playground/PhoneScreen.svelte';
  import StateReadout from '$lib/playground/StateReadout.svelte';
  import ActionPanel from '$lib/playground/ActionPanel.svelte';
  import Console from '$lib/playground/Console.svelte';

  const state = new PlaygroundState();
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
        appear at any given moment</strong>.
      </p>
    </header>

    <div class="grid">
      <PhoneScreen {state} />
      <div class="info-col">
        <StateReadout {state} />
        <ActionPanel {state} />
        <Console {state} />
      </div>
    </div>
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

  /* Cap the inner container so its right edge clears the
     ScrollProgress rail (~210 px) when the rail shows its full
     labels at ≥ 1340 viewport. */
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

  .grid {
    display: grid;
    /* Phone column auto-sizes to whatever the phone needs (capped by
       both viewport width and viewport height — see PhoneScreen.svelte's
       .phone rule). The right column flexes to fill the remainder. */
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
