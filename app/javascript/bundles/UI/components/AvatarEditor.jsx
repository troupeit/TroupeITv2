import React, { useState } from 'react';
import $ from 'jquery';
import Avatar from './Avatar'; 

/**
 * AvatarEditor component
 * @param {Object} props - Component properties
 * @param {string} props.src - Source of the avatar image
 * @param {string} props.name - Name of the user
 * @param {string} props.email - Email of the user
 * @param {string} props.facebookId - Facebook ID of the user
 * @returns {JSX.Element} AvatarEditor component
 */
const AvatarEditor = ({ src, name, email, facebookId }) => {
  const [avatarSrc, setAvatarSrc] = useState(src);
  const [updating, setUpdating] = useState(false);

  /**
   * Set the image for the avatar
   * @param {Object} data - Data object containing filename and uuid
   */
  const setImage = (data) => {
    const extension = data.filename.substr(data.filename.lastIndexOf('.') + 1);
    const assetFilename = `${data.uuid}.${extension}`;
    const ajaxData = {
      user: {
        avatar_uuid: assetFilename
      }
    };

    setUpdating(true);

    $.ajax({
      type: 'POST',
      url: '/settings/update.json',
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(ajaxData),
      success: (response) => {
        setAvatarSrc(assetFilename);
        setUpdating(false);
      },
      error: (xhr, status, err) => {
        console.error('avatar update', status, err.toString());
        setUpdating(false);
      }
    });
  };

  /**
   * Start the photo change process
   * @param {Event} e - Event object
   */
  const startPhotoChange = (e) => {
    $(document).trigger("setAssetPickerCallback", setImage);
    $(document).trigger("setAssetPickerTitle", "Select an Image");
    $('#assetPicker').modal('show');
    e.preventDefault();
  };

  if (updating) {
    return (
      <div id="profile-img-updating" className="text-center">
        <span className="spinner-border text-secondary" role="status" style={{ fontSize: '4rem' }}></span>
      </div>
    );
  }

  return (
    <div id="profile-img" className="profile-img-container" onClick={startPhotoChange}>
      <Avatar name={name} email={email} facebookId={facebookId} round={true} src={avatarSrc} />
      <a href="#"><span className="bi bi-camera" style={{ fontSize: '4rem', color: "#888888" }}></span></a>
    </div>
  );
};

export default AvatarEditor;