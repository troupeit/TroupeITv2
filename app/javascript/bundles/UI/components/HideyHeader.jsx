import React from 'react';
import PropTypes from 'prop-types';

const HideyHeader = (props) => {
  const { type, content, hideable, id } = props;

  let iconcolor, iconname;
  switch (type) {
    case 'alert':
      iconcolor = 'red';
      iconname = 'fa fa-exclamation-circle';
      break;
    case 'warning':
      iconcolor = 'orange';
      iconname = 'fa fa-exclamation-triangle';
      break;
    case 'info':
      iconcolor = 'blue';
      iconname = 'fa fa-info-circle';
      break;
    case 'request':
      iconcolor = 'green';
      iconname = 'fa fa-question-circle';
      break;
    default:
      iconcolor = 'blue';
      iconname = 'fa fa-info-circle';
  }

  const icon = `<font color="${iconcolor}"><i class="${iconname}"></i>&nbsp;</font>`;
  const htmlContent = { __html: icon + content };

  const handleHide = (e) => {
    e.preventDefault();
    // Implement hide functionality here
  };

  return (
    <header id={id} className="account-alert">
      <span dangerouslySetInnerHTML={htmlContent}></span>
      {hideable && (
        <span className="dismiss">
          &nbsp;&nbsp;[<a href="#" onClick={handleHide}><i className="fa fa-times"></i></a>]
        </span>
      )}
    </header>
  );
};

HideyHeader.propTypes = {
  type: PropTypes.oneOf(['alert', 'warning', 'info', 'request']),
  content: PropTypes.string,
  hideable: PropTypes.bool,
  id: PropTypes.string.isRequired,
};

HideyHeader.defaultProps = {
  type: 'info',
  content: 'This is an informative message',
  hideable: false,
};

export default HideyHeader;