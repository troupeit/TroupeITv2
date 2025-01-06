import React from 'react';
import moment from 'moment';
import 'moment-timezone';

import { formatDuration } from './util';

const Act = (props) => {
  const showSubmitModal = () => {
    var mergedtitle = "";
    
    /* workaround for acts without title field. */
    if (props.act.title != null && props.act.title.length > 0) {
      mergedtitle = props.act.stage_name + " : " + props.act.title;
    } else { 
      mergedtitle = props.act.stage_name;
    }

    /* we have to reload just before display, or our data could be stale. */
    $('#submissionPicker.modal').modal('show');
    $('#submissionPickerLabel.modal-title').html("Submit " + mergedtitle + " to which event?");
    $('#submissionPicker').find('input').val(props.act.id);

    updated_at = moment(props.act.updated_at);
    
    if (updated_at.isValid())  {
      updated_at_s = updated_at.format('dddd, MMMM Do YYYY, h:mm a');
      ago = updated_at.fromNow();
      $('#submissionPickerDetail').html(mergedtitle + ' was last updated ' + updated_at_s + " (" + ago + ")");
    } 
  };

  if (!props.act) {
    return null;
  }
  
  var actlink = "/acts/" + props.act.id + "/edit";
  var mergedtitle = "";
  var tinfo = "";

  var updated_at = moment(props.act.updated_at);
  
  if (updated_at.isValid())  {
    var updated_at_s = updated_at.format('dddd, MMMM Do YYYY, h:mm a');
    var ago = updated_at.fromNow();
    
    var tinfo = "Last Updated " + updated_at_s + " (" + ago + ")";
  } 
    
  /* workaround for acts without title field. */
  if (props.act.title != null && props.act.title.length > 0) {
    mergedtitle = props.act.stage_name + " : " + props.act.title;
  } else { 
    mergedtitle = props.act.stage_name;
  }
      
  return (
    <>
      <div className="media">
        <div className="media-body">
          <h4 className="mt-0 mb-1">
            <a href={actlink}>{mergedtitle}</a>
          </h4>
          <p>{props.act.short_description}</p>
          <i>{tinfo}</i>
        </div>
        <div className="ml-3" style={{textAlign:'right'}}>
          {formatDuration(props.act.length)}<br/>
          <button className="btn btn-info btn-xs" onClick={showSubmitModal}>Submit to Event</button>
        </div>
      </div>
    </>
  );
};

export default Act;
