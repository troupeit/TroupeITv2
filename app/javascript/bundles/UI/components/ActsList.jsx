import React, { useState, useEffect } from 'react';
import Act from './Act';
import { readCookie, eraseCookie } from './util';

const ActsList = (props) => {
  const [ data, setData ] = useState([]);
  const [ type, setType ] = useState(3);

  const reloadActs = company => {
    /* setstate is an asynchronous update but we need this data now. stash it. */
    var tempurl = "/acts.json?mine=1&type=3";
    
    $.ajax({
      url: tempurl,
      dataType: 'json',
      success: function(data) {
         setData(data);
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(tempurl, status, err.toString());
      }.bind(this)
    });
  };

  const fullReload = () => {
    console.log("full reload requested");
    reloadActs();
  };

  useEffect(() => {
    /* this is our initial load. */
    reloadActs();
  }, []);

  useEffect(() => {
    /* jna - if the data changes, maybe we can do this here? */

    /* after we've drawn the dashboard, render a submissions window so that the
     * act can be submitted to a new place. Do this only if the cookie is set.
     * 
     * I don't like maintaining state here, but bridging the gap
     * between rails and js is hard otherwise.
     *
     */
    if (data.acts != undefined && data.acts.length > 0)  { 
      if (readCookie("recent_act_created") != null) {
        var mergedtitle = "";
        var found = false; 
        
        /* determine title based on data and open a dialog if we find the act */
        for (var i=0; i < data.acts.length; i++) {
          if (data.acts[i].id == readCookie("recent_act_created")) {
            found = true;
            if (data.acts[i].title != null && data.acts[i].title.length > 0) {
              mergedtitle = data.acts[i].stage_name + " : " + data.acts[i].title;
            } else { 
              mergedtitle = data.acts[i].stage_name;
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
  }, [data]);

  var actNodes;
    
  if (data.acts == undefined || data.acts.length == 0) {
    actNodes = (
        <li>
        <strong>No Acts.</strong>
        </li> );
  } else {
    actNodes = data.acts.map(function (act) {
      return (
          <Act key={act.id} act={act} reloadCallback={fullReload} />
      );
    });
  }

  return (
    <ul className="media-list media-list-with-divider">
      {actNodes}
    </ul>
  );
}

export default ActsList;
