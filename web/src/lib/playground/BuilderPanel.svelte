<script>
  /**
   * Sidebar editor for the Build tab. Renders the list of user-defined
   * screens and, beneath each, the actions configured on it. The user
   * can:
   *   • add / rename / remove screens
   *   • mark any screen as the flow's root
   *   • add an action (push / sheet / cover / pop / dismiss) with a
   *     target screen for routing-flavoured kinds
   *   • remove actions
   *
   * @prop flow BuilderState — the same instance the phone preview
   *            reads, so edits propagate live. Renamed from `state` so
   *            the local `$state` rune isn't shadowed.
   */
  import { ACTION_KINDS } from '$lib/playground/builder.svelte.js';

  let { flow } = $props();

  // Per-screen "pending action" — the user picks a kind and (for the
  // routing kinds) a target before clicking "Add".
  let pendingKind = $state({});      // { [screenId]: 'push' | … }
  let pendingTarget = $state({});    // { [screenId]: targetScreenId }

  function defaultTarget(screenId) {
    // First screen that isn't this one.
    return flow.screens.find((s) => s.id !== screenId)?.id ?? null;
  }

  function addAction(screenId) {
    const kind = pendingKind[screenId] ?? 'push';
    const needsTarget = kind === 'push' || kind === 'sheet' || kind === 'cover';
    const target = needsTarget ? (pendingTarget[screenId] ?? defaultTarget(screenId)) : null;
    if (needsTarget && !target) return;
    flow.addAction(screenId, kind, target);
    // Reset pending so the next add starts cleanly.
    pendingKind = { ...pendingKind, [screenId]: undefined };
    pendingTarget = { ...pendingTarget, [screenId]: undefined };
  }
</script>

<section class="builder" aria-label="Flow builder">
  <header class="builder-head">
    <h3>Build your flow</h3>
    <button type="button" class="reset" onclick={flow.resetBuilder}>↻ Reset</button>
  </header>

  <p class="hint">
    Each screen below becomes a <code>func</code> on the coordinator.
    Add actions and they render as live buttons on the phone preview —
    so you're driving a flow you assembled yourself.
  </p>

  <ul class="screens">
    {#each flow.screens as screen (screen.id)}
      <li class="screen" class:is-root={screen.id === flow.rootScreenId}>
        <header class="screen-head">
          <input
            class="name-input"
            type="text"
            value={screen.name}
            oninput={(e) => flow.renameScreen(screen.id, e.currentTarget.value.trim())}
            aria-label="Screen name"
            spellcheck="false"
          />
          <div class="screen-tools">
            {#if screen.id === flow.rootScreenId}
              <span class="root-pill" title="Root of the FlowStack">root</span>
            {:else}
              <button
                type="button"
                class="tool"
                onclick={() => flow.setRootScreen(screen.id)}
                title="Make this the root of the flow"
              >set root</button>
              <button
                type="button"
                class="tool danger"
                onclick={() => flow.removeScreen(screen.id)}
                title="Delete this screen"
              >×</button>
            {/if}
          </div>
        </header>

        {#if screen.actions.length > 0}
          <ul class="actions">
            {#each screen.actions as action (action.id)}
              <li class="action" data-kind={action.kind}>
                <span class="action-kind">{labelFor(action.kind)}</span>
                {#if needsTarget(action.kind)}
                  <select
                    class="target-select"
                    value={action.target ?? ''}
                    onchange={(e) => flow.setActionTarget(screen.id, action.id, e.currentTarget.value)}
                    aria-label="Action target"
                  >
                    {#each flow.screens.filter((s) => s.id !== screen.id) as t (t.id)}
                      <option value={t.id}>{t.name}</option>
                    {/each}
                  </select>
                {/if}
                <button
                  type="button"
                  class="action-remove"
                  onclick={() => flow.removeAction(screen.id, action.id)}
                  aria-label="Remove action"
                >×</button>
              </li>
            {/each}
          </ul>
        {/if}

        <div class="add-action">
          <select
            class="kind-select"
            value={pendingKind[screen.id] ?? 'push'}
            onchange={(e) => (pendingKind = { ...pendingKind, [screen.id]: e.currentTarget.value })}
            aria-label="New action kind"
          >
            {#each ACTION_KINDS as k (k.value)}
              <option value={k.value}>{k.label}</option>
            {/each}
          </select>
          {#if needsTarget(pendingKind[screen.id] ?? 'push')}
            <select
              class="target-select"
              value={pendingTarget[screen.id] ?? defaultTarget(screen.id) ?? ''}
              onchange={(e) => (pendingTarget = { ...pendingTarget, [screen.id]: e.currentTarget.value })}
              aria-label="New action target"
            >
              {#each flow.screens.filter((s) => s.id !== screen.id) as t (t.id)}
                <option value={t.id}>{t.name}</option>
              {/each}
            </select>
          {/if}
          <button
            type="button"
            class="add-btn"
            onclick={() => addAction(screen.id)}
            disabled={flow.screens.length < 2 && needsTarget(pendingKind[screen.id] ?? 'push')}
          >+ action</button>
        </div>
      </li>
    {/each}
  </ul>

  <button type="button" class="add-screen" onclick={flow.addScreen}>+ add screen</button>
</section>

<script module>
  // Module-scope helpers — pure, no state dependency.
  /** Whether an action kind needs a target screen. */
  export function needsTarget(kind) {
    return kind === 'push' || kind === 'sheet' || kind === 'cover';
  }

  /** Short label rendered on each action chip. */
  export function labelFor(kind) {
    if (kind === 'push')    return 'route(to:)';
    if (kind === 'sheet')   return 'present .sheet';
    if (kind === 'cover')   return 'present .cover';
    if (kind === 'pop')     return 'pop()';
    if (kind === 'dismiss') return 'dismissCoordinator()';
    return kind;
  }
</script>

<style>
  .builder {
    border: 1px solid var(--line);
    border-radius: 8px;
    background: var(--surface);
    padding: 1rem 1.1rem 1.2rem;
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
  }

  .builder-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  .builder-head h3 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
  }

  .reset {
    font-family: var(--font-mono);
    font-size: 11px;
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

  .hint {
    margin: 0;
    font-size: 12.5px;
    line-height: 1.55;
    color: color-mix(in srgb, var(--fg) 65%, transparent);
  }
  .hint code {
    font-family: var(--font-mono);
    font-size: 0.9em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

  /* ── Screens list ────────────────────────────────────────────────── */

  .screens {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.55rem;
  }

  .screen {
    border: 1px solid var(--line);
    border-radius: 6px;
    padding: 0.55rem 0.7rem 0.65rem;
    background: var(--bg);
    display: flex;
    flex-direction: column;
    gap: 0.45rem;
  }
  .screen.is-root {
    border-color: color-mix(in srgb, var(--syn-ty) 40%, transparent);
    background: color-mix(in srgb, var(--syn-ty) 4%, var(--bg));
  }

  .screen-head {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .name-input {
    flex: 1;
    min-width: 0;
    font: inherit;
    font-family: var(--font-mono);
    font-size: 13px;
    color: var(--fg);
    background: transparent;
    border: 0;
    border-bottom: 1px solid color-mix(in srgb, var(--fg) 14%, transparent);
    padding: 0.15rem 0.05rem;
    transition: border-color 140ms ease;
  }
  .name-input:focus-visible {
    outline: none;
    border-bottom-color: color-mix(in srgb, var(--fg) 50%, transparent);
  }

  .screen-tools {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
  }
  .root-pill {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--syn-ty);
    border: 1px solid currentColor;
    background: color-mix(in srgb, var(--syn-ty) 8%, transparent);
    padding: 0.15rem 0.4rem;
    border-radius: 999px;
    line-height: 1;
  }
  .tool {
    font: inherit;
    font-family: var(--font-mono);
    font-size: 10.5px;
    color: var(--muted);
    background: transparent;
    border: 1px solid var(--line);
    border-radius: 4px;
    padding: 0.18rem 0.45rem;
    cursor: pointer;
    transition: color 140ms ease, border-color 140ms ease;
  }
  .tool:hover {
    color: var(--fg);
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
  }
  .tool.danger:hover {
    color: var(--syn-kw);
    border-color: var(--syn-kw);
  }

  /* ── Actions ───────────────────────────────────────────────────── */

  .actions {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-wrap: wrap;
    gap: 0.3rem;
  }
  .action {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line);
    border-radius: 4px;
    padding: 0.18rem 0.4rem;
  }
  .action[data-kind='push']     { color: var(--syn-att); border-color: color-mix(in srgb, currentColor 40%, transparent); }
  .action[data-kind='sheet']    { color: var(--syn-mem); border-color: color-mix(in srgb, currentColor 40%, transparent); }
  .action[data-kind='cover']    { color: var(--syn-fn);  border-color: color-mix(in srgb, currentColor 40%, transparent); }
  .action[data-kind='pop']      { color: var(--muted); }
  .action[data-kind='dismiss']  { color: var(--syn-kw); border-color: color-mix(in srgb, currentColor 40%, transparent); }

  .action-kind { line-height: 1; }
  .action .target-select {
    font: inherit;
    font-family: var(--font-mono);
    font-size: 11px;
    color: inherit;
    background: var(--bg);
    border: 1px solid var(--line);
    border-radius: 3px;
    padding: 0.05rem 0.2rem;
  }
  .action-remove {
    font: inherit;
    font-size: 11px;
    color: var(--dim);
    background: transparent;
    border: 0;
    cursor: pointer;
    line-height: 1;
    padding: 0 0.2rem;
  }
  .action-remove:hover { color: var(--syn-kw); }

  /* ── Add-action row ──────────────────────────────────────────────── */

  .add-action {
    display: flex;
    flex-wrap: wrap;
    gap: 0.3rem;
    align-items: center;
  }
  .kind-select,
  .add-action .target-select {
    font: inherit;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--fg);
    background: var(--bg);
    border: 1px solid var(--line);
    border-radius: 4px;
    padding: 0.2rem 0.35rem;
  }
  .add-btn {
    font: inherit;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--fg);
    background: transparent;
    border: 1px dashed color-mix(in srgb, var(--fg) 30%, transparent);
    border-radius: 4px;
    padding: 0.2rem 0.55rem;
    cursor: pointer;
    transition: border-color 140ms ease, background-color 140ms ease;
  }
  .add-btn:hover:not(:disabled) {
    border-color: var(--fg);
    background: color-mix(in srgb, var(--fg) 4%, transparent);
  }
  .add-btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
  }

  .add-screen {
    align-self: flex-start;
    font: inherit;
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--fg);
    background: transparent;
    border: 1px dashed color-mix(in srgb, var(--fg) 35%, transparent);
    border-radius: 6px;
    padding: 0.4rem 0.85rem;
    cursor: pointer;
    transition: border-color 140ms ease, background-color 140ms ease;
  }
  .add-screen:hover {
    border-color: var(--fg);
    background: color-mix(in srgb, var(--fg) 4%, transparent);
  }
</style>
