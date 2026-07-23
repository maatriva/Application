import { GoogleGenAI } from '@google/genai';
import { env } from '../../config/env';

export class AiService {
  private ai: GoogleGenAI;

  constructor() {
    this.ai = new GoogleGenAI({
      apiKey: env.GEMINI_API_KEY,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        },
      },
    });
  }

  /**
   * Generates a warm, medical/pediatric-grade advice summary for parents based on real-time biometric metrics.
   */
  public async generateDailyInsight(data: {
    babyStatus?: string;
    temperature?: number;
    heartRate?: number;
    sleepHours?: number;
    cryCount?: number;
  }): Promise<string> {
    const babyStatus = data.babyStatus || 'Sleeping';
    const temperature = data.temperature || 24;
    const heartRate = data.heartRate || 115;
    const sleepHours = data.sleepHours || 8.2;
    const cryCount = data.cryCount || 0;

    const prompt = `You are the AI Pediatric Brain of the "Maatriva" smart baby monitoring system.
Analyze the following real-time biometric metrics of a baby:
- Baby Status: ${babyStatus}
- Ambient Nursery Temperature: ${temperature}°C
- Heart Rate: ${heartRate} bpm
- Sleep Duration: ${sleepHours} hours
- Cry Count: ${cryCount} occurrences today

Based on these readings, provide a concise, warm, highly informative, and actionable parent-centric daily summary/insight.
Ensure the tone is reassuring, expert, and warm. Limit the response to 2 to 3 sentences maximum. Do not use generic placeholders.`;

    const response = await this.ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: prompt,
      config: {
        systemInstruction: 'You are an expert pediatric nurse and baby sleep consultant. Speak directly to the parents (using \'Your baby\').',
      },
    });

    if (!response.text) {
      throw new Error('AI failed to generate a response text.');
    }

    return response.text;
  }
}
