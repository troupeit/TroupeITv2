import ReactOnRails from 'react-on-rails';

// Components here need to be registered if they are ever accessed from 
// react_component directly. 

import Avatar from '../bundles/UI/components/Avatar';
import ConfirmModal from '../bundles/UI/components/ConfirmModal';
import DashboardApp from '../bundles/UI/components/DashboardApp';
import ActivityFeed from '../bundles/UI/components/ActivityFeed';

// This is how react_on_rails can see the HelloWorld in the browser.
console.log('registering avatar');

ReactOnRails.register({
  ActivityFeed,
  Avatar,
  ConfirmModal,
  DashboardApp
});
