import React, { useEffect, useState } from 'react';
import CompanyListItem from './CompanyListItem';

const CompanyList = (props) => {
  const [companies, setCompanies] = useState(null);
  const [loaded, setLoaded] = useState(false);
  
  useEffect(() => {
     $.ajax({
       url: "/company_memberships.json",
       dataType: 'json',
       success: function(data) {
        setCompanies(data);
        setLoaded(true);
       }.bind(this),
       error: function(xhr, status, err) {
         console.error("company_memberships", status, err.toString());
       }.bind(this)
     });
  }, []);

  var companyNodes = "";

  if (loaded == false || !companies) {
    companyNodes = ( <li className="list-group-item"><i className="fa fa-spinner fa-spin"></i></li> );
  } else {
    if (companies.length == 0) { 
      companyNodes = (<li className="list-group-item"><strong>No memberships.</strong></li> );
    } else {
      companyNodes = companies.map(function (company) {
        return (
            <CompanyListItem company={company} key={company.company._id} thisuser={company.user_id} owner={company.company.user} accesslevel={company.access_level} callback={props.changeCallback.bind(null,company.company._id)} />
        );
      });
    }
  }

  return (
      <div className="panel panel-inverse">
        <div className="panel-heading">
        <h3 className="panel-title float-start">
          Companies
        </h3>
          <div className="btn-group float-end">
            <a href="/companies/new">
              <button type="button" className="btn btn-xs btn-info me-1">
              <i className="fa fa-plus"></i>&nbsp;<span>New</span>
              </button>
            </a>
            <a href="/companies/">
              <button className="btn btn-xs btn-info">
                <i className="fa fa-edit"></i>&nbsp;<span>Manage</span>
              </button>
            </a>
          </div>
        </div>
        <ul className="list-group">
        {companyNodes}
        </ul>
    </div>
  );
};

export default CompanyList;