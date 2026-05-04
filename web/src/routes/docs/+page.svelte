<script>
  import { base } from '$app/paths';
  import CodeBlock from '$lib/CodeBlock.svelte';
  import ScrollProgress from '$lib/ScrollProgress.svelte';
  import FlowSim from '$lib/FlowSim.svelte';
  import { GITHUB_URL, DOCC_URL } from '$lib/links.js';
  import Caveat from '$lib/docs/Caveat.svelte';
  import TopicCard from '$lib/docs/TopicCard.svelte';
  import {
    CODE_MOUNT_APP,
    CODE_MOUNT_PREVIEW,
    CODE_FLOW,
    CODE_FLOW_NAV,
    CODE_TAB,
    CODE_TAB_API,
    CODE_ROOT,
    CODE_ROOT_SET,
    CODE_ENV,
    CODE_ENV_DEST,
    CODE_ADAPTIVE_BAR,
    CODE_PREVIEW_BAD,
    CODE_PREVIEW_OK,
    CODE_COMPOSE,
    CODE_DEEPLINK,
    CODE_DEEPLINK_URL,
    CODE_CUSTOMIZE,
    CODE_DISMISS_PARENT,
    CODE_DISMISS_CHILD,
    CODE_DISMISS_VIEWS,
    CODE_NATIVE_VIEW,
    CODE_NATIVE_ENUM,
    CODE_SCAFFOLDING
  } from '$lib/code/docs.js';

  // Selected native-flavor for the comparison: 'view' (NavigationLink-driven)
  // or 'enum' (central typed-enum path).
  let nativeMode = $state('view');

  const SECTIONS = [
    { id: 'overview',   label: 'Overview' },
    { id: 'how',        label: 'How it works' },
    { id: 'mount',      label: 'Mounting' },
    { id: 'previews',   label: 'Previews' },
    { id: 'flow',       label: 'Flow' },
    { id: 'tab',        label: 'Tab' },
    { id: 'root',       label: 'Root' },
    { id: 'env',        label: 'Environment' },
    { id: 'composing',  label: 'Composing' },
    { id: 'deep-link',  label: 'Deep linking' },
    { id: 'dismiss',    label: 'Dismissing' },
    { id: 'customize',  label: 'Customize' },
    { id: 'vs-native',  label: 'vs NavigationStack' },
    { id: 'philosophy', label: 'When to use what' }
  ];

</script>

<ScrollProgress sections={SECTIONS} />

<main class="docs">
  <article class="article">
    <header class="hero">
      <p class="eyebrow">Documentation</p>
      <h1>Meet Scaffolding.</h1>
      <p class="lede">
        Learn how Scaffolding turns plain Swift functions into type-safe
        navigation routes — and why you might never write a destination
        enum again.
      </p>
      <p class="meta">
        Companion to the hosted <a href={DOCC_URL} target="_blank" rel="noopener noreferrer">DocC archive</a>.
        Source on <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer">GitHub</a>.
      </p>
    </header>

    <section id="overview" class="sec">
      <h2>Overview</h2>
      <p>
        Navigation in SwiftUI is powerful, but as apps grow it creates a
        familiar set of problems: navigation logic is scattered across views,
        destination enums must be maintained by hand, and deep linking
        requires plumbing that touches every layer of the app.
      </p>
      <p>
        Scaffolding solves this by moving navigation into <strong>coordinators</strong> —
        observable classes whose functions <em>are</em> the routes.
        The <code>@Scaffoldable</code> macro reads those functions at compile
        time and generates a <code>Destinations</code> enum automatically.
        You navigate by calling <code>route(to:)</code> to push or
        <code>present(_:as:)</code> to show a modal, and Scaffolding handles
        the rest using SwiftUI's native navigation stack, sheets, and
        full-screen covers under the hood.
      </p>
    </section>

    <section id="how" class="sec">
      <h2>How it works</h2>
      <ol class="steps">
        <li>Create a class and mark it <code>@Scaffoldable @Observable</code>.</li>
        <li>Conform to one of three coordinator protocols.</li>
        <li>Write functions — each one becomes a route.</li>
        <li>The macro generates a <code>Destinations</code> enum from those functions.</li>
        <li>
          Push with <code>coordinator.route(to: .someDestination)</code> or
          present a modal with <code>coordinator.present(.someDestination, as: .sheet)</code>.
        </li>
      </ol>

      <h3>Return types that become routes</h3>
      <p class="sub">
        The macro decides what kind of destination to generate based on the
        function's return type:
      </p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Return type</th><th>What it creates</th><th>Typical use</th></tr>
          </thead>
          <tbody>
            <tr><td><code>some View</code></td><td>A view destination</td><td>Simple screens</td></tr>
            <tr><td><code>any Coordinatable</code></td><td>A child coordinator</td><td>Nested navigation flows</td></tr>
            <tr><td><code>(any Coordinatable, some View)</code></td><td>Coordinator + tab label</td><td>Tab bar tabs</td></tr>
            <tr><td><code>(some View, some View)</code></td><td>View + tab label</td><td>View-only tabs</td></tr>
          </tbody>
        </table>
      </div>
      <p class="sub">
        Functions marked with <code>@ScaffoldingIgnored</code> or returning
        other types are skipped.
      </p>
    </section>

    <section id="mount" class="sec">
      <h2>Mounting the coordinator</h2>
      <p>
        A coordinator is a plain Swift class — it doesn't render
        anything until you ask it to. Hold the root coordinator in
        SwiftUI <code>@State</code> at the app entry point, then read
        its <code>view</code> property to mount its full navigation
        hierarchy as a SwiftUI view:
      </p>
      <CodeBlock code={CODE_MOUNT_APP} label="MyApp.swift" />
      <p>
        <code>view</code> is a <strong>computed property</strong>, not
        a function — there are no parentheses. SwiftUI re-renders
        whenever the coordinator's <code>@Observable</code> state
        changes, so the navigation stack, presented modals, and
        injected child coordinators all stay in sync without any
        further wiring.
      </p>
      <p class="sub">
        The same property works in <code>#Preview</code> — instantiate
        the coordinator and read <code>.view</code> directly:
      </p>
      <CodeBlock code={CODE_MOUNT_PREVIEW} label="HomeCoordinator preview" />
      <p class="sub">
        Only the <strong>root</strong> coordinator needs an explicit
        <code>@State</code> mount. Child coordinators returned from
        route functions (<code>any Coordinatable</code>) are
        instantiated by the parent and their views are rendered
        automatically when the parent routes to them.
      </p>
    </section>

    <section id="previews" class="sec">
      <h2>Previewing coordinator code</h2>
      <p>
        SwiftUI's <code>#Preview</code> macro and Scaffolding's
        <code>@Scaffoldable</code> macro both run at compile time, but
        they don't see each other the way the runtime does. A handful
        of preview-only papercuts are easy to chase as bugs if you're
        not expecting them.
      </p>

      <Caveat tag="Caveat 1">
        <p>
          <strong>The macro-generated routes can't seed a custom
          initial state in <code>#Preview</code>.</strong>
        </p>
        <p>
          The <code>Destinations</code> enum is emitted as a member
          of the coordinator type, and the stack is constructed from
          a literal root case
          (<code>FlowStack&lt;Home&gt;(root: .home)</code>). There's
          no synthesised <code>init(initialRoute:)</code> you can
          call — passing
          <code>HomeCoordinator(initialRoute: .detail)</code> doesn't
          compile. Preview the coordinator at its real root, or
          render the deeper screen directly (next caveat).
        </p>
      </Caveat>

      <CodeBlock code={CODE_PREVIEW_BAD} label="Won't compile" />
      <CodeBlock code={CODE_PREVIEW_OK}  label="Two patterns that do work" />

      <Caveat tag="Caveat 2">
        <p>
          <strong>Views that use
          <code>@Environment(SomeCoordinator.self)</code> need an
          explicit injection.</strong>
        </p>
        <p>
          At runtime Scaffolding installs each coordinator into the
          environment of every view it manages. In
          <code>#Preview</code> you usually render a view by itself,
          outside the coordinator's view chain — so the environment
          is missing and the lookup falls back (or crashes,
          depending on Swift version). Pass the coordinator
          yourself: <code>SomeScreen().environment(HomeCoordinator())</code>.
        </p>
      </Caveat>

      <Caveat tag="Caveat 3">
        <p>
          <strong>The <code>\.destination</code> environment value
          doesn't fully reflect runtime in previews.</strong>
        </p>
        <p>
          Scaffolding sets <code>\.destination</code> when it
          materialises a destination through a route or modal
          presentation. A view rendered alone in
          <code>#Preview</code> isn't materialised through that
          path, so <code>destination.routeType</code>,
          <code>destination.presentationType</code>, and
          <code>destination.meta</code> read as their default
          (<code>.root</code>) — not the value you'd see when the
          screen is actually pushed or presented.
        </p>
        <p>
          Don't gate critical preview rendering behind
          <code>destination.routeType</code> alone. The adaptive
          top-bar pattern <a href="#env">below</a> is preview-safe
          because it falls through to a benign placeholder when the
          value is <code>.root</code>.
        </p>
      </Caveat>
    </section>

    <section id="flow" class="sec sim-side">
      <div class="prose">
        <h2>FlowCoordinatable — Navigation stacks</h2>
        <p>
          <code>FlowCoordinatable</code> manages a push/pop navigation stack
          with support for sheet and full-screen-cover modals. This is the
          coordinator you'll use most often.
        </p>
        <CodeBlock code={CODE_FLOW} label="HomeCoordinator.swift" />
        <p>
          Push with <code>route(to:)</code>, present a modal with
          <code>present(_:as:)</code>:
        </p>
        <CodeBlock code={CODE_FLOW_NAV} label="Navigation" />
        <p>
          <code>present(_:as:)</code> is available on every coordinator type, so
          a <code>TabCoordinatable</code> or <code>RootCoordinatable</code> can
          host a modal directly without delegating to a child flow.
        </p>
        <p>
          Go back with <code>pop()</code>, <code>popToRoot()</code>, or pop to
          a specific destination with <code>popToFirst(_:)</code> and
          <code>popToLast(_:)</code>.
        </p>
      </div>
      <aside class="sim-col" aria-label="Live FlowCoordinator simulation">
        <FlowSim
          coordName="HomeCoordinator"
          root={{ title: 'Planets', list: ['Mercury', 'Venus', 'Earth', 'Mars'] }}
          actions={[
            { code: 'route(to: .detail(item: "Earth"))',
              fn: (c) => c.push({ title: 'Earth', body: 'Detail screen.' }) },
            { code: 'present(.settings, as: .sheet)',
              fn: (c) => c.present({ title: 'Settings', list: ['Notifications', 'Privacy'] }, 'sheet') },
            { code: 'pop()',          fn: (c) => c.pop() },
            { code: 'popToRoot()',    fn: (c) => c.popToRoot() }
          ]}
          showState
        />
      </aside>
    </section>

    <section id="tab" class="sec">
      <h2>TabCoordinatable — Tab bars</h2>
      <p>
        <code>TabCoordinatable</code> manages a tab bar where each tab can
        contain its own coordinator with an independent navigation stack.
        Each function returns a tuple of the tab's content and its label.
      </p>
      <CodeBlock code={CODE_TAB} label="MainTabCoordinator.swift" />
      <p>Select tabs programmatically, add or remove them at runtime:</p>
      <CodeBlock code={CODE_TAB_API} label="Tab API" />
      <p class="sub">
        On iOS&nbsp;18+ you can also include a <code>TabRole</code> as a third
        tuple element to use the new tab bar API.
      </p>
    </section>

    <section id="root" class="sec">
      <h2>RootCoordinatable — State switches</h2>
      <p>
        <code>RootCoordinatable</code> holds a single root destination that
        can be swapped atomically. This is ideal for authentication flows,
        onboarding gates, or any state where the entire view hierarchy
        needs to change.
      </p>
      <CodeBlock code={CODE_ROOT} label="AppCoordinator.swift" />
      <p>One call flips the app state:</p>
      <CodeBlock code={CODE_ROOT_SET} label="Root swap" />
    </section>

    <section id="env" class="sec">
      <h2>Environment access</h2>
      <p>
        Scaffolding injects every coordinator in the hierarchy into the
        SwiftUI environment. Views access their nearest coordinator with
        <code>@Environment</code>:
      </p>
      <CodeBlock code={CODE_ENV} label="DetailView.swift" />
      <p>
        If multiple coordinators of the same type exist in the view tree,
        the one closest to the current view is used.
      </p>
      <p>
        You can also inspect how the current view was presented by reading
        the <code>destination</code> environment value:
      </p>
      <CodeBlock code={CODE_ENV_DEST} label="Destination metadata" />

      <h3>A reusable, route-aware top bar</h3>
      <p>
        Because every destination Scaffolding materialises sets
        <code>\.destination</code>, a single SwiftUI view can read the
        routing metadata and adapt itself to context. The same bar
        renders a back chevron when the screen is pushed, a
        <strong>Close</strong> when it's presented as a sheet or
        full-screen cover, and nothing leading when it's the root —
        without the bar knowing anything about the surrounding flow.
      </p>
      <CodeBlock code={CODE_ADAPTIVE_BAR} label="AdaptiveTopBar.swift · reusable" />
      <p class="sub">
        The same trick generalises to any chrome that should react to
        routing context — toolbar items, breadcrumb labels, swipe
        affordances. <code>destination.meta</code> lets you switch on
        the specific destination case (the macro generates a
        <code>Meta</code> enum alongside <code>Destinations</code>),
        which is useful when a screen renders different layouts
        depending on which route reached it.
      </p>
    </section>

    <section id="composing" class="sec">
      <h2>Composing coordinators</h2>
      <p>
        Coordinators nest naturally. A <code>FlowCoordinatable</code> can
        route to a child coordinator (returned as <code>any Coordinatable</code>),
        which can itself be any coordinator type. A typical app hierarchy
        looks like this:
      </p>
      <pre class="ascii"><code>{`AppCoordinator (Root)
├── LoginCoordinator (Flow)
└── MainTabCoordinator (Tab)
    ├── HomeCoordinator (Flow)
    │   └── DetailCoordinator (Flow)
    └── ProfileCoordinator (Flow)`}</code></pre>
      <p>
        A child coordinator destination can take parameters — useful for
        delivering a result back via a callback, the way the demo's
        <code>LoginCoordinator</code> works:
      </p>
      <CodeBlock code={CODE_COMPOSE} label="Composition with onComplete" />
    </section>

    <section id="deep-link" class="sec">
      <h2>Deep linking</h2>
      <p>
        Deep linking — landing the user on a specific screen straight
        from a cold launch — is where the coordinator model
        especially shines. Every navigation method that resolves a
        child coordinator
        (<code>route</code>, <code>present</code>, <code>setRoot</code>,
        <code>appendTab</code>, <code>insertTab</code>,
        <code>popToFirst</code>, <code>popToLast</code>,
        <code>selectFirstTab</code>, <code>selectLastTab</code>,
        <code>select(index:)</code>, <code>select(id:)</code>) ships
        an overload constrained to <code>{'<T: Coordinatable>'}</code>
        with a trailing closure. The closure fires after the
        route lands, receiving a typed reference to the freshly
        resolved child:
      </p>
      <CodeBlock code={CODE_DEEPLINK} label="AppCoordinator · openProfile(userId:)" />
      <p>
        Each step of the chain hands the next step a typed
        coordinator, so you can walk the tree
        — root → tab → flow → pushed screen — without storing handles
        anywhere or doing any runtime casting at the call site. The
        same pattern composes for any depth, and the typed overload
        is opt-in: when you don't need the child handle, the regular
        <code>route(to:)</code> / <code>setRoot(_:)</code> still works
        without a trailing closure.
      </p>
      <p>Hook the entry point to a URL, push notification, or quick action:</p>
      <CodeBlock code={CODE_DEEPLINK_URL} label="MyApp · onOpenURL" />
      <p class="sub">
        The typed closure only fires if the resolved child can be
        cast to <code>T</code>. Pick a concrete coordinator type that
        matches the destination's return signature — for an
        <code>any Coordinatable</code> route returning a
        <code>ProfileCoordinator</code>, the closure parameter must
        be <code>ProfileCoordinator</code>.
      </p>
    </section>

    <section id="dismiss" class="sec sim-side">
      <div class="prose">
        <h2>Dismissing a flow</h2>
        <p>
          <code>pop()</code> and <code>dismissCoordinator()</code> are
          not the same call. <code>pop()</code> removes a single pushed
          screen from the current flow's stack.
          <code>dismissCoordinator()</code> removes the
          <strong>entire coordinator</strong> from its parent —
          collapsing whatever sub-tree it owns (its root, every screen
          it has pushed, every modal it has presented) in one move.
        </p>
        <p>
          The difference shows up clearly in a nested flow. Below, an
          <code>AppCoordinator</code> presents a
          <code>LoginCoordinator</code> as a sheet. The login flow is
          itself two screens (<code>email</code> → <code>password</code>).
          When the user signs in on the password step, calling
          <code>dismissCoordinator()</code> closes the whole sheet at
          once — not just the password screen.
        </p>

        <CodeBlock code={CODE_DISMISS_PARENT} label="AppCoordinator.swift · presents the login flow" />
        <CodeBlock code={CODE_DISMISS_CHILD}  label="LoginCoordinator.swift · the nested flow" />
        <CodeBlock code={CODE_DISMISS_VIEWS}  label="Step views · pop() vs dismissCoordinator()" />

        <p class="sub">
          Drive the simulator on the right to see it: present the
          login sheet, push to the password step inside it, then
          compare <code>pop()</code> (one step back) to
          <code>dismissCoordinator()</code> (whole sheet closes,
          regardless of how deep you've pushed).
        </p>

        <Caveat tag="Watch out">
          <p>
            <strong>Calling <code>dismissCoordinator()</code> on the
            root coordinator is a no-op</strong> — there's no parent
            to remove it from. Save it for child coordinators that
            were pushed or presented.
          </p>
          <p>
            For a single-screen back button inside a flow, prefer
            <code>pop()</code> or SwiftUI's
            <code>@Environment(\.dismiss)</code>. Reach for
            <code>dismissCoordinator()</code> when the intent is
            "I'm done with this whole sub-flow," typically right
            after handing a result back through an
            <code>onComplete</code> callback.
          </p>
        </Caveat>
      </div>

      <aside class="sim-col" aria-label="Nested coordinator dismiss simulation">
        <FlowSim
          coordName="coordinator"
          root={{ title: 'Home' }}
          actions={[
            { code: 'present(.login(onComplete:), as: .sheet)',
              coord: 'AppCoordinator',
              hint: 'opens the login sheet',
              fn: (c) => c.present({ title: 'Email', body: 'Enter email' }, 'sheet'),
              disabled: (c) => c.modal !== null },
            { code: 'route(to: .password(email:))',
              coord: 'LoginCoordinator',
              hint: 'pushes the next step inside the sheet',
              fn: (c) => c.pushInModal({ title: 'Password', body: 'Enter password' }),
              disabled: (c) => c.modal === null || c.top?.pushType === 'modal-push' },
            { code: 'pop()',
              coord: 'LoginCoordinator',
              hint: 'one screen up — stays inside the sheet',
              fn: (c) => c.pop(),
              disabled: (c) => c.modal === null },
            { code: 'dismissCoordinator()',
              coord: 'LoginCoordinator',
              accent: true,
              hint: 'whole sheet closes, even from password',
              fn: (c) => c.dismiss(),
              disabled: (c) => c.modal === null }
          ]}
          showState
        />
      </aside>
    </section>

    <section id="customize" class="sec">
      <h2>Customizing views</h2>
      <p>
        Override <code>customize(_:)</code> on a coordinator to apply shared
        modifiers to every view it manages. Mark it with
        <code>@ScaffoldingIgnored</code> so the macro doesn't treat it as a
        route:
      </p>
      <CodeBlock code={CODE_CUSTOMIZE} label="Coordinator+customize" />
    </section>

    <section id="vs-native" class="sec">
      <h2>Compared to <code>NavigationStack(path:)</code></h2>
      <p>
        The same three-screen app — list, detail, settings sheet —
        written once with SwiftUI's <code>NavigationStack(path:)</code>
        and once with Scaffolding. The shape of the difference is the
        shape of the library's value.
      </p>

      <div class="compare-block">
        <header class="compare-head" data-flavor="native">
          <span class="compare-tag">SwiftUI</span>
          <span class="compare-title"><code>NavigationStack(path:)</code></span>
          <div class="compare-toggle" role="tablist" aria-label="Native variant">
            <button
              type="button"
              role="tab"
              aria-selected={nativeMode === 'view'}
              class:active={nativeMode === 'view'}
              onclick={() => (nativeMode = 'view')}
            >
              View-hosted
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={nativeMode === 'enum'}
              class:active={nativeMode === 'enum'}
              onclick={() => (nativeMode = 'enum')}
            >
              Typed enum
            </button>
          </div>
        </header>
        <CodeBlock
          code={nativeMode === 'view' ? CODE_NATIVE_VIEW : CODE_NATIVE_ENUM}
          label={nativeMode === 'view' ? 'ContentView · view-hosted' : 'ContentView · typed-enum path'}
        />
      </div>

      <p class="compare-vs" aria-hidden="true">↓ same thing, with Scaffolding</p>

      <div class="compare-block">
        <header class="compare-head" data-flavor="scaffolding">
          <span class="compare-tag">Scaffolding</span>
          <span class="compare-title"><code>FlowCoordinatable</code></span>
        </header>
        <CodeBlock code={CODE_SCAFFOLDING} label="HomeCoordinator.swift" />
      </div>

      <h3>What changes</h3>
      <ul class="diffs">
        <li>
          <strong>Path state moves out of the view.</strong>
          Native carries <code>@State path</code> and
          <code>@State showSettings</code> in <code>ContentView</code>;
          Scaffolding's coordinator owns the
          <code>FlowStack</code>, so views never store navigation state
          themselves.
        </li>
        <li>
          <strong>Pushes are explicit calls, not <code>NavigationLink</code>s.</strong>
          The native list couples the row to navigation through
          <code>NavigationLink(value:)</code>. With Scaffolding the row
          is a plain <code>Button</code> that calls
          <code>coordinator.route(to: .detail(item:))</code> — the view
          stays decoupled from how navigation happens.
        </li>
        <li>
          <strong>Modals don't need a binding.</strong>
          Native modals require a <code>@State Bool</code> and a
          <code>.sheet(isPresented:)</code> modifier on the view tree.
          Scaffolding presents from a method call —
          <code>coordinator.present(.settings, as: .sheet)</code> — and
          dismisses with <code>pop()</code>.
        </li>
        <li>
          <strong>Pop doesn't need a <code>@Binding</code>.</strong>
          The native <code>DetailView</code> takes
          <code>@Binding var path</code> so it can call
          <code>removeLast()</code>. Scaffolding's <code>DetailView</code>
          reads the coordinator from <code>@Environment</code> and just
          calls <code>pop()</code>.
        </li>
        <li>
          <strong>Type-safe destinations across modules.</strong>
          A heterogeneous <code>NavigationStack</code> path needs a
          custom enum and a <code>navigationDestination</code> per
          case, in <em>the view tree</em>. Scaffolding's macro
          generates the destination enum from your coordinator's
          functions, so a coordinator from another module slots in
          without touching any views.
        </li>
        <li>
          <strong>Coordinators compose.</strong>
          The native version is glued to
          <code>NavigationStack(path:)</code> — embedding it as a tab,
          presenting it modally, or driving it from another flow means
          re-plumbing the path bindings. A Scaffolding coordinator is a
          first-class value that any other coordinator can
          <code>route(to:)</code>, <code>present(_:as:)</code>, or hold
          as a tab.
        </li>
      </ul>
    </section>

    <section id="philosophy" class="sec">
      <h2>When to use what</h2>
      <p>
        Scaffolding exists to give <code>NavigationStack</code> the
        <strong>modularity</strong> it lacks — coordinators, child
        coordinators, and <code>route(to:)</code> that compose across
        module boundaries. That's the core value the library delivers.
      </p>
      <p>
        Modal presentations sit one level above that, and they have two
        flavors. The right tool depends on what's <em>inside</em> the
        modal:
      </p>

      <ul class="rules">
        <li>
          <span class="rule-tag">View-only</span>
          <span class="rule-body">
            Reach for SwiftUI's native <code>.sheet(item:)</code> /
            <code>.fullScreenCover(item:)</code> when the modal is a
            <em>single screen</em> — a confirmation, an info dialog, a
            simple form. Keep it native; the view-side modifier is
            lighter and avoids any coordinator overhead.
          </span>
        </li>
        <li>
          <span class="rule-tag">Sub-flow</span>
          <span class="rule-body">
            Use <code>present(_:as:)</code> when the modal is itself a
            <em>flow</em> — a Login coordinator with email → password →
            done, a Settings hierarchy, anything with its own
            navigation. The presented coordinator gets a parent
            reference, can call <code>dismissCoordinator()</code> on
            itself, and delivers results back through
            <code>onComplete</code> callbacks the parent installs at
            construction time.
          </span>
        </li>
      </ul>

      <p class="sub">
        Rule of thumb: <strong>if the modal contains navigation, make it
        a coordinator and <code>present</code>; if it's a single-page
        view, use SwiftUI's native modifier.</strong>
      </p>

      <Caveat>
        <p>
          <strong>Don't nest <code>NavigationStack</code> inside a
          flow.</strong>
        </p>
        <p>
          <code>FlowCoordinatable</code> <em>is</em> the
          <code>NavigationStack</code>, so putting another one inside
          any of its destination views breaks navigation — SwiftUI
          doesn't compose <code>NavigationStack</code>s with each
          other. The nested stack swallows the pushes that should
          belong to the parent flow, and the coordinator's
          <code>route(to:)</code> stops doing what you expect.
        </p>
        <p>
          If a screen genuinely needs its own navigation hierarchy,
          give it a child <code>FlowCoordinatable</code> instead —
          <code>route(to:)</code> a coordinator-typed destination, or
          <code>present(_:as:)</code> a sub-flow modally. Each
          coordinator boundary creates a fresh
          <code>NavigationStack</code>, which is the only configuration
          SwiftUI handles correctly.
        </p>
      </Caveat>
    </section>

    <footer class="next">
      <h2>Topics</h2>
      <p>
        More places to dig in — the symbol-by-symbol DocC archive, an
        in-site reference, the hands-on tutorial, and an opinionated
        guide for LLM coding agents working in this codebase:
      </p>
      <div class="topic-cards">
        <TopicCard
          href={DOCC_URL}
          external
          eyebrow="DocC · Generated"
          title="DocC archive ↗"
        >
          The full DocC website built from the in-source documentation —
          every public symbol with its declaration, parameters, and
          cross-links, served on GitHub Pages.
        </TopicCard>
        <TopicCard
          href={`${base}/docs/api`}
          eyebrow="Reference"
          title="API Reference →"
        >
          Every public protocol, type, and macro — grouped by purpose.
          Coordinator protocols, state containers, destinations, macros.
        </TopicCard>
        <TopicCard
          href={`${base}/docs/tutorial`}
          eyebrow="Tutorial · 25 min"
          title="Your first project →"
        >
          Build a three-screen iOS app — list, detail, settings sheet —
          from a blank Xcode project to a working coordinator.
        </TopicCard>
        <TopicCard
          href={`${base}/docs/agents`}
          eyebrow="Agent guide"
          title="For LLM coding agents →"
        >
          Best-practice reference for LLM coding agents.
          The no-nested-<code>NavigationStack</code> rule, the
          push/present/setRoot decision tree, separation-of-concerns
          patterns, and the mistakes to never generate.
        </TopicCard>
      </div>

      <p class="footnote">
        The <a href={`${base}/`}>landing page</a> also includes an
        interactive playground where you can drive a simulated coordinator
        hierarchy with the actual Scaffolding API.
      </p>
    </footer>
  </article>
</main>

<style>
  /* Shared docs chrome (.docs, .article, .hero, .eyebrow, .lede, .meta,
     .sec / .sec h2 / .sec h3 / .sec p / .sec code / .sec :global(.block),
     .next, .bullets, .steps, table, .ascii) lives in
     `$lib/styles/docs.css`. Below: page-specific tweaks only. */

  /* Sim-side sections break out of the article column on viewports that
     have room — but the threshold leaves space for the ScrollProgress
     rail (~210 px when labels show at ≥ 1340 viewport) so the sim and
     the rail don't overlap. The breakout caps at -180 so the sim stays
     well clear of the right-side rail even on huge displays. */
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

  /* ── "Compared to NavigationStack(path:)" stacked code blocks ──── */

  /* Each block runs the full article width so the code never gets
     squeezed into a half-column. The pairing is communicated by the
     "↓ same thing, with Scaffolding" hinge between them and the
     colored tag at the top of each block. */

  .compare-block {
    margin: 0.75rem 0 0.5rem;
  }

  .compare-head {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    margin: 0 0 0.5rem;
    padding: 0.3rem 0.7rem 0.3rem 0.55rem;
    border: 1px solid var(--line);
    border-radius: 999px;
    background: var(--surface);
    flex-wrap: wrap;
    max-width: 100%;
  }

  .compare-tag {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    line-height: 1;
    padding: 0.2rem 0.55rem;
    border-radius: 999px;
    color: var(--bg);
  }
  .compare-head[data-flavor='native']      .compare-tag { background: var(--syn-att); }
  .compare-head[data-flavor='scaffolding'] .compare-tag { background: var(--syn-ty); }

  .compare-title {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--fg);
  }
  .compare-title code {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--fg);
    background: transparent;
    border: 0;
    padding: 0;
  }

  .compare-vs {
    margin: 0.5rem 0 1.25rem;
    text-align: center;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
  }

  /* Native-variant toggle (View-hosted / Typed enum). Sits in the
     comparison header on the right of the title pill. */
  .compare-toggle {
    display: inline-flex;
    margin-left: auto;
    border: 1px solid var(--line);
    border-radius: 999px;
    overflow: hidden;
    background: var(--bg);
  }

  .compare-toggle button {
    font: inherit;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.06em;
    padding: 0.3rem 0.7rem;
    background: transparent;
    border: 0;
    color: var(--muted);
    cursor: pointer;
    transition: color 140ms ease, background-color 140ms ease;
  }

  .compare-toggle button:hover {
    color: var(--fg);
  }

  .compare-toggle button.active {
    background: color-mix(in srgb, var(--fg) 12%, var(--bg));
    color: var(--fg);
  }

  .compare-toggle button:focus-visible {
    outline: none;
    box-shadow: inset 0 0 0 2px color-mix(in srgb, var(--fg) 50%, transparent);
  }

  /* Differences bullet list. */
  .sec h3 {
    margin: 1.75rem 0 0.75rem;
    font-family: var(--font-mono);
    font-size: 12px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--dim);
    font-weight: 500;
  }

  .diffs {
    margin: 0 0 1rem;
    padding: 0;
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
  }
  .diffs li {
    position: relative;
    padding: 0.7rem 0.95rem 0.7rem 2.2rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
    font-size: 13.5px;
    line-height: 1.6;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .diffs li::before {
    content: '→';
    position: absolute;
    left: 0.95rem;
    top: 0.7rem;
    color: var(--muted);
    font-family: var(--font-mono);
    font-size: 13px;
  }
  .diffs li strong {
    color: var(--fg);
    font-weight: 500;
  }
  .diffs li em { color: var(--fg); font-style: italic; }
  .diffs li code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

  /* ── "When to use what" rule list ─────────────────────────────────── */

  .rules {
    margin: 0.5rem 0 1.25rem;
    padding: 0;
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
  }

  .rules li {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: 1rem;
    align-items: start;
    padding: 0.85rem 1rem;
    border: 1px solid var(--line);
    border-radius: 6px;
    background: var(--surface);
  }

  @media (max-width: 540px) {
    .rules li {
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

  .rule-body {
    font-size: 13.5px;
    line-height: 1.6;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .rule-body code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

  /* Caveat callout styles now live in $lib/docs/Caveat.svelte. */

  /* Topics cards: just the layout container — the card itself
     (`.topic`, `.topic-eyebrow`, etc.) lives in $lib/docs/TopicCard.svelte. */
  .topic-cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 0.85rem;
    margin: 0.5rem 0 1.5rem;
  }

  .footnote {
    margin: 1rem 0 0;
    font-size: 13px;
    color: var(--muted);
  }
  .footnote a {
    color: var(--fg);
    text-decoration: none;
    border-bottom: 1px solid color-mix(in srgb, var(--fg) 30%, transparent);
  }
  .footnote a:hover {
    border-bottom-color: var(--fg);
  }
</style>
