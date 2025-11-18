const express = require('express');
require('dotenv').config();
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Import controllers and middleware
const authController = require('./controllers/auth');
const { authMiddleware } = require('./middleware/authMiddleware');
const reelsRoutes = require('./routes/reels');
const adsRoutes = require('./routes/ads');
const walletRoutes = require('./routes/wallet');
const classifiedsRoutes = require('./routes/classifieds');

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Quddle AI Backend API',
    status: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Server is healthy',
    uptime: process.uptime()
  });
});

// Authentication routes (MVP)
app.post('/api/auth/register', authController.register);
app.post('/api/auth/login', authController.login);
app.post('/api/auth/logout', authController.logout);
app.post('/api/auth/refresh', authController.refreshSession);

// Protected routes (require authentication)
app.get('/api/auth/profile/:userId', authMiddleware, authController.getProfile);

// Test protected route
app.get('/api/protected', authMiddleware, (req, res) => {
  res.json({
    success: true,
    message: 'This is a protected route',
    user: req.user
  });
});
// Reels routes
app.use('/api/reels', reelsRoutes);

// Ads routes
app.use('/api/ads', adsRoutes);

// Wallet routes
app.use('/api/wallet', walletRoutes);

// Classifieds routes
app.use('/api/classifieds', classifiedsRoutes);


// Start server
app.listen(3000, '0.0.0.0', () => console.log("Server running on port 3000"));


module.exports = app;
