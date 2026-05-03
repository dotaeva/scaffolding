<script>
  /**
   * Working iPhone-shaped simulator: status bar, content area (auth or
   * main with home/profile tabs), tab bar, and modal overlay (sheet or
   * full-screen cover). Every interaction maps to the matching method
   * on PlaygroundState (so the action panel and the phone share the
   * exact same mutations).
   *
   * @prop state PlaygroundState.
   */
  import { fly, fade } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';

  let { state } = $props();
</script>

<div class="phone-col">
  <div class="phone">
    <div class="phone-frame">
      <span class="notch"></span>
      <div class="screen-area">
        {#if state.phase === 'auth'}
          <div
            class="layer auth"
            in:fade={{ duration: 220, easing: cubicOut }}
            out:fade={{ duration: 180 }}
          >
            <div class="status-bar"><span>9:41</span></div>
            <div class="screen-content auth-content">
              <h4>Welcome back</h4>
              <p class="muted">Sign in to continue</p>
              <div class="field"></div>
              <div class="field"></div>
              <button
                type="button"
                class="primary"
                onclick={() => state.setPhase('main')}
              >
                Sign in
              </button>
            </div>
          </div>
        {:else}
          <div
            class="layer main"
            in:fade={{ duration: 220, easing: cubicOut }}
            out:fade={{ duration: 180 }}
          >
            <div class="status-bar">
              <span>9:41</span>
              <span class="bars">●●●</span>
            </div>
            <div class="content">
              {#if state.tab === 'home'}
                <div
                  class="tab-pane"
                  in:fade={{ duration: 200, easing: cubicOut }}
                  out:fade={{ duration: 160 }}
                >
                  <div class="stack-region">
                    {#each state.homePushed as item, i (item.id)}
                      <div
                        class="screen"
                        style="z-index: {i + 1};"
                        in:fly={{ x: 320, duration: 340, easing: cubicOut }}
                        out:fly={{ x: 320, duration: 260, easing: cubicOut }}
                      >
                        {#if item.screen === 'home'}
                          <div class="screen-content">
                            <header class="screen-top">
                              <h4>Planets</h4>
                              <button
                                type="button"
                                class="icon-btn"
                                onclick={state.presentSheet}
                                aria-label="Open settings"
                              >⚙</button>
                            </header>
                            <ul class="list">
                              {#each state.PLANETS as p}
                                <li>
                                  <button
                                    type="button"
                                    class="row"
                                    onclick={() => state.routeToDetail(p)}
                                  >
                                    <span>{p}</span>
                                    <span class="chev" aria-hidden="true">›</span>
                                  </button>
                                </li>
                              {/each}
                            </ul>
                          </div>
                        {:else if item.screen === 'detail'}
                          <div class="screen-content detail">
                            <button
                              type="button"
                              class="back"
                              onclick={state.pop}
                            >‹ Planets</button>
                            <h4>{item.payload.title}</h4>
                            <p class="lorem"></p>
                            <p class="lorem short"></p>
                            <p class="lorem"></p>
                          </div>
                        {/if}
                      </div>
                    {/each}
                  </div>
                </div>
              {:else}
                <div
                  class="tab-pane"
                  in:fade={{ duration: 200, easing: cubicOut }}
                  out:fade={{ duration: 160 }}
                >
                  <div class="stack-region">
                    {#each state.profilePushed as item, i (item.id)}
                      <div
                        class="screen"
                        style="z-index: {i + 1};"
                        in:fly={{ x: 320, duration: 340, easing: cubicOut }}
                        out:fly={{ x: 320, duration: 260, easing: cubicOut }}
                      >
                        {#if item.screen === 'profile'}
                          <div class="screen-content">
                            <div class="avatar"></div>
                            <h4>Alex</h4>
                            <p class="muted">@alex</p>
                            <ul class="list">
                              <li>
                                <button
                                  type="button"
                                  class="row"
                                  onclick={state.routeToEditProfile}
                                >
                                  <span>Edit profile</span>
                                  <span class="chev" aria-hidden="true">›</span>
                                </button>
                              </li>
                              <li>
                                <button
                                  type="button"
                                  class="row"
                                  onclick={state.presentCover}
                                >
                                  <span>Re-authenticate</span>
                                  <span class="chev" aria-hidden="true">›</span>
                                </button>
                              </li>
                              <li>
                                <button
                                  type="button"
                                  class="row"
                                  onclick={() => state.setPhase('auth')}
                                >
                                  <span>Sign out</span>
                                  <span class="chev" aria-hidden="true">›</span>
                                </button>
                              </li>
                            </ul>
                          </div>
                        {:else if item.screen === 'detail'}
                          <div class="screen-content detail">
                            <button
                              type="button"
                              class="back"
                              onclick={state.pop}
                            >‹ Profile</button>
                            <h4>{item.payload.title}</h4>
                            <p class="lorem"></p>
                          </div>
                        {:else if item.screen === 'edit-profile'}
                          <div class="screen-content detail">
                            <button
                              type="button"
                              class="back"
                              onclick={state.pop}
                            >‹ Profile</button>
                            <h4>Edit profile</h4>
                            <div class="field"></div>
                            <div class="field"></div>
                            <button
                              type="button"
                              class="primary"
                              onclick={state.pop}
                            >Save</button>
                          </div>
                        {/if}
                      </div>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
            <div class="tabbar">
              <button
                type="button"
                class="tab-btn"
                class:active={state.tab === 'home'}
                onclick={() => state.selectTab('home')}
              >
                <span class="tab-icon" aria-hidden="true">⌂</span>
                <span>Home</span>
              </button>
              <button
                type="button"
                class="tab-btn"
                class:active={state.tab === 'profile'}
                onclick={() => state.selectTab('profile')}
              >
                <span class="tab-icon" aria-hidden="true">●</span>
                <span>Profile</span>
              </button>
            </div>
          </div>
        {/if}

        {#if state.modal}
          {#if state.modal.pushType === 'sheet'}
            <button
              type="button"
              class="backdrop"
              aria-label="Dismiss sheet"
              onclick={state.dismissCoordinator}
              in:fade={{ duration: 240 }}
              out:fade={{ duration: 200 }}
            ></button>
          {/if}
          <div
            class="modal {state.modal.pushType}"
            in:fly={{ y: 700, duration: 380, easing: cubicOut }}
            out:fly={{ y: 700, duration: 280, easing: cubicOut }}
          >
            {#if state.modal.pushType === 'sheet'}
              <span class="grabber" aria-hidden="true"></span>
            {/if}
            {#if state.modal.screen === 'settings'}
              <div class="screen-content">
                <header class="screen-top">
                  <h4>Settings</h4>
                  <button
                    type="button"
                    class="text-btn"
                    onclick={state.dismissCoordinator}
                  >Done</button>
                </header>
                <ul class="list">
                  <li>Notifications</li>
                  <li>Privacy</li>
                  <li>Account</li>
                  <li>About</li>
                </ul>
              </div>
            {:else if state.modal.screen === 'login-cover'}
              <div class="screen-content auth-content">
                <header class="screen-top">
                  <button
                    type="button"
                    class="text-btn cancel"
                    onclick={state.dismissCoordinator}
                  >Cancel</button>
                </header>
                <h4>Sign in</h4>
                <p class="muted">Enter your credentials</p>
                <div class="field"></div>
                <div class="field"></div>
                <button
                  type="button"
                  class="primary"
                  onclick={state.dismissCoordinator}
                >Continue</button>
              </div>
            {/if}
          </div>
        {/if}

        <div class="home-indicator" aria-hidden="true"></div>
      </div>
    </div>
  </div>

  <p class="caption">
    Tap rows, tabs, gear, or back arrow to drive the simulation.
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
    /* Whichever is smaller: the width clamp, or what fits in 75vh of
       viewport height while preserving aspect ratio. Keeps the phone
       on-screen on short displays without overflowing on tall ones. */
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
    /* Push the time / signal indicators down so they line up with the
       vertical center of the Dynamic Island. */
    padding: 18px 22px 8px;
    font-size: 11px;
    letter-spacing: 0.04em;
    color: color-mix(in srgb, var(--fg) 75%, transparent);
  }

  .bars {
    font-size: 8px;
    letter-spacing: 0.15em;
    opacity: 0.7;
  }

  .content {
    position: relative;
    flex: 1;
    min-height: 0;
    overflow: hidden;
  }

  .tab-pane {
    position: absolute;
    inset: 0;
  }

  .stack-region {
    position: absolute;
    inset: 0;
  }

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
    justify-content: space-between;
    gap: 0.5rem;
  }

  .screen-content h4 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: 17px;
    font-weight: 600;
    color: var(--fg);
    letter-spacing: -0.01em;
  }

  .muted {
    margin: 0;
    font-size: 12px;
    color: color-mix(in srgb, var(--fg) 55%, transparent);
  }

  /* ── In-phone interactive elements ──────────────────────────────── */

  .icon-btn {
    width: 28px;
    height: 28px;
    border-radius: 8px;
    border: 1px solid color-mix(in srgb, var(--fg) 14%, transparent);
    background: color-mix(in srgb, var(--fg) 5%, transparent);
    color: var(--fg);
    font-size: 13px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: background-color 140ms ease, border-color 140ms ease;
  }
  .icon-btn:hover {
    background: color-mix(in srgb, var(--fg) 12%, transparent);
    border-color: color-mix(in srgb, var(--fg) 30%, transparent);
  }
  .icon-btn:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
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
  }
  .text-btn:hover {
    background: color-mix(in srgb, var(--fg) 8%, transparent);
  }
  .text-btn.cancel {
    color: color-mix(in srgb, var(--fg) 70%, transparent);
  }

  .list {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .list li {
    padding: 0;
    font-size: 12.5px;
    color: color-mix(in srgb, var(--fg) 85%, transparent);
  }

  /* Plain (non-interactive) list rows used inside the settings sheet. */
  .list > li:not(:has(.row)) {
    padding: 9px 11px;
    border-radius: 6px;
    background: color-mix(in srgb, var(--fg) 6%, transparent);
    border: 1px solid color-mix(in srgb, var(--fg) 8%, transparent);
  }

  .row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 9px 11px;
    border-radius: 6px;
    background: color-mix(in srgb, var(--fg) 5%, transparent);
    border: 1px solid color-mix(in srgb, var(--fg) 8%, transparent);
    color: inherit;
    font: inherit;
    font-size: 12.5px;
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

  .chev {
    color: color-mix(in srgb, var(--fg) 45%, transparent);
    font-size: 13px;
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

  .lorem {
    height: 8px;
    margin: 0;
    border-radius: 999px;
    background: color-mix(in srgb, var(--fg) 12%, transparent);
  }
  .lorem.short { width: 60%; }

  .avatar {
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--fg) 18%, transparent);
    align-self: center;
    margin-top: 8px;
  }

  .field {
    height: 32px;
    border-radius: 7px;
    background: color-mix(in srgb, var(--fg) 8%, transparent);
    border: 1px solid color-mix(in srgb, var(--fg) 12%, transparent);
  }

  .primary {
    margin-top: 4px;
    padding: 9px 14px;
    font: inherit;
    font-size: 13px;
    border-radius: 8px;
    border: 0;
    background: var(--fg);
    color: var(--bg);
    cursor: pointer;
    transition: opacity 140ms ease;
  }
  .primary:hover { opacity: 0.85; }
  .primary:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }

  .auth-content {
    justify-content: center;
    gap: 12px;
  }

  /* ── Tab bar ──────────────────────────────────────────────────────── */

  .tabbar {
    flex-shrink: 0;
    display: grid;
    grid-template-columns: 1fr 1fr;
    border-top: 1px solid color-mix(in srgb, var(--fg) 12%, transparent);
    background: color-mix(in srgb, var(--fg) 4%, var(--bg));
    padding-bottom: 8px;
  }

  .tab-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    padding: 9px 0 6px;
    font: inherit;
    font-family: var(--font-mono);
    font-size: 10.5px;
    color: color-mix(in srgb, var(--fg) 50%, transparent);
    background: transparent;
    border: 0;
    cursor: pointer;
    transition: color 180ms ease, background-color 140ms ease;
  }
  .tab-btn:hover {
    color: var(--fg);
    background: color-mix(in srgb, var(--fg) 5%, transparent);
  }
  .tab-btn.active {
    color: var(--fg);
  }
  .tab-btn:focus-visible {
    outline: none;
    box-shadow: inset 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }

  .tab-icon {
    font-size: 16px;
    line-height: 1;
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

  .modal.sheet {
    /* Leave room above the sheet so the Dynamic Island stays visible. */
    top: 56px;
  }

  .modal.cover {
    top: 0;
    border-radius: 0;
  }

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

  .caption {
    margin: 0;
    font-size: 11px;
    letter-spacing: 0.04em;
    color: var(--dim);
    text-align: center;
    max-width: 30ch;
  }
</style>
