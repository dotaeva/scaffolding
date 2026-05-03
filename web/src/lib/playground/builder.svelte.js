// Reactive state for the Playground's "Build" tab.
//
// The user composes a custom FlowCoordinator from primitives:
//   • Screens — named Swift functions returning `some View`.
//   • Actions per screen — buttons that the simulator renders on that
//     screen. Each action is one of:
//        push   → route(to: .otherScreen)
//        sheet  → present(.otherScreen, as: .sheet)
//        cover  → present(.otherScreen, as: .fullScreenCover)
//        pop    → pop()
//        dismiss→ dismissCoordinator()      (only callable from a modal)
//
// The phone preview mirrors a real FlowStack: the runtime `stack`
// array holds pushed instances and modals together; pop() removes
// the topmost regardless of kind, dismiss() removes the modal.

const SCREEN_NAMES = [
  'home', 'detail', 'settings', 'profile',
  'editProfile', 'about', 'help', 'review', 'confirm'
];

export const ACTION_KINDS = [
  { value: 'push',     label: 'route(to:)',           short: 'push' },
  { value: 'sheet',    label: 'present(_:as: .sheet)', short: 'sheet' },
  { value: 'cover',    label: 'present(_:as: .cover)', short: 'cover' },
  { value: 'pop',      label: 'pop()',                short: 'pop' },
  { value: 'dismiss',  label: 'dismissCoordinator()', short: 'dismiss' }
];

const STARTER_SCREENS = [
  { id: 'home', name: 'home', actions: [
      { id: 'a-home-detail', kind: 'push', target: 'detail' },
      { id: 'a-home-settings', kind: 'sheet', target: 'settings' }
    ]
  },
  { id: 'detail', name: 'detail', actions: [
      { id: 'a-detail-pop', kind: 'pop' }
    ]
  },
  { id: 'settings', name: 'settings', actions: [
      { id: 'a-settings-dismiss', kind: 'dismiss' }
    ]
  }
];

export class BuilderState {
  // ── Definition (what the user is building) ─────────────────────────
  screens = $state(STARTER_SCREENS.map((s) => ({ ...s, actions: [...s.actions] })));
  rootScreenId = $state('home');

  // ── Runtime (what the phone is showing) ───────────────────────────
  stack = $state([{ id: 'inst-0', screenId: 'home', pushType: 'root' }]);
  log = $state([]);

  // ── Internal id counter ────────────────────────────────────────────
  #counter = 0;
  #nid = (prefix) => `${prefix}-${++this.#counter}`;

  // ── Derived ────────────────────────────────────────────────────────
  pushedInstances = $derived(
    this.stack.filter((i) => i.pushType === 'root' || i.pushType === 'push')
  );
  modalInstance = $derived(
    this.stack.find((i) => i.pushType === 'sheet' || i.pushType === 'cover') ?? null
  );

  /** Lookup helper — returns the screen definition for an instance. */
  screenFor = (instance) =>
    this.screens.find((s) => s.id === instance?.screenId) ?? null;

  /** The screen the user is currently looking at (modal wins if present). */
  activeScreen = $derived.by(() => {
    if (this.modalInstance) return this.screenFor(this.modalInstance);
    const top = this.pushedInstances[this.pushedInstances.length - 1];
    return this.screenFor(top);
  });

  /** Auto-generated Swift coordinator code reflecting current screens. */
  swiftCode = $derived.by(() => {
    const root = this.screens.find((s) => s.id === this.rootScreenId);
    const lines = [
      '@Scaffoldable @Observable',
      'final class CustomCoordinator: @MainActor FlowCoordinatable {',
      `    var stack = FlowStack<CustomCoordinator>(root: .${root?.name ?? 'home'})`,
      ''
    ];
    for (const s of this.screens) {
      lines.push(`    func ${s.name}() -> some View { ${capitalize(s.name)}View() }`);
    }

    // Add a few illustrative call-site samples drawn from declared actions.
    const sampleSites = [];
    for (const s of this.screens) {
      for (const a of s.actions) {
        if (a.kind === 'push' && a.target) {
          sampleSites.push(`    // ${s.name}() pushes ${a.target}`);
          sampleSites.push(`    //   route(to: .${a.target})`);
          break;
        }
        if (a.kind === 'sheet' && a.target) {
          sampleSites.push(`    // ${s.name}() presents ${a.target} as a sheet`);
          sampleSites.push(`    //   present(.${a.target}, as: .sheet)`);
          break;
        }
        if (a.kind === 'cover' && a.target) {
          sampleSites.push(`    // ${s.name}() presents ${a.target} as a cover`);
          sampleSites.push(`    //   present(.${a.target}, as: .fullScreenCover)`);
          break;
        }
      }
      if (sampleSites.length >= 6) break;
    }
    if (sampleSites.length) {
      lines.push('');
      lines.push(...sampleSites);
    }

    lines.push('}');
    return lines.join('\n');
  });

  // ── Definition mutations (sidebar editor) ──────────────────────────

  addScreen = () => {
    // Pick the first SCREEN_NAMES entry not already taken; if all taken,
    // fall back to screen-N.
    let name = SCREEN_NAMES.find((n) => !this.screens.some((s) => s.name === n));
    if (!name) name = `screen${this.screens.length}`;
    const id = this.#nid('s');
    this.screens = [...this.screens, { id, name, actions: [] }];
  };

  renameScreen = (id, name) => {
    if (!name) return;
    // De-dupe — append numeric suffix if name is already taken.
    let resolved = name;
    let n = 2;
    while (this.screens.some((s) => s.id !== id && s.name === resolved)) {
      resolved = `${name}${n++}`;
    }
    this.screens = this.screens.map((s) =>
      s.id === id ? { ...s, name: resolved } : s
    );
  };

  removeScreen = (id) => {
    if (id === this.rootScreenId) return;
    // Drop the screen, drop any actions targeting it, reset stack if it
    // currently shows the screen.
    this.screens = this.screens
      .filter((s) => s.id !== id)
      .map((s) => ({
        ...s,
        actions: s.actions.filter((a) => a.target !== id)
      }));
    if (this.stack.some((i) => i.screenId === id)) {
      this.reset();
    }
  };

  setRootScreen = (id) => {
    if (!this.screens.some((s) => s.id === id)) return;
    this.rootScreenId = id;
    this.reset();
  };

  addAction = (screenId, kind, target = null) => {
    const action = { id: this.#nid('a'), kind, target };
    this.screens = this.screens.map((s) =>
      s.id === screenId ? { ...s, actions: [...s.actions, action] } : s
    );
  };

  removeAction = (screenId, actionId) => {
    this.screens = this.screens.map((s) =>
      s.id === screenId
        ? { ...s, actions: s.actions.filter((a) => a.id !== actionId) }
        : s
    );
  };

  setActionTarget = (screenId, actionId, target) => {
    this.screens = this.screens.map((s) =>
      s.id === screenId
        ? {
            ...s,
            actions: s.actions.map((a) =>
              a.id === actionId ? { ...a, target } : a
            )
          }
        : s
    );
  };

  // ── Runtime mutations (phone tap drives these) ─────────────────────

  invokeAction = (action) => {
    if (action.kind === 'push' && action.target) {
      this.stack = [
        ...this.stack,
        { id: this.#nid('i'), screenId: action.target, pushType: 'push' }
      ];
      this.#logCall(
        `route(to: .${this.#nameOf(action.target)})`
      );
      return;
    }
    if (action.kind === 'sheet' && action.target) {
      if (this.modalInstance) {
        this.#logNote(`present blocked — modal already open`);
        return;
      }
      this.stack = [
        ...this.stack,
        { id: this.#nid('i'), screenId: action.target, pushType: 'sheet' }
      ];
      this.#logCall(
        `present(.${this.#nameOf(action.target)}, as: .sheet)`
      );
      return;
    }
    if (action.kind === 'cover' && action.target) {
      if (this.modalInstance) {
        this.#logNote(`present blocked — modal already open`);
        return;
      }
      this.stack = [
        ...this.stack,
        { id: this.#nid('i'), screenId: action.target, pushType: 'cover' }
      ];
      this.#logCall(
        `present(.${this.#nameOf(action.target)}, as: .fullScreenCover)`
      );
      return;
    }
    if (action.kind === 'pop') {
      if (this.stack.length <= 1) {
        this.#logNote('pop() — already at root');
        return;
      }
      this.stack = this.stack.slice(0, -1);
      this.#logCall('pop()');
      return;
    }
    if (action.kind === 'dismiss') {
      if (!this.modalInstance) {
        this.#logNote('dismissCoordinator() — no modal to dismiss');
        return;
      }
      const id = this.modalInstance.id;
      this.stack = this.stack.filter((i) => i.id !== id);
      this.#logCall('dismissCoordinator()');
      return;
    }
  };

  reset = () => {
    this.stack = [
      { id: this.#nid('i'), screenId: this.rootScreenId, pushType: 'root' }
    ];
    this.log = [];
  };

  resetBuilder = () => {
    this.screens = STARTER_SCREENS.map((s) => ({ ...s, actions: [...s.actions] }));
    this.rootScreenId = 'home';
    this.reset();
  };

  // ── Internal helpers ───────────────────────────────────────────────

  #nameOf = (screenId) => this.screens.find((s) => s.id === screenId)?.name ?? screenId;

  #logCall = (text) => {
    this.log = [...this.log, { id: this.#nid('l'), text, kind: 'call' }];
    if (this.log.length > 8) this.log = this.log.slice(-8);
  };

  #logNote = (text) => {
    this.log = [...this.log, { id: this.#nid('l'), text, kind: 'note' }];
    if (this.log.length > 8) this.log = this.log.slice(-8);
  };
}

function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
