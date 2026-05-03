<script>
  /**
   * A single do/don't / sub-flow / view-only style rule card. Renders inside
   * a `<RuleList>` (or any container — it's just a `<li>` with two columns).
   *
   * @prop tag   Pill label.
   * @prop tone  'bad' (red) | 'good' (green) | 'neutral' (default).
   */
  let { tag, tone = 'neutral', children } = $props();
</script>

<li class="rule" data-tone={tone}>
  <span class="rule-tag">{tag}</span>
  <span class="rule-body">{@render children()}</span>
</li>

<style>
  .rule {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: 1rem;
    align-items: start;
    padding: 0.85rem 1rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
  }

  /* Compact mode for do/don't pills (used in agents page). */
  :global(.rules:has(> [data-tone='bad'], > [data-tone='good'])) > .rule {
    grid-template-columns: 70px 1fr;
    gap: 0.85rem;
    align-items: center;
    padding: 0.6rem 0.85rem;
  }

  @media (max-width: 540px) {
    .rule {
      grid-template-columns: 1fr;
      gap: 0.45rem;
    }
  }

  .rule-tag {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--fg);
    padding: 0.18rem 0.5rem;
    border-radius: 999px;
    border: 1px solid color-mix(in srgb, var(--fg) 25%, transparent);
    background: color-mix(in srgb, var(--fg) 4%, transparent);
    justify-self: start;
    align-self: center;
    line-height: 1;
  }
  .rule[data-tone='bad'] .rule-tag {
    color: var(--syn-kw);
    border-color: currentColor;
    background: color-mix(in srgb, var(--syn-kw) 8%, transparent);
  }
  .rule[data-tone='good'] .rule-tag {
    color: var(--syn-ty);
    border-color: currentColor;
    background: color-mix(in srgb, var(--syn-ty) 8%, transparent);
  }

  .rule-body {
    font-size: 13.5px;
    line-height: 1.6;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .rule-body :global(code) {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }
  .rule-body :global(strong) { color: var(--fg); font-weight: 500; }
  .rule-body :global(em) { color: var(--fg); font-style: italic; }
</style>
