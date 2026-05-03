<script>
  import CodeBlock from '$lib/CodeBlock.svelte';
  import ScrollProgress from '$lib/ScrollProgress.svelte';
  import FlowSim from '$lib/FlowSim.svelte';
  import TabSim from '$lib/TabSim.svelte';
  import RootSim from '$lib/RootSim.svelte';
  import {
    CODE_COORDINATABLE,
    CODE_FLOW_PROTOCOL,
    CODE_TAB_PROTOCOL,
    CODE_ROOT_PROTOCOL,
    CODE_FLOWSTACK,
    CODE_ROOTC,
    CODE_TABITEMS,
    CODE_DESTINATION,
    CODE_DEST_TYPES,
    CODE_DESTINATIONABLE,
    CODE_SCAFFOLDABLE,
    CODE_SCAFFOLDING_TRACKED,
    CODE_SCAFFOLDING_IGNORED
  } from '$lib/code/api.js';

  // Per-symbol scroll stops — each symbol is its own anchor in the
  // ScrollProgress rail, so the reader can land on a specific protocol /
  // type / macro directly instead of paging through grouped sections.
  const SECTIONS = [
    { id: 'coordinatable',       label: 'Coordinatable' },
    { id: 'flow-coordinatable',  label: 'Flow' },
    { id: 'tab-coordinatable',   label: 'Tab' },
    { id: 'root-coordinatable',  label: 'Root' },
    { id: 'flowstack',           label: 'FlowStack' },
    { id: 'root-container',      label: 'Root< >' },
    { id: 'tabitems',            label: 'TabItems' },
    { id: 'destination',         label: 'Destination' },
    { id: 'dest-types',          label: 'Type enums' },
    { id: 'destinationable',     label: 'Bridge protocols' },
    { id: 'scaffoldable',        label: '@Scaffoldable' },
    { id: 'scaffolding-tracked', label: '@Tracked' },
    { id: 'scaffolding-ignored', label: '@Ignored' }
  ];

</script>

<ScrollProgress sections={SECTIONS} />

<main class="docs">
  <article class="article">
    <header class="hero">
      <p class="eyebrow">API Reference</p>
      <h1>Symbols.</h1>
      <p class="lede">
        Every public protocol, type, and macro the
        <code>Scaffolding</code> module exposes — declaration, conformance,
        and member topics for each.
      </p>
      <ul class="toc-flat">
        <li><a href="#coordinatable">Protocols</a> · 4</li>
        <li><a href="#flowstack">Containers</a> · 3</li>
        <li><a href="#destination">Destinations</a> · 3</li>
        <li><a href="#scaffoldable">Macros</a> · 3</li>
      </ul>
    </header>

    <!-- ════════ Protocols ═════════════════════════════════════════════ -->

    <article id="coordinatable" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>Coordinatable</h2>
          <span class="pill" data-kind="protocol">Protocol</span>
        </header>
        <p class="meta">
          <code>@MainActor</code> · base · all coordinator types build on this
        </p>
        <p class="overview">
          The shared surface every coordinator type builds upon: an associated
          <code>Destinations</code> enum, identity, parent tracking, and the
          ability to produce a SwiftUI view. You don't conform to
          <code>Coordinatable</code> directly — use one of the three
          specialized protocols.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_COORDINATABLE} label="Coordinatable.swift" />

        <h3 class="sym-label">Inherits from</h3>
        <p class="refs"><code>AnyObject</code>, <code>Identifiable</code></p>

        <h3 class="sym-label">Conforming protocols</h3>
        <p class="refs">
          <a href="#flow-coordinatable"><code>FlowCoordinatable</code></a>,
          <a href="#tab-coordinatable"><code>TabCoordinatable</code></a>,
          <a href="#root-coordinatable"><code>RootCoordinatable</code></a>
        </p>

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>parent: (any Coordinatable)?</code></dt>
          <dd>The coordinator that owns this one, or <code>nil</code> at the top of the hierarchy.</dd>

          <dt><code>view() -&gt; ViewType</code></dt>
          <dd>Produces the SwiftUI view for this coordinator's hierarchy.</dd>

          <dt><code>dismissCoordinator()</code></dt>
          <dd>Removes this coordinator from its parent (pop or modal-dismiss). Tab children log a warning instead.</dd>

          <dt><code>present(_:as:onDismiss:)</code></dt>
          <dd>Presents a destination as a sheet or full-screen cover. Available on every coordinator.</dd>

          <dt><code>customize(_ view: AnyView) -&gt; some View</code></dt>
          <dd>Override to apply shared modifiers — toolbars, overlays, environment values — to every screen this coordinator renders.</dd>

          <dt><code>_injectsCoordinator: Bool</code></dt>
          <dd>Whether this coordinator is injected into descendant <code>@Environment</code>. Defaults to <code>true</code>; opt out with <code>@Scaffoldable(injectsCoordinator: false)</code>.</dd>
        </dl>
      </div>
    </article>

    <article id="flow-coordinatable" class="sym sim-side">
      <div class="prose">
        <header class="sym-head">
          <h2>FlowCoordinatable</h2>
          <span class="pill" data-kind="protocol">Protocol</span>
        </header>
        <p class="meta">
          <code>@MainActor</code> · push · pop · sheet · full-screen cover
        </p>
        <p class="overview">
          The push/pop navigation coordinator. Wraps a SwiftUI
          <code>NavigationStack</code> and stores both pushed screens and
          modal-presented coordinators in a single
          <code>FlowStack.destinations</code> array.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_FLOW_PROTOCOL} label="FlowCoordinatable.swift" />

        <h3 class="sym-label">Conforms to</h3>
        <p class="refs"><a href="#coordinatable"><code>Coordinatable</code></a></p>

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>stack: FlowStack&lt;Self&gt;</code></dt>
          <dd>Observable container holding root, pushes, and modals.</dd>

          <dt><code>route(to:onDismiss:) -&gt; Self</code></dt>
          <dd><strong>Push</strong> a destination. Modal presentation is split out — use <code>present(_:as:)</code> for that.</dd>

          <dt><code>present(_:as:onDismiss:) -&gt; Self</code></dt>
          <dd>Present a destination as a <code>.sheet</code> or <code>.fullScreenCover</code>. Both end up in <code>stack.destinations</code> with the matching <code>pushType</code>.</dd>

          <dt><code>pop()</code></dt>
          <dd>Removes the topmost destination. Works for pushed screens AND modals — they share the same array.</dd>

          <dt><code>popToRoot()</code></dt>
          <dd>Drops everything above the root. Each removed destination resolves its <code>onDismiss</code>.</dd>

          <dt><code>popToFirst(_:)</code> · <code>popToLast(_:)</code></dt>
          <dd>Pop back to the first / last occurrence of a destination by <code>Destinations.Meta</code>.</dd>

          <dt><code>setRoot(_:animation:) -&gt; Self</code></dt>
          <dd>Replace the flow's root destination atomically. Pushed destinations are cleared first.</dd>

          <dt><code>setRootTransitionAnimation(_:)</code></dt>
          <dd>Default animation for root swaps.</dd>

          <dt><code>isInStack(_:) -&gt; Bool</code></dt>
          <dd>Whether a destination meta is anywhere in the current stack.</dd>
        </dl>
      </div>
      <aside class="sim-col" aria-label="FlowCoordinatable simulation">
        <FlowSim
          coordName="HomeCoordinator"
          root={{ title: 'Planets', list: ['Mercury', 'Venus', 'Earth', 'Mars'] }}
          actions={[
            { code: 'route(to: .detail)',
              fn: (c) => c.push({ title: `Detail #${c.stack.length}`, body: 'Pushed onto the stack.' }) },
            { code: 'pop()',         fn: (c) => c.pop() },
            { code: 'popToRoot()',   fn: (c) => c.popToRoot() }
          ]}
          showState
        />
      </aside>
    </article>

    <article id="tab-coordinatable" class="sym sim-side">
      <div class="prose">
        <header class="sym-head">
          <h2>TabCoordinatable</h2>
          <span class="pill" data-kind="protocol">Protocol</span>
        </header>
        <p class="meta"><code>@MainActor</code> · tab bar · independent stacks per tab</p>
        <p class="overview">
          Manages a <code>TabView</code> where each tab is a destination —
          either a plain view or a child coordinator. Each tab keeps its
          own independent navigation stack.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_TAB_PROTOCOL} label="TabCoordinatable.swift" />

        <h3 class="sym-label">Conforms to</h3>
        <p class="refs"><a href="#coordinatable"><code>Coordinatable</code></a></p>

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>tabItems: TabItems&lt;Self&gt;</code></dt>
          <dd>Observable container holding tabs, selection, and modals.</dd>

          <dt><code>selectFirstTab(_:)</code> · <code>selectLastTab(_:)</code></dt>
          <dd>Select by destination meta (first / last match).</dd>

          <dt><code>select(index:)</code> · <code>select(id:)</code></dt>
          <dd>Select by zero-based index or tab UUID.</dd>

          <dt><code>setTabs(_:)</code></dt>
          <dd>Replace the entire tab list.</dd>

          <dt><code>appendTab(_:)</code> · <code>insertTab(_:at:)</code></dt>
          <dd>Add tabs dynamically.</dd>

          <dt><code>removeFirstTab(_:)</code> · <code>removeLastTab(_:)</code></dt>
          <dd>Remove by destination meta.</dd>

          <dt><code>isInTabItems(_:) -&gt; Bool</code></dt>
          <dd>Whether a destination meta is currently a tab.</dd>

          <dt><code>setTabBarVisibility(_:)</code></dt>
          <dd><code>.automatic</code> · <code>.visible</code> · <code>.hidden</code></dd>

          <dt><code>present(_:as:onDismiss:)</code></dt>
          <dd>Present a modal directly on the tab coordinator — no need to delegate to a child flow.</dd>
        </dl>
      </div>
      <aside class="sim-col" aria-label="TabCoordinatable simulation">
        <TabSim
          coordName="MainTabCoordinator"
          tabs={[
            { id: 'home',    label: 'Home',    icon: '⌂', screen: { title: 'Home',    list: ['Mercury', 'Venus', 'Earth', 'Mars'] } },
            { id: 'profile', label: 'Profile', icon: '●', screen: { title: 'Profile', body: '@alex',  list: ['Edit profile', 'Saved planets'] } }
          ]}
          actions={[
            { code: 'selectFirstTab(.home)',    fn: (c) => c.select('home') },
            { code: 'selectFirstTab(.profile)', fn: (c) => c.select('profile') }
          ]}
          showState
        />
      </aside>
    </article>

    <article id="root-coordinatable" class="sym sim-side">
      <div class="prose">
        <header class="sym-head">
          <h2>RootCoordinatable</h2>
          <span class="pill" data-kind="protocol">Protocol</span>
        </header>
        <p class="meta"><code>@MainActor</code> · atomic root swap · auth flows</p>
        <p class="overview">
          Holds a single root destination that can be swapped wholesale.
          Ideal for authentication, onboarding, or any state where the
          entire view hierarchy must change atomically.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_ROOT_PROTOCOL} label="RootCoordinatable.swift" />

        <h3 class="sym-label">Conforms to</h3>
        <p class="refs"><a href="#coordinatable"><code>Coordinatable</code></a></p>

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>root: Root&lt;Self&gt;</code></dt>
          <dd>Observable container with the current root + presented modals.</dd>

          <dt><code>setRoot(_:animation:) -&gt; Self</code></dt>
          <dd>Atomic root swap. Fires <code>onDismiss</code> on the previous tree.</dd>

          <dt><code>isRoot(_:) -&gt; Bool</code></dt>
          <dd>Whether the current root matches a given destination meta.</dd>

          <dt><code>setRootTransitionAnimation(_:)</code></dt>
          <dd>Default animation for root swaps.</dd>

          <dt><code>present(_:as:onDismiss:)</code></dt>
          <dd>Present a modal directly on the root coordinator.</dd>
        </dl>
      </div>
      <aside class="sim-col" aria-label="RootCoordinatable simulation">
        <RootSim
          coordName="AppCoordinator"
          initial="login"
          roots={[
            { id: 'login', screen: { title: 'Sign in', body: 'Unauthenticated flow.', list: ['Email', 'Password'] } },
            { id: 'main',  screen: { title: 'Home',    body: 'Authenticated app.',     list: ['Planets', 'Profile'] } }
          ]}
          actions={[
            { code: 'setRoot(.authenticated)',
              fn: (c) => c.setRoot('main') },
            { code: 'setRoot(.unauthenticated)',
              fn: (c) => c.setRoot('login') }
          ]}
          showState
        />
      </aside>
    </article>

    <!-- ════════ State containers ═══════════════════════════════════════ -->

    <article id="flowstack" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>FlowStack&lt;Coordinator&gt;</h2>
          <span class="pill" data-kind="class">Class</span>
        </header>
        <p class="meta"><code>@MainActor</code> · <code>@Observable</code> · <code>final</code></p>
        <p class="overview">
          Backs a <code>FlowCoordinatable</code>. The single
          <code>destinations</code> array holds <em>all</em> destinations on
          the flow — pushes <em>and</em> modals — so <code>pop()</code> on
          the parent flow can dismiss a sheet when that sheet is the
          topmost destination.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_FLOWSTACK} label="FlowStack.swift" />

        <h3 class="sym-label">Used by</h3>
        <p class="refs"><a href="#flow-coordinatable"><code>FlowCoordinatable</code></a></p>

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>root: Destination?</code></dt>
          <dd>The flow's root destination.</dd>

          <dt><code>destinations: [Destination]</code></dt>
          <dd>Mixed array of pushes and modals (filtered by <code>pushType</code> at render time).</dd>

          <dt><code>animation: Animation?</code></dt>
          <dd>Default animation for root transitions.</dd>

          <dt><code>presentedAs: PresentationType?</code></dt>
          <dd>How this flow itself is presented (when nested).</dd>

          <dt><code>parent: (any Coordinatable)?</code></dt>
          <dd>Weak reference to the parent coordinator.</dd>
        </dl>
      </div>
    </article>

    <article id="root-container" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>Root&lt;Coordinator&gt;</h2>
          <span class="pill" data-kind="class">Class</span>
        </header>
        <p class="meta"><code>@MainActor</code> · <code>@Observable</code> · <code>final</code></p>
        <p class="overview">
          Backs a <code>RootCoordinatable</code>. <code>modals</code> holds
          modals presented directly from the root coordinator (added via
          <code>present(_:as:)</code> on the root).
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_ROOTC} label="Root.swift" />

        <h3 class="sym-label">Used by</h3>
        <p class="refs"><a href="#root-coordinatable"><code>RootCoordinatable</code></a></p>
      </div>
    </article>

    <article id="tabitems" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>TabItems&lt;Coordinator&gt;</h2>
          <span class="pill" data-kind="class">Class</span>
        </header>
        <p class="meta"><code>@MainActor</code> · <code>@Observable</code> · <code>final</code></p>
        <p class="overview">
          Backs a <code>TabCoordinatable</code>. <code>modals</code> holds
          modals presented directly from the tab coordinator.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_TABITEMS} label="TabItems.swift" />

        <h3 class="sym-label">Used by</h3>
        <p class="refs"><a href="#tab-coordinatable"><code>TabCoordinatable</code></a></p>
      </div>
    </article>

    <!-- ════════ Destinations ═══════════════════════════════════════════ -->

    <article id="destination" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>Destination</h2>
          <span class="pill" data-kind="struct">Struct</span>
        </header>
        <p class="meta"><code>Identifiable</code> · <code>Hashable</code></p>
        <p class="overview">
          A resolved navigation destination wrapping a view or child
          coordinator together with routing metadata. The generated
          <code>Destinations</code> enum produces these via its
          <code>value(for:)</code> method — you rarely create them by hand.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_DESTINATION} label="Destination.swift" />

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>id: UUID</code></dt>
          <dd>Stable identifier for this destination instance.</dd>

          <dt><code>routeType: DestinationType</code></dt>
          <dd>How this destination was originally routed (root / push / sheet / fullScreenCover).</dd>

          <dt><code>presentationType: DestinationType</code></dt>
          <dd>The effective presentation type, derived from <code>pushType</code>.</dd>

          <dt><code>meta: any DestinationMeta</code></dt>
          <dd>Type-erased identity that matches the macro-generated <code>Destinations.Meta</code> case.</dd>
        </dl>
      </div>
    </article>

    <article id="dest-types" class="sym sim-side">
      <div class="prose">
        <header class="sym-head">
          <h2>Destination type enums</h2>
          <span class="pill" data-kind="enum">Enums</span>
        </header>
        <p class="meta">3 public enums · used together at the routing boundary</p>
        <p class="overview">
          Three small enums classify destinations from different angles —
          their lifecycle origin, the internal presentation tag, and the
          public API surface for modal presentation.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_DEST_TYPES} label="Destination.swift" />

        <h3 class="sym-label">Topics</h3>
        <dl class="members">
          <dt><code>DestinationType</code></dt>
          <dd>Lifecycle origin: <code>.root</code> · <code>.push</code> · <code>.sheet</code> · <code>.fullScreenCover</code>. Read from <code>Destination.routeType</code>.</dd>

          <dt><code>PresentationType</code></dt>
          <dd>Internal tag: <code>.push</code> · <code>.sheet</code> · <code>.fullScreenCover</code>. Stored on <code>Destination.pushType</code>.</dd>

          <dt><code>ModalPresentationType</code></dt>
          <dd>Public modal API: <code>.sheet</code> · <code>.fullScreenCover</code>. Pass to <code>present(_:as:)</code>.</dd>
        </dl>

        <p class="sub" style="margin-top: 1.25rem;">
          The two modal kinds animate from the bottom; tapping the
          backdrop on a sheet — or calling <code>pop()</code> on the
          parent flow — dismisses them.
        </p>
      </div>
      <aside class="sim-col" aria-label="Modal presentation simulation">
        <FlowSim
          coordName="HomeCoordinator"
          root={{ title: 'Home', body: 'Tap a button to present.' }}
          actions={[
            { code: 'present(.settings, as: .sheet)',
              fn: (c) => c.present({ title: 'Settings', list: ['Notifications', 'Privacy', 'Account'] }, 'sheet') },
            { code: 'present(.login, as: .fullScreenCover)',
              fn: (c) => c.present({ title: 'Sign in', body: 'Full-screen cover.' }, 'cover') },
            { code: 'pop()', accent: true, fn: (c) => c.pop() }
          ]}
        />
      </aside>
    </article>

    <article id="destinationable" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>Destinationable &amp; DestinationMeta</h2>
          <span class="pill" data-kind="protocol">Protocols</span>
        </header>
        <p class="meta">macro-implemented · you never conform manually</p>
        <p class="overview">
          <code>Destinationable</code> bridges between a coordinator's
          generated <code>Destinations</code> enum and the runtime
          <code>Destination</code> value. <code>DestinationMeta</code>
          identifies a case without its associated values — useful for
          <code>popToFirst(_:)</code>, <code>selectFirstTab(_:)</code>,
          and similar APIs.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_DESTINATIONABLE} label="Destination.swift" />

        <h3 class="sym-label">Conformance</h3>
        <p class="refs">
          Synthesised by <a href="#scaffoldable"><code>@Scaffoldable</code></a> —
          you don't implement these protocols by hand.
        </p>
      </div>
    </article>

    <!-- ════════ Macros ═════════════════════════════════════════════════ -->

    <article id="scaffoldable" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>@Scaffoldable</h2>
          <span class="pill" data-kind="macro">Macro</span>
        </header>
        <p class="meta">attached(member) · generates <code>Destinations</code> + <code>_injectsCoordinator</code></p>
        <p class="overview">
          Apply to an <code>@Observable</code> class that conforms to
          <code>FlowCoordinatable</code>, <code>TabCoordinatable</code>, or
          <code>RootCoordinatable</code>. The macro inspects every function
          whose return type is <code>some View</code>,
          <code>any Coordinatable</code>, or a supported tuple, and
          synthesises a <code>Destinations</code> enum with one case per
          eligible function.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_SCAFFOLDABLE} label="Scaffolding.swift" />

        <h3 class="sym-label">Auto-tracked return types</h3>
        <dl class="members">
          <dt><code>some View</code></dt>
          <dd>A view destination — pushed onto the stack or rendered as the active root / modal.</dd>

          <dt><code>any Coordinatable</code></dt>
          <dd>A child-coordinator destination. <strong>Must be the existential</strong> <code>any Coordinatable</code> — concrete coordinator types like <code>-&gt; LoginCoordinator</code> are <em>not</em> recognised by the macro.</dd>

          <dt><code>(any Coordinatable, some View)</code></dt>
          <dd>A tab tuple — coordinator content + label. Used by <code>TabCoordinatable</code>.</dd>

          <dt><code>(some View, some View)</code></dt>
          <dd>A view-only tab tuple — content + label, no child coordinator.</dd>

          <dt><code>(any Coordinatable, some View, TabRole)</code> · <code>(some View, some View, TabRole)</code></dt>
          <dd>iOS 18+ tab tuples that include a <code>TabRole</code>.</dd>
        </dl>

        <h3 class="sym-label">Parameters</h3>
        <dl class="members">
          <dt><code>injectsCoordinator: Bool = true</code></dt>
          <dd>Whether the coordinator should be injected into descendant <code>@Environment</code>. Pass <code>false</code> on reusable views that shouldn't bind to a specific flow.</dd>
        </dl>

        <h3 class="sym-label">Generates</h3>
        <p class="refs">
          <a href="#destinationable"><code>Destinations</code> enum (conforms to <code>Destinationable</code>)</a>
          · <a href="#coordinatable"><code>_injectsCoordinator</code> property</a>
        </p>
      </div>
    </article>

    <article id="scaffolding-tracked" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>@ScaffoldingTracked</h2>
          <span class="pill" data-kind="macro">Macro</span>
        </header>
        <p class="meta">attached(peer) · explicit-include opt-in</p>
        <p class="overview">
          Marks a function for inclusion in the generated
          <code>Destinations</code> enum. By default
          <code>@Scaffoldable</code> includes every eligible function;
          adding <code>@ScaffoldingTracked</code> to one method makes the
          inclusion list explicit — anything without the attribute is
          then excluded.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_SCAFFOLDING_TRACKED} label="Scaffolding.swift" />
      </div>
    </article>

    <article id="scaffolding-ignored" class="sym">
      <div class="prose">
        <header class="sym-head">
          <h2>@ScaffoldingIgnored</h2>
          <span class="pill" data-kind="macro">Macro</span>
        </header>
        <p class="meta">attached(peer) · explicit exclude</p>
        <p class="overview">
          Excludes a single function from the generated
          <code>Destinations</code> enum. Apply it whenever a method's
          signature <em>looks</em> like a route to the macro — i.e.
          returns one of the <a href="#scaffoldable">auto-tracked
          return types</a> — but is actually a helper, an override, or
          a factory you don't want surfaced as a destination case.
        </p>

        <h3 class="sym-label">When to use it</h3>
        <dl class="members">
          <dt><code>customize(_ view: AnyView) -&gt; some View</code></dt>
          <dd>Returns <code>some View</code>, so without the attribute the macro would generate a <code>.customize(view:)</code> destination. Mark it <code>@ScaffoldingIgnored</code> so it stays a plain override, not a route.</dd>

          <dt>Helper view builders shared between routes</dt>
          <dd>Methods returning <code>some View</code> that aren't full screens — header rows, loading placeholders, anything you call from inside another route's body. Ignored.</dd>

          <dt>Coordinator factories you call manually</dt>
          <dd>If you build a child coordinator imperatively without going through a destination case, mark its factory as <code>@ScaffoldingIgnored</code> so it doesn't become an unused enum case.</dd>
        </dl>

        <h3 class="sym-label">Counter-example — what the macro tracks by default</h3>
        <p>
          <em>Without</em> <code>@ScaffoldingIgnored</code>, every function
          whose return type is on the
          <a href="#scaffoldable">auto-tracked list</a> becomes a case in
          the generated <code>Destinations</code> enum:
        </p>
        <dl class="members">
          <dt><code>func home() -&gt; some View</code></dt>
          <dd>→ <code>.home</code> case, view destination.</dd>

          <dt><code>func detail(item: Item) -&gt; some View</code></dt>
          <dd>→ <code>.detail(item:)</code> case with the matching associated value.</dd>

          <dt><code>func settings() -&gt; any Coordinatable</code></dt>
          <dd>→ <code>.settings</code> case, child-coordinator destination.</dd>

          <dt><code>func feed() -&gt; (any Coordinatable, some View)</code></dt>
          <dd>→ <code>.feed</code> tab case (coordinator + label tuple).</dd>
        </dl>
        <p class="meta">
          You only need <code>@ScaffoldingIgnored</code> when one of these
          shapes shows up where you <em>don't</em> want it generated.
        </p>

        <h3 class="sym-label">Declaration</h3>
        <CodeBlock code={CODE_SCAFFOLDING_IGNORED} label="Scaffolding.swift" />
      </div>
    </article>
  </article>
</main>

<style>
  /* Shared docs chrome (.docs / .article / .hero / .lede etc.) lives in
     `$lib/styles/docs.css`. The API page tweaks a few of those values
     and adds symbol-specific chrome (.sym, .sym-head, .pill, …). */

  .docs {
    /* Slightly smaller top padding than the prose pages so the dense
       symbol list starts higher. */
    padding-top: clamp(2.5rem, 6vw, 4rem);
  }

  .hero {
    margin-bottom: clamp(2.5rem, 6vw, 4rem);
    gap: 0.85rem;
  }
  .hero h1 {
    font-size: clamp(1.75rem, 4vw, 2.5rem);
  }
  .lede {
    font-size: 14.5px;
  }

  .toc-flat {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem 1.6rem;
    padding: 0.85rem 0 0;
    margin: 0;
    list-style: none;
    font-family: var(--font-mono);
    font-size: 11.5px;
    letter-spacing: 0.04em;
    color: var(--muted);
  }
  .toc-flat a {
    color: var(--fg);
    text-decoration: none;
    border-bottom: 1px dashed color-mix(in srgb, var(--fg) 25%, transparent);
    transition: border-color 140ms ease;
  }
  .toc-flat a:hover {
    border-bottom-color: var(--fg);
  }

  /* ── Symbols ──────────────────────────────────────────────────────── */

  .sym {
    margin: 0 0 clamp(3.5rem, 7vw, 5rem);
    padding-top: clamp(2rem, 4.5vw, 3rem);
    border-top: 1px solid var(--line-soft);
    scroll-margin-top: 5.5rem;
  }
  .sym:first-of-type {
    padding-top: 0;
    border-top: 0;
  }

  /* Sim-side: prose on the left, sticky simulator on the right.
     Threshold matches the ScrollProgress full-label breakpoint so the
     sim never extends into the rail's territory on the right. */
  .sym.sim-side {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    column-gap: clamp(1.5rem, 3vw, 2.5rem);
    align-items: start;
    margin-right: clamp(-180px, calc((1380px - 100vw) / 2), 0px);
  }
  .sym.sim-side > .prose { min-width: 0; }
  .sym.sim-side > .sim-col {
    position: sticky;
    top: 6rem;
    align-self: start;
  }
  @media (max-width: 880px) {
    .sym.sim-side {
      grid-template-columns: 1fr;
      margin-right: 0;
    }
    .sym.sim-side > .sim-col {
      position: static;
      justify-self: center;
      margin-top: 0.85rem;
    }
  }

  .sym-head {
    display: flex;
    align-items: center;
    gap: 0.7rem;
    flex-wrap: wrap;
    margin: 0 0 0.4rem;
  }
  .sym-head h2 {
    margin: 0;
    font-family: var(--font-mono);
    font-size: clamp(1.2rem, 2.4vw, 1.5rem);
    font-weight: 500;
    color: var(--fg);
    letter-spacing: -0.015em;
  }

  /* Kind pill — color-coded by symbol kind (matches the syntax palette). */
  .pill {
    display: inline-flex;
    align-items: center;
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    padding: 0.2rem 0.5rem;
    border-radius: 999px;
    border: 1px solid currentColor;
    background: color-mix(in srgb, currentColor 8%, transparent);
    line-height: 1;
  }
  .pill[data-kind='protocol'] { color: var(--syn-ty); }
  .pill[data-kind='class']    { color: var(--syn-att); }
  .pill[data-kind='struct']   { color: var(--syn-mem); }
  .pill[data-kind='enum']     { color: var(--syn-fn); }
  .pill[data-kind='macro']    { color: var(--syn-kw); }

  /* Sub-meta line directly under the symbol head. */
  .meta {
    margin: 0 0 1.1rem;
    font-size: 11.5px;
    letter-spacing: 0.04em;
    color: var(--muted);
    font-family: var(--font-mono);
  }
  .meta code {
    font-size: 11px;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }

  /* Overview prose. */
  .overview {
    margin: 0 0 1.5rem;
    font-size: 14px;
    line-height: 1.7;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .overview strong { color: var(--fg); font-weight: 500; }
  .overview em { color: var(--fg); font-style: italic; }
  .overview code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.4em;
    border-radius: 3px;
  }

  /* Sub-block label (Declaration / Conforms to / Topics / Parameters). */
  .sym-label {
    margin: 1.25rem 0 0.55rem;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--dim);
    font-weight: 500;
  }
  .sym :global(.block) {
    margin: 0 0 0.5rem;
  }

  /* Cross-reference rows. */
  .refs {
    margin: 0 0 0.5rem;
    font-size: 13.5px;
    line-height: 1.7;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
    display: flex;
    flex-wrap: wrap;
    gap: 0.35rem 0.5rem;
  }
  .refs code {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.4em;
    border-radius: 3px;
  }
  .refs a {
    color: inherit;
    text-decoration: none;
    border-bottom: 1px dashed color-mix(in srgb, var(--fg) 25%, transparent);
    transition: border-color 140ms ease;
  }
  .refs a code {
    background: color-mix(in srgb, var(--fg) 4%, transparent);
  }
  .refs a:hover { border-bottom-color: var(--fg); }

  /* Member definition list — DocC-style. */
  .members {
    margin: 0;
    border: 1px solid var(--line);
    border-radius: 6px;
    overflow: hidden;
    background: color-mix(in srgb, var(--fg) 2%, transparent);
  }
  .members dt {
    padding: 0.6rem 0.95rem 0.25rem;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 500;
    color: var(--fg);
    border-top: 1px solid var(--line-soft);
  }
  .members dt:first-of-type { border-top: 0; }
  .members dt code {
    font-size: 12px;
    color: var(--fg);
  }
  .members dd {
    margin: 0;
    padding: 0 0.95rem 0.7rem;
    font-size: 12.5px;
    line-height: 1.6;
    color: color-mix(in srgb, var(--fg) 78%, transparent);
  }
  .members dd code {
    font-family: var(--font-mono);
    font-size: 0.9em;
    color: var(--fg);
    background: color-mix(in srgb, var(--fg) 6%, transparent);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }
  .members dd strong { color: var(--fg); font-weight: 500; }

  /* Sheet/cover hint paragraph. */
  .sub {
    margin: 0;
    font-size: 13px;
    line-height: 1.65;
    color: color-mix(in srgb, var(--fg) 60%, transparent);
    border-left: 2px solid var(--line);
    padding-left: 0.85rem;
  }
  .sub code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    color: var(--fg);
    background: var(--surface-2);
    border: 1px solid var(--line-soft);
    padding: 0.05em 0.35em;
    border-radius: 3px;
  }
</style>
