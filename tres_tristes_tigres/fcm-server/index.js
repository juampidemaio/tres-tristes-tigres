require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');

const app = express();
app.use(bodyParser.json());

// Parsear el JSON string del service account desde env var
const serviceAccount = JSON.parse(process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // databaseURL: process.env.DATABASE_URL, // Opcional si usas RTDB
});

app.post('/send-notification', async (req, res) => {
  console.log('📩 Petición POST /send-notification recibida');
  console.log('📥 Cuerpo recibido:', req.body);

  const { token, title, body } = req.body;

  if (!token || !title || !body) {
    console.warn('⚠️ Faltan campos obligatorios en la petición');
    return res.status(400).send('Faltan campos obligatorios');
  }

  const message = {
    notification: {
      title,
      body,
    },
    token,
    android: {
      priority: "high", // para asegurarte que notificación es inmediata
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: "default",
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notificación enviada con éxito:', response);
    res.status(200).send({ success: true, response });
  } catch (error) {
    console.error('❌ Error al enviar notificación:', error);
    res.status(500).send({ success: false, error });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
