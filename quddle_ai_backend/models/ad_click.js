// quddle_ai_backend/models/ad_click.js

/**
 * Ad Click Model
 * Tracks each time a user clicks on an ad.
 */

const AdClick = {
  tableName: 'ad_clicks',
  fields: {
    id: 'uuid', // primary key, default gen_random_uuid()
    ad_id: 'uuid', // not null, references ads.id (CASCADE on delete)
    user_id: 'uuid', // nullable, track which user clicked
    reel_id: 'uuid', // nullable, track which reel showed the ad
    created_at: 'timestamptz', // not null, default now()
  },
};

module.exports = AdClick;
  