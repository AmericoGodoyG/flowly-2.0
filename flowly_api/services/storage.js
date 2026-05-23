const { Storage } = require('@google-cloud/storage');

// Configuração do Google Cloud Storage
const storage = new Storage();

const bucket = storage.bucket(process.env.GCP_BUCKET_NAME);

module.exports = bucket;