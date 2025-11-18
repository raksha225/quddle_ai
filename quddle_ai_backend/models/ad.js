// quddle_ai_backend/models/ad.js

/**
 * Ad Model
 * Represents an advertisement created by an advertiser.
 */

const Ad = {
  tableName: 'ads',
  fields: {
    id: 'uuid', // primary key, default gen_random_uuid()
    advertiser_id: 'uuid', // not null, reference to the advertiser/user
    image_url: 'text', // not null, S3/CloudFront URL
    link_url: 'text', // not null, destination URL
    title: 'text', // not null
    payment_amount: 'numeric', // not null, e.g., 100.00
    target_impressions: 'bigint', // not null, e.g., 100
    current_impressions: 'bigint', // not null, default 0
    current_clicks: 'bigint', // not null, default 0
    status: 'text', // not null, default 'pending', enum: 'pending', 'active', 'expired', 'paused'
    created_at: 'timestamptz', // not null, default now()
    updated_at: 'timestamptz', // not null, default now()
    expires_at: 'timestamptz', // not null, calculated based on impressions
  },
};

module.exports = Ad;
  