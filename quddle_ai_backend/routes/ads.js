const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/authMiddleware');
const adsController = require('../controllers/ads');

// GET /api/ads - List all active ads (for display, public)
router.get('/', adsController.getActiveAds);

// GET /api/ads/my - List advertiser's own ads (requires auth)
router.get('/my', authMiddleware, adsController.getMyAds);

// GET /api/ads/:id - Get specific ad details (public)
router.get('/:id', adsController.getAdById);

// POST /api/ads/:id/impression - Record ad impression (public, rate-limited)
router.post('/:id/impression', adsController.recordImpression);

// POST /api/ads/:id/click - Record ad click (public, rate-limited)
router.post('/:id/click', adsController.recordClick);

// PUT /api/ads/:id - Update ad (requires auth, owner only)
router.put('/:id', authMiddleware, adsController.updateAd);

// DELETE /api/ads/:id - Delete ad (requires auth, owner only)
router.delete('/:id', authMiddleware, adsController.deleteAd);

// POST /api/ads/:id/payment - Initiate Stripe payment (requires auth, owner only)
router.post('/:id/payment', authMiddleware, adsController.initiatePayment);

// POST /api/ads - Create new ad (requires auth, image upload)
router.post('/', authMiddleware, adsController.createAd);

module.exports = router;

