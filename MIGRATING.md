Migrating components:
---

* Remove all `this.`
* Remove all `state.`
* Migrate all state vars out of `state.` to `useState`
* Replace function signatures with `const ...`
* move old HOC stuff (getIniitalState, componentDidMount) over to `useState` and hooks `useEffect, etc.`

Backend
-------

* Mongoid: It seems that `._id.$oid` is not the right thing to do anymore, now it's just `._id`
