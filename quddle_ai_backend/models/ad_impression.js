// quddle_ai_backend/models/ad_impression.js

/**
 * Ad Impression Model
 * Tracks each time an ad is displayed to a user.
 */

const AdImpression = {
  tableName: 'ad_impressions',
  fields: {
    id: 'uuid', // primary key, default gen_random_uuid()
    ad_id: 'uuid', // not null, references ads.id (CASCADE on delete)
    user_id: 'uuid', // not null, track which user saw the ad
    reel_id: 'uuid', // not null, track which reel showed the ad
    created_at: 'timestamptz', // not null, default now()
  },
};

module.exports = AdImpression;
  