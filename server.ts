import express from "express";
import path from "path";
import dotenv from "dotenv";
import { GoogleGenAI } from "@google/genai";
import { createServer as createViteServer } from "vite";

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
  app.use(express.json());

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
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Maatriva server running at http://localhost:${PORT}`);
  });
}

startServer();
