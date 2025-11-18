const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/authMiddleware');
const reelsController = require('../controllers/reels');

router.post('/presign', authMiddleware, reelsController.presignUpload);
router.post('/finalize', authMiddleware, reelsController.finalizeUpload);
router.get('/', authMiddleware, reelsController.listMyReels);
router.get('/all', authMiddleware, reelsController.listAllReels);
router.get('/:id/playback-url', authMiddleware, reelsController.getPlaybackUrl);
router.delete('/:id', authMiddleware, reelsController.deleteReel);
router.post('/:reelid/like', authMiddleware, reelsController.updateLikeCount);

module.exports = router;


