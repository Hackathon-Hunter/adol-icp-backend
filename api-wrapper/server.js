const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Helper function to execute dfx commands and return raw output
function executeDfxCommand(method, args = '') {
    return new Promise((resolve, reject) => {
        const command = `cd ${path.dirname(__dirname)} && dfx canister call adol-backend ${method} ${args} --network ic`;
        
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject({ error: error.message, stderr });
                return;
            }
            
            // Return raw stdout - let the endpoint handle parsing
            resolve(stdout.trim());
        });
    });
}

// API Routes

// Health check
app.get('/health', async (req, res) => {
    try {
        res.json({ success: true, status: 'API wrapper is running', canisterId: 'ujk5g-liaaa-aaaam-aeocq-cai' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get health status', details: error.message });
    }
});

// Get all products - Use HTTP interface directly
app.get('/products', async (req, res) => {
    try {
        // Use fetch to call the canister's HTTP interface directly
        const response = await fetch('https://ujk5g-liaaa-aaaam-aeocq-cai.icp0.io/?canisterId=ujk5g-liaaa-aaaam-aeocq-cai&method=getProducts');
        const data = await response.text();
        
        // Try to parse as JSON first, if it fails return raw data
        try {
            const jsonData = JSON.parse(data);
            res.json(jsonData);
        } catch {
            // If direct JSON parsing fails, use dfx command as fallback
            const result = await executeDfxCommand('getProducts');
            res.json({ success: true, data: result });
        }
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({ error: 'Failed to get products', details: error.message });
    }
});

// Get specific product
app.get('/products/:id', async (req, res) => {
    try {
        const productId = req.params.id;
        const result = await executeDfxCommand('getProduct', `("${productId}")`);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get product', details: error.message });
    }
});

// Get categories
app.get('/categories', async (req, res) => {
    try {
        const result = await executeDfxCommand('getCategories');
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get categories', details: error.message });
    }
});

// Get products by category
app.get('/categories/:id/products', async (req, res) => {
    try {
        const categoryId = req.params.id;
        const result = await executeDfxCommand('getProductsByCategory', `(${categoryId})`);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get products by category', details: error.message });
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
    console.log(`  GET /health - Check API health`);
    console.log(`  GET /products - Get all products`);
    console.log(`  GET /products/:id - Get specific product`);
    console.log(`  GET /categories - Get all categories`);
    console.log(`  GET /categories/:id/products - Get products by category`);
});

module.exports = app;
