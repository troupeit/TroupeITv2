pin "@popperjs/core", to: "popper.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# NOTE: rename `fontawesome.js` to `all.js`
pin "@fortawesome/fontawesome-free",
  to: "https://ga.jspm.io/npm:@fortawesome/fontawesome-free@6.1.1/js/all.js"
