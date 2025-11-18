// Authentication Controller with Supabase Auth
const { supabase } = require('../config/database');

// Register a new user using Supabase Auth (Email-based authentication)
const register = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;
    console.log('Register request:', { name, email, phone });
    
    // Validate required fields
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required'
      });
    }

    // Register user with Supabase Auth using email
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: email,
      password: password,
      options: {
        data: {
          name: name,
          email: email
        }
      }
    });

    if (authError) {
      return res.status(400).json({
        success: false,
        message: authError.message
      });
    }

    // Check for duplicate phone if phone is provided
    if (phone) {
      const { data: existingUser, error: checkError } = await supabase
        .from('users')
        .select('id')
        .eq('phone', phone)
        .single();

      if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows found
        console.error('Error checking duplicate phone:', checkError);
        return res.status(400).json({
          success: false,
          message: 'Error checking phone number'
        });
      }

      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already exists'
        });
      }
    }

    // Insert user into custom users table
    const { error: insertError } = await supabase
      .from('users')
      .insert({
        id: authData.user.id,
        name: name,
        phone: phone || null
      });

    if (insertError) {
      console.error('Error inserting user into custom table:', insertError);
      // TODO: Transaction Safety - Consider implementing one of these solutions:
      // 1. Use Supabase trigger to auto-create user record on auth.users insert
      // 2. Wrap both operations in a single Postgres function with transaction
      // 3. Implement cleanup job to remove orphaned auth users
      console.warn('User created in auth but failed to insert in custom table');
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: {
        id: authData.user.id,
        email: email,
        name: name,
        phone: phone || null
      },
      session: authData.session
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Login user using Supabase Auth (Email-based authentication)
const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Login request:', { email });
    console.log('>>>>>>');
    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Sign in with Supabase Auth using email
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (authError) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Fetch user data from custom users table
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('name, phone')
      .eq('id', authData.user.id)
      .single();

    if (userError) {
      console.error('Error fetching user from custom table:', userError);
      // Fallback to auth metadata if custom table fails
      res.status(200).json({
        success: true,
        message: 'Login successful',
        user: {
          id: authData.user.id,
          email: email,
          name: authData.user.user_metadata?.name || 'User',
          phone: authData.user.phone || null
        },
        session: authData.session
      });
      return;
    }

    console.log('User data from custom table:', userData);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: {
        id: authData.user.id,
        email: email,
        name: userData.name,
        phone: userData.phone
      },
      session: authData.session
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user profile using Supabase Auth (MVP)
const getProfile = async (req, res) => {
  try {
    // User info is already available from authMiddleware
    const user = req.user;

    // Fetch user data from custom users table
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('name, phone')
      .eq('id', user.id)
      .single();

    if (userError) {
      console.error('Error fetching user from custom table:', userError);
      // Fallback to auth middleware data
      res.status(200).json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name || 'User',
          phone: null
        }
      });
      return;
    }

    res.status(200).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: userData.name,
        phone: userData.phone
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Logout user using Supabase Auth
const logout = async (req, res) => {
  try {
    // Sign out from Supabase Auth
    const { error } = await supabase.auth.signOut();

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Logout failed',
        error: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Refresh access token using Supabase refresh token
const refreshSession = async (req, res) => {
  try {
    const { refreshToken } = req.body || {};
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'refreshToken is required' });
    }

    const { data, error } = await supabase.auth.refreshSession({
      refresh_token: refreshToken
    });

    if (error || !data?.session || !data?.user) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    res.status(200).json({
      success: true,
      message: 'Token refreshed',
      user: {
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata?.name || 'User'
      },
      session: data.session
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  logout,
  refreshSession
};


