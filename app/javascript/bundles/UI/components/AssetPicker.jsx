import React, { useState, useEffect } from 'react';
import $ from 'jquery';
import moment from 'moment';
import FileUpload from './FileUpload';
import { formatDuration, titleize, asset_embed_for } from './util';

/**
 * AssetPickerItem component
 * @param {Object} props - Component properties
 * @param {Object} props.asset - Asset details
 * @param {Function} props.uicallback - Callback function for UI
 * @returns {JSX.Element} AssetPickerItem component
 */
const AssetPickerItem = ({ asset, uicallback }) => {
  let drmwarning = "";
  const handleClick = (event) => {
    uicallback(asset);
    $('#assetPicker').modal('hide');
    soundManager.stopAll();
  };

  const owner = titleize(asset.user.username);
  const cdate = moment(asset.created_at);
  const cdate_s = cdate.format('dddd, MMMM Do, YYYY h:mm A');

  let title = "";
  if (asset.song_artist && asset.song_artist !== "") {
    title = asset.song_artist;
    if (asset.song_title && asset.song_title !== "") {
      title = `${title} - ${asset.song_title}`;
    } else if (asset.song_title) {
      title = asset.song_title;
    }
  }

  if (title === "") {
    title = asset.filename;
  }

  let assetdesc = asset.kind;
  let durstring = "";
  let preview = (<div className="previewcontrol"><i className="fa fa-file-o fa-5x"></i></div>);

  if (asset.processed === 0) {
    preview = (
      <span className="text-center fa-lg" style={{ width: "100px" }}>
        <i className="fa fa-spinner fa-spin fa-3x" style={{ width: "100px" }}></i>
      </span>
    );
  } else {
    if (asset.kind.indexOf("audio/") === 0) {
      if (asset.kind === "audio/m4p") {
        drmwarning = (<div><div className="badge bg-danger">File is protected with DRM and cannot be played</div><br /></div>);
      }

      const previewurl = asset_embed_for(asset);
      assetdesc = `${assetdesc}, ${asset.song_bitrate} Kbit bitrate`;
      durstring = `(${formatDuration(asset.song_length, false)})`;
      preview = (
        <div className="ui360">
          <a href={previewurl}></a>
        </div>
      );
    }

    if (asset.kind.indexOf("image/") === 0) {
      const imgembed = asset_embed_for(asset);
      assetdesc = `${assetdesc}, ${asset.img_size_x} x ${asset.img_size_y}`;
      preview = (
        <a href="#">
          <img src={imgembed} alt="Asset" />
        </a>
      );
    }
  }

  return (
    <div className="media asset_picker_row">
      <li className="media">
        <div className="media-left">
          {preview}
        </div>
        <div className="media-body">
          <h4 className="media-heading">
            <a href="#" onClick={handleClick}><strong>{title}</strong></a> {durstring}
          </h4>
          <p>
            {asset.filename}<br />
            {assetdesc}
          </p>
          {drmwarning}
          <p><small><em>{owner} - {cdate_s} ({cdate.fromNow()})</em></small></p>
        </div>
      </li>
    </div>
  );
};

/**
 * AssetPickerList component
 * @param {Object} props - Component properties
 * @param {Array} props.results - List of assets
 * @param {Function} props.reloadCallback - Callback function to reload data
 * @param {Function} props.uicallback - Callback function for UI
 * @returns {JSX.Element} AssetPickerList component
 */
const AssetPickerList = ({ results, reloadCallback, uicallback }) => {
  if (!results) {
    return (
      <div className="list-group">
        No results.
      </div>
    );
  }

  const pickeritems = results.map((d) => (
    <AssetPickerItem key={d._id.$oid} asset={d} reloadCallback={reloadCallback} uicallback={uicallback} />
  ));

  return (
    <ul className="media-list" style={{ height: '450px', overflow: 'scroll' }}>
      {pickeritems}
    </ul>
  );
};

/**
 * AssetPicker component
 * @param {Object} props - Component properties
 * @param {string} props.initialMimeType - Initial MIME type
 * @param {Function} props.reloadCallback - Callback function to reload data
 * @returns {JSX.Element} AssetPicker component
 */
const AssetPicker = ({ initialMimeType, reloadCallback }) => {
  const [results, setResults] = useState([]);
  const [term, setTerm] = useState('');
  const [sortoption, setSortoption] = useState(0);
  const [searchoption, setSearchoption] = useState(0);
  const [uicallback, setUicallback] = useState(null);
  const [title, setTitle] = useState("Select Media File");
  const [mimeType, setMimeType] = useState(initialMimeType || '');

  useEffect(() => {
    doSearch();

    $(document).on("setAssetPickerCallback", (event, callback) => {
      setUicallback(callback);
    });

    $(document).on("setAssetPickerKind", (event, mime_type) => {
      setMimeType(mime_type);
      doSearch();
    });

    $(document).on("setAssetPickerTitle", (event, arg1) => {
      setTitle(arg1);
    });

    $("#searchinprogress").hide();
    //$("[data-toggle='tooltip']").tooltip({ html: true });

    return () => {
      $(document).off("setAssetPickerCallback");
      $(document).off("setAssetPickerKind");
      $(document).off("setAssetPickerTitle");
    };
  }, []);

  const handleClose = (event) => {
    $('#assetPicker').modal('hide');
    $("#searcharea").show();
    soundManager.stopAll();
  };

  const finishUpload = (response) => {
    soundManager.stopAll();
    $("#searchinprogress").hide();
    setTerm('');
    setSearchoption(0);
    setSortoption(0);
    reloadResults();
  };

  const reloadResults = () => {
    $("#searchinprogress").show();

    $.ajax({
      url: `/passets/search.json?term=${term}&searchopt=${searchoption}&sortopt=${sortoption}&mimetype=${mimeType}`,
      dataType: 'json',
      success: (data) => {
        $("#searchinprogress").hide();
        if (data.length === 0) {
          setResults(null);
        } else {
          setResults(data);
          let needsreload = false;
          for (let i = 0; i < data.length; i++) {
            if (data[i].processed === 0) {
              needsreload = true;
            }
          }
          if (needsreload) {
            setTimeout(reloadResults, 3000);
          }
         
        }
      },
      error: (xhr, status, err) => {
        $("#searchinprogress").hide();
        console.error("search failed", status, err.toString());
      }
    });
  };

  const doSearch = () => {
    reloadResults();
  };

  const handleSearchBtn = (event) => {
    reloadResults();
    event.preventDefault();
  };

  const handleSearchBy = (event) => {
    setSearchoption(event.target.value);
  };

  const handleSortBy = (event) => {
    setSortoption(event.target.value);
  };

  const handleSearch = (event) => {
    setTerm(event.target.value);
  };

  const searchOptions = ['Your Files', 'Company Files'].map((m, index) => (
    <option value={index} key={m}>{m}</option>
  ));

  const sortOptions = ['Newest First', 'by Alpha (filename)'].map((m, index) => (
    <option value={index} key={m}>{m}</option>
  ));

  return (
    <div className="modal fade" id="assetPicker" tabIndex="-1" role="dialog" aria-labelledby="assetPickerLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" onClick={handleClose} className="btn-close" aria-label="Close"></button>
            <h4 className="modal-title" id="assetPickerLabel">{title}</h4>
          </div>
          <div className="modal-body">
            <FileUpload successCallback={finishUpload} ref="fileupload" />
            <div id="searcharea">
              <div className="row">
                <form className='form-horizontal'>
                  <div className="col-sm-3">
                    <select className="form-select" id='searchby' name='searchby' onChange={handleSearchBy}>
                      {searchOptions}
                    </select>
                  </div>
                  <div className="col-sm-3">
                    <select className="form-select" id='sortby' name='sortby' onChange={handleSortBy}>
                      {sortOptions}
                    </select>
                  </div>
                  <div className="col-sm-4">
                    <input type='text' className="form-control" placeholder='Search' onChange={handleSearch} />
                  </div>
                  <div className="col-sm-1">
                    <button className="btn btn-warning" onClick={handleSearchBtn}>
                      Search
                    </button>
                  </div>
                </form>
              </div>
              <AssetPickerList results={results} reloadCallback={reloadCallback} uicallback={uicallback} />
            </div>
            <div className="modal-footer">
              <span id="searchinprogress" className="float-start"><i className="fa fa-spinner fa-spin fa-2x"></i></span>
              <button type="button" className="btn btn-danger" onClick={handleClose}> Cancel </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AssetPicker;
