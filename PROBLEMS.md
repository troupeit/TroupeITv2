PROBLEMS.md
----------
- Tooltips gone, need to figure that out
- Automatic tab switching / resetting in EventsApp (cannot control Tabs?)

- Pagination gone (have to migrate to pagy but was only using it for bhofmember)

- Lost all of EntryTechinfo entries in import

- Devise 2FA completely broken

- _meta.html: Had to remove soundmanager
```
    <%= javascript_tag "var SM_SWF = #{asset_path('soundmanager2.swf').inspect};" %>
```

as well as
```

  $(window).load(function(){
    soundManager.setup({
      url: SM_SWF,
      flashVersion: 9, // optional: shiny features (default = 8)
      preferFlash: false,
      debugMode: true,
      useHTML5Audio: true,
      consoleOnly: true,
      waitForWindowLoad: true
    });
  });

```
- _meta.html: Removed all FB tracking pixels as well as dead GA3 code

# Style and theming

- Entire css needs to be redone
- SCSS CSS Pipeline is a mess
- Need a new sound player and table layout