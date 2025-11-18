const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/authMiddleware');
const walletController = require('../controllers/wallet');

router.get('/', authMiddleware, walletController.getWallet);
router.get('/transactions', authMiddleware, walletController.getTransactions);
router.post('/add-money', authMiddleware, walletController.addMoney);

module.exports = router;