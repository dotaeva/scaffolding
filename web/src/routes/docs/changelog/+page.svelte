<script>
  import { base } from '$app/paths';
  import CodeBlock from '$lib/CodeBlock.svelte';
  import ScrollProgress from '$lib/ScrollProgress.svelte';
  import { GITHUB_URL } from '$lib/links.js';
  import {
    CODE_VIEW_BEFORE,
    CODE_VIEW_AFTER,
    CODE_ROUTE_BEFORE,
    CODE_ROUTE_AFTER,
    CODE_PRESENT_HOSTS,
    CODE_PRESENT_TYPED,
    CODE_CALLBACK_BEFORE,
    CODE_CALLBACK_AFTER,
    CODE_MACRO_INJECT,
    MIGRATION
  } from '$lib/code/changelog.js';

  const SECTIONS = [
    { id: 'three-one',   label: '3.1.0' },
    { id: 'three-zero',  label: '3.0' },
    { id: 'highlights',  label: 'Highlights' },
    { id: 'view',        label: 'view property' },
    { id: 'route',       label: 'route / present split' },
    { id: 'present',     label: 'present everywhere' },
    { id: 'callbacks',   label: 'Deep-link overloads' },
    { id: 'macro',       label: 'Macro options' },
    { id: 'fixes',       label: 'Fixes' },
    { id: 'compat',      label: 'Compatibility' },
    { id: 'migration',   label: 'Migration checklist' }
  ];
</script>

<ScrollProgress sections={SECTIONS} />

<main class="docs">
  <article class="article">
    <header class="hero">
      <p class="eyebrow">Changelog · latest 3.1.0</p>
      <h1>Scaffolding 3.1.0.</h1>
      <p class="lede">
        A small additive minor release. <code>present(_:as:)</code> gains
        a typed <code>{'<T: Coordinatable>'}</code> overload that mirrors
        the existing deep-link callbacks — so every navigation method
        that resolves a child now hands you a typed reference once the
        route lands.
      </p>
      <p class="meta">
        Source on <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer">GitHub</a>.
        Compare with the <a href={`${base}/docs`}>library overview</a>
        and the <a href={`${base}/docs/api`}>API reference</a>.
        Looking for the 2.x → 3.0 migration? <a href="#three-zero">Skip down</a>.
      </p>
    </header>

    <section id="three-one" class="sec">
      <h2>What's new in 3.1.0</h2>
      <ul class="highlights">
        <li>
          <span class="hl-tag new">New</span>
          <span class="hl-body">
            <code>present(_:as:onDismiss:)</code> ships a
            <code>{'<T: Coordinatable>'}</code> overload on every
            coordinator type. The trailing closure receives the
            freshly-presented child, ready to seed before SwiftUI
            commits the sheet or full-screen cover.
          </span>
        </li>
        <li>
          <span class="hl-tag fix">Fix</span>
          <span class="hl-body">
            Tutorial — Settings dismissal now uses
            <code>coordinator.pop()</code> (the modal lives on the host
            flow's unified stack).
            <code>dismissCoordinator()</code> on a root coordinator with
            no parent is a no-op, which the previous sample missed.
          </span>
        </li>
        <li>
          <span class="hl-tag fix">Fix</span>
          <span class="hl-body">
            Inline-code styling no longer leaks into syntax-highlighted
            <code>{'<pre><code>'}</code> blocks; pill backgrounds are
            scoped to genuine inline references in prose.
          </span>
        </li>
      </ul>
      <CodeBlock code={CODE_PRESENT_TYPED} label="HomeCoordinator · openSubscriptionAt" />
      <p class="sub">
        Same shape as <code>route(to:_:)</code> /
        <code>setRoot(_:_:)</code> — the cast only fires when the
        resolved destination matches <code>T</code>, so pick the
        concrete coordinator type returned by the route.
      </p>
    </section>

    <section id="three-zero" class="sec">
      <h2>Earlier — Scaffolding 3.0</h2>
      <p>
        A focused breaking release. Push and modal presentation are now
        separate APIs, <code>view</code> becomes a property, the
        generic value-callback overloads are gone, and a long list of
        navigation-state bugs got fixed. The migration checklist below
        applies to 2.x → 3.0; 3.0 → 3.1.0 is source-compatible.
      </p>
    </section>

    <section id="highlights" class="sec">
      <h2>Highlights</h2>
      <ul class="highlights">
        <li>
          <span class="hl-tag breaking">Breaking</span>
          <span class="hl-body">
            <code>coordinator.view()</code> is now the property
            <code>coordinator.view</code>.
          </span>
        </li>
        <li>
          <span class="hl-tag breaking">Breaking</span>
          <span class="hl-body">
            <code>route(to:as:)</code> is split into push-only
            <code>route(to:)</code> and modal-only
            <code>present(_:as:)</code>.
          </span>
        </li>
        <li>
          <span class="hl-tag breaking">Breaking</span>
          <span class="hl-body">
            The deep-link overloads
            (<code>route&lt;T&gt;</code>, <code>setRoot&lt;T&gt;</code>,
            <code>appendTab&lt;T&gt;</code>,
            <code>insertTab&lt;T&gt;</code>,
            <code>popToFirst&lt;T&gt;</code>,
            <code>popToLast&lt;T&gt;</code>,
            <code>selectFirstTab&lt;T&gt;</code>,
            <code>selectLastTab&lt;T&gt;</code>,
            <code>select&lt;T&gt;(index:)</code> /
            <code>select&lt;T&gt;(id:)</code>) keep their behaviour
            but tighten their signature: <code>T</code> is now
            constrained to <code>Coordinatable</code>, the trailing
            closure drops the <code>value:</code> label, and
            <code>route</code> loses its <code>as:</code> parameter.
          </span>
        </li>
        <li>
          <span class="hl-tag new">New</span>
          <span class="hl-body">
            <code>present(_:as:)</code> is now available on
            <code>TabCoordinatable</code> and
            <code>RootCoordinatable</code>, not just
            <code>FlowCoordinatable</code>.
          </span>
        </li>
        <li>
          <span class="hl-tag new">New</span>
          <span class="hl-body">
            <code>@Scaffoldable(injectsCoordinator: Bool = true)</code>
            opts a coordinator out of automatic environment injection.
          </span>
        </li>
        <li>
          <span class="hl-tag fix">Fix</span>
          <span class="hl-body">
            <code>setRoot</code> now wires up the parent chain on the
            new root and clears stale <code>NavigationStack</code>
            state from the previous root.
          </span>
        </li>
        <li>
          <span class="hl-tag fix">Fix</span>
          <span class="hl-body">
            <code>dismissCoordinator()</code> no longer leaks via
            retain cycles or leaves stale parent references behind.
          </span>
        </li>
        <li>
          <span class="hl-tag req">Platform</span>
          <span class="hl-body">
            Deployment floor bumped to iOS 18 / macOS 15 / tvOS 18 /
            watchOS 11 / macCatalyst 18. Strict-concurrency callbacks
            (<code>onDismiss</code>, deep-link trailing closures) are
            now <code>@MainActor</code>-typed.
          </span>
        </li>
      </ul>
    </section>

    <section id="view" class="sec">
      <h2><code>view()</code> → <code>view</code></h2>
      <p>
        Mounting a coordinator no longer goes through a function call.
        <code>view</code> is a SwiftUI-friendly computed property on
        every coordinator type, so it composes the same way any other
        view does — no parens, no method semantics to think about.
      </p>
      <CodeBlock code={CODE_VIEW_BEFORE} label="2.x · view() function" />
      <CodeBlock code={CODE_VIEW_AFTER}  label="3.0 · view property" />
      <p class="sub">
        Same change applies wherever the old API was reached for —
        <code>#Preview</code>, UIKit hosting controllers, snapshot
        tests, etc.
      </p>
    </section>

    <section id="route" class="sec">
      <h2><code>route(to:as:)</code> split into <code>route</code> and <code>present</code></h2>
      <p>
        The old <code>route(to:as:)</code> overloaded a single call
        with three different transitions (push / sheet / cover). The
        signature looked uniform but the call sites read ambiguously:
        you had to remember whether the destination represented a
        screen meant to be pushed or a flow meant to be shown
        modally. 3.0 makes the distinction explicit at the API level.
      </p>
      <CodeBlock code={CODE_ROUTE_BEFORE} label="2.x · combined route" />
      <CodeBlock code={CODE_ROUTE_AFTER}  label="3.0 · route + present" />
      <p class="sub">
        <code>present(_:as:)</code> takes a new
        <code>ModalPresentationType</code> (only <code>.sheet</code>
        and <code>.fullScreenCover</code>) so the type system also
        rules out the nonsensical "modal push." The richer
        <code>PresentationType</code> still exists internally for the
        unified-stack model that powers <code>pop()</code>.
      </p>
    </section>

    <section id="present" class="sec">
      <h2><code>present(_:as:)</code> on every coordinator type</h2>
      <p>
        Previously only <code>FlowCoordinatable</code> could present a
        modal. In 3.0 every coordinator type
        (<code>FlowCoordinatable</code>,
        <code>TabCoordinatable</code>,
        <code>RootCoordinatable</code>) implements
        <code>present(_:as:)</code>, so a tab coordinator or root
        coordinator can host a sheet directly without delegating to a
        synthetic child flow.
      </p>
      <CodeBlock code={CODE_PRESENT_HOSTS} label="TabCoordinatable hosts a sheet directly" />
      <p class="sub">
        <code>dismissCoordinator()</code> on the presented coordinator
        still dismisses the modal — <code>pop()</code> on the host
        does the same when the modal is the topmost destination
        (unified stack).
      </p>
    </section>

    <section id="callbacks" class="sec">
      <h2>Deep-link overloads tightened</h2>
      <p>
        Every navigation method that resolves a child coordinator
        (<code>route</code>, <code>present</code>, <code>setRoot</code>,
        <code>appendTab</code>, <code>insertTab</code>,
        <code>popToFirst</code>, <code>popToLast</code>,
        <code>selectFirstTab</code>, <code>selectLastTab</code>,
        <code>select(index:)</code>, <code>select(id:)</code>) ships
        a <code>{'<T: Coordinatable>'}</code> overload that hands you
        a typed reference to the resolved child once the route lands.
        That's the building block for <a href={`${base}/docs#deep-link`}>deep linking</a>:
        you walk the tree by chaining one overload per layer.
      </p>
      <p>
        The overloads themselves are <strong>still here</strong> in
        3.0 — what changed is their shape:
      </p>
      <ul class="bullets">
        <li><strong><code>T</code> is now constrained to <code>Coordinatable</code></strong>. View destinations don't need typed access (they have nothing to drive), so the constraint cleans up the call site without losing functionality.</li>
        <li><strong>The trailing closure drops the <code>value:</code> label.</strong> It's now an unlabelled trailing closure, which reads naturally as "after routing, do this with the resolved child."</li>
        <li><strong><code>route</code> drops <code>as:</code></strong> (the modal/push split). Pushes use <code>route(to:)</code>; modal entries via <code>present(_:as:)</code> have their own <code>{'<T: Coordinatable>'}</code> overload too.</li>
        <li><strong>Closures are <code>@MainActor</code>-typed</strong>, in line with the rest of the API.</li>
      </ul>
      <CodeBlock code={CODE_CALLBACK_BEFORE} label="2.x · value-labelled, unconstrained T, route-with-as" />
      <CodeBlock code={CODE_CALLBACK_AFTER}  label="3.0 · trailing closure, T: Coordinatable, route push-only" />
      <p class="sub">
        The pattern <em>itself</em> hasn't changed — just the spelling.
        See <a href={`${base}/docs#deep-link`}>Deep linking</a> in the
        overview for a full walk-through and an example that lands on
        a profile screen from a cold launch.
      </p>
    </section>

    <section id="macro" class="sec">
      <h2>Macro: <code>injectsCoordinator</code></h2>
      <p>
        By default <code>@Scaffoldable</code> wires the coordinator
        into the SwiftUI environment so any view in its hierarchy can
        read it via <code>@Environment(MyCoordinator.self)</code>.
        Sometimes that's the wrong default — a reusable coordinator
        embedded in a component shouldn't necessarily expose itself
        to surrounding views. Pass
        <code>injectsCoordinator: false</code> to opt out:
      </p>
      <CodeBlock code={CODE_MACRO_INJECT} label="@Scaffoldable(injectsCoordinator: false)" />
      <p class="sub">
        The macro emits a <code>nonisolated var _injectsCoordinator</code>
        member so the framework can read the flag at runtime without
        the user having to forward it themselves.
      </p>
    </section>

    <section id="fixes" class="sec">
      <h2>Bug fixes</h2>
      <ul class="bullets">
        <li>
          <strong><code>setRoot</code> stale state.</strong>
          The new root's parent chain was not always wired before the
          old root's <code>NavigationStack</code> ran one more update
          pass, leaving stale push state visible during the swap.
          <code>setRoot</code> now resolves the new root atomically
          and clears the navigation stack of the previous one.
        </li>
        <li>
          <strong><code>dismissCoordinator()</code> retain cycles.</strong>
          The presenter held a strong reference to the presented
          coordinator's <code>onDismiss</code>, which itself
          captured the presenter — collapse-from-modal kept the
          whole sub-tree alive. The presenter ↔ presented edge is
          now resolved through a one-shot resolver that drops the
          back-reference once dismissal completes.
        </li>
        <li>
          <strong>Parent chain on root coordinatables.</strong>
          <code>FlowStack</code> and <code>Root</code> now call
          <code>setParent</code> on the root coordinatable so child
          flows installed at the root can dismiss themselves and
          read the environment chain.
        </li>
        <li>
          <strong><code>FlowStack.setRoot</code> nil-unwrap crash.</strong>
          Replacing the root with a destination whose
          <code>coordinatable</code> resolved lazily could crash on a
          forced unwrap. The optional is now handled.
        </li>
        <li>
          <strong>Nested-coordinator pushes invisible to <code>NavigationStack</code>.</strong>
          A child flow's pushed destinations could be filtered out of
          the parent's flat path under specific traversal orderings.
          Fixed by recursing through nested coordinator boundaries
          when flattening destinations.
        </li>
        <li>
          <strong>Swift 6 strict-concurrency cleanup.</strong>
          Generated <code>Destinations</code> enum conformances no
          longer carry redundant <code>@MainActor</code>; closures and
          callbacks that touch coordinator state are
          <code>@MainActor</code>-typed at their declaration sites.
        </li>
      </ul>
    </section>

    <section id="compat" class="sec">
      <h2>Compatibility</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Requirement</th><th>2.x</th><th>3.0</th></tr>
          </thead>
          <tbody>
            <tr><td>Swift toolchain</td><td>6.2</td><td>6.2</td></tr>
            <tr><td>iOS</td><td>17</td><td><strong>18</strong></td></tr>
            <tr><td>macOS</td><td>14</td><td><strong>15</strong></td></tr>
            <tr><td>tvOS / watchOS / macCatalyst</td><td>13 / 6 / 13</td><td><strong>18 / 11 / 18</strong></td></tr>
            <tr><td><code>@Observable</code></td><td>required</td><td>required</td></tr>
            <tr><td>Strict concurrency</td><td>opt-in</td><td>required (<code>@MainActor</code>-typed callbacks)</td></tr>
            <tr><td><code>TabRole</code></td><td>iOS 18 + <code>@available</code></td><td>baseline (no annotation needed)</td></tr>
          </tbody>
        </table>
      </div>
      <p class="sub">
        The semver bump is driven by the API changes; the platform
        bump is the secondary breaking concern (consumers built
        against iOS 17 / macOS 14 won't link).
      </p>
    </section>

    <section id="migration" class="sec">
      <h2>Migration checklist</h2>
      <ol class="checklist">
        {#each MIGRATION as item}
          <li>
            <span class="check-tag" data-tag={item.tag.toLowerCase()}>{item.tag}</span>
            <span class="check-body">{@html item.body}</span>
          </li>
        {/each}
      </ol>
      <p class="sub">
        Once the call-site changes are in, the underlying mental
        model is unchanged: coordinators own navigation state, views
        read coordinators from <code>@Environment</code>,
        <code>route(to:)</code> pushes, <code>present(_:as:)</code>
        shows a modal, <code>dismissCoordinator()</code> closes a
        sub-flow.
      </p>
    </section>

    <footer class="next">
      <h2>Read on</h2>
      <p>
        <a href={`${base}/docs`}>Library overview →</a>
        &nbsp;·&nbsp;
        <a href={`${base}/docs/api`}>API reference →</a>
        &nbsp;·&nbsp;
        <a href={`${base}/docs/tutorial`}>Tutorial →</a>
        &nbsp;·&nbsp;
        <a href={`${base}/docs/agents`}>Agent guide →</a>
      </p>
    </footer>
  </article>
</main>

<style>
  /* Shared docs chrome lives in `$lib/styles/docs.css`. */

  /* ── Highlights list ──────────────────────────────────────────────── */

  .highlights {
    margin: 0.5rem 0 1rem;
    padding: 0;
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  .highlights li {
    display: grid;
    grid-template-columns: 92px 1fr;
    align-items: center;
    gap: 0.85rem;
    padding: 0.6rem 0.85rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
  }
  @media (max-width: 540px) {
    .highlights li {
      grid-template-columns: 1fr;
      gap: 0.4rem;
    }
  }
  .hl-tag {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    padding: 0.18rem 0.5rem;
    border-radius: 999px;
    line-height: 1;
    border: 1px solid currentColor;
    background: color-mix(in srgb, currentColor 8%, transparent);
    justify-self: start;
    align-self: center;
  }
  .hl-tag.breaking { color: var(--syn-kw); }
  .hl-tag.new      { color: var(--syn-ty); }
  .hl-tag.fix      { color: var(--syn-att); }
  .hl-tag.req      { color: var(--muted); }
  .hl-body {
    font-size: 13.5px;
    line-height: 1.55;
    color: color-mix(in srgb, var(--fg) 80%, transparent);
  }
  .hl-body code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

  /* ── Migration checklist ─────────────────────────────────────────── */

  .checklist {
    margin: 0 0 1rem;
    padding: 0;
    list-style: none;
    counter-reset: step;
    display: flex;
    flex-direction: column;
    gap: 0.55rem;
  }
  .checklist li {
    counter-increment: step;
    display: grid;
    grid-template-columns: 92px 1fr;
    gap: 0.85rem;
    align-items: center;
    padding: 0.65rem 0.95rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
  }
  @media (max-width: 540px) {
    .checklist li {
      grid-template-columns: 1fr;
      gap: 0.4rem;
    }
  }
  .check-tag {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    padding: 0.18rem 0.5rem;
    border-radius: 999px;
    line-height: 1;
    border: 1px solid currentColor;
    background: color-mix(in srgb, currentColor 8%, transparent);
    color: var(--muted);
    justify-self: start;
    align-self: center;
  }
  .check-tag[data-tag='required'] { color: var(--syn-kw); }
  .check-tag[data-tag='compiler'] { color: var(--syn-att); }
  .check-tag[data-tag='platform'] { color: var(--syn-kw); }
  .check-tag[data-tag='optional'] { color: var(--syn-ty); }

  .check-body {
    font-size: 13.5px;
    line-height: 1.6;
    color: color-mix(in srgb, var(--fg) 80%, transparent);
  }
  .check-body code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

</style>
