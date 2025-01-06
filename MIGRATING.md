Migrating components:
---

* Remove all `this.`
* Remove all `state.`
* Migrate all state vars out of `state.` to `useState`
* Replace function signatures with `const ...`
* move old HOC stuff (getIniitalState, componentDidMount) over to `useState` and hooks `useEffect, etc.`

