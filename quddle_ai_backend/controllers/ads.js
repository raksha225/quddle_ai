// Ads Controller
const { supabase } = require('../config/database');
const {
  createPresignedPutUrlForAds,
  s3AdsBucket,
  awsRegion,
  headObject
} = require('../config/aws');
const { v4: uuidv4 } = require('uuid');

// Initialize Stripe (if STRIPE_SECRET_KEY is set)
let stripe = null;
try {
  const stripeKey = process.env.STRIPE_SECRET_KEY;
  if (stripeKey) {
    stripe = require('stripe')(stripeKey);
  }
} catch (error) {
  console.warn('Stripe not installed. Install with: npm install stripe');
}


const createAd = async (req, res) => {
  try {
    const user = req.user;
    const { title, link_url, payment_amount, target_impressions, contentType, sizeBytes } = req.body;

    // Validate required fields
    if (!title || !link_url || !payment_amount || !target_impressions) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: title, link_url, payment_amount, target_impressions'
      });
    }

    // Validate payment amount
    if (Number(payment_amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Payment amount must be greater than 0'
      });
    }

    // Validate target impressions
    if (Number(target_impressions) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Target impressions must be greater than 0'
      });
    }

    // Validate URL format
    const urlPattern = /^https?:\/\/.+/;
    if (!urlPattern.test(link_url)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid link_url format'
      });
    }

    let imageUrl = null;
    let imageKey = null;

    // Handle image upload if contentType is provided
    if (contentType && contentType.startsWith('image/')) {
      // Validate image size (max 10MB for ads)
      const maxBytes = 10 * 1024 * 1024; // 10MB
      if (sizeBytes && Number(sizeBytes) > maxBytes) {
        return res.status(400).json({
          success: false,
          message: 'Image file too large (max 10MB)'
        });
      }

      const adId = uuidv4();
      const ext = (() => {
        if (contentType === 'image/jpeg') return 'jpg';
        if (contentType === 'image/png') return 'png';
        if (contentType === 'image/webp') return 'webp';
        const part = contentType.split('/')[1];
        return part || 'jpg';
      })();
      imageKey = `ads/${user.id}/${adId}.${ext}`;

      // Generate presigned URL for image upload
      const presignedUrl = await createPresignedPutUrlForAds({
        key: imageKey,
        contentType,
        expiresInSeconds: 900 // 15 minutes
      });

      // Build image URL (will be used after upload)
      imageUrl = s3AdsBucket.includes('.')
        ? `https://s3.${awsRegion}.amazonaws.com/${encodeURIComponent(s3AdsBucket)}/${imageKey}`
        : `https://${s3AdsBucket}.s3.${awsRegion}.amazonaws.com/${imageKey}`;

      // Create ad record with pending status (will be activated after payment)
      const { data, error } = await supabase
        .from('ads')
        .insert({
          id: adId,
          advertiser_id: user.id,
          image_url: imageUrl,
          link_url: link_url,
          title: title,
          payment_amount: Number(payment_amount),
          target_impressions: Number(target_impressions),
          current_impressions: 0,
          current_clicks: 0,
          status: 'pending',
          expires_at: new Date().toISOString() // Will be updated after payment
        })
        .select()
        .single();

      if (error) {
        console.error('Failed to create ad:', error);
        return res.status(400).json({
          success: false,
          message: 'Failed to create ad',
          error: error.message
        });
      }

      return res.status(201).json({
        success: true,
        ad: data,
        uploadUrl: presignedUrl,
        imageKey: imageKey,
        message: 'Ad created. Upload image using the presigned URL, then proceed with payment.'
      });
    } else {
      // If no image upload, return error (image is required)
      return res.status(400).json({
        success: false,
        message: 'Image upload is required. Provide contentType (image/jpeg, image/png, etc.)'
      });
    }
  } catch (error) {
    console.error('createAd error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// GET /api/ads - List all active ads (for display)
// auth: not required (public endpoint)
const getActiveAds = async (req, res) => {
  try {
    // Get all active ads that haven't reached target impressions
    const { data, error } = await supabase
      .from('ads')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Failed to get active ads:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch active ads',
        error: error.message
      });
    }

    // Filter out expired ads (where current_impressions >= target_impressions)
    const activeAds = (data || []).filter(ad => 
      ad.current_impressions < ad.target_impressions
    );

    return res.status(200).json({
      success: true,
      ads: activeAds,
      count: activeAds.length
    });
  } catch (error) {
    console.error('getActiveAds error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// GET /api/ads/my - List advertiser's own ads (requires auth)
const getMyAds = async (req, res) => {
  try {
    const user = req.user; // From authMiddleware

    // Get all ads created by this advertiser
    const { data, error } = await supabase
      .from('ads')
      .select('*')
      .eq('advertiser_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Failed to get advertiser ads:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch your ads',
        error: error.message
      });
    }

    return res.status(200).json({
      success: true,
      ads: data || [],
      count: (data || []).length
    });
  } catch (error) {
    console.error('getMyAds error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// GET /api/ads/:id - Get specific ad details
// auth: not required (public endpoint)
const getAdById = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Get ad by ID
    const { data, error } = await supabase
      .from('ads')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        // No rows returned
        return res.status(404).json({
          success: false,
          message: 'Ad not found'
        });
      }
      console.error('Failed to get ad:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch ad',
        error: error.message
      });
    }

    if (!data) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    return res.status(200).json({
      success: true,
      ad: data
    });
  } catch (error) {
    console.error('getAdById error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Simple in-memory rate limiter for impressions
// TODO: Replace with proper rate limiting middleware (e.g., express-rate-limit or Redis-based)
const impressionRateLimit = new Map(); // IP -> { count, resetTime }
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 100; // Max 100 impressions per minute per IP

const checkRateLimit = (ip) => {
  const now = Date.now();
  const record = impressionRateLimit.get(ip);

  if (!record || now > record.resetTime) {
    // Reset or create new record
    impressionRateLimit.set(ip, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW
    });
    return true;
  }

  if (record.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false; // Rate limit exceeded
  }

  record.count++;
  return true;
};

// POST /api/ads/:id/impression - Record ad impression (public, rate-limited)
const recordImpression = async (req, res) => {
  try {
    // Rate limiting check
    const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
    if (!checkRateLimit(clientIp)) {
      return res.status(429).json({
        success: false,
        message: 'Too many requests. Please try again later.'
      });
    }

    const { id: adId } = req.params;
    const { user_id, reel_id } = req.body;

    // Validate UUID format for ad_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(adId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Validate required fields
    if (!user_id || !reel_id) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: user_id, reel_id'
      });
    }

    // Validate UUID format for user_id and reel_id
    if (!uuidRegex.test(user_id) || !uuidRegex.test(reel_id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user_id or reel_id format'
      });
    }

    // Check if ad exists and is active
    const { data: ad, error: adError } = await supabase
      .from('ads')
      .select('*')
      .eq('id', adId)
      .single();

    if (adError || !ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    // Check if ad has reached target impressions
    if (ad.current_impressions >= ad.target_impressions) {
      return res.status(400).json({
        success: false,
        message: 'Ad has reached its target impressions'
      });
    }

    // Check if ad is active
    if (ad.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Ad is not active'
      });
    }

    // Record impression in ad_impressions table
    const { data: impression, error: impressionError } = await supabase
      .from('ad_impressions')
      .insert({
        ad_id: adId,
        user_id: user_id,
        reel_id: reel_id
      })
      .select()
      .single();

    if (impressionError) {
      console.error('Failed to record impression:', impressionError);
      return res.status(500).json({
        success: false,
        message: 'Failed to record impression',
        error: impressionError.message
      });
    }

    // Update ad's current_impressions count atomically
    const { error: updateError } = await supabase
      .from('ads')
      .update({
        current_impressions: ad.current_impressions + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', adId);

    if (updateError) {
      console.error('Failed to update ad impressions:', updateError);
      // Impression was recorded but count update failed - log for manual fix
      return res.status(500).json({
        success: false,
        message: 'Impression recorded but failed to update count',
        error: updateError.message
      });
    }

    // Check if ad should be marked as expired
    const newImpressionCount = ad.current_impressions + 1;
    if (newImpressionCount >= ad.target_impressions) {
      await supabase
        .from('ads')
        .update({
          status: 'expired',
          updated_at: new Date().toISOString()
        })
        .eq('id', adId);
    }

    return res.status(201).json({
      success: true,
      impression: impression,
      message: 'Impression recorded successfully'
    });
  } catch (error) {
    console.error('recordImpression error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// POST /api/ads/:id/click - Record ad click (public, rate-limited)
const recordClick = async (req, res) => {
  try {
    // Rate limiting check (reuse same rate limiter)
    const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
    if (!checkRateLimit(clientIp)) {
      return res.status(429).json({
        success: false,
        message: 'Too many requests. Please try again later.'
      });
    }

    const { id: adId } = req.params;
    const { user_id, reel_id } = req.body;

    // Validate UUID format for ad_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(adId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Validate UUID format for user_id and reel_id if provided (they are optional)
    if (user_id && !uuidRegex.test(user_id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user_id format'
      });
    }

    if (reel_id && !uuidRegex.test(reel_id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid reel_id format'
      });
    }

    // Check if ad exists
    const { data: ad, error: adError } = await supabase
      .from('ads')
      .select('*')
      .eq('id', adId)
      .single();

    if (adError || !ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    // Check if ad is active (clicks can still be recorded even if expired, but let's check status)
    if (ad.status === 'pending' || ad.status === 'paused') {
      return res.status(400).json({
        success: false,
        message: 'Ad is not active'
      });
    }

    // Record click in ad_clicks table (user_id and reel_id are optional)
    const clickData = {
      ad_id: adId
    };

    if (user_id) {
      clickData.user_id = user_id;
    }

    if (reel_id) {
      clickData.reel_id = reel_id;
    }

    const { data: click, error: clickError } = await supabase
      .from('ad_clicks')
      .insert(clickData)
      .select()
      .single();

    if (clickError) {
      console.error('Failed to record click:', clickError);
      return res.status(500).json({
        success: false,
        message: 'Failed to record click',
        error: clickError.message
      });
    }

    // Update ad's current_clicks count atomically
    const { error: updateError } = await supabase
      .from('ads')
      .update({
        current_clicks: ad.current_clicks + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', adId);

    if (updateError) {
      console.error('Failed to update ad clicks:', updateError);
      // Click was recorded but count update failed - log for manual fix
      return res.status(500).json({
        success: false,
        message: 'Click recorded but failed to update count',
        error: updateError.message
      });
    }

    return res.status(201).json({
      success: true,
      click: click,
      message: 'Click recorded successfully'
    });
  } catch (error) {
    console.error('recordClick error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// PUT /api/ads/:id - Update ad (requires auth, owner only)
const updateAd = async (req, res) => {
  try {
    const user = req.user; // From authMiddleware
    const { id: adId } = req.params;
    const { title, link_url, status, expires_at } = req.body;

    // Validate UUID format for ad_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(adId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Check if ad exists
    const { data: ad, error: adError } = await supabase
      .from('ads')
      .select('*')
      .eq('id', adId)
      .single();

    if (adError || !ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    // Verify user is the owner
    if (ad.advertiser_id !== user.id) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to update this ad'
      });
    }

    // Build update object with only provided fields
    const updateData = {
      updated_at: new Date().toISOString()
    };

    // Validate and add title if provided
    if (title !== undefined) {
      if (!title || typeof title !== 'string' || title.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Title cannot be empty'
        });
      }
      updateData.title = title.trim();
    }

    // Validate and add link_url if provided
    if (link_url !== undefined) {
      const urlPattern = /^https?:\/\/.+/;
      if (!urlPattern.test(link_url)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid link_url format'
        });
      }
      updateData.link_url = link_url;
    }

    // Validate and add status if provided
    if (status !== undefined) {
      const validStatuses = ['pending', 'active', 'paused', 'expired'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
        });
      }
      updateData.status = status;
    }

    // Validate and add expires_at if provided
    if (expires_at !== undefined) {
      const expiresDate = new Date(expires_at);
      if (isNaN(expiresDate.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid expires_at date format'
        });
      }
      updateData.expires_at = expiresDate.toISOString();
    }

    // Check if there's anything to update
    if (Object.keys(updateData).length === 1) {
      // Only updated_at was added, no actual fields to update
      return res.status(400).json({
        success: false,
        message: 'No fields provided to update'
      });
    }

    // Update the ad
    const { data: updatedAd, error: updateError } = await supabase
      .from('ads')
      .update(updateData)
      .eq('id', adId)
      .select()
      .single();

    if (updateError) {
      console.error('Failed to update ad:', updateError);
      return res.status(500).json({
        success: false,
        message: 'Failed to update ad',
        error: updateError.message
      });
    }

    return res.status(200).json({
      success: true,
      ad: updatedAd,
      message: 'Ad updated successfully'
    });
  } catch (error) {
    console.error('updateAd error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// DELETE /api/ads/:id - Delete ad (requires auth, owner only)
const deleteAd = async (req, res) => {
  try {
    const user = req.user; // From authMiddleware
    const { id: adId } = req.params;

    // Validate UUID format for ad_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(adId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Check if ad exists
    const { data: ad, error: adError } = await supabase
      .from('ads')
      .select('*')
      .eq('id', adId)
      .single();

    if (adError || !ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    // Verify user is the owner
    if (ad.advertiser_id !== user.id) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to delete this ad'
      });
    }

    // Delete the ad (CASCADE will automatically delete related impressions and clicks)
    const { error: deleteError } = await supabase
      .from('ads')
      .delete()
      .eq('id', adId);

    if (deleteError) {
      console.error('Failed to delete ad:', deleteError);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete ad',
        error: deleteError.message
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Ad deleted successfully'
    });
  } catch (error) {
    console.error('deleteAd error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// POST /api/ads/:id/payment - Initiate Stripe payment (requires auth, owner only)
const initiatePayment = async (req, res) => {
  try {
    // Check if Stripe is configured
    if (!stripe) {
      return res.status(503).json({
        success: false,
        message: 'Payment service not configured. Please install Stripe and set STRIPE_SECRET_KEY.'
      });
    }

    const user = req.user; // From authMiddleware
    const { id: adId } = req.params;

    // Validate UUID format for ad_id
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(adId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ad ID format'
      });
    }

    // Check if ad exists
    const { data: ad, error: adError } = await supabase
      .from('ads')
      .select('*')
      .eq('id', adId)
      .single();

    if (adError || !ad) {
      return res.status(404).json({
        success: false,
        message: 'Ad not found'
      });
    }

    // Verify user is the owner
    if (ad.advertiser_id !== user.id) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to pay for this ad'
      });
    }

    // Check if ad is already paid/active
    if (ad.status === 'active' || ad.status === 'expired') {
      return res.status(400).json({
        success: false,
        message: `Ad is already ${ad.status}. Payment not required.`
      });
    }

    // Check if ad is in pending status
    if (ad.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Cannot initiate payment for ad with status: ${ad.status}`
      });
    }

    // Validate payment amount
    const paymentAmount = Number(ad.payment_amount);
    if (!paymentAmount || paymentAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment amount'
      });
    }

    // Convert to cents (Stripe uses smallest currency unit)
    const amountInCents = Math.round(paymentAmount * 100);

    // Create Stripe Payment Intent
    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amountInCents,
        currency: 'usd', // TODO: Make currency configurable via env or ad settings
        metadata: {
          ad_id: adId,
          advertiser_id: user.id,
          ad_title: ad.title,
          target_impressions: ad.target_impressions.toString()
        },
        description: `Payment for ad: ${ad.title}`,
        // Optional: Set up automatic payment methods
        automatic_payment_methods: {
          enabled: true
        }
      });

      // Return client secret for frontend to complete payment
      return res.status(200).json({
        success: true,
        paymentIntent: {
          id: paymentIntent.id,
          clientSecret: paymentIntent.client_secret,
          amount: paymentAmount,
          currency: paymentIntent.currency,
          status: paymentIntent.status
        },
        ad: {
          id: ad.id,
          title: ad.title,
          payment_amount: ad.payment_amount,
          target_impressions: ad.target_impressions
        },
        message: 'Payment intent created. Use clientSecret to complete payment on frontend.'
      });
    } catch (stripeError) {
      console.error('Stripe payment intent creation error:', stripeError);
      return res.status(500).json({
        success: false,
        message: 'Failed to create payment intent',
        error: stripeError.message
      });
    }
  } catch (error) {
    console.error('initiatePayment error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

module.exports = {
  createAd,
  getActiveAds,
  getMyAds,
  getAdById,
  recordImpression,
  recordClick,
  updateAd,
  deleteAd,
  initiatePayment
};

