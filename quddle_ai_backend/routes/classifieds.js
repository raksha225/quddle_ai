const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/authMiddleware');
const classifiedsController = require('../controllers/classifieds');

router.post('/', authMiddleware, classifiedsController.postClassified);
router.get('/', classifiedsController.getClassifieds);
router.get('/my', authMiddleware, classifiedsController.getMyClassifieds);
router.put('/:id/images', authMiddleware, classifiedsController.updateClassifiedImages);

module.exports = router;