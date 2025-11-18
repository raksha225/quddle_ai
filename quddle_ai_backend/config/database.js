const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');
dotenv.config();    


// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL || 'your_supabase_project_url';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your_supabase_anon_key';

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

module.exports = {
  supabase
};
