# Frontend Developer Guide

This guide helps frontend developers discover, subscribe to, and use APIs through the WSO2 API Gateway.

## Getting Started

### 1. Access Developer Portal

Go to: **https://apim.ayinza.dev/devportal**

### 2. Create Account / Sign In

1. Click **Sign Up** or **Sign In**
2. Create account with your email
3. Verify email if required

### 3. Browse Available APIs

1. Navigate to **APIs** section
2. Browse by category or search
3. Click an API to see documentation

## Subscribing to APIs

### Step 1: Create an Application

1. Go to **Applications** → **Add New Application**
2. Enter application name (e.g., "My Frontend App")
3. Select throttling tier
4. Click **Save**

### Step 2: Subscribe to APIs

1. Go to the API you want to use
2. Click **Subscribe**
3. Select your application
4. Choose subscription tier
5. Click **Subscribe**

### Step 3: Generate API Key

1. Go to **Applications** → Your Application
2. Click **Production Keys** or **Sandbox Keys**
3. Click **Generate Keys**
4. Copy the **Access Token** or **API Key**

## Using the APIs

### Authentication Methods

#### OAuth2 Bearer Token
```javascript
fetch('https://apim.ayinza.dev/retail/v1/products', {
  headers: {
    'Authorization': 'Bearer YOUR_ACCESS_TOKEN'
  }
})
```

#### API Key
```javascript
fetch('https://apim.ayinza.dev/retail/v1/products', {
  headers: {
    'apikey': 'YOUR_API_KEY'
  }
})
```

### Example: Fetch Products

```javascript
// Using fetch
const response = await fetch('https://apim.ayinza.dev/retail/v1/products', {
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  }
});
const products = await response.json();
```

```javascript
// Using axios
import axios from 'axios';

const api = axios.create({
  baseURL: 'https://apim.ayinza.dev',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN'
  }
});

const { data } = await api.get('/retail/v1/products');
```

### Example: Create Order

```javascript
const order = {
  productId: '123',
  quantity: 2,
  customerId: '456'
};

const response = await fetch('https://apim.ayinza.dev/orders/v1/orders', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(order)
});
```

## API Documentation

### Try It Out

Each API in DevPortal has a **Try It Out** feature:

1. Go to API details page
2. Click on an endpoint
3. Fill in parameters
4. Click **Execute**
5. See response

### View OpenAPI Spec

1. Go to API details
2. Click **Definition**
3. Download OpenAPI/Swagger spec

## Environment Configuration

### Development
```javascript
const API_BASE = 'https://apim.ayinza.dev';
```

### Environment Variables
```env
# .env.local
NEXT_PUBLIC_API_URL=https://apim.ayinza.dev
NEXT_PUBLIC_API_KEY=your-api-key
```

```javascript
// Use in code
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

## Error Handling

### Common HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Check request body/params |
| 401 | Unauthorized | Check API key/token |
| 403 | Forbidden | Check subscription/permissions |
| 404 | Not Found | Check endpoint URL |
| 429 | Too Many Requests | Rate limited, retry later |
| 500 | Server Error | Contact backend team |

### Example Error Handling

```javascript
try {
  const response = await fetch('https://apim.ayinza.dev/retail/v1/products');

  if (!response.ok) {
    if (response.status === 401) {
      // Refresh token or redirect to login
    } else if (response.status === 429) {
      // Rate limited, implement backoff
    }
    throw new Error(`HTTP ${response.status}`);
  }

  const data = await response.json();
  return data;
} catch (error) {
  console.error('API Error:', error);
  throw error;
}
```

## Rate Limiting

APIs have rate limits based on subscription tier:

| Tier | Requests | Period |
|------|----------|--------|
| Bronze | 1000 | Per minute |
| Silver | 5000 | Per minute |
| Gold | 10000 | Per minute |
| Unlimited | No limit | - |

### Handling Rate Limits

```javascript
const fetchWithRetry = async (url, options, retries = 3) => {
  for (let i = 0; i < retries; i++) {
    const response = await fetch(url, options);

    if (response.status === 429) {
      // Rate limited, wait and retry
      const retryAfter = response.headers.get('Retry-After') || 60;
      await new Promise(r => setTimeout(r, retryAfter * 1000));
      continue;
    }

    return response;
  }
  throw new Error('Max retries exceeded');
};
```

## Available APIs

| API | Context | Description |
|-----|---------|-------------|
| Retail Operations | `/retail/v1` | Stores, products, inventory |
| Inventory | `/inventory/v1` | Stock management |
| Orders | `/orders/v1` | Order processing |
| Customers | `/customers/v1` | Customer management |
| Notifications | `/notifications/v1` | Notification service |

*Check DevPortal for complete, up-to-date API list*

## Support

- **DevPortal**: https://apim.ayinza.dev/devportal
- **API Status**: Check individual API pages for status
- **Issues**: Contact backend team for specific API issues
