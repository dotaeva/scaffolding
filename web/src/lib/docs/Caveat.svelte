<script>
  /**
   * Side-by-side warning/note callout used across docs pages.
   *
   * @prop tag    The pill label (e.g. "Caveat", "Watch out", "Never").
   * @prop tone   'warn' (default — keyword red) or 'thesis' (type-name blue).
   */
  let { tag = 'Caveat', tone = 'warn', children } = $props();
</script>

<aside class="caveat" data-tone={tone} role="note">
  <span class="caveat-tag">{tag}</span>
  <div class="caveat-body">
    {@render children()}
  </div>
</aside>

<style>
  .caveat {
    display: grid;
    grid-template-columns: 90px 1fr;
    gap: 1rem;
    padding: 0.95rem 1.05rem;
    margin: 1rem 0 0.5rem;
    border: 1px solid color-mix(in srgb, var(--accent) 35%, transparent);
    border-radius: 6px;
    background: color-mix(in srgb, var(--accent) 5%, transparent);
    --accent: var(--syn-kw);
  }
  .caveat[data-tone='thesis'] { --accent: var(--syn-ty); }

  @media (max-width: 540px) {
    .caveat {
      grid-template-columns: 1fr;
      gap: 0.4rem;
    }
  }

  .caveat-tag {
    align-self: start;
    justify-self: start;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--accent);
    padding: 0.2rem 0.55rem;
    border-radius: 999px;
    border: 1px solid currentColor;
    background: color-mix(in srgb, var(--accent) 8%, transparent);
    line-height: 1;
    margin-top: 0.1rem;
  }

  .caveat-body :global(p) {
    margin: 0 0 0.55rem;
    font-size: 13.5px;
    line-height: 1.65;
    color: color-mix(in srgb, var(--fg) 80%, transparent);
  }
  .caveat-body :global(p:last-child) { margin-bottom: 0; }
  .caveat-body :global(p strong) { color: var(--fg); font-weight: 500; }
  .caveat-body :global(p em)     { color: var(--fg); font-style: italic; }
  .caveat-body :global(code) {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: color-mix(in srgb, var(--accent) 8%, transparent);
    border: 1px solid color-mix(in srgb, var(--accent) 25%, transparent);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }
</style>
