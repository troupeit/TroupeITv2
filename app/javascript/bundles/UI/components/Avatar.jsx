import React from "react";

const Avatar = () => {
  return (
    <span className="avatar avatar-sm avatar-online">  
      <div className="image image-icon bg-gray-800 text-gray-600">
        <i className="fa fa-user"></i>
      </div>
      <span className="d-none d-md-inline">Adam Schwartz</span>
        <b className="caret"></b>
      </span> 
  );
};

export default Avatar;
