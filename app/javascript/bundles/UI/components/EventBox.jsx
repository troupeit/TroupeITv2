import React, { useEffect, useState } from 'react';
import EventList from './EventList';
import { ACCESS_PRODUCER } from './constants';
import { checkCompanyAccess } from "./util";

import EventForm from './EventForm';

const EventBox = (props) => {
  const { companies, company, data, type, user, reloadCallback } = props;

  // If adding is true, we'll show the EventForm
  const [adding, setAdding] = useState(false);
  const [visible, setVisible] = useState(true);
  
  let title = type == "upcoming" ? "Upcoming Events" : "Past Events";

  useEffect(() => { 
    /* if this is set, we will open with the new event box available */
    if (window.location.search == "?sc=1") {
      setAdding(true);
    }
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
  
  var content = ( <i className="fas fa-spinner fa-spin"></i> );

  if (data == null) {
    return content;
  }

  if (adding == true) {
      var startDate = new Date();
      content = <EventForm 
                  onCreate={onCreate} 
                  defaultCompany={company} 
                  start_date={startDate} 
                  end_date={startDate}
                  companies={companies} 
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

  // fully collapsed
  var classList = "panel collapse";
  var acClassList = "accordian-toggle accordian-toggle-styled collapsed";
  
  if (visible == true) {
    classList = "panel-collapse in";
    acClassList = "accordian-toggle accordian-toggle-styled";
  }
  
  var typeLink = "#" + type;
  
  if (type == "upcoming") {
    title="Upcoming Events";

    if (checkCompanyAccess(companies, 'any', ACCESS_PRODUCER)) {
      if (adding) { 
        var newEventLink = ( <a href="#" onClick={handleClick}><button type="button" className="btn btn-danger btn-xs">
                              <i className="fa-solid fa-times"></i>&nbsp;
                              Cancel</button></a>);
      } else { 
        var newEventLink = ( <a href="#" onClick={handleClick}><button type="button" className="btn btn-info btn-xs"><i className="fa-solid fa-plus"></i> Create Event</button></a>);
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
    
  return (
    <div className="panel panel-inverse" id={`panel-${type}`}>
      <div className="panel-heading">
        <h4 className="panel-title">
          <a className={acClassList} onClick={toggleVisible} href={typeLink}>{title}</a>
        </h4>
        <div className="panel-heading-btn float-end">
        {newEventLink}
        <a href="#" 
          onClick={() => setVisible(true)} 
          className="btn btn-xs btn-icon btn-success"
          data-toggle="panel-expand">
            <i className="far fa-expand"></i></a>
            <a href="#" onClick={() => setVisible(false)} className="btn btn-xs btn-icon btn-warning" data-toggle="panel-collapse"><i className="far fa-minus"></i></a>
        </div>
      </div>
      <div id={`panel-body-${type}`} className={classList}>
        <div className="panel-body">
          {content}
          </div>
      </div>
    </div>
  );
};

export default EventBox;