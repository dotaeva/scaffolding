<script>
  /**
   * Linkable "topic" card used in the Topics footer of /docs.
   *
   * @prop href     Destination — pass an internal `${base}/...` for in-site
   *                links or an absolute URL for external (e.g. DOCC_URL).
   * @prop external `true` opens in a new tab and adds rel=noopener.
   * @prop eyebrow  Small uppercase caption above the title.
   * @prop title    The card's headline (string).
   */
  let { href, external = false, eyebrow, title, children } = $props();
</script>

<a
  class="topic"
  {href}
  target={external ? '_blank' : undefined}
  rel={external ? 'noopener noreferrer' : undefined}
>
  {#if eyebrow}<span class="topic-eyebrow">{eyebrow}</span>{/if}
  <span class="topic-title">{title}</span>
  <span class="topic-desc">{@render children()}</span>
</a>

<style>
  .topic {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    padding: 1.1rem 1.2rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
    text-decoration: none;
    transition: border-color 140ms ease, background-color 140ms ease, transform 100ms ease;
  }
  .topic:hover {
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
    background: color-mix(in srgb, var(--fg) 4%, var(--bg));
  }
  .topic:active { transform: translateY(1px); }

  .topic-eyebrow {
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
  }
  .topic-title {
    font-family: var(--font-mono);
    font-size: 15px;
    font-weight: 500;
    color: var(--fg);
    letter-spacing: -0.01em;
  }
  .topic-desc {
    font-size: 12.5px;
    line-height: 1.55;
    color: color-mix(in srgb, var(--fg) 65%, transparent);
  }
  .topic-desc :global(code) {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }
</style>
