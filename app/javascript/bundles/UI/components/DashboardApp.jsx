import React, { useState, useEffect } from "react";
import Avatar from "./Avatar";
import ConfirmModal from "./ConfirmModal";
import CompanyList from "./CompanyList";
import EventsDashboard from "./EventsDashboard";
import HideyHeader from "./HideyHeader";
import ActsList from "./ActsList";
import ActivityFeed from "./ActivityFeed";

import { ACCESS_PRODUCER } from "./constants";

import moment from "moment";
import "moment-timezone";

const DashboardApp = (props) => {
  const [alerts, setAlerts] = useState([]);
  const [companyAlerts, setCompanyAlerts] = useState([]);
  const [company, setCompany] = useState("all");
  const [companyMemberships, setCompanyMemberships] = useState(null);
  const [userRecord, setUserRecord] = useState(null);

  console.log("DashboardApp props: ", props);

  useEffect(() => {
    reloadCompanyMemberships();
    reloadUserRecord();
  }, []);

  const checkCompanyStatus = () => {
    /* show a warning on the top of the dashboard if the user has an
     * unpaid or expired account. We will only show one line, for the
     * last company that expired. If more than one company expires,
     * we'll get to it after they pay for the first one.  */
    var statusAlerts = [];

    if (!companyMemberships) {
      return;
    }

    for (var i = 0; i < companyMemberships.length; i++) {
      /* we will only show messaging to company owners or producers. */
      if (
        companyMemberships[i].user_id ==
          companyMemberships[i].company.user_id ||
        companyMemberships[i].access_level == ACCESS_PRODUCER
      ) {
        var now = moment().utc();
        var paid_through = null;

        /* if you have paid us once, use that date */
        if (companyMemberships[i].company.paid_through != null) {
          paid_through = moment(
            companyMemberships[i].company.paid_through
          ).utc();
        }

        /* trial should never be null, but... */
        if (companyMemberships[i].company.user.trial_expires_at != null) {
          var trial_expires_at = moment(
            companyMemberships[i].company.user.trial_expires_at
          ).utc();
        } else {
          var trial_expires_at = moment().utc().subtract("1", "day");
        }

        var buynowtext =
          '"' +
          companyMemberships[i].company.name +
          '". <a href="/companies/' +
          companyMemberships[i].company._id +
          '/billing">Select a plan</a> to continue using this company.</span>';

        if (companyMemberships[i].company.payment_failed == true) {
          statusAlerts.push({
            html:
              "We're having a problem charging your credit card for \"" +
              companyMemberships[i].company.name +
              '". <a href="/settings/edit_card" class="alert-link">Update your credit card</a> to continue using this company.</span>',
            hideable: false,
          });
        }

        if (paid_through == null && trial_expires_at.isBefore(now)) {
          /* expired trial, if user has paid before, say so. */
          if (companyMemberships[i].company.last_payment == null) {
            statusAlerts.push({
              html: "The free trial has ended for " + buynowtext,
              hideable: false,
            });
          } else {
            statusAlerts.push({
              html: "We were unable to process payment for " + buynowtext,
              hideable: false,
            });
          }
        } else {
          /* prior subscriber */
          if (
            typeof paid_through !== "undefined" &&
            now.isAfter(paid_through)
          ) {
            statusAlerts.push({
              html: "The paid subscription has ended for " + buynowtext,
              hideable: false,
            });
          }
        }

        /* is the trial about to end? */
        if (
          companyMemberships[i].company.paid_through == null &&
          trial_expires_at.isAfter(now)
        ) {
          if (moment.duration(trial_expires_at.diff(now)).asDays() <= 5) {
            statusAlerts.push({
              html:
                'Your trial for "' +
                companyMemberships[i].company.name +
                '" expires ' +
                moment.duration(trial_expires_at.diff(now)).humanize("days") +
                '. <a href="/companies/' +
                companyMemberships[i].company._id +
                '/billing" class="alert-link">Select a plan now</a> to ensure continued access.</a>.</span>',
              hideable: false,
            });
          }
        }
      }
    }

    setCompanyAlerts(statusAlerts);
  };

  const reloadCompanyMemberships = () => {
    /* reload the user */
    $.ajax({
      url: "/company_memberships.json",
      dataType: "json",
      success: function (data) {
        setCompanyMemberships(data);
        console.log("successful cm load.");
        checkCompanyStatus();
      }.bind(this),
      error: function (xhr, status, err) {
        console.log("Company Memberships load error");
      }.bind(this),
    });
  };

  const reloadUserRecord = () => {
    /* reload the user */
    $.ajax({
      url: "/users/me.json",
      dataType: "json",
      success: function (data) {
        setUserRecord(data);
        console.log("successful ur load.");

        /* alert processing -- all alerts should be added here. */
        let newAlerts = [];

        if (data.user.email_valid == false) {
          newAlerts.push({
            html:
              'Please <a href="/settings/edit" class="alert-link"">update your email address</a> now. Your login provider, ' +
              titleize(data.user.provider) +
              ", did not provide one.<br>An email address is requires for invites and account recovery.",
            type: "alert",
            id: "email-warning",
            hideable: false,
          });
        }
        if (
          !(
            data.user.phone_number &&
            data.user.sms_capable &&
            data.user.sms_confirmed
          )
        ) {
          // test
          newAlerts.push({
            type: "warning",
            html: '<a href="/settings/edit" class="alert-link">Confirm your mobile number now</a>&nbsp;to receive event reminders.',
            id: "confirm_sms_nag2",
            hideable: true
          });
        }
        console.log("newAlerts: ", newAlerts);

        setAlerts(newAlerts);
      }.bind(this),
      error: function (xhr, status, err) {
        console.log("UR load error");
      }.bind(this),
    });
  };

  /*
  JNA: This is for the walk through / trial account work, leave it out for now.

  componentDidUpdate: function() {
    $('.trialhelp').popover({
      'title': 'Trial Account',
      'trigger':'hover', 
      'html' : true, 
      'container' : 'body', 
      'placement' : 'right',
      'content': "While a trial account is active you can create one company and have up to two crew members in that company. When your trial ends, your companies will be set to read-only until you purchase a subscription. Note that this only applies to companies that you personally create and own. If you are invited to a (paid) company by anyone else, your trial status has no bearing on the other company."});
    
    $('[data-toggle="popover"]').popover();
    
  },
  componentDidMount: function()  {
    if (readCookie("login_tutorial") == "true") {
      $(ReactDOM.findDOMNode(refs.tipModal)).modal("show");
      eraseCookie("login_tutorial");
    }
    
  },
  */

  const companyChanged = (company) => {
    setCompany(company);
  };
  const showEdit = () => {
    $("#profEditButton").fadeIn("fast");
  };

  const hideEdit = () => {
    $("#profEditButton").fadeOut("fast");
  };

  // render

  // group all of the alerts in one place, organized. This prevent clobbering
  // when multiple alerts are active
  var cnt = 0;
  var alertHeaders = alerts.map(function (a) {
    cnt++;
    return (
      <HideyHeader
        type={a.type}
        html={a.html}
        id={a.id}
        hideable={a.hideable}
        key={cnt}
      />
    );
  });

  var companyAlertHeaders = companyAlerts.map(function (a) {
    cnt++;
    return (
      <HideyHeader
        type={a.type}
        html={a.html}
        id={a.id}
        hideable={a.hideable}
        key={cnt}
      />
    );
  });

  if (companyMemberships) {
    if (companyMemberships?.length > 0) {
      var hasCompaniesBlock = (
        <div>
          <CompanyList changeCallback={companyChanged} user={userRecord} />
          {<ActivityFeed />}
        </div>
      );
    } else {
      var hasCompaniesBlock = <div></div>;
    }
  }

  return (
    <div className="container">
      {alertHeaders}
      {companyAlertHeaders}
      <div id="dashboardapp-instance">
        <div className="row">
          <div className="col-sm-4 col-12">
            <div className="card mb-4">
              <div
                className="card-body"
                onMouseEnter={showEdit}
                onMouseLeave={hideEdit}
              >
                <div className="d-flex align-items-center">
                  <a className="me-3" href="#">
                    <Avatar
                      name={props.name}
                      facebookId={props.facebookId}
                      src={props.avatar_uuid}
                      size={64}
                      round={true}
                    />
                  </a>
                  <div className="flex-grow-1">
                    <h4 className="card-title mb-1">{props.name}</h4>
                    <p className="card-text">{props.email}</p>
                  </div>
                  <div className="ms-auto">
                    <a href="/settings/edit/">
                      <button
                        type="button"
                        className="btn btn-outline-secondary btn-sm"
                        style={{ display: "none" }}
                        id="profEditButton"
                      >
                        Edit profile
                      </button>
                    </a>
                  </div>
                </div>
              </div>
            </div>
            {hasCompaniesBlock}
          </div>
          <div className="col col-sm-8 col-xs-12">
            {
              <EventsDashboard
                company={company}
                companies={companyMemberships}
                user={userRecord}
                reloadCallback={reloadCompanyMemberships}
              />
            }
            <div className="panel panel-inverse">
              <div className="panel-heading">
                <h3 className="panel-title">Acts</h3>
                <div className="btn-group float-end">
                  <a href="/passets">
                    <button
                      type="button"
                      className="btn btn-info btn-xs float-end me-1"
                    >
                      <i className="far fa-file"></i> Your Files
                    </button>
                  </a>
                  <a href="/acts/new">
                    <button
                      type="button"
                      className="btn btn-info btn-xs float-end"
                    >
                      <i className="fas fa-plus"></i> Create Act
                    </button>
                  </a>
                </div>
              </div>
              <div className="panel-body">{<ActsList company={company} />}</div>
            </div>
          </div>
        </div>
      </div>
      {
        <ConfirmModal ref="confirmModal" />
        /*
    <SubmissionPicker ref="submissionPicker" />
    <TipModal ref="tipModal" {...props} />
    <InviteModal ref="inviteModal" {...props} />
    */
      }
    </div>
  );
};

export default DashboardApp;
