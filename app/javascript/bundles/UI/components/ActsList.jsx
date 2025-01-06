var ActsList = React.createClass({
  getInitialState: function() {
    return { data: [], type: null };
  },
  
  reloadActs: function(company) {
    var $this = this;
    
    /* setstate is an asynchronous update but we need this data now. stash it. */
    var tempurl = "/acts.json?mine=1&type=3";
    
    $.ajax({
      url: tempurl,
      dataType: 'json',
      success: function(data) {
        this.setState({data: data});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(tempurl, status, err.toString());
      }.bind(this)
    });
  },
  fullReload : function() {
    console.log("full reload requested");
    this.reloadActs();
  },
  componentWillMount: function() {
    /* this is our initial load. */
    this.reloadActs();
  },
  componentDidUpdate: function() {
    /* after we've drawn the dashboard, render a submissions window so that the
     * act can be submitted to a new place. Do this only if the cookie is set.
     * 
     * I don't like maintaining state here, but bridging the gap
     * between rails and js is hard otherwise.
     *
     */
    if (this.state.data.acts != undefined && this.state.data.acts.length > 0)  { 
      if (readCookie("recent_act_created") != null) {
        var mergedtitle = "";
        var found = false; 
        
        /* determine title based on data and open a dialog if we find the act */
        for (var i=0; i < this.state.data.acts.length; i++) {
          if (this.state.data.acts[i].id == readCookie("recent_act_created")) {
            found = true;
            if (this.state.data.acts[i].title != null && this.state.data.acts[i].title.length > 0) {
              mergedtitle = this.state.data.acts[i].stage_name + " : " + this.state.data.acts[i].title;
            } else { 
              mergedtitle = this.state.data.acts[i].stage_name;
            }
          }
        }
        
        if (found) { 
          $('#submissionPicker.modal').modal('show');
          $('#submissionPickerLabel.modal-title').html("One or more of your companies is accepting submissions.<br>Submit " + mergedtitle + " to which event?");
          $('#forAct').val(readCookie("recent_act_created"));
        }
        
        /* and remove it, so this doesn't happen again. */
        eraseCookie("recent_act_created");
      }
    }
  },
  render: function() {
    var $this = this;
    var actNodes;
    
    if (this.state.data.acts == undefined || this.state.data.acts.length == 0) {
      actNodes = (
          <li>
          <strong>No Acts.</strong>
          </li> );
    } else {
      actNodes = this.state.data.acts.map(function (act) {
        return (
            <Act key={act.id} act={act} reloadCallback={$this.fullReload} />
        );
      });
    }
    return (
        <ul className="media-list media-list-with-divider">
      	{actNodes}
      </ul>
    );
  }
});
