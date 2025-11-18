const { supabase } = require('../config/database');

const POSTING_FEE = 50; // AED
const ADMIN_USER_ID = '00000000-0000-0000-0000-000000000000';

// Get user wallet
const getWallet = async (req, res) => {
  try {
    const user = req.user;

    let { data: wallet, error } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (error && error.code === 'PGRST116') {
      // Create wallet if doesn't exist
      const { data: newWallet, error: createError } = await supabase
        .from('wallets')
        .insert({ user_id: user.id, balance: 1000.00 })
        .select()
        .single();

      if (createError) {
        return res.status(400).json({ success: false, message: createError.message });
      }
      wallet = newWallet;
    } else if (error) {
      return res.status(400).json({ success: false, message: error.message });
    }

    return res.status(200).json({ success: true, wallet });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Get wallet transactions
const getTransactions = async (req, res) => {
  try {
    const user = req.user;

    const { data: wallet } = await supabase
      .from('wallets')
      .select('id')
      .eq('user_id', user.id)
      .single();

    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }

    const { data: transactions, error } = await supabase
      .from('wallet_transactions')
      .select('*')
      .eq('wallet_id', wallet.id)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(400).json({ success: false, message: error.message });
    }

    return res.status(200).json({ success: true, transactions });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getWallet,
  getTransactions,
  POSTING_FEE,
  ADMIN_USER_ID
};