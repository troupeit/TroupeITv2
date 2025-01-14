import moment from 'moment';
import { ACCESS_TECHCREW, ASSET_SERVER } from './constants';

/**
 * Protect window.console method calls, e.g. console is not defined on IE
 * unless dev tools are open, and IE doesn't define console.debug
 */
(() => {
  const methods = ["assert", "cd", "clear", "count", "countReset", "debug", "dir", "dirxml", "error", "exception", "group", "groupCollapsed", "groupEnd", "info", "log", "markTimeline", "profile", "profileEnd", "select", "table", "time", "timeEnd", "timeStamp", "timeline", "timelineEnd", "trace", "warn"];
  const console = (window.console = window.console || {});
  methods.forEach(method => {
    if (!console[method]) {
      console[method] = () => {};
    }
  });
})();

/**
 * Create a cookie
 * @param {string} name - Cookie name
 * @param {string} value - Cookie value
 * @param {number} days - Number of days until expiration
 */
const createCookie = (name, value, days) => {
  let expires = "";
  if (days) {
    if (days === -1) {
      expires = "; expires=Tue, 19 Jan 2038 03:14:07 UTC";
    } else {
      const date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      expires = "; expires=" + date.toGMTString();
    }
  }
  document.cookie = `${encodeURIComponent(name)}=${encodeURIComponent(value)}${expires}; path=/`;
};

/**
 * Read a cookie
 * @param {string} name - Cookie name
 * @returns {string|null} - Cookie value or null if not found
 */
const readCookie = (name) => {
  const nameEQ = `${encodeURIComponent(name)}=`;
  const ca = document.cookie.split(';');
  for (let c of ca) {
    c = c.trim();
    if (c.indexOf(nameEQ) === 0) return decodeURIComponent(c.substring(nameEQ.length));
  }
  return null;
};

/**
 * Erase a cookie
 * @param {string} name - Cookie name
 */
const eraseCookie = (name) => {
  createCookie(name, "", -1);
};

/**
 * Pad a number with leading zeros
 * @param {number} n - Number to pad
 * @returns {string} - Padded number
 */
const pad = (n) => {
  return n < 10 ? `0${n}` : n;
};

/** Regexp for duration values */
var durationRegexp=/^([0-2][0-3](:[0-9][0-9]){2})|([0-9]{1,2}:[0-5][0-9])$/;

/**
 * Format duration in seconds to HH:MM:SS
 * @param {number} n - Duration in seconds
 * @param {boolean} addPlus - Whether to add a plus sign
 * @returns {string} - Formatted duration
 */
const formatDuration = (n, addPlus) => {
  const h = Math.floor(n / 3600);
  const m = Math.floor((n - (h * 3600)) / 60);
  const s = n - h * 3600 - m * 60;
  return `${addPlus ? "+" : ""}${pad(h)}:${pad(m)}:${pad(s)}`;
};

/**
 * Convert duration string to seconds
 * @param {string} value - Duration string (HH:MM:SS or MM:SS)
 * @returns {number} - Duration in seconds
 */
const durationToSec = (value) => {
  const parts = value.split(':');
  let secs = 0;
  if (parts.length === 3) {
    secs += parseInt(parts[0]) * 3600;
    secs += parseInt(parts[1]) * 60;
    secs += parseInt(parts[2]);
  } else {
    secs += parseInt(parts[0]) * 60;
    secs += parseInt(parts[1]);
  }
  return secs;
};

/**
 * Check company access level
 * @param {Array} cmdata - Company membership data
 * @param {string} company_id - Company ID
 * @param {number} minaccess - Minimum access level
 * @returns {boolean} - Whether the user has access
 */
const checkCompanyAccess = (cmdata, company_id, minaccess) => {
  if (!cmdata || !company_id) return false;

  let access = false;
  cmdata.forEach(value => {
    if (value.company_id === company_id || company_id === 'any') {
      const now = moment().utc();
      if (minaccess >= ACCESS_TECHCREW) {
        if (value.company.paid_through) {
          const paid_through = moment(value.company.paid_through).utc();
          if (paid_through.isAfter(now) && value.access_level >= minaccess) {
            access = true;
          }
        } else {
          const trial_expires = moment(value.company.user.trial_expires_at).utc();
          if (trial_expires.isAfter(now) && value.access_level >= minaccess) {
            access = true;
          }
        }
      }
    }
  });

  return access;
};

/**
 * Check password strength
 * @param {HTMLInputElement} pw - Password input element
 */
const check_pwstrength = (pw) => {
  const colors = ['progress-bar-danger', 'progress-bar-danger', 'progress-bar-warning', 'progress-bar-success', 'progress-bar-success'];
  const data = { 'pw': pw.value };

  $.ajax({
    type: "POST",
    url: "/api/v1/password/check",
    dataType: "json",
    contentType: "application/json",
    data: JSON.stringify(data),
    success: (result) => {
      const value = result['score'] * 25;
      const width = value === 0 && pw.value.length > 0 ? 10 : value;
      $('#pwstrengthbar').css('width', `${width}%`).attr('aria-valuenow', width);
      $('#pwstrengthbar').attr('class', `progress-bar ${colors[result['score']]}`);
    },
    error: (xhr, status, err) => {
      console.error("passwordcheck", status, err.toString());
    }
  });
};

/**
 * Update and check password strength
 * @param {Event} e - Event object
 */
const update_and_checkpw = (e) => {
  check_pwstrength(e.target);

  if ($("#showpw").is(':checked')) {
    $("#user_password").val($('#user_password_confirmation').val());
  } else {
    $("#user_password_confirmation").val($('#user_password').val());
  }
};

/**
 * Reverse an array
 * @param {Array} a - Array to reverse
 * @returns {Array} - Reversed array
 */
const revArr = (a) => {
  return a.slice().reverse();
};

/**
 * Render switcher elements
 */
const renderSwitcher = () => {
  $("[data-render=switchery]").each(function() {
    const colorMap = {
      red: "#ff5b57",
      blue: "#348fe2",
      purple: "#727cb6",
      orange: "#f59c1a",
      black: "#2d353c"
    };
    const color = colorMap[$(this).attr("data-theme")] || "#00acac";
    const options = {
      color,
      secondaryColor: $(this).attr("data-secondary-color") || "#dfdfdf",
      className: $(this).attr("data-classname") || "switchery",
      disabled: $(this).attr("data-disabled") ? true : false,
      disabledOpacity: $(this).attr("data-disabled-opacity") || 0.5,
      speed: $(this).attr("data-speed") || "0.5s"
    };
    new Switchery(this, options);
  });
};

/**
 * Parse query string into an object
 */
(($) => {
  $.QueryString = ((a) => {
    if (a === "") return {};
    const b = {};
    a.forEach(p => {
      const [key, value] = p.split('=');
      if (key && value) {
        b[key] = decodeURIComponent(value.replace(/\+/g, " "));
      }
    });
    return b;
  })(window.location.search.substr(1).split('&'));
})(jQuery);

/**
 * Titleize a string
 * @param {string} title - String to titleize
 * @returns {string} - Titleized string
 */
const titleize = (title) => {
  return title.split(' ').map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()).join(' ');
};

/**
 * Get asset thumbnail path
 * @param {Object} asset - Asset object
 * @param {number} w - Width
 * @param {number} h - Height
 * @returns {string} - Thumbnail path
 */
const asset_thumb_path = (asset, w, h) => {
  return `${asset.uuid}.thumb-${w}x${h}`;
};

/**
 * Get asset download URL
 * @param {Object} asset - Asset object
 * @returns {string} - Download URL
 */
const asset_download_for = (asset) => {
  const ext = asset.filename.includes('.') ? `.${asset.filename.split('.').pop()}` : "";
  return `${ASSET_SERVER}/uploads/${asset.uuid}${ext}`;
};

/**
 * Get asset embed URL
 * @param {Object} asset - Asset object
 * @returns {string} - Embed URL
 */
const asset_embed_for = (asset) => {
  if (!asset) return undefined;
  if (asset.kind.startsWith("audio/")) return asset_download_for(asset);
  if (asset.kind.startsWith("image/")) return `${ASSET_SERVER}/thumbs/${asset_thumb_path(asset, 100, 100)}.jpg`;
};

/**
 * Get asset file URL for download
 * @param {Object} asset - Asset object
 * @returns {string} - File URL
 */
const asset_getfile_for = (asset) => {
  const safe_fn = asset.filename.replace(/[^a-z0-9\.]/gi, '_').replace(/[_]+/gi, '_');
  return `/gf/getfile?uuid=${asset.uuid}&downloadas=${safe_fn}`;
};

/**
 * Convert bytes to human-readable size
 * @param {number} bytes - Number of bytes
 * @returns {string} - Human-readable size
 */
const bytesToSize = (bytes) => {
  const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
  if (bytes === 0) return '0 bytes';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${Math.round(bytes / Math.pow(1024, i), 2)} ${sizes[i]}`;
};

/**
 * Truncate filename with ellipsis
 * @param {string} str - Filename
 * @param {number} maxlength - Maximum length
 * @returns {string} - Truncated filename
 */
const truncateFilename = (str, maxlength) => {
  if (!str) return undefined;
  return str.length > maxlength ? `${str.substring(0, 20)}...${str.substring(str.length - 10)}` : str;
};

/**
 * Enforce maxlength on input
 * @param {HTMLInputElement} oInObj - Input element
 * @param {string} outSel - Selector for output element
 */
const enforce_maxlength = (oInObj, outSel) => {
  const iMaxLen = parseInt(oInObj.getAttribute('maxlength'));
  if (oInObj.value.length > iMaxLen) {
    oInObj.value = oInObj.value.substring(0, iMaxLen);
  }
  $(outSel).html(iMaxLen - oInObj.value.length);
};

/**
 * Get FontAwesome icon class for mimetype
 * @param {string} mimetype - Mimetype
 * @returns {string} - FontAwesome icon class
 */
const get_fa_icon = (mimetype) => {
  const parts = mimetype.split("/");
  const fasize = "text-center fa fa-4x";
  switch (parts[0]) {
    case "audio":
      return `${fasize} fa-file-audio-o`;
    case "image":
      return `${fasize} fa-file-image-o`;
    case "video":
      return `${fasize} fa-file-video-o`;
    case "error":
      return `${fasize} fa-exclamation-circle`;
    default:
      return `${fasize} fa-file-o`;
  }
};

export {
  asset_download_for,
  asset_embed_for,
  asset_getfile_for,
  asset_thumb_path,
  bytesToSize,
  check_pwstrength,
  checkCompanyAccess,
  createCookie,
  durationRegexp,
  durationToSec,
  enforce_maxlength,
  eraseCookie,
  formatDuration,
  get_fa_icon,
  pad,
  readCookie,
  renderSwitcher,
  revArr,
  titleize,
  truncateFilename,
  update_and_checkpw
};
