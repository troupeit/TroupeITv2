// util.js
import moment from 'moment';
import { ACCESS_TECHCREW } from './constants';

/**
 * Protect window.console method calls, e.g. console is not defined on IE
 * unless dev tools are open, and IE doesn't define console.debug
 * 
 * Chrome 41.0.2272.118: debug,error,info,log,warn,dir,dirxml,table,trace,assert,count,markTimeline,profile,profileEnd,time,timeEnd,timeStamp,timeline,timelineEnd,group,groupCollapsed,groupEnd,clear
 * Firefox 37.0.1: log,info,warn,error,exception,debug,table,trace,dir,group,groupCollapsed,groupEnd,time,timeEnd,profile,profileEnd,assert,count
 * Internet Explorer 11: select,log,info,warn,error,debug,assert,time,timeEnd,timeStamp,group,groupCollapsed,groupEnd,trace,clear,dir,dirxml,count,countReset,cd
 * Safari 6.2.4: debug,error,log,info,warn,clear,dir,dirxml,table,trace,assert,count,profile,profileEnd,time,timeEnd,timeStamp,group,groupCollapsed,groupEnd
 * Opera 28.0.1750.48: debug,error,info,log,warn,dir,dirxml,table,trace,assert,count,markTimeline,profile,profileEnd,time,timeEnd,timeStamp,timeline,timelineEnd,group,groupCollapsed,groupEnd,clear
 */
(function() {
  // Union of Chrome, Firefox, IE, Opera, and Safari console methods
  var methods = ["assert", "cd", "clear", "count", "countReset",
                 "debug", "dir", "dirxml", "error", "exception", "group", "groupCollapsed",
                 "groupEnd", "info", "log", "markTimeline", "profile", "profileEnd",
                 "select", "table", "time", "timeEnd", "timeStamp", "timeline",
                 "timelineEnd", "trace", "warn"];
  var length = methods.length;
  var console = (window.console = window.console || {});
  var method;
  var noop = function() {};
  while (length--) {
    method = methods[length];
    // define undefined methods as noops to prevent errors
    if (!console[method])
      console[method] = noop;
  }
})();

/* Basic Cookie Handling */
function createCookie(name, value, days) {
  var expires;
  
  if (days) {
    var expires; 
    if (days == -1) {
      expires = "; expires=Tue, 19 Jan 2038 03:14:07 UTC";
    } else { 
      var date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      expires = "; expires=" + date.toGMTString();
    }
  } else {
    expires = "";
  }
  document.cookie = encodeURIComponent(name) + "=" + encodeURIComponent(value) + expires + "; path=/";
}

function readCookie(name) {
  var nameEQ = encodeURIComponent(name) + "=";
  var ca = document.cookie.split(';');
  for (var i = 0; i < ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) === ' ') c = c.substring(1, c.length);
    if (c.indexOf(nameEQ) === 0) return decodeURIComponent(c.substring(nameEQ.length, c.length));
  }
  return null;
}

function eraseCookie(name) {
  createCookie(name, "", -1);
}

/* Time Formats */

/* --- Duration Handling ---------------------------------------- */
/* permit mm:ss or hh:mm, also permit large minutes (90:00, etc.) */
var duration_re=/^([0-2][0-3](:[0-9][0-9]){2})|([0-9]{1,2}:[0-5][0-9])$/;

/* support functions for dates, move this to a utility someplace. */
function pad(n) {
    return (n < 10) ? ("0" + n) : n;
}

function formatDuration(n, addPlus) {
  
  let h = Math.floor(n / 3600);
  let m = Math.floor((n - (h * 3600)) / 60);
  let s = n - h * 3600 - m * 60;
  let plus_s = "";

  if (addPlus) {
    plus_s = "+";
  }
  
  return(plus_s + pad(h) + ":" + pad(m) + ":" + pad(s));
}

function durationToSec(value) {

  /* convert HH:MM:SS or MM:SS into seconds. This assumes you've
   * already validated value with the duration_re above.
   * Don't call this prior to validating. 
   */
  
  var parts = value.split(':');
  secs = 0;
  if (parts.length == 3) {
    secs = secs + parseInt(parts[0]) * (60 * 60);
    secs = secs + parseInt(parts[1]) * (60);
    secs = secs + parseInt(parts[2]);
  } else {
    secs = secs + parseInt(parts[0]) * (60);
    secs = secs + parseInt(parts[1]);
  }
  return secs;
}

function checkCompanyAccess(cmdata, company_id, minaccess) {
  /* returns true if your access is at or greater than minaccess 
   * and if the company is paid up -- the beauty of this is that
   * when your account expires you can't demote user access 
   * or move it, because the account is locked... 
   */
  
  if (cmdata == null) { return false }
  if (company_id == null) { return false }

  var access=false;
  $.each(cmdata, function (index, value) {
    if ((value.company_id == company_id) || (company_id == 'any')) {
      let now = moment().utc();
      /* if trial expired, maximum access can only be tech crew */
      if (minaccess >= ACCESS_TECHCREW) {
        if (value.company.paid_through != null) {
          let paid_through = moment(value.company.paid_through).utc();
          if (paid_through.isAfter(now) && value.access_level >= minaccess) {
            access = true;
          }
        } else { 
          let trial_expires = moment(value.company.user.trial_expires_at).utc();
          if (trial_expires.isAfter(now) && value.access_level >= minaccess) {
            access = true;
          }
        }
      }
    }
  });

  /* Now we have to handle paid vs. not paid */

  /* If company has a paid through date (and is current)
   *   return access
   * else
   *   if the company owner is in a valid trial period
   *      return access
   *   else (the company is unpaid.)
   *      if minaccess > TECH_CREW, return false. 
   *   end
   * end 
   */

  return access;
}

/* these functions are used on login pages */
function check_pwstrength(pw) {
  
  var colors = ['progress-bar-danger',
                'progress-bar-danger',
                'progress-bar-warning',
                'progress-bar-success',
                'progress-bar-success' ];

  var pw = pw.value;
  var data = { 'pw': pw };

  $.ajax({
    type: "POST",
    url: "/api/v1/password/check",
    dataType: "json",
    contentType: "application/json",
    data: JSON.stringify(data),
    success: function(result) {
      value = result['score'] * 25;
      if (value == 0 && pw.length > 0)  { value = 10 }; /* just enough to color it. */
      $('#pwstrengthbar').css('width', value + '%').attr('aria-valuenow', value);
      $('#pwstrengthbar').attr('class', 'progress-bar ' + colors[result['score']]);
    },
    error: function(xhr, status,err) {
      console.error("passwordcheck", status, err.toString());
    }
  });
}

function update_and_checkpw(e) {
  check_pwstrength(e);
  
  if ($( "#showpw" ).is(':checked')) {
    $( "#user_password" ).val( $('#user_password_confirmation').val() );
  } else {
    $( "#user_password_confirmation" ).val( $('#user_password').val() );
  }
}

function revArr(a) {
  var temp = [];
  var len = a.length;

  for (var i = (len - 1); i >= 0; i--) {
    temp.push(a[i]);
  }
  
  return temp;
}

/* support code to render switches on page */
var green = "#00acac",
    red = "#ff5b57",
    blue = "#348fe2",
    purple = "#727cb6",
    orange = "#f59c1a",
    black = "#2d353c";
    
var renderSwitcher = function() {
  if ($("[data-render=switchery]").length !== 0) {
    $("[data-render=switchery]").each(function() {
      var e = green;
      if ($(this).attr("data-theme")) {
        switch ($(this).attr("data-theme")) {
        case "red":
          e = red;
          break;
        case "blue":
          e = blue;
          break;
        case "purple":
          e = purple;
          break;
        case "orange":
          e = orange;
          break;
        case "black":
          e = black;
          break
        }
      }
      var t = {};
      t.color = e;
      t.secondaryColor = $(this).attr("data-secondary-color") ? $(this).attr("data-secondary-color") : "#dfdfdf";
      t.className = $(this).attr("data-classname") ? $(this).attr("data-classname") : "switchery";
      t.disabled = $(this).attr("data-disabled") ? true : false;
      t.disabledOpacity = $(this).attr("data-disabled-opacity") ? $(this).attr("data-disabled-opacity") : .5;
      t.speed = $(this).attr("data-speed") ? $(this).attr("data-speed") : "0.5s";
      var n = new Switchery(this, t)
    })
  }
};

/* a very small jQuery-esque plugin to handle querystring */
/* http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript */

(function($) {
    $.QueryString = (function(a) {
        if (a == "") return {};
        var b = {};
        for (var i = 0; i < a.length; ++i)
        {
            var p=a[i].split('=');
            if (p.length != 2) continue;
            b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
        }
        return b;
    })(window.location.search.substr(1).split('&'))
})(jQuery);


/* titleize from rails */
function titleize(title) {
  var words = title.split(' ');
  var array = [];

  for (var i=0; i<words.length; ++i) {
    array.push(words[i].charAt(0).toUpperCase() + words[i].toLowerCase().slice(1));
  }

  return array.join(' ');
}

/* array remove */
// Array Remove - By John Resig (MIT Licensed)
Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

/* javascript version of embed_for */
function asset_thumb_path(asset,w,h) {
  return asset.uuid + ".thumb-" + w + "x" + h 
}

function asset_download_for(asset) {

  /* append the extension if we have one */
  if ( asset.filename.lastIndexOf('.') != -1 ) { 
    var ext = "." + asset.filename.substr(asset.filename.lastIndexOf('.') + 1);
  } else {
    var ext = "";
  }

  return ASSET_SERVER + "/uploads/" + asset.uuid + ext;
}

function asset_embed_for(asset) {
  if (asset == undefined) {
    return undefined;
  }

  if (asset.kind.lastIndexOf("audio/",0) === 0) {
    return asset_download_for(asset);
  }
  if (asset.kind.lastIndexOf("image/",0) === 0) {  
    return ASSET_SERVER + "/thumbs/" + asset_thumb_path(asset,100,100) + '.jpg';
  }
}

function asset_getfile_for(asset) {
  /* this will send the user to our getfile server which will remap
   * the name into something sensible for download. This regexp
   * whitelist is a bit severe but very safe. */
  var safe_fn = asset.filename.replace(/[^a-z0-9\.]/gi, '_');
  safe_fn = safe_fn.replace(/[_]+/gi, '_');
  
  return "/gf/getfile?uuid=" + asset.uuid + "&downloadas=" + safe_fn;
}


function bytesToSize(bytes) {
  var sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
  if (bytes == 0) return '0 bytes';

  var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
  return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
};


function truncateFilename(str, maxlength) {
  /* mac-os style truncation, for filenames */
  if (str === undefined) {
    return undefined;
  }

  if (str.length > maxlength) {
    return str.substring(0, 20) + "..." + str.substring(str.length-10,str.length);
  } else {
    return str
  }
}
  
function enforce_maxlength(oInObj, outSel)
{
  var iMaxLen = parseInt(oInObj.getAttribute('maxlength'));
  var iCurLen = oInObj.value.length;

  if ( oInObj.getAttribute && iCurLen > iMaxLen )
  {
    oInObj.value = oInObj.value.substring(0, iMaxLen);
  }

  // update the count
  $(outSel).html(iMaxLen - oInObj.value.length);

} 

function get_fa_icon(mimetype) {
  /* return a font awesome icon class based on a mimetype */
  var parts = mimetype.split("/");
  var fasize  ="text-center fa fa-4x"
  switch(parts[0]) {
  case "audio":
    return fasize + " fa-file-audio-o";
    break;
  case "image":
    return fasize + " fa-file-image-o";
    break;
  case "video":
    return fasize + " fa-file-video-o";
    break;
  case "error":
    return fasize + " fa-exclamation-circle";
  default:
    return fasize + " fa-file-o";
  }
}

export {
  checkCompanyAccess,
  check_pwstrength,
  createCookie,
  durationToSec,
  eraseCookie,
  formatDuration,
  pad,
  readCookie,
  renderSwitcher,
  revArr,
  titleize,
  update_and_checkpw,
  bytesToSize,
  truncateFilename,
};
