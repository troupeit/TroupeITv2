import React, { useEffect } from "react";

import { ACCESS_PRODUCER } from "./constants";
import { checkCompanyAccess } from "./util";

import Show from "./Show";
import ShowForm from "./ShowForm";

const ShowList = (props) => {

  const { reloadCallback, company, user, event_id, time_zone } = props;

  const [ data, setData ] = useState([]);
  const [ editing, setEditing ] = useState(false);
  const [ adding, setAdding ] = useState(false);
  const [ expanded, setExpanded ] = useState(false);
  const [ showform_expanded, setShowFormExpanded ] = useState(false);

  const reloadShows = () => {
    console.log("reload shows event.");
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
  });
  
  const postChange = () => {
    console.log("post change");  
    reloadCallback(); // notify the parent. 
    reloadShows();
  };

  const expand = (e) => {
    if (expanded == false) {
      reloadShows(); 
    }

    newstate = !expanded
    setExpanded(newstate);

    if (newstate == true) {

      this.setState({showform_expanded: false});
    }
    
    e.preventDefault(); 
  };

  const toggleShowForm = (e) => {
      newstate = !showform_expanded;    
      setShowFormExpanded(newstate);

      /* state doesn't immediately update */
      if (newstate == true) { 
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

  if (showform_expanded) {
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
    
  if (checkCompanyAccess(user, company._id.$oid, ACCESS_PRODUCER)) { 
    var showaddbtn = ( <button className="btn btn-sm btn-success" onClick={this.toggleShowForm}>
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

      if (checkCompanyAccess(user, company._id.$oid, ACCESS_TECHCREW)) {
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
                <button className="btn btn-sm btn-success" onClick={this.expand}>
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