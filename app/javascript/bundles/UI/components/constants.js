// utility functions used across all components
const ACCESS_PRODUCER = 8;
const ACCESS_STAGEMGR = 4;
const ACCESS_TECHCREW = 2;
const ACCESS_PERFORMER = 0;

const ACCESS_S = { 
  0 : "Performer",
  2 : "Technical Crew",
  4 : "Stage Manager",
  8 : "Producer"
};

const ASSET_SERVER = "https://d2x9yi7v90o6mz.cloudfront.net";

module.exports = {
  ACCESS_PERFORMER,
  ACCESS_TECHCREW,
  ACCESS_STAGEMGR,
  ACCESS_PRODUCER,
  ACCESS_S,
  ASSET_SERVER
}