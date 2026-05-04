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
        <code>SettingsView</code> calls <code>coordinator.pop()</code>
        to dismiss itself — modals share the same
        <code>FlowStack.destinations</code> array as pushes, so popping
        the topmost destination removes the sheet.
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
            { code: 'pop()', accent: true, fn: (c) => c.pop() }
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
  /* Shared docs chrome lives in `$lib/styles/docs.css`. Tutorial-specific
     overrides + the sim-side layout are below. */

  .docs { padding-top: clamp(2.5rem, 6vw, 4rem); }
  .hero { gap: 0.85rem; }
  .hero h1 { font-size: clamp(1.75rem, 4vw, 2.5rem); line-height: 1.1; }
  .lede { font-size: 14.5px; }
  .sec { scroll-margin-top: 5.5rem; }

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
  /* The tutorial's section heading is inline-flex so the step number
     sits on the same baseline as the `<h2>` label. */
  .sec h2 {
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

  /* Tutorial uses a quoted-style "sub" — leave the global rule in place
     and add the left border. */
  .sec p.sub {
    border-left: 2px solid var(--line);
    padding-left: 0.85rem;
  }

  /* CodeBlock spacing inside tutorial sections is a touch tighter. */
  .sec :global(.block) {
    margin: 0.75rem 0 1rem;
  }
</style>
