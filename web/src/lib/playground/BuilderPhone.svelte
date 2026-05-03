<script>
  /**
   * Live phone preview for the Build tab. Renders the user's flow as
   * configured in the BuilderPanel — each screen draws a stack of
   * buttons (one per declared action) and the simulator routes / pops /
   * dismisses according to the action's kind. Reuses the same iPhone
   * chrome shape as the demo's PhoneScreen so the two tabs feel
   * consistent.
   *
   * @prop flow BuilderState (renamed from `state` to match BuilderPanel
   *            and avoid shadowing the `$state` rune in either file).
   */
  import { fly, fade } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';

  let { flow } = $props();

  /** Short Swift-call label rendered on each in-phone action button. */
  function actionLabel(action, screens) {
    if (action.kind === 'pop')      return 'pop()';
    if (action.kind === 'dismiss')  return 'dismissCoordinator()';
    const target = screens.find((s) => s.id === action.target);
    const name = target?.name ?? '?';
    if (action.kind === 'push')   return `route(to: .${name})`;
    if (action.kind === 'sheet')  return `present(.${name}, as: .sheet)`;
    if (action.kind === 'cover')  return `present(.${name}, as: .fullScreenCover)`;
    return action.kind;
  }
</script>

<div class="phone-col">
  <div class="phone">
    <div class="phone-frame">
      <span class="notch"></span>
      <div class="screen-area">
        <div class="layer">
          <div class="status-bar">
            <span>9:41</span>
            <span class="bars">●●●</span>
          </div>
          <div class="content">
            <div class="stack-region">
              {#each flow.pushedInstances as inst, i (inst.id)}
                {@const screen = flow.screenFor(inst)}
                <div
                  class="screen"
                  style="z-index: {i + 1};"
                  in:fly={{ x: 320, duration: 320, easing: cubicOut }}
                  out:fly={{ x: 320, duration: 240, easing: cubicOut }}
                >
                  <div class="screen-content">
                    <header class="screen-top">
                      {#if i > 0}
                        <button
                          type="button"
                          class="back"
                          onclick={() => flow.invokeAction({ kind: 'pop' })}
                        >‹ Back</button>
                      {/if}
                      <h4>{screen?.name ?? '?'}</h4>
                    </header>

                    {#if screen}
                      {#if screen.actions.length === 0}
                        <p class="hint">No actions yet — add some in the panel.</p>
                      {:else}
                        <ul class="actions">
                          {#each screen.actions as action (action.id)}
                            <li>
                              <button
                                type="button"
                                class="row"
                                data-kind={action.kind}
                                onclick={() => flow.invokeAction(action)}
                              >
                                <code>{actionLabel(action, flow.screens)}</code>
                              </button>
                            </li>
                          {/each}
                        </ul>
                      {/if}
                    {/if}
                  </div>
                </div>
              {/each}
            </div>
          </div>
        </div>

        {#if flow.modalInstance}
          {@const modalScreen = flow.screenFor(flow.modalInstance)}
          {#if flow.modalInstance.pushType === 'sheet'}
            <button
              type="button"
              class="backdrop"
              aria-label="Dismiss sheet"
              onclick={() => flow.invokeAction({ kind: 'dismiss' })}
              in:fade={{ duration: 220 }}
              out:fade={{ duration: 180 }}
            ></button>
          {/if}
          <div
            class="modal {flow.modalInstance.pushType}"
            in:fly={{ y: 700, duration: 360, easing: cubicOut }}
            out:fly={{ y: 700, duration: 260, easing: cubicOut }}
          >
            {#if flow.modalInstance.pushType === 'sheet'}
              <span class="grabber" aria-hidden="true"></span>
            {/if}
            <div class="screen-content">
              <header class="screen-top">
                <h4>{modalScreen?.name ?? '?'}</h4>
                <button
                  type="button"
                  class="text-btn"
                  onclick={() => flow.invokeAction({ kind: 'dismiss' })}
                >Done</button>
              </header>
              {#if modalScreen}
                {#if modalScreen.actions.length === 0}
                  <p class="hint">No actions yet — add some in the panel.</p>
                {:else}
                  <ul class="actions">
                    {#each modalScreen.actions as action (action.id)}
                      <li>
                        <button
                          type="button"
                          class="row"
                          data-kind={action.kind}
                          onclick={() => flow.invokeAction(action)}
                        >
                          <code>{actionLabel(action, flow.screens)}</code>
                        </button>
                      </li>
                    {/each}
                  </ul>
                {/if}
              {/if}
            </div>
          </div>
        {/if}

        <div class="home-indicator" aria-hidden="true"></div>
      </div>
    </div>
  </div>

  <p class="caption">
    Tap an action to drive the flow. The buttons mirror what your screen
    would show at runtime — each <code>route(to:)</code> pushes, each
    <code>present(_:as:)</code> opens a modal, and so on.
  </p>
</div>

<style>
  .phone-col {
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
    align-items: center;
    position: sticky;
    top: 5.5rem;
  }
  @media (max-width: 980px) {
    .phone-col { position: static; }
  }

  .phone {
    width: min(clamp(240px, 26vw, 360px), calc(75svh * 9 / 18.5));
    aspect-ratio: 9 / 18.5;
  }
  @supports not (height: 1svh) {
    .phone {
      width: min(clamp(240px, 26vw, 360px), calc(75vh * 9 / 18.5));
    }
  }

  .phone-frame {
    position: relative;
    width: 100%;
    height: 100%;
    padding: 8px;
    border-radius: 38px;
    border: 1px solid color-mix(in srgb, var(--fg) 28%, transparent);
    background: color-mix(in srgb, var(--fg) 12%, var(--bg));
    box-shadow:
      0 0 0 1px color-mix(in srgb, var(--fg) 6%, transparent) inset,
      0 24px 50px -22px color-mix(in srgb, var(--fg) 35%, transparent);
  }

  .notch {
    position: absolute;
    top: 18px;
    left: 50%;
    transform: translateX(-50%);
    width: 96px;
    height: 26px;
    background: #000;
    border-radius: 999px;
    z-index: 50;
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.04);
  }

  .screen-area {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
    border-radius: 30px;
    background: var(--bg);
    color: var(--fg);
    isolation: isolate;
  }

  .layer {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
  }

  .status-bar {
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 22px 8px;
    font-size: 11px;
    letter-spacing: 0.04em;
    color: color-mix(in srgb, var(--fg) 75%, transparent);
  }
  .bars { font-size: 8px; letter-spacing: 0.15em; opacity: 0.7; }

  .content {
    position: relative;
    flex: 1;
    min-height: 0;
    overflow: hidden;
  }

  .stack-region { position: absolute; inset: 0; }

  .screen {
    position: absolute;
    inset: 0;
    background: var(--bg);
    overflow: hidden;
    will-change: transform, opacity;
  }

  .screen-content {
    padding: 16px 18px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    height: 100%;
  }

  .screen-top {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  .screen-top h4 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: 17px;
    font-weight: 600;
    color: var(--fg);
  }

  .back {
    align-self: flex-start;
    font: inherit;
    font-size: 12.5px;
    color: color-mix(in srgb, var(--fg) 75%, transparent);
    background: transparent;
    border: 0;
    padding: 0.2rem 0.4rem 0.2rem 0;
    cursor: pointer;
    border-radius: 4px;
  }
  .back:hover { color: var(--fg); }
  .back:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
    color: var(--fg);
  }

  .text-btn {
    font: inherit;
    font-size: 13px;
    color: var(--fg);
    background: transparent;
    border: 0;
    padding: 0.2rem 0.4rem;
    cursor: pointer;
    border-radius: 4px;
    transition: background-color 140ms ease;
    margin-left: auto;
  }
  .text-btn:hover { background: color-mix(in srgb, var(--fg) 8%, transparent); }

  .hint {
    margin: 0.5rem 0 0;
    font-size: 11.5px;
    color: color-mix(in srgb, var(--fg) 50%, transparent);
    line-height: 1.5;
  }

  .actions {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .row {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    width: 100%;
    padding: 9px 11px;
    border-radius: 6px;
    background: color-mix(in srgb, var(--fg) 5%, transparent);
    border: 1px solid color-mix(in srgb, var(--fg) 8%, transparent);
    color: inherit;
    font: inherit;
    cursor: pointer;
    transition: background-color 140ms ease, border-color 140ms ease, transform 80ms ease;
  }
  .row:hover {
    background: color-mix(in srgb, var(--fg) 10%, transparent);
    border-color: color-mix(in srgb, var(--fg) 22%, transparent);
  }
  .row:active { transform: translateY(0.5px); }
  .row:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }
  .row code {
    font-family: var(--font-mono);
    font-size: 11.5px;
    color: var(--fg);
  }
  .row[data-kind='push']     code { color: var(--syn-att); }
  .row[data-kind='sheet']    code { color: var(--syn-mem); }
  .row[data-kind='cover']    code { color: var(--syn-fn); }
  .row[data-kind='dismiss']  code { color: var(--syn-kw); }

  /* ── Modal & backdrop ─────────────────────────────────────────────── */

  .backdrop {
    position: absolute;
    inset: 0;
    background: color-mix(in srgb, #000 35%, transparent);
    z-index: 100;
    will-change: opacity;
    border: 0;
    padding: 0;
    cursor: pointer;
  }

  .modal {
    position: absolute;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 110;
    background: var(--bg);
    will-change: transform, opacity;
    border-radius: 18px 18px 0 0;
    overflow: hidden;
  }
  .modal.sheet { top: 56px; }
  .modal.cover { top: 0; border-radius: 0; }

  .grabber {
    position: absolute;
    top: 8px;
    left: 50%;
    transform: translateX(-50%);
    width: 36px;
    height: 4px;
    border-radius: 999px;
    background: color-mix(in srgb, var(--fg) 25%, transparent);
  }

  .home-indicator {
    position: absolute;
    bottom: 6px;
    left: 50%;
    transform: translateX(-50%);
    width: 110px;
    height: 4px;
    border-radius: 999px;
    background: color-mix(in srgb, var(--fg) 30%, transparent);
    z-index: 60;
    pointer-events: none;
  }

  .caption {
    margin: 0;
    font-size: 11px;
    letter-spacing: 0.04em;
    color: var(--dim);
    text-align: center;
    max-width: 36ch;
    line-height: 1.55;
  }
  .caption code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.3em;
    border-radius: 3px;
  }
</style>
