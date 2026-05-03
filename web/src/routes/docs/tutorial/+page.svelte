<script>
  import { base } from '$app/paths';
  import CodeBlock from '$lib/CodeBlock.svelte';
  import ScrollProgress from '$lib/ScrollProgress.svelte';
  import FlowSim from '$lib/FlowSim.svelte';
  import {
    CODE_APP_INITIAL,
    CODE_COORD_EMPTY,
    CODE_COORD_HOME,
    CODE_COORD_DETAIL,
    CODE_COORD_SETTINGS,
    CODE_HOME_VIEW,
    CODE_DETAIL_VIEW,
    CODE_SETTINGS_VIEW,
    CODE_HOME_NAV,
    CODE_DETAIL_NAV,
    CODE_COORD_FINAL,
    CODE_HOME_SHEET,
    CODE_APP_FINAL
  } from '$lib/code/tutorial.js';

  const SECTIONS = [
    { id: 'setup',       label: 'Set up' },
    { id: 'coordinator', label: 'Coordinator' },
    { id: 'views',       label: 'Views' },
    { id: 'navigation',  label: 'Navigation' },
    { id: 'sheet',       label: 'Sheet' },
    { id: 'wire',        label: 'Wire up' }
  ];
</script>

<ScrollProgress sections={SECTIONS} />

<main class="docs">
  <article class="article">
    <header class="hero">
      <p class="eyebrow">Tutorial · 25 minutes</p>
      <h1>Your first Scaffolding project.</h1>
      <p class="lede">
        Build a three-screen iOS app — list, detail, and settings — using
        a single <code>FlowCoordinatable</code>. By the end you'll have
        push navigation, a sheet, and a coordinator that the macro
        generates routes for automatically.
      </p>
    </header>

    <section id="setup" class="sec">
      <h2><span class="step-num">01</span> Set up the project</h2>
      <p>
        Create a new iOS App project in Xcode. Choose <strong>SwiftUI</strong>
        for the interface and name it <strong>ScaffoldingDemo</strong>.
      </p>
      <p>
        Add Scaffolding via <em>File → Add Package Dependencies</em>, enter
        <code>https://github.com/dotaeva/scaffolding.git</code>, and add
        the <code>Scaffolding</code> library to your app target.
      </p>
      <CodeBlock code={CODE_APP_INITIAL} label="ScaffoldingDemoApp.swift" />
    </section>

    <section id="coordinator" class="sec">
      <h2><span class="step-num">02</span> Create your coordinator</h2>
      <p>
        Define a <code>FlowCoordinatable</code> that manages navigation
        between three screens — Home, Detail, and Settings. Mark it
        <code>@Scaffoldable @Observable</code>; the macro inspects each
        function and generates the type-safe <code>Destinations</code>
        enum at compile time.
      </p>
      <p>
        Start with an empty class and a <code>FlowStack</code> rooted at
        <code>.home</code> — a case the macro will generate from the
        <code>home()</code> function you add next.
      </p>
      <CodeBlock code={CODE_COORD_EMPTY} label="AppCoordinator.swift · empty" />

      <p>
        Add a <code>home()</code> function that returns
        <code>some View</code>. This becomes the stack's root destination
        and the macro generates a <code>.home</code> enum case from the
        function name.
      </p>
      <CodeBlock code={CODE_COORD_HOME} label="AppCoordinator.swift · home" />

      <p>
        Add a <code>detail(title:)</code> function with a parameter — the
        macro generates a <code>.detail(title:)</code> enum case with a
        matching associated value.
      </p>
      <CodeBlock code={CODE_COORD_DETAIL} label="AppCoordinator.swift · detail" />

      <p>
        Add <code>settings()</code> to round out the routes. You now have
        three: <code>.home</code>, <code>.detail(title:)</code>, and
        <code>.settings</code> — generated automatically.
      </p>
      <CodeBlock code={CODE_COORD_SETTINGS} label="AppCoordinator.swift · settings" />
    </section>

    <section id="views" class="sec">
      <h2><span class="step-num">03</span> Build the views</h2>
      <p>
        Each screen is a regular SwiftUI view that resolves its
        coordinator via <code>@Environment</code> — Scaffolding injects
        every coordinator in the hierarchy automatically.
      </p>
      <CodeBlock code={CODE_HOME_VIEW}     label="HomeView.swift" />
      <CodeBlock code={CODE_DETAIL_VIEW}   label="DetailView.swift" />
      <CodeBlock code={CODE_SETTINGS_VIEW} label="SettingsView.swift" />
      <p class="sub">
        <code>SettingsView</code> calls
        <code>coordinator.dismissCoordinator()</code> to dismiss itself —
        because it'll be the root of a presented modal coordinator, this
        removes the entire sheet.
      </p>
    </section>

    <section id="navigation" class="sec">
      <h2><span class="step-num">04</span> Add push navigation</h2>
      <p>
        Wire up navigation between screens. Call <code>route(to:)</code>
        on the coordinator to push a destination, and <code>pop()</code>
        to go back programmatically (the system back button works
        automatically — this is just to demonstrate the API).
      </p>
      <CodeBlock code={CODE_HOME_NAV}   label="HomeView.swift · push" />
      <CodeBlock code={CODE_DETAIL_NAV} label="DetailView.swift · pop" />
    </section>

    <section id="sheet" class="sec sim-side">
      <div class="prose">
        <h2><span class="step-num">05</span> Present a sheet</h2>
        <p>
          Replace the placeholder views with the real ones, then add a
          toolbar button to <code>HomeView</code> that presents settings as
          a sheet. Use <code>present(_:as:)</code> — <code>route(to:)</code>
          is push-only.
        </p>
        <CodeBlock code={CODE_COORD_FINAL} label="AppCoordinator.swift · final" />
        <CodeBlock code={CODE_HOME_SHEET}  label="HomeView.swift · sheet" />
        <p class="sub">
          Pass <code>.fullScreenCover</code> in place of <code>.sheet</code>
          for a full-screen modal. Both live in the same
          <code>FlowStack.destinations</code> array as the pushed
          destinations.
        </p>
        <p>
          With everything wired, this is what the user gets — push a planet,
          tap the gear for settings, dismiss to come back:
        </p>
      </div>
      <aside class="sim-col" aria-label="Tutorial result simulation">
        <FlowSim
          coordName="AppCoordinator"
          root={{ title: 'Planets', list: ['Mercury', 'Venus', 'Earth', 'Mars'] }}
          actions={[
            { code: 'route(to: .detail(title: "Earth"))',
              fn: (c) => c.push({ title: 'Earth', body: 'Detail.' }) },
            { code: 'present(.settings, as: .sheet)',
              fn: (c) => c.present({ title: 'Settings', list: ['Notifications', 'Privacy'] }, 'sheet') },
            { code: 'pop()',                      fn: (c) => c.pop() },
            { code: 'dismissCoordinator()',
              accent: true,
              fn: (c) => c.dismiss() }
          ]}
        />
      </aside>
    </section>

    <section id="wire" class="sec">
      <h2><span class="step-num">06</span> Wire up the app</h2>
      <p>
        Connect the coordinator to your app entry point. Read the
        <code>coordinator.view</code> property inside
        <code>WindowGroup</code> — it's a computed property (no
        parentheses) that renders the entire navigation hierarchy as a
        SwiftUI view.
      </p>
      <CodeBlock code={CODE_APP_FINAL} label="ScaffoldingDemoApp.swift · final" />
      <p>
        Build and run. You'll see a list of planets — tap one to push the
        detail screen, tap the gear to present settings as a sheet, tap
        <strong>Done</strong> to dismiss it.
      </p>
    </section>

    <footer class="next">
      <h2>That's it.</h2>
      <p>
        From here you can experiment with the
        <a href={`${base}/docs/api`}>API reference</a>, browse the
        <a href={`${base}/`}>interactive playground</a>, or jump straight
        into your own app.
      </p>
    </footer>
  </article>
</main>

<style>
  .docs {
    position: relative;
    z-index: 1;
    padding: clamp(2.5rem, 6vw, 4rem) 0 clamp(3rem, 6vw, 4rem);
  }

  .article {
    max-width: 960px;
    margin: 0 auto;
    padding: 0 clamp(1.25rem, 3.5vw, 2rem);
  }

  .hero {
    border-bottom: 1px solid var(--line-soft);
    padding-bottom: clamp(2rem, 5vw, 3rem);
    margin-bottom: clamp(2rem, 5vw, 3rem);
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
  }
  .eyebrow {
    margin: 0;
    font-size: 11px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--muted);
  }
  .hero h1 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: clamp(1.75rem, 4vw, 2.5rem);
    font-weight: 500;
    line-height: 1.1;
    letter-spacing: -0.025em;
    color: var(--fg);
  }
  .lede {
    margin: 0;
    font-size: 14.5px;
    line-height: 1.65;
    color: color-mix(in srgb, var(--fg) 75%, transparent);
    max-width: 60ch;
  }

  .sec {
    margin: 0 0 clamp(4rem, 8vw, 6rem);
    padding-top: clamp(2.5rem, 5vw, 4rem);
    border-top: 1px solid var(--line-soft);
    scroll-margin-top: 5.5rem;
  }
  .sec:first-of-type {
    margin-top: 0;
    padding-top: 0;
    border-top: 0;
  }

  /* Sim-side: prose on the left, simulator on the right.
     Threshold matches the ScrollProgress full-label breakpoint so the
     sim never extends into the rail's territory on the right. */
  .sec.sim-side {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    column-gap: clamp(1.5rem, 3vw, 2.5rem);
    align-items: start;
    margin-right: clamp(-180px, calc((1380px - 100vw) / 2), 0px);
  }
  .sim-side .prose { min-width: 0; }
  .sim-side .sim-col {
    position: sticky;
    top: 6rem;
    align-self: start;
  }
  @media (max-width: 880px) {
    .sec.sim-side {
      grid-template-columns: 1fr;
      margin-right: 0;
    }
    .sim-side .sim-col {
      position: static;
      justify-self: center;
      margin-top: 0.75rem;
    }
  }
  .sec h2 {
    margin: 0 0 1rem;
    font-family: var(--font-mono);
    font-size: clamp(1.2rem, 2.4vw, 1.55rem);
    font-weight: 500;
    letter-spacing: -0.015em;
    color: var(--fg);
    display: flex;
    align-items: baseline;
    gap: 0.85rem;
  }
  .step-num {
    font-size: 11px;
    letter-spacing: 0.16em;
    color: var(--dim);
    flex-shrink: 0;
  }
  .sec p {
    margin: 0 0 1rem;
    font-size: 14px;
    line-height: 1.7;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .sec p.sub {
    color: color-mix(in srgb, var(--fg) 60%, transparent);
    font-size: 13.5px;
    border-left: 2px solid var(--line);
    padding-left: 0.85rem;
  }
  .sec p strong {
    color: var(--fg);
    font-weight: 500;
  }
  .sec p em {
    color: var(--fg);
    font-style: italic;
  }
  .sec :global(.block) {
    margin: 0.75rem 0 1rem;
  }

  .sec code,
  .lede code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.4em;
    border-radius: 3px;
  }

  .next {
    margin-top: clamp(2rem, 5vw, 3rem);
    padding-top: clamp(2rem, 5vw, 3rem);
    border-top: 1px solid var(--line-soft);
  }
  .next h2 {
    margin: 0 0 0.75rem;
    font-family: var(--font-mono);
    font-size: clamp(1.05rem, 1.8vw, 1.25rem);
    font-weight: 500;
    color: var(--fg);
  }
  .next p {
    font-size: 14px;
    line-height: 1.7;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .next a {
    color: var(--fg);
    text-decoration: none;
    border-bottom: 1px solid color-mix(in srgb, var(--fg) 30%, transparent);
    transition: border-color 140ms ease;
  }
  .next a:hover {
    border-bottom-color: var(--fg);
  }
</style>
