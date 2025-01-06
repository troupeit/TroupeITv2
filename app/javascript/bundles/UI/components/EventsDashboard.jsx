import React, {useEffect, useState} from "react";
import CompanySelect from "./CompanySelect";

const EventsDashboard = (props) => {
  const [company, setCompany] = useState("all");
  const [data, setData] = useState([]);

  const reloadEvents = () => {
      $.ajax({
        url: "/events.json?t=" + props.type + "&company=" + company,
        dataType: 'json',
        success: function (data) {
          console.log("Reload of events on eventsdashboard")
          setData(data);
        }.bind(this),
        error: function (xhr, status, err) {
          console.error("eventsload", status, err.toString());
        }.bind(this)
      });
  };

  /* Load events on first load */
  useEffect(() => {
    reloadEvents();
  }, []);

  useEffect(() => {
    setCompany(props.company);
  }, [props.company]);
  
  const handleCompanyChange = (event) => {
    setCompany(event.target.value);
  };

  /*  if (this.props.companies.length == 0) { 
      return (<FirstTime user={this.props.user} reloadCallback={this.props.reloadCallback}/>);
    };
    */
  if (props.companies == null) {
    return (<div></div>);
  }

  return (
      <div>
      <CompanySelect companies={props.companies} callback={handleCompanyChange} value={company} showAll={true} />
      { /*    <div className="panel-group" id="eventacc">
          <EventBox type="upcoming" company={this.state.company} companies={this.props.companies} user={this.props.user} data={this.state.data} reloadCallback={this.reloadEvents} />
          <EventBox type="past" company={this.state.company} companies={this.props.companies} user={this.props.user} data={this.state.data} reloadCallback={this.reloadEvents} />
          </div>
          */}
      </div>
  );
};

export default EventsDashboard;
