const {supabase} = require('../config/database');
const {
    createPresignedPutUrl,
    s3Bucket,
    s3ProcessedBucket,
    headObject,
    awsRegion,
    createPresignedGetUrl,
    deleteObject
} = require('../config/aws');
const {v4: uuidv4} = require('uuid');

// POST /api/reels/presign
// body: { contentType: string, sizeBytes?: number }
// auth: required
const presignUpload = async (req, res) => {
  try {
    const user = req.user;
        const {contentType, sizeBytes} = req.body || {};

    if (!contentType || !contentType.startsWith('video/')) {
            return res.status(400).json({success: false, message: 'Invalid or missing contentType'});
    }

    // optional simple size guard (frontend should compress/limit too)
    const maxBytes = 200 * 1024 * 1024; // 200MB
    if (sizeBytes && Number(sizeBytes) > maxBytes) {
            return res.status(400).json({success: false, message: 'File too large'});
    }
    
    const reelId = uuidv4();
    const ext = (() => {
      if (contentType === 'video/quicktime') return 'mov';
      const part = contentType.split('/')[1];
      return part || 'mp4';
    })();
    const key = `reels/${user.id}/${reelId}.${ext}`;

        const url = await createPresignedPutUrl({key, contentType, expiresInSeconds: 900});

    console.log(' Presigned URL created:', {
      reelId,
      key,
      bucket: s3Bucket,
      contentType,
      sizeBytes
    });

    res.status(200).json({
      success: true,
      uploadUrl: url,
      bucket: s3Bucket,
      key,
      reelId,
    });
  } catch (error) {
    console.error('presignUpload error', error);
        res.status(500).json({success: false, message: 'Internal server error', error: error.message});
  }
};

// POST /api/reels/finalize
// body: { reelId: string, key: string, s3Url?: string, durationSec?: number, sizeBytes?: number }
// auth: required
const finalizeUpload = async (req, res) => {
  try {
    const user = req.user;
        const {reelId, key, s3Url, durationSec, sizeBytes} = req.body || {};
    if (!reelId || !key) {
            return res.status(400).json({success: false, message: 'reelId and key are required'});
    }

    // Best-effort head to verify object exists
    try {
            const headResult = await headObject({key});
      console.log('S3 object verified:', {
        key,
        size: headResult.ContentLength,
        lastModified: headResult.LastModified
      });
    } catch (e) {
            console.log(' S3 object not found:', {key, error: e.message});
            return res.status(400).json({success: false, message: 'S3 object not found for provided key'});
    }

    // Build playback URL. If bucket has dots, use path-style to avoid TLS mismatch.
    // For now, use presigned URLs for playback to avoid permission issues
    const publicUrl = s3Url || (
      s3Bucket.includes('.')
        ? `https://s3.${awsRegion}.amazonaws.com/${encodeURIComponent(s3Bucket)}/${key}`
        : `https://${s3Bucket}.s3.${awsRegion}.amazonaws.com/${key}`
    );

        const serveUrl = `https://${s3ProcessedBucket}.s3.${awsRegion}.amazonaws.com/${reelId}_720p.m3u8`; // Remove once AWS trigger works
        const thumbnailUrl = `https://${s3ProcessedBucket}.s3.${awsRegion}.amazonaws.com/${reelId}_thumb.0000000_thumb.m3u8`; // Remove once AWS trigger works

        const {data, error} = await supabase
      .from('reels')
      .insert({
        id: reelId,
        user_id: user.id,
        s3_key: key,
        s3_url: publicUrl,
                s3_serve_url: serveUrl, // Remove once AWS trigger works
                thumbnail_url: thumbnailUrl, // Remove once AWS trigger works
        duration_sec: durationSec ?? null,
        size_bytes: sizeBytes ?? null,
                converted: true, // Remove once AWS trigger works
      })
      .select()
      .single();

    if (error) {
      console.error(' Supabase insert error', error);
            return res.status(400).json({success: false, message: 'Failed to save reel'});
    }

    console.log('Reel saved to database:', {
      id: data.id,
      user_id: data.user_id,
      s3_key: data.s3_key,
      s3_url: data.s3_url
    });

        res.status(200).json({success: true, reel: data});
  } catch (error) {
    console.error('finalizeUpload error', error);
        res.status(500).json({success: false, message: 'Internal server error', error: error.message});
  }
};


const listMyReels = async (req, res) => {
  try {
    const user = req.user;
        const oneMinuteAgo = new Date(Date.now() - 20 * 1000).toISOString(); // Remove once AWS trigger works

        const {data, error} = await supabase
      .from('reels')
            .select(`
                id, 
                user_id, 
                s3_key, 
                s3_serve_url, 
                duration_sec, 
                size_bytes, 
                created_at, 
                thumbnail_url,
                likes_count,
                reel_likes!left(user_id)
            `)
      .eq('user_id', user.id)
            .eq('converted', true)
            .lt('created_at', oneMinuteAgo) // Remove once AWS trigger works
            .order('created_at', {ascending: false});

    if (error) {
      console.error('List reels error', error);
            return res.status(400).json({success: false, message: 'Failed to list reels'});
        }

        // Process the data to include isLikedByMe
        const processedReels = (data || []).map(reel => ({
            ...reel,
            isLikedByMe: reel.reel_likes && reel.reel_likes.length > 0 && 
                        reel.reel_likes.some(like => like.user_id === user.id)
        }));

        return res.status(200).json({success: true, reels: processedReels});
  } catch (e) {
    console.error('listMyReels exception', e);
        return res.status(500).json({success: false, message: 'Internal server error', error: e.message});
  }
}

const listAllReels = async (req, res) => {
  try {
        const userId = req.user.id;
        const oneMinuteAgo = new Date(Date.now() - 20 * 1000).toISOString(); // Remove once AWS trigger works

        // Get reels with like status for current user
        const {data, error} = await supabase
      .from('reels')
            .select(`
                id, 
                user_id, 
                s3_key, 
                s3_serve_url, 
                duration_sec, 
                size_bytes, 
                created_at, 
                thumbnail_url,
                likes_count,
                reel_likes!left(user_id)
            `)
            .eq('converted', true)
            .lt('created_at', oneMinuteAgo) // Remove once AWS trigger works
            .order('created_at', {ascending: false});

    if (error) {
      console.error('List all reels error', error);
      return res.status(400).json({ 
        success: false, 
        message: 'Failed to list all reels',
        error: error.message,
        details: error.details,
        hint: error.hint
      });
    }

        // Process the data to include isLikedByMe
        const processedReels = (data || []).map(reel => ({
            ...reel,
            isLikedByMe: reel.reel_likes && reel.reel_likes.length > 0 && 
                        reel.reel_likes.some(like => like.user_id === userId)
        }));


        processedReels.sort(() => Math.random() - 0.5);  // Randomize the reels
        


        console.log(`Found ${processedReels.length} reels from all users`);
        return res.status(200).json({success: true, reels: processedReels});
  } catch (e) {
    console.error('listAllReels exception', e);
        return res.status(500).json({success: false, message: 'Internal server error', error: e.message});
  }
}

// GET /api/reels/:id/playback-url
// auth: required
const getPlaybackUrl = async (req, res) => {
  try {
        const {id} = req.params;
    
    // Get the reel from database
        const {data: reel, error} = await supabase
      .from('reels')
      .select('s3_key')
      .eq('id', id)
      .single();
    
    if (error || !reel) {
            return res.status(404).json({success: false, message: 'Reel not found'});
    }
    
    // Generate presigned URL for playback
    const playbackUrl = await createPresignedGetUrl({ 
      key: reel.s3_key,
      expiresInSeconds: 3600 // 1 hour
    });
    
    res.status(200).json({
      success: true,
      playbackUrl,
      expiresIn: 3600
    });
  } catch (error) {
    console.error('getPlaybackUrl error', error);
        res.status(500).json({success: false, message: 'Internal server error', error: error.message});
    }
};

// DELETE /api/reels/:id
// auth: required
const deleteReel = async (req, res) => {
    try {
        const user = req.user;
        const {id} = req.params;

        // Fetch reel and ensure it belongs to the user
        const {data: reel, error: fetchError} = await supabase
            .from('reels')
            .select('id, user_id, s3_key')
            .eq('id', id)
            .single();

        if (fetchError || !reel) {
            return res.status(404).json({success: false, message: 'Reel not found'});
        }
        if (reel.user_id !== user.id) {
            return res.status(403).json({success: false, message: 'Not allowed to delete this reel'});
        }

        // Best-effort delete object from S3 (ignore if already gone)
        try {
            await deleteObject({key: reel.s3_key});
        } catch (e) {
            console.warn('S3 delete warning:', e.message);
        }

        // Delete from database
        const {error: delError} = await supabase
            .from('reels')
            .delete()
            .eq('id', id);

        if (delError) {
            return res.status(400).json({success: false, message: 'Failed to delete reel'});
        }

        return res.status(200).json({success: true, message: 'Reel deleted'});
    } catch (error) {
        console.error('deleteReel error', error);
        return res.status(500).json({success: false, message: 'Internal server error', error: error.message});
    }
};

// POST /api/reels/aws-update
// body: { reelId: string, m3u8Url: string }
// auth: AWS webhook secret
const updateReelFromAws = async (req, res) => {
    try {
        const {s3_key, newS3Url, sizeBytes} = req.body || {};

        if (!s3_key || !newS3Url) {
            return res.status(400).json({success: false, message: 'reelId and newS3Url are required'});
        }

        // Optional: verify AWS request via secret token
        const secretToken = req.headers['x-aws-secret'];
        if (secretToken !== process.env.AWS_WEBHOOK_SECRET) {
            return res.status(403).json({success: false, message: 'Unauthorized'});
        }


        // Set s3_serve_url in Supabase
        const {data, error} = await supabase
            .from('reels')
            .update({s3_serve_url: newS3Url, converted: true})
            .eq('s3_key', s3_key)
            .select()
            .single();

        if (error || !data) {
            console.error('Failed to update reel from AWS:', error);
            return res.status(400).json({success: false, message: 'Failed to update reel', error: error?.message});
        }

        console.log('Reel updated from AWS:', {reelId, newS3Url});

        return res.status(200).json({success: true, reel: data});
    } catch (error) {
        console.error('updateReelFromAws error', error);
        return res.status(500).json({success: false, message: 'Internal server error', error: error.message});
    }
};

// POST /api/reels/:reelid/like
// auth: required
const updateLikeCount = async (req, res) => {
    try {
        const reelId = req.params.reelid;
        const userId = req.user.id;

        if (!reelId) {
            return res.status(400).json({success: false, message: 'Reel ID is required'});
        }

        // First, check if the reel exists
        const {data: existingReel, error: fetchError} = await supabase
            .from('reels')
            .select('id, likes_count')
            .eq('id', reelId)
            .single();

        if (fetchError || !existingReel) {
            return res.status(404).json({success: false, message: 'Reel not found'});
        }

        // Check if user has already liked this reel
        const {data: existingLike, error: likeCheckError} = await supabase
            .from('reel_likes')
            .select('id')
            .eq('reel_id', reelId)
            .eq('user_id', userId)
            .single();

        let isLiked = false;
        let newLikeCount = existingReel.likes_count || 0;

        if (existingLike) {
            // USER IS UNLIKING: Delete the like record
            const {error: deleteError} = await supabase
                .from('reel_likes')
                .delete()
                .eq('reel_id', reelId)
                .eq('user_id', userId);

            if (deleteError) {
                console.error('Delete like record error:', deleteError);
                return res.status(400).json({
                    success: false, 
                    message: 'Failed to remove like'
                });
            }

            // Decrement likes count
            newLikeCount = Math.max(0, newLikeCount - 1);
            isLiked = false;

            console.log('Like removed successfully:', {
                reelId,
                userId,
                newLikeCount
            });

        } else {
            // USER IS LIKING: Create new like record
            const {data: likeRecord, error: likeError} = await supabase
                .from('reel_likes')
                .insert({
                    reel_id: reelId,
                    user_id: userId,
                    created_at: new Date().toISOString()
                })
                .select()
                .single();

            if (likeError) {
                console.error('Insert like record error:', likeError);
                return res.status(400).json({
                    success: false, 
                    message: 'Failed to create like record'
                });
            }

            // Increment likes count
            newLikeCount = newLikeCount + 1;
            isLiked = true;

            // console.log('Like added successfully:', {
            //     reelId,
            //     userId,
            //     newLikeCount,
            //     likeRecordId: likeRecord.id
            // });
        }

        // Update the likes count in reels table
        const {data: updatedReel, error: updateError} = await supabase
            .from('reels')
            .update({likes_count: newLikeCount})
            .eq('id', reelId)
            .select('id, likes_count, user_id, s3_serve_url, thumbnail_url, created_at')
            .single();

        if (updateError) {
            console.error('Update like count error:', updateError);
            return res.status(400).json({
                success: false, 
                message: 'Failed to update like count'
            });
        }

        return res.status(200).json({
            success: true, 
            reel: updatedReel,
            isLiked: isLiked,
            message: isLiked ? 'Reel liked successfully' : 'Reel unliked successfully'
        });
    } catch (error) {
        console.error('updateLikeCount error:', error);
        return res.status(500).json({
            success: false, 
            message: 'Internal server error', 
            error: error.message
        });
    }
};



module.exports = {
  presignUpload,
  finalizeUpload,
  listMyReels,
  listAllReels,
  getPlaybackUrl,
    deleteReel,
    updateReelFromAws,
    updateLikeCount
};
