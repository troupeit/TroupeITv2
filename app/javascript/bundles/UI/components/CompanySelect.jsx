const CompanySelect = (props) => {
  if (props.companies == undefined) {
    return (<div><i className="fa fa-spinner fa-spin"></i></div>);
  }

  console.log("CompanySelect", props.companies);
  
  var companyNodes = props.companies.map(function (company) {
    return (
        <option key={company.company_id.$oid} value={company.company_id.$oid}>{company.company.name}</option>
    );
  });

  if (props.showAll == true) {
    // have to do this as two vars or the select will fail.
    var showall=(<option value="all">All events in all companies</option>);
    var showallsep=(<option value="" disabled className="separator"></option>);
  }

  return (
    <div className="form-group">
        <form role="form">
          <select className="form-control" name="companysel" id="companysel" onChange={props.callback} value={props.company}>
            {showall}
            {showallsep}
            {companyNodes}
          </select>
        </form>
      </div>
  );
};

export default CompanySelect;
