<script>
  import { base } from '$app/paths';
  import CodeBlock from '$lib/CodeBlock.svelte';
  import ScrollProgress from '$lib/ScrollProgress.svelte';
  import { GITHUB_URL } from '$lib/links.js';
  import Caveat from '$lib/docs/Caveat.svelte';
  import RuleList from '$lib/docs/RuleList.svelte';
  import Rule from '$lib/docs/Rule.svelte';
  import MistakeCard from '$lib/docs/MistakeCard.svelte';
  import {
    CODE_NESTED_BAD,
    CODE_DECISION_TREE,
    CODE_ANATOMY,
    CODE_CONCRETE_VS_EXISTENTIAL,
    CODE_IGNORED,
    CODE_HIERARCHY,
    CODE_RESULT_PRESENTER,
    CODE_RESULT_PRESENTED,
    CODE_PATTERN_SHEET_FLOW,
    CODE_PATTERN_NATIVE_SHEET,
    CODE_PATTERN_AUTH,
    CODE_PATTERN_TAB,
    CODE_DEEPLINK,
    CODE_DEEPLINK_URL,
    CODE_PREVIEW_BAD,
    CODE_PREVIEW_OK,
    CODE_ADAPTIVE_BAR,
    CODE_MISTAKE_NESTED,
    CODE_MISTAKE_CONCRETE,
    CODE_MISTAKE_VIEW_STATE,
    CODE_MISTAKE_OLD_API,
    CODE_MISTAKE_NAVLINK,
    CODE_MISTAKE_DISMISS
  } from '$lib/code/agents.js';

  // Copy-as-markdown action. The full AGENTS.md is mirrored at
  // /static/AGENTS.md so it's served untouched alongside the site —
  // agents can pull it directly via that URL too.
  let copyState = $state('idle'); // 'idle' | 'copied' | 'error'
  let copyTimer;

  async function copyMarkdown() {
    try {
      const res = await fetch(`${base}/AGENTS.md`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const text = await res.text();
      await navigator.clipboard.writeText(text);
      copyState = 'copied';
    } catch {
      copyState = 'error';
    }
    clearTimeout(copyTimer);
    copyTimer = setTimeout(() => { copyState = 'idle'; }, 2000);
  }

  const SECTIONS = [
    { id: 'why',          label: 'Why' },
    { id: 'hard-rule',    label: 'Hard rule' },
    { id: 'picking',      label: 'Picking a primitive' },
    { id: 'anatomy',      label: 'Coordinator anatomy' },
    { id: 'protocols',    label: 'Three protocols' },
    { id: 'discipline',   label: 'Separation' },
    { id: 'patterns',     label: 'Quick patterns' },
    { id: 'deep-link',    label: 'Deep linking' },
    { id: 'previews',     label: 'Previews' },
    { id: 'mistakes',     label: 'Common mistakes' },
    { id: 'compat',       label: 'Compatibility' },
    { id: 'tldr',         label: 'TL;DR' }
  ];

</script>

<ScrollProgress sections={SECTIONS} />

<main class="docs">
  <article class="article">
    <header class="hero">
      <p class="eyebrow">Agent guide · Best practices</p>
      <h1>Scaffolding for agents.</h1>
      <p class="lede">
        A reference for LLM coding agents (and humans) writing SwiftUI
        code with the <strong>Scaffolding</strong> library. Read this
        before generating navigation code in any project that uses
        Scaffolding.
      </p>
      <aside class="thesis" role="note">
        <span class="thesis-tag">Thesis</span>
        <p>
          Scaffolding's value is <strong>modular navigation across
          coordinator boundaries</strong>. The win is separation of
          concerns — UI views never own navigation state. If you produce
          code that mixes navigation state into views, you've lost the
          reason to use the library.
        </p>
      </aside>
      <div class="actions">
        <button
          type="button"
          class="copy-btn"
          class:is-copied={copyState === 'copied'}
          class:is-error={copyState === 'error'}
          onclick={copyMarkdown}
          aria-live="polite"
        >
          <span class="copy-icon" aria-hidden="true">
            {#if copyState === 'copied'}✓{:else if copyState === 'error'}!{:else}⧉{/if}
          </span>
          <span class="copy-label">
            {#if copyState === 'copied'}Copied to clipboard{:else if copyState === 'error'}Copy failed — try again{:else}Copy as Markdown{/if}
          </span>
        </button>
        <a class="raw-link" href={`${base}/AGENTS.md`} target="_blank" rel="noopener">
          View raw <code>AGENTS.md</code> →
        </a>
      </div>
      <p class="meta">
        Source on <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer">GitHub</a>.
        See also the <a href={`${base}/docs`}>library overview</a> and
        the <a href={`${base}/docs/api`}>API reference</a>.
      </p>
    </header>

    <section id="why" class="sec">
      <h2>Why Scaffolding exists</h2>
      <p>
        SwiftUI's <code>NavigationStack(path:)</code> works for a single,
        self-contained screen graph. It breaks down once an app has:
      </p>
      <ul class="bullets">
        <li>multiple feature modules that need to push into each other,</li>
        <li>destination types defined in different modules,</li>
        <li>coordinator-driven flows (login, onboarding, settings sheets),</li>
        <li>programmatic navigation that has to compose across module boundaries.</li>
      </ul>
      <p>
        <code>NavigationStack</code> keeps navigation
        <strong>inside the view tree</strong>. That's the design
        constraint Scaffolding is built to escape. A
        <code>FlowCoordinatable</code> <em>is</em> a
        <code>NavigationStack</code> — but its destinations live on the
        coordinator (a plain Swift class), the macro generates the
        destination enum, and child coordinators slot in as routes
        without the view tree knowing.
      </p>
      <p>
        If you find yourself reaching for
        <code>NavigationStack(path:)</code> inside a Scaffolding project,
        <strong>stop</strong>. There is almost certainly a
        coordinator-side answer.
      </p>
    </section>

    <section id="hard-rule" class="sec">
      <h2>The hard rule: do not nest <code>NavigationStack</code></h2>
      <p>
        <code>FlowCoordinatable</code> already wraps a
        <code>NavigationStack</code> internally. SwiftUI does
        <strong>not</strong> compose <code>NavigationStack</code>s with
        each other — the inner stack swallows pushes that should belong
        to the outer one, and <code>route(to:)</code> stops doing what
        you expect.
      </p>
      <Caveat tag="Never">
        <p>
          <strong>Never put a <code>NavigationStack</code> inside any
          view returned by a <code>FlowCoordinatable</code> route
          function.</strong>
          Not in the root view, not in a pushed detail view, not in a
          customise wrapper.
        </p>
        <p>
          The same applies to anything that wraps SwiftUI's stack:
          <code>NavigationView</code>, <code>NavigationSplitView</code>,
          custom containers that hold a <code>NavigationPath</code>.
          They all conflict.
        </p>
      </Caveat>
      <p>If a screen needs its own navigation hierarchy, give it a child coordinator:</p>
      <CodeBlock code={CODE_NESTED_BAD} label="Detail · child coordinator instead of nested stack" />
    </section>

    <section id="picking" class="sec">
      <h2>Picking a navigation primitive</h2>
      <p>When a user-facing transition needs to happen, use this decision tree:</p>
      <pre class="ascii"><code>{CODE_DECISION_TREE}</code></pre>

      <h3>Concretely</h3>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>You want…</th><th>Use</th></tr>
          </thead>
          <tbody>
            <tr><td>Push a screen onto the current flow</td><td><code>coordinator.route(to: .screen(args:))</code></td></tr>
            <tr><td>Pop the current screen</td><td><code>coordinator.pop()</code></td></tr>
            <tr><td>Pop everything above the root</td><td><code>coordinator.popToRoot()</code></td></tr>
            <tr><td>Show a confirmation dialog</td><td>SwiftUI's <code>.alert</code> / <code>.confirmationDialog</code></td></tr>
            <tr><td>Show a one-screen sheet (simple form, info)</td><td>SwiftUI's <code>.sheet(item:)</code></td></tr>
            <tr><td>Show a multi-step sub-flow</td><td><code>coordinator.present(.subflow, as: .sheet)</code></td></tr>
            <tr><td>Show a full-screen sub-flow</td><td><code>coordinator.present(.subflow, as: .fullScreenCover)</code></td></tr>
            <tr><td>Atomically replace the entire view hierarchy (auth, onboarding)</td><td><code>appCoordinator.setRoot(.authenticated)</code> (on a <code>RootCoordinatable</code>)</td></tr>
            <tr><td>Switch tabs programmatically</td><td><code>tabCoordinator.selectFirstTab(.home)</code></td></tr>
          </tbody>
        </table>
      </div>
      <p class="sub">
        Stay native for view-only modals. The native modifier is
        lighter, requires no coordinator boundary, and avoids the
        overhead of an extra <code>Destinations</code> case.
      </p>
    </section>

    <section id="anatomy" class="sec">
      <h2>Coordinator anatomy</h2>
      <CodeBlock code={CODE_ANATOMY} label="HomeCoordinator.swift" />

      <h3>Auto-tracked return types</h3>
      <p class="sub">
        The <code>@Scaffoldable</code> macro generates a
        <code>Destinations</code> enum with one case per function whose
        return type is one of:
      </p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Return type</th><th>What it generates</th></tr>
          </thead>
          <tbody>
            <tr><td><code>some View</code></td><td>A view destination</td></tr>
            <tr><td><code>any Coordinatable</code></td><td>A child-coordinator destination</td></tr>
            <tr><td><code>(any Coordinatable, some View)</code></td><td>Tab tuple (coordinator + label)</td></tr>
            <tr><td><code>(some View, some View)</code></td><td>Tab tuple (view-only + label)</td></tr>
            <tr><td><code>(any Coordinatable, some View, TabRole)</code></td><td>Tab tuple with role</td></tr>
            <tr><td><code>(some View, some View, TabRole)</code></td><td>Tab tuple with role + view-only</td></tr>
          </tbody>
        </table>
      </div>
      <p>
        Anything else — including a <strong>concrete</strong>
        coordinator type like <code>-&gt; LoginCoordinator</code> — is
        <strong>not</strong> recognised. For a child coordinator the
        return type <strong>must</strong> be
        <code>any Coordinatable</code> (the existential).
      </p>
      <CodeBlock code={CODE_CONCRETE_VS_EXISTENTIAL} label="Concrete vs. existential" />

      <h3>Marking exclusions</h3>
      <p>
        Use <code>@ScaffoldingIgnored</code> whenever a method returns
        one of the auto-tracked types but <strong>isn't</strong> a
        destination — typically a <code>customize(_:)</code> override or
        a helper view builder shared between screens:
      </p>
      <CodeBlock code={CODE_IGNORED} label="@ScaffoldingIgnored on customize" />
      <p>
        Use <code>@ScaffoldingTracked</code> only when you want the
        <em>opposite</em> default — explicit opt-in. After applying it
        once, only methods carrying <code>@ScaffoldingTracked</code> are
        emitted as destinations.
      </p>
    </section>

    <section id="protocols" class="sec">
      <h2>Three coordinator protocols</h2>
      <p>Pick by user-facing structure, not by mood.</p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Protocol</th><th>Use when</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>FlowCoordinatable</code></td>
              <td>Push/pop navigation. The workhorse. Wraps a <code>NavigationStack</code>.</td>
            </tr>
            <tr>
              <td><code>TabCoordinatable</code></td>
              <td>Tab bar where each tab is independent. Each tab's content is its own coordinator.</td>
            </tr>
            <tr>
              <td><code>RootCoordinatable</code></td>
              <td>Atomic root swap: auth flow ↔ main app, onboarding ↔ home. The whole tree is replaced when <code>setRoot(_:)</code> is called.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>A typical app uses all three:</p>
      <pre class="ascii"><code>{CODE_HIERARCHY}</code></pre>
      <p>
        <code>setRoot</code> flips between the two <code>App</code>
        children. The tab coordinator owns the home/profile flows. Each
        flow handles its own pushes and modals.
      </p>
    </section>

    <section id="discipline" class="sec">
      <h2>Separation of concerns — the discipline</h2>
      <p>
        This is the part that makes Scaffolding worth using. If you
        violate it, you've reintroduced the problems Scaffolding was
        built to solve.
      </p>

      <h3>Views never own navigation state</h3>
      <RuleList>
        <Rule tag="Don't" tone="bad">A view holds <code>@State path: [SomeType]</code>.</Rule>
        <Rule tag="Don't" tone="bad">A view holds <code>@State isPresented = false</code> for a sheet that's part of the flow.</Rule>
        <Rule tag="Don't" tone="bad">A view receives <code>@Binding path: [SomeType]</code> to pop.</Rule>
        <Rule tag="Do" tone="good">A view reads its coordinator from <code>@Environment</code> and calls <code>coordinator.route(to:)</code>, <code>coordinator.pop()</code>, <code>coordinator.present(_:as:)</code> etc.</Rule>
      </RuleList>

      <h3>Coordinators don't know how their views render</h3>
      <RuleList>
        <Rule tag="Don't" tone="bad">A coordinator imports SwiftUI just to construct a <code>NavigationStack</code>.</Rule>
        <Rule tag="Don't" tone="bad">A coordinator reads <code>@Environment</code> (it's not a View).</Rule>
        <Rule tag="Do" tone="good">A coordinator's job is route declaration + state mutation. The macro and the framework wire the views to the stack.</Rule>
      </RuleList>

      <h3>Modules expose coordinators, not views</h3>
      <p>In a multi-module app, the right unit of import is the coordinator type:</p>
      <CodeBlock code={`import HomeFeature

let home = HomeCoordinator()
appRoot.setRoot(.home(home))`} label="Cross-module composition" />
      <p>
        Other modules don't need to know what views are inside, what
        destinations exist, or how the flow is structured. They hold a
        coordinator reference and route to its surface.
      </p>

      <h3>Result delivery between coordinators</h3>
      <p>When a presented coordinator needs to return a value, take the callback in the route function:</p>
      <CodeBlock code={CODE_RESULT_PRESENTER} label="AppCoordinator · presenter" />
      <p>Inside <code>LoginCoordinator</code>, when the user finishes:</p>
      <CodeBlock code={CODE_RESULT_PRESENTED} label="LoginCoordinator · presented" />
      <p>
        The presenter doesn't observe the presented coordinator's
        state. The presented coordinator hands a result back through
        the closure it was constructed with, then dismisses itself.
        Clean boundaries.
      </p>

      <h3><code>dismissCoordinator()</code> semantics</h3>
      <p>
        <code>dismissCoordinator()</code> is called on the coordinator
        being removed. It pops the <strong>whole coordinator</strong>
        off its parent — not a screen. For a sheet/cover, that closes
        the modal. For a pushed child coordinator, that removes the
        child and any of its own pushed destinations.
      </p>
      <p>
        To pop a single screen within the same flow, use
        <code>pop()</code>. The two are not interchangeable.
      </p>
    </section>

    <section id="patterns" class="sec">
      <h2>Quick patterns</h2>

      <h3>A flow with a sheet that's a sub-flow</h3>
      <CodeBlock code={CODE_PATTERN_SHEET_FLOW} label="HomeCoordinator with present(.settings, as: .sheet)" />

      <h3>A flow with a one-screen view-only sheet</h3>
      <CodeBlock code={CODE_PATTERN_NATIVE_SHEET} label="Coordinator + native .sheet" />

      <h3>Atomic auth swap</h3>
      <CodeBlock code={CODE_PATTERN_AUTH} label="AppCoordinator · RootCoordinatable" />

      <h3>Tab bar with independent flows</h3>
      <CodeBlock code={CODE_PATTERN_TAB} label="MainTabCoordinator" />
    </section>

    <section id="deep-link" class="sec">
      <h2>Deep linking</h2>
      <p>
        Every navigation method that resolves a child coordinator
        (<code>route</code>, <code>present</code>, <code>setRoot</code>,
        <code>appendTab</code>, <code>insertTab</code>,
        <code>popToFirst</code>, <code>popToLast</code>,
        <code>selectFirstTab</code>, <code>selectLastTab</code>,
        <code>select(index:)</code>, <code>select(id:)</code>) ships
        an overload constrained to <code>{'<T: Coordinatable>'}</code>
        with a trailing closure. The closure fires after the route
        lands, receiving a typed reference to the freshly-resolved
        child — chain them to walk the tree from a cold launch.
      </p>
      <CodeBlock code={CODE_DEEPLINK}     label="AppCoordinator · openProfile(userId:)" />
      <CodeBlock code={CODE_DEEPLINK_URL} label="MyApp · onOpenURL" />

      <RuleList>
        <Rule tag="Do" tone="good">
          Pick the concrete coordinator type that matches the
          route's return signature for <code>T</code>. The closure
          only fires if the cast succeeds.
        </Rule>
        <Rule tag="Don't" tone="bad">
          Store handles to child coordinators outside the chain.
          The typed overloads exist so you don't have to — they
          hand you the right reference at the right time.
        </Rule>
        <Rule tag="Don't" tone="bad">
          Deep-link in pieces from a view. Deep-linking belongs on
          the coordinator (or on whatever orchestrator owns the
          URL/push entry point), and views call into it. A view
          that dispatches multiple <code>route(to:)</code> /
          <code>setRoot(_:)</code> calls in sequence is a smell.
        </Rule>
      </RuleList>
    </section>

    <section id="previews" class="sec">
      <h2>Previews</h2>
      <p>
        SwiftUI's <code>#Preview</code> and Scaffolding's
        <code>@Scaffoldable</code> are both compile-time macros, but
        they don't compose at runtime the way you might expect. When
        generating preview code in a Scaffolding project, follow these
        rules — they save the user from chasing phantom bugs.
      </p>

      <RuleList>
        <Rule tag="Don't" tone="bad">
          Generate <code>HomeCoordinator(initialRoute: .detail)</code>.
          The macro doesn't emit an init that takes a starting
          destination — there's nothing to call.
        </Rule>
        <Rule tag="Do" tone="good">
          Preview the coordinator at its real root
          (<code>HomeCoordinator().view</code>), or render the leaf
          view directly and inject the coordinator it reads.
        </Rule>
      </RuleList>

      <CodeBlock code={CODE_PREVIEW_BAD} label="Won't compile" />
      <CodeBlock code={CODE_PREVIEW_OK}  label="Two patterns that do work" />

      <RuleList>
        <Rule tag="Do" tone="good">
          For any view that declares
          <code>@Environment(SomeCoordinator.self)</code>, attach
          <code>.environment(SomeCoordinator())</code> in the
          preview. Without it, the lookup falls back to a default
          (or crashes on Swift 6).
        </Rule>
        <Rule tag="Don't" tone="bad">
          Make rendering decisions that depend on
          <code>destination.routeType</code> /
          <code>destination.presentationType</code> /
          <code>destination.meta</code> showing the runtime value in
          previews. The destination env value is set when
          Scaffolding materialises a route — a preview that renders
          a leaf view gets the default
          (<code>.root</code>), regardless of how the screen would
          be reached at runtime.
        </Rule>
      </RuleList>

      <h3>Adaptive bars from <code>\.destination</code></h3>
      <p>
        The flip side of caveat 3: at <em>runtime</em> the destination
        environment is reliable, and its public properties are exactly
        what you need to write a single reusable chrome that adapts to
        push / sheet / cover / root context. The pattern below is the
        canonical use of <code>destination.routeType</code>:
      </p>
      <CodeBlock code={CODE_ADAPTIVE_BAR} label="AdaptiveTopBar.swift" />
      <p class="sub">
        Switch on <code>destination.meta</code> when the same view
        renders different layouts depending on which generated case
        led to it. The <code>Meta</code> enum is emitted alongside
        <code>Destinations</code> by the macro.
      </p>
    </section>

    <section id="mistakes" class="sec">
      <h2>Common mistakes — what NOT to generate</h2>

      <MistakeCard num="01">
        {#snippet title()}Wrapping a destination view in <code>NavigationStack</code>{/snippet}
        <CodeBlock code={CODE_MISTAKE_NESTED} label="Anti-pattern · nested NavigationStack" />
        <p class="sub">
          Drop the <code>NavigationStack</code>. The parent flow already
          provides one.
        </p>
      </MistakeCard>

      <MistakeCard num="02">
        {#snippet title()}Concrete coordinator return types{/snippet}
        <CodeBlock code={CODE_MISTAKE_CONCRETE} label="Anti-pattern · concrete return type" />
        <p class="sub">Use <code>any Coordinatable</code>.</p>
      </MistakeCard>

      <MistakeCard num="03">
        {#snippet title()}Holding navigation state in a view{/snippet}
        <CodeBlock code={CODE_MISTAKE_VIEW_STATE} label="Anti-pattern · view-owned state" />
        <p class="sub">
          Move pushes to the coordinator
          (<code>coordinator.route(to: .detail(item:))</code>). Keep the
          sheet only if it's a true single-screen view-only modal.
        </p>
      </MistakeCard>

      <MistakeCard num="04">
        {#snippet title()}<code>route(to:as:)</code> (old API){/snippet}
        <p>
          That API was split. Push uses <code>route(to:)</code>. Modals
          use <code>present(_:as:)</code>. There is no <code>as:</code>
          parameter on <code>route</code> anymore.
        </p>
        <CodeBlock code={CODE_MISTAKE_OLD_API} label="Anti-pattern · old combined API" />
      </MistakeCard>

      <MistakeCard num="05">
        {#snippet title()}Reaching for <code>NavigationLink</code> to push{/snippet}
        <CodeBlock code={CODE_MISTAKE_NAVLINK} label="Anti-pattern · NavigationLink coupling" />
      </MistakeCard>

      <MistakeCard num="06">
        {#snippet title()}Calling <code>dismissCoordinator()</code> to close a single screen{/snippet}
        <CodeBlock code={CODE_MISTAKE_DISMISS} label="Anti-pattern · misusing dismissCoordinator" />
        <p class="sub">
          Use <code>coordinator.pop()</code> — or SwiftUI's
          <code>@Environment(\.dismiss)</code>, which works because
          Scaffolding wraps <code>NavigationStack</code>. Save
          <code>dismissCoordinator()</code> for "close the whole
          sub-flow" cases.
        </p>
      </MistakeCard>
    </section>

    <section id="compat" class="sec">
      <h2>Compatibility notes</h2>
      <ul class="bullets">
        <li>Scaffolding requires Swift 6.2 (<code>@Observable</code>, the macro toolchain, strict concurrency). The package's <code>swift-tools-version</code> is <code>6.2</code>.</li>
        <li>Platform floor: iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / macCatalyst 18. <code>TabRole</code> is available unconditionally on this floor.</li>
        <li><code>onDismiss</code> and the deep-link trailing closures are typed <code>@MainActor () -&gt; Void</code> / <code>@MainActor (T) -&gt; Void</code>. Annotate any closures you forward.</li>
        <li>Scaffolding plays well with SwiftUI's <code>@Environment(\.dismiss)</code>, <code>@Environment(\.scenePhase)</code>, <code>@Environment(\.openURL)</code>, etc. — those are native environment values that don't conflict with the coordinator injection.</li>
        <li>Scaffolding <strong>does</strong> conflict with anything that introduces another <code>NavigationStack</code> (or <code>NavigationView</code>, <code>NavigationSplitView</code>) inside a flow's view tree.</li>
      </ul>
    </section>

    <section id="tldr" class="sec">
      <h2>TL;DR for code generation</h2>
      <p>When asked to add navigation to a Scaffolding project:</p>
      <ol class="steps">
        <li>
          <strong>Don't generate <code>NavigationStack</code>,
          <code>NavigationView</code>, or
          <code>NavigationSplitView</code></strong> anywhere inside a
          <code>FlowCoordinatable</code>'s view hierarchy.
        </li>
        <li>
          Decide push vs. modal vs. root-swap, then pick
          <code>route(to:)</code> / <code>present(_:as:)</code> /
          <code>setRoot(_:)</code>.
        </li>
        <li>
          For modals, decide view-only vs. sub-flow:
          <ul class="bullets">
            <li>View-only → SwiftUI native <code>.sheet(item:)</code>.</li>
            <li>Sub-flow → <code>present(_:as:)</code> with a child coordinator.</li>
          </ul>
        </li>
        <li>
          New routes go on the coordinator as functions returning
          <code>some View</code>, <code>any Coordinatable</code>, or a
          tab tuple. Add the function — the macro generates the case.
        </li>
        <li>
          Views read the coordinator from
          <code>@Environment(MyCoordinator.self)</code> and call methods
          on it. Views never store path or sheet booleans for
          flow-driven navigation.
        </li>
        <li>
          Cross-coordinator results are delivered by the presenter
          installing an <code>onComplete</code> callback at construction
          time; the presented coordinator calls the callback then
          <code>dismissCoordinator()</code>.
        </li>
      </ol>
      <p class="sub">
        If you can't figure out which coordinator should own a
        destination, the answer is usually "the closest existing one" —
        don't invent new coordinator types just to host one route.
      </p>
    </section>

    <footer class="next">
      <h2>Keep reading</h2>
      <p>
        The same patterns documented here are demonstrated live in the
        landing page playground, and surfaced symbol-by-symbol in the
        API reference.
      </p>
      <p>
        <a href={`${base}/docs`}>Library overview →</a>
        &nbsp;·&nbsp;
        <a href={`${base}/docs/api`}>API reference →</a>
        &nbsp;·&nbsp;
        <a href={`${base}/docs/tutorial`}>Tutorial →</a>
      </p>
    </footer>
  </article>
</main>

<style>
  /* Shared docs chrome lives in `$lib/styles/docs.css`. Below: agent-specific bits. */

  .lede strong { color: var(--fg); font-weight: 500; }

  /* Copy-as-Markdown action row. Sits between the thesis and the meta
     line so it's the second-most-prominent thing in the hero. */
  .actions {
    margin: 0.25rem 0 0;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.85rem 1rem;
  }

  .copy-btn {
    appearance: none;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 0.55rem;
    padding: 0.55rem 0.95rem;
    font-family: var(--font-mono);
    font-size: 12.5px;
    letter-spacing: 0.02em;
    color: var(--fg);
    background: var(--surface);
    border: 1px solid var(--line);
    border-radius: 6px;
    line-height: 1;
    transition: background-color 140ms ease, border-color 140ms ease,
                color 140ms ease, transform 100ms ease;
  }
  .copy-btn:hover {
    border-color: color-mix(in srgb, var(--fg) 35%, transparent);
    background: color-mix(in srgb, var(--fg) 6%, var(--bg));
  }
  .copy-btn:active { transform: translateY(1px); }
  .copy-btn:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }
  .copy-btn.is-copied {
    color: var(--syn-ty);
    border-color: color-mix(in srgb, var(--syn-ty) 45%, transparent);
    background: color-mix(in srgb, var(--syn-ty) 8%, transparent);
  }
  .copy-btn.is-error {
    color: var(--syn-kw);
    border-color: color-mix(in srgb, var(--syn-kw) 45%, transparent);
    background: color-mix(in srgb, var(--syn-kw) 8%, transparent);
  }

  .copy-icon {
    font-family: var(--font-mono);
    font-size: 13px;
    line-height: 1;
    width: 1ch;
    text-align: center;
  }
  .copy-label { line-height: 1; }

  .raw-link {
    font-family: var(--font-mono);
    font-size: 12.5px;
    color: var(--muted);
    text-decoration: none;
    border-bottom: 1px solid color-mix(in srgb, var(--fg) 18%, transparent);
    transition: color 140ms ease, border-color 140ms ease;
  }
  .raw-link:hover {
    color: var(--fg);
    border-bottom-color: var(--fg);
  }
  .raw-link code {
    font-family: var(--font-mono);
    font-size: inherit;
    color: inherit;
    background: transparent;
    border: 0;
    padding: 0;
  }

  /* Thesis — opening manifesto using the syn-ty accent so it reads as
     the central idea, distinct from the warning-flavored caveats. */
  .thesis {
    display: grid;
    grid-template-columns: 90px 1fr;
    gap: 1rem;
    padding: 0.95rem 1.05rem;
    margin: 0.25rem 0 0;
    border: 1px solid color-mix(in srgb, var(--syn-ty) 35%, transparent);
    border-radius: 6px;
    background: color-mix(in srgb, var(--syn-ty) 5%, transparent);
  }
  @media (max-width: 540px) {
    .thesis { grid-template-columns: 1fr; gap: 0.4rem; }
  }
  .thesis-tag {
    align-self: start;
    justify-self: start;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--syn-ty);
    padding: 0.2rem 0.55rem;
    border-radius: 999px;
    border: 1px solid currentColor;
    background: color-mix(in srgb, var(--syn-ty) 8%, transparent);
    line-height: 1;
    margin-top: 0.1rem;
  }
  .thesis p {
    margin: 0;
    font-size: 13.5px;
    line-height: 1.65;
    color: color-mix(in srgb, var(--fg) 80%, transparent);
  }
  .thesis p strong { color: var(--fg); font-weight: 500; }

  /* Rule lists / Caveat callouts / Mistake cards live in
     $lib/docs/{RuleList,Rule,Caveat,MistakeCard}.svelte.

     `.bullets`, `.steps`, `.table-wrap` / table chrome, `.ascii`, and
     `.next` chrome live in $lib/styles/docs.css. */
  .steps .bullets { margin: 0.4rem 0 0; }
</style>
