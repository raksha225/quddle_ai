const { supabase } = require('../config/database');
const { createPresignedPutUrl, s3Bucket, awsRegion } = require('../config/aws');
const { v4: uuidv4 } = require('uuid');
const { POSTING_FEE, ADMIN_USER_ID } = require('./wallet');

// Post a classified ad
const postClassified = async (req, res) => {
  try {
    const user = req.user;
    const { title, description, price, category, location, imageCount } = req.body;

    if (!title || !description) {
      return res.status(400).json({ 
        success: false, 
        message: 'Title and description are required' 
      });
    }

    // Get user wallet
    const { data: userWallet, error: walletError } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (walletError || !userWallet) {
      return res.status(400).json({ 
        success: false, 
        message: 'Wallet not found. Please contact support.' 
      });
    }

    // Check balance
    if (userWallet.balance < POSTING_FEE) {
      return res.status(400).json({ 
        success: false, 
        message: `Insufficient balance. You need AED ${POSTING_FEE} to post an ad. Current balance: AED ${userWallet.balance}` 
      });
    }

    // Get admin wallet
    const { data: adminWallet } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', ADMIN_USER_ID)
      .single();

    if (!adminWallet) {
      return res.status(500).json({ 
        success: false, 
        message: 'Admin wallet not found' 
      });
    }

    // Deduct from user
    const { error: deductError } = await supabase
      .from('wallets')
      .update({ 
        balance: userWallet.balance - POSTING_FEE,
        updated_at: new Date().toISOString()
      })
      .eq('id', userWallet.id);

    if (deductError) {
      return res.status(400).json({ success: false, message: deductError.message });
    }

    // Credit to admin
    const { error: creditError } = await supabase
      .from('wallets')
      .update({ 
        balance: adminWallet.balance + POSTING_FEE,
        updated_at: new Date().toISOString()
      })
      .eq('id', adminWallet.id);

    if (creditError) {
      // Rollback user deduction
      await supabase
        .from('wallets')
        .update({ balance: userWallet.balance })
        .eq('id', userWallet.id);
      return res.status(400).json({ success: false, message: creditError.message });
    }

    // Create classified ad
    const classifiedId = uuidv4();
    const { data: classified, error: classifiedError } = await supabase
      .from('classifieds')
      .insert({
        id: classifiedId,
        user_id: user.id,
        title,
        description,
        price: price || null,
        category: category || null,
        location: location || null,
        posting_fee: POSTING_FEE,
        images: []
      })
      .select()
      .single();

    if (classifiedError) {
      return res.status(400).json({ success: false, message: classifiedError.message });
    }

    // Record transactions
    await supabase.from('wallet_transactions').insert([
      {
        wallet_id: userWallet.id,
        amount: POSTING_FEE,
        type: 'debit',
        description: `Posted classified: ${title}`,
        reference_type: 'classified',
        reference_id: classifiedId
      },
      {
        wallet_id: adminWallet.id,
        amount: POSTING_FEE,
        type: 'credit',
        description: `Posting fee from user: ${title}`,
        reference_type: 'classified',
        reference_id: classifiedId
      }
    ]);

    // Generate presigned URLs for image uploads if needed
    const uploadUrls = [];
    if (imageCount && imageCount > 0) {
      for (let i = 0; i < Math.min(imageCount, 5); i++) {
        const imageKey = `classifieds/${user.id}/${classifiedId}/image_${i}.jpg`;
        const url = await createPresignedPutUrl({
          key: imageKey,
          contentType: 'image/jpeg',
          expiresInSeconds: 900
        });
        uploadUrls.push({ key: imageKey, uploadUrl: url });
      }
    }

    return res.status(201).json({ 
      success: true, 
      classified,
      uploadUrls,
      message: `Ad posted successfully! AED ${POSTING_FEE} deducted from your wallet.`,
      newBalance: userWallet.balance - POSTING_FEE
    });
  } catch (error) {
    console.error('Post classified error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Get all classifieds (PUBLIC - anyone can see)
const getClassifieds = async (req, res) => {
  try {
    const { category, status = 'active' } = req.query;

    let query = supabase
      .from('classifieds')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (category) {
      query = query.eq('category', category);
    }

    const { data: classifieds, error } = await query;

    if (error) {
      return res.status(400).json({ success: false, message: error.message });
    }

    return res.status(200).json({ success: true, classifieds });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Get user's classifieds
const getMyClassifieds = async (req, res) => {
  try {
    const user = req.user;

    const { data: classifieds, error } = await supabase
      .from('classifieds')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(400).json({ success: false, message: error.message });
    }

    return res.status(200).json({ success: true, classifieds });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Update classified images after upload
const updateClassifiedImages = async (req, res) => {
  try {
    const user = req.user;
    const { id } = req.params;
    const { imageKeys } = req.body;

    const { data: classified, error: fetchError } = await supabase
      .from('classifieds')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();

    if (fetchError || !classified) {
      return res.status(404).json({ success: false, message: 'Classified not found' });
    }

    const imageUrls = imageKeys.map(key => 
      `https://${s3Bucket}.s3.${awsRegion}.amazonaws.com/${key}`
    );

    const { error: updateError } = await supabase
      .from('classifieds')
      .update({ images: imageUrls })
      .eq('id', id);

    if (updateError) {
      return res.status(400).json({ success: false, message: updateError.message });
    }

    return res.status(200).json({ success: true, message: 'Images updated' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  postClassified,
  getClassifieds,
  getMyClassifieds,
  updateClassifiedImages
};