const express = require('express');
const { Kafka } = require('kafkajs');
const app = express();

// Middleware
app.use(express.json());

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        status: 'ok',
        message: 'API is running',
        endpoints: {
            root: 'GET /',
            health: 'GET /health',
            sendEvent: 'POST /api/event'
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Kafka producer setup
const kafka = new Kafka({
    clientId: 'test-api',
    brokers: [process.env.KAFKA_BROKERS || 'kafka:29092']
});

const producer = kafka.producer();

// Event endpoint
app.post('/api/event', async (req, res) => {
    try {
        await producer.connect();
        await producer.send({
            topic: 'test-events',
            messages: [{ value: JSON.stringify(req.body) }]
        });
        res.status(200).json({
            status: 'success',
            message: 'Event sent to Kafka',
            data: req.body
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log('Available endpoints:');
    console.log('GET  /         - Root endpoint');
    console.log('GET  /health   - Health check');
    console.log('POST /api/event - Send event to Kafka');
}); 