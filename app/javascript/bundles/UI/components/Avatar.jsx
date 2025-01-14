// based on react-avar
// https://www.npmjs.com/package/react-avatar

import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { ASSET_SERVER } from './constants';

const Avatar = (props) => {
  const [src, setSrc] = useState(null);
  const [value, setValue] = useState(null);
  const [triedFacebook, setTriedFacebook] = useState(false);
  const [triedGoogle, setTriedGoogle] = useState(false);
  const [triedSkype, setTriedSkype] = useState(false);
  const [triedGravatar, setTriedGravatar] = useState(false);

  const getProtocol = () => {
    if (typeof window === 'undefined') return 'https:';
    return window.location.protocol;
  };

  const parse = (value, variables) => {
    for (const variable in variables) {
      value = value.replace(`<%=${variable}%>`, variables[variable]);
    }
    return value;
  };

  const getGravatarURL = (email, size, cb) => {
    let base = 'gravatar.com/avatar/<%=id%>?s=<%=size%>';

    let emailHash = "";

    if (email.indexOf('@') > -1) {
      // roll a random salt to improve privacy
      const salt = 'bbb8d599239a8e4b0939db798e80448e';
      emailHash = CryptoJS.SHA256( `${salt}${email}` );
    }

    const prefix = getProtocol() === 'https:' ? 'https://secure.' : 'http://';
    cb(prefix + parse(base, { id: emailHash, size: size }));
  };

  const getFacebookURL = (id, size, cb) => {
    let base = 'graph.facebook.com/<%=id%>/picture?width=<%=size%>';
    cb(getProtocol() + '//' + parse(base, { id: id, size: size }));
  };

  const getGoogleURL = (id, size, cb, tryNext) => {
    let base = 'picasaweb.google.com/data/entry/api/user/<%=id%>?alt=json';
    let url = getProtocol() + '//' + parse(base, { id: id });
    fetch(url)
      .then(response => response.json())
      .then(data => {
        let src = data.entry.gphoto$thumbnail.$t.replace('s64', 's' + size);
        cb(src);
      })
      .catch(tryNext);
  };

  const getSkypeURL = (id, size, cb) => {
    let base = 'api.skype.com/users/<%=id%>/profile/avatar';
    cb(getProtocol() + '//' + parse(base, { id: id }));
  };

  const getColor = (name) => {
    const colors = ['#d73d32', '#7e3794', '#4285f4', '#67ae3f', '#d61a7f', '#ff4080'];
    const index = (name ? name.charCodeAt(0) : 0) % colors.length;
    return colors[index];
  };

  const getInitials = (name) => {
    return name
      .split(' ')
      .map(part => part.charAt(0).toUpperCase())
      .join('');
  };

  const fetchAvatar = (e) => {
    let url = null;

    const tryNext = () => {
      fetchAvatar();
    };

    if (url === null && props.src) {
      if (!props.src.startsWith('http://') && !props.src.startsWith('https://')) {
        let newsrc = props.src.replace('.', `.thumb-${_bestsize(props.size)}.`);
        newsrc = `${ASSET_SERVER}/thumbs/${newsrc}`;
        setSrc(newsrc);
        return;
      }

      setSrc(parse(props.src, { size: props.size }));
      return;
    }

    if (e && e.type === 'error') setSrc(null);

    if (!triedFacebook && !url && props.facebookId) {
      setTriedFacebook(true);
      getFacebookURL(props.facebookId, props.size, setSrc, tryNext);
      return;
    }

    if (!triedGoogle && !url && props.googleId) {
      setTriedGoogle(true);
      getGoogleURL(props.googleId, props.size, setSrc, tryNext);
      return;
    }

    if (!triedSkype && !url && props.skypeId) {
      setTriedSkype(true);
      getSkypeURL(props.skypeId, props.size, setSrc, tryNext);
      return;
    }

    if (!triedGravatar && !url && props.email) {
      setTriedGravatar(true);
      getGravatarURL(props.email, props.size, setSrc, tryNext);
      return;
    }

    if (src) return;

    if (props.name) setValue(getInitials(props.name));

    if (!props.name && props.value) setValue(props.value);
  };

  useEffect(() => {
    fetchAvatar();
  }, []);

  const _bestsize = (siz) => {
    const sizelist = [400, 200, 100];
    for (let i = sizelist.length; i > -1; i--) {
      if (siz >= sizelist[i]) {
        return `${sizelist[i]}x${sizelist[i]}`;
      }
    }
    return `${sizelist[sizelist.length - 1]}x${sizelist[sizelist.length - 1]}`;
  };

  const getVisual = () => {
    const imageStyle = {
      maxWidth: '100%',
      width: props.size,
      height: props.size,
      borderRadius: props.round ? 500 : 0,
    };

    const initialsStyle = {
      background: getColor(props.name),
      width: props.size,
      height: props.size,
      font: `${Math.floor(props.size / 3)}px/100px Helvetica, Arial, sans-serif`,
      color: '#fff',
      textAlign: 'center',
      textTransform: 'uppercase',
      lineHeight: `${props.size + Math.floor(props.size / 10)}px`,
      display: 'inline-block',
      borderRadius: props.round ? 500 : 0,
      border: '1px #000 ',
    };

    if (src) {
      return (
        <img
          width={props.size}
          height={props.size}
          style={imageStyle}
          src={src}
          onError={fetchAvatar}
          className={props.imgClasses}
        />
      );
    } else {
      return <div style={initialsStyle}>{value}</div>;
    }
  };

  const hostStyle = {
    display: 'inline-block',
    width: props.size,
    height: props.size,
    borderRadius: props.round ? 500 : 0,
  };

  const visual = getVisual();

  if (props.inline) {
    return (
      <div className={props.addClasses}>
        {visual}&nbsp;&nbsp;&nbsp;&nbsp;
        {props.name}&nbsp;
      </div>
    );
  }

  if (props.navstyle) {
    return (
      <div className={props.addClasses}>
        {visual}&nbsp;&nbsp;&nbsp;&nbsp;
        {props.name}&nbsp;
        <span className="caret"></span>
      </div>
    );
  } else {
    return <div style={hostStyle}>{visual}</div>;
  }
};

Avatar.propTypes = {
  name: PropTypes.string,
  value: PropTypes.string,
  email: PropTypes.string,
  facebookId: PropTypes.string,
  googleId: PropTypes.string,
  skypeId: PropTypes.string,
  round: PropTypes.bool,
  size: PropTypes.number,
  src: PropTypes.string,
  imgClasses: PropTypes.string,
  addClasses: PropTypes.string,
  inline: PropTypes.bool,
  navstyle: PropTypes.bool,
};

Avatar.defaultProps = {
  name: null,
  value: null,
  email: null,
  facebookId: null,
  skypeId: null,
  googleId: null,
  round: false,
  size: 100,
  src: null,
  imgClasses: '',
  addClasses: '',
  inline: false,
  navstyle: false,
};

export default Avatar;