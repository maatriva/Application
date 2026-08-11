import express from "express";
import path from "path";
import dotenv from "dotenv";
import { GoogleGenAI } from "@google/genai";
import { createServer as createViteServer } from "vite";
import apiRouter from "./src/routes";
import { getUploadsDirectory } from "./src/config/uploads.config";

dotenv.config();

const PORT = 3000;

// Initialize GoogleGenAI with appropriate headers as per instructions
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  httpOptions: {
    headers: {
      "User-Agent": "aistudio-build",
    },
  },
});

async function startServer() {
  const app = express();

  // CORS Middleware setup
  app.use((req, res, next) => {
    const origin = req.headers.origin;
    if (origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    } else {
      res.setHeader('Access-Control-Allow-Origin', '*');
    }
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Access-Control-Allow-Request-Private-Network, *');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Private-Network', 'true');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    next();
  });

  app.use(express.json({ limit: '100mb' }));
  app.use(express.urlencoded({ limit: '100mb', extended: true }));
  const uploadsDirectory = getUploadsDirectory();
  app.use('/uploads', express.static(uploadsDirectory, {
    setHeaders: (res) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', '*');
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    }
  }));

  // Mount API Router
  app.use('/', apiRouter);

  // Server-side Gemini API route for Smart Baby Monitor AI Insights
  app.post("/api/gemini/insight", async (req, res) => {
    try {
      const { babyStatus, temperature, heartRate, sleepHours, cryCount } = req.body;

      const prompt = `You are the AI Pediatric Brain of the "Maatriva" smart baby monitoring system.
Analyze the following real-time biometric metrics of a baby:
- Baby Status: ${babyStatus || "Sleeping"}
- Ambient Nursery Temperature: ${temperature || "24"}°C
- Heart Rate: ${heartRate || "115"} bpm
- Sleep Duration: ${sleepHours || "8.2"} hours
- Cry Count: ${cryCount || "0"} occurrences today

Based on these readings, provide a concise, warm, highly informative, and actionable parent-centric daily summary/insight.
Ensure the tone is reassuring, expert, and warm. Limit the response to 2 to 3 sentences maximum. Do not use generic placeholders.`;

      const response = await ai.models.generateContent({
        model: "gemini-3.5-flash",
        contents: prompt,
        config: {
          systemInstruction: "You are an expert pediatric nurse and baby sleep consultant. Speak directly to the parents (using 'Your baby').",
        }
      });

      res.json({ insight: response.text });
    } catch (error: any) {
      console.error("Gemini Insight Generation Error:", error);
      res.status(500).json({
        error: "Could not generate AI insights.",
        details: error.message || error,
      });
    }
  });

  // Vite middleware setup
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
      root: path.join(__dirname, "../app"),
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(__dirname, "../app/dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  const HOST = process.env.HOST || "0.0.0.0";
  app.listen(PORT, HOST, () => {
    console.log(`Maatriva server running at http://${HOST}:${PORT}`);
  });
}

startServer();
