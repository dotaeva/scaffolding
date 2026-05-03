// Reactive state class for the landing-page Playground simulator.
//
// Mirrors a real Scaffolding coordinator hierarchy at the data level so
// each Scaffolding API call maps cleanly to a state mutation:
//
//   AppCoordinator (Root)
//     ├── LoginCoordinator (Flow)              ← phase === 'auth'
//     └── MainTabCoordinator (Tab)             ← phase === 'main'
//         ├── HomeCoordinator (Flow)           ← tab === 'home'
//         │   └── homeStack: [home, detail*, sheet?]
//         └── ProfileCoordinator (Flow)        ← tab === 'profile'
//             └── profileStack: [profile, editProfile*, cover?]
//
// Each stack entry carries a `pushType: 'root' | 'push' | 'sheet' | 'cover'`.
// That's how Scaffolding's FlowStack actually models the world — pushes
// and modals share the same `destinations` array, and `pop()` (which
// just removes the topmost) therefore dismisses a sheet when the sheet
// is the topmost entry.
//
// Sub-components import a single `PlaygroundState` instance from
// `Playground.svelte` via a prop and read/mutate its fields directly —
// the class fields are runes, so reads are tracked and writes propagate.

const PLANETS = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn'];

export class PlaygroundState {
  // ── Mutable state ──────────────────────────────────────────────────
  phase = $state('main');                 // 'main' | 'auth'
  tab = $state('home');                   // 'home' | 'profile'
  homeStack = $state([{ id: 'home-root', screen: 'home', pushType: 'root' }]);
  profileStack = $state([{ id: 'profile-root', screen: 'profile', pushType: 'root' }]);
  log = $state([]);

  // ── Internal id generator ──────────────────────────────────────────
  #counter = 0;
  #nid = (prefix) => `${prefix}-${++this.#counter}`;

  // ── Derived ────────────────────────────────────────────────────────
  currentStack = $derived(this.tab === 'home' ? this.homeStack : this.profileStack);

  // Pushed screens are only the root + push items. Modals are filtered
  // out so the phone view renders them as overlays, not as stack pages.
  homePushed = $derived(
    this.homeStack.filter((s) => s.pushType === 'root' || s.pushType === 'push')
  );
  profilePushed = $derived(
    this.profileStack.filter((s) => s.pushType === 'root' || s.pushType === 'push')
  );

  // First (and in our demo, only) modal destination on the active stack.
  modal = $derived(
    this.currentStack.find((s) => s.pushType === 'sheet' || s.pushType === 'cover') ?? null
  );

  /**
   * Coordinators injected into the SwiftUI environment at the topmost
   * visible screen, leaf → root.
   */
  injectedChain = $derived.by(() => {
    if (this.modal) {
      const modalCoord =
        this.modal.pushType === 'sheet' ? 'SettingsCoordinator' : 'LoginCoordinator';
      if (this.phase === 'auth') {
        return [modalCoord, 'LoginCoordinator', 'AppCoordinator'];
      }
      return [modalCoord, this.activeFlow(), 'MainTabCoordinator', 'AppCoordinator'];
    }
    if (this.phase === 'auth') {
      return ['LoginCoordinator', 'AppCoordinator'];
    }
    return [this.activeFlow(), 'MainTabCoordinator', 'AppCoordinator'];
  });

  /**
   * Action panel groups — only what's actually callable from the
   * currently-injected coordinator. dismissCoordinator() lives only on
   * the presented-modal context; route(.detail) only on Home; etc.
   */
  actionGroups = $derived.by(() => {
    if (this.modal) {
      const groups = [
        {
          label:
            this.modal.pushType === 'sheet'
              ? 'Presented coordinator (sheet)'
              : 'Presented coordinator (full-screen cover)',
          items: [
            {
              code: 'dismissCoordinator()',
              fn: this.dismissCoordinator,
              accent: true,
              hint:
                'Pops the entire presented coordinator off its parent. ' +
                'It does not dismiss screens — pop() does that.'
            }
          ]
        }
      ];

      // The underlying flow coordinator is still alive AND its
      // FlowStack.destinations is the same array that holds the modal —
      // that's why `flow.pop()` removes the modal when it's topmost.
      if (this.phase === 'main') {
        const flowName = this.activeFlow();
        const top = this.currentStack[this.currentStack.length - 1];
        const topIsModal = top && (top.pushType === 'sheet' || top.pushType === 'cover');

        const popHint = topIsModal
          ? `${flowName}.stack.destinations.removeLast() — the topmost destination is the ${top.pushType}, so pop() dismisses it.`
          : `Pop the top of ${flowName}'s stack. The sheet stays put because it isn't topmost.`;

        const isHome = this.tab === 'home';
        const routeAction = isHome
          ? {
              code: 'route(to: .detail)',
              fn: () => this.routeToDetail(),
              hint: `Append a pushed detail onto home.stack — even with the ${this.modal.pushType} still open.`
            }
          : {
              code: 'route(to: .editProfile)',
              fn: this.routeToEditProfile,
              hint: `Append the edit-profile screen onto profile.stack — even with the ${this.modal.pushType} still open.`
            };
        const stackItems = [routeAction];

        if (this.currentStack.length > 1) {
          stackItems.push({
            code: 'pop()',
            fn: this.pop,
            hint: popHint
          });
          stackItems.push({
            code: 'popToRoot()',
            fn: this.popToRoot,
            hint: `Drop everything above ${flowName}'s root — pushes and the ${this.modal.pushType} both go.`
          });
        }
        groups.push({
          label: `Underlying flow (${flowName})`,
          items: stackItems
        });
      }

      return groups;
    }

    if (this.phase === 'auth') {
      return [
        {
          label: 'Root coordinator',
          items: [
            {
              code: 'setRoot(.authenticated)',
              fn: () => this.setPhase('main'),
              hint:
                'Atomic root swap — replaces the unauthenticated flow with the main app.'
            }
          ]
        }
      ];
    }

    // phase === 'main', no modal — we are inside the active flow.
    const groups = [];
    const isHome = this.tab === 'home';
    const routeAction = isHome
      ? {
          code: 'route(to: .detail)',
          fn: () => this.routeToDetail(),
          hint: 'Push a detail screen onto home.stack. Cycles through the planet list.'
        }
      : {
          code: 'route(to: .editProfile)',
          fn: this.routeToEditProfile,
          hint: 'Push the edit-profile screen onto profile.stack.'
        };
    const stackItems = [routeAction];

    if (this.currentStack.length > 1) {
      stackItems.push({
        code: 'pop()',
        fn: this.pop,
        hint: 'Pop the top of the active stack. Fires its onDismiss.'
      });
      stackItems.push({
        code: 'popToRoot()',
        fn: this.popToRoot,
        hint: 'Pop everything except the root. Each removed screen resolves once.'
      });
    }
    groups.push({ label: 'Stack', items: stackItems });

    groups.push({
      label: 'Present',
      items: [
        {
          code: 'present(.settings, as: .sheet)',
          fn: this.presentSheet,
          hint: 'Present a SettingsCoordinator as a modal sheet over the current flow.'
        },
        {
          code: 'present(.login, as: .fullScreenCover)',
          fn: this.presentCover,
          hint: 'Present a LoginCoordinator as a full-screen cover. No backdrop tap-out.'
        }
      ]
    });

    const otherTab = this.tab === 'home' ? 'profile' : 'home';
    groups.push({
      label: 'Tabs & root',
      items: [
        {
          code: `select(first: .${otherTab})`,
          fn: () => this.selectTab(otherTab),
          hint: `Switch the tab coordinator to ${otherTab.charAt(0).toUpperCase() + otherTab.slice(1)}. Each tab keeps its own stack.`
        },
        {
          code: 'setRoot(.unauthenticated)',
          fn: () => this.setPhase('auth'),
          hint: 'Atomic root swap back to the auth flow. Tears down the main app.'
        }
      ]
    });

    return groups;
  });

  // ── Helpers ────────────────────────────────────────────────────────

  /** The flow coordinator owning the currently-visible non-modal screens. */
  activeFlow = () => {
    if (this.phase === 'auth') return 'LoginCoordinator';
    return this.tab === 'home' ? 'HomeCoordinator' : 'ProfileCoordinator';
  };

  /** Push onto the active flow's stack. */
  #pushItem = (item) => {
    if (this.tab === 'home') this.homeStack = [...this.homeStack, item];
    else this.profileStack = [...this.profileStack, item];
  };

  /** Replace the active flow's stack. */
  #setStack = (items) => {
    if (this.tab === 'home') this.homeStack = items;
    else this.profileStack = items;
  };

  #logCall = (text, kind = 'call', caller = '') => {
    this.log = [...this.log, { id: this.#nid('log'), text, kind, caller }];
    if (this.log.length > 8) this.log = this.log.slice(-8);
  };

  // ── Mutations (called by phone UI AND action panel) ────────────────

  routeToDetail = (planet) => {
    if (this.phase !== 'main') return;
    const callerName = this.activeFlow();
    if (!planet) {
      const pushedSoFar = this.currentStack.filter(
        (s) => s.pushType === 'push' && s.screen === 'detail'
      ).length;
      planet = PLANETS[pushedSoFar % PLANETS.length];
    }
    this.#pushItem({
      id: this.#nid('detail'),
      screen: 'detail',
      pushType: 'push',
      payload: { title: planet }
    });
    this.#logCall(`route(to: .detail(item: "${planet}"))`, 'call', callerName);
  };

  /**
   * Profile-tab equivalent of routeToDetail. ProfileCoordinator doesn't
   * have a `.detail` route — it has `.editProfile`. Keeps the action
   * labels honest about what's actually on each tab's coordinator.
   */
  routeToEditProfile = () => {
    if (this.phase !== 'main' || this.tab !== 'profile') return;
    const callerName = this.activeFlow();
    this.#pushItem({
      id: this.#nid('edit'),
      screen: 'edit-profile',
      pushType: 'push'
    });
    this.#logCall('route(to: .editProfile)', 'call', callerName);
  };

  /**
   * Mirrors FlowStack.pop() — removes the topmost destination
   * regardless of whether it's a pushed screen or a presented modal.
   */
  pop = () => {
    if (this.phase !== 'main') return;
    const callerName = this.activeFlow();
    if (this.currentStack.length <= 1) {
      this.#logCall('pop()', 'note', callerName);
      return;
    }
    this.#setStack(this.currentStack.slice(0, -1));
    this.#logCall('pop()', 'call', callerName);
  };

  popToRoot = () => {
    if (this.phase !== 'main' || this.currentStack.length <= 1) return;
    const callerName = this.activeFlow();
    this.#setStack(this.currentStack.slice(0, 1));
    this.#logCall('popToRoot()', 'call', callerName);
  };

  presentSheet = () => {
    if (this.modal) return;
    const callerName = this.activeFlow();
    this.#pushItem({
      id: this.#nid('modal'),
      screen: 'settings',
      pushType: 'sheet'
    });
    this.#logCall('present(.settings, as: .sheet)', 'call', callerName);
  };

  presentCover = () => {
    if (this.modal) return;
    const callerName = this.activeFlow();
    this.#pushItem({
      id: this.#nid('modal'),
      screen: 'login-cover',
      pushType: 'cover'
    });
    this.#logCall('present(.login, as: .fullScreenCover)', 'call', callerName);
  };

  /**
   * `dismissCoordinator()` is called on the presented coordinator and
   * removes itself from its parent's stack.
   */
  dismissCoordinator = () => {
    if (!this.modal) {
      this.#logCall('dismissCoordinator()', 'note', this.activeFlow());
      return;
    }
    const callerName =
      this.modal.pushType === 'sheet' ? 'SettingsCoordinator' : 'LoginCoordinator';
    this.#setStack(this.currentStack.filter((s) => s.id !== this.modal.id));
    this.#logCall('dismissCoordinator()', 'call', callerName);
  };

  selectTab = (t) => {
    if (this.phase !== 'main' || this.tab === t) return;
    this.tab = t;
    this.#logCall(`select(first: .${t})`, 'call', 'MainTabCoordinator');
  };

  setPhase = (p) => {
    if (this.phase === p) return;
    this.phase = p;
    // setRoot tears down the previous flow — clear stacks, including
    // any modal destinations they still hold.
    this.homeStack = [{ id: 'home-root', screen: 'home', pushType: 'root' }];
    this.profileStack = [{ id: 'profile-root', screen: 'profile', pushType: 'root' }];
    this.#logCall(
      `setRoot(.${p === 'main' ? 'authenticated' : 'unauthenticated'})`,
      'call',
      'AppCoordinator'
    );
  };

  reset = () => {
    this.phase = 'main';
    this.tab = 'home';
    this.homeStack = [{ id: 'home-root', screen: 'home', pushType: 'root' }];
    this.profileStack = [{ id: 'profile-root', screen: 'profile', pushType: 'root' }];
    this.log = [];
  };

  // Exposed so views can render planet rows from the same source of truth.
  PLANETS = PLANETS;
}

/**
 * Pretty-print a flow's destinations array as it would read in Swift —
 * `[home, detail("Earth"), sheet(.settings)]` etc. Used by the State
 * read-out.
 */
export function stackPretty(stack) {
  return stack
    .map((s) => {
      if (s.pushType === 'push' && s.screen === 'detail') {
        return `detail("${s.payload?.title ?? ''}")`;
      }
      if (s.pushType === 'push' && s.screen === 'edit-profile') {
        return 'editProfile';
      }
      if (s.pushType === 'sheet')  return `sheet(.${s.screen})`;
      if (s.pushType === 'cover')  return `cover(.${s.screen})`;
      return s.screen; // root
    })
    .join(', ');
}
