import React, { useState, useEffect } from "react";

import { 
  ACCESS_PRODUCER, 
  ACCESS_TECHCREW 
} from "./constants";

import { checkCompanyAccess } from "./util";

import Show from "./Show";
import ShowForm from "./ShowForm";

const ShowList = (props) => {
  const { reloadCallback, company, user, event_id, time_zone } = props;

  const [ data, setData ] = useState([]);
  const [ expanded, setExpanded ] = useState(false);
  const [ showFormExpanded, setShowFormExpanded ] = useState(false);

  const reloadShows = () => {
    console.log(`reload shows event ${event_id}`);

    $.ajax({
      url: '/shows.json?event_id=' + event_id,
      dataType: 'json',
      success: function(data) {
         setData(data);
      }.bind(this),
      error: function(xhr, status, err) {
        console.error('reloadShows / eventid:' + event_id, status, err.toString());
      }.bind(this)
    });
  };

  useEffect(() => {
    reloadShows();
  }, []);
  
  const postChange = () => {
    console.log("post change");  
    reloadCallback(); // notify the parent. 
    reloadShows();
  };

  const expand = (e) => {
    if (expanded == false) {
      reloadShows(); 
    }

    let newState = !expanded
    setExpanded(newState);

    if (newState == true) {
      setShowFormExpanded(false);
    }
    
    e.preventDefault(); 
  };

  const toggleShowForm = (e) => {
      let newState = !showFormExpanded;    
      setShowFormExpanded(newState);

      /* state doesn't immediately update */
      if (newState == true) { 
        setExpanded(false);
      }

      e.preventDefault();
  };

  const postCreate = () => {
    /* fires after create or update of a show */
    setShowFormExpanded(false);
    setExpanded(true);
    postChange();
  };

  var showNodes = "";
  var arrowClass = "glyphicon glyphicon-chevron-right";
        
  if (expanded) {
    if (data.aaData.length == 0) {
      showNodes = (<div className="noshows">No shows for this event. Please add one.</div>);
    } else {
      showNodes = data.aaData.map(function (s) {
      var st = moment(s.show_time);
      var dt = moment(s.door_time);
      return (
        <Show key={s.id}
              id={s.id}
              title={s.title}
              time_zone={time_zone}
              door_time={dt}
              show_time={st}
              venue={s.venue}
              room={s.room}
              goog_place_id={s.goog_place_id}
              reloadCallback={postChange}
              company={company}
              user={user} /> );
      });
    }

    var arrowClass = "glyphicon glyphicon-chevron-down";
  };

  if (showFormExpanded) {
    var showNodes = (
      <ShowForm 
        event_id={event_id}
        onCreate={postCreate}
        onCancel={postCreate}
        user={user}
        company={company} 
        />
    );
  }
    
  if (checkCompanyAccess(user, company._id, ACCESS_PRODUCER)) { 
    var showaddbtn = ( <button className="btn btn-sm btn-success" onClick={toggleShowForm}>
                        <i className="glyphicon glyphicon-plus"></i>
                        <span>&nbsp;Add Show</span>
                        </button> );

    var editurl = "/events/" + event_id + "/showpage";

    var eventeditbtn = (
        <a href={editurl} className="btn btn-sm btn-success" role="button">
        <i className="glyphicon glyphicon-pencil"></i>
        <span>&nbsp;Edit Event</span>
        </a>
    );
  }

      if (checkCompanyAccess(user, company._id, ACCESS_TECHCREW)) {
        livelink = "/events/" + event_id + "/live";
        var liveviewbtn = ( <a href={livelink}>
                             <button className="btn btn-inverse btn-sm">
                             <span className="glyphicon glyphicon-th-list"></span>
                             &nbsp;
                             Live view
                             </button>
                             </a>
                           );
      }
      
      return (
              <div>
                <button className="btn btn-sm btn-success" onClick={expand}>
                <i className={arrowClass}></i>
                <span>&nbsp;Shows</span>
                </button>
                &nbsp;
                {showaddbtn}
                &nbsp;
                {eventeditbtn}
                &nbsp;
                {liveviewbtn}
                {showNodes}
            	</div>
        );
}

export default ShowList;