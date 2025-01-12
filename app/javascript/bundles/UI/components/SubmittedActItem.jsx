import React, { useState } from "react";
import Avatar from "./Avatar";

/**
 * SubmittedActItem component
 * @param {Object} props - Component properties
 * @param {Object} props.act - Act details
 * @param {string} props.id - Act ID
 * @param {boolean} props.is_alternate - Is alternate act
 * @param {string} props.return_to - Return URL
 * @returns {JSX.Element} SubmittedActItem component
 */
const SubmittedActItem = ({ act, id, is_alternate, return_to }) => {
  const [selected, setSelected] = useState(false);

  /**
   * Handle checkbox change
   * @param {Event} e - Event object
   */
  const changed = (e) => {
    setSelected(e.target.checked);
  };

  const current_href = $(".nav-tabs .active a").attr("href");
  let showid;
  if (current_href) {
    const parts = current_href.split("-");
    if (parts.length === 2) {
      showid = parts[1];
    }
  }

  const actlink = `/acts/${act.act._id.$oid}/edit?${return_to}`;
  const tagslist = act.act.tags.map((t, index) => (
    <span key={index} className="badge bg-info me-1">{t}</span>
  ));

  const altbadge = is_alternate && (
    <span className="badge bg-warning text-dark">ALTERNATE</span>
  );

  return (
    <li className="media media-item-act list-group-item" key={id}>
      <div className="media-left media-middle">
        <Avatar name={act.user.name} facebookId={act.user.uid} src={act.user.avatar_uuid} size={64} round={true} />
      </div>
      <div className="media-body">
        <h5 className="media-heading">
          <a href={actlink}>
            <strong>{act.act.stage_name}</strong>
          </a> &nbsp;
          <small>({formatDuration(act.act.length)})</small>
        </h5>
        {altbadge}
        <p className="list-group-item-text">
          <strong>{act.user.name}</strong> <br />
          {act.act.short_description}
        </p>
      </div>
      <div className="media-right">
        <input type="checkbox" className="form-check-input sacheckbox" onChange={changed} />
      </div>
      <div className="tagbox">
        {tagslist}
      </div>
    </li>
  );
};

export default SubmittedActItem;
