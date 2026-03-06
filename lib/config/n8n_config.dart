// Configuration for the local PDF extraction service.
// The service runs locally at http://localhost:8000 and exposes a
// POST /extract-json endpoint that accepts a multipart PDF upload
// and returns a JSON object with meal_options.

const String kLocalExtractBaseUrl = 'http://192.168.1.10:8000';
const String kLocalExtractEndpoint = '$kLocalExtractBaseUrl/extract-json';
const String kN8nFileFieldName = 'file';

// Legacy n8n webhook URLs (kept for reference, no longer used)
// const String kN8nWebhookUrl =
//     'http://192.168.1.9:5678/webhook-test/c571e2f1-bdfc-465c-8cd8-17cc064db6ae';
