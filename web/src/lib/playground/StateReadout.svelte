<script>
  /**
   * Mirrors the playground's coordinator state in a code-style read-out:
   * `root`, the active tab and its pretty-printed stack, the current
   * modal (or `nil`), and the @Environment chain (leaf → root).
   *
   * @prop state PlaygroundState.
   */
  import { stackPretty } from '$lib/playground/state.svelte.js';

  let { state } = $props();
</script>

<section class="state" aria-label="Coordinator state">
  <h3>State</h3>
  <div class="state-grid">
    <span class="k">root</span>
    <span class="v">
      <code>.{state.phase === 'main' ? 'authenticated' : 'unauthenticated'}</code>
    </span>

    {#if state.phase === 'main'}
      <span class="k">tab.selected</span>
      <span class="v"><code>.{state.tab}</code></span>

      <span class="k">{state.tab}.stack</span>
      <span class="v"><code>[{stackPretty(state.currentStack)}]</code></span>
    {/if}

    <span class="k">modal</span>
    <span class="v">
      <code>
        {state.modal
          ? `.${state.modal.screen} (${state.modal.pushType === 'cover' ? 'fullScreenCover' : 'sheet'})`
          : 'nil'}
      </code>
    </span>

    <span class="k">@Environment</span>
    <span class="v env">
      {#each state.injectedChain as coord, i (coord)}
        <code class="env-line">
          {#if i > 0}
            <span class="env-arrow" aria-hidden="true">↑</span>
          {/if}
          {coord}
        </code>
      {/each}
    </span>
  </div>
</section>

<style>
  .state {
    border: 1px solid var(--code-line);
    border-radius: 8px;
    background: var(--code-bg);
    padding: 1rem 1.1rem;
  }

  .state h3 {
    margin: 0 0 0.7rem;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: color-mix(in srgb, var(--code-fg) 50%, transparent);
  }

  .state-grid {
    display: grid;
    grid-template-columns: max-content 1fr;
    gap: 0.45rem 1rem;
    /* `start` (not baseline) so multi-line @Environment values don't
       drag the key label off the first line. */
    align-items: start;
    font-family: var(--font-mono);
    font-size: 12.5px;
    color: var(--code-fg);
  }

  .state-grid .k {
    color: color-mix(in srgb, var(--code-fg) 55%, transparent);
    line-height: 1.45;
  }

  .state-grid .v {
    line-height: 1.45;
  }

  .state-grid .v code {
    color: var(--syn-ty);
  }

  /* @Environment chain — one coordinator per line with a leading ↑. */
  .v.env {
    display: flex;
    flex-direction: column;
    gap: 1px;
  }

  .env-line {
    display: inline-flex;
    align-items: baseline;
    gap: 0.4rem;
  }

  .env-arrow {
    color: color-mix(in srgb, var(--code-fg) 40%, transparent);
    font-family: var(--font-mono);
  }
</style>
