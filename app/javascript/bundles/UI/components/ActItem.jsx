import React from 'react';
import moment from 'moment';
import 'moment-timezone';

import { formatDuration } from './util';

const ActItem = (props) => {
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

  // ps-3 is padding start 3
  // mb-1 is margin bottom 1
  // flex-1 is flex-grow 1
  // bg-gray-500 is background gray 500
  // ml-3 is margin left 3

  // all of this is inside a d-flex from ActsList
  // d-flex is display flex
  return (
    <>
    <div className="row">
      <div className="col d-flex flex-column">
        <div className="flex-fill">
          <h5 className="mb-2">
            <a href={actlink}>{mergedtitle}</a>
          </h5>
          <p>
            {props.act.short_description}
          </p>
          <p>
            <i>{tinfo}</i>
          </p>
        </div>
      </div>

      <div className="col-auto d-flex flex-column align-items-end">
        <div className="d-flex align-items-center">
          {formatDuration(props.act.length)}
        </div>
        <button className="btn btn-info btn-sm mt-auto" onClick={showSubmitModal}>Submit to Event</button>
      </div>
    </div>

    <hr className="bg-gray-500" />
  </>
  );
};

export default ActItem;
