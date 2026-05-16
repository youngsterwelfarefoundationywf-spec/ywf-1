import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // Email Transporter (Lazy Init)
  let transporter: nodemailer.Transporter | null = null;

  const getTransporter = () => {
    if (!transporter) {
      if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
        console.warn('SMTP credentials missing. Email notifications will fail.');
        return null;
      }
      transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '587'),
        secure: false,
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
    }
    return transporter;
  };

  // API: Health Check
  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // API: Send Deposit Notification
  app.post('/api/notify-deposit', async (req, res) => {
    const { email, name, amount, totalBalance, monthYear } = req.body;

    if (!email || !name || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const mailOptions = {
      from: `"Youngster Welfare Foundation" <${process.env.FROM_EMAIL || process.env.SMTP_USER}>`,
      to: email,
      subject: `টাকা জমার নিশ্চিতকরণ - ${monthYear}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #00df82;">Youngster Welfare Foundation</h2>
          <p>জনাব <strong>${name}</strong>,</p>
          <p>আপনার অ্যাকাউন্ট থেকে <strong>${monthYear}</strong> মাসের জন্য <strong>৳ ${amount}</strong> সফলভাবে জমা করা হয়েছে।</p>
          <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0; color: #555;">বর্তমান মোট জমা:</p>
            <h3 style="margin: 5px 0; font-size: 24px; color: #333;">৳ ${totalBalance}</h3>
          </div>
          <p>যেকোন প্রয়োজনে অ্যাডমিনের সাথে যোগাযোগ করুন।</p>
          <p style="font-size: 12px; color: #999;">ধন্যবাদ,<br>Youngster Welfare Foundation Team</p>
        </div>
      `,
    };

    const mailer = getTransporter();
    if (!mailer) {
      return res.status(500).json({ error: 'Email service not configured' });
    }

    try {
      await mailer.sendMail(mailOptions);
      res.json({ success: true });
    } catch (error: any) {
      console.error('Email send error:', error);
      res.status(500).json({ error: 'Failed to send email', details: error.message });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
