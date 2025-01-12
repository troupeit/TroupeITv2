import {
  ACCESS_PRODUCER,
  ACCESS_STAGEMGR,
  ACCESS_S,
} from "./constants.js";

import { truncateFilename } from "./util.js";

import moment from 'moment';

const CompanyListItem = (props) => {
  
  const showInviteModal = (e) =>  {
    // broadcast the event to the window. we'll pick this up in the Modal. 
    evt = new CustomEvent("showInviteModal", {
      detail: {
        company: props.company.company._id
      }
    });
    window.dispatchEvent(evt);
    e.preventDefault();
  };

  var company_id = props.company.company._id;
  var mylink    = "/profiles/" + company_id  + "/company";
  var fileslink = "/passets/?company_id=" + company_id;
  var actslink  = "/acts/?company_id=" + company_id;
  var settingslink = "/companies/" + company_id + "/edit";
  var paylink   = "/companies/" + company_id + "/billing";
  var linkblock = "";
  
  if (props.accesslevel == ACCESS_PRODUCER) {
    var invitelink = (<a href="#" onClick={showInviteModal}><button className="btn btn-info btn-xs">Invite</button></a>);
  }

  if (props.thisuser == props.owner._id) {
    var ownerBadge = (<span className="badge pill-rounded bg-dark float-end">OWNER</span>);
  }

  var now = moment().utc();
  /* if you have paid us once, use that date */
  if (props.company.company.paid_through != null) {
    var paid_through = moment(props.company.company.paid_through).utc();
  } else {
    var paid_through = undefined
  }

  /* trial should never be null, but... */
  if (props.company.company.user.trial_expires_at != null) {
    var trial_expires_at = moment(props.company.company.user.trial_expires_at).utc();
  } else {
    var trial_expires_at = moment().utc().subtract('1','day');
  }

  var trial_expires_str="This trial ends on " + moment(props.company.company.user.trial_expires_at).format("L");

  if (typeof(paid_through) !== "undefined" ) { 
    /* previously paid customer logic here */
    if (now.isAfter(paid_through)) {
      var ownerBadge = (<a href={paylink}><span className="badge pill-rounded badge-danger float-end"
                        data-toggle="tooltip"
                        data-placement="left"
                        title="Payment for this company could not be completed and your company is now read-only. Click to purchase a subscription.">PAYMENT DUE</span></a>);
    }
  } else {
    /* never paid for but after trial */
    if (now.isAfter(trial_expires_at)) {
      if (props.company.company.last_payment == null) {
        var ownerBadge = (<a href={paylink}><span className="badge pill-rounded badge-danger float-end"
                          data-toggle="tooltip"
                          data-placement="left"
                          title="The trial period for your account has ended and your company is now read-only. Click to purchase a subscription.">TRIAL ENDED</span></a>);
      } else {
        var ownerBadge = (<a href={paylink}><span className="badge pill-rounded badge-danger float-end"
                          data-toggle="tooltip"
                          data-placement="left"
                          title="Payment for this company could not be completed and your company is now read-only. Click to select a new plan.">CANCELLED</span></a>);
      }
    } else {
      var ownerBadge = (<a href={paylink}><span className="badge pill-rounded badge-success float-end"
                        data-toggle="tooltip"
                        data-placement="left"
                        title={trial_expires_str}>TRIAL</span></a>);
    }
  }

  if (props.accesslevel >= ACCESS_STAGEMGR) {  
    var linkblock = ( <div className="float-end">
                      {invitelink}&nbsp;
                      <a href={fileslink}><button className="btn btn-info btn-xs">Files</button></a>&nbsp;
                      <a href={actslink}><button className="btn btn-info btn-xs">Acts</button></a>&nbsp;
                      <a href={settingslink}><button className="btn btn-info btn-xs" style={{height: "22px"}}><i className="fas fa-gear"></i></button></a>
                      </div> );
  }
  
  return (
    <li className="list-group-item">
      <h5><a href={mylink}>{truncateFilename(props.company.company.name, 30)}</a>{ownerBadge}</h5>
      {ACCESS_S[props.accesslevel]}
      {linkblock}<br/>
    </li>
  );
};

export default CompanyListItem;
