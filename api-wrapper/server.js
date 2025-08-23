const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Helper function to execute dfx commands
function executeDfxCommand(method, args = '') {
    return new Promise((resolve, reject) => {
        const command = `cd ${path.dirname(__dirname)} && dfx canister call adol-backend ${method} ${args} --network ic`;
        
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject({ error: error.message, stderr });
                return;
            }
            
            try {
                // Parse the Candid output
                let result = stdout.trim();
                
                // Remove Candid syntax and convert to JSON-like format
                result = result.replace(/\brecord\s*{/g, '{');
                result = result.replace(/\bvec\s*{/g, '[');
                result = result.replace(/=/g, ':');
                result = result.replace(/;/g, ',');
                result = result.replace(/,(\s*[}\]])/g, '$1');
                
                resolve({ success: true, data: result });
            } catch (parseError) {
                resolve({ success: true, data: stdout.trim() });
            }
        });
    });
}

// API Routes

// Health check
app.get('/health', async (req, res) => {
    try {
        const result = await executeDfxCommand('health');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get health status', details: error });
    }
});

// Get system info
app.get('/info', async (req, res) => {
    try {
        const result = await executeDfxCommand('getInfo');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get system info', details: error });
    }
});

// Get all products
app.get('/products', async (req, res) => {
    try {
        const result = await executeDfxCommand('getProducts');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get products', details: error });
    }
});

// Get specific product
app.get('/products/:id', async (req, res) => {
    try {
        const productId = req.params.id;
        const result = await executeDfxCommand('getProduct', `(${productId})`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get product', details: error });
    }
});

// Get categories
app.get('/categories', async (req, res) => {
    try {
        const result = await executeDfxCommand('getCategories');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get categories', details: error });
    }
});

// Get products by category
app.get('/categories/:id/products', async (req, res) => {
    try {
        const categoryId = req.params.id;
        const result = await executeDfxCommand('getProductsByCategory', `(${categoryId})`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get products by category', details: error });
    }
});

// Get payment config
app.get('/payment/config', async (req, res) => {
    try {
        const result = await executeDfxCommand('getPaymentConfig');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get payment config', details: error });
    }
});

// Get owner ICP account info
app.get('/payment/owner-account', async (req, res) => {
    try {
        const result = await executeDfxCommand('getOwnerICPAccount');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get owner account info', details: error });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Adol E-commerce API wrapper running on port ${PORT}`);
    console.log(`📡 Canister ID: ujk5g-liaaa-aaaam-aeocq-cai`);
    console.log(`🌐 Available endpoints:`);
    console.log(`  GET /health - Check canister health`);
    console.log(`  GET /info - Get system information`);
    console.log(`  GET /products - Get all products`);
    console.log(`  GET /products/:id - Get specific product`);
    console.log(`  GET /categories - Get all categories`);
    console.log(`  GET /categories/:id/products - Get products by category`);
    console.log(`  GET /payment/config - Get payment configuration`);
    console.log(`  GET /payment/owner-account - Get owner ICP account info`);
});

module.exports = app;
