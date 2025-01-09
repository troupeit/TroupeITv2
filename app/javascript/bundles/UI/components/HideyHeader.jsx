import React from 'react';
import PropTypes from 'prop-types';

const HideyHeader = (props) => {
  const { id, type, hideable, html } = props;

  let iconcolor, iconname, alertType;

  switch (type) {
    case 'alert':
    case 'danger':
      iconcolor = 'red';
      alertType = 'danger';
      iconname = 'fa-solid fa-exclamation-circle fa-2x';
      break;
    case 'warning':
      iconcolor = 'orange';
      alertType = 'warning';
      iconname = 'fa-solid fa-exclamation-triangle fa-2x';
      break;
    case 'info':
      iconcolor = 'blue';
      alertType = 'info';
      iconname = 'fa-solid fa-info-circle fa-2x';
      break;
    case 'request':
    case 'success':
      iconcolor = 'green';
      alertType = 'success';
      iconname = 'fa-solid fa-check-circle fa-2x';
      break;
    default:
      iconcolor = 'blue';
      alertType = 'info';
      iconname = 'fa-solid fa-info-circle fa-2x';
  }

  const icon = `<span class="d-flex align-items-center me-2"><font color="${iconcolor}"><i class="${iconname}"></i>&nbsp;</font></span>`;
  const htmlContent = { 
    __html:  icon + html 
  };

  return (
    <div className={`alert alert-${alertType} alert-dismissible fade show d-flex align-items-center ${hideable ? 'alert-dismissible' : ''}`} role="alert" id={id}>
      <span className="d-flex align-items-center flex-fill" dangerouslySetInnerHTML={htmlContent}></span>
      { hideable && (<button type="button" class="btn-close" data-bs-dismiss="alert"></button>)}
    </div>
  );
};

HideyHeader.propTypes = {
  type: PropTypes.oneOf(['alert', 'warning', 'info', 'request', 'success', 'danger']),
  html: PropTypes.string,
  hideable: PropTypes.bool,
  id: PropTypes.string.isRequired,
};

HideyHeader.defaultProps = {
  type: 'info',
  html: 'This is an informative message',
  hideable: true,
};

export default HideyHeader;