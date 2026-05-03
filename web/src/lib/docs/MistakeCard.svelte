<script>
  /**
   * Numbered "common mistake" card used on /docs/agents.
   *
   * @prop num   Two-digit string ('01', '02', …). Rendered in mono.
   * @prop title The short headline for the mistake — accepts inline HTML
   *             through the `title` snippet (passed as a child snippet,
   *             see usage below).
   *
   * Usage:
   *
   *     <MistakeCard num="04">
   *       {#snippet title()}
   *         <code>route(to:as:)</code> (old API)
   *       {/snippet}
   *
   *       <p>That API was split.</p>
   *       <CodeBlock code={...} />
   *     </MistakeCard>
   */
  let { num, title, children } = $props();
</script>

<div class="mistake">
  <header class="mistake-head">
    <span class="mistake-num">{num}</span>
    <h3>{@render title()}</h3>
  </header>
  {@render children()}
</div>

<style>
  .mistake {
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
    padding: 1rem 1.1rem 1.1rem;
    margin: 0.6rem 0 1rem;
  }
  .mistake-head {
    display: flex;
    align-items: baseline;
    gap: 0.85rem;
    margin: 0 0 0.5rem;
  }
  .mistake-num {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.16em;
    color: var(--syn-kw);
    flex-shrink: 0;
  }
  .mistake-head h3 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: 13.5px;
    font-weight: 500;
    color: var(--fg);
    line-height: 1.45;
    text-transform: none;
    letter-spacing: -0.005em;
  }
  .mistake-head :global(code) {
    font-family: var(--font-mono);
    font-size: 0.95em;
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.4em;
    border-radius: 3px;
  }

  /* Body styling for the children — prose + a sub note. */
  .mistake :global(p) {
    font-size: 13.5px;
  }
  .mistake :global(p.sub) {
    margin: 0.5rem 0 0;
    color: color-mix(in srgb, var(--fg) 60%, transparent);
    font-size: 13px;
    line-height: 1.6;
    border-left: 2px solid var(--line);
    padding-left: 0.85rem;
  }
</style>
