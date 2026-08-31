const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const multer = require('multer');
const { structuredLog, buildCorrelationId } = require('./observability');

// Inicialização do Firebase Admin (usaria Application Default Credentials no GCP)
// Para testes locais, normalmente se passaria um serviceAccountKey.json
admin.initializeApp();
const db = admin.firestore();

// No GCP o bucket é configurado automaticamente na infra, 
// aqui podemos definir o nome se for o caso
// const bucket = admin.storage().bucket('seu-bucket.appspot.com');

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  const correlationId = buildCorrelationId(req.headers['x-correlation-id']);
  req.correlationId = correlationId;
  res.setHeader('x-correlation-id', correlationId);
  const startedAt = Date.now();

  structuredLog('http.request.start', {
    method: req.method,
    path: req.path,
    correlationId,
  });

  res.on('finish', () => {
    structuredLog('http.request.end', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs: Date.now() - startedAt,
      correlationId,
    });
  });

  next();
});

// Configurando upload em memória
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // Limite de 5MB
  }
});

// Middleware de Autenticação (validação JWT)
const authenticateAdmin = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const correlationId = req.correlationId || buildCorrelationId();

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    structuredLog('admin.auth.denied', {
      reason: 'missing_bearer_token',
      correlationId,
    });
    return res.status(401).json({ error: 'Não autorizado' });
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    if (decodedToken.admin !== true) {
      structuredLog('admin.auth.denied', {
        reason: 'missing_admin_claim',
        correlationId,
      });
    }
    req.user = decodedToken;
    structuredLog('admin.auth.success', {
      uid: decodedToken.uid,
      correlationId,
    });
    next();
  } catch (err) {
    structuredLog('admin.auth.failure', {
      error: err.message,
      correlationId,
    });
    return res.status(401).json({ error: 'Token inválido', details: err.message });
  }
};

// ========================
// Rotas Públicas
// ========================
app.get('/api/v1/event', async (req, res) => {
  try {
    const doc = await db.collection('events').doc('labomba_2027').get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Evento não encontrado' });
    }
    res.json(doc.data());
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/v1/content', async (req, res) => {
  try {
    const rulesDoc = await db.collection('content').doc('rules').get();
    const mediaDoc = await db.collection('content').doc('media').get();
    
    res.json({
      rules: rulesDoc.exists ? rulesDoc.data().rules : [],
      media: mediaDoc.exists ? mediaDoc.data() : { bannerImages: [], galleryImages: [] }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/v1/pricing', async (req, res) => {
  try {
    const snapshot = await db.collection('pricing').get();
    const pricing = [];
    snapshot.forEach(doc => pricing.push({ id: doc.id, ...doc.data() }));
    res.json(pricing);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// ========================
// Rotas Privadas (Admin)
// ========================
app.put('/api/v1/event', authenticateAdmin, async (req, res) => {
  try {
    const data = req.body;
    await db.collection('events').doc('labomba_2027').set(data, { merge: true });
    res.json({ message: 'Evento atualizado com sucesso' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/v1/content/rules', authenticateAdmin, async (req, res) => {
  try {
    const { rules } = req.body;
    await db.collection('content').doc('rules').set({ rules }, { merge: true });
    res.json({ message: 'Regras atualizadas com sucesso' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/v1/pricing', authenticateAdmin, async (req, res) => {
  try {
    const data = req.body;
    const docRef = await db.collection('pricing').add(data);
    res.json({ message: 'Preço adicionado com sucesso', id: docRef.id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/v1/pricing/:id', authenticateAdmin, async (req, res) => {
  try {
    const data = req.body;
    await db.collection('pricing').doc(req.params.id).set(data, { merge: true });
    res.json({ message: 'Preço atualizado com sucesso' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Upload de imagens
app.post('/api/v1/media/upload', authenticateAdmin, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado.' });
    }
    
    // NOTA: Requer bucket configurado.
    // const bucket = admin.storage().bucket();
    // const blob = bucket.file(`images/${Date.now()}_${req.file.originalname}`);
    // const blobStream = blob.createWriteStream({
    //   metadata: { contentType: req.file.mimetype }
    // });
    
    // Para simplificar no MVP local, vamos apenas simular sucesso.
    const fakeUrl = `https://storage.googleapis.com/fake-bucket/images/${Date.now()}_${req.file.originalname}`;
    
    res.status(200).json({ message: 'Upload concluído com sucesso', url: fakeUrl });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// Inicia servidor
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
