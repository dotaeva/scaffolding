<script>
  /**
   * Action buttons + Reset, driven by `state.actionGroups` (a $derived
   * that computes which Scaffolding calls are valid in the current
   * coordinator context — only those buttons render).
   *
   * @prop state PlaygroundState.
   */
  import { fade } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';

  let { state } = $props();
</script>

<section class="actions" aria-label="Available actions">
  <div class="actions-head">
    <h3>Available actions</h3>
    <button type="button" class="reset" onclick={state.reset}>↻ Reset</button>
  </div>

  <div class="action-groups">
    {#each state.actionGroups as group (group.label)}
      <div
        class="group"
        in:fade={{ duration: 180, easing: cubicOut }}
        out:fade={{ duration: 120 }}
      >
        <span class="group-label">{group.label}</span>
        {#each group.items as item (item.code)}
          <button
            type="button"
            class="action"
            class:accent={item.accent}
            onclick={item.fn}
          >
            <code>{item.code}</code>
            {#if item.hint}
              <span class="action-hint">{item.hint}</span>
            {/if}
          </button>
        {/each}
      </div>
    {/each}
  </div>
</section>

<style>
  .actions {
    border: 1px solid var(--line);
    border-radius: 8px;
    background: var(--surface);
    padding: 1.1rem 1.1rem 1.2rem;
  }

  .actions h3 {
    margin: 0 0 0.7rem;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
  }

  .actions-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .reset {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.04em;
    color: var(--muted);
    background: transparent;
    border: 1px solid var(--line);
    border-radius: 999px;
    padding: 0.25rem 0.65rem;
    cursor: pointer;
    transition: color 140ms ease, border-color 140ms ease, background-color 140ms ease;
  }
  .reset:hover {
    color: var(--fg);
    border-color: color-mix(in srgb, var(--fg) 30%, transparent);
    background: color-mix(in srgb, var(--fg) 5%, transparent);
  }

  .action-groups {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 1rem;
  }

  .group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }

  .group-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--dim);
    padding-bottom: 0.1rem;
  }

  .action {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
    text-align: left;
    border: 1px solid var(--line);
    background: var(--bg);
    color: var(--fg);
    padding: 0.55rem 0.7rem;
    border-radius: 6px;
    cursor: pointer;
    font-family: var(--font-mono);
    font-size: 12px;
    line-height: 1.3;
    transition:
      border-color 140ms ease,
      background-color 140ms ease,
      transform 100ms ease;
  }

  .action code { color: var(--fg); }

  .action:hover {
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
    background: color-mix(in srgb, var(--fg) 4%, var(--bg));
  }

  .action:active { transform: translateY(1px); }

  .action:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }

  .action.accent {
    border-color: color-mix(in srgb, var(--syn-kw) 60%, transparent);
  }
  .action.accent code {
    color: var(--syn-kw);
  }
  .action.accent:hover {
    background: color-mix(in srgb, var(--syn-kw) 7%, var(--bg));
  }

  .action-hint {
    margin-top: 0.15rem;
    padding-top: 0.4rem;
    border-top: 1px dashed color-mix(in srgb, var(--fg) 14%, transparent);
    font-family: var(--font-sans);
    font-size: 11px;
    line-height: 1.5;
    color: color-mix(in srgb, var(--fg) 62%, transparent);
  }
</style>
