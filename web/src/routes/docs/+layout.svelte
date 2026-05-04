<script>
  import { base } from '$app/paths';
  import { page } from '$app/state';
  import '$lib/styles/docs.css';

  let { children } = $props();

  const PAGES = [
    { id: '/docs',           href: '/docs',           label: 'Meet Scaffolding' },
    { id: '/docs/api',       href: '/docs/api',       label: 'API Reference' },
    { id: '/docs/tutorial',  href: '/docs/tutorial',  label: 'Tutorial' },
    { id: '/docs/agents',    href: '/docs/agents',    label: 'Agent guide' },
    { id: '/docs/changelog', href: '/docs/changelog', label: 'Changelog' }
  ];
</script>

<nav class="docs-tabs" aria-label="Documentation pages">
  <div class="docs-tabs-inner">
    {#each PAGES as p}
      <a
        href={`${base}${p.href}`}
        class="tab"
        class:active={page.route?.id === p.id}
        aria-current={page.route?.id === p.id ? 'page' : undefined}
      >
        {p.label}
      </a>
    {/each}
  </div>
</nav>

{@render children()}

<style>
  .docs-tabs {
    position: relative;
    z-index: 1;
    border-bottom: 1px solid var(--line-soft);
    background: var(--header-bg);
  }

  .docs-tabs-inner {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 clamp(1.25rem, 4vw, 3rem);
    display: flex;
    gap: 0.25rem;
    overflow-x: auto;
    scrollbar-width: none;
  }
  .docs-tabs-inner::-webkit-scrollbar { display: none; }

  .tab {
    flex-shrink: 0;
    padding: 0.85rem 0.95rem;
    font-family: var(--font-mono);
    font-size: 12.5px;
    color: var(--muted);
    text-decoration: none;
    border-bottom: 2px solid transparent;
    margin-bottom: -1px; /* overlap the bottom border for active state */
    transition: color 140ms ease, border-color 140ms ease;
  }

  .tab:hover {
    color: var(--fg);
  }

  .tab.active {
    color: var(--fg);
    border-bottom-color: var(--fg);
  }
</style>
