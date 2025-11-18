const { S3Client, PutObjectCommand, HeadObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
// const { S3Client, PutObjectCommand, HeadObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const dotenv = require('dotenv');
dotenv.config();

const awsRegion = process.env.AWS_REGION3 ;  // Remove this
const s3Bucket = process.env.S3_BUCKET_NAME3 ; // Remove this
const s3AdsBucket = process.env.S3_ADS_BUCKET_NAME ; // Ads bucket (defaults to main bucket if not set)
const s3ProcessedBucket = process.env.S3_PROCESSED_BUCKET_NAME || 'quddle-ai-reel-upload-process-videos'


const s3Client = new S3Client({
  region: awsRegion,
  credentials: (process.env.AWS_ACCESS_KEY_ID3 && process.env.AWS_SECRET_ACCESS_KEY3) ? {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID3,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY3,
  } : undefined,
});

async function createPresignedPutUrl({ key, contentType, expiresInSeconds = 900, acl }) {
  const command = new PutObjectCommand({
    Bucket: s3Bucket,
    Key: key,
    ContentType: contentType,
    ACL: acl, // optional; prefer bucket policy if possible
  });
  const url = await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
  return url;
}

async function headObject({ key }) {
  const command = new HeadObjectCommand({ Bucket: s3Bucket, Key: key });
  return await s3Client.send(command);
}

async function createPresignedGetUrl({ key, expiresInSeconds = 3600 }) {
  const command = new GetObjectCommand({
    Bucket: s3Bucket,
    Key: key,
  });
  const url = await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
  return url;
}

async function deleteObject({ key }) {
  const command = new DeleteObjectCommand({ Bucket: s3Bucket, Key: key });
  return await s3Client.send(command);
}

// Helper function to create presigned URL for ads bucket
async function createPresignedPutUrlForAds({ key, contentType, expiresInSeconds = 900, acl }) {
  const command = new PutObjectCommand({
    Bucket: s3AdsBucket,
    Key: key,
    ContentType: contentType,
    ACL: acl,
  });
  const url = await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
  return url;
}

module.exports = {
  s3Client,
  s3Bucket,
  s3AdsBucket,
  s3ProcessedBucket,
  awsRegion,
  createPresignedPutUrl,
  createPresignedPutUrlForAds,
  createPresignedGetUrl,
  headObject,
  deleteObject,
};


