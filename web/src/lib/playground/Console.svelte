<script>
  /**
   * Call log for the playground. Each entry is one of:
   *   { kind: 'call', text, caller }   ← a real Scaffolding call
   *   { kind: 'note', text, caller }   ← a no-op (e.g. pop on root)
   *
   * Entries fly in from the bottom and the list keeps the most recent 8.
   *
   * @prop state PlaygroundState — accessed read-only via `.log`.
   */
  import { fly } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';

  let { state } = $props();
</script>

<section class="console" aria-label="Console">
  <h3>Console</h3>
  <ol class="log">
    {#if state.log.length === 0}
      <li class="empty"><code>// Tap something on the phone or press an action.</code></li>
    {/if}
    {#each state.log as entry (entry.id)}
      <li
        class="entry"
        class:note={entry.kind === 'note'}
        in:fly={{ y: 6, duration: 200, easing: cubicOut }}
      >
        <span class="prompt" aria-hidden="true">›</span>
        <code class="call-text">coordinator.{entry.text}</code>
        {#if entry.caller}
          <code class="caller">// {entry.caller}</code>
        {/if}
      </li>
    {/each}
  </ol>
</section>

<style>
  .console {
    border: 1px solid var(--code-line);
    border-radius: 8px;
    background: var(--code-bg);
    padding: 1rem 1.1rem 1.1rem;
  }

  .console h3 {
    margin: 0 0 0.7rem;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: color-mix(in srgb, var(--code-fg) 50%, transparent);
  }

  .log {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    font-family: var(--font-mono);
    font-size: 12.5px;
    color: var(--code-fg);
    max-height: 220px;
    overflow-y: auto;
  }

  .log .empty {
    color: color-mix(in srgb, var(--code-fg) 38%, transparent);
    font-style: italic;
  }

  .entry {
    display: flex;
    align-items: baseline;
    gap: 0.55rem;
    flex-wrap: wrap;
  }

  .entry.note .call-text {
    color: color-mix(in srgb, var(--code-fg) 55%, transparent);
  }

  .prompt {
    color: color-mix(in srgb, var(--code-fg) 45%, transparent);
    flex-shrink: 0;
  }

  .entry .call-text {
    color: var(--code-fg);
    word-break: break-word;
  }

  /* Trailing `// CoordinatorName` comment on each entry — the Swift side
     calls `pop()` etc. on a specific coordinator instance, and this
     comment makes that explicit in the console. */
  .caller {
    color: color-mix(in srgb, var(--code-fg) 50%, transparent);
    font-style: italic;
  }

  .entry.note .caller {
    color: color-mix(in srgb, var(--code-fg) 38%, transparent);
  }
</style>
