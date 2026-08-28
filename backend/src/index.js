import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { createClient } from '@supabase/supabase-js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true
}))
app.use(express.json({ limit: '50mb' }))
app.use(express.urlencoded({ limit: '50mb', extended: true }))

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

// Reports routes
app.get('/api/reports', async (req, res) => {
  try {
    const { status } = req.query
    let query = supabase.from('reports').select('*')
    
    if (status) {
      query = query.eq('status', status)
    }
    
    const { data, error } = await query.order('created_at', { ascending: false })
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.get('/api/reports/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('id', req.params.id)
      .single()
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.post('/api/reports', async (req, res) => {
  try {
    const { reporter_id, comment, lat, lng } = req.body
    
    if (!reporter_id || lat === undefined || lng === undefined) {
      return res.status(400).json({ error: 'Missing required fields' })
    }
    
    const { data, error } = await supabase
      .from('reports')
      .insert([{
        reporter_id,
        comment: comment || '',
        lat,
        lng,
        status: 'new',
        created_at: new Date().toISOString()
      }])
      .select()
      .single()
    
    if (error) throw error
    res.status(201).json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.patch('/api/reports/:id', async (req, res) => {
  try {
    const { status, executor_id, completion_lat, completion_lng } = req.body
    
    const { data, error } = await supabase
      .from('reports')
      .update({
        status,
        executor_id,
        completion_lat,
        completion_lng,
        completed_at: status === 'completed' ? new Date().toISOString() : null,
        updated_at: new Date().toISOString()
      })
      .eq('id', req.params.id)
      .select()
      .single()
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Messages routes
app.get('/api/reports/:reportId/messages', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('report_id', req.params.reportId)
      .order('created_at', { ascending: true })
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.post('/api/reports/:reportId/messages', async (req, res) => {
  try {
    const { sender_id, text } = req.body
    const { reportId } = req.params
    
    if (!sender_id || !text) {
      return res.status(400).json({ error: 'Missing required fields' })
    }
    
    const { data, error } = await supabase
      .from('messages')
      .insert([{
        report_id: reportId,
        sender_id,
        text,
        created_at: new Date().toISOString()
      }])
      .select()
      .single()
    
    if (error) throw error
    res.status(201).json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Photo upload endpoint
app.post('/api/upload/photo', async (req, res) => {
  try {
    const { reportId, photoBase64, photoType } = req.body
    
    if (!reportId || !photoBase64) {
      return res.status(400).json({ error: 'Missing required fields' })
    }
    
    // Convert base64 to buffer
    const buffer = Buffer.from(photoBase64.split(',')[1], 'base64')
    const fileName = `${reportId}/${photoType}-${Date.now()}.jpg`
    
    const { data, error } = await supabase.storage
      .from('photos')
      .upload(fileName, buffer, {
        contentType: 'image/jpeg',
        upsert: false
      })
    
    if (error) throw error
    
    const { data: { publicUrl } } = supabase.storage
      .from('photos')
      .getPublicUrl(fileName)
    
    // Save photo reference to database
    await supabase
      .from('photos')
      .insert([{
        report_id: reportId,
        type: photoType,
        url: publicUrl,
        upload_date: new Date().toISOString()
      }])
    
    res.status(201).json({ url: publicUrl })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Transactions routes
app.get('/api/users/:userId/transactions', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', req.params.userId)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.post('/api/transactions/withdraw', async (req, res) => {
  try {
    const { user_id, amount_cents, payment_method } = req.body
    
    if (!user_id || !amount_cents || amount_cents <= 0) {
      return res.status(400).json({ error: 'Invalid amount' })
    }
    
    // Create transaction
    const { data: transaction, error: txError } = await supabase
      .from('transactions')
      .insert([{
        user_id,
        type: 'withdraw',
        amount_cents,
        status: 'pending',
        created_at: new Date().toISOString()
      }])
      .select()
      .single()
    
    if (txError) throw txError
    
    // TODO: Process payment based on payment_method
    // This would integrate with payment providers like Stripe, PayPal, etc.
    
    res.status(201).json(transaction)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// User routes
app.get('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', req.params.id)
      .single()
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.patch('/api/users/:id', async (req, res) => {
  try {
    const { full_name, phone, vehicle } = req.body
    
    const { data, error } = await supabase
      .from('users')
      .update({
        full_name,
        phone,
        vehicle,
        updated_at: new Date().toISOString()
      })
      .eq('id', req.params.id)
      .select()
      .single()
    
    if (error) throw error
    res.json(data)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({
    error: process.env.NODE_ENV === 'development' 
      ? err.message 
      : 'Internal server error'
  })
})

app.listen(PORT, () => {
  console.log(`🚀 Backend server running at http://localhost:${PORT}`)
  console.log(`📝 API docs available at http://localhost:${PORT}/api/health`)
})
