import React, { useEffect, useState } from 'react';
import EventList from './EventList';
import { ACCESS_PRODUCER } from './constants';
import { checkCompanyAccess } from "./util";

const EventBox = (props) => {
  const { companies, company, data, type, user, reloadCallback } = props;

  const [adding, setAdding] = useState(false);
  const [visible, setVisible] = useState(false);
  
  let title = type == "upcoming" ? "Upcoming Events" : "Past Events";

  useEffect(() => { 
    var initialvisible = false;
    var initialadding = false;
    
    if (type == "upcoming") {
      var initialvisible = true;
    }

    /* if this is set, we will open with the new event box available */
    if (window.location.search == "?sc=1") {
      var initialadding = true;
    }
  
    setVisible(initialvisible);

   }, []);
  
  const toggleVisible = (event) => {
    let newState = !visible;
    setVisible(newState);
    
    if ( newState == false && adding == true) {
      setAdding(false);
    }
  };

  const handleClick = (index) => {
    setAdding(!adding);
    setVisible(true);
  };

  const onCreate = (event) => {
    setAdding(false);
    reloadCallback();
  };
  
  var content = ( <i className="fa fa-spinner fa-spin"></i> );

  if (data == null) {
    return content;
  }

  if (adding == true) {
      var sd = new Date();
      content = <EventForm 
                  companies={companies} 
                  onCreate={onCreate} 
                  defaultCompany={company} 
                  start_date={sd} 
                  end_date={sd} 
                  user={user} />;
  } else {
    content = <EventList 
                data={data} 
                company={company} 
                companies={companies} 
                reloadCallback={reloadCallback} 
                type={type} 
                user={user} />;
  }

  var classList = "panel collapse";
  var acClassList = "accordian-toggle accordian-toggle-styled collapsed";
  
  if (visible == true) {
    classList = "panel-collapse collapse in";
    acClassList = "accordian-toggle accordian-toggle-styled";
  }
  
  var typelink = "#" + props.type;
  
  if (props.type == "upcoming") {
    title="Upcoming Events";

    if (checkCompanyAccess(props.companies, 'any', ACCESS_PRODUCER)) {
      if (adding) { 
        var newEventLink = ( <a href="#" onClick={handleClick}><button type="button" className="btn btn-danger btn-xs">
                              <i className="fa fa-times"></i>&nbsp;
                              Cancel</button></a>);
      } else { 
        var newEventLink = ( <a href="#" onClick={handleClick}><button type="button" className="btn btn-info btn-xs"><i className="glyphicon glyphicon-plus"></i> Create Event</button></a>);
      }
    } else {
      var newEventLink = "";
    }
  } else { 
    title="Past Events";
    var newEventLink = "";
  }
  
  if (visible == false) {
    title = title + " (click to expand)";
  }
    
  return (<div className="panel panel-inverse" id={props.type}>
            <div className="panel-heading">
              <div className="btn-group float-end">
                {newEventLink}
              </div>
              <h3 className="panel-title">
                <a className={acClassList} onClick={toggleVisible} href={typelink}>{title}</a>
              </h3>
            </div>
            <div id={props.type} className={classList}>
              <div className="panel-body">
                {content}
                </div>
            </div>
          </div>
  );
};

export default EventBox;