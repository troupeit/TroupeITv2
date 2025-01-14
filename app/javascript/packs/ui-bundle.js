import ReactOnRails from 'react-on-rails';

// Components here need to be registered if they are ever accessed via 
// react_component directly. If a component is accessed from another component,
// it does not need to be registered here and can be directly imported

import ActivityFeed from '../bundles/UI/components/ActivityFeed';
import AssetPicker from '../bundles/UI/components/AssetPicker';
import Avatar from '../bundles/UI/components/Avatar';
import AvatarEditor from '../bundles/UI/components/AvatarEditor';
import ConfirmModal from '../bundles/UI/components/ConfirmModal';
import DashboardApp from '../bundles/UI/components/DashboardApp';
import EventsApp from "../bundles/UI/components/EventsApp";

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  ActivityFeed,
  AssetPicker,
  Avatar,
  AvatarEditor,
  ConfirmModal,
  DashboardApp,
  EventsApp
});
